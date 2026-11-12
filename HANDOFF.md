# HANDOFF

## START HERE (2026-11-11)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole (the whole 2026-11-10 `f_vf_erode` session is in its top entry).

**State:** `f_vf_erode` is CLOSED and in `.specify/stable/f_vf_erode/` (commit `70e1f76`; reference doc, helpfile, README row, menu entry under Color / Tone, all looked at and approved by Matt): a water-and-pigment solver (wet once, or Feed continuously for an animated input, Fade so it cannot saturate), render-size scaling (reference height 1920, live passes at 1920 and 2160 square), Lift and Settle as curves. Benched: codebox 17/17, module 5/5, contract row clean (`tests/logs/20261110-183303-bench.log`, `-183434-bench.log`). The print-styles family: `f_separate` and `f_poincare` stable; `f_screen` and `f_engrave` specified, nothing built; `f_paper` needs a spec; **`f_misregister` is PAUSED and folded into an idea** (below). Everything else stable is as in the archive and the module `tasks.md` files; `f_wave_field` is finished except T041.

**Ideas captured 2026-11-10/11 (Matt):** `ideas/f_util_scoped_presets.md` (a scoped `pattrstorage` plus a linked parameter list over any chain: store everything, expose a few dials, presets that morph; sidecar first) and `ideas/f_util_randomizer.md` (a general randomizer as a percentage over a parameter list: amount, chance, groups and correlation, wobble, trim, seed, bake to a preset; `f_misregister` is one preset of it; placeholder name). Both concept only.

**FIRST next session:** Matt's look at round 2 of the misregistration experiment (local, gitignored): `scratch/experiments/misregister_chain/misregister_chain2.maxpat` (built by `build_chain2.py`; a per-plate strip of lp spread, duotoner hardness, `f_vf_erode` on a `vs_noise_2` terrain, density, then offsets), five notes at the bottom. Round 1 (`misregister_chain.maxpat`, with `misreg_press.js`) passed his look, and save and recall of the scoped store works. Then, with his go: generalize `misreg_press.js` into a table-driven engine and test `script send <name> <msg>` addressing, whether dials move on screen, and the base-versus-effective split. Not opened in Max by Claude: round 2 is validated for JSON, ids and cords only; the Vsynth message units of `vs_offset+rot` (`unit` / `aunit` in the press) and the noise seeds are unchecked.

**Candidates (Matt decides):**
- Print-styles: the PRELIMINARY gates and clarify questions for `f_screen` and `f_engrave` (`f_engrave` starts with a spike that may end in a stop, `G-engrave-method`); `f_screen` should get a phase input so shifted halftone marks stay sharp (from the misregister discussion).
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

## 2026-11-11: `f_vf_erode` closed; misregistration becomes a randomizer idea

- **Done and committed (Claude, with Matt's go at each step):** `f_vf_erode` built, benched, Feed and Fade, render-size scaling, Lift and Settle curves, reference doc, helpfile, panel (Polarity in the title bar, Wet in the first dial slot), T041 and preflight, moved to stable (`70e1f76`). `G-ink-direction` closed (its tripwire was met). `test_gates` 5/5.
- **Ideas (Matt, chat):** `f_misregister` paused, then folded into `ideas/f_util_randomizer.md`; `ideas/f_util_scoped_presets.md`; both in the INDEX. A claim of mine was wrong and is corrected in the notes: Vsynth does have low-pass, convolve, comparator and duotoner modules (I searched for "blur").
- **Experiments (local):** `scratch/experiments/misregister_chain/` (round 1 passed Matt's look; round 2 built, not seen) and `scratch/experiments/scoped_presets/` (the smaller store spike).
- **Memory saved:** the bench-batching rule (Matt, 2026-11-10).
- **Not done, not verified:** round 2 in Max; the `script send` addressing; the 1920 x 3840 cost. Last commit of the session: `4866d09` (ideas); this HANDOFF rewrite is committed after it.
