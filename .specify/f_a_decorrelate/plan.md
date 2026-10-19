# f_a_decorrelate — Implementation Plan

_Created: 2026-08-04_

## Architecture Decisions

### ADR-1 — `f_a_` prefix, first processor archetype
Every existing `f_a_` module (`f_a_purr`, `f_a_ripple`) is a pure generator:
no audio inlet. `f_a_decorrelate` is the first `f_a_` processor: audio in,
audio out, no texture/GL involvement either way. Worth naming explicitly as
a new archetype within the prefix, since `build_patcher.py` and any future
`f_a_` tooling decisions (Phase 4, both modules) should account for both
shapes, not assume "no audio inlet" as an `f_a_` invariant.

### ADR-2 — `pfft~`, per-bin gain (AM) / per-bin phase advance (PM)
`Mₙ(t)` — the same modulation matrix `f_a_ripple` computes per-harmonic — is
instead computed per-FFT-bin and applied as either a bin gain multiplier (AM)
or a bin phase rotation (PM). `Fₙ` becomes bin log-frequency relative to the
band's geometric center, matching the mean-centering documented in
`ideas/f_a_spectral_ripple.md` (MATLAB discrepancy 4; applied over the
modulated *bins in this case*, not the nominal band center).

### ADR-3 — `f_a_ripple` is a hard dependency, not a parallel effort
Despite being separate projects/specs, `f_a_decorrelate`'s scratch tests (T7,
T8) cannot run meaningfully until `f_a_ripple` has cleared T2–T6. This is a
sequencing dependency, not a scheduling preference: there is no independent
way to verify a `pfft~` implementation is doing the right thing (spec.md,
Primary risk). Do not begin `f_a_decorrelate` Phase 2 work before
`f_a_ripple` Phase 2 is complete.

**Satisfied 2026-10-12.** `f_a_ripple` Phase 2 is complete (T2–T6 passed)
and its Phase 4 core DSP is built and confirmed working — the dependency
has been honored and Phase 2 (T7/T8) is unblocked. The scratch-test
record lives in tasks.md T002/T003.

### ADR-4 — PM equivalence is unproven, not assumed
`ψₙ` in the additive domain is an unambiguous phase offset per partial.
Rotating a `pfft~` bin's phase by the equivalent amount is not obviously the
same operation — bin phase in an overlap-add STFT conflates true carrier
phase with windowing and frame-boundary effects in ways the additive
synthesis does not. Ship AM only in v1; treat PM as blocked on the T7-style
comparison, not as "probably fine, ship it and see."

