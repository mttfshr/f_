"""
tf_hatch_mirror.py -- NumPy mirror of the f_tf_hatch v2 (streamline / LIC)
renderer. Spec: .specify/f_tf_hatch/spec.md (2026-10-28); plan Phases 0 and 2.

Phase 2 (2026-10-28) folded v1's mirror into this file: `decode` (the canonical
tensor decode idiom) and `presence` (the structure-floor ramp) are the parts the
spec says carry over unchanged. v1's lattice-of-marks mirror and tests are gone
(git a24b8cd has them).

All coordinates inside the march are PIXEL units (x in [0, W], y in [0, H]),
texel centres at +0.5. The codebox does the same via `dim`; steps are uniform
in pixels so a non-square frame gets round streaks.

Stages (one function each, as the codebox passes will be):
  stage_e1  decode + presence  -> aux (axis pair, coherence, presence)
  stage_e2  streamline march   -> aux2 (raw LIC value, presence)
  stage_e3  normalize + style + presence + encode -> out0 (styled), out1 (raw field)

The two design questions the tests are here to settle (spec OQ1, OQ2):
  persist   how coherence enters the march ("mix" = direction mixing with a
            per-step hashed unit vector; "off" = coherence ignored, the
            mutation that reproduces the atan2(0,0) horizontal-axis trap)
  aux_mode  how the axis is stored for the march's reads:
            "doubled"          (cos 2a, sin 2a), bilinear read, half-angle in closed form
            "unsigned_bilinear" (cos a, sin a), bilinear read (flips sign at the cut)
            "unsigned_nearest"  (cos a, sin a), nearest read
"""
import numpy as np
import gpu_sim as g  # noqa: E402

F32 = np.float32

# --- named constants (the codebox carries the same names) ---
EPS_TRACE = 1e-6        # tensormap ADR-6/T019 value, cited
PRES_EPS = 1e-6         # presence knee width at floor 0 (a hair above the iso guard)
PRES_LO = 0.5           # presence ramp: lo = PRES_LO * thr  (thr = floor^2)
PRES_HI = 1.5           # presence ramp: hi = PRES_HI * thr + PRES_EPS
FILL_BASE = 0.0025      # density -> lit-cell probability: fill = FILL_BASE * 2^(5 * density)
FILL_SPAN = 5.0
N_STEPS = 16            # steps per direction (build-time constant; OQ3)
HALF_LEN_FRAC = 0.25    # `length` = 1 -> half-length of 0.25 frame heights per side
GRAIN_SPAN = 6.0        # noise cells per frame height = 2^((1-grain)*GRAIN_SPAN + GRAIN_BASE)
GRAIN_BASE = 3.0
HASH_A, HASH_B, HASH_C = 127.1, 311.7, 43758.5453   # weave's published hash constants
RND_A, RND_B, RND_C = 12.9898, 78.233, 37.719       # per-pixel/per-step direction hash
SIGMA_UNIT = 0.28867513                              # std of uniform[0,1) noise = 1/sqrt(12)
# OQ1 (provisional, Phase 0 evidence 2026-10-28): the aligned weight is coherence^PERSIST_POW.
# Measured on a 0->1 coherence ramp, 6 noise seeds: pow 0.5 gives a graded streak-length
# response over the whole range (2.6 / 4.6 / 7.3 / 11.1 / 16.0 / 14.3 px); pow 1.0 stays
# flat until coherence ~0.5 (2.3 / 2.8 / 2.9 / 6.3 / 11.4 / 13.3 px).
PERSIST_POW = 0.5


def _fract(x):
    x = np.asarray(x, F32)
    return (x - np.floor(x)).astype(F32)


def fill_from_density(density):
    """`density` dial (0..1) -> probability a noise cell is lit (0.0025 .. 0.08)."""
    return F32(FILL_BASE * 2.0 ** (FILL_SPAN * float(density)))


