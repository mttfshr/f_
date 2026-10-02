# Packaging f_ as a Max package

_Written 2026-10-01. Research and decisions behind `package/`, `package-info.json`, `build/release.sh` and the README install section. Facts are marked verified or unverified; "unverified" means not checked against Max or the registry._

## Why this exists

Kevin Kripper (author of Vsynth) reviewed the repo and had trouble opening some patches. The suspicion was that the installable part was not structured the normal way. This note records what the normal structure is, how `f_` differed, what changed, and what is still open. **Whether the structure was the actual cause of Kevin's trouble is unconfirmed** (see Open items).

## The standard structure

Source: Cycling '74 user guide, "Packages": https://docs.cycling74.com/userguide/packages/

A package is a folder placed in `Documents/Max 9/Packages/`. The names of its subfolders determine how Max loads them, and many are added to the search path automatically: `patchers`, `help`, `javascript`, `jsui`, `examples`, `docs`, `code`, `media`, `extras`, `clippings`, `externals` and others. Also expected at the package root: `package-info.json` (the manifest), `icon.png` (500x500, shown in the Package Manager), a `license` file and a `readme`.

Manifest keys that matter here: `name`, `displayname`, `version` (semver), `author`, `description`, `tags`, `website`, `max_version_min`, `max_version_max`, `homepatcher`, `os`, `toolbar_icon`. The docs say **not** to hand-write `filelist`, `c74install`, `installdate` or `copyright`: the Package Manager manages them. The docs suggest naming the package the same as its folder, and listing dependencies in `description` (there is no dependency field).

Reference layouts on the dev machine (verified): Vsynth, ease, Polish Your Pixels, av-toolbox and others all put these folders directly under the package root.

## How f_ differed, and what changed

| Was | Now |
|---|---|
| Manifest keys `display_name`, `max_version_required` (not recognised, so ignored) | `displayname`, `max_version_min` `9.0.0`, `max_version_max` `none` |
| No `website`; no Vsynth dependency noted | `website` set; `description` says it requires Vsynth |
| No readme inside the package | `package/readme.md` |
| `demos/` (not a recognised folder name) with generic file names on the global search path | `examples/`, every demo and preset prefixed `f_demo_` |
| No `icon.png`, no license | **Still missing** (see Open items) |

`max_version_min` is `9.0.0` to match the README's long-standing claim. **Unverified:** all 76 patches were saved in Max 9.1.4, and nobody has tested them on 9.0.x. `9.1.4` is the only version known to work.

I deliberately left out `os` (the package has no binaries and has only been run on macOS) and `homepatcher` (the only candidate, `f_modules.maxpat`, is the module-menu bpatcher, not a sensible landing page).

## Layout decision

The repo root is **not** the package root; the package is the `package/` subfolder. Consequence: `git clone` into `Packages/` gives Max a folder with no `package-info.json` and no `patchers/` at its top level, so nothing is on the search path. The previous install instructions (symlink or copy `package/` renamed to `f_`) worked around this.

**Option A (chosen): keep `package/` as a subfolder, ship a release zip.** `build/release.sh` builds a zip whose single top-level folder is `f_/`, containing the contents of `package/`. Least churn: the build scripts, tests, skills and `.specify` docs keep their `package/...` paths.

**Option B (not chosen, still available): make the repo root the package root.** This is the conventional layout; of the packages on the dev machine, av-toolbox and Rhythm and Time Toolkit are git checkouts with the repo root as package root (verified; the other ~25 are not git checkouts, so they say nothing about author layouts). av-toolbox keeps its dev material in a `dev/` folder. B would require: renaming `docs/` (a reserved Max folder name), rewriting every hardcoded `package/...` path across `build/`, `tests/`, `skills/` and `.specify/`, and moving the dev-machine symlink. It is the right move if the registry turns out to want a repo-root package.

## The release zip

`build/release.sh` (header comment has full usage):
- default: zips the **committed** state of `package/` using `git archive`, so untracked files (`.DS_Store`) cannot leak in;
- `--working-tree`: zips what is on disk, excluding `.DS_Store` and `*.bak`, for test builds;
- naming: `f_-<version>.zip` only when HEAD is tagged `v<version>`; `-dev` when untagged; `-wip` for `--working-tree`;
- refuses to build when HEAD's tag disagrees with the manifest version;
- verifies the zip has nothing outside `f_/`, contains `f_/package-info.json`, and no junk files.

