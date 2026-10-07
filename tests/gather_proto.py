"""
gather_proto.py -- prototype of the multi-start gather as a jit.gl.pix codebox: compile check,
correctness against the NumPy mirror, and GPU cost (spike for ideas/optics_map.md,
"Findings: multi-guess gather"; question: is a pull-based "sheets" mode for f_caustic affordable?).

A throwaway prototype, not a module: nothing here ships. It runs on the CODEBOX bench
(tests/bench/bench.maxpat), which, unlike the module bench, runs uncapped and so can resolve GPU time.

Per output pixel:  S*S sub-samples (a gather must integrate over the pixel); per sub-sample: G*G coarse
points around the pixel, each tested with |u + d F(u) - x|; the M best become Newton starts; T damped
Newton steps each, then accept / de-duplicate / sum 1/|det(I + d J)|.
in1 = source (unused here), in2 = f_vecfield texture (RG = F * 0.5 + 0.5). out1 = illuminance (grey).
The field is read with wrap-around (u - floor(u)), as the NumPy mirror does.

FINDING 2026-10-06 (first attempt, `make_code_unrolled`): fully unrolled (G=6, M=6, T=8, S=2 = 1,810 lines,
110 KB) does NOT compile: Max's codebox parser raised "lua: [string DSL.Parser]:393: stack overflow (too many
captures)", the output did not match the mirror (r = -0.07), and the "cost" numbers from that run measured a
shader that never compiled, so they were discarded. `make_code` keeps the repetition in `for` loops instead.

Run:  uv run --no-project --with numpy python3 tests/gather_proto.py            (ladder + cost)
      uv run --no-project --with numpy python3 tests/gather_proto.py code        (print the generated code)
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent / "scratch"))

LAM, TOL, DEDUP, EPS, STEP_CAP = 0.05, 1e-4, 2e-3, 0.05, 0.1     # same constants as multi_guess_gather2.py

TEMPS = ("wu wv fx fy xpx xpy xmx xmy ypx ypy ymx ymy gx gy na nb nc nd m11 m12 m22 r1 r2 dm stx sty kk ac dtm dk "
         "ic x0 y0 sox soy cx cy qx qy rs isless carr carx cary tr tx ty jx jy res0").split()


def _fetch(prefix="", uu="wu", vv="wv", k=256.0, bil=False):
    """GenExpr lines that read field and slopes at (uu, vv): fx fy and the four neighbours.
    k = 1 / (2 * hh) = fsize / 2 (central-difference scale). bil=True reads through the hand-made bilinear
    function fxy() (four exact nearest() taps) instead of sample(): see the FINDING in make_code_fn."""
    if bil:
        return [
            f"{prefix}fx, fy = fxy({uu}, {vv});",
            f"{prefix}xpx, xpy = fxy({uu} + hh, {vv});",
            f"{prefix}xmx, xmy = fxy({uu} - hh, {vv});",
            f"{prefix}ypx, ypy = fxy({uu}, {vv} + hh);",
            f"{prefix}ymx, ymy = fxy({uu}, {vv} - hh);",
            f"{prefix}na = 1.0 + d * (xpx - xmx) * {k};  nb = d * (ypx - ymx) * {k};",
            f"{prefix}nc = d * (xpy - xmy) * {k};  nd = 1.0 + d * (ypy - ymy) * {k};",
        ]
    return [
        f"{prefix}fx = (sample(in2, vec({uu}, {vv})).x - 0.5) * 2.0;  fy = (sample(in2, vec({uu}, {vv})).y - 0.5) * 2.0;",
        f"{prefix}xpx = (sample(in2, vec({uu} + hh, {vv})).x - 0.5) * 2.0;  xpy = (sample(in2, vec({uu} + hh, {vv})).y - 0.5) * 2.0;",
        f"{prefix}xmx = (sample(in2, vec({uu} - hh, {vv})).x - 0.5) * 2.0;  xmy = (sample(in2, vec({uu} - hh, {vv})).y - 0.5) * 2.0;",
        f"{prefix}ypx = (sample(in2, vec({uu}, {vv} + hh)).x - 0.5) * 2.0;  ypy = (sample(in2, vec({uu}, {vv} + hh)).y - 0.5) * 2.0;",
        f"{prefix}ymx = (sample(in2, vec({uu}, {vv} - hh)).x - 0.5) * 2.0;  ymy = (sample(in2, vec({uu}, {vv} - hh)).y - 0.5) * 2.0;",
        f"{prefix}na = 1.0 + d * (xpx - xmx) * {k};  nb = d * (ypx - ymx) * {k};",
        f"{prefix}nc = d * (xpy - xmy) * {k};  nd = 1.0 + d * (ypy - ymy) * {k};",
    ]


def make_code(G=6, M=6, T=8, S=2, debug=None, fsize=256):
    """Loop-based generator: statement count grows with M, not with M*T or G*G*M.
    fsize = side of the field texture in pixels; it must equal the pix output size for 1:1 (bilinear) sampling."""
    kslope = fsize / 2.0
    out = []
    w = out.append
    n_sub = S * S
    w("Param d(0.1);")
    w("Param peak(0.9);")
    w("Param tol(0.0003);")                                               # acceptance tolerance, UV (0.08 px)
    for name in TEMPS:                                                    # declare everything before any loop
        w(f"{name} = 0.0;")
    for i in range(M):
        w(f"rb{i} = 1000.0;  sx{i} = 0.0;  sy{i} = 0.0;  ux{i} = 0.0;  uy{i} = 0.0;  ac{i} = 0.0;")
    w("total = 0.0;")
    w("rho = d * peak;")
    w(f"hh = {1.0 / fsize};")                                             # one texel of the field texture
    w(f"for (s = 0; s < {n_sub}; s += 1) {{")
    w(f"  sox = (mod(s, {S}) + 0.5) / {S} - 0.5;")
    w(f"  soy = (floor(s / {S}) + 0.5) / {S} - 0.5;")
    w("  x0 = norm.x + sox / dim.x;")
    w("  y0 = norm.y + soy / dim.y;")
    w("  ic = 0.0;")
    for i in range(M):
        w(f"  rb{i} = 1000.0;  sx{i} = x0;  sy{i} = y0;")
    # coarse pass: residual of each coarse point, keep the M smallest by sorted insertion
    w(f"  for (j = 0; j < {G * G}; j += 1) {{")
    w(f"    jx = mod(j, {G});  jy = floor(j / {G});")
    w(f"    cx = x0 + (-1.0 + 2.0 * jx / {G - 1}) * rho;")
    w(f"    cy = y0 + (-1.0 + 2.0 * jy / {G - 1}) * rho;")
    w("    wu = cx - floor(cx);  wv = cy - floor(cy);")
    w("    fx = (sample(in2, vec(wu, wv)).x - 0.5) * 2.0;")
    w("    fy = (sample(in2, vec(wu, wv)).y - 0.5) * 2.0;")
    w("    qx = cx + d * fx - x0;  qy = cy + d * fy - y0;")
    w("    carr = sqrt(qx * qx + qy * qy);  carx = cx;  cary = cy;")
    for i in range(M):
        w(f"    isless = 1.0 - step(rb{i}, carr);")
        w(f"    tr = switch(isless, rb{i}, carr);  tx = switch(isless, sx{i}, carx);  ty = switch(isless, sy{i}, cary);")
        w(f"    rb{i} = switch(isless, carr, rb{i});  sx{i} = switch(isless, carx, sx{i});  sy{i} = switch(isless, cary, sy{i});")
        w("    carr = tr;  carx = tx;  cary = ty;")
    w("  }")
    # Newton from each start (T steps in a loop), then accept / de-duplicate / accumulate
    for m in range(M):
        w(f"  ux{m} = sx{m};  uy{m} = sy{m};")
        w(f"  for (it = 0; it < {T}; it += 1) {{")
        w(f"    wu = ux{m} - floor(ux{m});  wv = uy{m} - floor(uy{m});")
        for line in _fetch("    ", k=kslope):
            w(line)
        w(f"    gx = ux{m} + d * fx - x0;  gy = uy{m} + d * fy - y0;")
        w(f"    m11 = na * na + nc * nc + {LAM};  m12 = na * nb + nc * nd;  m22 = nb * nb + nd * nd + {LAM};")
        w("    r1 = na * gx + nc * gy;  r2 = nb * gx + nd * gy;")
        w("    dm = m11 * m22 - m12 * m12;")
        w("    stx = (m22 * r1 - m12 * r2) / dm;  sty = (m11 * r2 - m12 * r1) / dm;")
        w(f"    kk = min(1.0, {STEP_CAP} / max(sqrt(stx * stx + sty * sty), 0.000000000001));")
        w(f"    ux{m} = ux{m} - stx * kk;  uy{m} = uy{m} - sty * kk;")
        w("  }")
        w(f"  wu = ux{m} - floor(ux{m});  wv = uy{m} - floor(uy{m});")
        for line in _fetch("  ", k=kslope):
            w(line)
        w(f"  gx = ux{m} + d * fx - x0;  gy = uy{m} + d * fy - y0;")
        if m == 0:
            w("  res0 = sqrt(gx * gx + gy * gy);")
        w(f"  ac = 1.0 - step(tol, sqrt(gx * gx + gy * gy));")
        w("  dtm = na * nd - nb * nc;")
        for k in range(m):
            w(f"  dk = sqrt((ux{m} - ux{k}) * (ux{m} - ux{k}) + (uy{m} - uy{k}) * (uy{m} - uy{k}));")
            w(f"  ac = ac * (1.0 - ac{k} * (1.0 - step({DEDUP}, dk)));")
        w(f"  ac{m} = ac;")
        w(f"  ic = ic + ac{m} / max(abs(dtm), {EPS});")
    w("  total = total + ic;")
    w("}")
    if debug == "sel":                                    # first slot: residual and offset (S = 1 only)
        w("out1 = vec(rb0, sx0 - x0, sy0 - y0, 1.0);")
    elif debug == "newton":                               # first Newton start after T steps (S = 1 only)
        w("out1 = vec(ux0 - x0, uy0 - y0, ac0, 1.0);")
    elif debug == "res":                                  # its final residual |u + dF(u) - x| (S = 1 only)
        w("out1 = vec(res0, 0.0, 0.0, 1.0);")
    else:
        w(f"lum = total / {float(n_sub)};")
        w("out1 = vec(lum, lum, lum, 1.0);")
    return "\n".join(out) + "\n"


def _make_code_fn_core(G=6, M=6, T=8, S=2, fsize=256):
    """Same algorithm as make_code, but one Newton start is a GenExpr FUNCTION called M times, so the program
    grows by a few lines per start instead of ~35 (functions: sample(in2) inside, loops, multi-return all
    probed OK 2026-10-06). The function cannot see Params: d and tol are passed in."""
    kslope = fsize / 2.0
    out = []
    w = out.append
    n_sub = S * S
    ftemps = "wu wv fx fy xpx xpy xmx xmy ypx ypy ymx ymy gx gy na nb nc nd m11 m12 m22 r1 r2 dm stx sty kk".split()
    w("nstart(sx, sy, x0, y0, d, tol) {")
    for name in ftemps:
        w(f"  {name} = 0.0;")
    w("  ux = sx;  uy = sy;")
    w(f"  hh = {1.0 / fsize};")
    w(f"  for (it = 0; it < {T}; it += 1) {{")
    w("    wu = ux - floor(ux);  wv = uy - floor(uy);")
    for line in _fetch("    ", k=kslope):
        w(line)
    w("    gx = ux + d * fx - x0;  gy = uy + d * fy - y0;")
    w(f"    m11 = na * na + nc * nc + {LAM};  m12 = na * nb + nc * nd;  m22 = nb * nb + nd * nd + {LAM};")
    w("    r1 = na * gx + nc * gy;  r2 = nb * gx + nd * gy;")
    w("    dm = m11 * m22 - m12 * m12;")
    w("    stx = (m22 * r1 - m12 * r2) / dm;  sty = (m11 * r2 - m12 * r1) / dm;")
    w(f"    kk = min(1.0, {STEP_CAP} / max(sqrt(stx * stx + sty * sty), 0.000000000001));")
    w("    ux = ux - stx * kk;  uy = uy - sty * kk;")
    w("  }")
    w("  wu = ux - floor(ux);  wv = uy - floor(uy);")
    for line in _fetch("  ", k=kslope):
        w(line)
    w("  gx = ux + d * fx - x0;  gy = uy + d * fy - y0;")
    w("  okk = 1.0 - step(tol, sqrt(gx * gx + gy * gy));")
    w(f"  ivd = 1.0 / max(abs(na * nd - nb * nc), {EPS});")
    w("  return ux, uy, okk, ivd;")
    w("}")
    w("Param d(0.1);")
    w("Param peak(0.9);")
    w("Param tol(0.001);")
    for name in "x0 y0 sox soy cx cy qx qy rs isless carr carx cary tr tx ty jx jy wu wv fx fy ic dk ac".split():
        w(f"{name} = 0.0;")
    for i in range(M):
        w(f"rb{i} = 1000.0;  sx{i} = 0.0;  sy{i} = 0.0;  ux{i} = 0.0;  uy{i} = 0.0;  ok{i} = 0.0;  iv{i} = 0.0;  ac{i} = 0.0;")
    w("total = 0.0;")
    w("rho = d * peak;")
    w(f"for (s = 0; s < {n_sub}; s += 1) {{")
    w(f"  sox = (mod(s, {S}) + 0.5) / {S} - 0.5;")
    w(f"  soy = (floor(s / {S}) + 0.5) / {S} - 0.5;")
    w("  x0 = norm.x + sox / dim.x;")
    w("  y0 = norm.y + soy / dim.y;")
    w("  ic = 0.0;")
    for i in range(M):
        w(f"  rb{i} = 1000.0;  sx{i} = x0;  sy{i} = y0;")
    w(f"  for (j = 0; j < {G * G}; j += 1) {{")
    w(f"    jx = mod(j, {G});  jy = floor(j / {G});")
    w(f"    cx = x0 + (-1.0 + 2.0 * jx / {G - 1}) * rho;")
    w(f"    cy = y0 + (-1.0 + 2.0 * jy / {G - 1}) * rho;")
    w("    wu = cx - floor(cx);  wv = cy - floor(cy);")
    w("    fx = (sample(in2, vec(wu, wv)).x - 0.5) * 2.0;")
    w("    fy = (sample(in2, vec(wu, wv)).y - 0.5) * 2.0;")
    w("    qx = cx + d * fx - x0;  qy = cy + d * fy - y0;")
    w("    carr = sqrt(qx * qx + qy * qy);  carx = cx;  cary = cy;")
    for i in range(M):
        w(f"    isless = 1.0 - step(rb{i}, carr);")
        w(f"    tr = switch(isless, rb{i}, carr);  tx = switch(isless, sx{i}, carx);  ty = switch(isless, sy{i}, cary);")
        w(f"    rb{i} = switch(isless, carr, rb{i});  sx{i} = switch(isless, carx, sx{i});  sy{i} = switch(isless, cary, sy{i});")
        w("    carr = tr;  carx = tx;  cary = ty;")
    w("  }")
    for m in range(M):
        w(f"  ux{m}, uy{m}, ok{m}, iv{m} = nstart(sx{m}, sy{m}, x0, y0, d, tol);")
        w(f"  ac = ok{m};")
        for k in range(m):
            w(f"  dk = sqrt((ux{m} - ux{k}) * (ux{m} - ux{k}) + (uy{m} - uy{k}) * (uy{m} - uy{k}));")
            w(f"  ac = ac * (1.0 - ac{k} * (1.0 - step({DEDUP}, dk)));")
        w(f"  ac{m} = ac;  ic = ic + ac{m} * iv{m};")
    w("  total = total + ic;")
    w("}")
    w(f"lum = total / {float(n_sub)};")
    w("out1 = vec(lum, lum, lum, 1.0);")
    return "\n".join(out) + "\n"


# ------------------------------------------------------------------ hand-made bilinear (the fix)
# FINDING 2026-10-06 (bisected on the bench, see ideas/optics_map.md): jit.gl.pix `sample()` does NOT stay bilinear
# when the coordinate is data-dependent and jumps between neighbouring pixels (Newton starts from different coarse
# cells, ray marching, any dependent read). Texture filtering chooses magnify/minify from the coordinate's
# screen-space derivative; above ~1 texel per pixel it falls back to the NEAREST minification filter, so the field
# is read piecewise-constant (error up to half a texel of variation: median 6e-3 against 2e-5 at pixel-aligned
# coordinates) and Newton cannot converge. The same mechanism is why a source larger than the pix reads
# nearest-like. Fix: interpolate yourself from four exact nearest() taps.
def _fxy_function(fsize):
    W = float(fsize)
    lines = ["fxy(u, v) {",
             f"  tx = u * {W} - 0.5;  ty = v * {W} - 0.5;",
             "  ix = floor(tx);  iy = floor(ty);",
             "  ax = tx - ix;  ay = ty - iy;",
             f"  x0c = (ix + 0.5) / {W};  x1c = (ix + 1.5) / {W};  y0c = (iy + 0.5) / {W};  y1c = (iy + 1.5) / {W};"]
    for comp, name in ((".x", "px"), (".y", "py")):
        lines.append(f"  {name} = (nearest(in2, vec(x0c, y0c)){comp} * (1.0 - ax) + nearest(in2, vec(x1c, y0c)){comp} * ax) * (1.0 - ay)"
                     f" + (nearest(in2, vec(x0c, y1c)){comp} * (1.0 - ax) + nearest(in2, vec(x1c, y1c)){comp} * ax) * ay;")
    lines += ["  return (px - 0.5) * 2.0, (py - 0.5) * 2.0;", "}"]
    return "\n".join(lines) + "\n"


def make_code_fn(G=6, M=6, T=8, S=2, fsize=256, bil=False):
    """Function-based gather (see _make_code_fn_core). bil=True reads the field through fxy() instead of sample()."""
    code = _make_code_fn_core(G, M, T, S, fsize)
    if not bil:
        return code
    import re
    pair = re.compile(r"(\w+) = \(sample\(in2, vec\(([^,()]+), ([^,()]+)\)\)\.x - 0\.5\) \* 2\.0;\s+"
                      r"(\w+) = \(sample\(in2, vec\(\2, \3\)\)\.y - 0\.5\) \* 2\.0;")
    code = pair.sub(r"\1, \4 = fxy(\2, \3);", code)
    assert "sample(in2" not in code, "a field read was left on sample()"
    return _fxy_function(fsize) + code


# ------------------------------------------------------------------ the run
def analytic_field(cf, n):
    """The test glass's f_vecfield as an n x n float32 texture (RG = F * 0.5 + 0.5), sampled at texel centres.
    It must be the same size as the pix output: a larger source is read nearest-neighbour (bench-verified)."""
    c = (np.arange(n) + 0.5) / n
    X, Y = np.meshgrid(c, c)
    fx, fy = cf.field(X, Y)[:2]
    tex = np.zeros((n, n, 4), np.float32)
    tex[..., 0], tex[..., 1], tex[..., 2], tex[..., 3] = fx / 2 + 0.5, fy / 2 + 0.5, 0.5, 1.0
    return tex


def ensure_codebox_bench(bc):
    import socket
    if bc.ping(1.0, ports=bc.CODEBOX_PORTS):
        return
    with bc.Channel(bc.MODULE_PORTS) as ch:                  # close the module bench first
        ch.send("/close")
        try:
            ch.wait_for(lambda a, _: a in ("/closing", "/busy"), 1.0)
        except socket.timeout:
            pass
    print("codebox bench not open: reopening it (Max comes to the front)")
    bc.reopen(wait=40.0)


def ensure_healthy(bc):
    """A compile failure (seen 2026-10-06: the parser stack overflow on an oversized program) can wedge the
    bench so later jobs return a STALE image whatever the code is, with no error. Probe with a known-good
    codebox before every configuration and reopen the bench if the answer is wrong."""
    probe = np.zeros((16, 16, 4), np.float32)
    probe[..., 3] = 1.0
    for _ in range(2):
        out, _rep = bc.run_pass("out1 = vec(0.25, 0.5, 0.75, 1.0);", [probe], timeout_ms=15000)
        if out is not None and abs(out[..., 0].mean() - 0.25) < 1e-3 and abs(out[..., 2].mean() - 0.75) < 1e-3:
            return
        print("   (bench returned a stale image: reopening it)", flush=True)
        bc.reopen(wait=40.0)
    raise RuntimeError("bench still unhealthy after reopening")


def check(bc, cf, mg, code, G, M, T, S, fr, field, white, tol=1e-3):
    """Run one pass and compare with the NumPy mirror. Returns (matches_mirror, compiled_and_ran, text)."""
    ensure_healthy(bc)
    d = fr * cf.first_fold_distance()
    img, rep = bc.run_pass(code, [white, field], dim=(256, 256), params={"d": d, "peak": 0.9, "tol": tol}, timeout_ms=90000)
    errs = rep.get("errors") or []
    if img is None or rep.get("status") not in ("ok",):
        return False, False, f"status {rep.get('status')}, errors {len(errs)}: " + (errs[0][:140] if errs else "")
    lo, hi = mg.CROP
    gpu = img[lo:hi, lo:hi, 0].astype(np.float64)
    mg.TOL = tol                                           # the mirror uses the same acceptance tolerance
    mg.TEX, mg.H = field, 1.0 / field.shape[0]             # ... and the same field texture and slope step
    ref, _, _, _ = mg.run(d, mg.ev_texture, ("coarse", G, 100.0, M), T, 17.6)
    truth = cf.truth(d)[lo:hi, lo:hi]
    r = cf.pearson(gpu, ref)
    ok = (r > 0.9) and abs(gpu.mean() - ref.mean()) < 0.1 * max(ref.mean(), 1e-6) and not errs
    return ok, not errs, (f"errors {len(errs)}; GPU vs mirror r = {r:.4f}, mean GPU {gpu.mean():.4f} vs mirror {ref.mean():.4f}; "
                          f"vs truth: GPU r {cf.pearson(gpu, truth):.3f} IoU {cf.top_iou(gpu, truth):.3f}, "
                          f"mirror r {cf.pearson(ref, truth):.3f} IoU {cf.top_iou(ref, truth):.3f}")


def main():
    import benchclient as bc
    import caustic_fidelity as cf
    import multi_guess_gather2 as mg

    if len(sys.argv) > 1 and sys.argv[1] == "code":
        print(make_code())
        return
    ensure_codebox_bench(bc)
    field = analytic_field(cf, 256)                        # same size as the output: 1:1, bilinear
    white = np.ones((256, 256, 4), np.float32)

    print("== size ladder: does it compile AND match the NumPy mirror? (d = 3.5 d*, central 96x96 crop, S as listed)")
    ladder = [(4, 2, 3, 1), (6, 3, 4, 1), (6, 4, 6, 2), (6, 4, 8, 2), (6, 5, 6, 2)]
    good = []
    for (G, M, T, S) in ladder:
        code = make_code(G, M, T, S)
        try:
            ok, compiled, text = check(bc, cf, mg, code, G, M, T, S, 3.5, field, white)
        except Exception as e:
            ok, compiled, text = False, False, f"{type(e).__name__}: {e}"
        verdict = "matches mirror" if ok else ("compiled, output differs from mirror" if compiled else "DID NOT COMPILE")
        print(f"  G={G} M={M} T={T} S={S}  ({code.count(chr(10))} lines, {len(code) // 1024} KB): {verdict}: {text}", flush=True)
        if compiled:
            good.append((G, M, T, S))

    print("\n== cost (codebox bench, uncapped; K chained copies; ms per pass only when GPU-bound)")
    print("   measured for every config that COMPILES; the output of these configs is still below the NumPy mirror,")
    print("   so this is the cost of the shader's structure, not yet of a correct gather")
    d = 2.0 * cf.first_fold_distance()
    for dim in (256, 512):                                 # reference: an empty pass, to show the ceiling and that measure() works
        r0 = bc.measure("out1 = in1;", [np.ones((dim, dim, 4), np.float32)], dim=(dim, dim), chain=8)
        print(f"  reference  out1 = in1   {dim}^2  chain 8: fps {r0.get('fps', 0):.0f}  "
              f"(frame {r0.get('frame_ms', float('nan')):.2f} ms, baseline K=0 {r0.get('frame_ms_k0', float('nan')):.2f} ms)", flush=True)
    for (G, M, T, S) in good:
        ensure_healthy(bc)
        for dim in (256, 512):
            code = make_code(G, M, T, S, fsize=dim)
            win = np.ones((dim, dim, 4), np.float32)
            fld = analytic_field(cf, dim)                  # field at the output size, so sampling stays 1:1
            for chain in (1, 4, 8, 16, 32):
                try:
                    r = bc.measure(code, [win, fld], dim=(dim, dim), chain=chain, params={"d": d, "peak": 0.9, "tol": 1e-3})
                except Exception as e:
                    print(f"  G={G} M={M} T={T} S={S}  {dim}^2  chain {chain}: FAILED {type(e).__name__}: {e}")
                    break
                tag = (f"{r['ms_per_pass']:.2f} ms/pass (GPU-bound)" if r.get("gpu_bound")
                       else f"<= {r.get('ms_per_pass_upper_bound', float('nan')):.2f} ms/pass (not GPU-bound)")
                print(f"  G={G} M={M} T={T} S={S}  {dim}^2  chain {chain}: fps {r.get('fps', 0):.0f}  {tag}  "
                      f"[{r.get('status')}, errors {len(r.get('errors') or [])}]", flush=True)
                if r.get("gpu_bound"):
                    break


if __name__ == "__main__":
    main()
