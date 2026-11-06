"""
bench_vf_stamp.py -- f_vf_stamp T024: src/f_vf_stamp/codebox_stamp.gen on the GPU through the codebox bench, diffed against
vf_stamp_mirror.stamp_stage. One pass per job, three inputs: a bang stand-in, the stamp, the vecfield.

Every Param is pinned in every job (the bench keeps a Param's last value). Each Param without precedent as a codebox name
(`env`, `amount`, `impulse`, `rim`, `invert`) gets a row showing that a message changes the output.

Tolerances:
  TOL  1:1 reads at texel centres are exact, so what is left is float32 rounding in the smoothstep and the encode.
  TOL_RESAMPLE  a stamp smaller than the render: the hardware's 8-bit interpolation weights (1.2e-4 per read at worst,
       jit-gen-codebox) times the smoothstep's slope, 1.5 / softness = 5 at softness 0.3.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/vf_stamp/bench_vf_stamp.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 161            # integers only

import paths as _paths
import sys

import numpy as np

import benchclient as bc
import gpu_sim as g
from harness import check, note, run
from vf_stamp_mirror import F32, disc, stamp_stage

CODE = (_paths.REPO / "src" / "f_vf_stamp" / "codebox_stamp.gen").read_text()
N = 128
BANG = np.zeros((4, 4, 4), np.float32)          # stand-in for the `r draw` bang inlet
TOL = 1e-5
TOL_RESAMPLE = 2e-3
PINNED = {"threshold": 0.05, "softness": 0.1, "invert": 0.0, "amount": 1.0, "force": 1.0, "impulse": 0.0, "rim": 0.015,
          "env": 1.0, "src_stamp": 1.0, "src_vec": 0.0, "bypass_gate": 0.0}


def blank(h=N, w=N):
    """An unconnected inlet: black, A = 0 stands for vs_black in the mirror."""
    return np.zeros((h, w, 4), np.float32)


def gpu(stamp, field=None, dim=None, **deltas):
    """Both outlets of one pass. dim = (w, h), the render size; default the stamp's own."""
    h, w = (dim[1], dim[0]) if dim else stamp.shape[:2]
    params = dict(PINNED, width=float(w), height=float(h))
    params.update(deltas)
    outs, r = bc.run_pass(CODE, [BANG, stamp, field if field is not None else blank(h, w)], dim=(w, h), params=params,
                          timeout_ms=30000, all_outputs=True)
    if r["status"] != "ok" or outs[0] is None or outs[1] is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs[0], outs[1]


def mirror(stamp, field=None, dim=None, **deltas):
    p = dict(PINNED)
    p.update(deltas)
    size = (dim[1], dim[0]) if dim else None
    return stamp_stage(stamp, in1=field, size=size, **p)


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def both(label, stamp, field=None, dim=None, tol=TOL, **deltas):
    """GPU against the mirror on both outlets."""
    a, b = gpu(stamp, field, dim, **deltas)
    wa, wb = mirror(stamp, field, dim, **deltas)
    check(f"{label}: ink vs mirror", mx(a, wa), tol)
    check(f"{label}: impulse vs mirror", mx(b, wb), tol)
    return a, b


def blob(h, w):
    """A coloured stamp with a soft edge, off centre, on a non-square grid."""
    nx, ny, _, _ = g.grid(h, w)
    m = np.clip(1.5 - 6 * np.sqrt((nx - F32(0.4)) ** 2 + (ny - F32(0.55)) ** 2), 0, 1).astype(F32)
    t = g.texture(h, w)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = m, m * F32(0.6), m * F32(0.2), 1
    return t


def field_tex(h=N, w=N):
    """A vecfield that is non-neutral everywhere, so masking shows."""
    nx, ny, _, _ = g.grid(h, w)
    t = g.texture(h, w)
    t[..., 0] = F32(0.5) + F32(0.4) * np.sin(F32(2 * np.pi) * nx)
    t[..., 1] = F32(0.5) + F32(0.3) * np.cos(F32(2 * np.pi) * ny) + F32(0.1)
    t[..., 2], t[..., 3] = 0.5, 1
    return t


def test_radial_and_swirl_vs_mirror():
    hard, soft = disc(N), disc(N, ramp=0.1)
    colour = disc(N, rgb=(0.9, 0.2, 0.1), ramp=0.05)
    for label, t in (("hard disc", hard), ("soft disc", soft), ("colour disc", colour)):
        both(f"{label}, defaults", t)
        both(f"{label}, swirl", t, impulse=1.0)
        both(f"{label}, env and gains", t, env=0.4, amount=2.5, force=0.7)
    both("wide rim", soft, rim=0.05)
    both("hard edge, softness 0", soft, softness=0.0)
    both("threshold 0, softness 0", soft, threshold=0.0, softness=0.0)
    both("softness past twice threshold (the clamped band)", soft, softness=0.3)
    both("inverted", soft, invert=1.0, softness=0.2, threshold=0.4)
    both("force past 1 clips in the encode", hard, force=2.0, rim=0.05)


def test_connected_field_vs_mirror():
    t, f = disc(N, ramp=0.05), field_tex()
    a, b = both("field connected", t, f, src_vec=1.0)
    both("field connected, gains", t, f, src_vec=1.0, env=0.6, force=1.5, amount=0.5)
    far = gpu(t, f, src_vec=1.0)[1]
    check("masked: neutral where the stamp is not (corner)", mx(far[:8, :8, :2], 0.5), 0.0)
    swirl = gpu(t, f, src_vec=1.0, impulse=1.0)[1]
    check("the impulse switch has no effect with a field connected", mx(swirl, b), 0.0)
    rim = gpu(t, f, src_vec=1.0, rim=0.05)[1]
    check("rim has no effect with a field connected", mx(rim, b), 0.0)
    both("a field present but flagged off is ignored", t, f, src_vec=0.0)


