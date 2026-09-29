# HANDOFF

_Session: 2026-09-28_ — `f_vf_fluid` Phase 3, offline half. The 2026-09-24 handoff
(layout pass, drift survey, bypass work) follows unchanged below; 2026-09-23 is in git history.

## This session (2026-09-28): `f_vf_fluid` viscosity curve + force tap grid

Worked the offline half of thread 1. Two design decisions by Matt, both applied:
**(1)** `viscosity` means smoothing *independent of `dt`* (option B); **(2)** `taps` is a
**performable panel control**. Nothing is committed.

- **T036 viscosity (done).** Measured first: the old dial (ν 0–0.002, linear, codebox took
  physical ν) never reached "honey" (max m_c ≈ 16; m_c = 1/(2π√(ν·dt)) = the mode index that
  e-folds per frame) and `dt` also moved the smoothness. Now `viscosity` is a **0–1 dial** and
  `codebox_spec.gen` computes per-frame `nu_dt = 1.6e-3 · v³`; decay `exp(-(nu_dt·k² + drag·dt))`.
  Dial 1.0 → m_c ≈ 4; 0.5 → ≈ 11; 0.25 → ≈ 32; **default 0.085** reproduces the old default
  (ν·dt = 1e-6) so nothing shifts until tuned by eye. Mirror: `VISC_MAX`, `VISC_EXP`,
  `visc_to_nudt()`, `nudt_to_visc()` in `tests/fluid_mirror.py` (change shader and mirror
  together). **Saved `viscosity` values from before this change mean something different now.**
- **T038/T038a force filtering (done, tier 3 inconclusive).** Matt performs at **HD/4K**, so the
  force is minified 4–15× into the 256² grid. Study (`scratch/e4_force_alias.py`) and GPU
  measurements agree: hardware `sample()` is **nearest-like** when minifying; a single tap gives
  **6.0× (HD) / 11.6× (4K)** the noise of an exact area average. Fix: `codebox_adv.gen` averages a
  `taps × taps` grid of hardware taps at offsets in *normalised* coordinates (no source size
  needed). GPU noise gain, taps 1/4/8/16: HD 5.97/1.49/1.01/1.02, 4K 11.6/2.88/1.44/1.05. Cost of
  `adv` ≈ 0.05 (1 tap) / 0.4–0.7 (8) / 1.2–1.7 ms (16) → **default 8**, frame total 2.49 ms (budget
  3; 16 would give 3.3–4.4). Smooth forces (vortex/flow/repulse) are unchanged by design.
- **`taps` on the panel.** Int `live.numbox`, 1–16, default 8, row 2 slot 2
  (`definition.py` + `build_fluid.py` `TARGETS`; rebuilt: 49 boxes/lines, self-verified).
  Cosmetic: it displays "1.00" (float) although the shader floors the value; fix would be
  `parameter_type` 1 for int params in the shared `numbox_box` (affects other int params — check).
- **Checks:** mirror `tests/test_fluid_mirror.py` **22/22** (new: dial law, dt-independence, tap grid
  vs brute force, uniform force unchanged, HD aliasing; two new mutations caught); fluid bench
  `tests/bench_fluid.py` **12 tests** (spec vs mirror ≤ 2e-7 across the dial; 100 frames within 3e-6;
  tap grid on the GPU at HD and 4K; taps=1 reproduces the old shader; cost incl. tap grid);
  offline contract test **0 issues / 33 modules**.
- **Tier 3 result: nothing visible.** Matt saw no fps or visual difference between taps 1 and 16.
  Likely (not confirmed): force was `f_vf_repulse` (smooth); Fluid was set to an undamped,
  saturating state (dt ≈ 0 → drag·dt ≈ 0, Visc 0, Force 0.20, Gain 9.37, output pinned at the clamp);
  ~1.5 ms of a 16.7 ms vsync-locked frame can't move an fps counter. **Not run:** the module bench
  on the rebuilt patcher / a module-level check (noisy force, taps 1 vs 8) — needs Matt's patches
  closed. Re-test at Fluid defaults with `f_vf_optical_flow` as the force.
- **Docs updated:** `tasks.md` (T036 `[~]`, T038 `[x]`, T038a `[~]`, Findings rows), fluid `plan.md`
  (ADR-5 mapping, force-sampling paragraph), fluid `spec.md` (FR-005 clarification), project
  `.specify/plan.md` (item 11), `skills/jit-gen-codebox/SKILL.md` (three bench-verified facts, `f_` copy only).
