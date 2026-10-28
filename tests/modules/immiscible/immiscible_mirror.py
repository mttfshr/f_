"""
immiscible_mirror.py -- NumPy mirror of every f_vf_immiscible stage, pass for pass,
in float32 (plan ADR-1..5, .specify/f_vf_immiscible/).

Chain:   inab -> adv -> fx -> fy -> spec -> iy -> ix -> (hold -> pass -> adv)   enc
  pass  hold phi, or re-seed fill + amp*(2h-1) on reseed; zap non-finite only
  inab  decode + content-gate both velocity vecfields, taps x taps box minify, pack
  adv   blend by phi, backward-advect phi (PERIODIC bilinear), inject, clamp,
        pack phi and phi^3 as the two complex fields of one DFT chain
  fx/fy forward separable DFT            (fluid_mirror.fft2_np / dft_mirror)
  spec  stabilised semi-implicit Cahn-Hilliard step per bin
  iy/ix inverse DFT; ix keeps the real part of phi and zaps non-finite values
  enc   render-size periodic upsample of phi and both velocities, blend,
        encode out0 (phi as grey) and out1 (blended f_vecfield), bypass gate

Texture packing (float32 RGBA, solver 256 x 256 by default):
  inab out     R,G = uA.x,uA.y   B,A = uB.x,uB.y   (decoded (p - 0.5)*2; 0 if invalid)
  phi state    R = phi, G = B = A = 0
  adv out      R = phi, B = phi^3, G = A = 0       (G, A are the DFT imaginary parts)
  spectral     R,G = Re,Im phi-hat;  B,A = Re,Im (phi^3)^
  spec out     R,G = Re,Im phi-hat'; B,A = 0       (second field idle on the way back)
  out0         (w, w, w, 1) with w = (phi + 1)/2
  out1         f_vecfield: RG = 0.5 + 0.5*u, B = 0.5, A = 1

Domain: periodic unit square; wavevector k = 2*pi*signed_index; x runs along
axis 1 (columns), y along axis 0 (rows), as in fluid_mirror.

Module constants (A_STAB, MDT_MAX, MDT_EXP, PHI_CLAMP, RESEED_AMP, IFACE_MIN) were fixed
by the T004 stability sweep; S_LO, S_HI stay provisional until T007. They are looked
up at call time. Mutation hooks (tests patch these to prove the tests bite):
spec_factor(), blend_weight(), and fluid_mirror.PERIODIC.

The mirror does NOT clamp dial ranges (a test may pass coarsen > 1 to get a
bigger step); the module's dials do.

Run the tests:  tests/run.sh -q tests/modules/immiscible/test_immiscible.py
"""
from dataclasses import dataclass, replace

import numpy as np

import fluid_mirror as fm
from gpu_sim import F32, grid, sample, store_float32

N_SOLVER = 256           # fixed solver grid; iface is in texels of THIS grid (NF-005)

# ------------------------------------------------ constants fixed by T004 (2026-10-27)
# spike_immiscible_constants.py; numbers in .specify/f_vf_immiscible/tasks.md Record.
A_STAB = 1.5             # stabiliser a. a = 0.5 diverges at mdt >= 1e-2; a >= 1 never rose in energy up to
                         # mdt 51; 1.5 keeps the overshoot to 1.03 (a = 1: 1.09)
MDT_MAX = 0.1            # per-frame mobility*dt at coarsen = 1 (separation in ~60 frames; larger
                         # values stop helping: the stabiliser saturates the domain-scale rate)
MDT_EXP = 3              # cubic dial law, as f_vf_fluid's viscosity
PHI_CLAMP = 1.25         # safety bound in adv before packing (observed max |phi| 1.03)
RESEED_AMP = 0.05        # reset noise amplitude (onset 16-29 frames for 0.005-0.3: not critical)
IFACE_MIN = 1.5          # smallest dial value: the stripe profile matches tanh to 1.5e-3 at iface 1, 5e-5 from 1.5
THRESH_W = 0.15         # width of the injection smoothstep above `thresh` (baked in adv)
PULL_MAX = 0.05          # per-frame rate of the mean pull at pull = 1 (rate = PULL_MAX * pull^3, baked in spec)
# PROVISIONAL until T007 (blend rule, G2):
S_LO, S_HI = 0.05, 0.35  # interface-aware rule: smoothstep band on |grad phi| * eps