def presence(enc_trace, floor=0.0):
    """Presence: is there structure here AT ALL, independent of its direction.
    enc_trace = R + B of the tensormap outlet-0 texel (= trace * the tensormap's
    `strength`, ~1 on strong structure). thr = floor^2; smooth ramp 0.5*thr ->
    1.5*thr (+ a hair): floor 0 is a step at the iso guard. Not strength-invariant
    for floor > 0: the one absolute quantity in the module."""
    thr = F32(floor) * F32(floor)
    return _smoothstep(F32(PRES_LO) * thr, F32(PRES_HI) * thr + F32(PRES_EPS), np.asarray(enc_trace, F32))


def decode(t, strength=100.0):
    """Canonical decode idiom (.specify/f_tf_glyph/plan.md ADR-2; f_tensor_type.md
    outlet 0). t = RGBA planes (4, ...). Returns (Jxx, Jxy, Jyy, trace, diff, root,
    lambda1, lambda2, theta_grad, axis_along, coherence)."""
    Jxx = t[0] / strength
    Jxy = (t[1] - 0.5) * 2.0 / strength
    Jyy = t[2] / strength
    trace = Jxx + Jyy
    diff = Jxx - Jyy
    root = np.sqrt(diff * diff + F32(4.0) * Jxy * Jxy)
    lambda1 = F32(0.5) * (trace + root)
    lambda2 = F32(0.5) * (trace - root)
    theta = F32(0.5) * np.arctan2(F32(2.0) * Jxy, diff)   # GRADIENT axis
    axis = theta + F32(np.pi / 2)                          # ALONG-STRUCTURE axis
    coherence = np.where(trace > EPS_TRACE,
                         (lambda1 - lambda2) / np.maximum(trace, EPS_TRACE), F32(0.0))
    return (Jxx, Jxy, Jyy, trace, diff, root, lambda1, lambda2, theta, axis, coherence.astype(F32))


def _smoothstep(lo, hi, x):
    t = np.clip((np.asarray(x, F32) - F32(lo)) / np.maximum(F32(hi) - F32(lo), F32(1e-9)), 0, 1)
    return (t * t * (3 - 2 * t)).astype(F32)


# ------------------------------------------------------------------ E1 ---

def stage_e1(tex, strength=100.0, angle_offset=0.0, floor=0.0, aux_mode="doubled"):
    """Decode + presence. tex: (H, W, 4) outlet-0-format tensor texture.

    aux (intermediate, NEVER an outlet), float32:
      ch0, ch1  axis pair: doubled (cos 2a, sin 2a) or unsigned (cos a, sin a);
                a = ALONG-structure axis + angle_offset*pi/2
      ch2       coherence (lambda1-lambda2)/(lambda1+lambda2), 0 below eps_trace
      ch3       presence (structure floor ramp), 0 below eps_trace
    Below eps_trace the axis pair is (0, 0), coherence 0, presence 0 -- never a
    decoded-angle artifact (v1 ADR-5, carried over).
    """
    t = np.moveaxis(np.asarray(tex, F32), -1, 0)
    (_jxx, _jxy, _jyy, trace, _d, _r, _l1, _l2, _th, axis, coh) = decode(t, strength)
    a = (axis + F32(angle_offset * np.pi / 2.0)).astype(F32)
    live = trace > F32(EPS_TRACE)
    if aux_mode == "doubled":
        c, s = np.cos(2 * a), np.sin(2 * a)
    else:
        c, s = np.cos(a), np.sin(a)
    pres = presence(F32(1) * tex[..., 0] + tex[..., 2], floor)
    aux = np.stack([np.where(live, c, 0), np.where(live, s, 0),
                    np.where(live, coh, 0), np.where(live, pres, 0)], -1)
    return g.store_float32(aux)


def _axis_from_aux(s, aux_mode):
    """Recover a unit axis (ca, sa) from an aux sample (sign arbitrary: the
    march's sign_align fixes it). Unset / averaged-to-zero -> (1, 0)."""
    c, sn = s[..., 0], s[..., 1]
    m = np.sqrt(c * c + sn * sn)
    ok = m > F32(1e-6)
    cn = np.where(ok, c / np.maximum(m, F32(1e-6)), F32(1))
    sn_ = np.where(ok, sn / np.maximum(m, F32(1e-6)), F32(0))
    if aux_mode == "doubled":
        # half-angle, closed form, branch cos(a) >= 0:  no atan
        ca = np.sqrt(np.maximum((1 + cn) * F32(0.5), F32(0)))
        sa = np.where(sn_ >= 0, F32(1), F32(-1)) * np.sqrt(np.maximum((1 - cn) * F32(0.5), F32(0)))
        return np.where(ok, ca, F32(1)).astype(F32), np.where(ok, sa, F32(0)).astype(F32)
    return cn.astype(F32), sn_.astype(F32)


