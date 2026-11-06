# Tasks: f_vf_stamp

**Spec**: spec.md · **Plan**: plan.md · Created 2026-11-05 (Claude, with Matt). Nothing is built; every box is open.

Record format: date, who observed (offline Claude / live Matt), source (log path, commit).

## Phase 0: gates and the mirror (BLOCKING for Phase 1)

- [x] T001 [GATE G1] DECIDED (Matt, 2026-11-05): the envelope is in FRAMES, a per-draw one-pole (plan ADR-3), not `line` in ms.
- [x] T002 [GATE G2] DECIDED (Matt, 2026-11-05, on Claude's read of `codebox_advect.gen`): `out0 = vec(in0.rgb * cov * amount * env, 1.0)`; RGB carries the mask, A stays 1.
- [ ] T003 [GATE G3] Radial and swirl field: edge band only versus a smoothed interior; magnitude normalisation (plan ADR-4). Decided by the mirror numbers and a live look.
- [x] T004 [GATE G4] DECIDED (Matt, 2026-11-05): EXTRACT a schema UI type from `f_wave_field`'s raw boxes (`f_vf_stamp` is the second user), guarded by `drift -v f_wave_field`. Work is T020.
- [x] T005 [GATE G5] DECIDED (Matt, 2026-11-05: "pass the input through"; reading CONFIRMED by Matt in chat the same day): bypass = out0 passes in0, out1 passes in1 when it is connected (neutral 0.5 / 0.5 when not), gate and envelope ignored, FR-011's non-finite zap still active. Consequence: a bypassed stamp hands the WHOLE texture downstream as ink, not nothing.
- [ ] T006 [GATE G6] Dial set, ranges, defaults, with `G-ui-density` in mind. Decider: Matt.
- [x] T007 [GATE G7] DECIDED (Matt, 2026-11-05): Rec.709. The library is split, no single weight (list in the Record below).
- [ ] T008 [GATE G8] Menu category (the stamp takes and produces vecfields: Effects or Adapters). Held by `G-menu`; decide at Phase 3.
- [x] T009 NumPy mirror `tests/modules/vf_stamp/vf_stamp_mirror.py` and `test_vf_stamp.py`: coverage closed forms, idle exactness, linearity, mask zero, radial outward / swirl divergence-free and rotated 90 degrees, periodic wrap equivalence, noise range and determinism, non-finite zap (SC-001 to SC-004). Run `-q`.
- [x] T010 Record the mirror's numbers for the radial and swirl band at `softness` 0.02 / 0.1 / 0.3 (feeds T003). Script `tests/modules/vf_stamp/vf_stamp_bands.py`; numbers in the Record below.

## Phase 1: build

- [ ] T020 (if T004 = extract) Schema UI type for the gate button; rebuild `f_wave_field` from it; `drift -v f_wave_field` must still reproduce. Offline checks only (contracts, mirror); the live look is Matt's.
- [ ] T021 `src/f_vf_stamp/codebox_stamp.gen` (coverage, ink, impulse, bypass, containment, periodic indices).
- [ ] T022 `src/f_vf_stamp/definition.py`: two `vs_inState` inlets, `src_vec` flag, Params (`stamp_gate`, `env`, the dials), raw boxes for the gate (or the schema type from T020) and the envelope (plan ADR-3).
- [ ] T023 Build, `drift`, `test_module_contracts.py`, JSON validate.
- [ ] T024 `tests/modules/vf_stamp/bench_vf_stamp.py` (GPU against mirror, two inputs) and `bench_vf_stamp_module.py` (connected flags, gate sequence, bypass). Written offline; run only with Matt's go.

## Phase 2: tuning (Matt)

- [ ] T030 Live look: a held stamp into `f_vf_advect` + `f_vf_fluid`; Radial versus Swirl at `project` 1 (the prediction: swirl stirs, radial does not).
- [ ] T031 Live look: a camera on in0 and `f_vf_optical_flow` on in1.
- [ ] T032 Dial ranges, defaults, envelope feel, the `impulse` default.

## Phase 3: docs and registration

- [ ] T040 Reference doc, helpfile (the `f-helpfile` skill), menu placement (G8), README row (110 characters).
- [ ] T041 `ideas/f_vf_stamp.md` status to built; `ideas/f_vf_ch.md`, `f_vf_emulsion.md`, `f_vf_mix.md` links check.

## Record

- 2026-11-05 (offline, Claude): spec, plan and this task list written from `ideas/f_vf_stamp.md` and the decisions Matt made in chat the same evening (stamp only, luma coverage, name `f_vf_stamp`, radial fallback with a swirl switch, the held press). The unsettled parts are the gates above; none of the design numbers (envelope law, field normalisation, dial ranges) has been tried.
- 2026-11-05 (Matt, chat, 20:58): G1 frames, G4 extract, G5 pass the input through (reading above, unconfirmed). Open: T002, T003, T006 (dials), T007, T008, T009, T010. New session started from `HANDOFF.md`.
- 2026-11-05 (Matt, chat): G5 reading confirmed.
- 2026-11-05 (offline, Claude, read from source; awaiting Matt): T002: `src/f_vf_advect/codebox_advect.gen` injects `sample(in1, uv) * inj_eff` on all four channels, then clamps 0-1. No alpha gating, no luma, no premultiply step, so RGB must already be masked; A is carried as a plain fourth channel. T007: the library has no single weight. By `grep` of `src/`: Rec.709 in `f_lens`, `f_tf_hatch`, `f_vf_advect` (pass stage), `f_vf_ch`, `f_vf_chroma` (paused), `f_vf_glow`, `f_vf_optical_flow`, `f_vf_prism`, `f_wc`; Rec.601 in `f_grain`, `f_luma_processor`, `f_sirds`, `f_tf_glyph`, `f_tf_tensormap`, `f_tone_curve`, `f_vf_advect` (gradient outlet), `f_vf_fieldmap`, `f_vf_lbm`, `f_vf_repulse`. The two references G7 names disagree.
- 2026-11-05 (Matt, chat): G2 and G7 accepted as proposed (Rec.709; `out0 = vec(in0.rgb * cov * amount * env, 1.0)`).
- 2026-11-05 (offline, Claude, mirror only, nothing on the GPU or in `f_vf_fluid`): T010 at N = 256, disc radius 0.2, force 1. (1) ADR-4's `unit` field is ZERO on a hard-edged disc at every `softness`: `cov` is 0 or 1 at every texel centre, so `4 cov (1 - cov)` vanishes. (2) `softness` is a width in luma, not in space: on a hard disc it changes nothing (band, peak and rim identical at 0.02 / 0.1 / 0.3); `edge` at 0.3 changes nothing there either, so ADR-5's "works for any stamp shape" holds only for stamps with a soft luma ramp. (3) The candidate `diff` field (plain central difference at `reach` s, no divide) gives band about 1.8 s texels, rim about 2.1 s whatever the softness (s = 4: 8.05 to 8.43), peak 1.41 (per component within 1). Discrete curl and divergence by its own stencil are 0. (4) Energy kept by the projection formula: s = 1, radial 0.04 / swirl 0.96; s = 4, 0.10 / 0.90; s = 8, 0.10 / 0.90 on a hard disc; soft disc with `softness` 0.3, s = 4, 0.007 / 0.993. `unit` on a soft disc at `softness` 0.02: 0.43 / 0.57, so the radial / swirl split fails there. Viscosity and `f_vf_fluid`'s `taps` filter are not modelled. T003 waits for Matt.
