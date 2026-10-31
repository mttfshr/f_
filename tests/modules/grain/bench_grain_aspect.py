"""
bench_grain_aspect.py -- f_grain `aspect_mode` probe (T063, 2026-10-30): what does the Aspect menu actually change?

Matt, live: with the render_dim migration's Aspect menu (0 Render, 1 dim, 2 Square) the three modes looked identical.
`aspect` enters the codebox in ONE place, the horizontal cell count (px = uv.x * 4096 * aspect / size_scale), and the
cell height on screen is frame_height * 2^(12 Size) / 4096, so at Size 0 the cells are well under a pixel in every
mode and the mask is just noise on a slightly different lattice. This probe runs the REAL codebox
(src/f_grain/codebox_grain.gen, pix type char as the module) on the bench in each mode at several Sizes and reports:

  - the max / mean absolute difference of the grain-mask outlet between the modes;
  - an anisotropy measure of the mask: mean |horizontal neighbour difference| / mean |vertical neighbour difference|
    (about 1 for cells that are square in pixels, about 1 / 1.78 for cells stretched 1.78x wider, as Square mode makes
    them on a 16:9 frame).

Pass / fail legs (everything else is informational, to be read in the log):
  1. dim mode == Render mode exactly, at every Size. In the bench `dim` follows the FIRST input's size (the
     bench-quasi finding), and the first input is render-sized (256 x 144), the same numbers as width / height.
  2. At Sizes where cells are several pixels (0.65, 0.75), Square differs from Render (mean |diff| > 0.01) and the
     anisotropy separates them: Render within 0.8-1.25, Square below 0.8.
The same measurement at Size 0 and 0.5 (cells under / near a pixel) is recorded without a verdict: it is what the
default look shows.

Jitter 0 and Shape 0 so the cells read as cells; everything else at the codebox defaults, every Param pinned (the bench
keeps a Param's last value between jobs: bench-test-authoring #2).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/modules/grain/bench_grain_aspect.py
Not in the regression group (a probe).
"""
GROUP = "record"       # a probe: not in the regression set; see tests/lib/benchdeps.py list --group
ORDER = 67             # integers only; 66 is taken, 70 is bench_modules

import paths as _paths
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run

CODE = (_paths.REPO / "src" / "f_grain" / "codebox_grain.gen").read_text()
H, W = 144, 256
BLANK = np.zeros((H, W, 4), np.float32)          # render-sized first input: `dim` is the render's (and never read: src_mode 0)
PINNED = dict(src_mode=0.0, density=0.5, gain=1.0, mix_pct=100.0, era_clock=0.0, bypass_gate=0.0, size=0.0,
              size_var=0.0, shape=0.0, softness=0.0, jitter=0.0, fade=0.0, ch_diverge=0.0, luma_gate=0.0,
              displace=0.0, edge_mode=2.0, field=0.0, sv_seed=0.0, aspect_mode=0.0,
              width=float(W), height=float(H))
MODES = {0: "Render", 1: "dim", 2: "Square"}
SIZES = (0.0, 0.5, 0.65, 0.75)
JUDGED = (0.65, 0.75)       # cells several pixels tall on the 144-line bench frame: 7.8 and 18 px


def gpu(size, mode):
    p = {**PINNED, "size": size, "aspect_mode": float(mode)}
    outs, r = bc.run_pass(CODE, [BLANK], dim=(W, H), params=p, timeout_ms=30000, all_outputs=True, pix_type="char")
    if r["status"] != "ok" or outs[1] is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs[1][..., 0].astype(np.float64)        # the grain mask outlet, first channel


def anisotropy(m):
    """mean |d/dx| over mean |d/dy|: about 1 for isotropic cells, below 1 for cells wider than tall."""
    dx = float(np.abs(m[:, 1:] - m[:, :-1]).mean())
    dy = float(np.abs(m[1:, :] - m[:-1, :]).mean())
    return dx / dy if dy > 0 else float("nan"), dx, dy


_CACHE = {}


def mask(size, mode):
    if (size, mode) not in _CACHE:
        _CACHE[(size, mode)] = gpu(size, mode)
    return _CACHE[(size, mode)]


# ---------------------------------------------------------------- tests

def test_masks_are_not_flat():
    for size in SIZES:
        m = mask(size, 0)
        note(f"Size {size}: mask mean / std", f"{m.mean():.3f} / {m.std():.3f}")
        assert m.std() > 1e-3, f"the grain mask is flat at Size {size}"


def test_dim_mode_equals_render_mode_in_the_bench():
    for size in SIZES:
        check(f"Size {size}: dim mode == Render mode", float(np.abs(mask(size, 1) - mask(size, 0)).max()), 0.0)


def test_report_the_differences_and_anisotropy():
    """Informational at every Size; the verdict legs are test_square_separates_from_render_when_cells_are_large."""
    cell_h = {s: H * 2.0 ** (12.0 * s) / 4096.0 for s in SIZES}
    for size in SIZES:
        row = {}
        for mode, name in MODES.items():
            ratio, dx, dy = anisotropy(mask(size, mode))
            row[name] = f"aniso {ratio:.2f} (dx {dx:.3f}, dy {dy:.3f})"
        d_sq = np.abs(mask(size, 2) - mask(size, 0))
        note(f"Size {size} (cell height {cell_h[size]:.2f} px, Render width {cell_h[size]:.2f} px, Square width {cell_h[size] * W / H:.2f} px)",
             row)
        note(f"Size {size}: Square vs Render", f"max |diff| {d_sq.max():.3f}, mean |diff| {d_sq.mean():.4f}")


def test_square_separates_from_render_when_cells_are_large():
    for size in JUDGED:
        d = float(np.abs(mask(size, 2) - mask(size, 0)).mean())
        a_render = anisotropy(mask(size, 0))[0]
        a_square = anisotropy(mask(size, 2))[0]
        check(f"Size {size}: Square differs from Render (mean |diff| > 0.01)", 0 if d > 0.01 else 1, 0)
        check(f"Size {size}: Render cells are about isotropic (aniso {a_render:.2f} in 0.8-1.25)",
              0 if 0.8 <= a_render <= 1.25 else 1, 0)
        check(f"Size {size}: Square cells are stretched wide (aniso {a_square:.2f} < 0.8)",
              0 if a_square < 0.8 else 1, 0)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
