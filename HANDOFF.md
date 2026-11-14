# HANDOFF

## START HERE (2026-11-13)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole (the 2026-11-12 misregistration and randomizer experiments, and the 2026-11-12 `f_util_vary` build entry, are in its top entries).

**State:** `f_vf_erode` is closed and stable (`70e1f76`). Print-styles: `f_separate` and `f_poincare` stable; `f_halftone` specified with a passing NumPy mirror, no module code; `f_engrave` specified, nothing built; `f_paper` needs a spec; `f_misregister` is folded into `f_util_vary` (the look itself is an ordinary Vsynth chain, Matt live 2026-11-12). `f_wave_field` is finished except T041.

**`f_util_vary` is CLOSED and stable** (2026-11-13, Matt's go; record `.specify/stable/f_util_vary/`, preflight T030, live checks T003 all passed by Matt: 8 outlets, lo/hi and mode/sign/group after a recall, two copies, trim). Control-side variation: bases in on inlet 0, settings on inlet 1, 8 destination outlets, + row UI (`f_util_vary_row` bpatchers), saved by the patch's presets `pattrstorage`, not embedding (do not re-open unless presets prove unacceptable; scratch tests in T004). Title bar says Vary; trim dial runs 0-200 with a 100 offset (a negative dial minimum did not move). Groups: 4 are enough; the helpfile and reference doc now explain the draw and groups (`92821c0`, Matt: looks good). Not done: per-destination bases, non-float params. Old presets lack the new entries: re-store them.
- Known, not mine: `tests/build/test_layout.py` fails on `f_vf_erode` (1 overlapping pair), also on a clean tree. An older `git stash` (WIP on `e2ca2a4`) is still in the repo; Matt said keep it.

**Candidates (Matt decides):**
- Print-styles: `f_halftone` (renamed from `f_screen`, 2026-11-13, `5612cc6`): clarify pass done in part (P1, P6 accepted, per-plate x/y phase FR-016, Single reads `angle_b`, T002 open until the first live look) and the NumPy mirror is written and passes 16/16 offline (`tests/modules/halftone/`, `tests/logs/20261113-224223-offline.log`; T005, T017, T016a ticked). Mirror findings, accepted for now by Matt: about 10 texels is the practical pitch floor (area-law error 0.083 at 3 texels; the bench repeats it, T007), and jitter 1 loses ink above mid-tone. NEXT: the codebox (T020) and `definition.py` (T021), then the bench files (T022), each on Matt's go. Still open: P2-P5 and P7-P12 not explicitly confirmed, `f_engrave`'s clarify questions (it starts with a spike that may end in a stop, `G-engrave-method`).
- `f_wave_field` T041: the `f_cymascope` front end (an LFO texture for inlet 1, strike triggers); not started.
- `f_masonry` adopts tagged textures (design discussion first; 6 x 3 = 18 depths; the never-regenerate module, `G-masonry`).
- The UI design conversation (`ideas/ui_design_concepts.md`, `G-ui-density`): the scoped-presets and randomizer ideas are now part of it.
- `f_weave` name (keeping `weave` for now); `f_ks` docs (T040).
- `f_vf_erode` open, not blocking: the cost at a 1920 x 3840 atlas is unmeasured; the menu category is provisional (`G-menu`).
- `f_vf_fluid` fails the contract bench as a whole on its frame size (bypassed frame 640 x 640 against an expected 512 x 512): update the expectation or fix the module (Matt's call).
- Skills needing Matt's re-upload and `skills/check.sh stamp`: `skills/vsynth-bpatcher/SKILL.md` and `docs/vsynth-reference/patterns.md` (the `vs_black` wording: it is a 1x1 texture), and a new line for `skills/jit-gen-codebox/SKILL.md`: in a codebox `exp(-(a + b))` compiled as `exp(-a + b)` (found by the `f_vf_erode` bench; write `exp(-a - b)`).
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn. **Benches (Matt, 2026-11-10):** run one after a NEW codebox step, then plan benches once per major feature evolution (ask once, fold the commit into that ask); no bench for dial, panel, docs or helpfile changes; offline tier-1, contract and drift tests are free to run as you go. The plain Bash tool runs on the Mac. numpy scripts: `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy); the benches go through `tests/bench.sh -q <file>`; if it says the bench is not reachable, `uv run --no-project --with numpy python3 tests/lib/benchclient.py health` reopens a wedged one. `BENCH_MODULES=<module>` does not narrow the contract bench's printout (it lists all modules). `sed -i` needs an extension on this Mac, so edit with Python. `test_gates.py` is run with Matt's go before the last commit of a session. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01); keep them out of commits. `scratch/` is gitignored (local). Helpfiles: the `f-helpfile` skill, model on `package/help/f_vf_stamp.maxhelp`. Hand-authored `.maxpat` JSON is fine only for bpatcher-composition scratch patches (`skills/vsynth-bpatcher`).

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.

## 2026-11-13: `f_util_vary` row UI, persistence, helpfile, closed

- **Done and committed (Claude, with Matt's go):** the cellblock table replaced by a scripted + row UI; persistence through the presets `pattrstorage` after scratch tests ruled out embedding and parameters; strip, seed and g dials each on their own `pattr`; param menu placeholder; bigger delete button; reference doc and helpfile (Matt: looks good); 8 destination outlets. Last commit `f44947d`.
- **Found along the way:** a bpatcher does not understand an `embed` message (`setboxattr` works); parameter values do not save in an unembedded host; a `pattr @parameter_enable` blob keeps only the first list item; Max js `outlet.apply` is called with the js global as `this`; much of the afternoon's confusion was an old embedded instance still in the patch.
- **Mistake to avoid:** `git stash` with a clean tree then `git stash pop` applied an OLD stash and conflicted four files; reset to HEAD with Matt's go, stash kept. Do not stash to compare a failure.
- **Closed later the same day (Matt live):** all remaining checks passed; trim dial fixed (`8f1cdbd`); preflight and move to stable. `test_gates.py` run with Matt's go: 5/5. No bench applies.

## 2026-11-13 (later): `f_halftone` renamed, clarified, mirrored

- **Done and committed (`5612cc6`, Claude, with Matt's go):** `f_screen` renamed `f_halftone` in the live docs; clarify answers recorded in the spec and tasks; `halftone_mirror.py` and `test_halftone.py` (Dot, Line, Square, shape morph, phase, Single, jitter, Threshold, Bayer), 16/16 offline.
- **Found (mirror only):** the ADR-3 edge ramp loses ink in gaps thinner than a texel (cause inferred), so the area law needs about 10 texels of pitch; jitter 1 loses ink above mid-tone; a linear ramp cannot tell the centre tap from a 4 x 4 average, so that question waits for the live look.
- **Not touched:** Matt's uncommitted `ideas/INDEX.md` edit and `ideas/f_util_row_engine.md`.
