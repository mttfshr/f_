"""test_dithers.py -- tier-1 tests for f_halftone's Blue and Random screens and Levels (T034; spec US10-11, FR-023 to FR-027,
plan ADR-10, ADR-11). Offline, Claude, 2026-11-14; nothing here is built or benched.

Ground truth independent of the mirror where it can be: the area law (a flat patch's mean output equals its tone, for every
level count), today's one-bit Bayer written out here from the recursive matrix, the shipped blue-noise file read directly, and
a whole-cell phase shift as an array roll.

Run:  tests/run.sh -q tests/modules/halftone/test_dithers.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from halftone_mirror import BLUE_SEED_STEP, F32, PLATE_OFF, bayer8_recursive, bluenoise64, halftone_stage  # noqa: E402

N = 512
P1 = 8 / N          # pitch giving a grain cell of one pixel at H = 512 (cell = pitch * H / 8)
DITHERS = ("bayer", "blue", "random")


def flat(tone, W=N, H=N, a=1.0):
    t = np.zeros((H, W, 4), dtype=F32)
    t[..., :3] = np.asarray(tone, dtype=F32)
    t[..., 3] = a
    return t


def ramp(W=N, H=64):
    t = np.zeros((H, W, 4), dtype=F32)
    t[..., :3] = ((np.arange(W, dtype=F32) + 0.5) / W)[None, :, None]
    t[..., 3] = 1
    return t


def test_area_law_per_screen_and_levels():
    tol = {"bayer": 1 / 64, "blue": 1 / 4096 + 1e-6, "random": 0.006}
    for screen in DITHERS:
        for L in (2, 3, 5, 8, 16):
            worst = 0.0
            for t in (0.07, 0.3, 0.5, 0.62, 0.93):
                out = halftone_stage(flat(t), screen=screen, pitch=P1, levels=L)
                worst = max(worst, float(np.abs(out[..., :3].astype(np.float64).mean(axis=(0, 1)) - t).max()))   # float64: a float32 sum drifts
            check(f"{screen}, levels {L}: mean output equals the tone", worst, tol[screen] / (L - 1))


def test_levels_2_is_todays_bayer():
    src = ramp()
    want = (src[..., 0] > ((bayer8_recursive()[np.arange(64)[:, None] % 8, np.arange(N)[None, :] % 8] + 0.5) / 64)).astype(F32)
    for kw in (dict(), dict(levels=2)):
        out = halftone_stage(src, screen="bayer", pitch=P1, bayer_read="pixel", **kw)
        check(f"Bayer {kw or 'default'} equals the one-bit Bayer bit for bit", float(np.abs(out[..., 0] - want).max()), 0)


def test_only_neighbouring_levels():
    src = ramp()
    t = src[..., 0]
    for screen in DITHERS:
        for L in (3, 4, 7, 16):
            out = halftone_stage(src, screen=screen, pitch=P1, bayer_read="pixel", levels=L)[..., 0]
            k = np.round(out * (L - 1))
            lo = np.floor(t * (L - 1))
            bad = ~((k == lo) | (k == lo + 1)) | (np.abs(out * (L - 1) - k) > 1e-5)
            check(f"{screen}, levels {L}: each pixel is one of its two neighbouring levels", float(bad.mean()), 0)


def test_extremes_exact():
    for screen in DITHERS:
        for L in (2, 5, 16):
            for t, want in ((-0.5, 0), (0.0, 0), (1.0, 1), (1.5, 1)):
                out = halftone_stage(flat(t, 64, 64), screen=screen, pitch=P1, levels=L)
                check(f"{screen}, levels {L}, tone {t}: output exactly {want}", float(np.abs(out[..., :3] - want).max()), 0)


def test_blue_reads_the_file():
    """Plate 0 (red), seed 1, no phase, one-pixel cells: lit where tone > file[(y + oy) mod 64, (x + ox) mod 64]."""
    B = bluenoise64()
    ox, oy = PLATE_OFF[0][0] + BLUE_SEED_STEP[0], PLATE_OFF[0][1] + BLUE_SEED_STEP[1]
    y, x = np.mgrid[0:N, 0:N]
    for t in (0.2, 0.5, 0.8):
        want = (F32(t) > B[(y + oy) % 64, (x + ox) % 64]).astype(F32)
        out = halftone_stage(flat(t), screen="blue", pitch=P1, seed=1)
        check(f"Blue at tone {t} is the file's pattern (orientation, offset)", float(np.abs(out[..., 0] - want).max()), 0)


def test_plates_differ():
    for screen in ("blue", "random"):
        out = halftone_stage(flat(0.5), screen=screen, pitch=P1) > 0.5
        for i, j in ((0, 1), (0, 2), (1, 2)):
            ov = float((out[..., i] & out[..., j]).mean())
            note(f"{screen}: plates {i}, {j} both lit at grey .5 (independent = .25)", f"{ov:.4f}")
            check(f"{screen}: plates {i}, {j} are not one pattern (overlap within .03 of .25)", abs(ov - 0.25), 0.03)


def test_seed():
    for screen in ("blue", "random"):
        a = halftone_stage(flat(0.5, 128, 128), screen=screen, pitch=8 / 128, seed=1)
        b = halftone_stage(flat(0.5, 128, 128), screen=screen, pitch=8 / 128, seed=1)
        c = halftone_stage(flat(0.5, 128, 128), screen=screen, pitch=8 / 128, seed=2)
        check(f"{screen}: same seed, bit-identical", float(np.abs(a - b).max()), 0)
        changed = float((a[..., :3] != c[..., :3]).mean())
        note(f"{screen}: share of pixels a seed step changes", f"{changed:.3f}")
        check(f"{screen}: a seed step changes the pattern (over 30% of pixels)", 0.3 - changed, 0)


def test_phase_moves_whole_cells():
    """Phase x of 1 / 8 pitch is one grain cell: the output moves by +one cell (sc pixels). Pitch of 3-pixel cells."""
    pitch = 3 * 8 / N
    for screen in ("blue", "random"):
        a = halftone_stage(flat(0.4), screen=screen, pitch=pitch)
        b = halftone_stage(flat(0.4), screen=screen, pitch=pitch, phases=((1 / 8, 0), (0, 0), (0, 0)))
        check(f"{screen}: phase x of one cell moves red by +3 px", float(np.abs(b[:, 3:, 0] - a[:, :-3, 0]).max()), 0)
        check(f"{screen}: green unmoved by red's phase", float(np.abs(b[..., 1] - a[..., 1]).max()), 0)


def test_lattice_screens_ignore_levels():
    src = ramp(256, 128)
    for screen in ("dot", "line", "threshold"):
        a = halftone_stage(src, screen=screen, pitch=0.05)
        b = halftone_stage(src, screen=screen, pitch=0.05, levels=7)
        check(f"{screen} ignores levels", float(np.abs(a - b).max()), 0)


def test_single_and_plates_take_the_colour():
    col = np.array([0.8, 0.4, 0.2], dtype=F32)
    for screen in ("blue", "random", "bayer"):
        L = 4
        single = halftone_stage(flat(col), screen=screen, pitch=P1, levels=L, plate_mode="single")
        plates = halftone_stage(None, screen=screen, pitch=P1, levels=L, plate_mode="plates", plates=(None, None, flat(col)))
        cn = col / col.max()                    # the plate colour, normalised by its brightest channel
        for name, out in (("single", single), ("plates", plates)):
            v = out[..., 0] / cn[0]
            ratio = float(np.abs(out[..., :3] - v[..., None] * cn).max())
            check(f"{screen} {name}: output is the colour times one value", ratio, 1e-6)
            k = v * (L - 1)
            check(f"{screen} {name}: that value is a level of {L}", float(np.abs(k - np.round(k)).max()), 1e-5)
            tol = 1 / 64 if screen == "bayer" else (1e-3 if screen == "blue" else 0.006)
            check(f"{screen} {name}: its mean is the tone .8", abs(float(v.astype(np.float64).mean()) - 0.8), tol)


def test_mutations_caught():
    g = flat(0.5, 128, 128)
    cases = {
        "levels_one_bit": (flat(0.3, 64, 64), dict(screen="blue", pitch=8 / 64, levels=4)),
        "dither_shared_plate": (g, dict(screen="blue", pitch=8 / 128)),
        "dither_ignore_phase": (g, dict(screen="random", pitch=8 / 128, phases=((0.5, 0), (0, 0), (0, 0)))),
        "blue_transposed": (g, dict(screen="blue", pitch=8 / 128)),
        "random_ignore_seed": (g, dict(screen="random", pitch=8 / 128, seed=3)),
    }
    for bug, (src, kw) in cases.items():
        a = halftone_stage(src, **kw)
        b = halftone_stage(src, bug=bug, **kw)
        e = float(np.abs(a - b).max())
        note(f"mutation '{bug}' worst error", e)
        check(f"mutation caught: {bug}", float(e <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
