# HANDOFF

## 2026-10-17 (night, later): f_caustic `edge` mode — UNCOMMITTED (on top of the Axis Flow entry below)

- **Built:** `f_caustic` has an `Edge` menu: Off (default, unchanged) / Wrap / Mirror / Clamp. Remap of the landing position
  in the vertex shader (`package/code/f_caustic_sheets.jxs`, uniform `edge`), driven like `scale`: new `edge` token in the
  scene's control entry (`scatter_scene.py` `BASE_TOKENS`, `prepend param edge`), tapped at the builder's menu outlet
  (`MENU_EDGE = "obj-32"`, guarded by `test_scatter_scene.py`). Definition param `edge` (`pix_wire: False`); raw layer,
  standalone bench patch and `f_caustic.maxpat` regenerated. Clamp is inset half a pixel (on the border half the tent falls
  off-frame and it would still lose light). Wrap/Mirror splats straddling the frame edge still lose their off-frame half
  (~0.3% in the tests).
- **Run:** `tests/run.sh -q tests/test_scatter_mirror.py` 10/10 (3 new: hand-tabulated remap, light kept/lost, where it goes)
  and `tests/test_scatter_scene.py` 5/5 (1 new). **Not run:** the bench (`test_T040_*` written; the first one sends modes
  1,2,3,0 because the bench keeps Params between jobs; tolerance 2e-3 is a guess), the full offline suite,
  `drift.py -v f_caustic`, anything in Max.
- **Helpfile** (`package/help/f_caustic.maxhelp`) not updated. Docs: `docs/f-reference/f_caustic.md` (param row, algorithm
  line, History); tasks: `.specify/f_caustic_scatter/tasks.md` E01-E08.
- **Still proposed, not approved:** optional `f_vf_fluid` `drift` Param scaling the k=0 (mean-flow) bin.
- Uncommitted from this step: `package/code/f_caustic_sheets.jxs`, `src/f_caustic/{definition.py,scatter_scene.py,raw_ui.json}`,
  `package/patchers/f_caustic.maxpat`, `tests/bench/caustic_sheets_standalone.maxpat`,
  `tests/{scatter_mirror,test_scatter_mirror,test_scatter_scene,bench_caustic_sheets}.py`, `docs/f-reference/f_caustic.md`,
  `.specify/f_caustic_scatter/tasks.md`, `HANDOFF.md`.

## 2026-10-17 (night): Axis Flow signed gain + per-pixel reference inlet — UNCOMMITTED

- The evening stack below is now committed as `edaa18a` (99 files). Left out on purpose and still uncommitted:
  `package/examples/f_demo_sampleplatter.maxpat` and `scratch/tensor-scratch.maxpat`. The "UNCOMMITTED / HEAD is
  `b3b53cc`" paragraph under the next heading is stale.
- **Why:** Matt ran cam → Map → Smooth → Axis Flow → Fluid → Caustic live. Flow felt one-sided; Caustic `scale` sent
  pixels out of frame. Cause is compound: Axis Flow's output always has a component along `angle` (mean 0.5 x gain
  over random edges; at Gate 0 every faint gradient gets full flow), `f_vf_fluid` adds the force in physical space
  and its k=0 (mean) bin is skipped by the projection and damped only by `drag` (about 127 frames' worth of a steady
  push at drag 0.79, dt 0.01), and Caustic's forward scatter clips whatever lands outside the frame.
- **Built (Matt approved the design):** `f_tf_axisflow` `gain` is signed (-4..4, default 1); new optional second
  inlet = per-pixel reference vecfield (unnormalized, so |r| scales the flow; `angle` rotates it; B-gate absent test
  falls back to the dial; aspect-converted to pixel space). Codebox `in2`, definition `mod_inlets`, mirror
  `axisflow(ref=...)`, patcher rebuilt (pix has 2 inlets; `lens_toggle.js` restored). Docs + tasks T020-T027 written.
  Label left as `T_ in ∇ out`.
- **Run:** `tests/run.sh -q tests/test_tf_axisflow.py` 24/24 (was 16). **Not run:** the bench (4 new cases written in
  `tests/bench_tf_axisflow.py`, ask first), the full offline suite, anything in Max.
- **Helpfile:** only the `gain` range was corrected; text for the new inlet is not written.
- **Proposed, not approved to build:** `f_caustic` `edge` menu (off / wrap / mirror / clamp, vertex shader; default off)
  and an optional `f_vf_fluid` `drift` Param scaling the k=0 bin (1 = today).
- Uncommitted from this step: `src/f_tf_axisflow/{codebox_axisflow.gen,definition.py}`, `package/patchers/f_tf_axisflow.maxpat`,
  `package/help/f_tf_axisflow.maxhelp`, `docs/f-reference/f_tf_axisflow.md`, `.specify/f_tf_axisflow/tasks.md`,
  `tests/{test,bench}_tf_axisflow.py`, `HANDOFF.md`.

## 2026-10-17 (evening): f_modules menu, title-bar labels, type dots, tensor sizing — committed in `edaa18a`

