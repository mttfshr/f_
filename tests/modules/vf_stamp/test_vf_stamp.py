"""test_vf_stamp.py -- tier-1 tests for the not-yet-built f_vf_stamp module (T009, SC-001 to SC-004).

Ground truth is independent of the mirror: closed forms from the spec (smoothstep regions, idle
exactness, linearity, mask zero, G2 ink, G5 bypass) and identities of the difference stencil. A
central difference is an exact discrete gradient on a periodic grid, so the rotated field has
zero discrete divergence and the unrotated one zero discrete curl, up to float32 rounding; across
a clean 0-to-1 edge the "diff" field integrates to exactly 2 * reach.

The "unit" field (plan ADR-4) is not held to those identities: its numbers are compared in
vf_stamp_bands.py (T010). What must hold for whichever field T003 picks is checked for both.

Run:  tests/run.sh -q tests/modules/vf_stamp/test_vf_stamp.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_stamp_mirror import (F32, decode, disc, hash2, project, rim_texels,  # noqa: E402
                             stamp_stage, value_noise)

N = 64
FIELDS = (("diff", 1), ("diff", 4), ("unit", 1))
BUGS = ("inward", "clamp_edge", "value_flag", "ink_no_env", "swap_luma")


def flat(level, n=N):
    t = g.texture(n, n)
    t[..., 0:3] = level
    t[..., 3] = 1
    return t


def ramp_tex(n=N):
    """Luma ramp along x, 0 at the left to 1 at the right."""
    nx = g.grid(n, n)[0]
    t = g.texture(n, n)
    t[..., 0:3] = nx[..., None]
    t[..., 3] = 1
    return t


def vec_tex(vx, vy, n=N):
    t = g.texture(n, n)
    t[..., 0] = F32(vx) * F32(0.5) + F32(0.5)
    t[..., 1] = F32(vy) * F32(0.5) + F32(0.5)
    t[..., 2] = 0.5
    t[..., 3] = 1
    return t


def test_coverage_regions():
    """SC-001: 0 below the band, 1 above, the smoothstep value at its midpoint and quarter."""
    th, so = 0.5, 0.2
    for level, want in ((0.2, 0.0), (0.39, 0.0), (0.61, 1.0), (0.9, 1.0), (0.5, 0.5), (0.45, 0.15625)):
        o0, _ = stamp_stage(flat(level), threshold=th, softness=so)
        check(f"cov at luma {level}", abs(float(o0[3, 3, 0]) / level - want), 1e-3)


def test_invert_and_hard_edge():
    o, _ = stamp_stage(flat(0.3), threshold=0.5, softness=0.1, invert=1)
    check("invert covers below threshold", abs(float(o[0, 0, 0]) - 0.3), 1e-6)
    o, _ = stamp_stage(flat(0.7), threshold=0.5, softness=0.1, invert=1)
    check("invert uncovers above threshold", abs(float(o[0, 0, 0])), 0)
    lo, _ = stamp_stage(flat(0.49), threshold=0.5, softness=0.0)
    hi, _ = stamp_stage(flat(0.51), threshold=0.5, softness=0.0)
    check("softness 0 below", abs(float(lo[0, 0, 0])), 0)
    check("softness 0 above", abs(float(hi[0, 0, 0]) - 0.51), 1e-6)
    check("softness 0 finite", float(np.isfinite(lo).all() and np.isfinite(hi).all()) - 1, 0)


def test_luma_is_rec709():
    """G7: a colour whose Rec.709 and Rec.601 lumas fall either side of the threshold."""
    t = g.texture(N, N)
    t[..., 2] = 1  # pure blue: 0.0722 (709), 0.114 (601)
    t[..., 3] = 1
    o, _ = stamp_stage(t, threshold=0.09, softness=0.0)
    check("pure blue uncovered at 0.09 under Rec.709", abs(float(o[0, 0, 2])), 0)
    o, _ = stamp_stage(t, threshold=0.06, softness=0.0)
    check("pure blue covered at 0.06 under Rec.709", abs(float(o[0, 0, 2]) - 1), 1e-6)


def test_ink_encoding():
    """G2: RGB masked and scaled, A = 1 everywhere, in the disc and outside it."""
    t = disc(N, rgb=(0.8, 0.4, 0.2))
    o, _ = stamp_stage(t, threshold=0.1, softness=0.02, amount=0.5, env=0.5)
    want = np.array([0.2, 0.1, 0.05], np.float32)
    check("ink in the disc", float(np.abs(o[32, 32, 0:3] - want).max()), 1e-6)
    check("ink zero outside", float(np.abs(o[1, 1, 0:3]).max()), 0)
    check("alpha is 1", float(np.abs(o[..., 3] - 1).max()), 0)


def test_idle_exact():
    """SC-002: env 0 gives exactly (0, 0, 0, 1) and (0.5, 0.5, 0.5, 1), in every mode."""
    t = disc(N)
    for kw in (dict(), dict(impulse=1), dict(src_vec=1, in1=vec_tex(0.7, -0.3)), dict(field="unit")):
        o0, o1 = stamp_stage(t, env=0.0, **kw)
        check(f"idle ink {sorted(kw)}", float(np.abs(o0 - np.array([0, 0, 0, 1], np.float32)).max()), 0)
        check(f"idle impulse {sorted(kw)}", float(np.abs(o1 - np.array([0.5, 0.5, 0.5, 1], np.float32)).max()), 0)


def test_patched_field_masked_and_linear():
    """US2, SC-003: in1 masked by cov, linear in force and env, neutral where cov = 0."""
    t = disc(N)
    v = vec_tex(0.6, -0.4)
    _, o = stamp_stage(t, v, src_vec=1, force=0.5, env=0.5)
    vx, vy = decode(o)
    check("in the disc x", abs(float(vx[32, 32]) - 0.15), 1e-6)
    check("in the disc y", abs(float(vy[32, 32]) + 0.1), 1e-6)
    check("neutral outside x", abs(float(o[1, 1, 0]) - 0.5), 0)
    check("neutral outside y", abs(float(o[1, 1, 1]) - 0.5), 0)
    _, o2 = stamp_stage(t, v, src_vec=1, force=1.0, env=0.5)
    _, o3 = stamp_stage(t, v, src_vec=1, force=0.5, env=1.0)
    a = decode(o)[0]
    check("linear in force", float(np.abs(decode(o2)[0] - 2 * a).max()), 1e-6)
    check("linear in env", float(np.abs(decode(o3)[0] - 2 * a).max()), 1e-6)
    _, r = stamp_stage(t, v, src_vec=1, impulse=0.0)
    _, s = stamp_stage(t, v, src_vec=1, impulse=1.0)
    check("impulse switch inert when connected", float(np.abs(r - s).max()), 0)


def test_flag_not_value():
    """FR-005: an empty in1 reads vs_black; only the flag decides, so nothing decodes to -1."""
    t = disc(N)
    _, a = stamp_stage(t, None, src_vec=0)
    _, b = stamp_stage(t, flat(0.0), src_vec=0)
    check("vs_black on in1 is ignored", float(np.abs(a - b).max()), 0)
    check("centre of the disc is neutral", abs(float(a[32, 32, 0]) - 0.5), 0)


def test_radial_outward_and_swirl_rotated():
    """SC-004: both candidates point outward on the rim; swirl is radial rotated by (-y, x)."""
    t = disc(N, r=0.25, ramp=0.1)
    nx, ny, _, _ = g.grid(N, N)
    px, py = nx - F32(0.5), ny - F32(0.5)
    for field, reach in FIELDS:
        _, r = stamp_stage(t, field=field, reach=reach)
        _, s = stamp_stage(t, impulse=1, field=field, reach=reach)
        rx, ry = decode(r)
        sx, sy = decode(s)
        m = np.hypot(rx, ry) > 0.02
        dot = (rx * px + ry * py)[m]
        check(f"{field} s={reach}: rim is non-empty", float(m.sum() == 0), 0)
        check(f"{field} s={reach}: every rim texel outward", float((dot <= 0).sum()), 0)
        check(f"{field} s={reach}: swirl x = -radial y", float(np.abs(sx + ry).max()), 1e-6)
        check(f"{field} s={reach}: swirl y = radial x", float(np.abs(sy - rx).max()), 1e-6)


def test_diff_identities():
    """The diff field: exactly curl-free radial, exactly divergence-free swirl, irregular edge too."""
    for edge in (0.0, 0.3):
        t = disc(N, r=0.25, ramp=0.1)
        for reach in (1, 4):
            _, r = stamp_stage(t, field="diff", reach=reach, edge_amt=edge, seed=3)
            _, s = stamp_stage(t, field="diff", reach=reach, edge_amt=edge, seed=3, impulse=1)
            # the identities hold for a stencil of the same reach; encode rounds, hence the tolerance
            rx, ry = decode(r)
            sx, sy = decode(s)
            sd = (np.roll(sx, -reach, 1) - np.roll(sx, reach, 1)) + (np.roll(sy, -reach, 0) - np.roll(sy, reach, 0))
            rc = (np.roll(ry, -reach, 1) - np.roll(ry, reach, 1)) - (np.roll(rx, -reach, 0) - np.roll(rx, reach, 0))
            check(f"swirl divergence, s={reach} edge={edge}", float(np.abs(sd).max()), 1e-5)
            check(f"radial curl, s={reach} edge={edge}", float(np.abs(rc).max()), 1e-5)


def test_diff_rim_integral():
    """Across a clean 0-to-1 edge the diff field sums to 2 * reach, whatever the softness."""
    nx = g.grid(N, N)[0]
    t = g.texture(N, N)
    t[..., 0:3] = (np.abs(nx - F32(0.5)) < F32(0.25)).astype(F32)[..., None]
    t[..., 3] = 1
    for softness in (0.02, 0.3):
        for reach in (1, 4):
            _, r = stamp_stage(t, softness=softness, reach=reach)
            rx = decode(r)[0][5]
            check(f"rim integral s={reach} softness={softness}", abs(float(rx[N // 2:].sum()) - 2 * reach), 1e-4)


def test_rim_is_in_frame_units():
    """T003: the rim's strength in frame units is 2 * rim at any render size, and rim bottoms out at 1 texel."""
    rim = 1 / 16
    for n in (64, 256):
        nx = g.grid(n, n)[0]
        t = g.texture(n, n)
        t[..., 0:3] = (np.abs(nx - F32(0.5)) < F32(0.25)).astype(F32)[..., None]
        t[..., 3] = 1
        rx = decode(stamp_stage(t, rim=rim)[1])[0][5]
        check(f"rim integral at N={n}", abs(float(rx[n // 2:].sum()) / n - 2 * rim), 1e-5)
    check("default rim is 4 texels at 256", abs(rim_texels(0.015, 256) - 4), 0)
    check("rim never reaches 0 texels", abs(rim_texels(0.001, 64) - 1), 0)


def test_periodic_wrap():
    """SC-004: a disc across the corner gives the centred disc's field, shifted (FR-010)."""
    a = disc(N, cx=0.5, cy=0.5, r=0.2, ramp=0.08)
    b = disc(N, cx=0.0, cy=0.0, r=0.2, ramp=0.08)
    for field, reach in FIELDS:
        _, oa = stamp_stage(a, field=field, reach=reach)
        _, ob = stamp_stage(b, field=field, reach=reach)
        shifted = np.roll(oa, (-N // 2, -N // 2), (0, 1))
        check(f"wrap {field} s={reach}", float(np.abs(shifted - ob).max()), 1e-5)


def test_non_square():
    """ADR-7: steps are per texel in each axis on a non-square render target."""
    t = disc(N, r=0.25, ramp=0.1)
    _, o = stamp_stage(t, size=(48, 96))
    rx, ry = decode(o)
    check("shape", float(o.shape != (48, 96, 4)), 0)
    check("left rim points left", float(rx[24, :48].min() < -0.01) - 1, 0)
    check("right rim points right", float(rx[24, 48:].max() > 0.01) - 1, 0)


def test_noise():
    """Range, determinism, seed sensitivity, and edge = 0 exactly removing it."""
    _, _, ix, iy = g.grid(128, 128)
    a = value_noise(ix, iy, 128, 128, 1)
    check("noise in range", float(np.abs(a).max() > 0.5), 0)
    check("noise deterministic", float(np.abs(a - value_noise(ix, iy, 128, 128, 1)).max()), 0)
    check("seed changes it", float(np.abs(a - value_noise(ix, iy, 128, 128, 2)).max() < 0.05), 0)
    check("noise is not constant", float(a.std() < 0.02), 0)
    note("noise mean", float(a.mean()))
    note("noise std", float(a.std()))
    h = hash2(np.arange(256, dtype=F32)[:, None], np.arange(256, dtype=F32)[None, :])
    check("hash in [0, 1)", float((h < 0).any() or (h >= 1).any()), 0)
    note("hash mean", float(h.mean()))
    t = ramp_tex()
    o0, _ = stamp_stage(t, edge_amt=0.0, seed=1)
    o1, _ = stamp_stage(t, edge_amt=0.0, seed=2)
    check("edge 0 ignores the seed", float(np.abs(o0 - o1).max()), 0)


def test_non_finite():
    """FR-011: NaN and Inf in either inlet reach neither outlet, bypassed or not."""
    t = disc(N)
    t[10, 10, 0] = np.nan
    t[32, 32, 1] = np.inf
    t[20, 40, 3] = np.nan
    v = vec_tex(0.5, 0.5)
    v[32, 33, 0] = np.nan
    v[33, 32, 1] = -np.inf
    for kw in (dict(), dict(src_vec=1), dict(bypass_gate=1), dict(bypass_gate=1, src_vec=1), dict(field="unit")):
        o0, o1 = stamp_stage(t, v, **kw)
        check(f"finite {sorted(kw)}", float((~np.isfinite(o0)).sum() + (~np.isfinite(o1)).sum()), 0)


def test_bypass():
    """G5: out0 = in0, out1 = in1 when connected else neutral; gate and envelope ignored."""
    t = disc(N, rgb=(0.8, 0.4, 0.2))
    v = vec_tex(0.6, -0.4)
    o0, o1 = stamp_stage(t, v, src_vec=1, bypass_gate=1, env=0.0)
    check("out0 is in0", float(np.abs(o0 - t).max()), 0)
    check("out1 is in1", float(np.abs(o1 - v).max()), 0)
    o0, o1 = stamp_stage(t, None, src_vec=0, bypass_gate=1, env=1.0)
    check("out1 neutral with in1 empty", float(np.abs(o1 - np.array([0.5, 0.5, 0.5, 1], np.float32)).max()), 0)


def test_helmholtz_prediction():
    """The curl constraint in numbers (N = 64): project removes most of radial, keeps most of swirl.
    Not all: the spectral projection uses the true k, the stencil's gradient direction is
    (sin kx s, sin ky s), and the two part at high k. 7% of the energy leaks here; the 0.15 bound
    is that observed leak with margin (T010 has the numbers), not a closed form."""
    t = disc(N, r=0.25, ramp=0.1)
    _, r = stamp_stage(t, reach=2)
    _, s = stamp_stage(t, reach=2, impulse=1)
    for name, o, want_low in (("radial", r, True), ("swirl", s, False)):
        vx, vy = decode(o)
        px, py = project(vx, vy)
        kept = float((px ** 2 + py ** 2).sum() / (vx ** 2 + vy ** 2).sum())
        note(f"{name} energy kept by project", kept)
        check(f"{name} survival", kept if want_low else 1 - kept, 0.15)


def test_mutations():
    """Each plausible mistake changes the output the checks above look at."""
    t = disc(N, cx=0.0, cy=0.0, r=0.2, ramp=0.08, rgb=(0.0, 0.0, 1.0))
    u = disc(N, cx=0.0, cy=0.0, r=0.2, ramp=0.08)
    seam = g.texture(N, N)  # an edge exactly on the frame border: only a wrapped neighbour sees it
    seam[..., 0:3] = (g.grid(N, N)[0] < F32(0.5)).astype(F32)[..., None]
    seam[..., 3] = 1
    for bug in BUGS:
        src = {"swap_luma": t, "clamp_edge": seam}.get(bug, u)
        kw = dict(threshold=0.09, softness=0.0) if bug == "swap_luma" else dict(env=0.5)
        a = stamp_stage(src, **kw)
        b = stamp_stage(src, bug=bug, **kw)
        err = max(float(np.abs(a[0] - b[0]).max()), float(np.abs(a[1] - b[1]).max()))
        note(f"mutation '{bug}' worst error", err)
        check(f"mutation caught: {bug}", float(err <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
