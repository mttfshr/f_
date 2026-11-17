# f_a_purr — Tasks

_Session anchor. Updated 2026-07-27._

## Done

- [x] T001 Concept and layer architecture → `ideas/f_a_purr.md`
- [x] T002 Establish `f_a_` prefix; rename `f_breath_phase` → `f_a_breath_phase`
- [x] T003 Work out cycle-detect, one-pole decay, asymmetric breath warp
- [x] T004 Build scratch patch `/Users/matt/Vsynth/patterns/f_a_purr_scratch.maxpat`
- [x] T005 Bisect codebox failures; verify `phasor`/`twopi`/`cos`/`Param`/`History`
- [x] T006 Replace `latch` with self-referential conditional (deadlock fix)
- [x] T007 Add hand-rolled two-pole resonator
- [x] T008 Clamp all params inside codebox after instability blowup
- [x] T009 Reconcile scratch patch params; remove orphan breath columns

## Next — decision gate

- [x] **T010 Resolve: is per-cycle jitter the primary realism lever?**
      **Resolved 2026-07-27, informally: yes, real.** Ran the bracket-down
      protocol by ear; jitter reads as genuine cat-like irregularity rather
      than a mirage — Outcome A. Exact band edges (the numeric values where
      it flips chaotic→right→imperceptible) were not captured; verdict was
      by feel, not logged per-step. T011 deferred rather than re-run for
      precision — proceeding to build the breath layer (T012) so there's a
      fuller engine to judge final ranges against, rather than tuning
      jitter numbers in isolation now. Original protocol below kept as
      reference if precise ranges are revisited later.

      Re-run sweeps bracketing *down* from obviously-too-much, with A/B
      against a mechanical reference (set value, listen 15s, snap to zero).
      Outcome determines whether the parameter set simplifies and whether
      the layer ordering in the test protocol is backwards.
      **Blocks T011 and Phase 3.**

      Isolates two stacked confounds from the first attempt: no reference
      anchor (swept up from zero, nothing to judge against) and testing
      jitter without breath present (layer 2 doesn't exist yet, so a real
      band could be masked by the missing layer, not absent). This protocol
      fixes only the first confound, cheaply, before touching the second.

      Protocol — repeat per param (`rate_jit`, `amp_jit`, `decay_jit`),
      other two held at 0:

      1. Reference anchor: play the mechanical click train at defaults,
         `jit=0`. Listen 10-15s. This is the "machine" baseline.
      2. Too-much anchor: set param to range max (0.2). Confirm it reads as
         broken/chaotic, not just "very irregular."
      3. Bracket down in fixed steps: 0.2 → 0.15 → 0.1 → 0.05 → 0.02 → 0.
         ~15s per step, snap back to `jit=0` between each step for direct
         A/B rather than comparing to memory.
      4. One question per step: *does this sound more like a cat than the
         machine reference did?* — not "is it audible," audibility isn't in
         question.
      5. Record the step where chaotic→irregular flips (upper edge) and
         where irregular→imperceptible flips (lower edge). That's the
         usable band for this param.
      6. After all three individually, test `rate_jit`+`amp_jit` together
         at their found bands for a quick interaction check.

      **Outcome A** — a real band is found for one or more params → method
      was the confound, hypothesis (1) confirmed. Proceed to T011 with
      these numbers.

      **Outcome B** — still no identifiable band under this protocol → real
      evidence for hypothesis (2). Next step is building layer 2 (breath,
      T012) and re-testing jitter *with* breath present, since the ear may
      need that layer to judge irregularity against — not more jitter
      tuning in isolation.

