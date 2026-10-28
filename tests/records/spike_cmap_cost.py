"""
spike_cmap_cost.py -- f_cmap T006: cost of the pull pass on the codebox bench, and whether the GPU sampler
matches the mirror (spec NF-001, gate G4). No src/f_cmap codebox exists yet (T020), so the variants are scratch
shaders built here; this is measurement only, nothing is written to src/.

Variants of one pass (z^2 + w pull, bounds = Source, out = decay*hist*(1-inject) + src*inject), differing in
how the previous frame is read:
  copy       out = in1 (the `pass` stage's work, and the bench's floor)
  hw         one hardware sample()
  bil4       bilinear by hand from 4 nearest() taps (the skill's fix for data-dependent coordinates)
  cr16       Catmull-Rom from 16 nearest() taps
Inputs: in1 = the live source, in2 = the previous frame (both render-sized, so `dim` is the render's).

Part 1, correctness at 256 x 144: each variant's GPU output against the float32 mirror, per annulus of |q|.
The skill records that sample() reads NEAREST-like when its coordinate jumps by more than a texel between
neighbouring pixels (the minifying region of this pull, |f'| > 1), so `hw` is also compared with the mirror's
nearest sampler.
Part 2, cost at 1080p and 4K, chain 8, median of 3 (the bench's empty pass floor is ~2.1-2.5 ms, so
readings near it are upper bounds).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/records/spike_cmap_cost.py
"""
import statistics
import sys

import numpy as np

import benchclient as bc
import cmap_mirror as m

REPEATS = 3
CHAIN = 8
SIZES = [("HD (1920x1080)", 1080, 1920), ("4K (3840x2160)", 2160, 3840)]
H, W = 144, 256
PARAMS = dict(wx=0.15, wy=0.0, decay=0.97, inject=0.05)
BINS = [(0.0, 0.08), (0.08, 0.20), (0.20, 0.35), (0.35, 0.50), (0.50, 0.95)]

PRELUDE = """Param wx(0.15);
Param wy(0.0);
Param decay(0.97);
Param inject(0.05);

aspect = dim.x / dim.y;
qx = (norm.x - 0.5) * aspect;
qy = norm.y - 0.5;
zx = qx * 3.5;
zy = qy * 3.5;
rx = zx * zx - zy * zy + wx;
ry = 2.0 * zx * zy + wy;
ppx = rx / (3.5 * aspect) + 0.5;
ppy = ry / 3.5 + 0.5;
ins = step(0.0, ppx) * step(ppx, 1.0) * step(0.0, ppy) * step(ppy, 1.0);
cx = clamp(ppx, 0.0005, 0.9995);
cy = clamp(ppy, 0.0005, 0.9995);
sv = sample(in1, norm);
"""

TAIL = """fillv = mix(sv, hv, ins);
k1 = decay * (1.0 - inject);
res = fillv * k1 + sv * inject + vec(0.0, 0.0, 0.0, 1.0 - k1 - inject);
out1 = res;
"""

HW = "hv = sample(in2, vec(cx, cy));\n"

BIL4 = """tx = cx * dim.x - 0.5;
ty = cy * dim.y - 0.5;
ix = floor(tx);
iy = floor(ty);
ax = tx - ix;
ay = ty - iy;
x0c = (ix + 0.5) / dim.x;
x1c = (ix + 1.5) / dim.x;
y0c = (iy + 0.5) / dim.y;
y1c = (iy + 1.5) / dim.y;
hv = (nearest(in2, vec(x0c, y0c)) * (1.0 - ax) + nearest(in2, vec(x1c, y0c)) * ax) * (1.0 - ay) + (nearest(in2, vec(x0c, y1c)) * (1.0 - ax) + nearest(in2, vec(x1c, y1c)) * ax) * ay;
"""