- **Uncommitted from this session:** `src/f_vf_fluid/{codebox_adv,codebox_spec}.gen`, `definition.py`,
  `build_fluid.py`, `package/patchers/f_vf_fluid.maxpat`, `tests/{fluid_mirror,test_fluid_mirror,
  bench_fluid}.py`, the docs above, plus untracked `scratch/{e4_force_alias,measure_adv_taps}.py` and
  four `scratch/*.log` files. They overlap with the 09-24 layout-pass changes in the working tree. The
  viscosity and taps edits touch the same files, so one commit is simpler than splitting.

## Carried forward: definition/patch drift needs a tech-debt pass

Built the edit-view layout pass (`.specify/build_layout/`) this session and, in the
course of scoping "generated modules only" to a safe regen set, surveyed all 33
`src/*/definition.py` against their shipped patchers. **Only 10 are in sync**
(`f_ngon` plus the 9 now regenerated with the layout pass); **23 have drifted**:

- **9** (group B, `.specify/build_layout/tasks.md`): the *definition* is behind the
  patch — a param renamed/added by hand, a codebox edited, a panel resized
  (`f_vf_flow`, `f_weave`, `f_vf_advect`, `f_vf_warp`, `f_lens`, `f_vf_fieldmap`,
  `f_vf_repulse`, `f_vf_vorticity`, `f_vf_vortex_multi`).
- **10** (group C): predate the builder or are hand-built; definitions are
  after-the-fact transcriptions that don't match (`f_channel_grader`, `f_droste`,
  `f_grain`, `f_hue_processor`, `f_luma_processor`, `f_mobius`, `f_tone_curve`,
  `f_masonry`, `f_sirds`, `f_texrouter`).
- **3**: own build scripts, not compared (`f_util_profile`, `f_vf_fluid`, `f_vf_seeds`).
- **1**: `f_vf_vortex`, blocked on one decision (does its `r draw` box belong).

Matt: "this is much better and it's clear I need to do a lot of cleanup... we
probably should have a tech debt pass to bring everything current and resolve
diffs." **Not scheduled yet** — no tasks.md written for it. When it is: the
per-module classification and the diffing scripts already exist
(`scratch/regen_drift_semantic.py`, `regen_drift_props.py`,
`verify_regen_full.py`) and are the starting point, not `.specify/build_layout/`
itself, whose scope is the layout pass only.

## What happened

Worked **thread 0** from the last handoff: fix the module bugs the contract
tests found. All of them are fixed except two deliberate non-changes (below).
Both bench registries (`KNOWN` in `bench_modules.py`, `KNOWN_ISSUES` in
`test_module_contracts.py`) are now **empty**. Final state: live module bench
2/2 (0 unexpected issues, ~75 s), offline contract test 3/3.

### Bypass: investigation, decisions, three real bugs

- **Core Vsynth's convention is `enable`, not `bypass`.** 78 of 100 `vs_`
  modules open with `routepass enable jit_gl_texture jit_matrix`, which
  forwards `enable` to the pix's native `@enable` (stops rendering; no
  passthrough). Only `vs_pixelator` / `vs_pixelator_2` route a `bypass`
  message (→ a `live.toggle`). `docs/vsynth-reference/vocabulary.md` had
  said Kevin never uses `bypass`; corrected.
- **"`bypass 1` message works in only 9 modules" is NOT a defect.** The 9 are
  the oldest (`f_channel_grader`, `f_droste`, `f_grain`, `f_hue_processor`,
  `f_luma_processor`, `f_masonry`, `f_mobius`, `f_stereo`, `f_tone_curve`).
  The bypass *toggle* (jsui → `attrui @attr bypass` → pix) works in every
  module and is the supported path. **Decision: don't retrofit the message
  into generated modules' `route`.** Skill and bench wording corrected.
- **Fixed three real bugs** (all bench-verified):
  - `f_lens`: bypass attrui wasn't wired to `lens_halation` (tiltshift was
    removed on purpose, so the chain is two pix). One patchline added.
  - `f_sirds`: attrui wired to stages 1–12 but not stage 0. One patchline.
  - `f_vf_warp`: `out2` ignored bypass — see next section for the real cause.

