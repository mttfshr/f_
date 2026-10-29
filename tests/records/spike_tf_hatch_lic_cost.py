"""
spike_tf_hatch_lic_cost.py -- f_tf_hatch v2 plan Block 1: what does the streamline march (E2) cost on the GPU,
and does a scratch codebox of it match the NumPy mirror? Measurement only: the codebox below is a scratch
shader built here (nothing is written to src/); the production codeboxes come in Block 2, after this.

Decides spec OQ2 (aux read: nearest vs bilinear), OQ3 (N = 8 / 16 / 32) and whether E2 stays one pass,
against the provisional budget "whole module <= 5 ms at 1080p, M3 Max" (spec, cost gate).

The scratch codebox is the sparse-impulse march of tests/modules/tf_hatch/tf_hatch_mirror.py stage_e2:
  in1 = the aux texture (cos a, sin a, coherence, presence), UNSIGNED layout, render-sized (so `dim` is the
        render's: in the bench `dim` is the FIRST input's size)
  out = (raw lit-cells-crossed, presence, 0, 1)
Params are pixel units (half_len, cell_px), as the mirror's.

Part 1, parity at 64 x 64 on a COHERENT field (coherence 1, so the hashed random direction drops out; the
hash of 1e5-scale arguments legitimately differs between GPU and NumPy): GPU raw vs mirror.stage_e2 with
aux_mode "unsigned_nearest". The noise lattice hash sin(ix*127.1 + iy*311.7)*43758 is borderline-sensitive,
so the check is the fraction of pixels that differ by > 0.05, not a max error.
Part 2, cost at 1080p, chain 8 (the bench has 8 slots), median of 3, for N in {8, 16, 32} with nearest aux
reads and N = 16 with bilinear, each at a long kernel (half-length 135 px: far taps, cold texture cache) and a
short one (40 px). The bench's empty-pass floor is ~2.1-2.5 ms, so readings near it are upper bounds
(benchclient.measure reports which).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/records/spike_tf_hatch_lic_cost.py
"""
import paths as _paths  # noqa: F401  (puts tests/modules/* on sys.path, as bench_tf_hatch does)
import statistics
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run
import tf_hatch_mirror as lm

F32 = np.float32
REPEATS = 3
CHAIN = 8

MARCH = """lit_noise(cx, cy, cell_sz, fl) {
    ix = floor(cx / cell_sz);
    iy = floor(cy / cell_sz);
    hv = fract(sin(ix * 127.1 + iy * 311.7) * 43758.5453);
    return 1.0 - step(fl, hv);
}

Param nsteps(16.0);
Param half_len(8.0);
Param cell_px(2.83);
Param fill_frac(0.03);
Param persist_pow(0.5);

wpx = dim.x;
hpx = dim.y;
x0 = norm.x * wpx;
y0 = norm.y * hpx;
nst = max(1.0, floor(nsteps));
h_step = half_len / nst;
ca0 = {READ}(in1, norm).x;
sa0 = {READ}(in1, norm).y;
pres0 = {READ}(in1, norm).w;
acc = lit_noise(x0, y0, cell_px, fill_frac);
idxp = floor(y0) * wpx + floor(x0);
px = x0;
py = y0;
dx = 0.0;
dy = 0.0;
alive = 1.0;
sgn = 1.0;
for (side = 0; side < 2; side += 1) {
    px = x0;
    py = y0;
    alive = 1.0;
    sgn = 1.0 - 2.0 * side;
    dx = sgn * ca0;
    dy = sgn * sa0;
    for (k = 1; k <= nst; k += 1) {
        ux = clamp(px / wpx, 0.001, 0.999);
        uy = clamp(py / hpx, 0.001, 0.999);
        ax = {READ}(in1, vec(ux, uy)).x;
        ay = {READ}(in1, vec(ux, uy)).y;
        coh = {READ}(in1, vec(ux, uy)).z;
        dp = ax * dx + ay * dy;
        flipv = 2.0 * step(0.0, dp) - 1.0;
        ax = ax * flipv;
        ay = ay * flipv;
        wgt = pow(clamp(coh, 0.0, 1.0), persist_pow);
        ang = twopi * fract(sin(idxp * 12.9898 + k * 78.233 + sgn * 37.719) * 43758.5453);
        mx = wgt * ax + (1.0 - wgt) * cos(ang);
        my = wgt * ay + (1.0 - wgt) * sin(ang);
        mm = sqrt(mx * mx + my * my);
        okm = step(0.000001, mm);
        ax = mix(ax, mx / max(mm, 0.000001), okm);
        ay = mix(ay, my / max(mm, 0.000001), okm);
        nx = px + h_step * ax;
        ny = py + h_step * ay;
        alive = alive * step(0.0, nx) * step(nx, wpx) * step(0.0, ny) * step(ny, hpx);
        px = clamp(nx, 0.5, wpx - 0.5);
        py = clamp(ny, 0.5, hpx - 0.5);
        dx = ax;
        dy = ay;
        acc = acc + alive * lit_noise(px, py, cell_px, fill_frac);
    }
}
raw = acc * h_step / cell_px;
out1 = vec(raw, pres0, 0.0, 1.0);
"""

COPY = "out1 = in1;\n"