**First data point 2026-10-12** (`tests/records/spike_a_decorrelate_t7.py`, NumPy
mirror of the full per-bin chain): per-bin phase rotation ψ=(π/2)(1+d·M)
tracks the additive PM reference (T6's code-accurate depth) at −11.2 dB
residual, corr 0.962, and its envelope de-correlation (T8's metric) is in
family with additive PM (0.237 vs 0.202). Not ruled out — the remaining open
question is the audible one (inter-frame phase discontinuity), which the
mirror cannot settle: `f_a_decorrelate_scratch_t7b.maxpat` exists for that
listen. The Max verdict, not the mirror, closes or keeps this ADR open.

**VERDICT 2026-10-12 (Max listen passed): PM is un-scoped for v1.** The
depth A/B on `f_a_decorrelate_scratch_t7b.maxpat` produced no glitching
and a plausible PM character — the inter-frame phase-continuity fear did
not materialize at tested settings. Combined with the mirror's numbers
above, per-bin phase rotation is equivalent *enough*: not sample-exact to
additive PM (−11.2 dB), but the same de-correlation behavior by the
paper's own metric. PM stays in v1 scope, packaged after AM. Residual
honesty: one listen at default parameters; extreme depth/high-tmr
corners re-test under Phase 3 sweeps (tasks.md T009/T010).

### ADR-5 — FFT size is an open scratch-test question, not a fixed choice
Bin resolution trades against ripple density at the low end of the band (idea
file: 4.5 cyc/oct across 1–2 kHz is a fine ripple in linear bin spacing at
typical FFT sizes). No size is chosen here — determining a workable size (or
concluding low bands need a different FFT size than high bands) is part of
Phase 2, not a prerequisite decision.

**Answered 2026-10-12** (`tests/records/spike_a_decorrelate_t7.py`): **2048/overlap 4**.
Measured residual vs the additive AM reference at f0=96, band 6: 2048/4 gives
−15.6 dB (corr 0.986); 4096 (−13.0 dB) and 8192 (−9.5 dB) are strictly
worse — longer windows hold the gain curve longer than the 1 Hz temporal
modulation allows, and that error grows faster than leakage shrinks. The
error is dominated by Hann leakage × per-bin gain on non-bin-centered
partials, which shrinks with *finer time* resolution, not finer bins.
1024 is marginally better on this static carrier (−17.0 dB) but half the
band resolution; 2048/4 is the trade. The low-band question (4.5 cyc/oct
across 1–2 kHz, where bins are ~21.5 Hz) remains a Phase 3 item — the
sweep was run at band 6 only.

**Band-1 tail closed 2026-10-12** (same spike, permanent band-1 section):
the low band IMPROVES at 2048/4 — −22.7 dB, corr 0.997 (better than band
6's −15.6/0.986; 10 modulated partials vs 59 — fewer leakage crossings).
Envelope-corr matches its additive reference (0.350 vs 0.363); the
fixed-SMR control separates even more strongly (0.838 vs ~0.35).
**One FFT size serves all bands — the per-band-size question is closed
with a no.**

### ADR-6 — Band model and licensing carry over unchanged
Same 7-octave/8-half-octave band model as `f_a_ripple` (ADR-4, that plan),
same reimplementation-from-equations approach with MATLAB used only for
verification (ADR-7, that plan). Not re-litigated here.

### ADR-7 — No shared codebase with `f_a_ripple` in v1
The two modules compute structurally similar but not identical modulation
math (per-harmonic vs. per-bin `Fₙ`). Starting duplicated is simpler than
factoring out a shared `.gen` abstraction prematurely — revisit only if T7
shows the two implementations converge closely enough that a shared core
would still produce correct output in both domains.

## Phases

- **Phase 1 — concept and interface.** Complete. `ideas/f_a_spectral_
  ripple.md`, this spec.
- **Phase 2 — scratch verification.** **COMPLETE 2026-10-12.** NumPy
  tier (`tests/records/spike_a_decorrelate_t7.py`): FFT size settled (2048/4,
  ADR-5 — including the band-1 tail: one size serves all bands), 50 ms
  gain-curve refresh shown free (−15.6 vs −15.7 dB per-frame), PM's
  first data point measured (ADR-4), envelope-correlation on synthetic
  carriers (0.313/0.320 vs fixed-SMR 0.594). Max tier: T002 null rig
  PASSED (residual in the −15 dB class), T005 PM listen PASSED (no
  glitching — **ADR-4 verdict: PM un-scoped for v1**). T8 done on two
  real-world music carriers via the spike's CLI: varying-SMR
  cross-segment correlation drift 0.569/0.375 vs fixed 0.459/0.264 —
  the paper's stability claim holds on non-synthetic input (honest
  caveat: music's own nonstationarity makes the varying-vs-fixed
  margin modest; the strong real-world effect is decorrelation vs the
  raw carrier, 0.94→0.59). All evidence in spec.md's ticked boxes;
  tasks.md Phase 2b checkpoint MET.
- **Phase 3 — parameter characterization.** **COMPLETE 2026-10-12
  (mirror)**: `run_phase3()` in the spike. Bands: one FFT size (2048/4)
  serves all (T008). Parameters (T009): smooth monotonic degradation in
  depth/smr_range/tmr — no discontinuities; **depth > 1 sends the bin
  gain negative** (phase inversion — v1 range stays 0–1). High-tmr
  (T010): **window-limited, not refresh-limited** — per-frame refresh
  doesn't help at tmr ≥ 10 (the gain moves within the 2048-sample
  window), 1024/8 does (−8.6 vs −4.8 dB); **v1 tmr range: 0.1–4 Hz**
  at 2048/4 (paper's tested value is 1 Hz; higher tmr wants a smaller
  FFT as a mode, not a faster sweep). PM extreme depth (T005 caveat):
  graceful, no cliff; PM verdict unchanged. **v1 scope decided: AM+PM,
  depth 0–1, tmr 0.1–4 Hz, 2048/4.** One small Max-listen item (live
  no-clicks sweep) folds into the packaging pass.
- **Phase 4 — production build.** **COMPLETE 2026-10-12 at the
  `f_a_ripple` packaging bar**: DSP built
  (`~/Vsynth/patterns/f_a_decorrelate_v1.maxpat` +
  `f_a_decorrelate_inner.maxpat`, builder script alongside) and shipped
  to `package/patchers/` the same way `f_a_ripple`'s v1 ships — flonum
  UI, ⚠ README row. Production deltas: `band`→`coll` lookup of edges +
  measured per-band bin geomeans; both AM/PM sweep exprs self-gate on
  `mod_type` (no message inlet into pfft~); gain/mix; tanh safety
  ceiling; v1 ranges enforced. Drift story: `out_of_scope` baseline
  entry matching `f_a_ripple`'s precedent. **The `build_patcher.py`
  audio-archetype extension (ADR-1's open tooling question) remains the
  shared workstream item** — it replaces the hand-built patch when it
  lands.
- **Phase 5 — docs and helpfile.** **COMPLETE 2026-10-12 at the same
  bar**: reference doc written (`docs/f-reference/f_a_decorrelate.md`,
  incl. measured behavior + latency + safety), README/NOT_IN_MENU
  registered, `f_Launch` regenerated (dependency-file class added to
  the generators' checks: `NOT_MODULES` for the pfft~ inner subpatch).
  **Helpfile deliberately deferred**: the f-helpfile format has no
  audio-module shape yet — part of the same shared audio-archetype
  decision, alongside `f_a_ripple`'s own missing helpfile.
