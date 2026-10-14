# Tasks: f_a_decorrelate

_Last updated: 2026-10-12_
**Spec**: `.specify/f_a_decorrelate/spec.md`
**Plan**: `.specify/f_a_decorrelate/plan.md`
**Idea file**: `ideas/f_a_spectral_ripple.md` (scratch-test log T1–T8)
**NumPy mirror**: `tests/spike_a_decorrelate_t7.py` (the measured evidence)

> Created by the 2026-10-12 assessment pass (T001–T007) when the folder had
> only spec.md + plan.md. T001 (stale-block refresh) and T004 (bin-artifact
> characterization, band 6) are done. The 2026-10-12 NumPy session then
> answered ADR-5 and gave ADR-4 its first data point, and authored the two
> Max patches the tasks below verify. `f_a_ripple`'s block is lifted: its
> T2–T6 passed 2026-08-05/06 and its Phase 4 core DSP is built
> (`f_a_ripple_v1.maxpat`, 2026-09-16) — the reference for every comparison
> here. Full acceptance still trails `f_a_ripple`'s own packaging (its
> tasks.md T002: UI, docs, checkhearing comparison).

---

## Phase 2a: NumPy mirror — DONE 2026-10-12

- [x] T001 Refresh the stale block in spec.md (status header, Primary
  risk) and plan.md (ADR-3, Phase 2 line). _Done: spec header + Primary
  risk rewritten as resolved (narrower residual risk: comparisons run
  against the working patch, not a shipped module); plan ADR-3 marked
  satisfied, Phase 2 unblocked._
- [x] T004 Characterize bin-resolution artifacts; resolve ADR-5's FFT-size
  question. _Done (band 6): **2048/overlap 4** — 4096/8192 strictly worse
  (longer windows violate the 1 Hz modulation faster than leakage shrinks);
  50 ms gain-curve refresh measured free (−15.6 vs −15.7 dB per-frame);
  residual attribution: dominant term is Hann leakage × per-bin gain on
  non-bin-centered partials (f0=96 vs 21.5 Hz bins), NOT bin spacing per
  se; frame-hold and bin-quantization of M each ~−33 dB; STFT round-trip
  exact to −180 dB. Sweep recorded in plan.md ADR-5; band-1 sweep deferred
  to Phase 3 (T008)._

**Checkpoint**: measured bars exist for every Max test below. The T7 bar is
"−15 dB-class residual + envelope correlation", NOT waveform null — a null
is physically unattainable for windowed per-bin processing.

## Phase 2b: Max verification session (one sitting; patches already authored)

Both patches live in `~/Vsynth/patterns/`, built by
`build_t7b_patches.py` from the T7a exemplar per `maxpat-json-authoring`,
structurally validated (no duplicate ids, no dangling cords).

- [x] T002 T7 residual rig: open `f_a_decorrelate_scratch_null.maxpat`
  (needs `t7a_inner.maxpat` in the same folder — pfft~ loads subpatches by
  name from disk; don't run it in the same Max session as the t7a patch,
  they share the `T7a_gain` buffer name). Raise output_level slowly, run
  on, click the button: expect residual/ref ≈ 0.05 (−15.6 dB per the
  mirror; typed geomean default updated to the measured bin geomean
  8322.6). _**Passed 2026-10-12 in Max** — residual landed in the −15 dB
  class, matching the mirror. T7's "closely matches" bar met on both the
  synthetic (this) and metric (envelope-corr, Phase 2a) sides._
