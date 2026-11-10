# Tasks: f_vf_erode

**Spec**: spec.md · **Plan**: plan.md · Created 2026-11-08 (Claude, with Matt). **Narrowed 2026-11-09: T050 onward is the current work; everything above it describes the earlier design (spec "Narrowed", plan ADR-9).**

Record format: date, who observed (offline Claude / live Matt), source (log path, commit).

**Gate convention for this list:** a gate marked **PRELIMINARY** was decided by Claude's own recommendation on Matt's instruction (2026-11-08), not by Matt. It stays unticked until Matt confirms it or a measurement settles it. Gates Matt decided in the clarify session (Q1 to Q5) are ticked.

## Expected source layout

```
src/f_vf_erode/{definition.py, codebox_zap.gen, codebox_blur.gen, codebox_thresh.gen, codebox_pool.gen, codebox_fx_b.gen, codebox_dir.gen}
tests/modules/vf_erode/{vf_erode_mirror.py, test_vf_erode.py, bench_vf_erode.py, bench_vf_erode_module.py}
package/patchers/f_vf_erode.maxpat    docs/f-reference/f_vf_erode.md    package/help/f_vf_erode.maxhelp
```

## Phase 0: gates and the mirror (BLOCKING for Phase 1)

- [x] T001 [GATE Q1] DECIDED (Matt, 2026-11-08): the effects run in one fixed order.
- [x] T002 [GATE G6] DECIDED (Matt, 2026-11-08): output is unclamped float32.
- [x] T003 [GATE G3] DECIDED (Matt, 2026-11-08): patterns fixed to the frame, no switch.
- [x] T004 [GATE G8] DECIDED (Matt, 2026-11-08): two dedicated optional inlets (in1 amount texture, in2 spread-direction vecfield).
- [x] T005 [GATE Q5] DECIDED (Matt, 2026-11-08): three channel gains.
- [ ] T006 [GATE G1] PRELIMINARY: tiers 1, 2 and 3 all apply (plan "Testing plan"); nothing skipped.
- [ ] T007 [GATE G2] PRELIMINARY: every length in frame heights; x scaled by the aspect (plan ADR-7).
- [x] T008 (2026-11-09, bench, Claude; matrix-fed input only; see Record) [GATE G4] MEASURE on the bench first (T024): does `sample()` interpolate on this hardware? Until then the design uses only `nearest` taps at texel centres (plan ADR-2). Resolves the disagreement between `ideas/f_deflicker.md` and `.specify/f_vf_stamp/spec.md` FR-009.
- [ ] T009 [GATE G5] Spread cap DECIDED (Matt, 2026-11-08: taps one texel apart, 7 texels of reach). The pool blur cannot reuse the spread blur (plan ADR-3). MEASURE on the bench: the cost of the four blur stages at 1080p.
- [ ] T010 [GATE G7] PRELIMINARY: clamp-to-edge at the frame border, by explicit texel index math.
- [ ] T011 [GATE G9] DEFERRED by Matt (linear-light versus encoded). PRELIMINARY: treat values as given; revisit at T031 and add a switch if the look needs it.
- [ ] T012 [GATE G10] PRELIMINARY: three-octave value noise from the sin hash for mottle, one octave for tooth (plan ADR-4); confirm the statement count when written.
- [ ] T013 [GATE G11] PRELIMINARY: keep the name `f_vf_erode`; menu category at Phase 3 (`G-menu`).
- [ ] T014 [GATE G12] PRELIMINARY: panel grouped as Spread / Edge / Mottle / Dropout, then P2 rows (Fleck, Band, Gains, Drivers); decide the final layout at T040 with Matt (`G-ui-density`).
- [x] T015 (Matt, 2026-11-08: "Accept for now"; revisit at the looks, T030 and T031) Confirm with Matt the five assumptions left in the spec (A1 polarity, A2 per channel, A3 stateless, A4 frame-relative units, A6 identity at zero) and the two small G8 details (what in1 scales, how in2 elongates the kernel).
- [x] T016 (2026-11-08, offline, Claude; 15/15; re-run after the stride cap, log `tests/logs/20261108-232402-offline.log`) [US1-US4] NumPy mirror `tests/modules/vf_erode/vf_erode_mirror.py` and `test_vf_erode.py` per the plan's Tier 1 list: identity at zero, spread (disc area, merge, thin, bias), mottle statistics, dropout monotone and light-first, edge-pool rim, determinism, render-size scaling, border, non-finite zap. Run `tests/run.sh -q tests/modules/vf_erode/test_vf_erode.py`.
- [x] T017 (2026-11-08, offline, Claude; numbers in Record) [US1] Record in the mirror the measured numbers that settle SC thresholds still marked open in the spec (mottle mean shift, area preservation of the re-threshold).

