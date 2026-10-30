"""
SPIKE (not shipped), probe 3: can a small anti-aliased PRE-STAGE make Hatch's stroke-texture inlet cheap?
Probes 1-2 (bench_cost_probe*.py): E2 reads a 1080p float32 texture at 12-13 ms, a 256 x 256 one at ~5 ms.
This probe measures variant (c) of the 2026-10-30 plan: a separable box-filter downsample (no texture flags needed).

  accuracy  H pass then V pass (each averages f hand-built nearest() taps), vs the NumPy f x f block mean
  cost      H pass, V pass, a single f x f pass (the unseparated alternative), each at 1x and 8x tap repeats
            (a pass is under the bench's ~0.8 ms resolution, so the repeats amplify it; the taps are offset by
            1e-6 of a texel so the compiler cannot merge them; ms/pass is the 8x figure divided by 8)
  E2        E2 with the 1080p texture vs with the downsampled one (grain 0.5 and 0.0), 16:9 and 1:1

The pre-stage size is the render size / f on each axis, so the aspect follows the render (16:9 and 1:1 here).
Variants (a)/(b), a mipmapped input texture, need texture flags the bench cannot set yet (see the HANDOFF note).

Needs Max with tests/bench/bench.maxpat open.
  tests/bench.sh .specify/f_tf_hatch/spike/bench_downsample_probe.py        (no -q: the numbers are notes)
Results are also appended to downsample_probe_2026-10-30.txt beside this file.
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

F32 = np.float32
OUT = REPO / ".specify" / "f_tf_hatch" / "spike" / "downsample_probe_2026-10-30.txt"
CASES = [("16:9 f=4", 1080, 1920, 4), ("1:1 f=4", 1080, 1080, 4), ("16:9 f=8", 1080, 1920, 8)]


def log(label, value):
    note(label, value)
    with open(OUT, "a") as fh:
        fh.write(f"{label}: {value}\n")


def ms(r):
    return r.get("ms_per_pass", r.get("ms_per_pass_upper_bound"))


def det(r):
    return (f"{ms(r):.3f} [{r.get('status')}, fps {r.get('fps')}, k0 {r.get('fps_baseline_k0')}, "
            f"{'gpu-bound' if r.get('gpu_bound') else 'UPPER BOUND'}]")


def rgba_noise(h, w, seed):
    t = np.random.default_rng(seed).random((h, w, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def blank(h, w):
    t = np.zeros((h, w, 4), F32)
    t[..., 3] = 1.0
    return t


def box_ref(img, f):
    h, w = img.shape[:2]
    return img.astype(np.float64).reshape(h // f, f, w // f, f, 4).mean(axis=(1, 3))


def box_code(axis, src_w, src_h, f, reps=1):
    """One box pass reading in2 (in1 only drives rendering). axis 'h': output (src_w/f) x src_h;
    'v': output src_w x (src_h/f); 'hv': output (src_w/f) x (src_h/f), f*f taps in one pass."""
    L = [f"// SPIKE box pass {axis}, factor {f}, source {src_w}x{src_h}, repeats {reps}",
         "ix = floor(norm.x * dim.x);", "iy = floor(norm.y * dim.y);"]
    terms = []
    for r in range(reps):
        e = f"{r * 1e-6:.7f}"
        for a in range(f):
            for b in (range(f) if axis == "hv" else [0]):
                if axis == "h":
                    u, v = f"(ix * {f}.0 + {a}.5) / {src_w}.0 + {e}", "norm.y"
                elif axis == "v":
                    u, v = "norm.x", f"(iy * {f}.0 + {a}.5) / {src_h}.0 + {e}"
                else:
                    u = f"(ix * {f}.0 + {a}.5) / {src_w}.0 + {e}"
                    v = f"(iy * {f}.0 + {b}.5) / {src_h}.0 + {e}"
                terms.append(f"nearest(in2, vec({u}, {v}))")
    n = len(terms)
    # one tap per statement: a single long sum trips the jit.gl.pix translator's capture limit
    L.append(f"acc = {terms[0]};")
    L += [f"acc = acc + {t};" for t in terms[1:]]
    L.append(f"out1 = acc * {1.0 / n:.9f};")
    return "\n".join(L) + "\n"


def test_box_matches_numpy():
    for label, h, w, f in CASES:
        src = rgba_noise(h, w, 3)
        ow, oh = w // f, h // f
        h_out, _ = bc.run_pass(box_code("h", w, h, f), [blank(h, ow), src], dim=(ow, h))
        v_out, _ = bc.run_pass(box_code("v", ow, h, f), [blank(oh, ow), h_out], dim=(ow, oh))
        hv_out, _ = bc.run_pass(box_code("hv", w, h, f), [blank(oh, ow), src], dim=(ow, oh))
        ref = box_ref(src, f)
        log(f"accuracy {label}: out size {v_out.shape[1]}x{v_out.shape[0]}", "")
        check(f"{label} separable max err", np.abs(v_out - ref).max(), 2e-5)
        check(f"{label} single-pass max err", np.abs(hv_out - ref).max(), 2e-5)


def test_box_cost():
    for label, h, w, f in CASES:
        src = rgba_noise(h, w, 3)
        ow, oh = w // f, h // f
        mid = rgba_noise(h, ow, 4)
        for reps in (1, 8):
            rh = bc.measure(box_code("h", w, h, f, reps), [blank(h, ow), src], dim=(ow, h), chain=B.CHAIN)
            rv = bc.measure(box_code("v", ow, h, f, reps), [blank(oh, ow), mid], dim=(ow, oh), chain=B.CHAIN)
            rs = bc.measure(box_code("hv", w, h, f, reps), [blank(oh, ow), src], dim=(ow, oh), chain=B.CHAIN)
            for nm, r in (("H pass", rh), ("V pass", rv), ("single f x f pass", rs)):
                v = ms(r)
                tag = "gpu-bound" if r.get("gpu_bound") else "upper bound"
                log(f"cost {label} {nm} x{reps} repeats ({tag}), ms/pass", det(r) + f"  per repeat {v / reps:.3f}")
    check("ran", 0, 0)


def test_e2_with_small_texture():
    m = B.m
    code = B.code("e2")
    for label, h, w, f in CASES[:2]:
        aux = m.stage_e1(B.rand_tensor_tex(h, w, seed=6), 0.0, 0.1, "unsigned_nearest")
        small = B.noise_tex(h // f, w // f, 9)
        full = B.noise_tex(h, w, 9)
        for g in (0.5, 0.0):
            rs = bc.measure(code, [aux, small], chain=B.CHAIN, params=B.e2p(aux, reach=0.5, grain=g, src_stroke=1.0))
            rf = bc.measure(code, [aux, full], chain=B.CHAIN, params=B.e2p(aux, reach=0.5, grain=g, src_stroke=1.0))
            log(f"E2 {label} grain {g}: full texture {w}x{h} ms/pass", det(rf))
            log(f"E2 {label} grain {g}: small texture {w // f}x{h // f} ms/pass", det(rs))
        rb = bc.measure(code, [aux, B.NOTEX], chain=B.CHAIN, params=B.e2p(aux, reach=0.5, grain=0.5))
        log(f"E2 {label}: blobs (no texture) ms/pass", det(rb))
    check("ran", 0, 0)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
