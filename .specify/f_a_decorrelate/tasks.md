# Tasks: f_a_decorrelate

_Last updated: 2026-10-12_
**Spec**: `.specify/f_a_decorrelate/spec.md`
**Plan**: `.specify/f_a_decorrelate/plan.md`
**Idea file**: `ideas/f_a_spectral_ripple.md` (scratch-test log T1–T8)
**NumPy mirror**: `tests/records/spike_a_decorrelate_t7.py` (the measured evidence)

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
  (`tests/records/spike_a_decorrelate_t7.py`'s `envelope_corr` is the metric).
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

## Phase 3: Parameter characterization

- [x] T008 Band-1 sweep (the deferred half of T004): the 4.5 cyc/oct
  ripple across 1–2 kHz against 21.5 Hz bins — run the mirror's
  size-sweep at band 1 to check whether low bands need a different FFT
  size than 2048 (plan.md ADR-5's open tail). _**Done 2026-10-12**
  (now a permanent section of `tests/records/spike_a_decorrelate_t7.py`):
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
  (permanent `run_phase3()` section of `tests/records/spike_a_decorrelate_t7.py`).
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
  precedent**: added to `tests/build/drift_baseline.json` as `out_of_scope`
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
  modules, f_a_decorrelate grayed = no helpfile), and the generators'
  checks extended for the new dependency-file class: `NOT_MODULES`
  (pfft~ inner subpatch — loaded by name, not a module) in
  `generate_launch.py` + the matching exemption in `generate_menu.py`
  and `tests/build/test_launch.py`. `tests/run.sh` offline suite green
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
---

## Audio archetype, Phase C (added 2026-11-16, Claude; Matt's go "as proposed"; BUILT offline 2026-11-16, Max checks owed; T016 written, not run)

Source: `build/spec.md` "Audio archetypes" (Phase C: `audio_pfft` + the hand-kept control fragment, rebuild this module); decisions of record in `G-audio` (`.specify/gates.md`); Phases A and B built `audio_gen` (`.specify/f_a_ripple/tasks.md`, `.specify/f_a_purr/tasks.md`). Out of scope: any DSP change, the helpfile, menu / `f_addmod` / launcher (Phase D), PM or tmr changes. Facts below were read this session from `package/patchers/f_a_decorrelate.maxpat` (107 cords, 77 boxes), `f_a_decorrelate_inner.maxpat` and the `pfft~` reference page (not run).

Starting point (read, not run): the shipped patch is the hand-built v1: `inlet~` -> `pfft~ f_a_decorrelate_inner 2048 4` -> `*~` (mix) + a dry `*~` (undelayed) -> `tanh~` -> `*~` (gain) -> `outlet~`; 11 flonum / number controls with a loadbang fan of defaults; the control chain: `coll bandtable` (7 `store` messages on loadbang) with `sel 1 2 3 4 5 6 7`, a `gen~` control supplier (`tmr`, `smr_*`, `q`, `p` by `prepend`), a `metro 50` started by a hand **toggle**, `t b b b b b`, two `uzi 1024` sweeps into two `expr` (AM gain, PM phase), `peek~` into global `buffer~ fad_gain` / `fad_phase`; the inner file reads them with `index~ fad_gain` / `index~ fad_phase`. No panel, title, presentation rect or `autopattr`.

Known defects of that patch that the rebuild must not carry over, found by reading (inferred, not run): (1) the dry path is not delayed, so a partial `mix` combs against the 1536-sample wet path (the spec decision of 2026-11-16 fixes this); (2) the `metro` needs a click, so a module opened cold is silent-neutral until someone toggles it; (3) the two buffer names are global, so a second instance would share and overwrite them; (4) the `coll` stores and the `band` value both fire at load with no ordering between them; (5) the `expr` text and the `coll` geomeans bake in 44100 Hz and 2048 (the module is only right at 44.1 kHz; documented, not fixed here, Q2).

- [ ] T016: **Spike first, Max, Matt's run** (blocks the instance-safety claim, not the builder work): a scratch patch `scratch/experiments/f_a_decorrelate_instances/` (authored by Claude, local, gitignored) with a bpatcher hosting a tiny pfft~ + inner file whose `index~` name comes from `pfft~ <inner> 2048 4 0 0 args ---`, two instances side by side, different buffer contents. The `pfft~` page says `args` initializes `#1` pound-sign arguments of the loaded patcher; whether `---` in a `pfft~` box's text is replaced per bpatcher instance before that is not documented (unknown). Pass: each instance reads its own buffer. Fail: fall back to a name the shell builds another way (to be designed then, not guessed now).
- [x] T017: Fragment `src/f_a_decorrelate/fragment.json`: the control chain extracted from the shipped patch (boxes, cords, and an `attach` map: `param:<name>` -> [box id, inlet] list), hand-kept, ids prefixed `frag-`. Edits from the shipped chain, listed in `src/f_a_decorrelate/README.md`, and only these: buffer names `---fad_gain` / `---fad_phase` (also in the two `peek~`); the toggle replaced by an autostart (`metro 50 @active 1`); the band value passes `deferlow` before `sel` so the `coll` stores have happened; no DSP or formula change (the `expr` text, the 44100 and 2048, stay).
- [x] T018: Inner file `src/f_a_decorrelate/inner.maxpat`: the shipped `f_a_decorrelate_inner.maxpat` with its two `index~` names changed to the `#1` form. Copied verbatim by the builder to `package/patchers/f_a_decorrelate_inner.maxpat` (a side file, as the panel-toggle JS is today). The existing `f_a_decorrelate_inner` baseline entry (`no_definition`) stays.
- [x] T019: Builder, extending `build_audio()` with `core: "pfft"` (texture path and `audio_gen` unchanged): shell = `inlet~`, `pfft~ <inner> <size> <overlap> 0 0 args ---`, `outlet~`, a dry path `delay~` of `latency_samples` (1536), the mix stage (`*~` / `!-~` / `+~`, as shipped but now against the delayed dry), bypass as a slewed crossfade to the delayed dry (so toggling does not jump: the spec decision), optional `tanh~`, gain `*~`; `mix`, `gain` and bypass go through `line~` (about 20 / 20 / 5 ms) instead of bare floats. The fragment is spliced: ids remapped under `frag-`, cords copied, each `param:<name>` attach wired from that control. Loud on: a param with no attach and no shell stage, an attach naming a missing box, a duplicate id, an inner file or fragment that does not exist, `latency_samples` missing.
- [x] T020: `src/f_a_decorrelate/definition.py`: `archetype: "audio_pfft"`, `core: "pfft"`, `inner`, `fft: [2048, 4]`, `fragment`, `latency_samples: 1536`, `audio_in: True`, `safety_tanh: True`, 11 params (band 1-7 int, mod_type AM / PM, depth 0-1, tmr 0.1-4, smr_mean, smr_range, smr_cycle, q, p, mix 0-1, gain per Q3) with the v1 ranges of this folder's spec and plan, the same 7 x 2 grid and panel as `f_a_ripple`.
- [x] T021: `tests/build/test_build_audio.py` extended for `audio_pfft`: the `pfft~` text names the inner file, size, overlap and `args ---`; the inner file is copied byte for byte; fragment ids are unique and prefixed; every attach resolves and is wired from its control; every param is attached or a shell stage; the dry `delay~` equals `latency_samples`; mutants (a dropped attach, a missing inner, a wrong delay). One named test, `-q`, with Matt's go.
- [x] T022: Build `package/patchers/f_a_decorrelate.maxpat` and the inner copy; `drift.py f_a_decorrelate` ok; remove the `f_a_decorrelate` `out_of_scope` entry from `tests/build/drift_baseline.json`; run `test_drift.py`, then the definition-scanning tests (layout, conventions, render_dim, gates) with Matt's go.
- [x] T023: Records: this file, `src/f_a_decorrelate/README.md`, `docs/f-reference/f_a_decorrelate.md` (it says the buffers are global and the dry path is undelayed: both change), `build/spec.md` (the fragment format as built, status), `G-audio` row, `HANDOFF.md` START HERE; `tests/rigs/f_a_decorrelate_rig.maxpat` (an `f_a_decorrelate` bpatcher fed by `noise~` or a file player into `ezdac~` and `scope~`); one commit.
- [ ] T024 (owed to Matt, Max, not claimed by Claude): T016's spike; open the built patcher; the null rig of T002 re-run on the generated patch (the old rig is outside the repo and loads the scratch inner, so it needs the module dropped in; residual expected in the -15 dB class); listen at defaults; mix at 0.5 (no comb, now that the dry is delayed); Bypass (no click, no jump); band switching live (the `coll` lookup, the `deferlow`); two instances; the autostart (module audible on a cold open, no toggle); save-in-Max round trip.

### Decided 2026-11-16 (Matt: "Go, as proposed")

1. **Spike in parallel.** Proposal: I write the T016 scratch patch first and then do T017-T023 on the design above without waiting for your result; if T016 fails, the buffer-name mechanism (T017, T018, the `args ---` in T019) is redone. Alternative: you run T016 before I write any builder code.
2. **44.1 kHz limitation.** Proposal: leave it (documented in the reference doc and README, in the tasks as a known limit), since fixing it means redesigning the `coll` geomeans and `expr` constants, which is DSP, not packaging. Say if you want it in Phase C.
3. **Gain.** The shipped order is mix, `tanh~`, then gain, with gain unbounded. Proposal: keep the order and give the dial 0-1.5, default 1 (so a gain above 1 can leave the `tanh` ceiling, as shipped); or move gain before the ceiling as in `f_a_ripple` and `f_a_purr` (then the output is bounded by construction).

### Phase C record (2026-11-16, Claude, offline)

- Built: `build_audio()` `core: "pfft"` branch (shell, latency-matched dry `delay~`, bypass crossfade, `line~` stages, fragment splice, inner-file copy as a side file); `src/f_a_decorrelate/{definition.py,fragment.json,inner.maxpat,README.md}`; `package/patchers/f_a_decorrelate.maxpat` (87 boxes, 93 cords) and `f_a_decorrelate_inner.maxpat` (byte for byte the source); `tests/rigs/f_a_decorrelate_rig.maxpat`; spike patches in `scratch/experiments/f_a_decorrelate_instances/` (local, gitignored: `spike_parent.maxpat`, T016, written, not opened in Max, so T016 is `[~]`, not ticked).
- **Finding (by reading, never run):** the hand-built v1 patcher had defects that mean it cannot have worked as shipped: every message box's text began with the word `message` (`message store 1 ...`, `message 44100.`), and the `band` lookup went `sel` (bangs) into `coll` with `coll` outlets 1-3 wired as if they were the stored elements. v1 was only structurally validated (T011); the NumPy mirror and the T002 / T005 Max results came from the scratch rigs, not from this patch. The fragment fixes both (README there). The module's first audible run is therefore the first run of this chain in Max.
- Run offline: `test_build_audio.py` 7/7 (`tests/logs/20261116-234317-offline.log`); `test_drift.py` 16/16 after removing the `f_a_decorrelate` baseline entry (`f_a_decorrelate_inner` stays, `no_definition`); `drift.py f_a_decorrelate` ok; conventions 40/40, render_dim 13/13, layout 11/12 (the known `f_vf_erode` pair); launch 8/8, generate_menu 17/17, gates 5/5 (`20261116-234418-offline.log`).
- Found while running the sweep: `test_launch.py` and `test_generate_menu.py` had been failing since Phase B (the new `f_a_purr` patcher had no README row and no `NOT_IN_MENU` entry; I did not run them then). Fixed minimally, without doing Phase D: a README row and a `NOT_IN_MENU` entry for `f_a_purr`, `f_Launch` regenerated.
- Not verified: everything in Max (T024); T016's spike; that `---` in a `pfft~` box text is substituted per instance before `args` hands it to `#1` (documented behavior of `args` only); `delay~ 1536 1536`; the `line~` stage times (20 / 20 / 5 ms) and that gain 1.0 is the right default; that `deferlow` orders the lookup after the `store` messages (inferred).

### Correction 2026-11-16 (Phase D session, Matt's report: "none of the audio modules have inlets or outlets")

Phases A-C wrote the ports as `newobj` boxes with text `inlet~` / `outlet~`. **Max has no such objects**: a patcher's ports are `inlet` / `outlet` objects, which carry signals too. The three audio patchers therefore had no ports at all (they would show a missing-object box), and my tests passed because they checked for those same wrong boxes (inferred from the report and Max's object set, not opened in Max by me). Also, Phase A dropped the control-message inlet (Q4, "none in Phase A"); Matt wants control messages in. Fixed in `build_audio()`: ports are `inlet` / `outlet` objects (`check_port_order()` now applies); every module has a control inlet feeding `route bypass <params>` into each control (a generator: inlet 0; a processor: the audio inlet 0 and a control inlet 1, so a signal is never fanned out to a route or to `pfft~` as messages); the tests now fail on an `inlet~` / `outlet~` newobj, a missing route or a dropped route cord. The Phase A/B/C records above that call the ports `inlet~` / `outlet~` newobjs are superseded by this note. All three patchers rebuilt, `drift.py` ok, `test_build_audio.py` 8/8; not opened in Max.