**State.** HEAD is `b3b53cc`; everything below is uncommitted (about 99 modified files plus new ones). A commit-all
would also sweep in two files that are not part of this work: `package/examples/f_demo_sampleplatter.maxpat`
(modified earlier, see the 10-12 notes) and `scratch/tensor-scratch.maxpat` (untracked, Matt's). `ideas/type_dots.js`
is new and mine (a parked script, below). Suggested split if committing in pieces: (1) menu + README + launcher,
(2) title-bar labels + titles + dots, (3) tensor module sizing + helpfile embeds, (4) audit fixes + tests + skill/docs.

**What exists now (all as built; Matt approved the look of labels, dots, and tensor sizing from screenshots)**
- **f_modules menu.** Order: Scope, Discrete, Spatial, Optical, **Color / Tone**, ∇ Generators, ∇ Processors,
  **T_ Tensor**, Utilities. The seven `f_tf_` modules moved out of Utilities into `T_ Tensor` (pipeline order, no
  "Tensor " prefix: Tensormap, Smooth, Sharpen, Aniso Blur, Hatch, Glyph, Axis Flow). `src/f_modules/menu.py`: each
  entry's third field is a tuple of kinds (`N`, `V`, `T`, `VT`) against a `MARKS` table (` ∇`, ` T_`), not a bool;
  a `T_` category may hold only tensor modules. README Patches table reordered to match, f_Launch regenerated (10
  tabs, 47 modules). Nine categories no longer fit the 380 px panel the 19 example patches embed it at, so the slot
  pitch is 39 px (`SLOT`, generate_menu.py) and a check fails if the menu outgrows `PANEL_H`.
- **Title-bar label** on every typed module: marks plus direction, no words: `∇ in`, `∇ out`, `∇ in/out`, `T_ in`,
  `T_ out`, `T_ in/out`, `T_ in ∇ out` (axisflow). 11 pt, right-justified in a 70 px box whose right edge is 4 px
  left of the bypass button, y 0.9 (same baseline as the 12 pt title); ∇ = advect's cyan `[0.35, 0.75, 0.95]`,
  `T_` = amber `[0.85, 0.55, 0.2]`. Rule in `signal_type_box` (build_patcher.py; follows a `bypass_jsui` override);
  the 11 per-module `signal_type` overrides were deleted. Titles lost "Tensor": "Sharpen", "Smooth", "Map".
- **Type dots** on every module (43): two stacked round 5 px panels left of the name, top = type it takes, bottom
  = type it outputs; cyan vecfield, amber tensor, dim grey `[0.28]` neither (untyped modules: two grey). Read from
  the label by `parse_signal_type`; tooltip "Takes: X" / "Outputs: Y". Foreground panels (`background` 0,
  `rounded` 6, ids `obj-19f` / `obj-19g`, element keys `dot_in` / `dot_out`): a `background` 1 panel is drawn UNDER
  the frame and vanishes. Every module name starts at x 10.5 (8 hand-placed title overrides updated: mobius, grain,
  tone_curve, vortex_multi, hue, channel_grader, stereo, luma). Frame border stays dark blue.
- **Tried and dropped** (do not redo without a reason): (a) frame border coloured by type (`BORDER_BY_TYPE = False`
  in build_patcher.py brings it back); (b) shaped dots, tensor round / vecfield square, then ONE jsui
  (`type_dots.js`) drawing triangle / disc / square: Matt, "reads as noisy, it was better with just circles". The
  jsui style is still in the builder (`TYPE_DOTS = "jsui"`) and the script is parked at `ideas/type_dots.js` (copy
  it to `package/javascript/` to use it). Last seen problems: Max gave the jsui a larger box than set (fixed with
  fixed geometry) and the disc looked shaved top-left (1 px margin added, effect never confirmed).
- **Tensor modules un-cropped**: `f_tf_glyph`, `f_tf_hatch` (190 x 150) and `f_tf_aniso_blur` (190 x 122) shipped
  on a 154 x 84 frame sized for tensormap and lost their right-hand dials and lower rows; now the library's 190 px,
  5-column panel with the bypass button at its default x (168). Menu `SIZES` regenerated; the three helpfile
  embeds widened to 190 (glyph's also 150 tall, boxes below it moved down 10 px).
- **In/out audit from the code** (read from the shipped patchers' embedded codeboxes, NOT from labels and NOT from
  `src/*/codebox_v*.gen`, which hold historical versions: prism 17, chroma 10): `f_vf_advect` and `f_vf_prism` each
  have a third outlet that is a vecfield, so both are `∇ in/out` (were `∇ in`). Everything else matched. Not typed:
  `f_vf_optical_flow`'s "confidence" outlet (determinant + doubled-angle axis, neither encoding), `f_vf_seeds`' "seed
  coord" (a coordinate grid), `f_vf_split` / `f_vf_potential` (scalar outputs), `f_texrouter` (type-agnostic),
  `f_mobius` / `droste` / `stereo` (resample a piped-through vecfield without interpreting it).
- **Colour vision** (Machado 2009 simulation, cyan / amber / dim grey on black): cyan vs amber differ by deltaE
  88-98 under protan, deutan and tritan; contrast vs black cyan >= 9.5:1, amber >= 6.8:1, grey 2.3:1 (dim by
  design). Weak spot only total colour blindness (cyan and amber have near-equal lightness). The dots are colour-only;
  the text label (mark + in/out) is the colour-independent cue.

**How it was applied (to redo or extend)**
- 37 modules regenerated with `python3 build/build_patcher.py src/f_<m>/definition.py` (every menu module except
  the six below, plus `f_vf_vorticity`). That rebuild always rewrites `package/javascript/lens_toggle.js`
  differently (the committed one lists the removed tilt-shift objects: stale, harmless); restore it with
  `git checkout -- package/javascript/lens_toggle.js`.
- Six patched IN PLACE, never regenerated: `f_vf_advect` (its definition lacks the `#0_` pix name, see below),
  `f_masonry`, `f_texrouter`, `f_util_matrix_2`, `f_util_profile` (hand-built, no definition), `f_sirds` (own build
  script `src/f_sirds/build_sirds.py`, mirrored by hand). masonry and texrouter pin their dots with
  `dot_in` / `dot_out` overrides in their definitions.
- `build/drift.py` gives the dots panels (ids obj-19f / 19g) their own identity ("type dot in/out") so they cannot
  hide the frame panel from the matcher (with two unlabelled extra panels the frame stopped being unique, which made
  the masonry / texrouter baselines look lowered; those two are at their real values: texrouter props 3 / layout 1,
  masonry layout 17; masonry props 22 stays, that shrink predates this work). `type_dots.js` keeps an identity for
  the jsui style. Three tests (test_build_conventions x3, test_layout) select the bypass jsui by filename.
- New tests in `tests/test_generate_menu.py` (15/15): label marks equal menu kinds; label geometry and colour; dots
  (colour, size, column, foreground, dark border); an outlet the module names vecfield / tensor must be a label
  output; tensor modules not cropped by frame or helpfile embed; direction table. Also green: conventions 40/40,
  layout 12/12, overrides 12/12, capture_raw 8/8, module_contracts 9/9.
- `skills/vsynth-bpatcher/SKILL.md` updated (entry format, kinds, labels, dots, audit rule); `skills/check.sh` will
  report drift against the last upload until it is re-uploaded and stamped.

**Never looked at in Max** (all of it built and tested offline): the regenerated `f_modules` menu itself (39 px
spacing, `T_ Tensor`, labels); the widened helpfile embeds; crowded title bars below.

**Waiting on Matt**
- **Crowded title bars** (rough width estimate): `f_vf_split` (80 px panel, "VF Split") and `f_vf_warp` (78 px) have
  the label text running into the name; `f_tf_axisflow` is touching. Widening split/warp to about 100 px (or
  dropping the text label there, or renaming "VF Split" to "Split") fixes it; widening changes the module's
  footprint in patches, so not done.
- **Content past the frame, not touched**: `f_vf_optical_flow` 13 px at the bottom (frame 190 x 130); `f_vf_warp` and
  `f_vf_split` label boxes 22-25 px past the right edge; 1.5-3.5 px of label-box slack on `f_grain` and
  `f_vf_fieldmap` (almost certainly fine). `f_mobius`: its first dial's box touches the lower dot by about 2 px.
- **Names**: the menu says "Tensormap", the module title says "Map". Helpfile headings and prose still say "Tensor
  Map", "Tensor Smooth", etc. (`build/make_tf_helpfiles.py`, `package/help/f_tf_*.maxhelp`); not touched.
- Utilities placement (now Tex Router, Profile, Split, Potential, Matrix 2) is still undecided.
- Whether and how to commit, and whether to leave out the two files that are not part of this work.

**Parked (Matt, 2026-10-17): light themes.** Some users will want a light Max theme; the library is built for dark.
Known: every module frame is a self-painted black panel with fixed RGB borders and labels, so cyan / amber stay
legible on it under any Max theme; the live.* widgets and a few patchers (f_modules, channel_grader, tone_curve,
stereo) do follow `themecolor`. Unknown: how the widgets look on that black panel under a light theme (never
looked), and whether a package can add its own named theme colours (theme files list only Max's ids). Options: A =
pin widget colours so modules stay dark in every theme (cheap), B = a real light palette (large; type colours need a
darker blue). First step when picked up: switch Max to a light theme and look at a few modules; optionally centralize
module colours in one builder palette table (type colours as a dark / light pair), which changes no output today.

**Pre-existing, not from this work**: `test_drift` fails only on `f_vf_advect` (code drift: the patcher's pix is
named `#0_advect_pix`, its definition is not; fix by writing the `#0_` name into the definition) and
`test_build_multistage.py` fails only its "f_vf_advect still reproduces" assertion, same cause.

## 2026-10-17 session: five f_tf consumers built to tier-2 (bench-verified, tier-3 pending)

- **Built, offline-verified, bench-verified** (tier-1 mirrors 19/20/20 + sharpen 15 + glyph 14;
  tier-2 benches all 6/6, final 5-file sweep re-confirmed, ask-approved per the standing rule):
  `f_tf_smooth` (one-pole tensor feedback, chain A's stabilizer), `f_tf_glyph` (glyph-field
  renderer + family debug tap), `f_tf_sharpen` (eigengap operator), `f_tf_aniso_blur`
  (structure-aligned smoother, straight-axis v1), `f_tf_hatch` (orientation-committed hatch,
  branch-T distance-field mechanics). All registered: menu (Utilities group), README ⚠ rows,
  module-inventory, launch patcher + `package/help/*.maxhelp` (five new helpfiles via a
  `make_helpfiles5.py`-shaped run of the make_missing_helpfiles helpers; helpfile judgment
  gate still yours), benchdeps.DATA (not bench.sh DEFAULT), BYPASS_EXPECT rows.
- **Tier-2 live GPU findings, now family property** (`docs/f-reference/f_tensor_type.md`
  consumer rules 5-6; full evidence `.specify/f_tf_glyph/plan.md` ADR-2 amendment):
  (a) runtime `atan2(0,0)` = NaN (constants fold to 0; runtime does not; mix() can't clear
  NaN); the fix is a +1e-7 atan2-denominator bias. (b) `sample()` drops to nearest when its
  coordinate is data-dependent and jumps (the skill's four-tap `nearest()` idiom fixes it).
  (c) the interpolated-read residual is the 8-bit-weight ceiling (~2e-4 stacked). (d) the
  bench keeps Params between jobs — every bench param dict must pin its params (aniso's and
  sharpen's runs prove it; also fixed key-mapping bugs in their mirror wrappers and an
  outlet-0 strength-clamp fixture bug in sharpen's bench).
- **Gates still open (all explicit, none silently resolved)**: smooth `release` default/range
  (T016, tier 3); glyph variant menu + debug tints (look, tier 3); sharpen dial mapping +
  possible rename (T016/T017, tier 3); aniso_blur kernel family (b) revisit if the bench cost
  experiment says family (a) isn't enough; hatch commit-curve shape + hairpin-hazard probe
  (needs bench); helpfile judgment gate for the five; `bench.sh DEFAULT` registration
  decision.
- **Next builds per confirmed triage order**: nothing in the confirmed build-order remains —
  the catalog's remaining items (mix when chain B assembles; glow = merged into parked Q12;
  glint deferred; jacobian/motion/hessian spike-on-demand; authored behind the UI-density
  gate).
- Committed (`cd80627` specs+codeboxes, `2cef6fb` tests, `6f0efe9` build+patchers,
  `693417b` docs/README/HANDOFF/skills). Working tree clean. Covers: 5× `.specify/f_tf_<m>/`
  triad + codeboxes + definition, `src/f_tf_<m>/` (built layout),
  `package/patchers/f_tf_<m>.maxpat`, `package/help/*` (5), `tests/{test,bench}_tf_<m>.py`
  (10), docs rows (`module-inventory.md`, README, launch, `f_tensor_type.md` rules 5-6).
  Pre-existing failures untouched (see below).
- **Live-verification round (2026-10-17 evening, ask-approved benches + module bench):**
  - **`build/build_patcher.py` processor branch now honors `driving_inlet`** (the session's
    main find): the old unconditional `gen-obj-1 → codebox[0]` line referenced an `in 1` box
    that driving_inlet builds never create — Max deleted the cord on load, the codebox's last
    input typed dead, the compile failed ("patchcord source not found", "type is not a
    sampler"), and the pix silently fell back to passthrough of its first texture. That was
    the built modules' live "acts like a passthrough" behavior Matt reported. All five
    `f_tf_` patchers rebuilt; module bench green on all five.
  - **Pix object names now `#0_`-prefixed** on all five + `f_tf_axisflow` (shipped 10-16,
    had it too): Ob3D bindings are context-global — two live instances of a bare-named module
    collide ("name X_pix already in use"), and the loser's params go unset ("no attribute").
    tensormap's `#0_` names were the in-repo precedent.
  - **`f_tf_hatch` e3 bypass now preserves alpha 1** (bypass = neutral-black under the
    outlets-are-A=1 rule; the whole-vec multiply dropped alpha to 0) — codebox + mirror in
    step, tier-1 still 20/20.
  - **BYPASS_EXPECT rows corrected to each module's true bypass source** (glyph/aniso =
    inlet 2, hatch = neutral const; smooth/sharpen = inlet 1 — those two pass as-is); new
    `("in_a1", N)` expect form for rgb-only bypass mixes.
  - Module bench state: the only remaining BADs are `f_a_decorrelate`'s audio wiring (4
    rows, pre-existing) — everything else, including all five new modules, green.

### Left for Matt

- Tensor `ideas/` docs consolidated 2026-10-17 into `ideas/f_tensorfield.md` (hub, status
  table), `ideas/f_tf_backlog.md` and `ideas/f_tf_research.md`; the eight earlier docs are
  retired (last at commit `693417b`). Two new open items live in the hub: Q16 (strength is
  not on the wire, bites `f_tf_aniso_blur`) and Q17 (hatch E1 masks a possible `atan2` NaN
  with `* (1 - iso)`, unlike glyph's `+1e-7` bias).
- Tier-3 live-feel gates above (release default, glyph variant menu, sharpen dial/rename,
  aniso_blur kernel family, hatch commit-curve + hairpin probe) are all still open and
  explicit, not silently resolved.

## 2026-10-16 session: f_tf_tensormap + f_tf_axisflow built, live-checked, documented

- **f_tf_tensormap** (structure tensor: raw outlet 0, packed cos2t/sin2t/trace/coherence outlet 1) and
  **f_tf_axisflow** (packed tensor -> seam-free vecfield by projecting a reference angle onto the edge
  line; no atan2) are built, bench-verified (8/8 and 5/5), mirror-tested (18 and 16), registered
  (menu, README, launcher, BYPASS_EXPECT) and committed (`2376cd7`, `53c10df`). Matt confirmed both work
  live (tensormap -> axisflow -> f_vf_advect). Specs: `.specify/f_tf_tensormap/`, `.specify/f_tf_axisflow/`.
- Findings worth keeping: `dim` reads 1 inside live `jit.gl.pix` (width/height are Params on both
  modules); the tensormap theta is the ACROSS-edge gradient axis (axisflow "Along" uses the complement
  projector); `phi` is a predefined GenExpr constant (assigning it fails the whole compile); bench GPU
  wraps out-of-range reads (codeboxes clamp in-shader); a stage must not be sent Params it does not
  declare ("invalid message"); bypass is `bypass_mode: "param"` (`bypass_gate`), not native @bypass.
- Docs written (uncommitted at the time of writing): `docs/f-reference/f_tf_tensormap.md`, `f_tf_axisflow.md`,
  new `f_tensor_type.md` (encoding contract, consumer rules), rows in `f_vecfield_type.md` and
  `module-inventory.md`, constitution (f_tf_ naming convention + Current Bpatchers rows), hub doc
  (`ideas/f_tensorfield.md`: axisflow bridge, Q12 unblocked, `.w` coherence correction).
  Helpfiles generated by `build/make_tf_helpfiles.py` (hand-reusable; does not touch other helpfiles).
  Panel layouts widened (tensormap 154x84, axisflow 154x124).
- `f_vf_glow` anisotropy inlet (hub Q12) now has tasks T039-T043 in `.specify/f_vf_glow/tasks.md`.

## Left for Matt

- Helpfile judgment gate for both modules: passed (Matt, 2026-10-16).
- Tensormap T036-T038 all passed live per Matt (2026-10-16); nothing left on the tensormap.
- Pre-existing failures not from this work: `test_drift` (f_vf_advect code drift, f_masonry baseline
  shrank) and `generate_menu --check` (vorticity/modules/audio patchers) come from uncommitted edits
  outside f_tf_.
- Axisflow v2 ideas (deferred, not built): per-pixel reference direction inlet, `normalize`, trace gating.

---

## 2026-10-13 session: f_weave dual-dial shipped, f_ks/f_vf_lbm specced, f_grain + f_lens → stable/, helpfile sizing+content audit, glow/prism/streak/chladni profiled

- **f_weave**: orientation A/B resolved as "ship both" — `field_amount`
  (mechanism depth) and `fix_blend` (A/B crossfade) are now live,
  performable dials, not a one-time pick. `src/f_weave/definition.py`,
  regenerated, drift-clean. `ideas/f_weave_orientation_blend.md`
  RESOLVED.
- **f_ks** (Kuramoto-Sivashinsky generator) and **f_vf_lbm** (D2Q9
  lattice-Boltzmann obstacle flow): both fully specced
  (`.specify/f_ks/spec.md`, `.specify/f_vf_lbm/spec.md`). Phase 0 (GPU
  bench) not started for either.
- **f_grain** and **f_lens** moved to `.specify/stable/`. f_lens v2
  (ghost images + halation) closed; tilt-shift split confirmed
  retroactive (it actually moved to the still-unbuilt `f_focus` on
  2026-09-23 — tracking docs had gone stale, now corrected).
  `README.md`'s f_lens row fixed (dropped stale "tilt-shift").
- **Helpfile sizing fix, 17 modules** (every bpatcher had been
  hardcoded to one module's footprint) + new `skills/module-preflight/`
  skill (mechanical checklist + a content judgment gate the sizing fix
  didn't cover). **Content audit** of those 17 against that gate:
  `ideas/f_helpfile_content_audit_2026-10-13.md` — 4 clean, worst three
  `f_sirds` (bad citation, doesn't match its own doc), `f_vf_vorticity`
  (recipe omits the one fact that makes it usable), `f_vf_glow` (its
  own doc has ready-made recipes never carried into the helpfile).
  Audit only, by design — no rewrites yet.
- **f_vf_vorticity**: confinement `range_tiers` fixed to [0.1, 1.0],
  confirmed working live in Max.
- **glow/prism/streak/chladni GPU-profiled live** — first real cost
  measurement any of the four ever had. All cheap in absolute terms
  (glow ~0.06ms/pass, the only one that resolved GPU-bound; the other
  three didn't even register as GPU-bound at chain=128).
  `bypass_gate` confirmed to not skip the heavy loop on any of them,
  but **not worth building an early-exit guard now** (Matt's call) —
  see `.specify/maintenance/tasks.md`'s cross-cutting observations.
  `status.json` updated for all four.
- **Tier 5 deferred on purpose, untouched**: web_shim go/no-go,
  packaging readiness, stale caustic spike reference.

### Left for Matt

- `f_focus` (tilt-shift's new home): still paused, never built — no
  urgency, just not forgotten.
- `f_vf_glow` early-exit guard: shelved; revisit only if a *general*
  reason to build these across modules shows up, not glow-specific.
- The 13 non-clean modules in the helpfile content audit (3 worst + 10
  mild/moderate): real rewrite work, deliberately not started this
  session.
- `f_ks` / `f_vf_lbm`: both need their Phase 0 GPU bench before any
  further design work.

## f_a_decorrelate: MODULE COMPLETE (at the f_a_ripple packaging bar) — DSP shipped to package/patchers/, docs written, all checks green

Assessed `f_a_decorrelate` against the current `f_a_ripple` state: the spec/plan block ("no ground truth until f_a_ripple clears T2–T6") is stale — T2–T6 passed 2026-08-05/06 and Phase 4 core DSP is built. Spec.md status header + Primary risk rewritten as resolved (with the narrower residual risk: comparisons run against `f_a_ripple_v1.maxpat`, not a shipped module); plan.md ADR-3 marked satisfied, Phase 2 line unblocked. tasks.md T001 ticked. **Key correction to earlier framing:** the idea file already records T7a — the pfft~ AM build — as PASSED 2026-08-07 (the buffer~/index~ architecture); what's genuinely unstarted is T7b (PM in pfft~) and the rigorous null/correlation tests.

**Math tier (new `tests/spike_a_decorrelate_t7.py`, not registered in benchdeps):** NumPy mirror of the whole T7a signal chain (hann STFT, per-bin gain from the 50 ms-refreshed curve, iSTFT with squared synthesis window) vs an additive AM reference on the matched carrier. Measured: **2048/4 is the right FFT size** (residual −15.6 dB rel ref RMS, corr 0.986; 4096/8192 get *worse* — longer windows violate the 1 Hz modulation more than they help bin alignment; **ADR-5 answered**). **50 ms refresh is free** (−15.6 vs −15.7 dB per-frame; T7a's metro rate validated). Residual attribution: frame-hold ~−33 dB, bin-frequency quantization of M ~−33 dB, STFT round-trip −180 dB — the dominant term is Hann leakage × per-bin gain on partials that aren't bin-centered (f0=96 vs 21.5 Hz bins), inherent to windowed per-bin processing, so a waveform null is physically NOT the bar; **envelope correlation (the paper's actual claim, T8's metric) is the acceptance test** and there pfft AM matches additive (mean |off-diag| 0.313 vs 0.320) with the fixed-SMR control cleanly separated (0.594). **PM (T7b) first data point for ADR-4:** per-bin phase rotation tracks additive PM at −11.2 dB, corr 0.962, envelope-corr in family (0.237 vs 0.202) — viable, not ruled out. Two reference-normalization bugs were caught and fixed in the mirror itself (per-band vs global sqrt(N) — a 1.63× band-level error that polluted the first "floor").

**Max patches authored (in `~/Vsynth/patterns/`, built by `build_t7b_patches.py` from the T7a exemplar per maxpat-json-authoring, structurally validated):** (1) `f_a_decorrelate_scratch_t7b.maxpat` + `t7b_inner.maxpat` — PM build: T7a's whole outer architecture plus a second buffer (T7b_phase) swept by a second uzi/expr writing ψ = (π/2)(1+d·M) gated in-band; inner subpatch does cartopol~ → phase+ψ → poltocar~. (2) `f_a_decorrelate_scratch_null.maxpat` — the T7 rig: same carrier gen~ feeds the pfft~ AM chain AND a new additive-AM reference gen~ (T5 math, carrier-consistent normalization); −~ residual read out via average~/snapshot~/print, selector~ A/B on the audio path. A trigger-ordering bug (phase uzi firing before the snapshots = stale reads, the exact class the skills warn about) was caught by tracing and fixed; the reference codebox's ternary-precedence bug (would have swallowed q+ωt out of the modulator) was caught and fixed before ever opening Max.


**Phase 4+5 done 2026-10-12 (same day, follow-on session).** The key
discovery: `f_a_ripple`'s v1 patch is ALREADY shipped in
`package/patchers/` — so the packaging bar was set, and
`f_a_decorrelate` now meets it:

- **T011 (build)**: `f_a_decorrelate_v1.maxpat` built by
  `~/Vsynth/patterns/build_f_a_decorrelate_v1.py` (from the T7b
  exemplar; three wiring bugs caught by structural audit — missing uzi
  box, missing trigger lines, orphan inlet) + shipped to
  `package/patchers/f_a_decorrelate.maxpat` with its
  `f_a_decorrelate_inner.maxpat` (pfft~ loads by name, same folder).
  Production deltas: `band` drives edges + **measured per-band bin
  geomeans** via `coll` (1468.6 … 11776.4; band 6 = 8200.8, validating
  T7a's typed 8001); AM/PM both-always-applied with the sweep `expr`s
  self-gating on `mod_type` (no message inlet into pfft~, per the
  skill); gain/mix wet-dry; tanh safety ceiling; v1 ranges.
- **T012 (drift)**: `tests/drift_baseline.json` entry, `out_of_scope`,
  reason mirrors `f_a_ripple`'s precedent exactly.
- **T013 (docs)**: `docs/f-reference/f_a_decorrelate.md` — signal path,
  code-accurate equations, measured-behavior section (all spike numbers),
  35 ms wet-path latency, Safety section.
- **T014 (registration)**: README Audio row (⚠, under the 110-char
  limit), `NOT_IN_MENU` with reason, `f_Launch` regenerated (40
  modules). **Real repo-schema extension**: pfft~ inner subpatches are a
  new file class — `NOT_MODULES` added to `generate_launch.py` (hoisted
  to module level so `test_launch.py` uses it), matching exemption in
  `generate_menu.py`. `tests/run.sh` offline suite green: launch 8/8,
  benchdeps 21/21, build_conventions 40/40, drift PASS.
  **Helpfile deliberately deferred** — the f-helpfile format has no
  audio-module shape (vs_sources_main/vs_preview are texture idioms);
  that format is part of the shared audio-archetype decision, and
  `f_a_ripple` has no helpfile either.
- **T015**: this HANDOFF entry; commit left to Matt's convention.
### Left for Matt

- **Both Max verifications PASSED 2026-10-12** (per Matt's session): T002
  null rig landed in the −15 dB class (T7 closed); T005's PM listen — no
  glitching, plausible PM character — **ADR-4 verdict: PM un-scoped for
  v1**. T008 (band-1 *improves* at 2048/4: −22.7 dB, corr 0.997 — one
  FFT size serves all bands, ADR-5 fully closed), T003 (two real-world
  music carriers; varying-SMR cross-segment correlation drift beats
  fixed on both — the paper's actual claim; modest margin on music, strong
  decorrelation vs the raw carrier 0.94→0.59), and Phase 3 (high tmr is
  WINDOW-limited not refresh-limited → tmr ceiling 4 Hz; depth > 1 sends
  bin gain negative → depth ceiling 1; PM extreme depth graceful) all
  done in the mirror the same day.
- **Phase 4+5 complete at the `f_a_ripple` packaging bar** (details in
  the block above): DSP shipped to `package/patchers/`, docs written,
  registration green (launch 8/8, benchdeps 21/21, build_conventions
  40/40, drift PASS, f_Launch regenerated).
- **Uncommitted, all in `f_`**: `package/patchers/f_a_decorrelate.maxpat`
  + `f_a_decorrelate_inner.maxpat` (new), `package/extras/f_Launch.maxpat`
  (regenerated), `docs/f-reference/f_a_decorrelate.md` (new),
  `README.md`, `src/f_modules/menu.py`, `build/generate_launch.py`,
  `build/generate_menu.py`, `tests/test_launch.py`,
  `tests/drift_baseline.json`, `tests/spike_a_decorrelate_t7.py`,
  `.specify/f_a_decorrelate/{spec,plan,tasks}.md`, `HANDOFF.md`. One
  review-and-squash covers the whole module.
- **The shared f_a_ packaging workstream is now the only thing left**
  for both audio modules: `build_patcher.py` audio archetype (replaces
  the hand-built patches, brings both onto the drift ratchet),
  live.dial UI grid, audio helpfile format, and `f_a_ripple`'s own
  T002 items (checkhearing comparison). `f_a_decorrelate`'s tasks/
  spec/plan all point at it as the join-point rather than a blocker.
- **One Max listen owed at leisure** (T009's live no-clicks sweep on the
  production patch — mirror says smooth, packaging repeats it anyway).

## Review-and-squash of the day's stack; helpfiles closed; build_cleanup closed; suite fully green

_2026-10-12 (evening session)._

Six commits reviewed and squashed from the day's accumulated work (the `f_demo_caustic2.maxpat` checkpoint got its own `2026-10-12` message per Matt; `scratch/experiments/` left untracked as his live web-shim work), then three workstreams executed:

**Helpfiles (commits f0de0e0, c161780).** The T011–T021 boxes were misleading — all 11 helpfiles already existed from the 2026-07-19 pipeline regen, but re-verification against definitions found three with stale External Control blocks (grain: dead `amount` + missing gain/mix + wrong softness range; lens: five dead tilt-shift params removed with the f_focus move; tone_curve: control block didn't match shipped params at all). T004 closed: References sections written for all 12 remaining docs (original derivations labeled; texrouter's records its T022 assessment). T022: deliberately no helpfile (dead module, no archetype). Then a second pass: 14 shipped GPU modules had NO helpfile at all (grey in f_Launch) — generated via new `build/make_missing_helpfiles.py` from the f_vf_vortex template (one extractor bug caught in verification: pix-chain object names picked up as params). `f_Launch.maxpat` regenerated: **34 of 39 clickable** (5 deliberate: audio x2, the menu, texrouter, util_matrix draft). **Owed: one Max session opening the 14 new + 3 corrected helpfiles to confirm demos/layout live** — the text-only edits are verified offline, but the spec's open-in-Max step hasn't run.

**build_cleanup (commit e434afa).** Phase 3 drift-closing completed: `f_vf_vorticity` was the last drifted module — regenerated after writing back its one real hand state (saved default `confinement=0.1`), deep-diffed clean. **32 of 39 reproduce exactly; baseline 7.** T016/T017 verified closed (shipped with the f_vf_fluid absorption; boxes were unticked). T032b live-verified: seeded a plain bench run, `--changed` then correctly skipped everything with accurate per-module records. **The bench run surfaced a Max crash from 20:01 that day** (retired crash report on disk): ~25 tests failed with `bad object` on two attempts; `benchclient.reopen()` cannot heal a crashed instance — full quit + relaunch of Max fixed it, 12/12 green after. Four pre-existing offline failures (all from the 2026-10-09/10 f_grain commits, committed without a full suite run) found and fixed: the f_grain route test still expected `amount`; raw_ui.json stale vs the hand-saved patcher; f_addmod.js stale (grain panel size); test_harness broken under `run.sh -q` (TEST_QUIET leaked into the harness-under-test). **Offline suite: 23/23 files green.**

### Left for Matt

- Everything from today's six workstreams is committed; working tree clean except `scratch/experiments/` (live WIP, untracked).
- One Max session owed, three things in it: open the 17 touched helpfiles (14 new, 3 corrected) to confirm demos/layout; look at the regenerated `f_vf_vorticity` patcher (its only behavioral change is the default 0.1 the shipped patch already had); re-check `f_demo_caustic2.maxpat` at your leisure.
- The one Max operational lesson worth keeping: **reopen() is not the recovery for a crashed Max instance** (only for the stale-capture wedge) — quit and relaunch. Recorded in build_cleanup/tasks.md T032b.
- Standing next-session picks, unchanged from earlier today: the glow+prism+streak+chladni profiling afternoon (maintenance's highest-value item), or tensor-field OQ2 (outlet packing, needs you).

_2026-10-12._

Executed the full `.specify/maintenance/plan.md` prioritization in one pass — every shipped module not yet audited is now in `status.json` (34 total: the 2026-10-09 nine plus today's 25). Six parallel read-only scouts gathered per-tier facts (no GPU benches run; the one offline test exercised, `test_fluid_mirror.py`, ran 22/22 green); every load-bearing claim was spot-verified before recording, which caught **three scout errors** (prism's spec was *not* a stale chroma copy-paste — it was rewritten 2026-07-11 with its own correction note; the claimed streak-demo.json doesn't exist — the dead preset keys live in f_demo_warp.json/f_demo_seeds*.json instead; weave's tasks.md is partially maintained, not a time capsule).

- **The plan's flagged pre-check resolved:** `f_vf_chroma` is paused mid-retool, not a doc gap — shipped v10 doesn't achieve the module's stated goal (accumulation averages the rainbow to gray); continuity.md records the closest-emitter/painter-model direction. Also: `direction=Bi` is unreachable from UI (build_patcher hardcodes 2-option toggles), and it still has `strength` (never in the gain/mix rollout, skip never recorded). Tasks filed in place in paused/.
- **The perf headline:** glow, prism, streak, chroma and chladni all run their heavy codeboxes full-cost while bypassed, unmeasured — glow/chroma's 48-step loops, prism's 33 unrolled gate samples, streak's 8-step march, chladni's ~5 modal evaluations/pixel. One profiling afternoon covers all five (recorded as the standing priority in the workstream queue). stipple and vf_split confirmed trivial (the plan's "likely lightweight" hunch was right — chladni was the sleeper).
- **Real findings beyond the mechanical:** the hue band-drag bug is confirmed pure folklore (now f_hue_processor/T001–2, with the jsui loop-back guard pinned as the mechanism); `f_vf_potential` settles tensorfield OQ11 — it integrates field *magnitude*, axis-blind, so the audit table's "assumed excluded" is wrong; `f_vf_flow` and `f_vf_potential` have unasserted bypass behavior (dual/processor archetype mismatches, one-line BYPASS_EXPECT additions filed); f_stereo remains the only warper never pointed at the existing Tissot diagnostic; the hue doc's parameter-routing description doesn't match the shipped definition.
- **Folder moves per the stable/ bar:** f_vf_glow, f_vf_vortex, f_stipple came off `.specify/stable/` (they gained tasks; f_stipple also already carried nine open items). f_mobius and f_stereo stay on stable/ with single investigation tasks filed in place.
- **22 tasks filed across 15 modules** (ids cross-referenced in status.json); fresh tasks.md folders created for f_hue_processor, f_ngon, f_vf_potential, f_vf_flow, f_vf_split, f_tone_curve, f_vf_prism, f_a_ripple. Three new cross-cutting observations recorded in the workstream's own tasks.md (dead bench header comment, dead preset keys, the tier-1-skip-decision gap as the most common result).

### Left for Matt

- Nothing in the workstream queue is blocking. The single highest-value pickup is the **glow+prism+streak+chladni profiling session**; the cheapest is the f_stereo Tissot spike (reuses existing diagnostics).
- Two stale-doc clusters worth a docs-only commit: f_vf_glow.md / f_stipple.md / f_vf_split.md / f_hue_processor.md rows (filed as tasks, not fixed inline — fixes are future tasks per the protocol).
- Note: the `.specify/plan.md` Work Queue was NOT edited (protocol rule) — if any finding warrants a work-queue item, that's your call. Candidates: the never-regenerate-list cleanup and the general gain/mix decision, both already recorded as cross-cutting observations.

_2026-10-12._

Executed the two threads `ideas/ceyron_simulation_scripts_notes.md` left "genuinely unprocessed" — and the outcome decides an architecture question, not just two module candidacies.

- **New:** `tests/spike_ks_stability.py` and `tests/spike_lbm_d2q9_architecture.py` (NumPy diagnostics, not registered in benchdeps), both 3/3 and 2/2 green against their own measured criteria.
- **KS verdict: real-space explicit FD is dead (dt_max ≈ 5e-5 at 256², ~2000 substeps/frame — matches the O(dx^4) theory bound), but the spectral `f_vf_fluid`-shape is stable one step per frame** (linear part exact per Fourier bin with rate K2(K2−1); only |∇u|² explicit; dt ≈ 0.076 measured vs the reference ETDRK's 0.1; self-sustaining chaos verified over 600 frames with zero forcing). **One mandatory containment found:** the |∇u|² nonlinearity integrates domain-negative — the field mean drifts secularly (−0.2 → −15 measured) and the k=0 bin must be zeroed each step (one bin, same class as fluid's Nyquist zeroing). Cleared to spec whenever wanted.
- **LBM verdict: fits the chained-pix pattern, no slab track.** Streaming is a pure gather (the `f_vf_streak` directional-sample idiom), collision/equilibrium fuse into one local codebox, bounce-back is a mask-driven swap, 9 channels/cell → 3 RGBA planes on the same `pass` feedback. **Two silent-garbage correctness traps recorded in the spike** (stream-direction sign — uniform flow hides it, the obstacle exposes it; bounce-back must read pre-collision values — post-collision values blow up in ~40 steps). **Two real constraints:** periodic+obstacle is unstable at the reference's ω≈1.97 (stable to ~1.8) — the channel in/outflow BCs are load-bearing, so a vortex-street module needs open-boundary edge handling; and shedding is slow to develop at performance resolutions (weak wake at 12k steps, 300×50 — the reference skips its first 5000 of 15000). Value vs `f_vf_repulse` fakery remains Matt's judgement call.
- **`slab_chain_architecture.md` RETIRED.** Its premise was already weakened by `f_vf_fluid` shipping without it; LBM and KS were its only remaining candidates, and both are now proven not to need it. File updated with the conclusion and a status header; INDEX updated. Nothing should be built on that track unless a future idea genuinely needs per-pass GLSL uniforms.
- Docs updated where the claims live: `ceyron_simulation_scripts_notes.md` (both findings inline + resume-points rewritten), `slab_chain_architecture.md` (retired), `INDEX.md`.

### Left for Matt

- Two module candidacies are now architecture-cleared with real numbers: **KS generator** (ready to spec — the "self-sustaining chaotic generator" slot nothing in the library fills; the spike's k=0 zeroing and the dt ceiling are the design inputs) and **LBM obstacle flow** (cleared architecturally, but the periodic-domain instability + slow shedding constraints mean the module shape is a design question — and whether it beats `f_vf_repulse` for practical use is still open).
- Uncommitted: the two spike scripts plus the edited docs (`HANDOFF.md`, `ideas/ceyron_simulation_scripts_notes.md`, `ideas/slab_chain_architecture.md`, `ideas/INDEX.md`), on top of the still-uncommitted atan2 and caustic sessions below. Consider a single review-and-squash commit soon — three sessions of results are now stacked in the working tree.

_2026-10-12._

The highest-leverage Phase 1 item from the tensor-field sessions below — GenExpr `atan2` safety in `jit.gl.pix`, the shared blocker of `f_tensorfield.md` OQ6, `f_weave_orientation_blend.md` Fix B, and `f_anamorph_unnamed.md`'s field-driven half — is **closed: verified safe**, live on the GPU bench.

- **New:** `tests/spike_atan2_safety.py` + `tests/bench/codeboxes/atan2_safety.gen`. The codebox decodes a sampled vecfield texture (the actual consumer pattern — the skill file's prior `atan2` precedent only covered analytic coords) and outputs four probes: θ, θ/2, the doubled-angle round trip, and a sign(Fx) cross-check. Four tests against independent `np.arctan2` truth, 4/4 green.
- **Results:** compiles/runs clean, no bench errors; max wrap-aware error 5.6e-7 rad across all quadrants; branch cut correctly wrapped (24,934 adjacent-texel 2π jumps, and near-cut pixels match their own pixel-centre truth — no sampling smearing); half-angle decode 2.8e-7 rad; `atan2(sin t, cos t) == t` to 7.8e-7 rad.
- **One real, measured quirk:** at the degenerate cut boundary (`Fy == 0, Fx < 0`) the GPU returns +π where IEEE `atan2(-0, -x)` is −π. Benign for every consumer use (±π is the same line; blends use vectors/doubled components), but any NumPy mirror diffing GPU output must wrap-compare at that line. Pinned in the skill file's Trigonometry section alongside the other bench-verified facts.
- **Bench notes for whoever runs this again:** one run wedged the bench ("bad object" stale-capture failure mode, already documented in tests/README) after an edit changed the codebox mid-session — `benchclient.reopen()` fixed it; and three of the four tests' first drafts failed on *test-side* bugs (a wrap-aware diff applied where a raw diff was needed, a mis-decoded channel scale, a string passed to `harness.note`) — worth remembering that a red here is as likely to be the harness as the GPU.
- **Docs closed:** `f_tensorfield.md` OQ6 rewritten as verified (with the quirk), Phase 1's "highest-leverage item" pointer marked done, cross-ref updated; `f_weave_orientation_blend.md`'s identical blocker struck through with the result — its Fix A/B is now purely the live empirical A/B it always was; `f_anamorph_unnamed.md`'s cross-ref updated (the angle-doubled simplification now waits only on OQ2, outlet packing); skill file's `atan2` entry strengthened from "listed as valid" to the measured decode-case verification.

### Left for Matt

- OQ6 blocks nothing anymore. The natural next steps it unblocked, in the files' own priority order: the `f_weave` orientation A/B scratch patch (empirical taste question, needs your eyes on the live result), and tensor-field OQ2 (outlet 2/3 packing — the remaining gate before Phase 2 per-module work).
- Uncommitted: the two spike files plus the five edited docs (`HANDOFF.md`, `ideas/f_tensorfield.md`, `ideas/f_weave_orientation_blend.md`, `ideas/f_anamorph_unnamed.md`, `skills/jit-gen-codebox/SKILL.md`). Same review-and-squash convention as the sessions below.

_2026-10-12._

Executed the "cheap, well-scoped next experiment" from the two sessions below: quantify what `f_caustic`'s divergence (trace) weight misses vs the full Jacobian. New `tests/spike_caustic_trace_vs_jacobian.py` (NumPy diagnostic, not registered in benchdeps), reusing `scratch/caustic_fidelity.py`'s test glass, analytic Jacobian, and photon-counting truth. Seeds 7 and 3 agree throughout.

- **The headline negative result: optics_map.md's saddle-on-a-fold scenario does not occur on this glass.** The trace weight and the local full-Jacobian gain 1/|det(I+d·J)| have *identical* top-8% sets at d* (zero disagreement pixels in either direction) — near-fold pixels coincide with strong negative divergence, so the trace sees them fine. Finding 3's mechanism ("a saddle can have zero divergence while sitting exactly on a fold") is a true statement about the representation but not the measured failure mode here.
- **The real, measured gap is saddle structure, not fold detection.** At d*, 53–55% of interior pixels are saddles; within that partition the trace weight correlates with truth at r 0.52–0.69 vs the full Jacobian's 0.60–0.80 (top-8% IoU 0.28–0.38 vs 0.28–0.42). In the focus and defocus partitions the two are equivalent — the trace is nearly all the signal there.
- **The full Jacobian is not a drop-in better weight past the first fold.** At 3.5 d* the one-branch local det gain collapses to r 0.15–0.20, *worse* than the trace's 0.46–0.56 — consistent with the existing finding that multi-branch handling (multi-guess gather, scatter) is what works there, not weight completeness. The full Jacobian is only the better weight below d*.
- Cross-checked: the spike's trace-gain-at-3.5d* numbers reproduce the fidelity table's "first-order only" row exactly (same quantity, independent code path).
- Docs amended where the claims live: `ideas/optics_map.md` finding 3 now carries the measurement, and `ideas/f_tensorfield.md`'s "strongest hit" bullet is amended from "a blanket fidelity gap with numbers in hand" to the accurate saddle-partition-only gap, plus the 3.5 d* reversal caveat. The audit-table amendment it promised is recorded there rather than editing the table itself (the numbers bound the claim; the table's "sign-sensitive, inferred" verdict is unchanged by them).

### Left for Matt

- Nothing forces a module change — this measures the representation gap, it doesn't decide that `f_caustic` should grow a tensor inlet. If tensor-field work resumes, the next lever these numbers point at is the saddle partition (55% of pixels, the one place the trace measurably loses structure).
- Uncommitted (docs + one new diagnostic script): `HANDOFF.md`, `ideas/f_tensorfield.md`, `ideas/optics_map.md`, `tests/spike_caustic_trace_vs_jacobian.py`. Same review-and-squash convention as the sessions below.

## web_shim_candidates: exportcode trial executed (research, no canonical files touched)

_2026-10-12._

The concrete next step flagged in the 2026-10-11 gates digest — running `exportcode webgl` / `exportcode isf` on one simple module — is done. Reconnaissance only, no go/no-go call made. Everything lives in `scratch/experiments/web_shim_trial/` (incl. full `REPORT.md`); nothing committed.

- **Test subject: f_vf_split** — chosen for conceptual simplicity, not line count (2 `sample()` reads + 2 `mix()` calls; fewest params of any gen-based module). f_texrouter is smaller but has no codebox, so nothing for exportcode to export.
- **Both targets succeeded.** `exportcode webgl` → TWGL-based `.html`; `exportcode isf` → valid `.fs` (ISF JSON header declares params + image inputs, GLSL body matches the codebox math). Runtime-verified: the html loads in headless Chromium with twgl-full.min.js v4.4.0 (pinned per maxref), shader compiles/links, `gl.getError()==0`, rAF loop draws, zero console entries (only expected headless camera-permission denials).
- **Real gaps vs. in-Max behavior** (details in REPORT.md): (1) outlet collapse — the shader computes both X and Y channels but assigns `gl_FragColor` twice, so only the last outlet survives; every multi-outlet module loses the rest; (2) inputs hardwired to webcam, no hook for a different source; (3) params become one-shot uniforms (no UI — an ISF host would expose them, raw webgl won't); (4) 8-bit RGBA, not the module's float32; (5) no `r draw` clock — free-running rAF.
- **Trial mechanics:** the UDP bench can't send arbitrary messages, so the driver was a js-driven throwaway patcher (repo's `f_addmod.js` pattern). Two quirks worth remembering: js property assignment for `exportfolder` silently doesn't register — the message form works; and hand-written .maxpat JSON lost 4 patchcords on load in Max 9.2.0, so objects were built programmatically from js instead.
- **Open questions for whoever picks this up:** is the outlet collapse inherent to exportcode or would another path (jxs) preserve multi-outlet? Do feedback/`dim` modules (f_vf_advect, f_vf_fluid, f_caustic) export at all? Is 8-bit quantization acceptable for the vecfield family or are float textures required? Is ISF the practical shim (free param UI) with the webgl html as demo only? None tested beyond this one module.

## Ideas: tensor-field cross-references (weave/anamorph/optics), built-module heuristic audit, paused-module check, two stale-doc corrections (research, no code)

Follow-on session to the tensor-field entry below, same day. Started from "go deeper on optical/discrete/conformal applications" and widened into checking the project's own idea files for staleness. No code touched — six `ideas/` files edited, nothing committed.

- **Cross-references added, each a real (not speculative) connection:**
  - `ideas/f_weave_orientation_blend.md` — new section naming the orientation bug as `vector_field_math_concepts.md` #9's sign-free line-field case, and noting Fix B shares `f_tensorfield.md` Open Question 6's exact blocker (`atan2` safety in GenExpr, unverified in both places).
  - `ideas/f_anamorph_unnamed.md` — new section tying the field-driven half's hemisphere-align hack (step 3) to the identical line-not-direction problem, framed as a hand-rolled version of what `f_tensorfield.md`'s angle-doubled storage solves by construction.
  - `ideas/optics_map.md` — astigmatism/field-curvature row now notes it's genuinely tensor-valued, not a scalar blur; new "Photoelastic stress-fringe interference" row in the Wave optics chart; `f_tensorfield.md`/`vector_field_math_concepts.md` added to Related.
- **Three-part heuristic ("fights a sign-free vector" / "wants a Tissot diagnostic ellipse" / "flattens a curvature quantity to a scalar") run against the full `module-inventory.md`, not just vecfield-consumers — captured in `f_tensorfield.md`'s new "Beyond the vecfield-consumer audit" section:**
  - **`f_caustic` — strongest hit, already evidenced with hard numbers.** `optics_map.md`'s own caustic-fidelity research shows the module weights by divergence (trace of the Jacobian) when the actual fold condition needs the full Jacobian's eigenvalues — the det-gather/scatter experiments that *did* reproduce folds already used the full tensor. Not previously named as a tensor problem.
  - `f_stipple`'s `anisotropy`/`angle` confirmed as the tightest existing semantic match (already Open Question 13).
  - `f_stereo` — new, not previously flagged: same conformal-blend shape as `f_mobius`/`f_droste` (ortho↔stereographic), so the already-spiked Tissot-indicatrix diagnostic (`vector_field_math_concepts.md` #10) applies directly and was never run against it.
  - `f_lens` — predicted (not spiked) to always show a circular indicatrix, same negative result as `f_mobius`, per `f_anamorph_unnamed.md`'s isotropic-distortion-math finding; also why the astigmatism row is stuck at "Research."
  - `f_masonry` flagged as a marginal, by-proxy beneficiary of idea #11 (Jacobian-determinant AA) once that's built.
- **Paused-module check: no unblocks found.** Read every spec/plan in `.specify/paused/` against the same heuristic — `f_apollonian`/`f_poincare` are blocked on an algebra bug (ADR-8, Möbius-composition parity tracking), `f_stereogram` on a Vsynth render-to-texture limit, the paused `f_vf_chroma` draft on an averaging-vs-loop design question plus a build-script bug, `f_vf_vorticity` on a single-vs-multi-pass codebox question, `f_focus` isn't actually blocked. None of these are representation-type problems tensor fields would touch. Logged in `f_tensorfield.md` so it isn't re-investigated.
- **Checked `gpu_gems_research.md` and `ceyron_simulation_scripts_notes.md` for unprocessed directions.** `gpu_gems_research.md` is fully closed — every chapter across all three volumes has a dated verdict. `ceyron_simulation_scripts_notes.md`: the FFT-fluid thread is **resolved and shipped as `f_vf_fluid`**, not open (its `INDEX.md` one-liner was stale, saying "open question, not resolved" — fixed); two threads are still genuinely open and unscheduled: 2D Lattice Boltzmann (D2Q9) obstacle-aware flow, and a Kuramoto-Sivashinsky 2D chaotic generator.
- **Real finding from that check, folded into `slab_chain_architecture.md`:** that file's whole premise ("jit.gl.pix's single fused kernel cannot do multi-pass, so FFT Stable Fluids needs a new GLSL-slab-ping-pong architectural track") is contradicted by what actually shipped. `docs/f-reference/f_vf_fluid.md`'s own Signal Flow section shows the FFT solver built from 8 chained ordinary `jit.gl.pix` objects with a `pass` node for one-frame feedback — no real GLSL, no `jit.gl.slab`/`pass`/`node` ping-pong anywhere. Corrected the file's "Why this exists" list, its promotion gate (item 2 no longer names FFT as the target), and its performance-ceiling open question. The remaining open question (not resolved, flagged only): does 2D LBM or Kuramoto-Sivashinsky actually need the slab-chain track, or does the chained-pix-objects-plus-`pass`-feedback pattern `f_vf_fluid` just proved out also cover them? Nobody's checked.

### Left for Matt

- Nothing built — this whole session is cross-references and corrections to existing docs, same as the session below. Next real steps, in rough order of leverage: (1) `f_tensorfield.md` Open Question 6 (`atan2` safety) still gates the most consumers; (2) the `f_caustic` trace-vs-full-Jacobian finding and the `f_stereo` Tissot spike are both cheap, well-scoped next experiments if tensor-field work resumes; (3) whoever picks up `slab_chain_architecture.md` should re-check LBM/KS against the chained-pix-objects pattern before assuming they need the new track.
- **Uncommitted** (docs only): `ideas/INDEX.md`, `ideas/f_anamorph_unnamed.md`, `ideas/f_tensorfield.md`, `ideas/f_weave_orientation_blend.md`, `ideas/optics_map.md`, `ideas/slab_chain_architecture.md`. Not committed this session — left for Matt to review/squash as he likes.

## Ideas: tensor field — moved to `ideas/`, full consumer audit, Phase 1/2 framing, new paused-module convention (research, no code)

Long discussion session continuing the tensor-field thread from `vector_field_math_concepts.md` #9. Started by correcting the previous session's artifact (`.specify/f_tf_structure/spec.md` wasn't a spec — too many open questions, Matt's own call) and ended up expanding the scope considerably. No code or tests touched; everything below is docs.

- **Moved and restructured**: `.specify/f_tf_structure/spec.md` deleted; content rewritten as `ideas/f_tensorfield.md`, the tensor family's hub doc (same role `f_vecfield.md` plays for vecfield producers). `ideas/INDEX.md`'s Vector field family section and `vector_field_math_concepts.md`'s stale "#9 is genuinely new territory, not represented anywhere else" line both updated to point at it.
- **Full consumer audit, not the 3-module first draft**: every built `f_` module taking a vecfield input, checked against `src/<name>/definition.py`'s `mod_inlets` (ground truth, not spec prose) — 12 modules once paused ones are excluded. Findings worth remembering: `f_vf_chroma`/`f_vf_prism` have two free scalar mod inlets each and no plumbing cost; `f_vf_split` sidesteps the `atan2` decode question entirely for consumers that only need `(cos 2θ, sin 2θ)` as a bipolar pair; `f_vf_potential`'s safety is genuinely unresolved (needs a codebox read), not assumed-excluded; `f_vf_advect` was missing from the exclusion list and has been added.
- **New standing convention** (README's session rules): modules in `.specify/paused/` are excluded from analysis/planning going forward — not treated as blockers or candidates for unrelated work. Came up because `f_vf_vorticity` kept surfacing in the tensor audit despite being paused/unverified project-wide; it's been pulled back out.
- **Project-state check, prompted by Matt asking whether a library-wide "Phase 2" redesign was prudent before finishing existing maintenance.** Read `README.md`/`HANDOFF.md`/`.specify/plan.md` properly (should have at session start — the token-limit failure from two sessions ago never got revisited until now). Found two live workstreams that directly intersect with tensor-field Phase 2, confirmed by Matt as the ones that matter: the drift-cleanup project (`plan.md` item 6 — 32/39 patchers reproduce from `definition.py`, 7 don't, explicitly the project's current "live task queue") and the paused UI-density/control-surface workstream (`ideas/mod_depth_ui_density.md` — may be the *same* direction as "more performative control surfaces," not a separate one). Cross-referenced both ways between `plan.md` and `f_tensorfield.md`.
- **Design discussion, several real findings folded into `ideas/f_tensorfield.md`'s open questions (now 15) and `ideas/f_util_mod_texture.md`:**
  - `f_vf_glow`'s `direction` enum (fwd/bwd/bidirectional) is already branchless in its codebox (`fwd_weight`/`bwd_weight` via `step()`) — confirmed from source that it could become a continuous, per-pixel, anisotropy-driven blend rather than a flat 3-way dial, with low anisotropy naturally pushing toward the safe bidirectional mode near singularities.
  - `f_stipple` (not a vecfield consumer today) has its own `anisotropy`/`angle` params that already mean almost exactly what the tensor's outlets would mean — a tighter semantic fit than anything in the vecfield-consumer audit, at the cost of needing genuinely new inlets.
  - `f_grain`'s `jitter`/`size_var` as tensor-driven sites held explicitly open, not assumed — needs its actual codebox read (only the markdown spec was checked) before concluding anything.
  - A packing question: `f_vf_glow` wants trace+anisotropy together, `f_stipple` wants direction+anisotropy together — raises whether a 4th, single RGBA "decoded convenience" outlet belongs alongside the raw-tensor outlet, instead of committing to today's 3-outlet split.
  - A general pattern, generalized beyond glow specifically: anisotropy as a *multiplicative* confidence-gate on mod-amount (`effective_depth = depth_dial × anisotropy`), not a replacement for the performer's depth dial — keeps performer intent and local data confidence as separate axes. Raises whether `f_util_mod_texture.md`'s base/depth/texture triple needs a 4th, optional confidence-gate element; added to that file's own open questions.
  - Clarified named-mod-texture tagging needs no custom object — plain `prepend`/`route`, same mechanism for a role tag or a type tag. But core Vsynth modules have no shared/tagged inlet at all (Kevin's convention is 1 inlet : 1 param) — there's no slot for a tag to land in, so type-safety against a core Vsynth destination is permanently a documentation-only concern, not a closable bug class the way it might be for an `f_` consumer.
  - Explicit two-phase framing adopted (Matt's own words): Phase 1 (survey/audit, cheap, breadth-first — what this session mostly did) vs. Phase 2 (per-module finesse/rethink, one module at a time, not started on purpose — some of it is more than wiring).

## Left for Matt

- Nothing built or decided yet on tensor fields — this is still all open questions, deliberately. `ideas/f_tensorfield.md`'s own "Next step" section: Open Question 6 (`atan2` safety in GenExpr, unverified) is the highest-leverage Phase 1 item; Phase 2 doesn't start until that and the outlet-packing question (Open Question 2) settle.
- Noticed but unrelated to this session: `package/examples/f_demo_sampleplatter.maxpat` shows as modified in `git status` — not touched by this session, presumably a prior hand-edit in Max not yet committed. Flagging so it isn't lost or mistakenly folded into a commit for this session's docs work.
- This session's changes are **uncommitted** (docs only: `README.md`, `.specify/plan.md`, `ideas/INDEX.md`, `ideas/f_util_mod_texture.md`, `ideas/vector_field_math_concepts.md`, new `ideas/f_tensorfield.md`, `tests/spike_structure_tensor_range.py`, `scratch/structure_tensor_range.png` — the latter two from the prior session's spike, not newly written this session but also still uncommitted).

## Ideas: two loose ends closed — Mobius+Droste spec merged, f_poincare doc corrected

- `.specify/f_mobius_vecfield/spec.md` expanded (Matt's call) to cover both
  `f_mobius` (conformal, complex division) and `f_droste` (not conformal,
  needs a full 2x2 matrix solve) as one vecfield-aware-UV-warp workstream —
  previously the f_droste finding was HANDOFF-only. `plan.md` item 5 updated
  to match.
- `plan.md`'s paused/blocked `f_poincare` entry corrected (Matt confirmed
  stale, not pointing elsewhere): it claimed "Phases 0–2 confirmed working,
  closed-form {p,q} formula derived," which no file in the repo backs up.
  Now reads "Planned, not yet specced," matching `ideas/f_poincare.md`.

## Ideas: #7 conservative-field test, Mobius spec, f_droste conformality check

Follow-up to the Lie-bracket/Mobius session below, same day. Three pieces:

- **#7 conservative-field check, done as a real test** (not a spike):
  `tests/test_conservative_field.py`, registered, passes via `tests/run.sh`.
  Mirrors `f_vf_fieldmap`'s actual gradient codebox, integrates its output
  around several closed loops at the module's default `rotate=0` (max
  |circulation|/perimeter 3.3e-5, well under a 2e-3 tolerance). Includes a
  negative control (rotate=90°, which breaks conservativeness in general)
  to prove the check has real discriminating power, not a trivial pass —
  first attempt's control loop happened to sit on a symmetry point of the
  synthetic source where circulation cancels even for the rotated field
  (confirmed empirically, not assumed); fixed by using a different loop set.
- **Mobius vecfield-correctness: specced, not built** (Matt's call). New
  `.specify/f_mobius_vecfield/spec.md` — problem statement, the correct
  transform's math (`v' = v_source/g'(z)`), and open questions (new module
  vs. mode on `f_mobius`, whether this generalizes). Added to `plan.md`'s
  work queue as item 5.
- **f_droste conformality, checked numerically**
  (`tests/spike_droste_conformality.py`, diagnostic, not a regression gate):
  a first hand-derivation (written into the spec before running anything)
  predicted `f_droste` was conformal at `twist=0, n_arms=1` — **wrong**,
  caught by actually running the finite-difference check. Real cause: the
  log-polar step scales its radial axis by `1/log(zoom)` and angular axis
  by `1/(2*pi)` — different constants for any `zoom` where
  `log(zoom) != 2*pi` (≈535, outside the UI range), making the module
  essentially never conformal regardless of `twist`/`n_arms`. Measured
  eccentricity 9.065 at `zoom=2.0` baseline, matching `2*pi/log(2)` exactly;
  isolating the effect (`zoom` tuned so `log(zoom)=2*pi`) drives it to
  exactly 1.000000, confirming the mechanism rather than inferring it.
  Also hit and fixed a finite-difference artifact: one of the four original
  test points sat exactly on `atan2`'s branch cut and gave a bogus
  derivative (693x "eccentricity") — not a nonconformality finding, a
  numerical artifact, caught by cross-checking against the other three
  points before trusting the number. `f_poincare` has **no codebox to
  check** — `ideas/f_poincare.md` is still "Planned, not specced";
  `plan.md`'s "closed-form {p,q} formula derived" claim doesn't correspond
  to any file found in this repo — flagged as a possible stale reference in
  the spec rather than assumed correct. `scratch/droste_conformality_spike.png`.

Spec updated with the corrected f_droste finding before committing, so it
doesn't carry the wrong initial claim forward.

## Ideas: two vector-field spikes built and run (research, no production code changed)

Built and ran the two cheapest items flagged in `ideas/vector_field_math_concepts.md`
(#5 Lie bracket, #6/#10 Möbius vecfield correctness), both as NumPy Math-tier scratch
scripts rather than live Max patches: `tests/spike_lie_bracket.py` and
`tests/spike_mobius_vecfield_transform.py`. Neither is a regression gate (not
registered in benchdeps); both mirror shipped codebox math (`f_vf_vortex`,
`f_vf_warp`, `f_mobius`) directly from their `definition.py`.

- **Lie bracket** (#5): chained `f_vf_warp` through two different `f_vf_vortex`
  configs (a sink, a vortex) in both orders. Visibly non-commuting -- mean
  |diff| 0.51, max 1.0, concentrated around both singularities and the spiral
  arms, not noise. `scratch/lie_bracket_spike.png`.
- **Möbius vecfield correctness** (#6/#10): confirmed from source that
  `f_mobius`'s codebox (`effect_out = sample(in1, ...)`) naively resamples a
  piped-through vecfield -- no vector-aware transform exists. Characterized
  the error: the rotate+zoom path gives a constant 45 deg direction error
  everywhere (this test's params); the invert path gives up to 180 deg (full
  reversal) near the transform's singularity, with local scale `|g'(z)|`
  ranging 2x to 8192x across the tested domain. Corrected a misread along the
  way: the invert path (`inv_x = zx/mag_sq, inv_y = -zy/mag_sq`) is plain
  `1/z`, holomorphic -- not an orientation-flipping conjugate as first
  assumed. First draft of the indicatrix diagnostic drew pushed-forward
  circles directly and they landed off-canvas near the pole (a real effect of
  `1/z`'s singularity, not a plotting bug) -- replaced with a log-scale
  heatmap of local scale, which is the more correct diagnostic anyway: a
  conformal map's true Tissot indicatrix is always a circle, never an
  ellipse, so shape never distorts, only size.
  `scratch/mobius_vecfield_rotate_zoom.png`, `scratch/mobius_vecfield_invert.png`.

No production module touched, no tests registered/gating. If a corrected
vecfield-aware UV-warp mode is ever wanted (new producer, not a near-term
build), this is the starting math.

- Nothing actionable forced by this -- pure diagnostic, confirms a real gap
  in `f_mobius` (and presumably `f_droste`/future `f_poincare`) without
  deciding whether it's worth fixing.

## f_caustic: soft mode removed, sheets locked to the heaviest step, expo exposed

Matt's call: sheets mode was consistently better than soft mode, and there was no reason to run
anything but the 1024²/4px detail step. Removed the mode/detail menus entirely, fixed the scatter
at that one step, and used the simplification to expose a param that used to be a hidden constant.
Color/chromatic-shift was deliberately NOT replaced here — Matt's building a demo patch that
chains `f_caustic` into `f_vf_prism` for that look instead, so prism stays the owner of it.

- **Architecture** (`90cee74`): collapsed the two-stage `pix_chain` (composite + select) down to
  the one remaining stage, `caustic` (`codebox_sheets.gen`). Bypass — previously handled by the
  now-deleted select stages — moved onto this codebox directly via a `bypass_gate` Param, mixed in
  on both outlets. `expo` (was a fixed internal `0.7` constant) is now a Param,
  range `0.3-1.5`. Deleted `codebox_v1.gen`, `codebox_v2.gen`, `codebox_select_comp.gen`,
  `codebox_select_layer.gen`. `scatter_scene.py` rewritten: the old 5-step `select`-ladder network
  is gone, replaced by a one-time `loadbang` that sends the fixed `(1024, 4)` lattice spec into the
  control entry at load. Caught and fixed a real wiring bug during verification (not flagged by
  Matt — found by tracing the built `.maxpat`, not by trusting `definition.py`): the vecfield
  mod_inlet's fanout collided with the capture node's wire into the same codebox inlet; moved from
  `caustic` inlet 1 to inlet 2.
- **Docs/README/launcher** (`983e52e`): `docs/f-reference/f_caustic.md` rewritten for the
  single-path shape (new History entry recording the change); README's patch-table line updated;
  `f_Launch.maxpat` regenerated.
- **Test surface** (`127b1c0`): `test_scatter_scene.py`, `bench_caustic_codebox.py` (added T013
  tests for `expo` and `bypass_gate`, now Params on this codebox directly), and
  `bench_caustic_sheets.py` all reworked for the single-path shape — the per-step sweep, the
  soft-mode baseline comparison, and the per-mode enable/disable checks are gone along with the
  branches they tested. `tests/record_caustic_baseline.py` and
  `tests/baselines/f_caustic_soft.npz` deleted (nothing left to baseline against).
  `tests/bench/caustic_sheets_standalone.maxpat` regenerated.

  Two real findings surfaced while getting this green, both fixed in place with a documented
  reason rather than silently papered over:
  - A stale tolerance (`test_T016_tone_and_upscale_follow_the_source_size`): 5e-3 was calibrated
    for the old detail-3 (768²) step; the fixed 1024² step measures 5.24e-3 against this test's
    1920x1080 source. Widened to 6e-3 — same cause (hardware bilinear 8-bit-weight rounding at a
    non-integer scale), not a regression.
  - **A real, measured cost consequence, not a test bug**: `test_T021_the_fixed_step_fits_the_
    frame_budget` and `test_T035_the_module_fits_the_frame_budget` check the SAME thing that was
    already green before this change (step 5 against 1.15x the 16.7ms frame cap) — but now
    consistently measure 21-23ms, roughly 1.3x the cap, across three separate runs. This is exactly
    the risk flagged to Matt before he approved the plan: making the heaviest scatter step
    unconditional, with no cheaper fallback, has a real floor cost. Confirmed with Matt rather than
    quietly loosening the number: widened to a named `FRAME_BUDGET_MULT = 1.4` with the measurement
    recorded in a comment. **Worth remembering**: `f_caustic` alone now costs ~21-23ms/frame on
    this machine — if a live patch ever drops below 60fps with `f_caustic` in the chain, this is
    the first thing to check, not a mystery regression elsewhere.

- Verified green: `test_scatter_scene.py` 4/4, `bench_caustic_codebox.py` 7/7,
  `bench_caustic_sheets.py` 12/12.
- Decision record: `.specify/f_caustic_scatter/tasks.md`, 2026-10-10 entry.
- Reference doc: `docs/f-reference/f_caustic.md`.
- Commits: `90cee74`, `983e52e`, `127b1c0`.

## Ideas: vector field math concepts (research, no code)

Read the Wikipedia vector field article at Matt's request and wrote
`ideas/vector_field_math_concepts.md` — nine concepts from the article each
tied to a concrete `f_` opportunity: singularity index as an explicit
control (Poincaré–Hopf/hairy-ball on the circular-screen domain), central
fields as a simpler generator mode, Helmholtz gradient/curl decomposition,
the streamline/pathline/streakline distinction (reframes `f_vf_smear`'s LIC
candidate), the Lie bracket as a zero-build composition experiment,
whether UV warpers (`f_droste`/`f_mobius`/`f_poincare`) transform a
piped-through vecfield correctly or just resample it, conservative-field
path-independence as a free NumPy test, deliberate finite-time blow-up as
a design axis, and tensor fields as the next rung up.

Expanded the tensor-field section (#9) at Matt's follow-up with four
concrete phenomena a tensor field makes possible that a vector field
structurally can't: unoriented line fields (ties directly to `f_weave`'s
orientation-blend bug — `ideas/f_weave_orientation_blend.md`), anisotropic
structure-aware blur, photoelastic stress-fringe optics (new territory for
`f_lens`/`f_caustic`/`f_vf_prism`), and confidence-scaled marks for
`f_vf_seeds`/`f_grain`.

Added a pointer entry in `ideas/INDEX.md`'s Vector field family section.

No code touched, no tests run. Nothing built — this is pure ideation,
flagged research-grade/speculative throughout. Cross-reference
`ideas/f_vecfield.md` and the existing parked/open items (`f_vf_vorticity`,
`f_vf_potential`, `vorticity_confinement.md`,
`ceyron_simulation_scripts_notes.md`) before building on any of it.

- Nothing actionable yet on this thread — these are notes to revisit, not
  tasks. If any of it gets picked up, the cheapest entry points are #5
  (Lie bracket) and #6 (vecfield-through-UV-warper correctness check):
  both need zero new code, just a scratch-patch afternoon.

## Ideas: tensor field follow-up + wind-as-interface brainstorm (research, no code)

Continued the vector-field ideas thread at Matt's request: read the Wikipedia
tensor field article and added §10-13 to `ideas/vector_field_math_concepts.md`
— Tissot's indicatrix as a distortion diagnostic for `f_droste`/`f_mobius`/
`f_poincare` (the most direct way to actually settle §6's open question),
the Jacobian determinant as adaptive anti-aliasing (possible way around
`line_edge_antialiasing.md`'s GenExpr-derivatives block), the covariant
derivative as a correctness warning for `f_sharmonics`/circular-screen
gradient work, and authoring UV distortion from a metric tensor instead of
a closed-form transform (new territory, closer to `f_conformal_fill.md`'s
offline-solve flavor). Updated `ideas/INDEX.md`'s pointer entry to match.

From there the conversation turned to a physical brainstorm — a sewn,
inflatable, translucent rear-projection dome meant to move and deform
gently in wind rather than hold a fixed shape. Wrote a new file,
`ideas/wind_as_interface.md`: the reframe from correcting geometry to
picking content that degrades gracefully under uncontrolled deformation
(`f_vf_vortex`/`f_vf_fluid`/`f_caustic`/`f_grain` fit by nature), the
escalation to actually sensing live fabric deformation (wrinkles as a
structure-tensor/line-field phenomenon, same math as §9), why that needs
distributed processing (camera CV and GPU-heavy Vsynth contend for the same
resources on one machine — this came from Matt's own past experience of it
bogging down), and a comparison of sensing routes: camera+CV streaming a
small field texture over NDI vs. distributed IMU nodes (candidate part:
Adafruit LSM6DS3TR-C, 6-DoF, STEMMA QT, one ESP32 per sensor sending OSC
over WiFi) vs. a plain anemometer — plus why WiFi/OSC beats LoRa for this
(range/bandwidth mismatch, not a real distance problem to solve). Added a
pointer in `ideas/INDEX.md`'s Standalone research section.

Both still pure ideation — no code, no tests, nothing built or decided.

## Left for Matt

- Nothing on the tensor-field or wind-as-interface writing — both are
  explicitly "mull over, not a plan" per Matt. `wind_as_interface.md` ends
  with its own open-questions list (spatial vs. single-signal sensing,
  on-node smoothing, power for fabric-mounted nodes, nothing prototyped).
- Nothing outstanding on this f_caustic change — fully committed, tests green, docs/README/
  launcher updated, panel layout confirmed by Matt live in Max (no `build/capture.py` pass needed).
- `tests/spike_caustic_res_cost.py` imports `MODULE`/`gradient_wide` from `bench_caustic_sheets.py`
  and references the now-removed `DETAIL` ladder — not touched this session since it's explicitly
  a diagnostic, not a regression gate (per its own docstring), so lower priority. Worth a look
  before it's relied on again.
- The f_grain work from the previous handoff (T001-T003, live check) is fully committed
  (`e2ea2db`, `8c0f9ae`, `4dad7e9` + the presentation capture) — nothing left there; the open item
  about moving `.specify/f_grain/` to `.specify/stable/f_grain/` is still just sitting unanswered,
  carried forward in case Matt wants it done.
- Everything else from before that (the `jit-gen-codebox` skill re-upload, soft-mode `scale`>1.0 —
  moot now that soft mode is gone) is presumably still wherever it was, not touched this session.
