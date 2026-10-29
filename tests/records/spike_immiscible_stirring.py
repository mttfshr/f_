"""spike_immiscible_stirring.py -- T006 / experiment 1 (decides G7) and experiment 3 (coarsening
under stirring) for f_vf_immiscible. Thresholds were pre-registered in
.specify/stable/f_vf_immiscible/tasks.md Record (T005) before this file existed.

One stirred fluid_mirror Fluid (N 256, seed-free: deterministic drifting-cell force) advects phi in
every arm; A = B = u so the blend is neutral. Arms: ch (Cahn-Hilliard, the module's step), plain
(advection only), sh<s> (advection + pointwise sharpening phi += s phi (1 - phi^2)).
Starts: blob, filaments of 1/3/8 texels, a coalescence pair, plus a noise start for coarsening.

Run: uv run --no-project --with numpy --with pillow python3 tests/records/spike_immiscible_stirring.py vel
     (same with `run`; `vel` only prints the velocity scale check that T005 requires first)
Needs the test import path:  . tests/_log.sh >/dev/null; export PYTHONPATH
Stills: tests/logs/immiscible/stirring_<start>.png (rows = arms, columns = frames 0 150 300 600).
"""
import collections
import os
import sys
import time

import numpy as np

import fluid_mirror as fm
import immiscible_mirror as im
from gpu_sim import F32
from immiscible_mirror import Params

N = 256
AMP = float(os.environ.get("STIR_AMP", "0.6"))
WARM, FRAMES, EVERY = 200, 600, 25
SNAPS = (0, 150, 300, 600)
OUT = os.path.join(os.path.dirname(__file__), "..", "logs", "immiscible")
SHARP = (0.001, 0.003, 0.01, 0.03)


def force_tex(t):
    c = (np.arange(N) + 0.5) / N
    fx = AMP * np.sin(2 * np.pi * 2 * c[:, None] + 0.03 * t) * np.ones((1, N))
    fy = AMP * np.sin(2 * np.pi * 3 * c[None, :] - 0.02 * t) * np.ones((N, 1))
    tex = np.zeros((N, N, 4), F32)
    tex[..., 0], tex[..., 1], tex[..., 2], tex[..., 3] = 0.5 + 0.5 * fx, 0.5 + 0.5 * fy, 0.5, 1.0
    return tex


def packed(vel):
    u = np.zeros((N, N, 4), F32)
    u[..., 0] = u[..., 2] = vel[..., 0]
    u[..., 1] = u[..., 3] = vel[..., 2]
    return u


def tanh_phi(d, iface=4.0):
    return np.tanh(d / (np.sqrt(2.0) * iface)).astype(F32)


def starts():
    i = np.arange(N) + 0.5
    X, Y = np.meshgrid(i, i)
    def blob(cx, cy, r):
        dx, dy = np.abs(X - cx), np.abs(Y - cy)
        dx, dy = np.minimum(dx, N - dx), np.minimum(dy, N - dy)
        return r * N - np.hypot(dx, dy)
    s = {"blob": tanh_phi(blob(128, 128, 0.12))}
    for w in (1, 3, 8):
        s[f"fil{w}"] = tanh_phi(w / 2.0 - np.abs(X - 128))
    s["pair"] = tanh_phi(np.maximum(blob(128 - 25.6, 128, 0.08), blob(128 + 25.6, 128, 0.08)))
    return s


def gradp99(phi):
    p = phi.astype(np.float64)
    gx, gy = (np.roll(p, -1, 1) - np.roll(p, 1, 1)) / 2, (np.roll(p, -1, 0) - np.roll(p, 1, 0)) / 2
    return float(np.percentile(np.hypot(gx, gy), 99)), float(np.hypot(gx, gy).mean())


def components(phi, min_area=16):
    pos, seen, n = phi > 0, np.zeros(phi.shape, bool), 0
    for sy, sx in zip(*np.nonzero(pos)):
        if seen[sy, sx]:
            continue
        q, area = collections.deque([(sy, sx)]), 0
        seen[sy, sx] = True
        while q:
            y, x = q.popleft()
            area += 1
            for yy, xx in (((y + 1) % N, x), ((y - 1) % N, x), (y, (x + 1) % N), (y, (x - 1) % N)):
                if pos[yy, xx] and not seen[yy, xx]:
                    seen[yy, xx] = True
                    q.append((yy, xx))
        n += area >= min_area
    return n


def advance(arm, st, uab, p):
    a = im.adv(st, uab, None, p)
    if arm == "ch":
        return im.ix_cleanup(fm.ifft2_np(im.spec(fm.fft2_np(a), p)))
    phi = a[..., 0]
    if arm.startswith("sh"):
        s = F32(float(arm[2:]))
        phi = np.clip(phi + s * phi * (F32(1) - phi * phi), -1, 1).astype(F32)
    return im.phi_state(phi)


