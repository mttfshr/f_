# Tasks: f_tf_glyph

**Spec**: `.specify/f_tf_glyph/spec.md`
**Plan**: `.specify/f_tf_glyph/plan.md`
**Triage**: `ideas/f_tf_triage.md` (build order 2 of 6; decode decision and review outcome recorded there)
**Brief**: `ideas/f_tf_build_brief.md` (§4 catalog entry, §5 ranked chains)
**Build order**: Sequential by phase. Phases 0 and 1 are BLOCKING.
**Commits**: After each phase checkpoint.
**Test discipline** (ways-of-working): run the one affected test, `-q`, in the background with `tests/bg.sh`; never rerun the bench to re-verify your own change; **ask before any bench run**. Tier-1 (NumPy) runs are cheap and need no ask.

---

## Expected Output Layout

```
.specify/f_tf_glyph/
  spec.md  plan.md  tasks.md      — done
  REGISTRATION_NOTES.md           — Phase 5 parent lines

src/f_tf_glyph/                   — as-built 2026-10-17 (parent normalization:
                                    src/<name>/ is the shipped-module layout,
                                    tensormap/axisflow precedent)
  codebox_glyph.gen               — Phase 1
  definition.py                   — Phase 3

tests/
  test_tf_glyph.py                — Phase 0, tier-1 mirror
  bench_tf_glyph.py               — Phase 1, tier-2

~/Vsynth/patterns/tf_glyph_scratch.maxpat   — Phase 2 (not committed)

docs/f-reference/f_tf_glyph.md   — Phase 5
```

Family context: tensormap is built and shipped (`.specify/f_tf_tensormap/`, docs at
`docs/f-reference/f_tf_tensormap.md` + `f_tensor_type.md`); smooth's triad is authored
in parallel — its plan cross-references THIS file's decode idiom (plan ADR-2), so
ADR-2's text must be final by the end of Phase 0 (TG003).

---

## Phase 0: Gates + tier-1 NumPy mirror (BLOCKING)

**Purpose:** Settle decode + lattice + draw math against independent ground truth
(`np.linalg.eigh`) before any codebox exists; finalize the canonical decode idiom
the rest of the family will copy.

⚠️ Do not begin Phase 1 until this checkpoint is confirmed.