Tested 2026-10-01: default, `--working-tree`, tag mismatch and bad flag. Not tested: installing a zip into Max. It does not create tags or GitHub releases. **No tag or release exists yet.**

**Caution:** on the dev machine `~/Documents/Max 9/Packages/f_` is a symlink to this repo's `package/`. Unzipping a release there would write into the working tree.

## Package Manager / registry

The official Package Manager is curated by Cycling '74; the documented route in is a submission form: https://cycling74.com/support/submit-packages (the form page itself has **not** been read). How submissions are ingested (repo link, zip, subfolder support) is **not documented anywhere found**. A third-party downloader (natcl/max_package_downloader, not the official Package Manager) says package structure at the repo root is the best way, accepts zips, and has a `relative_path` option for packages not at the zip root. That is weak evidence for B and for zips being workable; it is not evidence about the official registry.

## moduleSize.js

`package/javascript/moduleSize.js` is a byte-identical copy of Vsynth's own `javascript/moduleSize.js` (verified). 37 `.maxpat` files under `package/` reference it via the box `js moduleSize.js`, which is generated by `build/build_patcher.py`; the name resolves through the search path, not by location. With both copies installed, Max prints a duplicate-file warning and uses the `f_` copy (verified, console screenshot).

Deleting the `f_` copy was tried once (2026-10-01) and Max reported `js: can't find file moduleSize.js` even though Vsynth's copy is on the search path. Most likely a stale file cache; **not confirmed.** The file was restored. The test still to run: delete it, fully quit and relaunch Max, then open `f_droste` inside a Vsynth patch and check the console. If it fails after a full restart, keep our copy. Renaming it to `f_moduleSize.js` would mean editing all 37 `.maxpat` files plus `build_patcher.py`.

## Demo presets (autorestore)

Each demo's `pattrstorage` box names its preset in a box-level `autorestore` key. Three demos named files that were not shipped (`chladni-scratch.json`, `repulse-scratch.json`, `glow-scratch.json`), while `chladni.json` and `repulse.json` shipped unreferenced, and `weave-advect` loaded `seeds2.json` (which holds `f_vf_seeds` data) instead of its own `weave-advect.json` (which holds `f_weave`/`f_vf_advect` data). Repointed during the `examples/` rename; `general` has no preset yet so its `autorestore` was removed. **Unverified:** how Max reacts to a missing `autorestore` file, and that the renamed demos open cleanly. `prism-masonry` (preset exists, no `autorestore`) and `streak` (no `pattrstorage`) were left unchanged on purpose; `help/streak-demo.json` was left in `help/`.

## License research (decision pending)

Licenses of the 17 installed packages that ship a license file (dev machine only, not a survey): MIT (CidLink, ISF, Polish Your Pixels source, ease, vb.mi-objects), GPL v3 (Rhythm and Time Toolkit, av-toolbox), CC BY-NC-SA (ml.star, zsa.descriptors), BSD 3-Clause (FluidCorpusManipulation), CC BY-NC 4.0 (**Vsynth**), others custom or BSD-style. Ten installed packages have no license file.

Vsynth is CC BY-NC 4.0 (attribution, non-commercial). Open questions, not legal advice: whether `f_` counts as an adaptation of Vsynth (it uses `vs_` abstractions and conventions, and ships a copy of one Vsynth file), and therefore whether NonCommercial carries over. **Matt is asking Kevin.** Until decided, `package/readme.md` says "Not yet specified" and no license file exists.

## Open items

- License choice (waiting on Kevin).
- `package/icon.png` (500x500): not made; needs a design decision.
- `moduleSize.js` restart test (above).
- Confirm with Kevin how he installed it, his Max and Vsynth versions, and the first console error line when a patch fails.
- First tag and GitHub release; read the submission form before building the release process around the registry.
- Separate, parked: the console error `patcher: doesn't understand "getattr"` appears with or without `moduleSize.js`; Vsynth's `vs_displacement` contains the same `getattr presentation_rect` message; cause unknown (see HANDOFF).