### New finding: native `@bypass` flips secondary outlets

Under the native bypass attribute (what the toggle sets), the pix **skips the
shader**: outlet 1 passes input 0 through exactly, but **outlets 2+ output
input 0 vertically flipped** (exact `flipud`), and any `mix(..., bypass)` in
the codebox never runs. That's why `f_vf_warp`'s `out2` "changed direction"
when bypassed — and why the codebox `out1 = mix(..., bypass)` was dead code.

- `f_vf_warp` fixed by **not using native bypass**: codebox Param renamed
  `bypass_gate`, toggle wired `jsui → prepend param bypass_gate → pix`
  (attrui `obj-24` replaced by that `prepend`), both outlets
  `mix(warped_sample, sample(in1, uv), bypass_gate)`. Bench check added
  (`BYPASS_PASSTHROUGH_OUTLETS = {"f_vf_warp": (2,)}`).
- **11 other modules show the same flip** on outlets 2+: `f_caustic`,
  `f_chladni`, `f_grain`, `f_masonry`, `f_stipple`, `f_vf_advect`,
  `f_vf_chroma`, `f_vf_glow`, `f_vf_prism`, `f_vf_split`, `f_vf_streak`
  (`f_vf_optical_flow` / `f_vf_seeds` differ but aren't flipped). **Not fixed —
  Matt wants to eyeball each one.** Tracked as `.specify/plan.md` Work Queue
  item 10 with a per-module/per-outlet checklist. Isolated-layer outlets
  (glow/streak/prism/chroma/caustic) arguably shouldn't show the source at
  all when bypassed — per-module decision.
- Documented in `skills/vsynth-bpatcher/SKILL.md` ("Native bypass caveat")
  and `skills/jit-gen-codebox/SKILL.md` (Bench-Verified Facts).

### Other fixes

- **Gain dials** (`f_vf_fieldmap`, `f_vf_repulse`): dial fed `attrui strength`
  (pre-rename name); codebox has `Param gain`. Changed to `gain`; also the
  stale "Strength" label → "Gain" in both, and the stale `strength` entry in
  `f_vf_repulse`'s `parameters` block. Saved presets under `strength` won't
  load (they never worked).
- **`f_vf_fieldmap`**: removed invalid `@boundmode 1` from the pix box (only
  ever in the hand-edited patch; `sample()` clamps by default anyway).
- **`autopattr @varname X`** is invalid in Max 9. The name belongs in the box's
  `varname` property. Fixed in `f_mobius`, `f_stereo`, `f_masonry` (box text is
  now plain `autopattr`, `varname` = `<prefix>_autopattr`). Corrected the
  notation in `skills/vsynth-bpatcher/SKILL.md` (2 places) and `build/spec.md`.
  Older `.specify/stable/*` task lists still use the `@varname` shorthand
  (archival, left alone).
- **`f_masonry`** (hand-edited by script; never regenerate):
  - Route off-by-one from when `bypass` was inserted: `brick_seed` drove the
    `course_seed` numbox, the unmatched outlet drove `brick_seed`,
    `course_seed` went nowhere. Every route token now wires to the control of
    the same name.
  - **`quantize` removed** (E001p, decided 2026-07-05, finally applied): dial,
    label, attrui, the mod-matrix `prepend`/`focus` messages, route token,
    restore + `parameters` entries, the matrix `params` list entry,
    `masonry_toggle.js` names. Row 2 of the controls panel **reflowed to six
    columns** (regularity/drift/skip/phase/speed_var each shifted left one
    slot). **Layout is a visual guess — Matt to eyeball in Max.**
  - The edit was done with a small span-based JSON text editor (delete
    elements from the `boxes`/`lines` arrays, adjust route outlet indices,
    everything else byte-preserved). Untracked copy: `scratch/edit_masonry.py`
    — the `rebuild()` helper is a reusable pattern for surgical edits to the
    big hand-built patchers.
- **`hue_range.js`**: trailing global `calc()` called `outlet()` before the
  object's outlets existed ("bad outlet index", 3× per load). Removed; behavior
  unchanged (that call never produced output).

### Deliberately NOT changed (Matt, 2026-09-23: leave as is)

`f_vf_advect`, `f_vf_optical_flow`, `f_vf_seeds` keep GPU stages running while
bypassed ("bypass-leaves-active" in the bench). Their specs make this
deliberate: advect's feedback loop stays warm through bypass; seeds' ADR 8
gates bypass at the composite stage only; optical flow has per-stage bypass
Params. Bench now prints "(by design)"; parked in `plan.md`. Revisit only if
bypassed GPU cost matters live (optical flow: 5 of 8 stages; seeds: both
search stages) — that would loosen the "state stays warm" behavior, so it's a
design change, not a bug fix.

### Later same session: `f_vf_fluid` specced, planned, tasked

The fluid thread (thread 1 of the 9/22 handoff) moved from research to a
full spec set in `.specify/f_vf_fluid/` (`spec.md`, `plan.md`, `tasks.md`;
Work Queue item 11), and **Phases 0, 1 and 2 are done** (T001–T033a): the NumPy
mirror, the GPU/Vsynth feasibility experiments, all seven stage codeboxes proven
on the bench, and the **module itself** (`package/patchers/f_vf_fluid.maxpat`,
built by `src/f_vf_fluid/build_fluid.py`). T033 (parameters restore after save/reopen)
and T034 (smoke test in a real Vsynth patch) were **confirmed by Matt**, and he judged the
panel look good. Next: Phase 3 tuning.

- **Decided** (with Matt): a *new* module — a spectral (FFT) velocity solver
  that outputs an evolving vecfield; force vecfield in, velocity vecfield out.
  **No dye inside** — feed `f_vf_advect`/`f_vf_warp`/etc. Internal 256²
  (128² fallback), periodic boundaries, `project` 0–1 (0 = Burgers-like
  "rung 2" look, 1 = divergence-free), output `gain` + clamp under the
  `f_vecfield` contract.
- **Plan highlights**: 8-stage `jit.gl.pix` chain (`pass → adv → fx → fy →
  spec → iy → ix → enc`, `ix → pass` feedback); only the solver stages are
  256² — the encode stage runs at **render resolution**, so consumers and the
  module bench see an ordinary render-size vecfield; periodic self-advection
  via a manual 4-tap bilinear (E-seam experiment to confirm); Nyquist bins
  zeroed in the spectral operators (the old `pass_spectral` mirror doesn't do
  this); **bypass is a Param gate on `enc` (`bypass_gate`), not native
  `@bypass`**, passing the force through (or neutral when unconnected) while
  the solver stays warm; dedicated `build_fluid.py` (like `build_advect.py`),
  not a `build_patcher.py` schema extension.
- **Multi-frame bench caveat**: the bench drives one codebox at a time, so the
  100-frame whole-chain check is host-sequenced from Python (plan ADR-10).
- **Phase 0 results** (details in the `tasks.md` Findings table):
  - `tests/fluid_mirror.py` + `tests/test_fluid_mirror.py`: 16/16, five
    mutations caught; Taylor–Green amplitude error at frame 100 is 0.85% at
    N=256 (3.5% at N=64).
  - A `@adapt 0 @dim 256 256` pix **works inside Vsynth's render context**
    (`tests/fluid_feasibility.py` runs a generated scratch module through the
    module bench and deletes it afterwards).
  - **Plan changed**: a render-res stage that adapts to the force texture is
    1×1 when the inlet is unconnected (`vs_black`); `adv` and `enc` are now
    triggered by `r draw` bangs on inlet 0 (force = codebox `in2`, state/velocity
    = `in3`), so `enc` takes the render-context size (512² in the bench) and the
    solver runs every frame.
  - **All interpolation is manual 4-tap** (hardware `sample()` clamps at the
    seam, has 8-bit weights, and is nearest-like when minifying); **NaN guard is
    `switch(abs(x) < 1e30, x, 0)`** (`NaN == NaN` is TRUE on this GPU).
  - A `Param` loop bound works for the DFT (N=128, 64), so runtime resolution is
    possible later; cost unmeasured.
  - New tasks T031a (per-module bench input size: context is 512², bench feeds
    64²) and T033a (solver advances exactly once per frame; hot/cold inlets).
- **Phase 1 results** (`tests/bench_fluid.py`, 9/9, ~6 min; codeboxes in
  `src/f_vf_fluid/`, DFTs generated by `gen_dft.py`):
  - Every stage matches the mirror at float precision (spec 2e-7, adv 6.5e-7,
    enc ≤ 9.4e-6, forward DFT 1e-7 vs `np.fft2`); 100 host-sequenced GPU frames
    track the mirror to 3.1e-6; GPU Taylor–Green decay 0.85% off analytic at
    frame 100; cost 2.4–2.8 ms/frame at 256² (budget 3 ms; DFTs are ~2.1–2.5 ms).
  - **GenExpr quirk found:** a unary minus before a parenthesis mis-parses
    (`-(a + b) * c`); write `0 - (a + b) * c`. It was silently making decay wrong.
  - A codebox cannot read an input texture's size (no `texdim`), so the *force* is
    read with hardware `sample()` (nearest-like when minifying — harmless for a
    smooth force; E4/tier 3 may add prefiltering). Velocity reads are manual
    periodic 4-tap.
  - New facts are in the `jit-gen-codebox` skill (f_ copy) and the tasks.md Findings.
- **Phase 2 results:**
  - `build_fluid.py` (imports shared chrome from `build/build_patcher.py`, reads UI
    params from `definition.py`, self-verifies) → 46 boxes / 46 lines, 8 `#0_`-scoped
    pix. Live module bench: **33 modules, 0 unexpected issues**; the module loads
    first try inside `vs_render` and every param reaches the right stage (`dt` reaches
    both `adv` and `spec`).
  - `tests/bench_fluid_module.py` 3/3: the solver advances **exactly once per frame**
    (1.000000), two instances are independent (unconnected one exactly neutral), fresh
    load is exactly neutral at render size.
  - **Bug found and fixed:** `vs_black` is all ZEROS (decoded −1; the contract doc
    wrongly said 0.5 — corrected) and `vs_inState`'s connected flag lags ~180 ms at
    load/disconnect, so the solver injected a −1 force for ~10 frames and kept a
    phantom velocity (~−0.1 uniform). Fixed by a content check in `adv` and `enc`:
    a real vecfield has B = 0.5, `vs_black` B = 0. Caveat added to the
    `vsynth-bpatcher` skill; other state-holding modules could have the same issue.
  - `f_vf_fluid` is a **hand-built module**: the script is the source of truth; once
    hand-edited, add it to the never-regenerate list. The bench's module-input size for
    it is 512 (`INPUT_SIZE` in `tests/bench_modules.py`) because the render context is
    512² and `enc` follows the context.
  - Confirmed by Matt in Max: T033, T034 and the panel look (6 dials, 190×150). Ranges
    and defaults are still provisional (Phase 3).

## Warnings for next session

- **The bench keeps a `Param`'s last value between jobs.** A job that omits a Param inherits the
  previous job's value, not the codebox default; pin every Param a measurement depends on (a cost
  test measured `taps=16` and briefly reported a bogus 4.35 ms frame). Recorded in the skill.