def _read(aux, px, py, aux_mode):
    H, W = aux.shape[:2]
    u, v = px / F32(W), py / F32(H)
    if aux_mode == "unsigned_nearest":
        return g.nearest(aux, u, v)
    return g.sample(aux, u, v, oob="clamp")


# ------------------------------------------------------------------ E2 ---

def noise_at(px, py, cell_px, seed=0, fill=None):
    """Procedural noise, WORLD coordinates (never the pixel's rotated frame --
    the cause of v1's origin-anchored rings): a hash of the lattice cell the
    position falls in (weave's published hash form). `seed` shifts the lattice
    by whole cells: a TEST HOOK so metrics can be averaged over independent
    noise realisations; the codebox has no seed."""
    ix = np.floor(px / F32(cell_px)) + F32(101 * seed)
    iy = np.floor(py / F32(cell_px)) + F32(57 * seed)
    h = _fract(np.sin(ix * F32(HASH_A) + iy * F32(HASH_B)) * F32(HASH_C))
    if fill is None:
        return h                                  # dense: uniform white noise per cell
    return (h < F32(fill)).astype(F32)           # sparse: a lit cell (1) with probability `fill`


def stage_e2(aux, n_steps=N_STEPS, length=0.5, grain=0.5, persist="mix",
             persist_pow=PERSIST_POW, aux_mode="doubled", n_dirs=(1, -1), seed=0, fill=None):
    """Streamline march. For each pixel, walk n_steps each way along the local
    axis (sign-aligned against the previous step), accumulate noise_at() at
    every position, box kernel. Coherence enters ONLY through `persist`.

    aux2 (intermediate): (raw, pres, 0, 1): raw = mean noise along the path,
    pres = presence at the starting pixel.
    """
    H, W = aux.shape[:2]
    cy, cx = np.meshgrid(np.arange(H, dtype=F32), np.arange(W, dtype=F32), indexing="ij")
    x0, y0 = cx + F32(0.5), cy + F32(0.5)
    idx = (cy * F32(W) + cx).astype(F32)
    half_len = F32(length * HALF_LEN_FRAC * H)
    step = half_len / F32(n_steps)
    cells_per_h = 2.0 ** ((1.0 - grain) * GRAIN_SPAN + GRAIN_BASE)
    cell_px = H / cells_per_h

    acc = noise_at(x0, y0, cell_px, seed, fill).astype(F32)
    wsum = F32(1.0)
    s0 = _read(aux, x0, y0, aux_mode)
    ca0, sa0 = _axis_from_aux(s0, aux_mode)
    for sgn in n_dirs:
        px, py = x0.copy(), y0.copy()
        alive = np.ones_like(x0)      # a path that leaves the frame STOPS contributing (it used to
                                      # clamp to the edge and re-count one cell: wedge artifacts)
        dx, dy = F32(sgn) * ca0, F32(sgn) * sa0          # start direction
        for k in range(1, n_steps + 1):
            samp = _read(aux, px, py, aux_mode)
            ax, ay = _axis_from_aux(samp, aux_mode)
            flip = np.where(ax * dx + ay * dy < 0, F32(-1), F32(1))   # sign continuity
            ax, ay = ax * flip, ay * flip
            if persist == "mix":
                w = np.clip(samp[..., 2], 0, 1) ** F32(persist_pow)
                ang = F32(2 * np.pi) * _fract(np.sin(idx * F32(RND_A) + F32(k) * F32(RND_B)
                                                     + F32(sgn) * F32(RND_C)) * F32(HASH_C))
                rx, ry = np.cos(ang), np.sin(ang)
                mx, my = w * ax + (F32(1) - w) * rx, w * ay + (F32(1) - w) * ry
                mm = np.sqrt(mx * mx + my * my)
                okm = mm > F32(1e-6)
                ax = np.where(okm, mx / np.maximum(mm, F32(1e-6)), ax)
                ay = np.where(okm, my / np.maximum(mm, F32(1e-6)), ay)
            elif persist != "off":
                raise ValueError(persist)
            nx_, ny_ = px + step * ax, py + step * ay
            alive = alive * ((nx_ >= 0) & (nx_ <= W) & (ny_ >= 0) & (ny_ <= H)).astype(F32)
            px = np.clip(nx_, F32(0.5), F32(W) - F32(0.5)).astype(F32)   # reads stay in-bounds
            py = np.clip(ny_, F32(0.5), F32(H) - F32(0.5)).astype(F32)
            dx, dy = ax, ay
            acc = acc + alive * noise_at(px, py, cell_px, seed, fill)
            wsum = wsum + alive
    if fill is None:
        raw = (acc / wsum).astype(F32)                  # dense: the mean along the (in-frame) path
    else:
        # sparse: lit CELLS crossed, so one impulse's stroke has brightness ~1 whatever
        # `length` and `grain` are (each sample spans step/cell_px of a cell)
        raw = (acc * F32(step / cell_px)).astype(F32)
    pres = s0[..., 3]
    return g.store_float32(np.stack([raw, pres, np.zeros_like(raw), np.ones_like(raw)], -1))


