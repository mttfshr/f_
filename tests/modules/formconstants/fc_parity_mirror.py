"""fc_parity_mirror.py -- tier-1 NumPy mirror of the f_formconstants PARITY build
(spec Revision 2, tasks T041).

A term-for-term port of webgpgpu/examples/wilson_cowan_examples/
WC_Example_10_fullscreen.html and the lib/ functions it calls. Nothing is added:
no per-frame noise, no habituation, no foveal softening, no contrast/sharp, no
clamps beyond the NaN guard. Each item below cites the spec's S-table.

    S1  fixed solver size N (the page: 1024; arrays here may be smaller for tests)
    S2  8-bit quantization q(x) = floor(255 x + 0.5)/255 at: the blur-x output,
        the blur-y output, and the WC update's E and I
    S3  blur: sigma = (1, 2, 1, 1) per channel (R, G, B, A), one shared radius
        ceil(3 * max sigma) = 6, weights exp(-0.5 (i/sigma)^2) normalized over
        [-6, 6], taps at exact integer offsets, wrap
    S4  WC update, Example-10 constants; B = |Ue - Ui| * 3 (UNquantized Ue/Ui)
        stored through an 8-bit target (clamp + round), A = 1
    S5  drive s (E sigmoid input only): s_depth * (fract(t * s_rate) < 0.5),
        s_depth 0.6, s_rate 3.4/500 (the source's sign(sin(...)) square wave;
        see s_source() for the exact form and the one-frame difference at t = 0)
    S6  seed: uniform uint8 (k/255) in all four channels, once
    S7  map: z in [-1, 1]^2 of the SQUARE canvas (window crop on the long axis);
        sample the state at (atan2(zy, zx), ln |z|) / 2 pi, bilinear, wrap
    S8  display: the sampled state's four channels, E, I, B, with alpha 1

Array layout: state is (H, W, 4) float32, R = E, G = I, B = contour, A = flag.
Row index = texture t coordinate (GL convention: row 0 is the BOTTOM). A jit
texture may show the picture vertically mirrored relative to the page; that is
not a parity failure (spec Revision 2).

The stage functions (blur_pass, wc_step, pass_stage, encode) are the unit the
codeboxes mirror; step() runs one whole frame in the page's order:
blur_x -> blur_y -> wc (reads the PRE-blur state for the relaxation target).
"""
import numpy as np

F32 = np.float32

# ---------------------------------------------------------------- constants
LEVELS = 255.0
N_SOLVER = 1024                     # S1 (tests run smaller; the mirror takes any N)
SIGMAS = (1.0, 2.0, 1.0, 1.0)       # S3: GPUGaussianMultiBlur(gl, 1, 2, 1, 1)
RADIUS = 6                          # ceil(3 * max sigma)
AEE, AIE, AEI, AII = 10.5, 8.5, 12.0, 3.0     # S4 (page `parameters`)
HE, HI = 2.0, 3.5
TE, TI = 10.0, 20.0
DT = 1.0
S_DEPTH = 0.6                       # S5
S_RATE = 3.4 / 500.0                # period 1 / S_RATE ~ 147.06 frames
TWO_PI = F32(2.0 * np.pi)


# --------------------------------------------------------------------- S2
def q(x, levels=LEVELS):
    """EncodeFloat: floor(255 x + 0.5)/255. levels=None disables it (the
    test-only float control; the page always quantizes)."""
    if levels is None:
        return x
    lv = F32(levels)
    return (np.floor(lv * x + F32(0.5)) / lv).astype(F32)


def q8_store(x, levels=LEVELS):
    """A float written to an 8-bit render target: clamp to [0, 1], round."""
    return q(np.clip(x, F32(0.0), F32(1.0)), levels)


# --------------------------------------------------------------------- S3
def createGaussianConvolution(sigma, radius=RADIUS):
    """lib/gpugaussian.js createGaussianConvolution(sigma, true, radius):
    2*radius+1 weights exp(-0.5 ((i - radius)/sigma)^2), normalized."""
    i = np.arange(0, 2 * radius + 1, dtype=np.float64)
    w = np.exp(-0.5 * ((i - radius) / sigma) ** 2)
    return (w / w.sum()).astype(F32)


def half_kernel():
    """(RADIUS+1, 4): weights[i, c] = kernel_c[i + radius] -- the packing the
    page passes as the shader's `weights[K+1]` vec4 array."""
    k = np.zeros((RADIUS + 1, 4), dtype=F32)
    for c, s in enumerate(SIGMAS):
        full = createGaussianConvolution(s)
        k[:, c] = full[RADIUS:]
    return k


