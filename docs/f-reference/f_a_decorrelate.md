# f_a_decorrelate — Patch Reference (As-Built DSP)

_Last updated: 2026-10-12_
_Status: Built and shipped to `package/patchers/` 2026-10-12 (hand-built `f_a_decorrelate.maxpat` + `f_a_decorrelate_inner.maxpat`); registration done. First `f_a_` processor still awaits the `build_patcher.py` audio archetype_

## Role

Cross-frequency de-correlating modulation as a **processor**: audio in,
de-correlated audio out. Applies the same modulation matrix as `f_a_ripple`
(the Yukhnovich et al. 2025 stimulus) to an arbitrary input via `pfft~` —
per-bin gain (AM) or per-bin phase rotation (PM) — instead of generating its
own carrier. The paper gestures at this version and never builds it; it is
the one that behaves like the rest of `f_`.

`f_a_ripple` is the ground truth: every correctness criterion was measured
against its additive synthesis (`tests/records/spike_a_decorrelate_t7.py`, the NumPy
mirror of this exact chain).

## Signal path

```
inlet~ ──┬── pfft~ f_a_decorrelate_inner 2048 4 ── wet * mix ──┐
         │        (per-bin gain + phase from named            │
         │         buffer~s swept every 50 ms)                 ├─ + ─ tanh~ ─ * gain ─ outlet~
         └──────────────── dry * (1 - mix) ────────────────────┘
```

Inside the external `pfft~` subpatch: `fftin~` → `index~ fad_gain`
(AM gain per bin) and `index~ fad_phase` (PM offset per bin) →
`cartopol~` → amp×gain, phase+ψ → `poltocar~` → `fftout~`. Both modulations
are always applied; the inactive one is a no-op (unity gain / zero phase)
because the sweep `expr`s gate themselves on `mod_type` — no message inlet
into `pfft~` (the `pfft-spectral-processing` skill's canonical
`buffer~`/`index~` pattern; `gen~`-inside-`pfft~` control routing is
documented there as failing four ways and must not be re-attempted).

The gain/phase curves are precomputed message-rate: `metro 50` →
trigger-ordered `snapshot~`s → `uzi` × 1024 bins → `expr` → `peek~` into the
named buffers. 50 ms refresh measured free at the v1 `tmr` ceiling (−15.6 vs
−15.7 dB per-frame, `tests/records/spike_a_decorrelate_t7.py`).

**`band` drives the constants**: a `coll` lookup holds each band's edges and
its *measured bin geomean* (2048/44.1 kHz; band 6: 5700–11000 Hz, geomean
8200.8 — the value the scratch patches typed by hand as 8001).

## Modulation

Code-accurate equation set (per-bin; see `ideas/f_a_spectral_ripple.md` for
the paper-vs-MATLAB discrepancies this follows):

```
M(bin,t) = sin(2π (q + tmr·t + F_bin · S(t)))
F_bin   = log2(freq_bin / geomean(band))       geomean over the band's BINS
S(t)    = smr_mean + smr_range · sin(p + 2π t / smr_cycle)
AM:  gain = 1 + depth·M                        (in-band only, else 1)
PM:  ψ    = (π/2)(1 + depth·M)                 (in-band only, else 0)
```

PM depth is π/2 (code-accurate, MATLAB discrepancy #2), matching
`f_a_ripple`'s T6. `q`/`p` are exposed params (the stimulus protocol redraws
them per 4 s block; a live processor holds them).

## Parameters

