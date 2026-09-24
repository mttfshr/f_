# HANDOFF

_Session: 2026-09-23_ (previous handoff, 2026-09-22 — test bench build — is in git history)

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
Work Queue item 11), and **Phases 0 and 1 are done** (T001–T022): the NumPy
mirror, the GPU/Vsynth feasibility experiments, and all seven stage codeboxes
proven on the bench. **No patcher yet** (Phase 2).

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

## Warnings for next session

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

**1. `f_vf_fluid` — Phase 2 of `.specify/f_vf_fluid/tasks.md` (T023–T034): build
the module.** Write `src/f_vf_fluid/definition.py` (metadata only) and
`build_fluid.py` (dedicated script; wiring in plan ADR-1/ADR-2: `r draw` bangs on
`adv`/`enc` inlet 0, force via `vs_inState` on inlet 1, `pass` feedback, Param
`bypass_gate` on `enc`), then the contract tests and module bench (T031a per-module
input size, T033a exactly-once-per-frame). Max was left running with both benches
open (`open -a Max tests/bench/bench.maxpat` / `bench_module.maxpat` relaunches
them; `bc.ping()` tells you if they're up). Running a long bench file through the
Desktop Commander tool can time out on the client side while the job keeps running;
run it in the background and read `tests/jobs/bench_last.log`. `scratch/run_subset.py`
runs chosen tests from `tests/bench_fluid.py`.

**2. `f_a_ripple` production UI polish** — unchanged: DSP done and confirmed by
ear; UI still plain flonums/toggles, not the `f_` convention.
`ideas/f_a_build_process.md` has the reuse analysis; then Phase 5 (docs/
helpfile).

**3. Definition drift cleanup** — decide, per module (`f_vf_warp`, `f_lens`,
`f_vf_fieldmap`, `f_vf_repulse`), whether to sync `definition.py` from the
patch or mark it archival and add to the never-regenerate list.

## Loose threads

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