def _tap(state, d, axis):
    """state sampled at x + d along axis: two wrapped texels blended by the fraction (T072 Grain)."""
    f0 = int(np.floor(d))
    fr = F32(d - f0)
    a = np.roll(state, -f0, axis=axis)
    b = np.roll(state, -(f0 + 1), axis=axis)
    return a + (b - a) * fr


def blur_pass(state, axis, levels=LEVELS, grain=1.0):
    """One pass of the page's multi-blur shader along `axis` (0 = rows = y,
    1 = columns = x), all four channels, wrap, quantized output.
    c = tex(0) w[0] + sum_i (tex(+i) + tex(-i)) w[i];  c /= w[0] + 2 sum w[i]."""
    w = half_kernel()
    acc = state * w[0]
    ssum = w[0].copy()
    for i in range(1, RADIUS + 1):
        if grain == 1.0:                # parity: integer taps
            pair = np.roll(state, i, axis=axis) + np.roll(state, -i, axis=axis)
        else:                           # T072 Grain: tap offsets i * grain, bilinear between texels
            pair = _tap(state, i * grain, axis) + _tap(state, -i * grain, axis)
        acc = acc + pair * w[i]
        ssum = ssum + F32(2.0) * w[i]
    return q(acc / ssum, levels)


def blur(state, levels=LEVELS, grain=1.0):
    """blur_x then blur_y (`blur(U, temp, UC)`); grain scales the tap spacing (T072)."""
    return blur_pass(blur_pass(state, 1, levels, grain), 0, levels, grain)


# --------------------------------------------------------------------- S5
def s_of_t(t):
    """The module's drive: s_depth * (fract(t * s_rate) < 0.5)."""
    return F32(S_DEPTH) if (float(t) * S_RATE) % 1.0 < 0.5 else F32(0.0)


# ------------------------------------------------------- Phase D, T061: the pulse
S_PERIOD = 500.0 / 3.4              # the internal square wave's period in frames (S5)


def luma(tex):
    """Rec. 709 luma of an RGB(A) texture -- the pulse inlet's reading."""
    return (F32(0.2126) * tex[..., 0] + F32(0.7152) * tex[..., 1]
            + F32(0.0722) * tex[..., 2]).astype(F32)


def screen_coords(n, ow, oh):
    """Phase D T073, Pulse Space = Screen: for each solver texel, the normalized SCREEN position it is
    displayed at (the inverse of encode's map). u = (ix + .5)/n -> angle 2 pi u; v = (iy + .5)/n -> the
    radii exp(2 pi (v - k)), k integer (the map repeats outward). Per direction the outermost copy
    INSIDE the frame is used: rb = the distance to the frame edge along that angle, k = ceil(v - log(rb) /
    2 pi), so every texel reads an on-screen point (no black). Returns (h, w, 2) float32 (x, y) in [0, 1]."""
    lng = float(max(ow, oh))
    ax, ay = F32(ow / lng), F32(oh / lng)
    c = (np.arange(n, dtype=F32) + F32(0.5)) / F32(n)
    u = c[None, :] * np.ones((n, 1), F32)
    v = c[:, None] * np.ones((1, n), F32)
    th = TWO_PI * u
    cs, sn = np.cos(th).astype(F32), np.sin(th).astype(F32)
    rb = np.minimum(ax / np.maximum(np.abs(cs), F32(1e-6)), ay / np.maximum(np.abs(sn), F32(1e-6)))
    k = np.ceil(v - np.log(rb) / TWO_PI)
    r = np.exp(TWO_PI * (v - k)).astype(F32)
    out = np.empty((n, n, 2), F32)
    out[..., 0] = (r * cs / ax + F32(1.0)) * F32(0.5)
    out[..., 1] = (r * sn / ay + F32(1.0)) * F32(0.5)
    return out


def sample_tex(tex, coords):
    """Bilinear read of a texture at normalized coords (x, y), texel centres at (i + .5) / size, edges
    clamped -- GL linear filtering as the codebox's `sample` does."""
    h, w = tex.shape[:2]
    x = coords[..., 0].astype(np.float64) * w - 0.5
    y = coords[..., 1].astype(np.float64) * h - 0.5
    x0, y0 = np.floor(x), np.floor(y)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    xi0 = np.clip(x0, 0, w - 1).astype(int); xi1 = np.clip(x0 + 1, 0, w - 1).astype(int)
    yi0 = np.clip(y0, 0, h - 1).astype(int); yi1 = np.clip(y0 + 1, 0, h - 1).astype(int)
    top = tex[yi0, xi0] * (1 - fx) + tex[yi0, xi1] * fx
    bot = tex[yi1, xi0] * (1 - fx) + tex[yi1, xi1] * fx
    return (top * (1 - fy) + bot * fy).astype(F32)