| Name | Range | Default | Note |
|---|---|---|---|
| `band` | 1–7 | 6 | paper's octave bands: 1–2, 1.4–2.8, 2–4, 2.8–5.7, 4–8, 5.7–11, 8–16 kHz |
| `mod_type` | 0=AM, 1=PM | 0 | PM verified equivalent-enough (ADR-4 verdict 2026-10-12) |
| `depth` | 0–1 | 1.0 | hard ceiling 1.0 — above it the bin gain goes negative (phase inversion; Phase 3 finding) |
| `tmr` | 0.1–4 Hz | 1.0 | ceiling 4 Hz at 2048/4 — window-limited above that (Phase 3/T010); paper's tested value 1 Hz |
| `smr_mean` | 0–12 cyc/oct | 4.5 | μ |
| `smr_range` | 0–12 | 3.0 | r |
| `smr_cycle` | 1–60 s | 8.0 | scyc |
| `q`, `p` | 0–2π | 0 | modulator phase offsets |
| `gain` | 0–4 | 1.0 | post-modulation trim (after tanh) |
| `mix` | 0–1 | 1.0 | wet/dry |

## Known behavior (measured, not eyeballed)

- **vs `f_a_ripple`'s additive AM on a matched carrier**: −15.6 dB residual,
  corr 0.986 at 2048/4 (Max rig confirmed the class). A waveform *null* is
  physically unattainable — Hann leakage × per-bin gain on non-bin-centered
  partials is inherent; frame-hold and bin-quantization each cost only ~−33 dB.
- **The paper's claim** (envelope-correlation stability): synthetic carrier —
  pfft AM 0.313 vs additive 0.320 mean |off-diag|, fixed-SMR control 0.594;
  real-world music carriers — varying-SMR cross-segment matrix drift
  0.569/0.375 vs fixed 0.459/0.264 (both in the claimed direction; margin
  modest on music because music is already nonstationary).
- **Latency**: `pfft~` adds win−hop = 1536 samples (35 ms) on the wet path
  only. For comb-free live blending keep `mix` extreme (0 or 1) or accept
  the wet/dry offset.
- **Bands**: one FFT size (2048/4) serves all seven bands — band 1 measures
  *better* than band 6 (−22.7 dB, corr 0.997).
- **PM**: tracks additive PM at −11.2 dB, corr 0.962; graceful at extreme
  depths (no cliff); Max listen passed (no glitching).

## Safety

From the idea file's Safety section (the trial's listening rules): treat
output at ≤60 % device volume, ≤60 min at a time, 60 min between sessions.
The `tanh~` stage bounds the wet path to [−1, 1] by construction (same
class as `f_a_ripple`'s ADR-6 ceiling), but the dry path and `gain` are
unbounded — `gain` is a trim, not a limiter.

## Verification provenance

All numbers above: `tests/records/spike_a_decorrelate_t7.py` (NumPy mirror of this
exact chain, incl. band-1, real-world-carrier and parameter-sweep sections)
plus the 2026-10-12 Max session (null rig + PM listen, tasks.md T002/T005).
Spec/plan record: `.specify/f_a_decorrelate/`.

## Packaging status (why this is not in `package/patchers/` yet)

`build_patcher.py` has no `f_a_`/`pfft~` archetype — this is the first `f_a_`
processor (audio inlet; `pfft~` requires an external subpatch file, which
the definition→patcher path has never placed). Same open item as
`f_a_ripple`'s own packaging (its tasks.md T002). Registration
(`f_modules` menu, README table, helpfile) follows packaging.

## References

Yukhnovich, Harrison, Wray, Alter, Sedley (2025), _Chronic tinnitus is
quietened by sound therapy using a novel cross-frequency de-correlating
stimulus modulation_, Hearing Research 464, doi:10.1016/j.heares.2025.109335.
Built from the paper's published equations (code-accurate where the deposit's
MATLAB disagrees — sine-phase carrier precedent, π/2 PM depth); no MATLAB
code transcribed (ADR-7 licensing position, `f_a_ripple/plan.md`).

## Source Files

`~/Vsynth/patterns/f_a_decorrelate_v1.maxpat` (production DSP) +
`f_a_decorrelate_inner.maxpat` (pfft~ subpatch, loaded by name from the
same folder). Built by `~/Vsynth/patterns/build_f_a_decorrelate_v1.py`.