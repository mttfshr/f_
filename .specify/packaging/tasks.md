# Tasks: Package structure and Package Manager readiness

**Reference**: `docs/max-reference/packaging.md` (research, decisions, evidence). Plan item: `.specify/plan.md` Work Queue 13.
**Commits**: Matt commits manually. Done work is in `8af4c71` and `2e014c7`.

**Status 2026-10-01:** the structural fixes are done and committed. What remains is verification in Max, answers from Kevin Kripper, two missing assets (license, icon), and the first tag and release. **The release is blocked on T012 and T013.** Whether the old install layout was the actual cause of Kevin's trouble is still unconfirmed (T011).

---

## Done (committed)

- [x] T001 `package-info.json`: `displayname`, `max_version_min` 9.0.0 (Matt kept it; unverified, see T010), `max_version_max`, `website`, Vsynth named in `description`. No `os`, no `homepatcher`.
- [x] T002 `demos/` renamed to `examples/`; 16 demos and 11 presets prefixed `f_demo_`; stale `autorestore` names repaired (`chladni`, `repulse`, `weave-advect`; `general` cleared). Presets byte-identical, one changed line per patch.
- [x] T003 `package/readme.md`.
- [x] T004 `build/release.sh` (committed-state zip with top-level `f_/`; `--working-tree` for test builds; tag/version check). Tested: default, working-tree, tag mismatch, bad flag.
- [x] T005 README install section and Repo Structure lines.
- [x] T006 `docs/max-reference/packaging.md`, HANDOFF entry, plan item 13.
- [x] T007 `package/javascript/moduleSize.js` removed (byte-identical to Vsynth's; caused a duplicate-file warning). Matt reports the restart test passed; not observed by Claude.

## Verify in Max (Matt)

- [ ] T008 Restart Max. Open `f_demo_chladni`, `f_demo_repulse`, `f_demo_general` and one demo without a preset (e.g. `f_demo_streak`); read the console (Cmd-M). Confirms the renamed demos open cleanly, and shows how Max treats a missing or absent `autorestore`. Also note whether `weave-advect` now loads sensibly with its own preset.
- [ ] T009 Install-test a release zip. Build with `build/release.sh`. **Never unzip into `~/Documents/Max 9/Packages/` while `f_` there is a symlink to the checkout** (it writes into the working tree). Either test on another machine, or remove the symlink first and restore it afterwards. Not yet tested at all: installing a zip into Max, and the Windows install note in the README.
- [ ] T010 `max_version_min` 9.0.0 is unverified: all 76 patches were saved in Max 9.1.4. Test on 9.0.x if available, or use Kevin's version (T011). If patches fail on older Max, raise `max_version_min` in `package-info.json`.

## Kevin Kripper

- [ ] T011 Ask Kevin: (a) how he installed `f_`, (b) his Max and Vsynth versions, (c) the first console error line when a patch fails. Settles whether the install layout was the cause.
- [ ] T012 License. Ask Kevin whether `f_` counts as an adaptation of Vsynth (CC BY-NC 4.0, attribution and non-commercial). Then choose a license, add `package/license.md` (or `.txt`), and replace "Not yet specified" in `package/readme.md`. Evidence and options are in `docs/max-reference/packaging.md` ("License research"). Not legal advice.
- [ ] T020 Once Kevin gives his Vsynth version, decide whether to state a required Vsynth version in `package-info.json` `description` and `package/readme.md` (currently: developed against 1.7.0, others untested).

## Assets and release

- [ ] T013 `package/icon.png`, 500x500 (shown in the Package Manager). Needs an image from Matt, or a generated plain placeholder.
- [ ] T014 Read the Cycling '74 submission form (https://cycling74.com/support/submit-packages) before building the release process around it. How the registry ingests submissions (repo link, zip, subfolder layouts) is undocumented in everything found so far. If it needs a repo-root package, revisit Option B (see packaging.md: `docs/` is a reserved Max folder name, all `package/...` paths need rewriting, dev material would move under a `dev/` folder).
- [ ] T015 After T008, T012 and T013: tag `v0.1.0` (must match the manifest version), run `build/release.sh`, create a GitHub release and attach the zip. `gh` availability not checked; upload may be manual. Then update the README ("No release has been published yet").

## Small decisions and cleanups

- [ ] T016 `prism-masonry` has a preset but no `autorestore`; `streak` has no `pattrstorage`; `help/streak-demo.json` still lives in `help/`. Decide whether to wire them up (adding `autorestore` changes how those demos open).
- [ ] T017 Optional: one line in `.specify/constitution.md` (the `moduleSize` chain convention, line 39) saying the file now comes from Vsynth, not this package.
- [ ] T018 The README's `build/` line says helpfile generation is "via Claude API"; `.specify/plan.md` says `build/generate_helpfiles.py` no longer calls the API. Noticed in passing, not verified (script not opened). Fix whichever is stale.

## Parked

- [ ] T019 Console error `patcher: doesn't understand "getattr"`. Appears with or without `moduleSize.js`, so it is not caused by it. The moduleSize chain is `loadbang` to `getattr presentation_rect` to `thispatcher` to `zl slice 2` to `prepend tam` to `js moduleSize.js`, copied from Vsynth's convention (`vs_displacement` has the same message). Cause unknown. First test: open `vs_displacement.maxpat` directly from the file browser and see whether it raises the same error (baseline). Matt asked to troubleshoot this separately.
