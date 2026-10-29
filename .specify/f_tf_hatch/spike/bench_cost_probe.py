"""
SPIKE (not shipped): why is E2's stroke-texture mode 11.8 ms/pass at 1080p (blobs 2.9)? Measures the shipped
E2 codebox and variants of it on the bench, all at 1080p, same bench and chain as bench_tf_hatch's cost test.

  A  blob mode (src_stroke 0), random aux ........................ the gate's number (baseline)
  B  texture mode as shipped (3 fetches, if/else), random aux, 1080p noise texture
  C  as B, COHERENT aux (a real frame's neighbouring pixels walk similar paths: cache friendly)
  D  texture, ONE fetch (the R channel only), random aux
  E  texture, NO branch (texture code only, no if/else), random aux
  F  texture, one fetch + no branch, random aux
  G  as B, a SMALL (256 x 256) texture: if this is much cheaper, memory access is the cost
  H  one fetch + no branch, COHERENT aux

Needs Max with tests/bench/bench.maxpat open.
  tests/bench.sh -q .specify/f_tf_hatch/spike/bench_cost_probe.py
"""
GROUP = "spike"
ORDER = 999

import paths as _paths  # noqa: F401
import re
import sys

import numpy as np

REPO = _paths.REPO
sys.path.insert(0, str(REPO / "tests" / "modules" / "tf_hatch"))
import bench_tf_hatch as B  # noqa: E402
import benchclient as bc  # noqa: E402
from harness import check, note, run  # noqa: E402

READ3 = "0.2126 * nearest(in2, vec(tu, tv)).x + 0.7152 * nearest(in2, vec(tu, tv)).y + 0.0722 * nearest(in2, vec(tu, tv)).z"


def one_fetch(c):
    assert c.count(READ3) == 2
    return c.replace(READ3, "nearest(in2, vec(tu, tv)).x")


def no_branch(c):
    c2, n = re.subn(r"if \(tex_on > 0\.5\) \{(.*?)\} else \{.*?\}", r"\1", c, flags=re.S)
    assert n == 2, n
    return c2


def ms(r):
    return r.get("ms_per_pass", r.get("ms_per_pass_upper_bound"))


def test_cost_probe_e2_texture_mode():
    m = B.m
    aux_r = m.stage_e1(B.rand_tensor_tex(1080, 1920, seed=6), 0.0, 0.1, "unsigned_nearest")
    aux_c = m.stage_e1(B.field_tex(1080, 1920, 20.0, 1.0), 0.0, 0.1, "unsigned_nearest")
    big, small = B.noise_tex(1080, 1920, 9), B.noise_tex(256, 256, 9)
    base = B.code("e2")
    tex_p = lambda aux: B.e2p(aux, reach=0.5, grain=0.5, src_stroke=1.0)
    runs = [
        ("A blob mode, random aux", base, [aux_r, B.NOTEX], B.e2p(aux_r, reach=0.5, grain=0.5)),
        ("B texture as shipped, random aux, 1080p texture", base, [aux_r, big], tex_p(aux_r)),
        ("C texture as shipped, COHERENT aux, 1080p texture", base, [aux_c, big], tex_p(aux_c)),
        ("D one fetch, random aux", one_fetch(base), [aux_r, big], tex_p(aux_r)),
        ("E no branch, random aux", no_branch(base), [aux_r, big], tex_p(aux_r)),
        ("F one fetch + no branch, random aux", no_branch(one_fetch(base)), [aux_r, big], tex_p(aux_r)),
        ("G texture as shipped, random aux, 256x256 texture", base, [aux_r, small], tex_p(aux_r)),
        ("H one fetch + no branch, COHERENT aux", no_branch(one_fetch(base)), [aux_c, big], tex_p(aux_c)),
    ]
    for label, c, args, params in runs:
        r = bc.measure(c, args, chain=B.CHAIN, params=params)
        note(f"E2 1080p ms/pass | {label}", ms(r))
    check("probe ran", 0, 0)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
