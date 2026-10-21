"""
vf_lbm_mirror.py -- tier-1 NumPy mirror of the future f_vf_lbm solver (no codebox
exists yet; .specify/f_vf_lbm/spec.md FR-001..FR-005 + FR-008 fix the design).

Conventions (stated here because the spec is silent on both):
  - Textures are (row = y, column = x) RGBA float32 arrays, row 0 at the
    smallest norm.y, the gpu_sim convention. The reference experiment
    (inputs/f_vf_lbm/codebox_spike_lbm_d2q9_architecture.txt) indexes [x, y]
    with axis 0 = x; this mirror is the transposed image of it, verified by
    test_vf_lbm.py's wrap and streaming checks.
  - y is PERIODIC (the experiment rolls on its y axis; the spec FR-005 names
    only the x edges). gpu_sim.sample's out-of-range wrap reproduces the
    experiment's np.roll at the x seam too, because texel-centre gathers read
    at norms strictly inside (0, 1) after the coordinate wrap (e.g. reading
    x - e_x = -1 from column 0 lands at norm -0.5/W -> 1 - 0.5/W, exactly the
    last column's texel centre), so a shader gather wraps the same way and the
    branch conditions at the two x edges overwrite exactly the populations the
    wrap contaminated. test_vf_lbm.py pins this per-direction.
  - "pre-collision" (FR-003) means the state at the start of the frame, taken
    BEFORE the outflow copy, exactly as the experiment does
    (`f_prev = [fi.copy() ...]` precedes the outflow loop).

Stages (one future codebox pass each; FR-001..FR-005):
  1. fuse_local  -- fused macro + equilibrium + collision + bounce-back,
     reading the 3 state planes + obstacle mask AT THE SAME TEXEL plus the
     zero-gradient neighbour at x - 1 (outflow edge) and Zou/He inflow at
     x = 0; writes the 3 state planes.
  2. stream      -- gather streaming: population i of the new state reads
     population i of the old state at the texel displaced by -e_i
     (`new[x] = old[x - e_i]`), i.e. the SAMPLE COORDINATE offset is -e_i in
     texel units; writes the 3 state planes.
  3. encode      -- local extraction of (rho, ux, uy) from the streamed state,
     encoded per FR-008: R = clamp(0.5 + gain * ux), G = clamp(0.5 + gain * uy),
     B = 0.5, A = 1. (The spec fixes the contract, not the gain default or the
     spare channels; those are noted in the report's needs_decision.)

Everything is float32 throughout, stored through gpu_sim.store_float32 between
passes. `f_vecfield`-conformant char quantization is NOT modeled (noted in the
report; the outlet is the packed state texture, float32, in this mirror).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32

# D2Q9 lattice velocities (ex, ey), weights, opposite index -- textbook values.
E = np.array([[0, 0], [1, 0], [0, 1], [-1, 0], [0, -1],
              [1, 1], [-1, 1], [-1, -1], [1, -1]], dtype=np.int64)
W9 = np.array([4 / 9, 1 / 9, 1 / 9, 1 / 9, 1 / 9,
               1 / 36, 1 / 36, 1 / 36, 1 / 36], dtype=np.float64)
OPP = np.array([0, 3, 4, 1, 2, 7, 8, 5, 6], dtype=np.int64)
RIGHT = (1, 5, 8)   # populations with e_x = +1, overwritten at the inflow edge
LEFT = (3, 6, 7)    # populations with e_x = -1, zero-gradient at the outflow edge
PURE = (0, 2, 4)    # populations with e_x = 0, used by the Zou/He density


def equilibrium(rho, ux, uy, bug=None):
    """BGK equilibrium f_eq_i = w_i rho (1 + 3 e.u + 4.5 (e.u)^2 - 1.5 u^2),
    in float32, fully local -- one codebox's arithmetic at one texel."""
    w = W9.astype(F32).copy()
    if bug == "wrong_weight":
        w[1] = F32(4.0 / 35.0)             # a slip near 1/9 (the sums patched: w2 adjusted)
        w[2] = F32(1.0 - float(w.sum()) + w[1])
    out = []
    for i in range(9):
        eu = F32(E[i, 0]) * ux + F32(E[i, 1]) * uy
        feq = w[i] * rho * (F32(1.0) + F32(3.0) * eu
                            + F32(4.5) * eu * eu - F32(1.5) * (ux * ux + uy * uy))
        out.append(feq.astype(F32))
    return out


def macro(f):
    """rho, ux, uy from the 9 distributions -- local, one codebox pass."""
    rho = f[0].copy()
    for i in range(1, 9):
        rho = rho + f[i]
    ux = F32(0.0) * rho
    uy = F32(0.0) * rho
    for i in range(9):
        ux = ux + f[i] * F32(E[i, 0])
        uy = uy + f[i] * F32(E[i, 1])
    return rho, ux / rho, uy / rho


def pack(f):
    """9 distributions -> 3 RGBA float32 planes (FR-001)."""
    z = np.zeros_like(f[0])
    return [g.store_float32(np.stack([f[0], f[1], f[2], f[3]], -1)),
            g.store_float32(np.stack([f[4], f[5], f[6], f[7]], -1)),
            g.store_float32(np.stack([f[8], z, z, z], -1))]


def unpack(planes):
    """3 RGBA planes -> list of 9 (H, W) float32 arrays."""
    p0, p1, p2 = planes
    return [p0[..., 0], p0[..., 1], p0[..., 2], p0[..., 3],
            p1[..., 0], p1[..., 1], p1[..., 2], p1[..., 3],
            p2[..., 0]]