def s_pulse(t, depth=S_DEPTH, period=S_PERIOD, pulse=None, conn=0.0, mix=1.0, gain=1.0,
            space=0.0, ow=None, oh=None, n=None):
    """T061 `s`: depth * mix(square(t / period), luma(pulse), conn). REPLACE semantics (Matt,
    2026-10-24): a connected pulse texture IS the pulse; unplugged (conn 0) the internal square
    wave runs. The pulse is read in cortical space (on the solver grid, same size as the state
    here; the module bilinear-samples a texture of any size). Returns a scalar when unplugged,
    an (h, w) array when a pulse texture is given."""
    sq = F32(1.0) if (float(t) / float(period)) % 1.0 < 0.5 else F32(0.0)
    if pulse is None:
        return F32(depth) * sq
    if space:                           # T073: Screen -- read the texture where each texel is displayed
        pulse = sample_tex(pulse, screen_coords(n, ow, oh))
    c = F32(conn) * F32(mix)            # T071: Pulse Mix blends the internal wave with the texture
    return (F32(depth) * ((F32(1.0) - c) * sq + c * F32(gain) * luma(pulse))).astype(F32)   # T071: Pulse Gain


def rate_clock(frameno, rate):
    """Phase D T065: Rate by STEP SKIPPING (not a smaller dt, which freezes under quantization).
    Returns (steps, simt): whether this frame advances the solver, and the solver's own clock (what the
    pulse wave reads). simt = floor(frameno * rate); a frame steps when floor((frameno + 1) * rate)
    > simt. rate 1 = every frame steps and simt == frameno (parity). A non-stepping frame holds the
    state exactly like Freeze."""
    simt = int(np.floor(float(frameno) * float(rate)))
    return int(np.floor((float(frameno) + 1.0) * float(rate))) > simt, simt


def module_frame(state, frameno, rate=1.0, freeze=False, levels=LEVELS, grain=1.0):
    """One rendered frame of the module with Rate and Freeze: the pulse reads simt; the state holds on
    a non-stepping frame or under Freeze."""
    steps, simt = rate_clock(frameno, rate)
    return step(state, simt, levels, s=s_pulse(simt), freeze=freeze or not steps, grain=grain)


Q_LEVELS = (255.0, 1023.0, None)  # Phase D T062: the q_levels menu index -> levels (None = float)

OUT_MODES = ("RGB", "E", "Contour", "Luma")     # Phase D T060: the out_mode menu, in order


def encode_mode(state, ow, oh, mode):
    """T060: encode() then the output mode. 0 RGB = (E, I, contour) as the page (S8); 1 E, 2 contour,
    3 Rec. 709 luma of that RGB -- each a gray (v, v, v, 1)."""
    rgb = encode(state, ow, oh)
    if mode == 0:
        return rgb
    if mode == 1:
        v = rgb[..., 0]
    elif mode == 2:
        v = rgb[..., 2]
    else:
        v = luma(rgb)
    out = np.empty_like(rgb)
    out[..., 0] = out[..., 1] = out[..., 2] = v
    out[..., 3] = 1.0
    return out


def s_source(t):
    """The page's exact expression: .3 * (sign(sin(t pi 6.8 / 500)) + 1).
    Equals s_of_t at every integer t except two kinds of single frame: t = 0
    (the page gives 0.3, sign 0; the module 0.6) and t = 1250 k, which land
    exactly on a half-period (1250 * 3.4/500 = 8.5), where the sign is decided
    by the page's truncated 3.1415926 for pi (a ~1e-6 sine either way) and the
    fract form can pick the other side. Documented, not chased."""
    return F32(0.3 * (np.sign(np.sin(t * 3.1415926 * 6.8 / 500.0)) + 1.0))


# --------------------------------------------------------------------- S6
def seed_state(n, rng):
    """Uniform uint8 random in all four channels (k/255). n x n, or (h, w)."""
    h, w = (n, n) if np.isscalar(n) else n
    return (rng.integers(0, 256, size=(h, w, 4)).astype(F32) / F32(255.0))


# --------------------------------------------------------------------- S4
def F(x):
    return (F32(1.0) / (F32(1.0) + np.exp(-x))).astype(F32)


