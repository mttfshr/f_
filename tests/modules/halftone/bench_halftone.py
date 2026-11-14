"""
bench_halftone.py -- f_halftone T022 (codebox half): src/f_halftone/codebox_halftone.gen on the GPU through the codebox bench,
diffed against halftone_mirror.halftone_stage. One pass per job, one input (the tone texture), one outlet.

This is the first time the codebox is COMPILED: a syntax error shows as a failed job (status and errors in the message).
Written 2026-11-13 (Claude, offline) and not yet run: every tolerance below is a prediction, written before the first run.
A first run may need one recalibrated; the measured number and the reason are then recorded here, not just the new value.

Every Param is pinned in every job (the bench keeps a Param's last value). `width` and `height` are set to the output's size in
gpu(): the codebox takes the render size from them, never from the size global.

Two kinds of row, because a halftone has hard switches the two float32 implementations cannot agree on at every pixel:
  FLAT   a flat tone per channel. Every lattice cell reads the same tone, so a pixel that lands in the neighbouring cell on the
         GPU (floor(q + .5) one float32 ulp apart) still gets the same coverage: the dot is symmetric about the cell edge. Compared
         at EVERY pixel, within TOL.
  PHOTO  a picture. A pixel on a cell edge, or a tone read on a texel edge, can take its tone from the neighbouring cell or
         texel, which is a different tone and a large error at that one pixel. Compared as a fraction: at least 1 - FRAC_BAD of
         the pixels within TOL. The worst error and the fraction are noted.

Tolerances:
  TOL       2e-3. The coverage ramp is about one texel wide, so its slope against lattice position is the pitch in texels
            (at most 24 here). q is a float32 of size up to about 40 lattice units (error about 5e-6), giving about 1e-4; the
            area function's acos and sqrt differ between GLSL and NumPy by a few ulp more. 2e-3 leaves a factor of ten.
  FRAC_BAD  5e-3. Inferred: edge pixels are a thin set (cell edges are 2 / pitch-in-texels of the pixels, and only those within
            a float32 ulp of the edge can flip). Expected far below this; the first run records the real fraction.
  Exact rows (tolerance 0 or 1e-6): the extremes, plate independence, bypass, alpha.

Gates measured here: G8 / T010 (reads inside a function and a loop; sample() against nearest() at texel centres) and G5 / T007
(the area law against pitch in texels, GPU beside the mirror).

Not here: non-finite input (the bench's input path for NaN is unproven, and the mirror tests the zap); shape, jitter, Threshold,
Bayer and Single (not in the codebox yet); the shipped patcher (bench_halftone_module.py).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/modules/halftone/bench_halftone.py       (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 172            # integers only

import paths as _paths
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run, slow
from halftone_mirror import F32, halftone_stage

CODE = (_paths.REPO / "src" / "f_halftone" / "codebox_halftone.gen").read_text()
W, H = 128, 128
TOL = 2e-3
FRAC_BAD = 5e-3
PITCH = 16.0 / H       # 16 texels
PINNED = {"screen": 0.0, "pitch": PITCH, "angle_r": 15.0, "angle_g": 75.0, "angle_b": 45.0,
          "phase_r_x": 0.0, "phase_r_y": 0.0, "phase_g_x": 0.0, "phase_g_y": 0.0, "phase_b_x": 0.0, "phase_b_y": 0.0,
          "softness": 0.0, "bypass_gate": 0.0}
SCREENS = {0: "dot", 1: "line"}


def flat(r, g, b, w=W, h=H, seed=2):
    t = np.zeros((h, w, 4), np.float32)
    t[..., 0], t[..., 1], t[..., 2] = r, g, b
    t[..., 3] = np.random.default_rng(seed).uniform(0.2, 1, (h, w))
    return t


def photo(w=W, h=H, seed=4):
    """Smooth blobs in 0..1, a different one per channel, with a hard-edged patch and a few out-of-range texels."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    t = np.zeros((h, w, 4), np.float32)
    for c in range(3):
        acc = np.zeros((h, w), np.float32)
        for _ in range(4):
            fx, fy, ph = rng.uniform(0.5, 2.5), rng.uniform(0.5, 2.5), rng.uniform(0, 6.28)
            acc += np.sin(6.2832 * (fx * xx / w + fy * yy / h) + ph).astype(np.float32)
        t[..., c] = 0.5 + 0.12 * acc
    t[..., :3] = np.clip(t[..., :3], 0.02, 0.98)
    t[h // 4:h // 2, w // 4:w // 2, :3] = 0.8
    t[0, :4, :3] = 1.6
    t[1, :4, :3] = -0.3
    t[..., 3] = rng.uniform(0.2, 1, (h, w))
    return t


def gpu(src, code=CODE, **deltas):
    h, w = src.shape[:2]
    params = dict(PINNED)
    params.update(deltas)
    params["width"], params["height"] = float(w), float(h)
    outs, r = bc.run_pass(code, [src], dim=(w, h), params=params, timeout_ms=30000, all_outputs=True)
    if r["status"] != "ok" or outs[0] is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs[0]


def mirror(src, **deltas):
    p = dict(PINNED)
    p.update(deltas)
    return halftone_stage(src, screen=SCREENS[int(p["screen"])], pitch=p["pitch"],
                          angles=(p["angle_r"], p["angle_g"], p["angle_b"]),
                          phases=((p["phase_r_x"], p["phase_r_y"]), (p["phase_g_x"], p["phase_g_y"]),
                                  (p["phase_b_x"], p["phase_b_y"])),
                          softness=p["softness"], bypass=bool(p["bypass_gate"]))


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def everywhere(label, src, tol=TOL, **deltas):
    got, want = gpu(src, **deltas), mirror(src, **deltas)
    worst = mx(got[..., :3], want[..., :3])
    note(f"{label}: worst rgb error", worst)
    check(f"{label}: rgb vs mirror at every pixel", worst, tol)
    check(f"{label}: alpha is the source's", mx(got[..., 3], src[..., 3]), 1e-6)
    return got


def mostly(label, src, **deltas):
    got, want = gpu(src, **deltas), mirror(src, **deltas)
    err = np.abs(got[..., :3].astype(np.float64) - want[..., :3].astype(np.float64))
    bad = float((err > TOL).mean())
    note(f"{label}: worst rgb error (edge pixels may flip cells)", float(err.max()))
    note(f"{label}: fraction of values beyond {TOL}", bad)
    check(f"{label}: fraction beyond tolerance", bad, FRAC_BAD)
    check(f"{label}: alpha is the source's", mx(got[..., 3], src[..., 3]), 1e-6)
    return got


def test_compile_and_flat_tones():
    """The first check: the codebox compiles, and Dot and Line match the mirror on flat tones at every pixel."""
    t = flat(0.3, 0.5, 0.8)
    for s, name in SCREENS.items():
        got = everywhere(f"{name}, flat 0.3 / 0.5 / 0.8", t, screen=float(s))
        for c, tone in enumerate((0.3, 0.5, 0.8)):
            note(f"{name}: mean coverage minus tone {tone}", float(got[..., c].mean()) - tone)
    everywhere("dot, softness 0.5", t, softness=0.5)
    everywhere("line, softness 0.5", t, screen=1.0, softness=0.5)


def test_extremes_are_exact():
    for s, name in SCREENS.items():
        got = gpu(flat(0.0, 1.0, 1.6), screen=float(s), softness=0.3)
        check(f"{name}: tone 0 gives exactly 0", float(np.abs(got[..., 0]).max()), 0.0)
        check(f"{name}: tone 1 gives exactly 1", float(np.abs(got[..., 1] - 1.0).max()), 0.0)
        check(f"{name}: tone 1.6 gives exactly 1", float(np.abs(got[..., 2] - 1.0).max()), 0.0)
        got = gpu(flat(-0.3, 0.5, 0.5), screen=float(s))
        check(f"{name}: tone -0.3 gives exactly 0", float(np.abs(got[..., 0]).max()), 0.0)


def test_grid_angles():
    """0, 45 and 90 degrees (gate G6): the codebox snaps cos and sin below 1e-6 to 0, the mirror uses exact quarter turns."""
    t = flat(0.35, 0.35, 0.35)
    for s, name in SCREENS.items():
        everywhere(f"{name}, angles 0 / 90 / 45", t, screen=float(s), angle_r=0.0, angle_g=90.0, angle_b=45.0)
        everywhere(f"{name}, angles 180 / 135 / 30", t, screen=float(s), angle_r=180.0, angle_g=135.0, angle_b=30.0)


def test_picture():
    t = photo()
    for s, name in SCREENS.items():
        mostly(f"{name}, picture", t, screen=float(s))
        mostly(f"{name}, picture, softness 0.2", t, screen=float(s), softness=0.2)
    got = gpu(t)
    check("output within 0..1", max(-float(got[..., :3].min()), float(got[..., :3].max()) - 1.0, 0.0), 1e-6)


def test_non_square_frame():
    """160 x 96: the lattice must stay square-spaced and the tone reads must land on the right texels."""
    everywhere("dot, 160 x 96, flat", flat(0.3, 0.5, 0.8, 160, 96), pitch=16.0 / 96)
    mostly("dot, 160 x 96, picture", photo(160, 96), pitch=16.0 / 96)
    mostly("line, 160 x 96, picture", photo(160, 96), pitch=16.0 / 96, screen=1.0)


def test_phase_and_plate_independence():
    t, p = flat(0.3, 0.5, 0.8), photo()
    everywhere("dot, flat, phase r (0.25, 0), g (0, 0.5), b (0.3, 0.7)", t,
               phase_r_x=0.25, phase_g_y=0.5, phase_b_x=0.3, phase_b_y=0.7)
    mostly("dot, picture, phase r (0.25, 0.4)", p, phase_r_x=0.25, phase_r_y=0.4)
    mostly("line, picture, phase g (0.1, 0.5)", p, screen=1.0, phase_g_x=0.1, phase_g_y=0.5)
    base = gpu(t)
    whole = gpu(t, phase_r_x=1.0, phase_r_y=-1.0)
    check("flat: a whole-pitch phase returns the original", mx(whole, base), TOL)
    quarter = gpu(t, phase_r_x=0.25)
    check("flat: a quarter-pitch phase moves the red plate", float(mx(quarter[..., 0], base[..., 0]) < 0.5), 0.0)
    check("phase r: green and blue exactly unchanged", mx(quarter[..., 1:3], base[..., 1:3]), 0.0)
    a, b = gpu(p), gpu(p, angle_r=33.0)
    check("angle r: green and blue exactly unchanged", mx(a[..., 1:3], b[..., 1:3]), 0.0)
    check("angle r: red changes", float(mx(a[..., 0], b[..., 0]) < 0.5), 0.0)


def test_bypass():
    t = photo()
    got = gpu(t, bypass_gate=1.0)
    check("bypass: the source", mx(got, t), 1e-6)


def test_area_law_against_pitch():
    """G5 / T007: mean coverage minus tone, worst over five tones, by pitch in texels; the GPU beside the mirror. The mirror's
    numbers (2026-11-13) were 0.083 at 3 texels and 0.005 at 24. Asserted: the GPU's figure is the mirror's, within AREA_TOL
    (5e-3: a mean over 128 x 128 pixels of per-pixel differences expected near TOL); the law itself is noted, not asserted."""
    tones = (0.1, 0.3, 0.5, 0.8, 0.95)
    for texels in (3.0, 4.0, 6.0, 8.0, 12.0, 24.0):
        worst_g, worst_m = 0.0, 0.0
        for tone in tones:
            t = flat(tone, tone, tone)
            g_, m_ = gpu(t, pitch=texels / H), mirror(t, pitch=texels / H)
            worst_g = max(worst_g, abs(float(g_[..., :3].mean()) - tone))
            worst_m = max(worst_m, abs(float(m_[..., :3].mean()) - tone))
        note(f"pitch {texels:g} texels: worst area-law error, GPU", worst_g)
        note(f"pitch {texels:g} texels: worst area-law error, mirror", worst_m)
        check(f"pitch {texels:g} texels: GPU area error is the mirror's", abs(worst_g - worst_m), 5e-3)


# G8 / T010. One codebox, four channels: a read inside a function beside the same read in the main body, and a four-tap loop
# inside a function beside the same loop in the main body. Then sample() beside nearest() at texel centres, 1:1.
PROBE_READS = """
tap(u, v) {
    return nearest(in1, vec(u, v)).x;
}
tap4(u, v, du) {
    acc = 0;
    for (i = 0; i < 4; i += 1) {
        acc = acc + nearest(in1, vec(u + du * i, v)).y;
    }
    return acc * 0.25;
}
Param width(128);
du = 1 / max(width, 1);
fa = tap(norm.x, norm.y);
ma = nearest(in1, vec(norm.x, norm.y)).x;
fb = tap4(norm.x, norm.y, du);
mb = 0;
for (k = 0; k < 4; k += 1) {
    mb = mb + nearest(in1, vec(norm.x + du * k, norm.y)).y;
}
mb = mb * 0.25;
out1 = vec(fa, ma, fb, mb);
"""
PROBE_INTERP = """
out1 = vec(sample(in1, norm).x, nearest(in1, norm).x, sample(in1, norm).y, nearest(in1, norm).y);
"""


def test_reads_in_functions_and_loops():
    t = photo()
    got = gpu(t, code=PROBE_READS)
    check("a read inside a function equals the main-body read", mx(got[..., 0], got[..., 1]), 0.0)
    check("the read is the texel itself", mx(got[..., 1], t[..., 0]), 1e-6)
    check("a four-tap loop inside a function equals the main-body loop", mx(got[..., 2], got[..., 3]), 0.0)
    want = np.mean([np.take(t[..., 1], np.arange(W) + k, axis=1, mode="clip") for k in range(4)], axis=0)
    inner = slice(0, W - 4)       # past the right edge the read wraps or clamps: not this gate's question
    check("the loop reads the four texels to the right", mx(got[:, inner, 3], want[:, inner]), 1e-6)
    got = gpu(t, code=PROBE_INTERP)
    note("sample() minus nearest() at texel centres, 1:1, worst", mx(got[..., 0], got[..., 1]))
    check("sample() at a texel centre is that texel", max(mx(got[..., 0], got[..., 1]), mx(got[..., 2], got[..., 3])), 1e-6)


@slow       # a timing measurement (tests/bench.sh --slow); NF-001 records it, nothing is asserted
def test_cost_at_1080p():
    """ms per pass for Dot and Line at 1920 x 1080. As bench_separate.py: when the pass hides inside the bench's own per-frame
    work, 4K is run instead and its figure / 4 is the 1080p equivalent. Each later slot of the chain reads the previous slot's
    output; the codebox has no per-pixel loop, so that should not change the cost (inferred)."""
    src = photo()
    for s, name in SCREENS.items():
        for dim in ((1920, 1080), (3840, 2160)):
            params = {**PINNED, "screen": float(s), "width": float(dim[0]), "height": float(dim[1])}
            r = bc.measure(CODE, [src], dim=dim, chain=8, params=params)
            k = int(r.get("chain") or 8)
            scale = 1 if dim[0] == 1920 else 4
            if r.get("gpu_bound"):
                note(f"{name}: 1080p ms per pass, from {dim[0]} x {dim[1]} (chain {k})", f"{r['ms_per_pass'] / scale:.3f}")
                break
            if scale == 4:
                note(f"{name}: NOT resolved at 4K, 1080p-equivalent upper bound ms per pass",
                     f"{r['ms_per_pass_upper_bound'] / 4:.3f}")


if __name__ == "__main__":
    sys.exit(run(globals()))