def cr16():
    lines = ["tx = cx * dim.x - 0.5;", "ty = cy * dim.y - 0.5;", "ix = floor(tx);", "iy = floor(ty);",
             "ax = tx - ix;", "ay = ty - iy;"]
    for a in ("x", "y"):
        v = "a" + a
        lines += [f"t2{a} = {v} * {v};", f"t3{a} = t2{a} * {v};",
                  f"w{a}0 = 0.0 - 0.5 * t3{a} + t2{a} - 0.5 * {v};",
                  f"w{a}1 = 1.5 * t3{a} - 2.5 * t2{a} + 1.0;",
                  f"w{a}2 = 0.0 - 1.5 * t3{a} + 2.0 * t2{a} + 0.5 * {v};",
                  f"w{a}3 = 0.5 * t3{a} - 0.5 * t2{a};"]
    for k, nm in enumerate("abcd"):
        lines.append(f"x{nm} = (ix + {k - 0.5}) / dim.x;")
        lines.append(f"y{nm} = (iy + {k - 0.5}) / dim.y;")
    for j, yn in enumerate("abcd"):
        taps = " + ".join(f"nearest(in2, vec(x{xn}, y{yn})) * wx{i}" for i, xn in enumerate("abcd"))
        lines.append(f"row{j} = {taps};")
    lines.append("hv = row0 * wy0 + row1 * wy1 + row2 * wy2 + row3 * wy3;")
    return "\n".join(lines) + "\n"


VARIANTS = {"copy": "out1 = in1;\n", "hw": PRELUDE + HW + TAIL, "bil4": PRELUDE + BIL4 + TAIL,
            "cr16": PRELUDE + cr16() + TAIL}


REPS = 4        # the amplified variants read the previous frame this many times per pass (offset taps)


def block(kind, k):
    """One read of the previous frame at (cx, cy) + 0.0007 k, every temporary suffixed _k; defines hv_k."""
    s = f"_{k}"
    off = repr(k * 0.0007)
    L = [f"cx{s} = clamp(cx + {off}, 0.0005, 0.9995);", f"cy{s} = clamp(cy + {off}, 0.0005, 0.9995);"]
    if kind == "hw":
        return "\n".join(L + [f"hv{s} = sample(in2, vec(cx{s}, cy{s}));"]) + "\n"
    L += [f"tx{s} = cx{s} * dim.x - 0.5;", f"ty{s} = cy{s} * dim.y - 0.5;", f"ix{s} = floor(tx{s});",
          f"iy{s} = floor(ty{s});", f"ax{s} = tx{s} - ix{s};", f"ay{s} = ty{s} - iy{s};"]
    if kind == "bil4":
        L += [f"x0{s} = (ix{s} + 0.5) / dim.x;", f"x1{s} = (ix{s} + 1.5) / dim.x;",
              f"y0{s} = (iy{s} + 0.5) / dim.y;", f"y1{s} = (iy{s} + 1.5) / dim.y;",
              f"hv{s} = (nearest(in2, vec(x0{s}, y0{s})) * (1.0 - ax{s}) + nearest(in2, vec(x1{s}, y0{s})) * ax{s})"
              f" * (1.0 - ay{s}) + (nearest(in2, vec(x0{s}, y1{s})) * (1.0 - ax{s}) + nearest(in2, vec(x1{s}, y1{s}))"
              f" * ax{s}) * ay{s};"]
        return "\n".join(L) + "\n"
    for a in ("x", "y"):
        v = f"a{a}{s}"
        L += [f"t2{a}{s} = {v} * {v};", f"t3{a}{s} = t2{a}{s} * {v};",
              f"w{a}0{s} = 0.0 - 0.5 * t3{a}{s} + t2{a}{s} - 0.5 * {v};",
              f"w{a}1{s} = 1.5 * t3{a}{s} - 2.5 * t2{a}{s} + 1.0;",
              f"w{a}2{s} = 0.0 - 1.5 * t3{a}{s} + 2.0 * t2{a}{s} + 0.5 * {v};",
              f"w{a}3{s} = 0.5 * t3{a}{s} - 0.5 * t2{a}{s};"]
    for i, nm in enumerate("abcd"):
        L += [f"x{nm}{s} = (ix{s} + {i - 0.5}) / dim.x;", f"y{nm}{s} = (iy{s} + {i - 0.5}) / dim.y;"]
    for j, yn in enumerate("abcd"):
        taps = " + ".join(f"nearest(in2, vec(x{xn}{s}, y{yn}{s})) * wx{i}{s}" for i, xn in enumerate("abcd"))
        L.append(f"row{j}{s} = {taps};")
    L.append(f"hv{s} = row0{s} * wy0{s} + row1{s} * wy1{s} + row2{s} * wy2{s} + row3{s} * wy3{s};")
    return "\n".join(L) + "\n"


