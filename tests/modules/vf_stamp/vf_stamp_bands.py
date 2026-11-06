"""vf_stamp_bands.py -- T010: radial / swirl band numbers that feed T003. Not a test (nothing is
asserted): it prints one row per stamp, softness and field at N = 256, f_vf_fluid's solver size.

Columns, for a disc of radius 0.2 frame widths:
  band    texels: area where |v| > 10% of peak, divided by the disc's perimeter
  peak    largest |v| in vecfield units (force 1, env 1)
  rim     texels: sum of |v| divided by the perimeter (the impulse across the edge, per unit of rim)
  div     swirl's RMS divergence by a ONE-texel stencil over its RMS magnitude; a reach above 1 is
          exactly divergence-free only by its own stencil, so kept_s is the column to trust
  kept_r  share of the radial field's energy left by f_vf_fluid's projection
  kept_s  the same for swirl

Run:  PYTHONPATH=tests/lib:tests/modules/vf_stamp uv run --no-project --with numpy \
          python3 tests/modules/vf_stamp/vf_stamp_bands.py
"""
import numpy as np

from vf_stamp_mirror import decode, disc, project, stamp_stage

N = 256
R = 0.2
PERIM = 2 * np.pi * R * N
FIELDS = (("unit", 1), ("diff", 1), ("diff", 4), ("diff", 8))
STAMPS = (("hard disc", 0.0), ("soft disc, ramp 0.1", 0.1))


def kept(vx, vy):
    px, py = project(vx, vy)
    return float((px ** 2 + py ** 2).sum() / max((vx ** 2 + vy ** 2).sum(), 1e-20))


def row(t, softness, field, reach, edge):
    kw = dict(softness=softness, field=field, reach=reach, edge_amt=edge, seed=3)
    rx, ry = decode(stamp_stage(t, **kw)[1])
    sx, sy = decode(stamp_stage(t, impulse=1, **kw)[1])
    mag = np.hypot(rx, ry)
    peak = float(mag.max())
    band = float((mag > 0.1 * peak).sum()) / PERIM
    rim = float(mag.sum()) / PERIM
    div = (np.roll(sx, -1, 1) - np.roll(sx, 1, 1) + np.roll(sy, -1, 0) - np.roll(sy, 1, 0)) / 2
    d = float(np.sqrt((div ** 2).sum() / max((sx ** 2 + sy ** 2).sum(), 1e-20)))
    return band, peak, rim, d, kept(rx, ry), kept(sx, sy)


def main():
    print(f"N = {N}, disc radius {R}, threshold 0.5")
    print(f"{'stamp':22}{'edge':>5}{'soft':>6}  {'field':8}{'band':>7}{'peak':>7}{'rim':>7}{'div':>8}{'kept_r':>8}{'kept_s':>8}")
    for name, ramp in STAMPS:
        t = disc(N, r=R, ramp=ramp)
        for edge in (0.0, 0.3):
            for softness in (0.02, 0.1, 0.3):
                for field, reach in FIELDS:
                    b, p, r, d, kr, ks = row(t, softness, field, reach, edge)
                    label = f"{field} s={reach}"
                    print(f"{name:22}{edge:5.1f}{softness:6.2f}  {label:8}{b:7.2f}{p:7.2f}{r:7.2f}{d:8.4f}{kr:8.3f}{ks:8.3f}")


if __name__ == "__main__":
    main()