@dataclass(frozen=True)
class Params:
    dt: float = 0.01            # advection step, same meaning as f_vf_fluid / f_vf_advect
    iface: float = 4.0          # interface width, solver texels: eps = iface / N, kappa = eps^2
    coarsen: float = 0.3        # dial -> per-frame mobility*dt via coarsen_to_mdt()
    inject: float = 0.3         # in0 deposit dial (rate = inject^3)
    thresh: float = 0.5         # source luma where deposit starts (smoothstep over THRESH_W)
    mix_pct: float = 50.0       # Mix: 0 = pure A motion, 50 = neutral, 100 = pure B motion (velocity weight only)
    pull: float = 0.3           # mean-of-phi relaxation toward fill (rate = PULL_MAX * pull^3 per frame)
    fill: float = 0.0           # mean phi at reseed, and what `pull` relaxes the mean toward
    blend: float = 0.0          # 0 = plain, 1 = interface-aware (G2)
    taps: float = 2.0           # inab minification: taps x taps hardware taps per solver texel
    bypass_gate: float = 0.0    # 1 = neutral outlets (G5 as planned)
    src_a: float = 1.0          # vs_inState flags: input connected
    src_b: float = 1.0
    src_phi: float = 1.0

    def with_(self, **kw):
        return replace(self, **kw)


def coarsen_to_mdt(c):
    """Dial value -> per-frame mobility*dt (cubic law, like f_vf_fluid's viscosity)."""
    return MDT_MAX * float(c) ** MDT_EXP


def mdt_to_coarsen(mdt):
    return (float(mdt) / MDT_MAX) ** (1.0 / MDT_EXP)


def kappa_of(iface, n):
    """Gradient-energy coefficient: the flat-interface profile is tanh(x / (sqrt(2) eps))."""
    return (float(iface) / float(n)) ** 2


# ------------------------------------------------------------------ helpers

def fract(x):
    return x - np.floor(x)


def hash01(cx, cy, salt):
    """Arithmetic hash in [0, 1) of texel index and salt (no sin()); Hoskins hash12 shape.
    The GPU codebox (codebox_pass.gen) computes the same arithmetic but is NOT bit-identical: fract at magnitude ~2e3 amplifies float32 rounding (T016: median err 1e-9, 7.5% of texels off by ~1e-4, 0.05% wrap-flipped by 2*amp). Statistically equal; change both together."""
    s = F32(salt)
    px = fract((cx + s * F32(37.0)) * F32(0.1031))
    py = fract((cy + s * F32(17.0)) * F32(0.1030))
    pz = fract((cx + cy + s * F32(5.0)) * F32(0.0973))
    d = px * (py + F32(33.33)) + py * (pz + F32(33.33)) + pz * (px + F32(33.33))
    px, py, pz = px + d, py + d, pz + d
    return fract((px + py) * pz).astype(F32)


def smoothstep(lo, hi, x):
    t = np.clip((x - F32(lo)) / F32(hi - lo), 0, 1).astype(F32)
    return (t * t * (F32(3.0) - F32(2.0) * t)).astype(F32)


def blend_weight(phi):
    """w = clamp((phi + 1)/2, 0, 1): 0 at phase A (phi = -1), 1 at phase B (phi = +1)."""
    return np.clip((phi + F32(1.0)) * F32(0.5), 0, 1).astype(F32)


def grad_phi(phi):
    """Periodic central differences, per unit domain length (x = axis 1, y = axis 0)."""
    h, w = phi.shape
    gx = (np.roll(phi, -1, 1) - np.roll(phi, 1, 1)) * F32(w) * F32(0.5)
    gy = (np.roll(phi, -1, 0) - np.roll(phi, 1, 0)) * F32(h) * F32(0.5)
    return gx.astype(F32), gy.astype(F32)