- [x] T005 PM listen (ADR-4's decision input): open
  `f_a_decorrelate_scratch_t7b.maxpat` + `t7b_inner.maxpat`, depth A/B
  (0 vs 100). Mirror says viable (−11.2 dB, corr 0.962 vs additive PM;
  envelope-corr 0.237 vs 0.202). _**Passed 2026-10-12 in Max**: no
  glitching, audible PM character — the inter-frame phase-continuity
  fear did not materialize at the tested settings. **ADR-4 verdict: PM
  equivalent enough to un-scope from v1** (plan.md updated). Caveat kept
  honest: this is one listen at default parameters; extreme `pm` depth
  or high `tmr` re-tests belong to Phase 3's sweeps (T009/T010)._
- [x] T003 T8's remaining half: run the off-diagonal envelope-correlation
  matrix on a real-world carrier (music, voice, room tone) through the
  null rig's pfft chain — record the carrier into a `buffer~` the mirror
  can ingest, or run the analysis on a recorded file
  (`tests/spike_a_decorrelate_t7.py`'s `envelope_corr` is the metric).
  Synthetic-carrier half already done: pfft AM 0.313 vs additive 0.320,
  fixed-SMR control cleanly separated at 0.594. _**Done 2026-10-12**,
  two real-world music carriers (12 s each, 44.1 kHz mono, decoded from
  local files — not committed; the spike takes wav paths as CLI args so
  the run is reproducible with any carrier). Result, measured with a
  NEW segment-drift metric: the paper's claim is about *stability* ("no
  frequency pair maintains a stable correlation"), which a whole-file
  matrix cannot see — so the spike reports cross-segment correlation-
  matrix drift (4×3 s segments) alongside the whole-file number.
  **Both carriers show the claimed direction on drift**: varying-SMR
  0.569 vs fixed 0.459 (carrier 1, which also separates on whole-file
  0.414 vs 0.531); varying 0.375 vs fixed 0.264 (carrier 2). Big
  caveat kept honest: on music the varying-vs-fixed separation is much
  weaker than on the synthetic complex — music's envelope correlations
  are already nonstationary (raw carrier drift 0.607/0.221), so the
  chain's dominant effect is the strong decorrelation vs the raw
  carrier (whole-file 0.94→0.59; carrier 2: 0.77→0.45). The effect
  holds on real-world input; its margin over fixed-SMR is modest
  there._

**Checkpoint MET 2026-10-12**: T002's residual in the −15 dB class
(Max), T005's listen verdict recorded (plan.md ADR-4: PM un-scoped),
T003's real-world matrices on file (both music carriers). **Phase 2
complete — spec.md Acceptance fully evidenced.** Phase 3 (T009/T010)
is next; T008 already done below.

## Phase 3: Parameter characterisation

- [x] T008 Band-1 sweep (the deferred half of T004): the 4.5 cyc/oct
  ripple across 1–2 kHz against 21.5 Hz bins — run the mirror's
  size-sweep at band 1 to check whether low bands need a different FFT
  size than 2048 (plan.md ADR-5's open tail). _**Done 2026-10-12**
  (now a permanent section of `tests/spike_a_decorrelate_t7.py`):
  band 1 IMPROVES at 2048/4 — −22.7 dB, corr 0.997 (vs band 6's
  −15.6/0.986; 10 partials vs 59). Envelope-corr matches its additive
  reference (0.350 vs 0.363) and the fixed-SMR control separates even
  more strongly than at band 6 (0.838 vs ~0.35 varying). **One FFT
  size (2048/4) serves all bands — ADR-5 fully closed, no per-band
  size.** The paper's low-band worry doesn't bite: fewer partials per
  band means fewer leakage crossings, and bin spacing is fine relative
  to 4.5 cyc/oct as the idea file predicted._
- [x] T009 Free-parameter sanity sweep: depth, tmr, smr_range swept in
  the mirror against matched additive references at each setting
  (permanent `run_phase3()` section of `tests/spike_a_decorrelate_t7.py`).
  **Findings**: degradation is smooth and monotonic in every direction —
  depth 0.5→1.5 costs ~8 dB, smr_range 0→6 costs ~4 dB, all without
  discontinuities; **depth > 1 sends the bin gain negative** (1+d·M < 0
  inverts bin phase where it crosses — mathematically correct but a
  character change the additive reference doesn't share at the same
  setting, so **v1 range should stay 0–1**, matching `f_a_ripple`'s
  spec). **Max-listen half owed** (small): the no-clicks live sweep on
  the actual patch — expected clean given the smooth mirror behavior,
  same one-sitting check as `f_a_ripple`'s Phase 3 found zero issues;
  and the typed-geomean flonum should be re-typed per band if band
  switching is exercised (its value is band-dependent: 8322.6 at band 6,
  different per band).
- [x] T010 High-tmr character (idea file Q5): measured, verdict in.
  **The limit is the analysis WINDOW, not the refresh rate**: at tmr=10
  the 2048-sample window (46 ms ≈ the modulation period) is the binding
  constraint — per-frame refresh does not help (−4.8 dB at 2048/4 and
  even 2048/8), but a smaller window does (1024/8 → −8.6 dB). 50 ms
  refresh stays free up to tmr ≈ 4 (−9.6 dB). **Decision for v1: tmr
  range 0.1–4 Hz at 2048/4** — the paper's own tested value is 1 Hz, and
  the idea file's Q5 curiosity (100+ Hz) is a *character* question the
  bin-gain formulation answers poorly at any refresh rate; if high tmr
  is ever wanted it needs a smaller FFT (1024/8) as a mode, not a faster
  sweep. Recorded in plan.md ADR-5's neighborhood as the T010 note.

**T005 caveat closed (same sweep)**: PM extreme depth is graceful in the
mirror — −17.0 dB at depth 0.5 degrading to −5.8 dB at 2.0, no
discontinuity cliff; envelope decorrelation holds at every depth (0.23–
0.35). The Max listen at default depth stands; extreme-depth PM corners
degrade the same smooth way AM's do. **PM verdict unchanged: un-scoped
for v1** (with the same 0–1 depth range recommendation).

**Checkpoint MET 2026-10-12 (mirror half)**: bands (T008) and parameters
(T009/T010) characterized; v1 scope decided: **AM+PM, depth 0–1, tmr
0.1–4 Hz, one FFT size 2048/4**. The single remaining Max-listen item
(T009's no-clicks pass, one sitting) does not gate Phase 4 planning —
the mirror's smoothness is strong prior, and the production build
repeats the listen at packaging anyway.

## Phase 4: Production build

- [x] T011 Build the module — **done 2026-10-12 at the `f_a_ripple`
  packaging bar**: `f_a_decorrelate_v1.maxpat` (production DSP; built by
  `~/Vsynth/patterns/build_f_a_decorrelate_v1.py` from the T7b exemplar)
  + `f_a_decorrelate_inner.maxpat` (external pfft~ subpatch), both copied
  to `package/patchers/` exactly the way `f_a_ripple`'s v1 patch ships
  there. Production deltas vs scratch: one `band` param drives edges +
  measured per-band bin geomeans via `coll` (1468.6 … 11776.4; band 6
  8200.8 — validates T7a's typed 8001); `mod_type` AM/PM with BOTH exprs
  self-gating (no message inlet into pfft~); gain/mix wet-dry stage; tanh
  safety ceiling; v1 ranges (depth 0–1, tmr 0.1–4). The 1536-sample
  wet-path delay is documented in the reference doc. **`build_patcher.py`
  archetype extension remains the shared open item** (with
  `f_a_ripple`'s tasks.md T002) — when an audio archetype exists, the
  definition path replaces the hand-built patch; until then this ships
  the same way f_a_ripple does.
- [x] T012 Drift story — **decided 2026-10-12, matching `f_a_ripple`'s
  precedent**: added to `tests/drift_baseline.json` as `out_of_scope`
  with the reason ("pfft~ audio processor, external subpatch loaded by
  name, no jit.gl.pix; schema has no audio archetype — revisit if one is
  added"). `test_drift.py` passes. When the archetype lands, this entry
  comes out and the module goes on the normal definition ratchet.

**Checkpoint MET 2026-10-12 at the packaging bar set by `f_a_ripple`**
(shipped patcher in `package/patchers/`, structural checks green, drift
baseline recorded). The `build_patcher.py` audio-archetype + inner-file
workstream is the *shared* remaining item, not this module's alone.

## Phase 5: Docs + registration

- [x] T013 `docs/f-reference/f_a_decorrelate.md` — written (as-built:
  signal path with the buffer~/index~ pattern, code-accurate modulation
  equations, parameters with the measured v1 ranges and ceilings,
  measured-behavior section carrying all the spike numbers, the 35 ms
  wet-path latency note, and the Safety section with the trial's
  listening rules + what tanh does and doesn't cover).
- [x] T014 Registration — done to the same bar `f_a_ripple` ships at:
  README Audio table row (⚠, ≤110 chars), `NOT_IN_MENU` entry in
  `src/f_modules/menu.py` with reason, `f_Launch` regenerated (40
  modules, f_a_decorrelate greyed = no helpfile), and the generators'
  checks extended for the new dependency-file class: `NOT_MODULES`
  (pfft~ inner subpatch — loaded by name, not a module) in
  `generate_launch.py` + the matching exemption in `generate_menu.py`
  and `tests/test_launch.py`. `tests/run.sh` offline suite green
  (launch 8/8, benchdeps 21/21, build_conventions 40/40). **Helpfile
  deliberately not written**: the `f-helpfile` format is
  Vsynth-texture-oriented (`vs_sources_main`/`vs_preview`); an audio-
  module helpfile shape is part of the same shared audio-archetype
  decision (and `f_a_ripple` has no helpfile either). Not a silent
  skip — recorded here and in HANDOFF.
- [x] T015 HANDOFF updated; commit left to Matt's review-and-squash
  convention (all changes listed there).

**Checkpoint MET 2026-10-12**: docs consistent with as-built state at the
`f_a_ripple` packaging bar. **Module complete to that bar.** Remaining
work is the shared f_a_ packaging workstream (build_patcher.py audio
archetype, live.dial UI grid, helpfile format for audio modules) — same
items `f_a_ripple` itself owes, to be done together when that
workstream is picked up.

---

## Notes

- The Max patches owe their architecture entirely to T7a's hard-won
  lessons (`pfft-spectral-processing` skill): buffer~/index~ for per-bin
  control (gen~-inside-pfft~ routing failed 4 ways, never re-attempt),
  external subpatch file, expr not gen~ at uzi speed, snapshots
  trigger-ordered before the sweep. Two authoring bugs were caught by
  tracing before Max ever saw them: phase-uzi firing before the snapshots
  (stale reads) and a ternary-precedence bug that would have swallowed
  q+ωt out of the reference modulator.
- `build_t7b_patches.py` stays in `~/Vsynth/patterns/` with the patches
  (scratch tooling, same convention as the other ripple scratch files);
  re-run it to regenerate after Max round-trips a file.