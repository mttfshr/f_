"""
test_conservative_field.py -- a conservative field's line integral around any
closed loop is ~0 (path-independence, ideas/vector_field_math_concepts.md #7).
Mirrors f_vf_fieldmap's actual codebox (src/f_vf_fieldmap/definition.py, a
gradient-of-luma producer) in NumPy and integrates its output field around
several closed loops.

A gradient field is always conservative; f_vf_fieldmap computes exactly that
(a central-difference luma gradient) at its default rotate=0. Rotating the
gradient by a nonzero angle breaks conservativeness in general (curl becomes
the Laplacian of the source luma, generically nonzero) -- used below as a
negative control, confirming this check can actually detect a
non-conservative field rather than trivially passing regardless of input.

Run:  tests/run.sh tests/test_conservative_field.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402

F32 = np.float32


def _luma_texture(h, w):
    """Smooth synthetic source -- a few low-frequency sinusoids, strictly
    positive so f_vf_fieldmap's thresh stays inert at its default 0.0 (the
    codebox's step(L_center, thresh) only suppresses the field where
    thresh >= L_center)."""
    nx, ny, _, _ = g.grid(h, w)
    L = (F32(1.0)
         + F32(0.6) * np.sin(nx * F32(2 * np.pi) * 2) * np.cos(ny * F32(2 * np.pi) * 1.5)
         + F32(0.3) * np.sin((nx + ny) * F32(2 * np.pi) * 3))
    tex = g.texture(h, w)
    tex[..., 0] = L
    tex[..., 1] = L
    tex[..., 2] = L
    tex[..., 3] = 1.0
    return g.store_float32(tex)


def fieldmap(source, gain=4.0, scale=0.004, rotate_deg=0.0, thresh=0.0):
    """NumPy mirror of f_vf_fieldmap's codebox. Returns the DECODED signed
    field (gx2, gy2), not the [0,1]-encoded wire value -- this script
    integrates the field directly, no need to round-trip the encode."""
    h, w = source.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    s = F32(scale)
    suv_x = nx * (1 - 2 * s) + s
    suv_y = ny * (1 - 2 * s) + s

    def luma(u, v):
        c = g.sample(source, u, v)
        return c[..., 0] * F32(0.299) + c[..., 1] * F32(0.587) + c[..., 2] * F32(0.114)

    L_center = luma(suv_x, suv_y)
    L_right = luma(suv_x + s, suv_y)
    L_left = luma(suv_x - s, suv_y)
    L_down = luma(suv_x, suv_y + s)
    L_up = luma(suv_x, suv_y - s)

    gx = (L_right - L_left) * F32(gain)
    gy = (L_down - L_up) * F32(gain)

    angle = F32(rotate_deg) * F32(np.pi) / F32(180.0)
    cos_r, sin_r = np.cos(angle), np.sin(angle)
    gx2 = gx * cos_r - gy * sin_r
    gy2 = gx * sin_r + gy * cos_r

    suppressed = F32(thresh) >= L_center
    gx2 = np.where(suppressed, F32(0.0), gx2)
    gy2 = np.where(suppressed, F32(0.0), gy2)
    return gx2, gy2


def _sample_field_at(field_x, field_y, u, v):
    """Bilinear-sample a (H, W) scalar-pair field at normalized (u, v) --
    reuses gpu_sim's sample() by packing into a throwaway RGBA texture."""
    h, w = field_x.shape
    packed = g.texture(h, w)
    packed[..., 0] = field_x
    packed[..., 1] = field_y
    s = g.sample(packed, np.asarray(u, F32), np.asarray(v, F32))
    return s[..., 0], s[..., 1]


def _loop_circulation(field_x, field_y, cx, cy, half, n_per_side=40):
    """Line integral of the field around a closed square loop centered at
    (cx, cy) with half-width `half`, via the trapezoidal rule on each edge."""
    t = np.linspace(0.0, 1.0, n_per_side + 1)
    corners = [(cx - half, cy - half), (cx + half, cy - half),
               (cx + half, cy + half), (cx - half, cy + half)]
    total = 0.0
    for i in range(4):
        x0, y0 = corners[i]
        x1, y1 = corners[(i + 1) % 4]
        xs = x0 + (x1 - x0) * t
        ys = y0 + (y1 - y0) * t
        fx, fy = _sample_field_at(field_x, field_y, xs, ys)
        dx, dy = (x1 - x0) / n_per_side, (y1 - y0) / n_per_side
        seg = (fx[:-1] + fx[1:]) * 0.5 * dx + (fy[:-1] + fy[1:]) * 0.5 * dy
        total += float(seg.sum())
    return total


def test_default_field_is_conservative():
    """rotate=0 (the module's default): a pure luma gradient is always
    conservative -- circulation around any closed loop should net to ~0."""
    h = w = 256
    source = _luma_texture(h, w)
    fx, fy = fieldmap(source, rotate_deg=0.0)

    loops = [(0.3, 0.3, 0.1), (0.6, 0.4, 0.15), (0.5, 0.5, 0.2), (0.35, 0.65, 0.08)]
    mags = []
    for cx, cy, half in loops:
        circ = _loop_circulation(fx, fy, cx, cy, half)
        perim = 8 * half
        note(f"loop (cx={cx}, cy={cy}, half={half}) |circulation|/perimeter", abs(circ) / perim)
        mags.append(abs(circ) / perim)
    check("max |circulation|/perimeter across loops", max(mags), 2e-3)


def test_rotated_field_is_not_conservative():
    """Negative control: rotating the gradient by 90deg should break
    conservativeness in general (curl becomes the source's Laplacian) --
    confirms this check can actually detect a non-conservative field, not
    just trivially pass. Uses the same loop set as the positive test EXCEPT
    the one centered at (0.5, 0.5): that loop sits on a symmetry point of
    the synthetic source where the Laplacian's area-integral happens to
    cancel even for the rotated field (empirically confirmed, not assumed --
    circulation/perimeter ~1e-8 there even at rotate=90), so it would be a
    false negative for this control, not evidence the check is insensitive."""
    h = w = 256
    source = _luma_texture(h, w)
    fx, fy = fieldmap(source, rotate_deg=90.0)

    loops = [(0.3, 0.3, 0.1), (0.6, 0.4, 0.15), (0.35, 0.65, 0.08)]
    ratios = []
    for cx, cy, half in loops:
        circ = _loop_circulation(fx, fy, cx, cy, half)
        ratio = abs(circ) / (8 * half)
        note(f"rotated-field loop (cx={cx}, cy={cy}, half={half}) |circulation|/perimeter", ratio)
        ratios.append(ratio)
    if max(ratios) <= 2e-3:
        raise AssertionError(
            f"expected at least one rotated (non-conservative) loop to show "
            f"circulation above 2e-3, got max {max(ratios):.3e} -- this check "
            f"may not be sensitive enough to catch a real non-conservative field"
        )
    print(f"    ok   confirmed nonzero circulation (max {max(ratios):.3e}) -- "
          f"check has real discriminating power")


if __name__ == "__main__":
    sys.exit(run(globals()))