- [ ] T011 **(deferred, partial preset found)** Record usable ranges for
      `rate_jit`, `amp_jit`, `decay_jit`, individually and in combination.
      Deliverable is four numbers plus an interaction note. Feeds spec.md
      parameter table. Deferred 2026-07-27 pending breath layer (T012) —
      revisit ranges once there's a fuller engine to judge them against.

      **2026-07-27, post-breath/noise/resonator listening pass:** initial
      full-engine listen (all layers, defaults) read as "motorcycle near
      the ocean" — perfectly periodic click train ringing a high-Q
      resonator (jitters still at 0), plus `breath_noise` dragged to 1.44
      (clamped to 1.0 internally, full-strength surf). Found a working
      combination by ear that reads noticeably more cat-like and less
      mechanical/oceanic, now baked into the scratch patch's preset
      messages: `rate_jit` 0.05, `amp_jit` 0.05, `decay_ms` 3.7,
      `decay_jit` 0.6, `breath_hz` 0.32, `breath_skew` 0.79,
      `breath_rate_mod` 0.464, `breath_noise` 0.15, `res_hz` 215.5,
      `res_q` 0.9919. This is a whole-preset verdict ("approximately
      better"), not isolated per-param bands — still doesn't satisfy
      T011's original deliverable (four numbers + interaction note from
      controlled one-at-a-time sweeps), but is a real, verified-by-ear
      starting point worth preserving rather than losing to further
      dial-dragging. `res_hz`/`res_q` moved substantially from their
      original defaults (90→215.5, 0.98→0.9919) — the high-Q clean ring
      was a major contributor to "motorcycle," not just the missing
      jitter.

      **2026-11-03 note (read from the scratch patch's codebox):** the
      preset's `decay_jit` 0.6 and `res_hz` 215.5 sit outside the ranges in
      spec.md (0–0.2, 20–200) but inside the codebox clamps (`decay_jit` and
      `amp_jit` 0.9, `rate_jit` 0.5, `res_hz` up to `samplerate * 0.25`).
      spec.md's table is marked provisional; per-parameter ranges are
      decided when this task is finished.

## Build — layers 2 and 4

- [x] T012 Re-add layer 2 (breath) to codebox; restore the four breath param
      columns removed in T009. **Done 2026-07-27.** Free-running breath
      phase accumulator (independent of click cycle) + asymmetric warp +
      raised-cosine `b_curve`, folded into `rate_target` per ADR-3/Q5
      (latched per-cycle, not continuous) and into a `b_gain` output-
      amplitude term via `breath_depth`. `out1`/`out2` reassigned to match
      spec (`out1`=audio incl. breath gain, `out2`=breath phase) — the old
      `env` debug outlet is gone. Four UI columns restored: `breath_hz`
      (0.4), `breath_skew` (0.3), `breath_depth` (0.3), `breath_rate_mod`
      (0.2). Verified in Max via T013/T014 below.
- [x] T013 Verify asymmetric warp: `breath_skew` 0 vs. high, `breath_depth`
      fixed. The tremolo-vs-breathing test. **Passed 2026-07-27** — reads as
      breathing, not tremolo.
- [x] T014 Confirm breath phase is continuous across the 0.5 crossover in
      practice, not just on paper. Note: spec.md's outlet table uses
      0-indexed naming (`out0`=audio, `out1`=phase); the gen~ codebox and
      Max's physical outlets are 1-indexed, so breath phase is codebox
      `out2` / the module's second physical outlet, not literally "out1."
      **Passed 2026-07-27** — no discontinuity/click at the crossover.
- [ ] T015 Decide whether `bcurve` peaking at the inhale/exhale crossover is
      the right amplitude shape, or whether energy should peak mid-exhale
      (2026-11-03: research says amplitude dips at both flow reversals, i.e. two
      humps; implemented as an option, `breath_shape`, in T035. The decision itself
      needs your ears; leave this open until you've compared the shapes.)
- [x] T016 Add layer 4 (breath noise), gated by breath envelope. **Done
      2026-07-27.** New param `breath_noise` (0-1, default 0). Broadband
      noise through a fixed-coefficient one-pole lowpass (0.05, hardcoded —
      idea file doesn't call for a separate exposed tone param, so this
      isn't user-controllable color, just enough to keep it from being flat
      white noise), gated by the same `b_curve` used for breath gain,
      mixed additively into `out1` post-resonator. UI column added at
      x=706 (new row, y=280/312, to avoid colliding with the
      `breath_rate_mod` column occupying the same x at the main row).
      **Not yet verified in Max** — JSON-validated only.
- [ ] T017 Test per-breath resonator detune (idea file Q4) — audible or
      wasted complexity?

## Realism pass — from `ideas/f_a_purr_realism_research.md` (2026-11-03)

Written together at Matt's request ("do all 2-5"). Every one defaults to the old
behaviour, so with the new params at 0 (and `breath_skew` unchanged) the sound should be
statistically the same as before; the random draws come from slightly different `noise()`
call sites, so it will not be bit-identical (it never was run to run). **None compiled or
heard in Max.** Code is in `src/f_a_purr/codebox.gen`; test copy with controls and two
preset message boxes: `scratch/experiments/f_a_purr_realism/f_a_purr_scratch_realism.maxpat`.

- [ ] T035 `breath_shape` (0-1, default 0): morphs `b_curve` from one hump per breath
      (`0.5 - 0.5 cos(2 pi p)`) to two (`0.5 - 0.5 cos(4 pi p)`, zero at p = 0, 0.5, 1,
      peaks mid-inhale and mid-exhale). Same mean level (both average 0.5). `b_curve` also
      drives the rate fold and the breath-noise gate, so both follow the shape. The floor
      at the dips is `1 - breath_depth`, no separate floor param. Evidence: research note
      finding 2 (medium confidence, one source seen secondhand).
- [ ] T036 `breath_jit` (0-0.3, default 0): per-breath rate multiplier latched at each
      breath wrap, `1 + breath_jit * 1.732 * noise()` (so `breath_jit` is its standard
      deviation), floored at 0.3. Applies to the internal oscillator only. Measured SD of
      phase durations was 0.09-0.21. A held multiplier, not a re-latched rate, so
      `breath_hz` still changes take effect immediately.
- [ ] T037 `jit_tau` (0-10 s, default 0): the three click jitters (`rate_jit`, `amp_jit`,
      `decay_jit`) become AR(1) noise across click cycles with correlation time `jit_tau`
      seconds (`rho = exp(-1 / (jit_tau * rate))`, innovation scaled by `sqrt(1 - rho^2)` so
      the stationary spread stays the same and the existing jitter dials keep their
      meaning; clamped to +-3). 0 = independent each cycle (old behaviour). A one-pole
      approximation of the 1/f-like variation found in natural voices, not a true 1/f source.
- [ ] T038 `breath_skew` widened to -1..1: inhale share is `0.5 - 0.4 * skew`, so negative
      values make inhale the longer phase (the four-cat measurement had inhale 51-54%).
      Values in 0..1 are unchanged.

      **Owed (Matt, live):** (1) the codebox compiles in the test copy (console message if
      not); (2) with the new params at 0, it sounds like before; (3) the two message boxes
      are an A/B: A = the T011 breath settings, B = evidence-based (`breath_hz` 0.8,
      `breath_skew` -0.1, `breath_shape` 1, `breath_jit` 0.15, `jit_tau` 0.5). Those B values
      come from the research numbers, not from listening. The message boxes do not update the
      number boxes, so the number boxes show stale values after clicking one; (4) move
      `breath_shape` 0 -> 1 with `breath_depth` raised (try 0.6) and judge T015; (5) turn
      `jit_tau` up with the existing jitter dials and say whether it reads as less machine.

## Inhale/exhale timbre contrast and tempo runs (written 2026-11-04, not compiled or heard)

- [ ] T039 Matt, 2026-11-04: "I think we want an inhale vs exhale timbre difference."
      Evidence: Schötz & Eklund say the two phases are distinguishable by sound and waveform;
      Remmers & Gautier put the vocal tract on opposite sides of the larynx in the two
      phases; the direction of the level and F0 differences is individual (research note
      findings 1 and 4), so no fixed "dull inhale" is justified and the controls must be
      bipolar; Purrli plays a different recording per phase (research note, Purrli section).
      **Design (Matt, 2026-11-04: "go", all four):** keep one click generator and offset its
      parameters by phase. Weight `s = sin(2 pi b_phase)`: +1 mid-inhale, -1 mid-exhale,
      0 at both flow reversals. It is smooth, and the timbre passes through neutral exactly
      where the two-hump gain (T035) dips, so any change is masked. Bipolar params, all
      default 0 so nothing changes until used: `ph_gain` (inhale/exhale level balance),
      `ph_tilt` (click spectral tilt, duller or brighter on inhale), `ph_res` (resonator
      frequency offset in semitones, the tract-position difference), `ph_rate` (F0 offset
      between phases; antisymmetric, unlike `breath_rate_mod`, which is the same in both
      phases). Works with the internal and the external phase.
      **Written 2026-11-04, not compiled or heard.** Full-scale effects: `ph_gain` +-6 dB
      (positive = inhale louder); `ph_tilt` multiplies the tilt coefficient by e^(+-1)
      (positive = inhale brighter, clamped to the existing 0.02-1); `ph_res` +-6 semitones
      (positive = inhale higher); `ph_rate` +-15% click rate (positive = inhale faster).
      The 6 dB / 6 semitone / e / 15% full-scale sizes are my choices, not from data (the
      F0 data spread about +-10% between phases, research note finding 4). The weight is
      written `cos(twopi * (phase - 0.25))` because `cos` is the operator already verified
      in this codebox; a flatter shape is still an open option. At 0 each term multiplies
      by exactly 1.

- [ ] T040 Clustered tempo excursions (`run_prob` 0-1 default 0, `run_oct` 0-1.5 default
      0.6). Idea from the architecture study of a public generator (research note, Purrli
      section); Matt, 2026-11-04: "add it now". At each breath wrap with no run active,
      probability `run_prob` starts a run of 2-4 breaths at a different breath tempo,
      drawn log-uniform within +-`run_oct` octaves (default 0.6 = 0.66x to 1.5x), then back
      to normal. Acts on the internal breath oscillator only (not an external phase) and
      does not change the click rate. Complements `breath_jit`, which varies each breath
      independently. The "runs on" message in the test patch uses `run_prob` 0.15, an
      arbitrary starting value.

      **Owed (Matt, live), T039 and T040:** (1) the codebox compiles in the t039 test copy;
      (2) with all six new params at 0 it sounds like the realism patch did; (3) with
      `breath_shape` 1 and `breath_depth` raised so the phases are audible, try each `ph_`
      param at +1 and -1 and say which direction sounds more like a real cat (the
      purring.org clips are the reference); (4) `run_prob` 0.15: does the clustering read
      as natural or as glitchy?
## Documentation debt — do before this scrolls out of memory

- [x] T018 Add a gen~ / audio-domain section to
      `skills/jit-gen-codebox/SKILL.md`. **Done 2026-07-27.** New top-level
      section, clearly marked as a different compiler from the GPU-path
      content above it. Covers all four findings: `in`-object requirement,
      `latch` zero-init deadlock (with the self-referential-conditional
      fix), read-before-write History precaution, and `noise()` being
      valid in gen~ (explicit reversal callout against the GPU-path rule
      right above it). Also references the `_build_purr_scratch.py`
      `code`/`text` key bug as a concrete case.
- [x] T019 Fix `_build_purr_scratch.py` — writes codebox contents to `text`;
      must be `code`. **Done 2026-07-27.** Key fixed. Also added a
      prominent header comment flagging that `GEN_CODE`/`PARAMS` in this
      script are stale (predate the resonator, breath layer, and layer 4)
      — fixing the key bug alone does not make the script safe to run;
      it would still silently overwrite the current hand-built codebox
      with an older, simpler one.
- [x] T020 Update `ideas/f_a_purr.md`: jitter ranges are 0–0.2 not 0–1;
      ADR-5 resonator; ADR-6 clamping; mark Q5 mechanism as verified.
      **Done 2026-07-27.** Parameter contract table rewritten with actual
      ranges/defaults for all 13 params including `res_hz`/`res_q`/
      `breath_noise`; status line updated; Q1 and Q3 marked resolved
      (Q3 partial); Q4 updated to note it's now testable; outlets section
      annotated with the 0-indexed-spec vs. 1-indexed-Max distinction.
- [x] T021 Fix the stale comment block in the scratch patch — still describes
      layer 2 and the breath-phase outlet, which no longer exist in the
      codebox. **Done 2026-07-27**, alongside T012 rather than strictly
      after it. Comment now describes the actual current layer set,
      outlet assignment, and verification status.

## Deferred — open questions from ideas/f_a_purr.md

- [ ] T022 Q2 — presets vs. continuous morphing. Needs T011's ranges first.
- [x] T023 Q3 — parametric click vs. wavetable bank. **Resolved (partial)
      2026-07-27** — parametric built and confirmed audible/non-repeating;
      wavetable alternative not pursued. See `ideas/f_a_purr.md` Q3.
- [x] T024 Q6 — performance instrument vs. fixed piece. **Decided (Matt,
      2026-11-03): "playable by construction" for v1.** No macro, mapping or
      scheduler layer; presets as saved messages (T011 preset first). Owed:
      a live-safety check (fast param moves, no clicks or blowups) on the next
      listening pass. My reading of the codebox says rate/decay are latched per
      cycle and the resonator is clamped stable; that is inferred, not heard.
- [ ] T025 Q7 — inlet accepting an external 0–1 breath phase, overriding the
      internal oscillator. **Decided (Matt, 2026-11-03): in v1, with an
      explicit `breath_src` switch** (0 internal, 1 external) plus the signal
      inlet; no sentinel value, because an unconnected gen~ inlet reads 0, a
      valid phase. External phase replaces `b_phase` directly (skips the
      `breath_skew` warp; `breath_hz` and `breath_skew` inert in that mode).
      **Not yet built or tested.** Test input: a `phasor~`.
      **Design sketched 2026-11-03 (Matt: crossfade between sources):**
      the fade is done on the *phase*, along the shortest circular arc
      (`d = ext - b_int`, wrapped to [-0.5, 0.5) with comparisons only), not on
      derived values, so `b_curve`, the rate fold, the noise gate and `out2`
      all stay consistent. `breath_src` is clamped 0-1 (ADR-6) and smoothed by
      a one-pole (about 50 ms time constant; first sketched as fixed, then
      exposed as `breath_src_ms` at Matt's request, see Applied below).
      The external value is used only if `0 <= in1 <= 1` (a NaN fails both
      comparisons and falls back to internal), so a bad sensor value cannot
      reach the latched-rate feedback. The internal breath oscillator keeps
      running so switching back never jumps. `in1` already reaches the codebox
      (it has one inlet, fed by `in 1`), so no rewiring; the patch only needs
      a `breath_src` control. Known edge: mid-fade, if the two phases are
      exactly antipodal the blend direction flips (a step of size mix); at
      `breath_src` 0 or 1 it has no effect. Operators used are only ones already
      verified in this codebox (comparisons, ternary, arithmetic, `exp`).
      **Applied 2026-11-03 (Matt: go; fade time exposed as a param):** the
      sketch is in `src/f_a_purr/codebox.gen` (114 lines) with a new
      `breath_src_ms` param (clamped 1-2000, default 50, one-pole time
      constant). A copy of the scratch patch with the same codebox, a
      `breath_src` and `breath_src_ms` control and a `phasor~ 0.3` test source
      is at `scratch/experiments/f_a_purr_breath_src/f_a_purr_scratch_t025.maxpat`; the
      original scratch patch is untouched. Control positions are guesses
      (below the breath_noise column, y about 390), not looked at. **Not
      compiled or heard in Max.** Owed (Matt, live): (1) `breath_src` 0 sounds
      the same as before; (2) src 1 with the `phasor~` follows it, scope on
      `out2`; (3) toggling mid-play, listen for a click; (4) feed 2.0, -1 and a
      NaN-making value at src 1 and check it falls back to internal with no
      lasting silence; (5) src 1 with nothing connected sits at gain
      `1 - breath_depth` (expected). Then T025 can be ticked.
      **Live report (Matt, 2026-11-03 21:01):** the test copy runs ("working
      fine"), "sounds approximately like a purr, but could be more realistic".
      The codebox compiled. The five checks were NOT reported individually, so
      T025 stays unticked; a toggle was added to the test patch for check 3.

## Phase 4 — production build (not started)

- [x] T026 **Decision gate (answered 2026-11-16, G-audio: the audio archetype in the builder):** how does an `f_a_` module get built?
      `build_patcher.py` targets the `jit.gl.pix` archetype and cannot
      generate this. Options: hand-build, extend the build script with an
      audio archetype, or accept hand-built status like `f_masonry`.
- [x] T027 Build `package/patchers/f_a_purr.maxpat` per the decision in T026 (built 2026-11-16 from `src/f_a_purr/definition.py`, offline only; heard checks owed, T047)
- [x] T028 (decided 2026-11-16, G-audio: yes, an Audio category; built, Phase D) Decide whether `f_a_` modules appear in `f_modules.maxpat` at all
      — the menu spawns visual modules into a Vsynth patch
- [ ] T029 `docs/f-reference/f_a_purr.md` as-built reference
- [ ] T030 Helpfile per `skills/f-helpfile/SKILL.md` conventions

## Research — parallel, non-blocking

- [x] T031 Purr rate ranges, adult vs. kitten — published measurements.
      **Found 2026-07-27** — see `ideas/f_a_purr.md` Research Needed.
      ~25–150 Hz consensus, adult cats cluster 25–50 Hz, kittens ~30–60 Hz.
- [x] T032 Ingressive vs. egressive phase: rate / amplitude / timbre deltas.
      **Found 2026-07-27, inconclusive** — literature itself disagrees on
      direction/magnitude across four sources. See idea file.
- [x] T033 Chest and tract resonance frequencies in domestic cats.
      **Searched 2026-07-27, no usable published numbers found** —
      literature covers glottal/laryngeal mechanism, not chest/tract
      formants. `res_hz` stays an ear-tuned value, not literature-derived.
- [x] T034 Prior art: academic purr synthesis models, if any exist.
      **Found 2026-07-27, none specific to purring exist** — confirms
      original assumption to build from acoustics directly.

## Audio archetype, Phase B (added 2026-11-16, Claude; Matt's go "as proposed"; BUILT offline 2026-11-16, Max checks owed)

Source: `build/spec.md` "Audio archetypes" (Phase B: `f_a_purr` as the first new module through the shell built in Phase A, record in `.specify/f_a_ripple/tasks.md`). It answers T026 (the build decision: the audio archetype, `G-audio`) and T027 (build the patcher). T028 (menu) stays Phase D; T029 / T030 (docs, helpfile) are out of scope. Facts below were read this session from `src/f_a_purr/codebox.gen` and this folder's spec / tasks (not run).

Starting point: `src/f_a_purr/codebox.gen` (176 lines, 22 `Param`s, `in1` = external breath phase, `out1` = audio, `out2` = breath phase), no patcher exists (`package/patchers/f_a_purr.maxpat` is absent), the test copies are in `scratch/experiments/`. The codebox has no `gain`, no `bypass_gate` and no output ceiling; its defaults are the old ones (rate 25, res 90, q 0.98), not the T011 by-ear preset. The realism pass and the T039 / T040 / T025 code in it have never been compiled or heard in Max (T035-T040, T025 above), so the first open of the built patcher in Max is also their compile check.

- [x] T041: Codebox edits for the module, listed in `src/f_a_purr/README.md`, nothing else: `Param bypass_gate(0.0)` with a ~5 ms slewed mute on `out1` only (`out2`, the breath phase, keeps running, so a consumer is not stalled by a bypass; as Matt chose for ripple, the generator's neutral is silence); `Param gain` and a `tanh` ceiling on `out1` (ADR-6 style; the resonator at Q 0.9919 is not bounded by construction); `Param` defaults changed to the T011 preset (Q2). DSP and the unheard realism code untouched.
- [x] T042: Builder, extending `build_audio()` (Phase A, texture path still untouched): (a) `audio_outputs`, a list of `outlet~` comments (default one), so purr gets audio plus the breath phase on a second `outlet~`; ids `obj-2` and onward as in the spec, x strictly increasing; (b) the `inlet~` / `outlet~` ports are `newobj`s, which `check_port_order()` does not see, so `build_audio` checks their x order itself (Max reorders ports by x on save); (c) `audio_in` takes a comment (here "breath phase 0-1"; the inlet~ is a control signal, not audio to process); (d) the codebox's `out N` count must equal the outlet count (a loud error, as for undeclared Params); (e) a grid of 23 controls (22 params plus Bypass is in the title bar): 7 columns by 4 rows with the existing 62 px row pitch.
- [x] T043: `src/f_a_purr/definition.py`: `archetype: "audio_gen"`, `audio_in: True`, two outputs, the 22 params in layer groups (click: rate_hz, rate_jit, amp_jit, jit_tau, decay_ms, decay_jit, tilt; resonator: res_hz, res_q; breath: breath_hz, breath_skew, breath_depth, breath_rate_mod, breath_shape, breath_jit, run_prob, run_oct, breath_noise; source: breath_src, breath_src_ms; phase contrast: ph_gain, ph_tilt, ph_res, ph_rate; plus gain), ranges per Q2, hints from the spec text.
- [x] T044: `tests/build/test_build_audio.py` extended: the output count, port x order of the two `outlet~`, `audio_in` comment, the codebox `out N` count check, and mutants for them (a reversed port order, a missing second outlet). It already covers every `audio_*` definition, so purr joins by being built. One named test, `-q`, run with Matt's go.
- [x] T045: Build `package/patchers/f_a_purr.maxpat`; `drift.py f_a_purr` ok; `test_drift.py` (a new patcher with a definition must reproduce; no baseline entry is needed or added). A standalone rig `tests/rigs/f_a_purr_rig.maxpat` (an `f_a_purr` bpatcher with a `phasor~ 0.3` into its inlet, `ezdac~`, `scope~` on each outlet, `peakamp~`), not opened in Max.
- [x] T046: Records: this file (tick T026 and T027 only if Matt agrees the build answers them; T028 stays open), `src/f_a_purr/README.md` (it says the scratch patch is the master and the file is not a build input: both change, `src/` becomes the master), the `G-audio` row and `build/spec.md` status, `HANDOFF.md` START HERE; the definition-scanning tests run again (layout, conventions, render_dim, gates) with Matt's go; one commit.
- [ ] T047 (owed to Matt, Max): open the built patcher (compile check for the realism, `ph_`, `run_` and `breath_src` code, none of which has been heard); listen at the new defaults against the T011 preset; Bypass clicks; the breath phase on outlet 2 with a scope; the inlet with a `phasor~` and `breath_src` 1; two instances; save-in-Max round trip.

### Decided 2026-11-16 (Matt: "Go, as proposed")

1. **Defaults and ranges (Q2).** Proposal: the module's defaults are the T011 by-ear preset (`rate_jit` 0.05, `amp_jit` 0.05, `decay_ms` 3.7, `decay_jit` 0.6, `breath_hz` 0.32, `breath_skew` 0.79, `breath_rate_mod` 0.464, `breath_noise` 0.15, `res_hz` 215.5, `res_q` 0.9919; the rest as in the codebox), the only listen that read as "approximately better", with the realism and `ph_` / `run_` params at 0. The dials follow the spec table except where the preset sits outside it: `decay_jit` 0-0.9 and `res_hz` 20-400 (the codebox clamp is `samplerate * 0.25`; 400 is my choice) and `breath_rate_mod` -0.5-0.5. Or: keep the old codebox defaults and the spec ranges, and ship the preset as a saved state later.
2. **Level.** Proposal: `gain` 0-1, default 0.3 (a guess: the codebox's raw level was never measured), then `tanh`. Say if you know the right level or want a different ceiling.
3. **Unheard DSP.** Proposal: build it anyway from `src/` as it is; the first open in Max is the compile check and a failure there is a codebox bug to fix in `src/`, not a builder bug. Alternative: hold Phase B until you have compiled and heard the t039 test copy in Max.
4. **Bypass and the phase outlet.** Proposal as T041: bypass mutes `out1` only; the breath phase keeps running.

### Phase B record (2026-11-16, Claude, offline)

- Built: `src/f_a_purr/{definition.py,codebox.gen (edited, see README.md)}`, `package/patchers/f_a_purr.maxpat` (new; 23 controls in a 7 x 4 grid, Bypass in the title bar, `inlet~` for the breath phase, two `outlet~`: purr and breath phase), `tests/rigs/f_a_purr_rig.maxpat`. Builder: `audio_outputs` (one `outlet~` per entry), `audio_in_comment`, an `outlet~` x-order check, a loud error when the codebox's `outN` assignments do not match `audio_outputs`. `f_a_ripple` was rebuilt too (its `outlet~` now carries the comment "audio out"; `drift.py` ok for both).
- Run: `test_build_audio.py` 6/6 (`tests/logs/20261116-233624-offline.log`); `test_drift.py` 16/16, `test_build_conventions.py` 40/40, `test_render_dim.py` 13/13, `test_layout.py` 11/12 (the known `f_vf_erode` pair; `20261116-233643-offline.log`). `test_gates.py` is run after the records are final (below).
- Not verified: everything in Max (T047). The `gain` identifier as a gen~ Param name is unchecked in Max (it is also used by `f_a_ripple`); the codebox has never been compiled with the realism / `ph_` / `run_` / `breath_src` code; the `tanh` ceiling and the default level 0.3 are guesses; the 400 Hz `res_hz` ceiling is my choice. T028 (menu) stays open (Phase D).

### Correction 2026-11-16 (Phase D session, Matt's report: "none of the audio modules have inlets or outlets")

Phases A-C wrote the ports as `newobj` boxes with text `inlet~` / `outlet~`. **Max has no such objects**: a patcher's ports are `inlet` / `outlet` objects, which carry signals too. The three audio patchers therefore had no ports at all (they would show a missing-object box), and my tests passed because they checked for those same wrong boxes (inferred from the report and Max's object set, not opened in Max by me). Also, Phase A dropped the control-message inlet (Q4, "none in Phase A"); Matt wants control messages in. Fixed in `build_audio()`: ports are `inlet` / `outlet` objects (`check_port_order()` now applies); every module has a control inlet feeding `route bypass <params>` into each control (a generator: inlet 0; a processor: the audio inlet 0 and a control inlet 1, so a signal is never fanned out to a route or to `pfft~` as messages); the tests now fail on an `inlet~` / `outlet~` newobj, a missing route or a dropped route cord. The Phase A/B/C records above that call the ports `inlet~` / `outlet~` newobjs are superseded by this note. All three patchers rebuilt, `drift.py` ok, `test_build_audio.py` 8/8; not opened in Max.