def tap_avg(tex, taps, h, w):
    """tex channels averaged through the taps x taps grid onto an h x w solver grid
    (fluid_mirror.tap_weights: the factorised box minify), returns h x w x 4."""
    th, tw = tex.shape[:2]
    wy, wx = fm.tap_weights(th, taps, h), fm.tap_weights(tw, taps, w)
    out = np.zeros((h, w, 4), F32)
    for c in range(4):
        out[..., c] = (wy @ tex[..., c] @ wx.T).astype(F32)
    return out


def mix_bias(w, mix_pct):
    """The Mix bias on the velocity weight: moves w toward 1 (mix_pct > 50) or 0 (< 50) by |mix_pct - 50| / 50.
    50 is exactly the identity; 0 gives w = 0 (pure A), 100 gives w = 1 (pure B)."""
    mv = (F32(mix_pct) - F32(50.0)) * F32(0.02)
    return (w + (F32(1.0) - w) * max(mv, F32(0.0)) - w * max(F32(0.0) - mv, F32(0.0))).astype(F32)


def blend_vel(uA, uB, phi, iface, mode, n_solver=N_SOLVER, mix_pct=50.0):
    """Blended velocity, h x w x 2 (float32). mode < 0.5: plain convex blend.
    mode >= 0.5: interface-aware (plan ADR-3): the normal component is moved toward
    the band-weighted average of the two normals, which SPREADS the normal jump over
    the band (it does not remove it: spec, Settled model).
    The weight uses blend_weight(phi); the gradient is taken on whatever grid phi is on."""
    w = blend_weight(phi)[..., None]
    wm = mix_bias(w, mix_pct)
    up = ((F32(1.0) - wm) * uA + wm * uB).astype(F32)
    if mode < 0.5:
        return up
    gx, gy = grad_phi(phi)
    mag = np.sqrt(gx * gx + gy * gy)
    eps = F32(iface) / F32(n_solver)
    s = smoothstep(S_LO, S_HI, mag * eps)
    inv = np.where(mag > F32(1e-12), F32(1.0) / np.maximum(mag, F32(1e-12)), F32(0.0)).astype(F32)
    nxv, nyv = gx * inv, gy * inv
    un_plain = nxv * up[..., 0] + nyv * up[..., 1]
    ubar = F32(0.5) * ((nxv * uA[..., 0] + nyv * uA[..., 1]) + (nxv * uB[..., 0] + nyv * uB[..., 1]))
    corr = s * (un_plain - ubar)
    out = np.stack([up[..., 0] - corr * nxv, up[..., 1] - corr * nyv], -1)
    return out.astype(F32)


def pack_phi(phi):
    """phi -> the DFT input packing (phi, 0, phi^3, 0)."""
    phi = phi.astype(F32)
    out = np.zeros(phi.shape + (4,), F32)
    out[..., 0] = phi
    out[..., 2] = phi * phi * phi
    return out