def fluid_warm():
    fp, st = fm.Params(viscosity=0.3), fm.zero_state(N)
    for t in range(WARM):
        st = fm.step(st, force_tex(t), fp)
    return fp, st


def vel():
    fp, st = fluid_warm()
    sp = np.hypot(st[..., 0], st[..., 2])
    print(f"force amp {AMP}: after {WARM} warm-up frames  rms|u| = {np.sqrt((sp ** 2).mean()):.3f}  "
          f"max|u| = {sp.max():.3f}   displacement per frame at rms: {np.sqrt((sp ** 2).mean()) * 0.01 * N:.2f} texels")


def run():
    os.makedirs(OUT, exist_ok=True)
    fp, fst = fluid_warm()
    arms = ["ch", "plain"] + [f"sh{s}" for s in SHARP]
    p = Params(iface=4.0, coarsen=0.3, inject=0.0)
    S = starts()
    states = {(k, a): im.phi_state(v) for k, v in S.items() for a in arms}
    # noise start for coarsening under stirring: CH only, two coarsen dials
    pn = {"ch@0.3": p, "ch@1.0": p.with_(coarsen=1.0)}
    for k in pn:
        states[("noise", k)] = im.seed(N, p, 3)
    rec = {key: [] for key in states}
    snaps = {key: {} for key in states}
    t0 = time.time()
    for t in range(FRAMES + 1):
        if t:
            fst = fm.step(fst, force_tex(WARM + t - 1), fp)
        uab = packed(fst)
        for key in states:
            if t:
                k, a = key
                states[key] = advance("ch" if k == "noise" else a, states[key], uab, pn.get(a, p))
            phi = states[key][..., 0]
            if t in SNAPS:
                snaps[key][t] = phi.copy()
            if t % EVERY == 0:
                g99, gmean = gradp99(phi)
                rec[key].append((t, g99, gmean, components(phi) if key[0] != "noise" else 0,
                                 float(phi.mean()), float(np.abs(phi).max()), bool(np.isfinite(phi).all())))
    print(f"({time.time() - t0:.0f} s for {FRAMES} frames)\n")
    report(rec, S)
    stills(snaps, arms)


def report(rec, S):
    print("start   arm        minG[300-600]  G@600  drift@600  comps 0->600  max|phi|@600  finite   verdict")
    for (k, a), r in rec.items():
        if k == "noise":
            continue
        g0 = r[0][1]
        ming = min(x[1] / g0 for x in r if 300 <= x[0] <= 600)
        last = r[-1]
        drift = abs(last[4] - r[0][4])
        ok = ming >= 0.5 and drift <= 0.02 and all(x[6] for x in r) and max(x[5] for x in r) <= 1.25
        if k in ("blob", "fil8"):
            ok = ok and last[3] <= 4
        elif k == "pair":
            ok = ok and last[3] <= r[0][3]
        verdict = "PASS" if ok else "fail"
        if k in ("fil1", "fil3"):
            verdict = "(info)"
        print(f"{k:<7} {a:<10} {ming:<14.3f} {last[1] / g0:<6.3f} {drift:<10.4f} {r[0][3]}->{last[3]:<9} "
              f"{last[5]:<13.4f} {last[6]!s:<8} {verdict}")
    print("\nG(t)/G(0) every 50 frames, CH vs plain vs sh0.01:")
    for k in S:
        for a in ("ch", "plain", "sh0.01"):
            r = rec[(k, a)]
            print(f"{k:<6} {a:<7}", " ".join(f"{x[1] / r[0][1]:.2f}" for x in r[::2]))
    print("\nExperiment 3, coarsening under stirring from noise: domain size L = 1/mean|grad phi| (texels^-1 units)")
    for key in rec:
        if key[0] != "noise":
            continue
        r = rec[key]
        L = [1.0 / x[2] for x in r]
        print(f"{key[1]:<8}", " ".join(f"{v:.2f}" for v in L[::2]), "  max|phi|", max(x[5] for x in r))


def stills(snaps, arms):
    try:
        from PIL import Image
    except ImportError:
        print("(no pillow: stills skipped)")
        return
    for k in ("blob", "fil8", "pair", "fil3"):
        tile = 128
        sheet = np.zeros((tile * len(arms), tile * len(SNAPS)), np.uint8)
        for ri, a in enumerate(arms):
            for ci, t in enumerate(SNAPS):
                im2 = (np.clip((snaps[(k, a)][t] + 1) / 2, 0, 1)[::2, ::2] * 255).astype(np.uint8)
                sheet[ri * tile:(ri + 1) * tile, ci * tile:(ci + 1) * tile] = im2
        path = os.path.join(OUT, f"stirring_{k}.png")
        Image.fromarray(sheet).save(path)
        print("still:", os.path.normpath(path), "rows:", ", ".join(arms))


if __name__ == "__main__":
    globals()[sys.argv[1]]()