# ------------------------------------------------------------------ E3 ---

SPARSE_GAIN_LO = 0.6  # sparse input: raw is in lit-cells-crossed (one impulse ~ 1), so the gain is
SPARSE_GAIN_HI = 2.0  # O(1): contrast 0 -> 0.6 (dim strokes), contrast 1 -> 2.0 (saturated).
                      # PROVISIONAL exploration values.


def stage_e3(aux2, n_steps=N_STEPS, contrast=0.5, line=0.0, bypass=0.0, fill=None):
    """Normalize + style + presence + encode (the only clamp). The mean of
    n_eff independent uniform samples has std SIGMA_UNIT/sqrt(n_eff), so raw LIC
    is gray; `contrast` interpolates the gain from 1 to the stretch that puts
    +-2 sigma at +-0.5. `line` blends the smooth field into a hard
    engraved-line threshold at 0.5.

    out0 = styled (luma on black, A=1); out1 = normalized unstyled field
    (spec OQ4). Bypass -> black on both, A=1.
    """
    raw, pres = aux2[..., 0], aux2[..., 1]
    n_eff = 2 * n_steps + 1
    sigma = SIGMA_UNIT / np.sqrt(n_eff)
    if fill is None:
        gain = F32(1.0 + contrast * (0.25 / sigma - 1.0))
        v = np.clip(F32(0.5) + (raw - F32(0.5)) * gain, 0, 1).astype(F32)
    else:
        v = np.clip(raw * F32(SPARSE_GAIN_LO + contrast * (SPARSE_GAIN_HI - SPARSE_GAIN_LO)), 0, 1).astype(F32)
    w = F32(0.5 + (0.03 - 0.5) * line)
    hard = _smoothstep(F32(0.5) - w, F32(0.5) + w, v)
    styled = (v + (hard - v) * F32(line)).astype(F32)
    keep = F32(1.0 - bypass)
    o0 = (styled * pres * keep).astype(F32)
    o1 = (v * pres * keep).astype(F32)
    one = np.ones_like(o0)
    return (np.stack([o0, o0, o0, one], -1).astype(F32),
            np.stack([o1, o1, o1, one], -1).astype(F32))


def chain(tex, strength=100.0, angle_offset=0.0, floor=0.0, aux_mode="doubled",
          n_steps=N_STEPS, length=0.5, grain=0.5, persist="mix", persist_pow=PERSIST_POW,
          contrast=0.5, line=0.0, bypass=0.0, seed=0, fill=None):
    aux = stage_e1(tex, strength, angle_offset, floor, aux_mode)
    aux2 = stage_e2(aux, n_steps, length, grain, persist, persist_pow, aux_mode, seed=seed, fill=fill)
    return stage_e3(aux2, n_steps, contrast, line, bypass, fill=fill)
