"""spike_immiscible_stirring_b.py -- T006b: the supercritical stirring test that closes G7.
Thresholds pre-registered in .specify/stable/f_vf_immiscible/tasks.md Record (T006b) before this file existed.
Same stirred velocity as spike_immiscible_stirring.py (imported). Starts: stripes, drops, noise.

Run: . tests/_log.sh >/dev/null; export PYTHONPATH
     uv run --no-project --with numpy --with pillow python3 tests/records/spike_immiscible_stirring_b.py
Stills: tests/logs/immiscible/stirring_b_<start>.png (rows = arms, columns = frames 0 150 300 600).
"""
import os

import numpy as np

import fluid_mirror as fm
import immiscible_mirror as im
from immiscible_mirror import Params
from spike_immiscible_stirring import (EVERY, FRAMES, N, OUT, SNAPS, WARM, advance, components,
                                       fluid_warm, force_tex, gradp99, packed, tanh_phi)

GREF = 1.0 / (np.sqrt(2.0) * 4.0)


def starts():
    i = np.arange(N) + 0.5
    X, Y = np.meshgrid(i, i)
    s = {"stripes": tanh_phi(64.0 - np.abs(X - 128.0))}
    d = np.full((N, N), -1e9)
    for cx, cy in ((64, 64), (192, 64), (64, 192), (192, 192)):
        dx, dy = np.abs(X - cx), np.abs(Y - cy)
        d = np.maximum(d, 0.14 * N - np.hypot(np.minimum(dx, N - dx), np.minimum(dy, N - dy)))
    s["drops"] = tanh_phi(d)
    return s


def main():
    os.makedirs(OUT, exist_ok=True)
    fp, fst = fluid_warm()
    p = Params(iface=4.0, coarsen=0.3, inject=0.0)
    states, params, kind = {}, {}, {}
    for k, v in starts().items():
        for a in ("ch", "plain"):
            states[(k, a)], params[(k, a)], kind[(k, a)] = im.phi_state(v), p, a
    for c in (0.3, 1.0):
        key = ("noise", f"ch@{c}")
        states[key], params[key], kind[key] = im.seed(N, p, 3), p.with_(coarsen=c), "ch"
    rec = {k: [] for k in states}
    snaps = {k: {} for k in states}
    for t in range(FRAMES + 1):
        if t:
            fst = fm.step(fst, force_tex(WARM + t - 1), fp)
        uab = packed(fst)
        for key in states:
            if t:
                states[key] = advance(kind[key], states[key], uab, params[key])
            phi = states[key][..., 0]
            if t in SNAPS:
                snaps[key][t] = phi.copy()
            if t % EVERY == 0:
                g99, _ = gradp99(phi)
                rec[key].append((t, g99, components(phi) if key[0] == "drops" else 0, float(phi.mean()),
                                 float(np.abs(phi).max()), bool(np.isfinite(phi).all())))
    report(rec)
    stills(snaps)


def report(rec):
    print("start   arm      minG[300-600]  G@600   drift@600  comps 0->600  max|phi|  finite")
    res = {}
    for (k, a), r in rec.items():
        if k == "noise":
            continue
        g0 = r[0][1]
        ming = min(x[1] / g0 for x in r if 300 <= x[0] <= 600)
        res[(k, a)] = ming
        drift = abs(r[-1][3] - r[0][3])
        print(f"{k:<7} {a:<8} {ming:<14.3f} {r[-1][1] / g0:<7.3f} {drift:<10.4f} {r[0][2]}->{r[-1][2]:<9} "
              f"{max(x[4] for x in r):<9.4f} {all(x[5] for x in r)}")
    print("\nnoise start: S = p99|grad phi| / 0.1768 every 50 frames, then verdicts")
    ok_all = True
    for (k, a), r in rec.items():
        if k != "noise":
            continue
        S = [(x[0], x[1] / GREF) for x in r]
        mins = min(v for t, v in S if t >= 300)
        mx = max(x[4] for x in r)
        ok = mins >= 0.5 and mx <= 1.25 and all(x[5] for x in r)
        ok_all &= ok
        print(f"{a:<8}", " ".join(f"{v:.2f}" for t, v in S[::2]), f"  minS[300-600] {mins:.3f} max|phi| {mx:.4f}",
              "PASS" if ok else "fail")
    for k in ("stripes", "drops"):
        r = rec[(k, "ch")]
        g0 = r[0][1]
        ming = res[(k, "ch")]
        drift = abs(r[-1][3] - r[0][3])
        ok = (ming >= 0.5 and drift <= 0.02 and all(x[5] for x in r) and max(x[4] for x in r) <= 1.25
              and ming > res[(k, "plain")])
        if k == "drops":
            ok = ok and 1 <= r[-1][2] <= 6
        ok_all &= ok
        print(f"{k}: CH {'PASS' if ok else 'fail'}  (min G {ming:.3f} vs plain {res[(k, 'plain')]:.3f})")
    print("\nmean phi every 100 frames (drift diagnosis, added after the first run):")
    for key, r in rec.items():
        print(f"{key[0]:<8}{key[1]:<8}", " ".join(f"{x[3]:+.4f}" for x in r[::4]))
    print("\nOVERALL (pre-registered):", "PASS" if ok_all else "FAIL")
    print("G(t)/G(0) every 50 frames:")
    for k in ("stripes", "drops"):
        for a in ("ch", "plain"):
            r = rec[(k, a)]
            print(f"{k:<8}{a:<6}", " ".join(f"{x[1] / r[0][1]:.2f}" for x in r[::2]))


def stills(snaps):
    try:
        from PIL import Image
    except ImportError:
        return
    groups = {"stripes": [("stripes", "ch"), ("stripes", "plain")], "drops": [("drops", "ch"), ("drops", "plain")],
              "noise": [("noise", "ch@0.3"), ("noise", "ch@1.0")]}
    for name, keys in groups.items():
        tile = 128
        sheet = np.zeros((tile * len(keys), tile * len(SNAPS)), np.uint8)
        for ri, key in enumerate(keys):
            for ci, t in enumerate(SNAPS):
                sheet[ri * tile:(ri + 1) * tile, ci * tile:(ci + 1) * tile] = (
                    np.clip((snaps[key][t] + 1) / 2, 0, 1)[::2, ::2] * 255).astype(np.uint8)
        path = os.path.join(OUT, f"stirring_b_{name}.png")
        Image.fromarray(sheet).save(path)
        print("still:", os.path.normpath(path), "rows:", ", ".join(k[1] for k in keys))


if __name__ == "__main__":
    main()
