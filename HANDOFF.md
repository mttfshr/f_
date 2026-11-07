# HANDOFF

## START HERE (2026-11-06)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** `f_wave_field` is finished except T041 (the `f_cymascope` audio front end, not started): redesign built, docs and helpfile written, in the menu under ∇ Fields, README ⚠ removed, live looks passed, benches green on the four-input harness (record: `.specify/f_wave_field/tasks.md`). `f_vf_stamp` (was `f_splat`) is BUILT OFFLINE, nothing run: `.specify/f_vf_stamp/{spec,plan,tasks}.md`; Phase 0 and T020-T024 are done, benches green (10/10, 7/7, 2/2), live looks passed, documented and registered (Phase 3 done 2026-11-06; the helpfile is not yet opened in Max); menu category provisional under Adapters (`G-menu`). Earlier closed work (`f_vf_ch` rename, `f_weave` promotion, `f_stipple` / `f_vf_flow` render triggers, the `render_dim` migration, Hatch, `f_ks` tuning, the Claims rule) is in `HANDOFF_ARCHIVE.md` and the module `tasks.md` files. `f_vf_fluid` and `f_vf_split` moved to `.specify/stable/` 2026-11-06. `f_tf_tensormap` moved to `.specify/stable/` 2026-11-06. `f_tf_hatch` moved to `.specify/stable/` 2026-11-06. `f_tf_axisflow` moved to `.specify/stable/` 2026-11-06. `f_vf_fieldmap` and `f_vf_potential` moved to `.specify/stable/` 2026-11-06. `f_vf_flow` and `f_tone_curve` moved to `.specify/stable/` 2026-11-06, so all seven batch 3 modules are moved. Stable push: batch 4 triage is done (`.specify/maintenance/batch4_triage_2026-11-06.md`); Group A (`f_vf_warp`, `f_stipple`, `f_vf_glow`, `f_vf_prism`) moved to `.specify/stable/` 2026-11-06 after Matt's helpfile looks and one live contract bench (2/2, log `tests/logs/20261106-192009-bench.log`). Group B (`f_vf_advect`, `f_vf_streak`) moved to `.specify/stable/` 2026-11-06 after Matt's batch 4 calls were applied (entry below). Next: the vortex preflight (optical_flow and seeds bypass passthrough built offline 2026-11-06, entry below). Plan and bar: the 2026-11-06 entries in `HANDOFF_ARCHIVE.md`, and `.specify/plan.md` Next 0.

**Candidates (Matt decides):**
- `f_wave_field` T041: the `f_cymascope` front end now produces an LFO texture for inlet 1 (and strike triggers); not started.
- `f_masonry` adopts tagged textures (Matt, 2026-11-01 21:17: "we will do masonry, but not this second"): design discussion first. Its modulation is by space (slot, brick, pixel) with a depth per appearance param in each (6 x 3 = 18 depths, read from `src/f_masonry/definition.py`), so one tag per named `<param>_tex` needs a decision about the spaces. It is the module on the never-regenerate list (`G-masonry`).
- The UI design conversation toward a design skill: `ideas/ui_design_concepts.md` (gate `G-ui-density`); the compact `f_weave` panel is the first test case.
- `f_weave` name and identity: keeping `weave` for now (Matt, 2026-11-01 21:26), to revisit once he knows the module better (question 6; the names discussed are listed in `ideas/f_weave_scope_questions.md`); the other scope questions are tabled.
- `f_ks` still needs its name (T010) and docs (T040) (its tuning is done).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`). New fact for that wording: `vs_black` is a 1x1 texture (`vs_render.maxpat`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run (the codebox bench now passes up to FOUR inputs); Desktop Commander for files (load schemas with ToolSearch; tool names vary by client; in the desktop app, 2026-11-05, the plain Bash tool ran on the Mac); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01). Long bench runs outlast the relay's 60 s wait: start with a short timeout, then ask Matt to say when it is done. Ad-hoc numpy scripts: `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy); `sed -i` needs an extension on this Mac, so edit with Python or `edit_block`.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-06: phase 3, optical_flow and seeds bypass passthrough (live look and bench passed)

- **Done (Claude, offline; uncommitted):** both modules moved from native `@bypass` to `bypass_mode: "param"` (`bypass_gate`). Rule (Matt): inlet 0 to the composite outlet, else out[0]. Seeds: stages 1c and 4, shape texture on a new stage 4 inlet, `out1` = shape tex, mask and seed coord black. Optical flow: stages c and d, source frame (stage a cur-passthrough) on a new stage d inlet, `out1` = source frame, confidence neutral. Records: seeds T050, optical_flow T041.
- **Checked:** both rebuild with drift 0; optical_flow's hand-computed obj ids unchanged (read from the built patcher); `test_bench_expect.py` 10/10, `test_module_contracts.py` 9/9 (stale stage_a `bypass` exemption removed), `test_vf_seeds.py` 11/11 (log `tests/logs/20261106-221045-offline.log`). Full suite not run.
- **Docs:** reference docs, inventory rows, seeds spec, `G-bypass-native` row (now 15 modules).
- **Verified:** Matt's live look passes (2026-11-06); `bench_modules.py` 2/2, 0 unexpected issues (`tests/logs/20261106-phase3-bypass-bench.log`). **Owed:** `test_gates.py` with Matt's go.
- **Not done:** vortex preflight; `vs_black` wording in the skill.

## 2026-11-06: batch 4 Matt's calls applied; Group B (advect, streak) moved to `.specify/stable/`

- **Applied (commits `c8583be`, `4459a3d`):** streak `falloff` max 2.5 -> 1.99 (Matt chose 1.99 over 2.0: weight sum `8 - 4 * falloff` is zero at 2.0, no codebox guard); advect `trail` max 1000 -> 120 (demo presets hold 0.0); vortex doc fixes (native bypass passes through; unconnected mod inlet with `*_amt` > 0 offsets by `-amt`, Matt: fix later, documented).
- **Preflight (offline by Claude, plus omp audit `advect-streak-audit-1`, 6 of 6 planted doc errors found, reports checked in the repo):** advect bypass wording (`definition.py`, `spec.md`), doc clamp line, spec Internal Architecture / Signal Flow rewritten (Matt's call), both helpfiles wired upstream (`f_vf_flow` to inlet 1), streak helpfile falloff range fixed. Commits `96ba60d`, `0f253dd`, `a806cfb`, `98a22fe`.
- **Matt, live:** both helpfile looks pass. **Benches by Claude at Matt's go:** `bench_vf_advect.py` 2/2, `bench_modules.py` 2/2, 0 unexpected issues (`tests/logs/20261106-advect-streak-bench2.log`). The first log, `...-bench.log`, was stopped early and is not evidence.
- **Gates:** `G-bypass-native` row updated for vortex's doc; `test_gates.py` run only with Matt's go.
- **Next (fresh session):** phase 3, `f_vf_optical_flow` and `f_vf_seeds` bypass passthrough (rule, Matt 2026-11-06: inlet 0 to the composite outlet, else out[0]); then the `f_vf_vortex` preflight (mod-inlet gating deferred).
- **Not done:** `skills/vsynth-bpatcher/SKILL.md` lines 279 and 798 (Matt re-uploading); `library-characteristics.md:373`.
