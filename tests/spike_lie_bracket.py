"""
spike_lie_bracket.py -- Lie bracket experiment: does warping through two vortex
fields in different orders commute? (ideas/vector_field_math_concepts.md #5)

Not a regression gate -- a scratch experiment. Mirrors f_vf_vortex's and
f_vf_warp's actual codebox math in NumPy (tests/gpu_sim.py conventions)
rather than touching Max. Chains a test pattern through field A then B, and
B then A, and diffs the two results. Any nonzero diff *is* a rendering of
the Lie bracket of the two fields' flows -- this script answers "is it
visible, and how big" for two concrete f_vf_vortex configurations.

Run:
  uv run --no-project --with numpy --with matplotlib python3 tests/spike_lie_bracket.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import gpu_sim as g  # noqa: E402

F32 = np.float32


def vortex_field(h, w, cx, cy, convergence, curl, falloff):
    """NumPy mirror of f_vf_vortex's codebox (src/f_vf_vortex/definition.py),
    modulation inlets omitted (amt=0 in the shipped default anyway). Returns
    the ENCODED field texture (H, W, 4) float32, R/G in [0,1], matching what
    the real module puts on the wire."""
    nx, ny, _, _ = g.grid(h, w)
    dx = nx - F32(cx)
    dy = ny - F32(cy)
    r = np.sqrt(dx * dx + dy * dy)
    r_safe = np.maximum(r, F32(0.0001))
    rx, ry = dx / r_safe, dy / r_safe
    tx, ty = -ry, rx
    fx = F32(convergence) * (-rx) + F32(curl) * tx
    fy = F32(convergence) * (-ry) + F32(curl) * ty
    strength = np.exp(-r * F32(max(falloff, 0.0)))
    fx, fy = fx * strength, fy * strength
    R = np.clip(fx * F32(0.5) + F32(0.5), 0.0, 1.0)
    G = np.clip(fy * F32(0.5) + F32(0.5), 0.0, 1.0)
    out = g.texture(h, w)
    out[..., 0] = R
    out[..., 1] = G
    out[..., 2] = F32(0.5)
    out[..., 3] = F32(1.0)
    return g.store_float32(out)


def warp(source, field_tex, strength):
    """NumPy mirror of f_vf_warp's codebox (src/f_vf_warp/definition.py).
    Bypass and the unconnected-inlet gate aren't modeled -- this script
    always treats the field as connected, strength as given."""
    h, w = source.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    field_x = field_tex[..., 0]
    field_y = field_tex[..., 1]
    offset_x = (field_x - F32(0.5)) * F32(2.0) * F32(strength)
    offset_y = (field_y - F32(0.5)) * F32(2.0) * F32(strength)
    warped_x = np.clip(nx + offset_x, 0.0, 1.0)
    warped_y = np.clip(ny + offset_y, 0.0, 1.0)
    return g.sample(source, warped_x, warped_y)


def checkerboard(h, w, cell=16):
    _, _, cx_idx, cy_idx = g.grid(h, w)
    cx_idx = cx_idx.astype(np.int64)
    cy_idx = cy_idx.astype(np.int64)
    parity = ((cx_idx // cell) + (cy_idx // cell)) % 2
    tex = g.texture(h, w)
    val = parity.astype(F32)
    tex[..., 0] = val
    tex[..., 1] = val
    tex[..., 2] = val
    tex[..., 3] = 1.0
    return g.store_float32(tex)


def main():
    h = w = 256
    strength = 0.4  # well above the module's 0.1 default, to make order-dependence visible

    source = checkerboard(h, w, cell=16)

    # Two deliberately different fields: A is a pure sink (no curl) off to
    # one side, B is a pure vortex (no convergence) off to the other. Each
    # kept under magnitude 1 individually so the R/G encode doesn't clip.
    field_a = vortex_field(h, w, cx=0.35, cy=0.5, convergence=0.6, curl=0.0, falloff=1.5)
    field_b = vortex_field(h, w, cx=0.65, cy=0.5, convergence=0.0, curl=0.7, falloff=1.5)

    result_ab = warp(warp(source, field_a, strength), field_b, strength)
    result_ba = warp(warp(source, field_b, strength), field_a, strength)

    diff = result_ab[..., :3] - result_ba[..., :3]
    abs_diff = np.abs(diff)
    mean_abs = float(abs_diff.mean())
    max_abs = float(abs_diff.max())

    print(f"mean |A-then-B minus B-then-A| = {mean_abs:.5f}")
    print(f"max  |A-then-B minus B-then-A| = {max_abs:.5f}")
    print("(0 would mean the two warp orders commute exactly; the article's "
          "Lie bracket is precisely this non-cancelling remainder)")

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, ax = plt.subplots(1, 4, figsize=(14, 3.6))
        ax[0].imshow(source[..., :3])
        ax[0].set_title("source")
        ax[1].imshow(np.clip(result_ab[..., :3], 0, 1))
        ax[1].set_title("A then B")
        ax[2].imshow(np.clip(result_ba[..., :3], 0, 1))
        ax[2].set_title("B then A")
        im = ax[3].imshow(abs_diff.mean(axis=-1), cmap="inferno")
        ax[3].set_title(f"|diff| (mean {mean_abs:.4f})")
        for a in ax:
            a.set_xticks([])
            a.set_yticks([])
        fig.colorbar(im, ax=ax[3], fraction=0.046)
        fig.tight_layout()
        out_dir = HERE.parent / "scratch"
        out_dir.mkdir(exist_ok=True)
        fp = out_dir / "lie_bracket_spike.png"
        fig.savefig(fp, dpi=110)
        print(f"figure: {fp}")
    except ImportError:
        print("matplotlib not available -- skipped the figure, numbers above still stand")


if __name__ == "__main__":
    main()
