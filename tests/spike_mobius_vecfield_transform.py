"""
spike_mobius_vecfield_transform.py -- does piping a vector field through
f_mobius's existing UV remap correctly transform the vectors, or does it just
resample the RG channels like any other texture? (ideas/vector_field_math_concepts.md
#6, diagnosed with the Tissot's-indicatrix method from #10.)

Reading src/f_mobius/definition.py's codebox directly already answers "does
it happen": `effect_out = sample(in1, vec(uv_x, uv_y, 0))` is a generic
resample with no vector-aware special case, so a vecfield piped through gets
its R/G channels carried to a new pixel location unmodified -- the field
value itself is never rotated/scaled to match the local transform. This
script characterizes HOW WRONG that is: the Tissot's-indicatrix view (what
the map does to small circles) and a direct vector-field comparison (naive
resample vs. the analytically correct transform, using the map's complex
derivative) side by side.

Both of f_mobius's two paths are conformal/holomorphic (correcting an
earlier misread: `inv_x = zx/mag_sq, inv_y = -zy/mag_sq` is plain `1/z`, not
an orientation-flipping conjugate), so the correct way to carry a vector v
at a point is to multiply it -- treated as a complex number -- by the map's
local derivative, not just move it:
    rotate+zoom path:  g(z) = scale * exp(i*angle) * z      g'(z) = scale * exp(i*angle)  (constant)
    invert path:       g(z) = 1/z                           g'(z) = -1/z^2
(z = norm - center, matching the codebox's own variable names.) `invert`'s
declared range is [0, 10], which would extrapolate `mix()` past the pure
inversion path above 1 -- a separate quirk, not exercised here. This script
only tests invert = 0 and invert = 1 (the two paths actually built for).

If a source point s = T(output_pixel) is what the codebox samples the field
at (T = the backward map it computes), the geometrically correct carried
vector is v'(output_pixel) = v_source(s) / g'(z), z = output_pixel - center
-- derived from the standard pushforward-of-a-vector-field-under-a-
diffeomorphism rule. "naive" below is exactly what the shipped module does
today; "correct" is this quotient.

Run:
  uv run --no-project --with numpy --with matplotlib python3 tests/spike_mobius_vecfield_transform.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import gpu_sim as g  # noqa: E402

F32 = np.float32
TWO_PI = F32(2.0 * np.pi)


def mobius_g(zx, zy, rotate, zoom, invert):
    """The codebox's inner transform (src/f_mobius/definition.py), in
    center-relative coordinates: returns (out_x, out_y) = g(zx, zy)."""
    angle = F32(rotate) * TWO_PI
    scale = F32(10.0) ** ((F32(zoom) - F32(0.5)) * F32(5.0))
    cos_a, sin_a = np.cos(angle), np.sin(angle)
    rot_x = (cos_a * zx - sin_a * zy) * scale
    rot_y = (sin_a * zx + cos_a * zy) * scale
    mag_sq = np.maximum(zx * zx + zy * zy, F32(0.0001))
    inv_x = zx / mag_sq
    inv_y = -zy / mag_sq
    out_x = rot_x * (1 - invert) + inv_x * invert
    out_y = rot_y * (1 - invert) + inv_y * invert
    return out_x, out_y


def mobius_g_prime(zx, zy, rotate, zoom, invert):
    """Complex derivative g'(z) as a (real, imag) pair, for the two pure
    cases this script exercises (invert exactly 0 or 1 -- see module
    docstring on why the continuous blend isn't tested)."""
    angle = F32(rotate) * TWO_PI
    scale = F32(10.0) ** ((F32(zoom) - F32(0.5)) * F32(5.0))
    if invert == 0:
        # g(z) = scale * e^{i angle} * z  =>  g'(z) = scale * e^{i angle}, constant
        gp_re = np.full_like(zx, scale * np.cos(angle))
        gp_im = np.full_like(zx, scale * np.sin(angle))
        return gp_re, gp_im
    elif invert == 1:
        # g(z) = 1/z  =>  g'(z) = -1/z^2 = -conj(z^2) / |z^2|^2
        z2_re = zx * zx - zy * zy
        z2_im = F32(2.0) * zx * zy
        mag_sq = np.maximum(z2_re * z2_re + z2_im * z2_im, F32(1e-8))
        gp_re = -z2_re / mag_sq
        gp_im = z2_im / mag_sq
        return gp_re, gp_im
    else:
        raise ValueError("this script only tests invert in {0, 1}")


def local_scale_map(cx, cy, rotate, zoom, invert, h=192, w=192):
    """|g'(z)| over the whole norm-space grid -- the true Tissot indicatrix
    for a CONFORMAL map (both f_mobius paths are conformal) is always a
    circle, never an ellipse, at every point: angle-preserving means shape
    can't change, only local scale. So the honest diagnostic here is this
    scale factor, not an ellipse glyph (an earlier version of this script
    drew pushed-forward circles directly and they landed far outside the
    plotted unit square near the invert path's singularity -- a real
    artifact of z=0 being a pole of 1/z, not a plotting bug to paper over,
    but the wrong diagnostic to chase: local scale is what's actually
    varying)."""
    nx, ny, _, _ = g.grid(h, w)
    zx, zy = nx - F32(cx), ny - F32(cy)
    gp_re, gp_im = mobius_g_prime(zx, zy, rotate, zoom, invert)
    return np.hypot(gp_re, gp_im)


def vecfield_comparison(cx, cy, rotate, zoom, invert, h=192, w=192):
    """Naive vs. analytically-correct transform of a uniform (+x) source
    field, piped through f_mobius's UV remap. A uniform source field is
    deliberate: resampling a spatially-uniform field at any location always
    returns the same value, so "naive" is (1, 0) everywhere no matter what
    -- which is exactly the failure mode worth seeing directly, rather than
    picking a source field that happens to partly compensate."""
    nx, ny, _, _ = g.grid(h, w)
    zx, zy = nx - F32(cx), ny - F32(cy)

    naive_x = np.ones((h, w), F32)
    naive_y = np.zeros((h, w), F32)

    # correct: v' = v_source / g'(z) = conj(g'(z)) / |g'(z)|^2, since
    # v_source = (1, 0) i.e. the complex number 1.
    gp_re, gp_im = mobius_g_prime(zx, zy, rotate, zoom, invert)
    mag_sq = np.maximum(gp_re * gp_re + gp_im * gp_im, F32(1e-12))
    correct_x = gp_re / mag_sq
    correct_y = -gp_im / mag_sq

    return naive_x, naive_y, correct_x, correct_y


def main():
    cx, cy = 0.5, 0.5
    # rotate_zoom case: nontrivial global rotate+scale, so naive vs. correct
    # actually differ (a pure identity map would make them coincide and
    # prove nothing). invert case ignores rotate/zoom entirely (the codebox
    # mix() picks the inversion branch fully at invert=1).
    rotate, zoom = 0.125, 0.55  # 45 deg rotation, ~1.78x scale

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        plt = None
        print("matplotlib not available -- printing numeric summary only")

    out_dir = HERE.parent / "scratch"
    out_dir.mkdir(exist_ok=True)

    for invert, label in ((0, "rotate_zoom"), (1, "invert")):
        scale_map = local_scale_map(cx, cy, rotate, zoom, invert)
        naive_x, naive_y, correct_x, correct_y = vecfield_comparison(cx, cy, rotate, zoom, invert)

        ang_diff = np.degrees(np.arctan2(correct_y, correct_x) - np.arctan2(naive_y, naive_x))
        ang_diff = (ang_diff + 180) % 360 - 180
        mag_correct = np.hypot(correct_x, correct_y)

        print(f"--- invert={invert} ({label}) ---")
        print(f"  mean |correct - naive| direction error: {np.abs(ang_diff).mean():.1f} deg, "
              f"max {np.abs(ang_diff).max():.1f} deg")
        print(f"  correct magnitude range: {mag_correct.min():.4f} .. {mag_correct.max():.4f} "
              f"(naive is always 1.0 everywhere by construction)")
        print(f"  local scale |g'(z)| range: {scale_map.min():.4f} .. {scale_map.max():.4f} "
              f"(this map is conformal, so the true Tissot indicatrix is always a circle "
              f"at every point -- only its RADIUS varies, shown here as a heatmap instead "
              f"of drawn circles, which blew up off-canvas near the invert path's pole)")

        if plt is None:
            continue

        fig, ax = plt.subplots(1, 2, figsize=(11.5, 5.4))

        from matplotlib.colors import LogNorm
        im0 = ax[0].imshow(scale_map, cmap="viridis",
                            norm=LogNorm(vmin=max(scale_map.min(), 1e-3), vmax=scale_map.max()),
                            extent=(0, 1, 1, 0))
        ax[0].set_title(f"local scale |g'(z)| ({label}), log scale")
        fig.colorbar(im0, ax=ax[0], fraction=0.046)
        ax[0].set_aspect("equal")

        step = 14
        h, w = naive_x.shape
        yy, xx = np.mgrid[0:h:step, 0:w:step]
        xn, yn = (xx + 0.5) / w, (yy + 0.5) / h
        ax[1].set_title("uniform field: naive resample (gray) vs. correct (blue)")
        ax[1].quiver(xn, yn, naive_x[yy, xx], naive_y[yy, xx], color="0.75",
                     angles="xy", scale_units="xy", scale=20, width=0.004)
        ax[1].quiver(xn, yn, correct_x[yy, xx], correct_y[yy, xx], color="steelblue",
                     angles="xy", scale_units="xy", scale=20, width=0.004)
        ax[1].set_xlim(0, 1)
        ax[1].set_ylim(0, 1)
        ax[1].set_aspect("equal")
        ax[1].invert_yaxis()

        fig.tight_layout()
        fp = out_dir / f"mobius_vecfield_{label}.png"
        fig.savefig(fp, dpi=110)
        print(f"  figure: {fp}")


if __name__ == "__main__":
    main()