def free_energy(phi, iface):
    """Discrete-domain Ginzburg-Landau energy of phi (float64, spectral gradient):
    mean(1/4 (phi^2 - 1)^2) + kappa/2 mean(|grad phi|^2). Test helper, not a stage."""
    phi = np.asarray(phi, np.float64)
    n = phi.shape[0]
    k = 2 * np.pi * np.fft.fftfreq(n, 1.0 / n)
    k[n // 2] = 0.0 if n % 2 == 0 else k[n // 2]
    f = np.fft.fft2(phi)
    gx = np.real(np.fft.ifft2(1j * k[None, :] * f))
    gy = np.real(np.fft.ifft2(1j * k[:, None] * f))
    kap = kappa_of(iface, n)
    return float(np.mean(0.25 * (phi * phi - 1.0) ** 2) + 0.5 * kap * np.mean(gx * gx + gy * gy))


# ------------------------------------------------------------------- stages

def pass_stage(state, reseed, salt, fill, amp=None):
    """Hold phi, or re-seed fill + amp*(2h - 1). Reseeds ONLY on `reseed` or non-finite
    values: a uniform phi = +-1 is a legitimate stable state (FR-010, no zero-heal)."""
    amp = RESEED_AMP if amp is None else amp
    h, w = state.shape[:2]
    _, _, cx, cy = grid(h, w)
    phi = state[..., 0]
    bad = ~np.isfinite(phi)
    seeded = F32(fill) + F32(amp) * (F32(2.0) * hash01(cx, cy, salt) - F32(1.0))
    use = bad | (reseed >= 0.5)
    out = np.zeros((h, w, 4), F32)
    out[..., 0] = np.where(use, seeded, phi)
    return store_float32(out)


def inab(A, B, taps, src_a=1.0, src_b=1.0, n=N_SOLVER):
    """Stage 0. Decode, content-gate (|B - 0.5| < 0.25 at the centre tap) and minify
    both velocity vecfields into one packed n x n texture. An unconnected or invalid
    input (vs_black has B = 0) reads as ZERO velocity, never as vs_black's decoded -1."""
    nx, ny, _, _ = grid(n, n)
    out = np.zeros((n, n, 4), F32)
    for off, tex, src in ((0, A, src_a), (2, B, src_b)):
        if tex is None or src < 0.5:
            continue
        f = sample(tex, nx, ny)
        fx, fy = fm.force_taps(tex, taps, n, n)
        valid = (np.abs(f[..., 2] - F32(0.5)) < F32(0.25)).astype(F32)
        out[..., off] = (fx - F32(0.5)) * F32(2.0) * valid
        out[..., off + 1] = (fy - F32(0.5)) * F32(2.0) * valid
    return store_float32(out)


def adv(state, uab, src, p):
    """Stage 3. Blend velocities by phi, backward-advect phi by it, inject from the
    source luma (phi += inject^3 * ramp(luma) * (1 - phi): bounded, phase B only; ramp is a
    smoothstep from thresh to thresh + THRESH_W), clamp, pack.
    """
    h, w = state.shape[:2]
    phi = state[..., 0]
    nx, ny, _, _ = grid(h, w)
    u = blend_vel(uab[..., 0:2], uab[..., 2:4], phi, p.iface, p.blend, mix_pct=p.mix_pct)
    a = fm.interp(state, nx - u[..., 0] * F32(p.dt), ny - u[..., 1] * F32(p.dt))
    newphi = a[..., 0]
    if src is not None and p.src_phi >= 0.5 and p.inject != 0:
        s = tap_avg(src, p.taps, h, w)
        luma = F32(0.2126) * s[..., 0] + F32(0.7152) * s[..., 1] + F32(0.0722) * s[..., 2]
        tt = np.clip((luma - F32(p.thresh)) / F32(THRESH_W), F32(0.0), F32(1.0)).astype(F32)
        ramp = tt * tt * (F32(3.0) - F32(2.0) * tt)
        newphi = newphi + F32(p.inject) ** 3 * ramp * (F32(1.0) - newphi)
    newphi = np.clip(newphi, -F32(PHI_CLAMP), F32(PHI_CLAMP)).astype(F32)
    return store_float32(pack_phi(newphi))


def spec_factor(k2, mdt, kappa, a):
    """Per-bin factors of the stabilised semi-implicit Cahn-Hilliard step (ADR-2):
        phi-hat' = fa * phi-hat + fn * (phi^3)^
        fa = (1 + x (a + 1)) / (1 + x (a + kappa k^2)),   fn = -x / (1 + x (a + kappa k^2)),
        x = mdt * k^2.   At k = 0: fa = 1, fn = 0, so the mean is conserved exactly."""
    x = F32(mdt) * k2
    den = F32(1.0) + x * (F32(a) + F32(kappa) * k2)
    fa = (F32(1.0) + x * (F32(a) + F32(1.0))) / den
    fn = -x / den
    return fa.astype(F32), fn.astype(F32)


def spec(tex, p):
    """Stage 4. R,G = phi-hat, B,A = (phi^3)^ in; R,G = phi-hat' out, B,A zero.
    """
    h, w = tex.shape[:2]
    _, _, k2, _, _ = fm.wavenumbers(h, w)
    mdt = coarsen_to_mdt(p.coarsen)
    fa, fn = spec_factor(k2, mdt, kappa_of(p.iface, h), A_STAB)
    out = np.zeros_like(tex)
    out[..., 0] = fa * tex[..., 0] + fn * tex[..., 2]
    out[..., 1] = fa * tex[..., 1] + fn * tex[..., 3]
    # pull: relax ONLY the k = 0 bin (phi-hat(0) = h*w*mean) toward fill
    pe = F32(PULL_MAX) * F32(p.pull) ** 3
    out[0, 0, 0] += pe * (F32(p.fill) * F32(h * w) - tex[0, 0, 0])
    return store_float32(out)


def ix_cleanup(tex):
    """Stage 6 tail. Keep the real part of phi, zap non-finite values."""
    out = np.zeros_like(tex)
    x = tex[..., 0]
    out[..., 0] = np.where(np.isfinite(x), x, F32(0.0))
    return store_float32(out)


def enc(state, uab, p, size):
    """Stage 9 (render resolution `size` = (h, w)). Periodic bilinear upsample of phi
    and both velocities, blend, encode. bypass_gate mixes both outlets to neutral
    (out0 mid grey, out1 the neutral vecfield), spec G5 as planned.
    Returns (out0, out1)."""
    h, w = size
    nx, ny, _, _ = grid(h, w)
    phi = fm.interp(state, nx, ny)[..., 0]
    u4 = fm.interp(uab, nx, ny)
    u = blend_vel(u4[..., 0:2], u4[..., 2:4], phi, p.iface, p.blend, mix_pct=p.mix_pct)
    half = F32(0.5)
    wv = blend_weight(phi)
    o0 = np.zeros((h, w, 4), F32)
    o0[..., 0] = o0[..., 1] = o0[..., 2] = wv
    o0[..., 3] = F32(1.0)
    o1 = np.zeros((h, w, 4), F32)
    o1[..., 0] = half + half * np.clip(u[..., 0], -1, 1)
    o1[..., 1] = half + half * np.clip(u[..., 1], -1, 1)
    o1[..., 2] = half
    o1[..., 3] = F32(1.0)
    neut = fm.neutral(h, w)
    return store_float32(fm.mix(o0, neut, p.bypass_gate)), store_float32(fm.mix(o1, neut, p.bypass_gate))


# -------------------------------------------------------------------- step

def _ffts(fft):
    return (fm.fft2_np, fm.ifft2_np) if fft == "np" else (fm.fft2_passes, fm.ifft2_passes)


def step(state, A, B, src, p, fft="np"):
    """One frame of the solver: inab -> adv -> fx -> fy -> spec -> iy -> ix.
    A, B: render-res f_vecfield textures or None; src: render-res texture or None.
    Returns the new phi state."""
    fwd, inv = _ffts(fft)
    n = state.shape[0]
    uab = inab(A, B, p.taps, p.src_a, p.src_b, n)
    a = adv(state, uab, src, p)
    return ix_cleanup(inv(spec(fwd(a), p)))


def spectral_step(state, p, fft="np"):
    """The spec stage alone between the FFTs (no advection, no injection): isolates stage 4."""
    fwd, inv = _ffts(fft)
    return ix_cleanup(inv(spec(fwd(pack_phi(state[..., 0])), p)))


def outputs(state, A, B, p, size):
    """The two outlets for a given state (what enc would render this frame)."""
    n = state.shape[0]
    return enc(state, inab(A, B, p.taps, p.src_a, p.src_b, n), p, size)


def seed(n, p, salt=0):
    """A fresh phi state: fill + noise (what reset does on load)."""
    return pass_stage(np.zeros((n, n, 4), F32), 1.0, salt, p.fill)


def phi_state(phi):
    """Wrap a 2-D phi array as a state texture."""
    s = np.zeros(np.shape(phi) + (4,), F32)
    s[..., 0] = np.asarray(phi, F32)
    return s