## Phase 1: build

- [x] T020 (2026-11-09, offline, Claude; not compiled in Max) [US1] `src/f_vf_erode/codebox_blur.gen`: one separable 15-tap pass at fixed offsets -7..7, tent weights set by the radius (plan ADR-2), direction and radius as Params, nearest taps by index, border clamp, non-finite taps zapped (the mirror zaps before any blur). Follow `skills/jit-gen-codebox/SKILL.md`.
- [x] T021 (2026-11-09, offline, Claude; not compiled in Max; two files, `codebox_thresh.gen` and `codebox_pool.gen`) [US1] [US3] [US4] `src/f_vf_erode/codebox_fx_a.gen`: re-threshold with `snap`, `bias` and `soften`, then edge pooling in its own stage after the pool blur (plan ADR-3, corrected), exact identity at zero amounts.
- [x] T022 (2026-11-09, offline, Claude; not compiled in Max) [US2] [US3] `src/f_vf_erode/codebox_fx_b.gen`: mottle, tooth and dropout, `bypass_gate` (plan ADR-4, ADR-6), alpha pass-through.
- [x] T023 (2026-11-09, offline, Claude: built, JSON loads, contract test 9/9, log `tests/logs/20261109-073307-offline.log`; drift 16/16, log `tests/logs/20261109-074041-offline.log`) `src/f_vf_erode/definition.py`: `pix_chain` with the stages (eight, see Record) and `pix_wires`, `render_dim`, the P1 dials, `bypass` as `bypass_gate`; then `build/py.sh build/build_patcher.py`, drift check, JSON validate, `tests/contracts/test_module_contracts.py` (offline only).
- [x] T024 (2026-11-09, bench run by Claude; logs in Record; T009's cost is only an upper bound) `tests/modules/vf_erode/bench_vf_erode.py` and `bench_vf_erode_module.py` (read `skills/bench-test-authoring` first). Written offline; run only with Matt's go, `-q`. First bench item: `sample()` interpolation (T008) and blur-stage cost (T009).
- [ ] T025 [US5] `fx_b` additions: flecks and banding (P2 stories).
- [ ] T026 [US6] Channel gains in `fx_b`; the in1 amount driver and its connected flag (`src_amt`); definition and mirror updates.
- [ ] T027 [US6] `src/f_vf_erode/codebox_dir.gen`: directional spread along the in2 vecfield (`src_dir`), mirror and bench.

## Phase 2: tuning (Matt)

- [ ] T030 Live look: `f_stipple`, `f_tf_hatch`, `f_wave_field` or `f_ks` through f_vf_erode; does it read as ink on paper? Mottle, dropout and edge pooling especially.
- [ ] T031 Live look: one deliberately bent use (per-channel gains, a field-driven spread); check linear-light (T011).
- [ ] T032 Dial ranges, defaults, the `spread` cap, the octave weights; back into the codebox and `definition.py`, then re-run tiers 1 and 2.

### Rework from the first look (2026-11-09; spec FR-005, 006, 007, 017; plan ADR-8)

- [x] T033 (2026-11-09, offline, Claude) Mirror and tier 1: edge pool thins the body (candidate C), two more blur passes; the old flat-field and rim-above-1 tests rewritten to the reversed FR-007.
- [x] T034 (2026-11-09, offline, Claude) Mirror and tier 1: mottle thins only, dropout with soft edges, both taking a field; built-in fallbacks (mottle C, dropout B).
- [x] T035 (2026-11-09, Claude) `codebox_pool.gen` and the cascade stages; `definition.py` (ten stages).
- [x] T036 (2026-11-09, Claude) `codebox_fx_b.gen`: the new mottle and dropout, in1/in2 fields through `mod_inlets` with `src_mottle`, `src_tooth`; dial mapping; build, contract and drift.
- [x] T037 (2026-11-09, bench run by Claude; T009's cost still only an upper bound) Benches updated (four-input `fx_b`, field inlets connected and not, cost of the extra stages); run with Matt's go.
- [ ] T038 Live look (Matt): edge pool, mottle and dropout, with and without a patched field. Then spread, snap and bias, which are "fairly subtle" (Matt, set aside for later).

### Narrowed: vecfield-driven ink (2026-11-09; spec "Narrowed", plan ADR-9)

- [x] T050 (2026-11-09, offline, Claude) Mirror and tier 1 rewritten for extent and bulge.
- [x] T051 (2026-11-09, Claude) `codebox_bulge.gen`, `codebox_extent.gen`, `definition.py` (three stages, one vecfield inlet); old stages removed.
- [x] T052 (2026-11-09, bench run by Claude; cost only an upper bound) Benches rewritten and run.
- T053, T054: lapsed 2026-11-10 with the spec rewrite; never run.
- T006-T014 (PRELIMINARY gates), T025-T027 (P2), T030-T032, T038: of the earlier design, not carried over except as listed in spec "Narrowed".

### Rewrite: erosion model (2026-11-10; spec rewritten the same day; plan not yet)

Every unticked gate here is PRELIMINARY: Claude's assumption in spec "Assumed by Claude", for Matt to confirm or reverse (`G-ink-direction`). T060, T061 and T065 were settled 2026-11-10 (Matt); T075 2026-11-10 too; T074 2026-11-10 too, T062-T064 the same day; T066-T071 were confirmed 2026-11-10 too ("confirm all"); the build waits on the plan rewrite (T072).

- [x] T060 [GATE P1] (2026-11-10, Matt, chat) Polarity: a control, Darker or Lighter. "we want to be able to choose here"; no layers concept, background means no light, so in3 is the background. How each setting renders is spec P1, PRELIMINARY (T075).
- [x] T061 [GATE P2] (2026-11-10, Matt, chat: "sounds good") Wet once on a press or trigger, as written. Its two open parts are T074.
- [x] T062 [GATE P3] (2026-11-10, Matt, chat: "confirm all three") Inlets: picture, terrain, vecfield, background.
- [x] T063 [GATE P4] (2026-11-10, Matt, same) Behaviour with nothing connected.
- [x] T064 [GATE P5] (2026-11-10, Matt, same) One water layer for the three channels.
- [x] T065 [GATE P6] (2026-11-10, Matt, chat) Render size "if at all possible". The 1080p cost is measured at build (NF-102); a fixed solver grid only if that cost rules render size out, and that call is Matt's.
- [x] T066 [GATE P7] (2026-11-10, Matt, chat: "confirm all") Frame edge: water leaves at the edge (proposal), or a wall.
- [x] T067 [GATE P8] (2026-11-10, Matt, chat: "confirm all") Flow model: no momentum of its own (proposal).
- [x] T068 [GATE P9] (2026-11-10, Matt, chat: "confirm all") Linear light (`G-linear-light`).
- [x] T069 [GATE P10] (2026-11-10, Matt, chat: "confirm all") What the thickness outlet carries; a water outlet or not.
- [x] T070 [GATE P11] (2026-11-10, Matt, chat: "confirm all") Dial set and names (`G-ui-density`, `G-menu`).
- [x] T071 [GATE P12] (2026-11-10, Matt, chat: "confirm all") Verification tiers.
- [x] T074 [GATE P2] (2026-11-10, Matt, chat: "Confirm T074") What a moving in0 does between wettings (proposal: nothing; the wash holds until the next wetting), and always-wet (proposal: not in this version; US5 stays a later mode).
- [x] T075 [GATE P1] (2026-11-10, Matt, chat: "Confirm T075") How each Polarity setting renders (spec Decided, "Polarity render"): Darker filters a background that is white when in3 is unconnected; Lighter adds over a background that is black; default Darker; a switch takes effect at the next wetting.
- [x] T072 (2026-11-10, offline by Claude) Rewrite `plan.md` for this spec: done; the design is inferred until T073 and the bench.
- [x] T076 [GATE ADR-5] (2026-11-10, Matt, chat: "2> confirm"; proposed by Claude): before the first wetting `enc` shows the picture as if loaded (so US3.4 holds); after it, in0 no longer reaches the layers. A moving in0 is therefore visible until the first press.
- [x] T077 (2026-11-10, Matt, chat: "i'd like to rename the module", then "Yes, rename") Renamed `f_ink` to `f_vf_erode` (offline, Claude): `.specify/`, `src/`, `tests/modules/vf_erode/`, `package/patchers/f_vf_erode.maxpat` (rebuilt from the definition; prefix `vferode`, title `Erode`), bench dependency and contract tables, and the other print-styles specs and ideas. `HANDOFF_ARCHIVE.md`, dated logs and Matt's demo patches were not rewritten. Tests not run. Still a build of the 2026-11-09 design under the new name.
- 2026-11-10 (Matt, chat): "2> confirm" (T076) and "Yes, rename" (T077). (Offline, Claude): plan ADR-5 and the spec now carry the before-first-wetting behaviour as decided; the module is `f_vf_erode`; earlier Record lines above keep the name `f_ink` where they were written. Nothing built beyond the patcher regeneration; nothing run.