def amplified(kind):
    body = "".join(block(kind, k) for k in range(REPS))
    total = " + ".join(f"hv_{k}" for k in range(REPS))
    return PRELUDE + body + f"hv = ({total}) * {1.0 / REPS};\n" + TAIL


VARIANTS_AMP = {"copy": "out1 = in1;\n", **{f"{k}x{REPS}": amplified(k) for k in ("hw", "bil4", "cr16")}}


def smooth_image(h, w, cycles, phases):
    py, px = np.meshgrid((np.arange(h) + 0.5) / h, (np.arange(w) + 0.5) / w, indexing="ij")
    out = np.ones((h, w, 4), np.float32)
    for c in range(3):
        v = 0.5
        for (fx, fy), ph, amp in zip(cycles, phases[c], (0.25, 0.25)):
            v = v + amp * np.cos(2 * np.pi * (fx * px + fy * py) + ph)
        out[..., c] = v
    return out


def correctness():
    src = smooth_image(H, W, ((6, 3), (24, 13)), [(0.3, 1.7), (2.2, 0.4), (4.1, 5.0)])
    prev = smooth_image(H, W, ((5, 4), (22, 15)), [(1.1, 2.7), (0.2, 3.4), (5.1, 0.9)])
    pxn, pyn = m.centred_p(H, W)
    r = np.hypot((pxn - 0.5) * (W / H), pyn - 0.5)
    masks = [(r >= lo) & (r < hi) for lo, hi in BINS]
    kw = dict(n=2, w=(0.15, 0.0), decay=0.97, inject=0.05, bounds="source")
    mirrors = {s: m.frame(prev.copy(), src.copy(), sampler=s, **kw) for s in m.SAMPLERS}
    print(f"=== Part 1: GPU vs mirror at {W}x{H}, mean |err| per annulus  "
          + "  ".join(f"{lo:.2f}-{hi:.2f}" for lo, hi in BINS) + "   max   frac>0.01")
    for name in ("hw", "bil4", "cr16"):
        out, res = bc.run_pass(VARIANTS[name], [src, prev], dim=(W, H), params=PARAMS, timeout_ms=30000)
        if out is None:
            print(f"  {name}: no output ({res})")
            continue
        for ref in (("nearest", "bilinear") if name == "hw" else ("catmull",) if name == "cr16" else ("bilinear",)):
            d = np.abs(out[..., :3].astype(np.float64) - mirrors[ref][..., :3]).max(axis=2)
            cells = "  ".join(f"{float(d[mk].mean()):9.4f}" for mk in masks)
            print(f"  {name:5s} vs mirror {ref:9s} {cells}   {float(d.max()):.3f}   {float((d > 0.01).mean()):.3f}")


def rand(h, w, seed=0):
    a = np.random.default_rng(seed).uniform(0.0, 1.0, (h, w, 4)).astype(np.float32)
    a[..., 3] = 1.0
    return a


def cost(variants=None, title="Part 2"):
    variants = variants or VARIANTS
    print(f"\n=== {title}: cost, ms per pass (chain 8, median of 3; '<' means an upper bound below what the bench resolves) ===")
    table = {}
    for label, h, w in SIZES:
        a, b = rand(h, w, 1), rand(h, w, 2)
        for name, code in variants.items():
            samples, bound = [], None
            for _ in range(REPEATS):
                r = bc.measure(code, [a, b], chain=CHAIN, params=({} if name == "copy" else PARAMS))
                if r["status"] != "ok":
                    raise RuntimeError(f"bench job failed: {r}")
                bound = r["gpu_bound"]
                samples.append(r["ms_per_pass"] if bound else r["ms_per_pass_upper_bound"])
            table[(label, name)] = (statistics.median(samples), bound)
            ms, bd = table[(label, name)]
            print(f"  {label:<16} {name:<5} {'' if bd else '<'}{ms:7.3f} ms/pass")
    return table


def main():
    bc.require_bench()
    correctness()
    cost()
    cost(VARIANTS_AMP, f"Part 3 (each read repeated x{REPS} per pass, offset taps)")
    print("\nfloor reference: `copy` (out = in1). A feedback module is one primary pass plus one `pass` copy.")


if __name__ == "__main__":
    sys.exit(main())