def fuse_local(planes, mask, omega, U0, bug=None):
    """Stage 1 (FR-002): the fused local pass. Reads the 3 state planes and
    the obstacle mask at the output texel's own coordinate; at the outflow
    edge also the state plane at x - 1 (zero gradient); at the inflow edge
    applies the Zou/He density and the inflow Dirichlet velocity. Order is
    exactly the experiment's: pre-collision copy, outflow, macro, inflow,
    equilibrium, right-population overwrite, collision, bounce-back."""
    f = unpack([p.copy() for p in planes])
    f_prev = [fi.copy() for fi in f]          # BEFORE the outflow copy
    H, W = planes[0].shape[:2]
    nx = ((np.arange(W, dtype=F32) + F32(0.5)) / F32(W))[None, :]
    ny = ((np.arange(H, dtype=F32) + F32(0.5)) / F32(H))[:, None]
    if bug == "prev_after_bc":                # a real mistake: copy after BCs
        for i in LEFT:
            f[i][:, -1] = f[i][:, -2]
        f_prev = [fi.copy() for fi in f]
    else:
        for i in LEFT:                        # zero-gradient outflow: gather
            f[i][:, -1] = g.sample(planes[i // 4], nx - F32(1.0 / W), ny)[..., i % 4][:, -1]
    rho, ux, uy = macro(f)
    # inflow at x = 0 (FR-005): Dirichlet ux on the interior rows, Zou/He rho.
    col = 0
    pure = f[PURE[0]][:, col] + f[PURE[1]][:, col] + f[PURE[2]][:, col]
    left = f[LEFT[0]][:, col] + f[LEFT[1]][:, col] + f[LEFT[2]][:, col]
    if bug == "rho_pre_dirichlet":            # density from the MEASURED ux (the 2026-10-21 mirror slip)
        rho[:, col] = (pure + F32(2.0) * left) / (F32(1.0) - ux[:, col])
        ux[1:-1, col] = F32(U0)
        uy[1:-1, col] = F32(0.0)
    else:                                     # the experiment's order: prescribe u first, then Zou/He rho
        ux[1:-1, col] = F32(U0)
        uy[1:-1, col] = F32(0.0)
        rho[:, col] = (pure + F32(2.0) * left) / (F32(1.0) - ux[:, col])
    feq = equilibrium(rho, ux, uy, bug=bug)
    for i in RIGHT:
        f[i][:, col] = feq[i][:, col]
    omega_f = F32(omega)
    for i in range(9):                        # BGK collision (local)
        f[i] = (f[i] + omega_f * (feq[i] - f[i])).astype(F32)
    f_post = f
    if bug == "bounce_post":                  # the spike's trap #2
        f_prev = [fi.copy() for fi in f_post]   # a snapshot, not an alias of the list the loop rewrites
    for i in range(9):                        # bounce-back in the mask (local swap)
        f[i] = np.where(mask, f_prev[OPP[i]], f[i]).astype(F32)
    return pack(f)


def stream(planes, bug=None):
    """Stage 2 (FR-004): the streaming gather. Population i of the new state
    reads population i of the old state at the texel displaced by -e_i
    (new[x] = old[x - e_i]); the SAMPLE COORDINATE offset is the opposite
    sign, -e_i in texel units (the brief's wording trap). Reads go through
    gpu_sim.sample, whose out-of-range wrap reproduces np.roll at the seams."""
    H, W = planes[0].shape[:2]
    nx = ((np.arange(W, dtype=F32) + F32(0.5)) / F32(W))[None, :]
    ny = ((np.arange(H, dtype=F32) + F32(0.5)) / F32(H))[:, None]
    new = []
    for i in range(9):
        tex = planes[i // 4]
        sx = F32(E[i, 0]) / F32(W)
        sy = F32(E[i, 1]) / F32(H)
        if bug == "stream_sign":              # the spike's trap #1
            sx, sy = -sx, -sy
        new.append(g.sample(tex, nx - sx, ny - sy)[..., i % 4].astype(F32))
    return pack(new)


def encode(planes, gain, bug=None):
    """Stage 3 (FR-008): extract the macro velocity from the streamed state and
    encode it (RG = XY, 0.5 = zero, gain-scaled, clamped, no NaN/Inf out)."""
    f = unpack(planes)
    rho, ux, uy = macro(f)
    if bug == "swap_rg":
        ux, uy = uy, ux
    enc = g.texture(*planes[0].shape[:2])
    enc[..., 0] = np.clip(F32(0.5) + F32(gain) * ux, F32(0.0), F32(1.0))
    enc[..., 1] = np.clip(F32(0.5) + F32(gain) * uy, F32(0.0), F32(1.0))
    enc[..., 2] = F32(0.5)
    enc[..., 3] = F32(1.0)
    return g.store_float32(enc)


def lbm_step(planes, mask, omega, U0, gain, bug=None):
    """One full frame (FR-001..FR-005, FR-008): fuse_local -> stream -> encode.
    Returns (new_planes, encoded)."""
    fused = fuse_local(planes, mask, omega, U0, bug=bug)
    streamed = stream(fused, bug=bug)
    return streamed, encode(streamed, gain, bug=bug)


def omega_from_nu(nu):
    """BGK relaxation rate omega = 1 / (3 * nu + 0.5) (the spike's formula)."""
    return F32(1.0) / (F32(3.0) * F32(nu) + F32(0.5))