- [x] TG001 **DECISION GATE: verification tiers (constitution).** CONFIRMED as written (build-mode note: the bench cost gate resolves provisionally against the tensormap floor ~0.9 ms/pass at 1080p R_MAX 16; gate PROVISIONAL-OPEN in the codebox + ADR-5 comment) Recorded in plan.md ADR-9: **tier 1 applies** (decode has independent ground truth — `np.linalg.eigh` on decoded 2×2 tensors; analytic ramps give known θ/aspect; the lattice is exactly mirrorable), **tier 2 applies** (one real codebox to compile; clamp-at-texel-centre behavior for cell-centre taps re-confirmed; cost recorded), **tier 3 applies** (glyph look, variant menu, tint behavior, all defaults — judgement). Confirm or amend; nothing skipped.
- [x] TG002 **DECISION GATE (cited, confirm only): decode architecture.** CONFIRMED cited Per-consumer in-pixel decode, no `f_tf_decode` module, name retired (`f_tf_triage.md`, review 2026-10-17, Matt). Precedent: `jit.fx.cf.kuwahara` decodes eigenvalues/coherence/angle in its main pass every frame (source-read; `ideas/f_tf_jitfx_audit.md` §2.1, §4.4). Nothing to decide — task exists so the idiom's custodian is explicit: **this module's plan owns it** (plan ADR-2).
- [x] TG003 **Finalize plan ADR-2's canonical decode idiom text** FINAL (copied verbatim into codebox_glyph.gen + docs/f-reference/f_tf_glyph.md; gain-free identities + theta+180 caveat + axisflow pointer present) (decode block + gain-free identities + θ+180° symmetry caveat + axisflow pointer). Cite `docs/f-reference/f_tensor_type.md` outlet 0 encoding verbatim; never re-derive numbers already in it. Exit: the ADR-2 block is the single citable text; smooth/sharpen/aniso_blur/hatch plans reference it by path later.
- [x] TG004 **DECISION GATE: plan ADR-4 (lattice) and ADR-5 (gain-free radius).** CONFIRMED (jitter-free floor-divide lattice; ratio-only aspect, radius = scale*cellsize/2, no strength echo param; mirror written against exactly this contract). Confirm jitter-free lattice (no loops anywhere; `f_vf_seeds.md` Q4 3×3 search stays a v2 mechanism if jitter is ever wanted) and ratio-only aspect with `scale`-driven radius (no `strength` echo param). Both were pre-decided at planning; the gate exists so tier-1 mirror values are written against a confirmed contract. Amend here (not silently in code) if the mirror work argues otherwise.
- [x] TG005 Create `tests/test_tf_glyph.py` — created, samples every texture read through gpu_sim.sample/g.nearest, outlet-0-format fixtures — mirror of the ADR-2 decode on synthetic outlet-0-format textures (`Jxx*strength`, `Jxy*strength*0.5+0.5`, `Jyy*strength`, A=1) over the exact ADR-4 lattice; sample through `gpu_sim.sample`/`nearest`, not array slicing (tests/README convention).
- [x] TG006 Ground truth, eigen: measured worst errors lambda1 1.19e-07, lambda2 1.19e-07, theta 2.38e-07 rad (random SPD field, sampled at the same cell centres the mirror reads; includes diag-only, repeated-eigenvalue, near-zero-l2, zero-tensor cases). 2026-10-17. Original gate text: on random symmetric 2×2 tensors (diagonal-only, repeated-eigenvalue, near-zero-λ2 cases included), the in-pixel decode's λ1/λ2/θ match `np.linalg.eigh` (θ mod pi). Print measured errors via `harness.check`.
- [x] TG007 Ground truth, direction & aspect: ramp phi in {0,0.3,1.1,2.0,2.9} — mirror theta == phi mod pi to 1e-5; drawn ring major axis == phi+pi/2 within 0.15 rad (PCA on rendered mask); ratio 4 -> aspect 2 (sqrt per ADR-5); max_aspect clamps at 1.5 and 8; gain-free identity x10 exact (render delta 0.0); **all-zeros unconnected-wire case** renders EMPTY (trace exactly 0 below gate; also empty at gate 0 via the eps_trace 1e-6 floor). 2026-10-17. NOTE for Matt: the spec acceptance criterion "eigenvalue ratio 4 gives measured ellipse aspect 4" conflicts with plan ADR-5's explicit aspect = clamp(sqrt(ratio),...) — the build follows ADR-5 (ratio 4 measures as 2); arbitrate in the spec.
  Original gate text: analytic ramps at known angles phi give glyph major axis at phi+pi/2 (along-edge convention, explicitly stated); eigenvalue ratio 4 gives measured aspect 4; `max_aspect` clamping verified; gain-free identity holds — axis and aspect unchanged (≤ ~1e-6 relative) when `strength` varies ×10; **all-zeros unconnected-wire case** (coordination 2026-10-17, AnisoBlurTriad): the texture (0,0,0,0) through the outlet-0 decode gives Jxy·s = −1 → λ1 = 1, λ2 = −1, non-SPD, with a plausible-looking atan2 orientation — assert the mirrored field still renders empty because decode trace = 0 falls below `gate` (glyph is incidentally safe via the trace gate; energy-gated consumers like f_tf_aniso_blur need an explicit SPD guard — see note in plan ADR-6).
- [x] TG008 Gate and invariants — huge gate kills all marks (exact 0); default gate draws; isotropic traceable cell draws aspect exactly 1; rot180 invariance exact (delta 0.0); cover reference values (1 in band, 0 past falloff, 0.5 mid). 2026-10-17. from the spec's acceptance criteria: cells below `gate` draw nothing; zero tensor renders an empty field; isotropic-but-traceable cells (λ1≈λ2, trace ≥ gate) draw aspect-1; rotating the tensor by pi leaves the rendered field identical; line-field (unoriented) invariance; ellipse cover function matches the smoothstep reference values on/off the curve.
- [x] TG009 Mutation-check once — dropped 0.5 offset on G: good worst angle err 0.0, mutated 1.24e-1 rad, ramp-angle check fails as required. 2026-10-17. (tests/README): inject a plausible bug (forget the 0.5-offset decode on G; use lambda1 instead of the ratio for aspect; drop the `+0.5` in the cell-centre formula) and confirm a test fails.
- [x] TG010 Run `tests/run.sh tests/test_tf_glyph.py -q` **Result 2026-10-17: 14/14 pass.** Measured: eigh lambda1/lambda2 worst 1.19e-07, theta 2.38e-07 rad; gain x10 render delta 0; rot180 delta 0; cover mid-falloff 0.5; per-cell centroid offset 0; mutation caught (good 0.0 vs mutated 1.24e-1 rad).