def test_flag_not_value():
    """An unconnected inlet reads as black, a -1 vector: only the flag may decide."""
    t = disc(N, ramp=0.05)
    _, ref = gpu(t, blank(), src_vec=0.0)
    _, bad = gpu(t, blank(), src_vec=1.0)
    check("control: black read as a field is a full -1 vector inside the stamp", float(mx(ref, bad) < 0.2), 0.0)


def test_empty_stamp_inlet():
    """FR-001: nothing on the main inlet stamps nothing, even inverted."""
    a, b = both("empty, inverted, field connected", blank(), field_tex(), src_stamp=0.0, src_vec=1.0, invert=1.0)
    check("ink black", mx(a[..., :3], 0.0), 0.0)
    check("impulse neutral", mx(b[..., :2], 0.5), 0.0)


def test_idle_is_exact():
    a, b = gpu(disc(N, ramp=0.05), env=0.0)
    check("env 0: ink exactly black", mx(a[..., :3], 0.0), 0.0)
    check("env 0: alpha exactly 1", mx(a[..., 3], 1.0), 0.0)
    check("env 0: impulse exactly neutral", mx(b, np.array([0.5, 0.5, 0.5, 1.0], np.float32)), 0.0)
    a, b = gpu(disc(N, ramp=0.05), field_tex(), env=0.0, src_vec=1.0)
    check("env 0, field connected: impulse exactly neutral", mx(b, np.array([0.5, 0.5, 0.5, 1.0], np.float32)), 0.0)


def test_each_param_takes_a_message():
    """The names with no precedent here. A Param that never takes its value reads as its default (`t` did)."""
    t = disc(N, ramp=0.1)
    a0, b0 = gpu(t, env=0.5)
    for label, kw, outlet in (("env", dict(env=0.9), 0), ("amount", dict(env=0.5, amount=2.0), 0),
                              ("invert", dict(env=0.5, invert=1.0), 0), ("threshold", dict(env=0.5, threshold=0.6), 0),
                              ("softness", dict(env=0.5, softness=0.9), 0), ("force", dict(env=0.5, force=0.2), 1),
                              ("impulse", dict(env=0.5, impulse=1.0), 1), ("rim", dict(env=0.5, rim=0.05), 1)):
        got = gpu(t, **kw)[outlet]
        d = mx(got, (a0, b0)[outlet])
        note(f"`{label}` moved the output by", d)
        check(f"`{label}` takes a message", float(d < 1e-3), 0.0)
    wide = gpu(t, dim=(N, N), env=1.0, width=float(N), rim=0.02)[1]
    other = gpu(t, dim=(N, N), env=1.0, width=float(2 * N), rim=0.02)[1]
    check("`width` takes a message (it sets the reach)", float(mx(wide, other) < 1e-3), 0.0)


def test_periodic_wrap():
    """A disc across the corner gives the same field as the same disc at the centre, shifted (FR-010)."""
    a = gpu(disc(N, cx=0.5, cy=0.5, ramp=0.05))[1]
    b = gpu(disc(N, cx=0.0, cy=0.0, ramp=0.05))[1]
    shifted = np.roll(a, (-N // 2, -N // 2), axis=(0, 1))
    check("the corner disc's field is the centre disc's, shifted", mx(b, shifted), TOL)
    both("the seam itself", disc(N, cx=0.0, cy=0.0))


def test_non_square_and_resampled():
    h, w = 72, 128
    both("non-square", blob(h, w), impulse=1.0)
    both("non-square, field", blob(h, w), field_tex(h, w), src_vec=1.0)
    both("a stamp smaller than the render", disc(64, ramp=0.1), dim=(N, N), tol=TOL_RESAMPLE, softness=0.3)


def test_non_finite_never_reaches_an_outlet():
    t = disc(N, ramp=0.05)
    f = field_tex()
    for arr in (t, f):
        arr[10, 10, 0], arr[11, 11, 1], arr[64, 64, 2], arr[64, 40, 0] = np.nan, np.inf, np.nan, 1e31
    for label, kw in (("running", dict(src_vec=1.0)), ("no field", dict()), ("bypassed", dict(src_vec=1.0, bypass_gate=1.0))):
        a, b = gpu(t, f, **kw)
        check(f"{label}: ink finite", float(np.count_nonzero(~np.isfinite(a))), 0.0)
        check(f"{label}: impulse finite", float(np.count_nonzero(~np.isfinite(b))), 0.0)


def test_bypass():
    t, f = disc(N, ramp=0.05, rgb=(0.8, 0.5, 0.2)), field_tex()
    t[..., 3] = 0.75
    a, b = both("bypass, field connected", t, f, bypass_gate=1.0, src_vec=1.0)
    check("the first outlet is the stamp, alpha included", mx(a, t), 0.0)
    check("the second is the field", mx(b[..., :2], f[..., :2]), 0.0)
    a, b = both("bypass, no field, gate ignored", t, bypass_gate=1.0, env=0.0)
    check("the first outlet still passes with env 0", mx(a, t), 0.0)
    check("the second is neutral", mx(b, np.array([0.5, 0.5, 0.5, 1.0], np.float32)), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
