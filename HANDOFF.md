# HANDOFF

_Session: 2026-10-01_ — Package structure and Package Manager readiness, after Kevin
Kripper (Vsynth's author) had trouble opening some patches. **All of it is committed**
(`8af4c71`, a single commit titled "cleanup", then `2e014c7` removing `moduleSize.js`).
The undone work is tracked in `.specify/packaging/tasks.md`. The 2026-09-29c entry follows
unchanged.

## This session (2026-10-01): packaging

Full research and reasoning: `docs/max-reference/packaging.md`. Summary:

- **Cause of Kevin's trouble: not confirmed.** Leading candidate: the repo root is not the
  package root, so `git clone` into `Packages/` leaves Max with no `patchers/` or
  `package-info.json` at the top level. Checked and ruled out: no hardcoded `/Users/...`
  paths, no unresolved dependencies (`vz.bfgener8r` is in Max's bundled Vizzie package).
- **Layout decision (Matt): keep `package/` as a subfolder and ship a release zip** (not
  restructure the repo root). Option B (repo root = package root, as av-toolbox does) is
  still available if the registry wants it; it would need `docs/` renamed (reserved Max
  folder name), every `package/...` path rewritten, and the symlink moved.
- **`package/package-info.json`:** `display_name` to `displayname`, `max_version_required`
  to `max_version_min` `9.0.0` (kept at Matt's call; **unverified on 9.0.x**, all patches
  were saved in 9.1.4), `max_version_max`, `website`, Vsynth named in `description`. No `os`,
  no `homepatcher` (the only candidate is the menu bpatcher).
- **`demos/` to `package/examples/`**, all 16 demos and 11 presets prefixed `f_demo_`
  (`git mv`). Each patch differs from its original by one line (the `autorestore`
  key); presets are byte-identical. Repaired stale `autorestore` names: `chladni`/`repulse`
  pointed at non-existent `*-scratch.json`; `weave-advect` loaded `seeds2.json`; `general`
  has no preset so its `autorestore` was removed. **Unverified in Max:** the renamed demos
  open cleanly, and how Max treats a missing `autorestore` file. Max needs a restart to see
  the new folder.
- **`package/readme.md`** written (license section says "Not yet specified").
- **`build/release.sh`** (+ `dist/` in `.gitignore`): zips the committed state of `package/`
  into `dist/f_-<version>[-dev].zip` with a top-level `f_/`; `--working-tree` for test
  builds (`-wip`). Tested: default, working-tree, tag mismatch, bad flag. Not tested:
  installing a zip into Max. No tag or GitHub release exists yet.
- **README** install section rewritten (zip for users, symlink for developers, do not clone
  into Packages); Repo Structure lines updated.
- Doc paths fixed: `.specify/demos/spec.md`, `ideas/walkthrough_and_capture.md`,
  `skills/vsynth-bpatcher/SKILL.md`. **`./skills/check.sh` now reports `vsynth-bpatcher`
  STALE: re-upload it, then `./skills/check.sh stamp`.**
- **Caution:** `~/Documents/Max 9/Packages/f_` is a symlink to this repo's `package/`.
  Never unzip a release there; it writes into the working tree.

### `moduleSize.js`: removed

`package/javascript/moduleSize.js` was byte-identical to Vsynth's, and with both installed Max
warned about duplicate files. A first delete gave `js: can't find file moduleSize.js` (most
likely a stale cache, not confirmed); after a restart test **Matt reports the deletion is safe
(as reported, not observed by Claude)**, so the copy is removed and `package/readme.md` no
longer credits it. Patchers and `build/build_patcher.py` are unchanged: the box still says
`js moduleSize.js` and Max now resolves Vsynth's copy. Last present in commit `8af4c71`.

### Parked: console error `patcher: doesn't understand "getattr"`

Appears with `moduleSize.js` present or absent, so it is not caused by the deletion test. The
moduleSize chain is `loadbang` to `getattr presentation_rect` to `thispatcher` to `zl slice 2`
to `prepend tam` to `js moduleSize.js`; Vsynth's `vs_displacement` has the same message, so it
is Kevin's convention that `build_patcher.py` copies. Cause unknown. First test: open
`vs_displacement.maxpat` directly and see whether it raises the same error (baseline). Matt
parked this ("troubleshoot separately").

### Next step

Open the renamed demos in Max (T008: `f_demo_chladni`, `f_demo_repulse`, `f_demo_general`, one
preset-less demo) and read the console; then relay Kevin's answers (T011/T012). The first tag
(`v0.1.0`) is blocked on the license and the icon.

### Outstanding

The full list, with owners and blockers, is `.specify/packaging/tasks.md` (T008 to T020). In
short: verify the renamed demos and a release-zip install in Max; ask Kevin (how he installed
it, Max and Vsynth versions, first console error, the license question); choose a license;
make `icon.png`; read the Cycling '74 submission form; tag and release `v0.1.0`; a few small
decisions (`prism-masonry`/`streak` presets, `help/streak-demo.json`). **Not confirmed: that
the old install layout was the cause of Kevin's trouble.** `max_version_min` 9.0.0 is
unverified.

### Loose threads

- The `getattr` console error is parked (T019); it is independent of `moduleSize.js`.
- Commit hygiene: `8af4c71` ("cleanup") bundled the whole packaging session, and also swept
  in `ideas/f_vf_emulsion.md`, which was not created this session; `2e014c7` is "rm
  modulesize.js". History was not rewritten.
- The README's `build/` line says helpfile generation is "via Claude API", but `plan.md` says
  `generate_helpfiles.py` no longer calls the API (T018; script not opened, so unverified).
- No release zip has ever been installed into Max, and the Windows install line in the README
  is untested (T009).
- `skills/check.sh` reported all uploads current at the end of the session.

---

_Session: 2026-09-29c_ — `f_vf_fluid` Phase 3 closed (Matt's by-eye calls) and Phase 4
(docs and integration) done, regression green. The 2026-09-29b entry
(skills consolidation) follows, then 2026-09-29a / 2026-09-28 unchanged; 2026-09-23 is
in git history.

## This session (2026-09-29c): `f_vf_fluid` Phase 3 closed, Phase 4 done

Every step committed with a clean tree (`3179cdd`, `4ef8459`, `1fcd0f6`, `a5f4184`,
`8f98636`, `ec2af07`, `38a13ea`, `d615cd1`, `3ac365b`, `9d4f23c`, `3d16918`, and the
commit that records the live bench result). Task-level detail and Findings are in
`.specify/f_vf_fluid/tasks.md`.

### Phase 3 (all Matt's calls, by eye in Vsynth)

- **T041 cost: 256² stays.** At 3840×2160 the tuning patch with four parallel consumer
  chains ran ~42 fps; one chain with Fluid held 59–60. Fluid is in both, so the overrun
  is the extra consumers. **The handoff's planned method was wrong and was dropped:**
  fps with bypass on vs off cannot measure the solver, because `bypass_gate` gates only
  `enc` and the solver stays warm by design (ADR-8); and at vsync a ~2.5 ms cost is
  invisible until the frame overruns. The real margin is unmeasured (59–60 is the ceiling).
- **T036 passes as is:** `dt` 0.01, `force` 0.02, `drag` 0.5, `gain` 1.0, `viscosity`
  0.085. Ranges were not judged separately. No regeneration.
- **T037 `project`: left as is** (on the panel, default 1). Matt could not tell 0 from 1
  on the force he tried. That is expected on solenoidal forces (the projection only
  removes the curl-free part), so it is not evidence of a wiring fault. **Not tried:** a
  compressive force (vortex with `convergence`, or `f_vf_repulse`). If `project` ever
  looks dead there, check that the tuning patch's RESET box doesn't also send `project`.
- **T039 pass:** the uniform-force case is covered offline (mirror, 10,000 frames);
  disconnect and resize were **not run** (reasoned safe: they share the `vs_black`
  content gate already confirmed at fresh load, and solver state is in fixed 256²
  textures). **T040 soak skipped. T042 pass.**

### Phase 4

- **T043–T045:** `docs/f-reference/f_vf_fluid.md` (new), a row each in the producers table
  (`f_vecfield_type.md`) and `module-inventory.md`, and a README row. Claims not yet
  observed are marked as such in the doc. `f_vecfield_type.md`'s producers table was
  **already incomplete** (5 modules; omits `f_vf_flow`, `f_vf_repulse`,
  `f_vf_optical_flow`, `f_vf_seeds`, …): only Fluid's row was added.
- **T046 helpfile** `package/help/f_vf_fluid.maxhelp`, built by copying box attributes
  from the optical-flow and droste helpfiles. Chain: `vs_sources_main` →
  `f_vf_optical_flow` (force) → `f_vf_fluid` → `vs_preview`, plus an unwired "try feeding
  into `f_vf_advect` / `f_vf_warp` / `f_vf_glow`" note. **References name no source
  implementation, because the spec and plan record none** (Taylor & Green 1937 is cited
  as verification only). If you worked from a published source, add it to both the doc
  and the helpfile. The skill also required a `## References` section in the doc; added.
- **T047 menu:** slot 5, **∇ Processors** (Matt's call), appended **last** (menu values are
  stored by index, so a mid-list insert would shift what saved states load); `parameter_mmax`
  9 → 10 in both menus; `VECFIELD_MODULES` updated. `f_addmod.js` also needed a `vf_fluid`
  size entry (190×150).
- **Found while doing T047, fixed with Matt's confirmation:** the `f_addmod.js` size table
  had drifted from the panel rects. `vf_advect` 190×130 → 190×150 (it was cropping 20 px),
  then `caustic` (→227×100), `lens` (→231×156), `vf_chroma` (→190×180), `vf_fieldmap`
  (→150×88), `weave` (→220×159), all previously *smaller* than their panels.
  **Not changed at that point:** `chladni` (table 299×234, panel 227×164) and `vf_seeds`
  (table 190×175, panel 190×160, content out to 205 px), which are larger than their
  panels. `vf_seeds` was cropped and was fixed after Matt's check (see Outstanding);
  `chladni` is a separate problem (it does not appear at all); and content sticking out past the panel on `vf_optical_flow`, `vf_split`,
  `vf_warp` and `vf_fieldmap`, which is a design question and not a stale number.
- **T048:** the four build-schema gaps (inlet fan-out through `vs_inState`, per-node
  `@dim`/`@adapt 0`, multi-stage param targets, Param-based bypass) are Gaps 3–6 in
  `ideas/build_patcher_schema_gaps.md`, with the workaround `build_fluid.py` uses and a
  candidate fix for each; **none attempted**. Gap 6 is the same mechanism as plan Work Queue
  item 10 (flipped secondary outlets), so a schema-level Param bypass would serve both.
- **T049:** plan Work Queue item 11 updated. **`f_vf_fluid` is not on the never-regenerate
  list:** `build_fluid.py` reproduces the committed patcher byte for byte, so it has not
  been hand-edited since its last build. (If plan item 12's T017, adopting the layout pass
  in `build_fluid.py`, is done, regeneration will change `patching_rect` values.)
- **T050 regression green.** Offline: `tests/run.sh` passes all 7 files (fluid mirror
  22/22, module contracts 3/3, 33 modules, 0 unexpected issues); `KNOWN_ISSUES` and
  `KNOWN` are both empty. Live: `tests/bench.sh` first exited 2 (Max not open), then Matt
  opened `tests/bench/bench.maxpat` and **reported the tests pass; I did not see that
  output.** The Phase 4 checkpoint is met.
- Gotcha for next time: `build/extract_params.py --all` (the T046 state check) **rewrites
  the tracked `build/helpfile_queue.json`** with ~2,100 lines of pending entries for other
  modules. I restored it and did not commit it.

### Outstanding, Matt's

None of these is covered by any test, so they are manual Max checks.

1. **`f_chladni` does not appear when added from the `f_modules` menu. Parked by Matt
   ("come back to chladni"); not diagnosed.** What is established: only one
   `f_chladni.maxpat` exists (nothing shadows it); its dependencies (`moduleSize.js`,
   `bypass_toggle.js`) exist; the contract tests and live bench load it fine; this
   session's changes did not touch it (the `f_modules.maxpat` diff is slot 5 only, and
   the `chladni` entry in `f_addmod.js` is unchanged); the file was saved in Max after
   its last generation (Max's compact JSON layout), so it has been hand-edited. **Not
   known: whether it ever worked from the menu.** **Update: picking it gives an empty
   rectangle, so something fires and a bpatcher is created. That does NOT refute the
   single-item-menu hypothesis (I wrongly said it did): the menu could fire with a wrong
   symbol, and `addmod` would still create a bpatcher, then fail to find
   `f_<wrong>.maxpat` and leave it empty. Matt's view is that the single item is the
   cause.** The rectangle's size tells the cases apart: **200×150** is the `SIZES`
   fallback, so `addmod` got an unrecognised name (the menu sent a wrong symbol: the
   single-item hypothesis); **299×234** is the `chladni` table entry, so the name was
   right and the file failed to load. Also checked and clean: the Max package `f_` is a symlink to the repo's `package/`, so Max reads the
   repo file; `f_chladni.maxpat` has no duplicate ids or dangling wires (the same checks
   pass for `f_vf_advect`, `f_vf_fluid`, `caustic`); its presentation content sits at the
   origin like the working modules (panel 227×164, min x −8), so it is not an offset; its
   appversion matches (9.1.4). **Next step: the size of the empty rectangle (above); if it
   is 299×234, the Max console (Cmd-M) after adding Chladni, whose first error line
   should say why.** Also cheap: drop a bpatcher by
   hand pointing at `f_chladni.maxpat`. If that works too, the menu path is at fault; if
   it is also empty, the file is.
   **Fix options if it turns out to be the menu (not started; discuss before building):**
   (1) make `addmod` take the module from the menu's **index** instead of its symbol, for
   slot 0 only (small, but slot 0 becomes a special case); (2) give slot 0 a second item
   so it is an ordinary multi-item menu (needs a real second module; the obvious
   candidate, `f_chladni_audio`, has no reference doc and is unverified, so do not add it
   untested; appending keeps saved indices stable). **Matt asked to drop this for now
   (2026-09-29): do not raise it unprompted.**


Resolved this session: `f_vf_fluid.maxhelp` (built by script) was opened in Max by Matt, who
reports the layout check passes. After Matt's menu check: all the `f_addmod.js` sizes he tried look right
except `vf_seeds`, which was still cropped; fixed (`c0a0a71`, 190×205). Its three
bottom dials (`size_mod`, `stretch_mod`, `color_mode`) sit at y 162–205, below the 160 px
panel; extending the panel to match is a small module-design tidy, not done.

Not started and unchanged: plan Work Queue item 10 (flipped secondary outlets, 11 modules).
Optional: bring the `f_vecfield_type.md` producers table up to date; test `project` on a
compressive force.

---

## Earlier session (2026-09-29b): skills consolidation closed

Both repos committed and clean (`f_` `71a520d`, `claude-scaffold` `82fd11f`). **The earlier
entries' "Nothing is committed" is stale** — that work went in as `97d2c5d` / `8b81ccb` /
`0dac1a8` before this session.

Closed both pieces carried from the previous session.

- **Piece 1 — the three remaining scaffold-only Max skills: all three moved** into
  `f_/skills/`, `claude-scaffold/skills/` symlinks back. Eight skills, eight symlinks,
  all verified resolving.
  - **The dividing line, decided:** *domain knowledge* (Max/Vsynth/audio DSP) lives in
    `f_/skills/`; *generic workflow/process scaffolding* stays in claude-scaffold. The
    handoff's proposed framing — this-repo conventions vs. all Max knowledge — doesn't
    survive reading the files: all three name f_ modules in their own descriptions
    (`max-advanced-object-methodology` exists because of `f_a_ripple` T7a,
    `pfft-spectral-processing` is written for `f_a_decorrelate`, `maxpat-json-authoring`
    for `f_a_` scratch work), so "f_-specific vs. generic Max" was never the cut that
    separated them.
  - What this buys: **the upload rule is now "everything in `f_/skills/`"**, no
    per-skill judgement call.
  - Also caught: last session's five symlinks had **never been committed** in
    claude-scaffold. All eight are now committed as mode-120000 symlinks.
- **Piece 2 — upload staleness: hole closed, uploads still outstanding.** Measured from
  inside a claude.ai session (the uploaded copies are readable there, so this is fact,
  not estimate):

  | skill | uploaded | on disk |
  |---|---|---|
  | `jit-gen-codebox` | 390 | **848** |
  | `vsynth-bpatcher` | 678 | **1010** |
  | `f-helpfile` | 246 | **297** |
  | `max-patch-notation` | 182 | 182 ✓ (hash-identical) |
  | `gen-tilde-codebox` | — | 483 (never uploaded) |

  The uploaded `jit-gen-codebox` is **under half** the reconciled one — it predates the
  entire fluid thread. Any session working from the uploads has been running without the
  last three sessions' findings.
  - **`skills/check.sh` + `skills/MANIFEST.md`.** Chose a hash manifest over a date line
    (a date needs remembering to bump; a hash is generated). **Key semantic:** the
    manifest records the last-**uploaded** state, not current disk state — a hash taken
    at edit time always matches and tells you nothing. `./skills/check.sh` reports drift;
    `./skills/check.sh stamp` rewrites the manifest and is run **immediately after
    uploading**. Both paths tested; no dependencies beyond `shasum`/`awk`.
  - `MANIFEST.md` is **seeded with hashes of the actually-uploaded copies**, so its first
    run reports real drift rather than a false all-clear. Current output: **7 of 8 need
    upload** (`max-patch-notation` is the only one in sync, and its hash matched
    byte-for-byte across container and disk — which cross-validates the seeding method).

### ~~Outstanding, Matt's: re-upload seven skills, then stamp~~ — DONE

Matt re-uploaded and ran `./skills/check.sh stamp` the same day (`3cb0bee`); `check.sh`
now reports all eight skills current. The original wording follows for the record.

Everything except `max-patch-notation`. Run `./skills/check.sh` for the list, upload, then
`./skills/check.sh stamp`. Until stamped, the manifest correctly keeps reporting drift.

Worth doing before the next codebox session specifically — `jit-gen-codebox` is the stale
one that matters most.

---

_Session: 2026-09-29a_ — `f_vf_fluid` Phase 3: bench block closed, `taps` off the panel,
tuning patch built.

## Earlier session (2026-09-29a): bench block, `taps` decision, T035 tuning patch

_(Committed as `8b81ccb` / `0dac1a8`; the "nothing is committed" note below is stale.)_

- **Bench block, all green.** Module bench on the rebuilt patcher: `f_vf_fluid` 0 issues,
  8 pix, every param on its stage. `tests/bench_fluid_module.py` **3/3**. Full live
  regression **33 modules, 0 unexpected issues**, both `KNOWN` registries still empty —
  so the uncommitted layout-pass regens haven't broken anything either. Offline contract
  test **3/3**.
- **`taps` is off the panel (T038a closed).** Matt's call, and the right one: the GPU
  study had already settled the default, a module-level re-test would only have confirmed
  through the patcher what the stage bench proved, and it still couldn't reach 4K (bench
  context 512²; a 4K force matrix is ~236 MB over jxf). More fundamentally `taps` fails
  the bar for a panel control — nothing on smooth forces by design, and on noisy ones it
  only removes noise, so there's no expressive range to perform.
  - `"ui": False` on the param in `definition.py`. **Route token kept**, widget and label
    gone. `Param taps(8)` in `codebox_adv.gen` is what governs now — checked, since with
    no widget nothing sends a value at load.
  - `build_fluid.py` now splits **`routed`** (route tokens, drives the obj-id indices)
    from **`panel`** (widgets). Non-UI params wire route → attrui directly and carry a
    `varname` so `verify()`'s token check still matches. Rebuilt **47 boxes / 48 lines**
    (was 49/49), self-verified, JSON valid.
  - Side effect worth knowing: the live bench can no longer range-scale `taps` (no widget
    to read `parameter_range` from) so it sends a raw fraction — wiring checked, range not.
  - The cosmetic "1.00" numbox display is gone with the numbox.
- **T035 done: `~/Vsynth/patterns/fluid_tuning.maxpat`**, generated by
  `scratch/build_fluid_tuning.py` (42 boxes, 33 lines, self-verifying). Four force sources
  → `switch 4` → Fluid → advect/warp/glow/split → `switch 5` → `vs_output`. Video from
  `vs_sources_main.maxpat` (movie tab) — the only noisy force, and the only one that can
  make `taps` visible. `vs_render` already carries `jit.fpsgui` and routes `dim`, so the
  HD/4K switch is three message boxes. Message boxes into Fluid: RESET-to-defaults,
  `taps 1/8/16`, `project 0./1.`.
- **Skills — two new entries** (written to `f_`, which is now the single source; see the
  reconciliation bullet below).
  `jit-gen-codebox`: "a fixed-`@dim` stage is a resampler, whether you meant it to be or
  not" — the generalisation beyond fluid, since any internal fixed-resolution stage
  minifies its inputs 4–15× at HD/4K and no `texdim` exists to warn you.
  `vsynth-bpatcher`: "Not every parameter earns a panel slot", with the `"ui": False`
  recipe.
- **Phase 3 reordered** to **T041 (cost) → T037 (`project`) → T036 rest → T039/T040 →
  T042.** Cost first: a fallback to 128² would invalidate anything tuned at 256².

- **Skills: all copies reconciled and single-sourced (2026-09-29).** `f_/skills/` is now
  the one source of truth; `claude-scaffold/skills/` symlinks into it for all five.
  - `f-helpfile` and `vsynth-bpatcher` were **already symlinks** — the "three diverged
    copies" loose thread was overstated for those two.
  - `jit-gen-codebox` had genuinely diverged **both ways**, and the `f_` copy was the
    worse one: it was missing the **`Param` named after a built-in operator (`mix`)**
    finding — the reason `mix_pct` exists library-wide, cited by `.specify/plan.md`
    item 1 — and the **discrete-item gate vs. silhouette** finding from `f_vf_seeds`.
    Both restored. Merged copy is 848 lines; a header-level check confirms nothing from
    either side was dropped (`scratch/reconcile_skills.py`, backup at
    `scratch/jit-gen-codebox.bak.md`).
  - The whole `## gen~ / Audio-Domain Codebox` section was **misfiled** in a
    `jit.gl.pix` skill. Moved into `gen-tilde-codebox`, which did *not* already contain
    it (so dropping it would have lost five findings, not deduplicated them).
    `gen-tilde-codebox` moved from `claude-scaffold` into `f_/skills/` — f_ now holds
    the audio modules, so it belongs here. 483 lines.
  - `max-patch-notation` was a byte-identical duplicate; symlinked to stop it drifting.
  - **Still to do, Matt:** re-upload to claude.ai (that third copy can't be symlinked).
  - **Not moved, worth a decision:** `max-advanced-object-methodology` (referenced by
    this project's own conventions), `maxpat-json-authoring` and
    `pfft-spectral-processing` are still claude-scaffold-only but are f_-relevant.

### Carried to next session: finish the skills consolidation

**[CLOSED 2026-09-29b — both pieces done; only Matt's re-upload remains. See the top
entry. Original text kept below for the reasoning it records.]**

Matt (2026-09-29): "we'll try to rectify everything next session." Two open pieces,
neither started:

1. **The three remaining claude-scaffold-only Max skills.** Decide per skill whether it
   moves into `f_/skills/` (and gets symlinked back, like the five already done) or
   stays scaffold-only. The same argument that moved `gen-tilde-codebox` applies to at
   least two of them: `max-advanced-object-methodology` is cited by this project's own
   conventions (read the help patch and bundled examples before architecting; build the
   smallest verified increment; flag guesses as guesses), and `pfft-spectral-processing`
   is directly `f_a_ripple`/`f_a_decorrelate` material. `maxpat-json-authoring` is the
   least clear — it is generic Max tooling, not f_-specific. The real question underneath
   is **what `f_/skills/` is for**: this-repo collaboration conventions only, or the home
   for all Max/Vsynth knowledge with scaffold as a consumer. Answer that first; the moves
   are mechanical afterwards.
2. **The claude.ai uploads.** Symlinks fix the two checkouts but not the uploaded copies,
   which are now the only place divergence can restart. Re-upload all five (and any of
   the three above that move). Worth deciding whether the upload set should be pinned to
   `f_/skills/` wholesale so "upload everything in that directory" is the whole rule.

Also unresolved and related: nothing prevents an upload from going stale silently. If a
cheap staleness check is wanted (a date line in each SKILL.md, or a hash manifest), that
is a third piece to scope.

### Next session — Matt's by-eye work

All tier 3, in `fluid_tuning.maxpat`. **Click RESET before judging anything** — last
session's inconclusive result came partly from an undamped saturating state (drag is
`drag·dt`, so at dt ≈ 0 there is no damping at all and the output pins at the clamp).
T041 measures Fluid's cost **differentially** (fps with its bypass on vs off), because
the unused producers are not disabled — f_ modules use the bypass toggle, not Vsynth's
`enable`.

---

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
  **[SUPERSEDED 2026-09-29 — reconciled and single-sourced; see this session's entry.]**
- **`taps` numbox shows "1.00"** — see "This session"; cosmetic, shared-builder change if done.
  **[RESOLVED 2026-09-29 — the numbox is gone; `taps` came off the panel.]**
- **Two `jit-gen-codebox` skill copies have diverged both ways** (`f_` and
  `claude-scaffold`). This session added the native-bypass bullet to the `f_`
  copy only. The claude.ai upload is a third copy — reconcile, then re-upload.
  **[RESOLVED 2026-09-29 for the two checkouts — merged both directions and
  symlinked; `f_` had been missing the `mix`-collision and discrete-item-gate
  findings. The claude.ai upload is still outstanding, and the three remaining
  scaffold-only Max skills are carried forward — see this session's entry.]**
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