**Checkpoint:** Mirror agrees with `np.linalg.eigh`, the known-angle ramp, the aspect/`max_aspect` numbers, and the gain-free identity; one injected bug caught; ADR-2 idiom final. → Proceed to Phase 1.

---

## Phase 1: Codebox on the bench (BLOCKING)

**Purpose:** One real codebox, diffed against the mirror on the GPU. Borders and
clamp behavior re-confirmed for cell-centre sampling; cost recorded.

⚠️ Do not begin Phase 2 until this checkpoint is confirmed. Ask before any bench run.

- [x] TG011 *[written 2026-10-17]* Write `codebox_glyph.gen` — WRITTEN: `.specify/f_tf_glyph/codebox_glyph.gen`, 84 statements (far under the 450/250 ceilings); ADR-2 decode verbatim with citation + caveat; ADR-4 lattice (floor-divide); cell taps clamped to texel centres; ADR-6 gate with eps_trace floor; closed-form ellipse ring (no loops); ellipse-only v1 + no debug-tint recorded as v1 resolution with gates PROVISIONAL-OPEN in comments (ADR-8); all six defaults provisional per TG020; `Param glyph_scale` (scale() collision avoided).: ADR-2 decode + ADR-4 lattice + ADR-5 aspect/radius + ADR-6 gate + ADR-8 ellipse distance + source tint tap, per plan ADR-1 (single stage). Clamp cell-centre sample coords to texel centres in-shader (tensomap ADR-5; the bench GPU wraps out-of-range reads). Final stage only — clamp/encode nothing upstream because there is no upstream. Params: `grid`, `scale`, `thickness`, `softness`, `gate`, `max_aspect`, `bypass`. Statement budget must land WELL under ~450 (`skills/jit-gen-codebox`); this design should be near-trivial to compile.
- [x] TG012 *[BENCHED 2026-10-17, COMPLETE after root-cause + fixes: 6/6 pass, re-confirmed in
  the final 5-file sweep. Three live GPU findings (full write-up in plan ADR-2 amendment,
  family-consumer-rule 6): (1) runtime atan2(0,0) = NaN on this GPU - constant-isotropic
  content rendered all-black; fixed with a +1e-7 atan2-denominator bias (codebox + mirror);
  (2) sample() drops to nearest on data-dependent jumping coords - the cell read was pure
  texel where the mirror bilinear-blended (0.98 worst diff); fixed with the skill's
  four-tap nearest() hand-bilinear idiom on both the tensor read and the tint read;
  (3) residual 2.3e-4 at the 64x97 grid-7 extreme = the documented 8-bit interpolation-
  weight ceiling; bench TOL 1.5e-4. The 'bench input path resamples' hypothesis is RETIRED:
  the passthrough probe sample(in1, norm) matched the mirror exactly at 97x64 - the input
  path is 1:1; the divergence was (1)+(2).]* Bench `codebox_glyph.gen` against the mirror
  channel-by-channel (`all_outputs=True`), including border cells where the lattice touches
  frame edges (the clamp makes border cell centres exact — verify, don't argue). Bypass and
  unconnected-tensor behaviors per the spec.
- [x] TG013 Cost measurement *[BENCHED 2026-10-17: 1080p ≈ 2.39 ms/pass and 4k ≈ 6.96 ms/pass,
  both UPPER BOUNDS (bench frame floor at chain 1; not GPU-bound — tensormap's T016
  convention). Real GPU cost is at or below these; the ADR-5 gain-free-radius gate has its
  resolving numbers.]* Cost measurement (`bc.measure`, `tests/bench_perf.py` precedent): per-pass at 1080p and 4K. Expected trivially cheap (one tensor tap + one source tap + closed-form math); record the numbers anyway — the family's cost ledger gets one line per module.
- [x] TG014 Assemble `tests/bench_tf_glyph.py` — written from the template pattern (mirrors bench_tf_tensormap.py); registration line for tests/benchdeps.DATA recorded in .specify/f_tf_glyph/REGISTRATION_NOTES.md (shared file, parent-owned); NOT in bench.sh DEFAULT. NOT RUN. from `tests/templates/bench_module_template.py`; register in `tests/benchdeps.DATA` (a test enforces this). Do **not** add to `bench.sh DEFAULT` until Matt says regression gate.

**Checkpoint:** Codebox compiles comfortably under budget, matches its mirror on the GPU, borders exact, cost recorded. → Proceed to Phase 2.

---

## Phase 2: Scratch patch, judgement tier

**Purpose:** The things numbers can't judge: variant look, tint behavior, and every
provisional default.

- [ ] TG015 [Phase 2 pending Matt/bench — out of scope for this build pass] Build `~/Vsynth/patterns/tf_glyph_scratch.maxpat` via a re-runnable build script (tensormap T022 precedent: reads the real codebox, structure-checked): `jit.gl.bfg → f_tf_tensormap → f_tf_glyph` with preview taps.
- [ ] TG016 **DECISION GATE (spec OQ1): variant menu.** Flip the ADR-8 compile-time variant constant across ellipse/cross/tick in the scratch builds; judge which (if any) earn a live param against the UI-density context (`mod_depth_ui_density.md` paused). Default expectation: ship ellipse only. Record the decision in spec Clarifications; keep the un-shipped variants as scratch-only.
- [ ] TG017 **DECISION GATE (spec OQ3): gain-free vs absolute-λ radius.** On live content, confirm the gain-free path reads right when tensormap `strength` is swept — glyphs must NOT change. If size-meaning proves important, record the absolute-λ fallback design here; do not silently change ADR-5.
- [ ] TG018 **DECISION GATE (spec OQ2): debug-view modes.** Decide whether axis-only tint / coherence tint are shipping modes, scratch-only previews, or nothing. The debug ROLE (family sidecar) is settled; the modes are optional.
- [ ] TG019 **(spec OQ4)** Decide inlet-1 tint behavior (luma vs color vs brightness-only) and the unconnected-source neutral; confirm geometry never depends on the source inlet.
- [ ] TG020 **DECISION GATE: lock all defaults.** `grid` (2-256, provisional 24), `scale` (0.8), `thickness` (0.15), `softness` (0.1), `gate` (0.05), `max_aspect` (8) — judge on bfg Perlin/Voronoi/fbm, update spec.md Parameters with confirmed values, close OQ3/OQ4 with reasoning where they intersect.
- [ ] TG021 Debug-sidecar check: with the smooth/sharpen scratch builds available (sibling triads), confirm the glyph field stays legible as a tap behind them — the validation the triage promised. If siblings aren't ready, mark deferred, not failed; the claim waits for the sibling phases.

**Checkpoint:** Variant/tint/debug-mode questions decided or explicitly deferred
with reasons; all defaults confirmed on real content; spec's provisional values
replaced. → Proceed to Phase 3.

---

## Phase 3: definition.py and build

**Purpose:** Assemble the confirmed codebox into a real module bpatcher.

- [x] TG022 **Read, don't assume:** f_tf_tensormap + f_vf_optical_flow + f_lens definition.py read BEFORE writing (2026-10-17). Structural difference recorded: single-stage single-pix module with `driving_inlet` (tensor rides outer inlet 0 with control; source tint on outer inlet 1 via mod_inlets[1]) vs tensormap's four-stage fan; params go straight to the pix (no pix_target fan needed); bypass_mode "param" -> prepend param bypass_gate -> the pix. `.specify/f_tf_tensormap/definition.py` for the family's param/routing/bypass conventions (tensormap T028/T031 precedents: fan-out, `bypass_mode "param"`, neutral handling) and how the two-texture inlet routing (tensor + source) is expressed. Record the one structural difference: two texture branches into one stage (tensormap fans one texture across four stages).
- [x] TG023 **DECISION GATE: inlet order + `signal_type` tags.** DECIDED per plan ADR-7 (in0 = tensor, in1 = source); header `signal_type` "tensor in" — colour is keyed on the first word in build_patcher.py:209-214, so the amber `tensor` colour from tensormap T030 applies verbatim; nothing new invented. Built and verified in the generated JSON. Plan ADR-7 fixes in0 = tensor / in1 = source. Confirm the header `signal_type`/outlet hint wording so the tensor-input requirement is visible at connection time (tensormap T030 added the amber `tensor` colour — reuse it on THIS module's inlet hint, don't invent a new one). Blocks definition.py only.
- [x] TG024 Write `.specify/f_tf_glyph/definition.py` (build-path note: written in the module folder per the build directive, matching the Expected Output Layout, NOT src/ — moved if Matt disagrees; REGISTRATION_NOTES.md records the exact relocation command). Single-pix, driving_inlet True, mod_inlets[1] = tint source, all six Phase-0-locked-provisional param values with PROVISIONAL (TG020) hints, bypass = param (bypass_gate passthrough). Param named `glyph_scale` on the wire to avoid the codebox scale() collision (rename per skills/jit-gen-codebox: UI label stays "Scale"). single-stage pix, `driving_inlet` on tensor + source branch, params per the Phase-2-locked values (with tensormap's `exponent` convention where a log dial helped — none expected here), `Param bypass` neutral.
- [x] TG025 Run `python3 build/build_patcher.py .specify/f_tf_glyph/definition.py` -> `Written: package/patchers/f_tf_glyph.maxpat` -> `json.load` VALID. Verified in the built JSON: 1 pix (glyph_pix) with 2 gen inlets (in 1, in 2), route tokens `grid glyph_scale thickness softness gate max_aspect`, 6 prepend-param wires + bypass_gate prepend, both vs_inState texture inlets wired (routepass -> pix in0; mod inlet 1 -> pix in1).
- [ ] TG026 Register in the modules menu [PENDING parent registration — exact line in REGISTRATION_NOTES.md]: src/f_modules/menu.py -> build/generate_menu.py; README row (⚠ Unverified). (`src/f_modules/menu.py` → build/generate_menu.py pathway, per tensormap T033's finding that `tools/` scripts no longer exist); README row (⚠ Unverified).
- [ ] TG027 Drift check [PENDING — parent-owned shared test]: tests/test_drift.py once menu registration lands. (`tests/test_drift.py`): the patcher reproduces from definition.py with no baseline additions.
- [ ] TG028 Contract tests [PENDING bench + parent shared files]: offline contract check needs menu registration first; bench_modules BYPASS_EXPECT entry recorded in REGISTRATION_NOTES.md (glyph bypass is PASSTHROUGH-BY-DESIGN, not neutral — needs the non-neutral entry like f_vf_seeds).: offline `tests/test_module_contracts.py`; add to `tests/bench_modules.py`'s `BYPASS_EXPECT` (neutral at bypass); run in background; **ask before the bench run**.
- [ ] TG029 Close and reopen in Max [PENDING Matt live session].; live load in a Vsynth session: panel visible, params addressable, bypass and unconnected-tensor give the neutral/empty, glyphs render.

**Checkpoint:** Patcher loads, drift-clean, contract tests green. → Proceed to Phase 4.

---

## Phase 4: Integration check — the canonical consumer chain

**Purpose:** Prove producer→consumer end to end and pin the reference wiring for
every later consumer plan.

- [ ] TG030 [Phase 4 pending Matt live] Wire the canonical demo chain `jit.gl.bfg → f_tf_tensormap → f_tf_glyph` live; this is the wiring that gets captured in the docs and cited by sharpen/aniso_blur/hatch plans as the consumer idiom's proof.
- [ ] TG031 Rotate the input 90°; confirm glyph rotation follows (mod 180° — the line-field property). Mirror-flip a component and confirm the glyph aspect responds per the tensor, not the pixels.
- [ ] TG032 Sweep tensormap `strength` across its range with glyphs live; confirm ZERO change in glyph geometry (plan ADR-5's gain-free contract — the strongest single assertion this module makes about the family).
- [ ] TG033 Feed `f_tf_smooth`/`f_tf_sharpen` outputs in when siblings ship (scratch or shipped): glyph view remains legible; isotropic-push under sharpen shows circles/no-marks per ADR-6. Deferred without siblings, per TG021's rule.

**Checkpoint:** The producer→consumer path is live-confirmed; reference wiring established. → Proceed to Phase 5.

---

## Phase 5: Docs and handoff

- [x] TG034 Write `docs/f-reference/f_tf_glyph.md` — written 2026-10-17: param table (all defaults marked PROVISIONAL per TG020), inlet contract (outlet-0-exact + the "what if outlet 1" line), canonical demo chain, ADR-5 gain-free statement, ADR-6 gate semantics incl. the all-zeros unconnected case, cost section with the PROVISIONAL-OPEN bench gate, Status: Draft header per the build directive.: param table, the inlet contract
  (outlet-0-exact, plan ADR-3 — and what happens if someone wires outlet 1 by
  mistake), the canonical demo chain, ADR-5's gain-free statement (glyphs are
  strength-blind by design), ADR-6's gate semantics.
- [x] TG035 Restate or cite the canonical decode idiom — the ADR-2 block is reproduced verbatim in the reference doc under "The decode idiom" with the cite-verbatim instruction for sharpen/aniso_blur/hatch (no re-derivation, no extra atan2). (plan ADR-2) in the reference
  doc as THE citation target for later consumer plans (sharpen, aniso_blur, hatch).
- [ ] TG036 Helpfile [PENDING — needs live module + parent helpfile pipeline] the `f-helpfile` skill, then the `skills/module-preflight/`
  checklist incl. its **content judgment gate**.
- [ ] TG037 [PENDING parent shared files — exact README row in REGISTRATION_NOTES.md] Update `README.md` (status table, build queue), `docs/f-reference/module-inventory.md`,
  and the constitution (Current Bpatchers; naming table already has `f_tf_` from tensormap T042 — extend entry only if glyph introduced something new, else leave).
- [ ] TG038 [PENDING parent shared files] Update `ideas/f_tf_triage.md` (glyph = built) and `ideas/f_tf_build_brief.md`
  §4/§5 cross-links so the build order shows the second slot filled; note in the
  brief that the decode idiom now has a citation target.
- [ ] TG039 [PENDING parent shared files] Update `HANDOFF.md` (short; detail lives here).
- [ ] TG040 Commit [PARENT — no git commands from this agent]. Suggested split: spec/plan/tasks; tests + codebox; patcher + registration; docs. Plain message style per repo history.

**Checkpoint:** Docs written, README updated, git clean.

---

## Dependencies & Execution Order

- Phase 0 → 1 → 2 → 3 → 4 → 5, strictly sequential (bench time is scarce; the
  mirror must exist before the codebox).
- **TG003 blocks everything downstream** — the idiom text is the deliverable other
  sibling plans cite; it must be final before Phase 1 code comments copy it.
- **TG004 (lattice/radius gates) blocks TG005** (mirror values are written against
  the confirmed contract).
- TG016–TG020 (Phase 2 gates) block TG023/TG024 (locked values go into definition.py).
- TG022 blocks TG024 (family precedents read before writing).
- No parallel work inside this folder: each phase's output is the next phase's input.
  Sibling-module parallelism (smooth/sharpen/aniso_blur/hatch triads) is at the
  planning level only; their Phase 1+ work follows this module so the idiom is
  already final.

## Notes

- **No loops, anywhere.** The design has zero iterative constructs (plan ADR-4);
  if a code change ever introduces one, that's a design regression, not a
  optimization question.
- The decode idiom (plan ADR-2) is this module's principal export to the rest of
  the family; guard its text like an API.
- Internal stage output is unbounded float32; the single stage clamps/encodes at
  the outlet (family hard rule — trivially satisfied here by there being only one
  stage).
- `f_tf_mix` is not in this task list (chain B, spec'd later, per triage).
- Hard constraint: no script in this task list calls the Anthropic API.
- Total tasks: 40