def wc_step(state, conv, t, levels=LEVELS, s=None, freeze=False):
    """The `wc` shader. state = Uin (pre-blur), conv = Uconv (blur output).
    E and I are written through EncodeFloat; B = |Ue - Ui| * 3 from the
    UNquantized updated values, stored as 8-bit; A = 1."""
    e, i = state[..., 0], state[..., 1]
    ce, ci = conv[..., 0], conv[..., 1]
    if s is None:                       # parity default; T061 passes s_pulse(...) (scalar or per texel)
        s = s_of_t(t)
    ve = F(F32(AEE) * ce - F32(AIE) * ci - F32(HE) + s)
    vi = F(F32(AEI) * ce - F32(AII) * ci - F32(HI))
    en = e + (ve - e) * F32(DT / TE)
    inn = i + (vi - i) * F32(DT / TI)
    out = np.empty_like(state)
    out[..., 0] = q(en, levels)
    out[..., 1] = q(inn, levels)
    out[..., 2] = q8_store(np.abs(en - inn) * F32(3.0), levels)
    out[..., 3] = 1.0
    if freeze:                          # Phase D T070: Freeze -- write back the incoming state unchanged
        out = state.copy()
        out[..., 3] = 1.0

    return out


# ---------------------------------------------------------------- pass stage
def pass_stage(fb, seed, reseed):
    """The module's hold/reseed stage. A feedback texel is LOST when its alpha
    is 0 (wc always writes A = 1; a fresh or reallocated texture reads A = 0) --
    NOT when E == I == 0, which is a legitimate state under quantization.
    Non-finite feedback is zeroed first (the NaN guard; it keeps A, so a zapped
    texel is held at zero, not reseeded)."""
    fbg = np.where(np.abs(fb) < F32(1e30), fb, F32(0.0))
    lost = (fbg[..., 3] == 0.0)[..., None]
    take_seed = bool(reseed) or lost
    return np.where(take_seed, seed, fbg).astype(F32)


# ------------------------------------------------------------------ one frame
def step(state, t, levels=LEVELS, s=None, freeze=False, grain=1.0):
    """One frame in the page's order. `state` is the held state (what the
    `pass` stage emitted); returns the new state (what feeds back and renders)."""
    conv = blur(state, levels, grain)
    return wc_step(state, conv, t, levels, s, freeze)


def run(state0, frames, t0=0, levels=LEVELS, trace=False):
    st = state0
    tr = {"em": [], "es": [], "ebar": []}
    for fr in range(frames):
        st = step(st, t0 + fr, levels)
        if trace:
            e = st[..., 0]
            tr["es"].append(float(e.std()))
            tr["em"].append(float(e.mean()))
    return st, tr


# ----------------------------------------------------------------------- S7/S8
def encode(state, ow, oh):
    """The retinal map on an (oh, ow) output. Square crop on the long axis,
    exactly the page's CSS stretch: L = max(ow, oh); zx = (2x-1) ow/L, zy =
    (2y-1) oh/L with texel-centred x, y in [0, 1]. Bilinear + wrap sample of all
    four channels at (atan2(zy, zx), ln r) / 2 pi. Returns (oh, ow, 4) with
    alpha forced to 1. r is floored at 1e-6 (ln 0); the page leaves the exact
    centre undefined."""
    nh, nw = state.shape[0], state.shape[1]
    ys, xs = np.mgrid[0:oh, 0:ow]
    L = float(max(ow, oh))
    zx = ((xs.astype(np.float64) + 0.5) / ow * 2.0 - 1.0) * (ow / L)
    zy = ((ys.astype(np.float64) + 0.5) / oh * 2.0 - 1.0) * (oh / L)
    r = np.maximum(np.hypot(zx, zy), 1e-6)
    th = np.arctan2(zy, zx)
    u = (th / (2.0 * np.pi)).astype(F32)          # texture x
    v = (np.log(r) / (2.0 * np.pi)).astype(F32)   # texture y
    fx = u * F32(nw) - F32(0.5)
    fy = v * F32(nh) - F32(0.5)
    x0f, y0f = np.floor(fx), np.floor(fy)
    tx = (fx - x0f).astype(F32)[..., None]
    ty = (fy - y0f).astype(F32)[..., None]
    x0 = x0f.astype(np.int64) % nw
    y0 = y0f.astype(np.int64) % nh
    x1 = (x0 + 1) % nw
    y1 = (y0 + 1) % nh
    s = state
    out = ((1 - ty) * ((1 - tx) * s[y0, x0] + tx * s[y0, x1])
           + ty * ((1 - tx) * s[y1, x0] + tx * s[y1, x1])).astype(F32)
    out[..., 3] = 1.0
    return out


# --------------------------------------------------------------------- metrics
def power_peak_period(x):
    """Dominant period (in samples) of a 1-D trace, DC removed, via FFT;
    returns None for a flat trace."""
    x = np.asarray(x, dtype=np.float64)
    x = x - x.mean()
    if np.abs(x).max() < 1e-9:
        return None
    sp = np.abs(np.fft.rfft(x * np.hanning(len(x))))
    k = int(np.argmax(sp[1:]) + 1)
    return len(x) / k