- **`f_vf_fluid` is script-built** (`src/f_vf_fluid/build_fluid.py` is the source of truth), the
  patcher was regenerated twice this session and is still safe to regenerate; once it is hand-edited
  it joins the never-regenerate list.
- **Definitions have drifted from the shipped patchers — do not regenerate**
  `f_vf_warp`, `f_lens`, `f_vf_fieldmap`, `f_vf_repulse`. A dry-run rebuild
  rewrote whole files: `f_vf_warp` (`strength` default 0.1 in patch vs 0.0 in
  definition, label/comment styling), `f_lens` (definition still builds the
  removed tiltshift), `f_vf_fieldmap` (inlet counts, rects), `f_vf_repulse`
  (codebox and labels differ). `plan.md`'s never-regenerate list now has
  `f_vf_warp` and `f_lens`. **Open decision: add `f_vf_fieldmap` and
  `f_vf_repulse` too**, or sync their definitions from the patches.
  `f_vf_warp`'s `definition.py` carries a "DO NOT REGENERATE" comment.
- **Before trusting a regen**: `build/py.sh build/build_patcher.py
  src/<m>/definition.py && git diff -w --stat -- package/patchers/<m>.maxpat`;
  `git checkout --` the file afterwards if the diff isn't tiny.
- **Module bench "name already in use" errors** (`ob3d does not allow multiple
  bindings`) mean another open patch — or stale bench state — already holds
  modules with fixed `@name`s (caustic, lens, fieldmap, vortex, …). Close every
  other patch and reopen `bench_module.maxpat` before running. Cost me two
  false-alarm runs (108 BADs) this session.