def code(read):
    return MARCH.replace("{READ}", read)


def field_tex(h, w, along_deg, coh, tr=0.01, strength=100.0):
    """Outlet-0-format tensor texture: constant ALONG axis, coherence `coh` (tests' `field`, any size)."""
    a = np.deg2rad(along_deg)
    gx, gy = np.cos(a + np.pi / 2), np.sin(a + np.pi / 2)
    jxx = tr * ((1 - coh) / 2 + coh * gx * gx)
    jxy = tr * (coh * gx * gy)
    jyy = tr * ((1 - coh) / 2 + coh * gy * gy)
    tex = np.zeros((h, w, 4), F32)
    tex[..., 0] = jxx * strength
    tex[..., 1] = jxy * strength * 0.5 + 0.5
    tex[..., 2] = jyy * strength
    tex[..., 3] = 1.0
    return tex


def rand_tensor_tex(h, w, seed=0, strength=100.0):
    rng = np.random.default_rng(seed)
    tex = np.zeros((h, w, 4), F32)
    jxx = np.abs(rng.normal(0, 0.003, (h, w)))
    jyy = np.abs(rng.normal(0, 0.003, (h, w)))
    jxy = rng.normal(0, 0.002, (h, w))
    tex[..., 0] = (jxx * strength).astype(F32)
    tex[..., 1] = (jxy * strength * 0.5 + 0.5).astype(F32)
    tex[..., 2] = (jyy * strength).astype(F32)
    tex[..., 3] = 1.0
    return tex


def test_parity_vs_mirror():
    h = w = 64
    length, grain = 0.5, 0.75
    half_len = length * lm.HALF_LEN_FRAC * h                       # 8 px
    cell_px = h / 2.0 ** ((1.0 - grain) * lm.GRAIN_SPAN + lm.GRAIN_BASE)   # 2.83 px
    for read, aux_mode in (("nearest", "unsigned_nearest"),):
        aux = lm.stage_e1(field_tex(h, w, 20.0, 1.0), 100.0, aux_mode="unsigned_nearest")
        params = {"nsteps": 16.0, "half_len": half_len, "cell_px": cell_px, "fill_frac": 0.03,
                  "persist_pow": 0.5}
        out, r = bc.run_pass(code(read), [aux], params=params)
        check("status ok", 0 if r["status"] == "ok" else 1, 0)
        ref = lm.stage_e2(aux, n_steps=16, length=length, grain=grain, persist="mix", persist_pow=0.5,
                          aux_mode=aux_mode, fill=0.03)
        d = np.abs(out[..., 0] - ref[..., 0])
        frac = float((d > 0.05).mean())
        note("fraction of pixels differing by > 0.05 (GPU vs mirror, coherent field)", frac)
        note("GPU / mirror mean raw", (float(out[..., 0].mean()), float(ref[..., 0].mean())))
        check("parity: <= 3% of pixels differ by > 0.05", 0.0 if frac <= 0.03 else frac, 0.0)
        check("presence channel", float(np.abs(out[..., 1] - ref[..., 1]).max()), 1e-4)
        check("mean raw within 10%", abs(float(out[..., 0].mean()) / max(float(ref[..., 0].mean()), 1e-9) - 1.0), 0.1)


def test_cost_ladder():
    h, w = 1080, 1920
    tex = rand_tensor_tex(h, w, seed=6)
    aux = lm.stage_e1(tex, 100.0, aux_mode="unsigned_nearest")
    cell = h / 64.0                                              # grain 0.5 at 1080p, ~16.9 px
    base = bc.measure(COPY, [aux], chain=CHAIN, params={})
    floor_ms = base.get("ms_per_pass") or base.get("ms_per_pass_upper_bound")
    note("1080p empty pass (the bench floor), ms/pass", floor_ms)
    rows = []
    for read, nst in (("nearest", 8), ("nearest", 16), ("nearest", 32), ("sample", 16)):
        for half_len in (135.0, 40.0):
            params = {"nsteps": float(nst), "half_len": half_len, "cell_px": cell, "fill_frac": 0.03,
                      "persist_pow": 0.5}
            vals, bound = [], False
            for _ in range(REPEATS):
                r = bc.measure(code(read), [aux], chain=CHAIN, params=params)
                if "ms_per_pass" in r:
                    vals.append(r["ms_per_pass"])
                    bound = True
                else:
                    vals.append(r["ms_per_pass_upper_bound"])
            med = statistics.median(vals)
            rows.append((read, nst, half_len, med, bound))
            kind = "gpu_bound" if bound else "UPPER BOUND (cpu floor)"
            note(f"{read:>7} N={nst:>2} half_len={half_len:>5.0f}px  ms/pass median", f"{med:.2f} ({kind}) samples {[round(v, 2) for v in vals]}")
    # nothing to assert: this is a measurement. One honest sanity check so a dead codebox cannot pass silently.
    check("every row measured", 0 if all(np.isfinite(r[3]) for r in rows) else 1, 0)
    best = min((r for r in rows if r[0] == "nearest" and r[1] == 16), key=lambda r: r[3])
    note("N=16 nearest, best/worst of the two kernel lengths", (best[3], max(r[3] for r in rows if r[0] == "nearest" and r[1] == 16)))


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
