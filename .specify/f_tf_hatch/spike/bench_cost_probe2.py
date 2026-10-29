"""
SPIKE (not shipped), probe 2: is E2's stroke-texture cost the texture's SIZE or the tiling STRIDE?
Probe 1 (bench_cost_probe.py): blobs 2.98 ms, texture as shipped 12.9, a 256 x 256 texture 4.92; fetch count
and the branch are not the cost. Here the shipped E2 codebox, 1080p, float32 textures, random aux unless noted:

  size, at Grain 0.5 (8 tiles across the frame, an 8-texel stride per pixel on a texture of that size):
    S1  4 x 4     S2  256 x 256     S3  512 x 512     S4  1024 x 1024     S5  1920 x 1080
  stride, with the 1080p texture:
    G1  Grain 1.0 (the texture once: a 1-texel stride, sequential)     G0  Grain 0.0 (64 tiles: a 64-texel stride)
    G1c Grain 1.0 on a COHERENT aux (a real frame's paths)

Needs Max with tests/bench/bench.maxpat open.
  tests/bench.sh -q .specify/f_tf_hatch/spike/bench_cost_probe2.py
"""
GROUP = "spike"
ORDER = 999

import paths as _paths  # noqa: F401
import sys

import numpy as np

REPO = _paths.REPO
sys.path.insert(0, str(REPO / "tests" / "modules" / "tf_hatch"))
import bench_tf_hatch as B  # noqa: E402
import benchclient as bc  # noqa: E402
from harness import check, note, run  # noqa: E402


def ms(r):
    return r.get("ms_per_pass", r.get("ms_per_pass_upper_bound"))


def test_cost_probe2_texture_size_vs_stride():
    m = B.m
    aux_r = m.stage_e1(B.rand_tensor_tex(1080, 1920, seed=6), 0.0, 0.1, "unsigned_nearest")
    aux_c = m.stage_e1(B.field_tex(1080, 1920, 20.0, 1.0), 0.0, 0.1, "unsigned_nearest")
    code = B.code("e2")
    tx = {n: B.noise_tex(h, w, 9) for n, (h, w) in
          {"4x4": (4, 4), "256x256": (256, 256), "512x512": (512, 512), "1024x1024": (1024, 1024), "1920x1080": (1080, 1920)}.items()}
    p = lambda aux, g: B.e2p(aux, reach=0.5, grain=g, src_stroke=1.0)
    runs = [(f"size {n}, grain 0.5", [aux_r, t], p(aux_r, 0.5)) for n, t in tx.items()]
    runs += [("stride: 1080p texture, grain 1.0 (1-texel stride)", [aux_r, tx["1920x1080"]], p(aux_r, 1.0)),
             ("stride: 1080p texture, grain 0.0 (64-texel stride)", [aux_r, tx["1920x1080"]], p(aux_r, 0.0)),
             ("stride: 1080p texture, grain 1.0, COHERENT aux", [aux_c, tx["1920x1080"]], p(aux_c, 1.0)),
             ("stride: 256x256 texture, grain 1.0", [aux_r, tx["256x256"]], p(aux_r, 1.0))]
    for label, args, params in runs:
        r = bc.measure(code, args, chain=B.CHAIN, params=params)
        note(f"E2 1080p ms/pass | {label}", ms(r))
    check("probe ran", 0, 0)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
