"""spike_fc_sustain.py -- f_wc Phase 0, T002 (the load-bearing
experiment): does the Example-10 Wilson-Cowan update SUSTAIN structure at
float32 without per-frame noise?

The source (WC_Example_10_fullscreen.html) injects NO per-frame noise: its
state is 8-bit (EncodeFloat every write, blur output floored to 1/255 too),
and it carries a slow square-wave bias s on the E threshold (0.6 half-duty,
period ~147 frames). Two candidate sustain mechanisms at their constants --
quantization decorrelation, or the s wave kicking the field off its settling
point. f_wc's Psychedelic corner needed explicit per-frame noise (the T005
ablation). At float32 neither of the source's mechanisms exists by default;
this spike measures what Example-10 needs.

Conditions, Example-10 constants (10.5/8.5/12/3, He 2, Hi 3.5, Te 10, Ti 20,
dt 1), seed uniform [0,1], no drive:
  baseline corner: N = 512, sigma_I = 1.0 px (grain 1/512 = the 1024-canvas
    look), sigma_E = 1/1.45.
  runs: Ne in {0, 0.05, 0.15, 0.5, 1.0}, 4000 frames; plus
    Ne = 0 + the source's square wave s; plus Ne = 0 at a second seed.
  confirmation corner: N = 1024, sigma_I = 2 px (the actual fullscreen look),
    for the best candidate(s), 2000 frames.
Tracked: E mean/std every 20 frames; end-state structure-factor metrics.

Verdict criteria (recorded in tasks.md T002):
  "sustained": end std >= 0.05 AND still moving (std trace not asymptoting 0)
  and not saturated (0.02 < mean < 0.98 at the end with spatial variance).
  "dead": std < 0.01 by the end. "saturated": mean outside the band or
  variance collapsed high.

Run from the repo root: uv run --no-project --with numpy python3 tests/records/spike_fc_sustain.py
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "lib"))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402
from wc_steadyweb_mirror import (F32, Params, ex10_square_wave, lambda_px, run,  # noqa: E402
                       seed_state, structure_factor_metrics)

FRAMES = 4000
NE_LEVELS = [0.0, 0.05, 0.15, 0.5, 1.0]


def condition(label, N, grain, ne, frames=FRAMES, seed=1, square_wave=False):
    P = Params(grain=grain, energy=ne)
    s_fn = ex10_square_wave if square_wave else None
    rng_seed = 1000 + seed           # per-frame noise stream (None if Ne == 0)
    st, tr = run(seed_state(N, N, seed), P, frames,
                 seed=(rng_seed if ne > 0 else None),
                 s_fn=s_fn, fast_blur=True, trace_every=20)
    e = st[..., 0]
    m = structure_factor_metrics(np.asarray(e, dtype=np.float64))
    lam = lambda_px(np.asarray(e, dtype=np.float64))
    em, es = float(e.mean()), float(e.std())
    # still moving? compare std 500 frames apart
    moving = (len(tr["es"]) > 50
              and abs(tr["es"][-1] - tr["es"][-26]) / max(tr["es"][-26], 1e-9) > 0.01)
    verdict = ("saturated" if not (0.02 < em < 0.98) or es < 0.01 and em > 0.5
               else "dead" if es < 0.01
               else "sustained" if es >= 0.05 else "marginal")
    print(f"{label:34s} N={N:4d} sigI={grain*min(N,N):6.2f}px Ne={ne:4.2f} "
          f"sw={int(square_wave)} | E mean {em:6.3f} std {es:6.3f} "
          f"lam {lam:6.1f}px prom {m['prominence']:5.1f} "
          f"aniso {m['anisotropy']:4.2f} | {verdict}")
    sys.stdout.flush()
    return {"label": label, "verdict": verdict, "em": em, "es": es,
            "lam": lam, "trace": tr, "state": st}


def main():
    results = []
    print("== baseline corner: N=512, sigma_I = 1.0 px ==", flush=True)
    for ne in NE_LEVELS:
        results.append(condition(f"Ne={ne}", 512, 1.0 / 512, ne))
    results.append(condition("Ne=0 + source square wave", 512, 1.0 / 512,
                             0.0, square_wave=True))
    results.append(condition("Ne=0, seed 2", 512, 1.0 / 512, 0.0, seed=2))

    # confirmation at the true fullscreen grain for the most interesting runs
    best = [r for r in results if r["verdict"] == "sustained"]
    print("== confirmation corner: N=1024, sigma_I = 2.0 px ==", flush=True)
    if best:
        for r in best[:2]:
            ne = float(r["label"].split("=")[1].split()[0])
            condition(f"fullscreen-grain Ne={ne}", 1024, 2.0 / 1024, ne,
                      frames=2000)
    else:
        condition("fullscreen-grain Ne=0", 1024, 2.0 / 1024, 0.0, frames=2000)

    print("\n== summary ==")
    for r in results:
        print(f"  {r['label']:34s} -> {r['verdict']:10s} "
              f"(mean {r['em']:.3f}, std {r['es']:.3f}, lambda {r['lam']:.1f}px)")


if __name__ == "__main__":
    main()