- Tooling: with Desktop Commander, scripts must live under an allowed path
  (`/tmp` is not allowed; `scratch/` is). `create_file` writes to Claude's own
  container, not the Mac.
- Everything from this session is committed, including
  `scratch/edit_masonry.py` and the `f_vf_fluid` spec/plan/tasks.

## Next session — start here

Pick one:

**0. Work Queue item 10 — the 11 flipped secondary outlets.** Matt eyeballs each
module's bypassed outlets in a real Vsynth patch, decides the bypassed state
(source / black / unchanged / leave), then fix using the `f_vf_warp` recipe
(drive a non-`bypass` Param; hand-edit). Extend `BYPASS_PASSTHROUGH_OUTLETS`
only for outlets whose intended state is "equals input".

**1. `f_vf_fluid` — Phase 3 (T035–T042), what is left.** The offline half is done (see
"This session"). Left, all by eye and Matt's: tuning patch (T035), `project` 0 vs 1 (T037),
ranges/defaults for `force`, `dt`, `drag`, `gain` and the `viscosity` default now that the dial
means something new (T036, rest), edge cases (T039), 10-minute soak (T040), cost/fps in a real
patch (T041), final verdict (T042). **Start the tuning from Fluid's defaults** (Force 0.02,
dt 0.01, Visc 0.085, Drag 0.5, Gain 1.0, Taps 8): extreme settings can saturate the output
(drag is `drag·dt`, so it does nothing at dt ≈ 0) and hide everything. To judge `taps`, use a
*noisy* force (`f_vf_optical_flow` on video) — smooth forces don't change. Claude-side leftovers:
run the module bench on the rebuilt patcher and add a module-level noisy-force check
(`bench_fluid_module.py`; needs Matt's other patches closed, the stage bench in Max is currently
open). Operational: `open -a Max tests/bench/bench.maxpat` / `bench_module.maxpat` relaunches the
benches and `bc.ping()` tells you if they're up; run long bench files in the background
(`nohup uv run --no-project --with numpy python3 -u ...`) and poll the log, since the Desktop
Commander client can time out while the job keeps running; `scratch/run_subset.py <test names>`
runs chosen tests from `tests/bench_fluid.py`; `scratch/run_module.py <name>` runs one module
through the live module bench.

