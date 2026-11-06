# HANDOFF

## START HERE (2026-11-05)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole.

**State:** `f_wave_field` is finished except T041 (the `f_cymascope` audio front end, not started): redesign built, docs and helpfile written, in the menu under ∇ Fields, README ⚠ removed, live looks passed, benches green on the four-input harness (record: `.specify/f_wave_field/tasks.md`). `f_vf_stamp` (was `f_splat`) is SPECCED, nothing built: `.specify/f_vf_stamp/{spec,plan,tasks}.md`; Phase 0 is done: G1-G7 are decided (`tasks.md`) and the mirror is written; G8 waits for Phase 3. Earlier closed work (`f_vf_ch` rename, `f_weave` promotion, `f_stipple` / `f_vf_flow` render triggers, the `render_dim` migration, Hatch, `f_ks` tuning, the Claims rule) is in `HANDOFF_ARCHIVE.md` and the module `tasks.md` files. Nothing else is scheduled; Matt picks the next item.

**Candidates (Matt decides):**
- **`f_vf_stamp` Phase 1** (start here if Matt says go): Phase 0 is closed (G3 is the plain difference field with a `rim` dial, plan ADR-4; G6 is the spec's table). T020 and T021 are done (the `gate_button` schema type, `build/spec.md`; the codebox, not yet compiled); next is T022.
- `f_wave_field` T041: the `f_cymascope` front end now produces an LFO texture for inlet 1 (and strike triggers); not started.
- `f_masonry` adopts tagged textures (Matt, 2026-11-01 21:17: "we will do masonry, but not this second"): design discussion first. Its modulation is by space (slot, brick, pixel) with a depth per appearance param in each (6 x 3 = 18 depths, read from `src/f_masonry/definition.py`), so one tag per named `<param>_tex` needs a decision about the spaces. It is the module on the never-regenerate list (`G-masonry`).
- The UI design conversation toward a design skill: `ideas/ui_design_concepts.md` (gate `G-ui-density`); the compact `f_weave` panel is the first test case.
- `f_weave` name and identity: keeping `weave` for now (Matt, 2026-11-01 21:26), to revisit once he knows the module better (question 6; the names discussed are listed in `ideas/f_weave_scope_questions.md`); the other scope questions are tabled.
- Hatch tail (T064): the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail.
- `f_ks` still needs its name (T010) and docs (T040) (its tuning is done).
- `vs_black` wording in `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the skill needs Matt's re-upload and `skills/check.sh stamp`). New fact for that wording: `vs_black` is a 1x1 texture (`vs_render.maxpat`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn; ask before any bench run (the codebox bench now passes up to FOUR inputs); Desktop Commander for files (load schemas with ToolSearch; tool names vary by client; in the desktop app, 2026-11-05, the plain Bash tool ran on the Mac); `edit_block` for targeted edits, and never rewrite a CRLF file in text mode; commit per module. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01). Long bench runs outlast the relay's 60 s wait: start with a short timeout, then ask Matt to say when it is done. Ad-hoc numpy scripts: `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy); `sed -i` needs an extension on this Mac, so edit with Python or `edit_block`.

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-05 (night): `f_vf_stamp` Phase 0 closed

- **Decided (Matt, chat; record in `.specify/f_vf_stamp/tasks.md`):** G5 reading confirmed; G2 `out0 = vec(in0.rgb * cov * amount * env, 1.0)`; G7 Rec.709; G3 the plain wide central difference with a `rim` dial in frame widths (plan ADR-4); G6 the spec's table (`edge` and `seed` cut, `threshold` 0.05, `amount` 0-4); FR-003's band clamped at 0 so black never stamps.
- **Commits:** 7ddc4a8, 269fdf6, 5667368, ed010cc, then this one.
- **Verified:** `test_vf_stamp.py` 20/20 offline (Claude; log `tests/logs/20261105-212945-offline.log`). Mirror only.
- **Also verified:** `tests/build/test_gates.py` 5/5 (Matt's go; log `tests/logs/20261105-213038-offline.log`).
- **Not run:** any bench, the rest of the offline suite. Nothing is on the GPU.
- **Inferred, not observed:** the radial leak through `project` (about 10% of energy, formula only; viscosity and `taps` not modelled); taps at about 0.15-0.2 brightness at advect's defaults; Swirl's on-screen direction against `f_vf_vortex`'s `curl`. All land at T030 / T032.
- **Known limits at the defaults:** pure blue stamps at 0.81. `softness` and `rim` are different things: `softness` acts in luma, the band's width comes from `rim`.
- **Owed to Matt:** T008 later (menu category, held by `G-menu`). The live looks come after Phase 1.
- **Gates touched, no row edited:** `G-ui-density` (ten controls plus the press), `G-menu`, `G-edge-wrap`, `P-taxonomy`.