**2. `f_a_ripple` production UI polish** — unchanged: DSP done and confirmed by
ear; UI still plain flonums/toggles, not the `f_` convention.
`ideas/f_a_build_process.md` has the reuse analysis; then Phase 5 (docs/
helpfile).

**3. Definition drift cleanup** — decide, per module (`f_vf_warp`, `f_lens`,
`f_vf_fieldmap`, `f_vf_repulse`), whether to sync `definition.py` from the
patch or mark it archival and add to the never-regenerate list.

## Loose threads

- **Skill copies diverged further:** this session's three bench-verified facts (nearest-like
  minification, nested `for` with an expression bound, bench Param persistence) went into the
  `f_` copy of `jit-gen-codebox` only, like the native-bypass bullet last session.
- **`taps` numbox shows "1.00"** — see "This session"; cosmetic, shared-builder change if done.
- **Two `jit-gen-codebox` skill copies have diverged both ways** (`f_` and
  `claude-scaffold`). This session added the native-bypass bullet to the `f_`
  copy only. The claude.ai upload is a third copy — reconcile, then re-upload.
- **Library-level, still uncounted:** any module whose pix uses a fixed `@name`
  (not `#0_`) can't exist twice in one Max session — e.g. two Glows in one
  Vsynth patch.
- **Open, uninvestigated:** loading ~30 modules into one bench session
  scrambled other modules' dial `_parameter_range` (suspect `range_tiers`
  modules); a fresh session per module fixes it for testing.
- **Bench intermittent:** one unexplained `ERROR` in
  `bench_control.py::test_frames_arrive_during_job` (first Phase 4 run only).
  `tests/jobs/bench_last.log` keeps full output.
- `bench_src` (identity pix before slot 1) kept but not proven necessary.
- Other tools could use the bench: re-verifying the UNVERIFIED
  `f_vf_vorticity`, tracing `f_apollonian`'s `debug_ok`.
- `f_droste` still lacks `autopattr` (plan.md Parked) — the fix is now known:
  plain `autopattr` box with `varname` `droste_autopattr`.
