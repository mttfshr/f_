# HANDOFF

## START HERE (2026-11-15)

**Read order for a new session:** CLAUDE.md, this block, `.specify/plan.md` (one-page focus), `.specify/gates.md`. README.md is NOT required. Older entries are in `HANDOFF_ARCHIVE.md`: grep it, do not read it whole (its top entries: the 2026-11-14 late-afternoon skills-sharing / `boundmode` entry, the 2026-11-14 afternoon `f_halftone` gate sweep / T028 close, the `f_halftone` T035 / T036 entry, the blue-noise spike and Plates entries, the earlier 2026-11-14 build-tasks entry, the 2026-11-13 `f_halftone` build, its rename and mirror, the `f_util_vary` close).

**State:** no active module; `f_halftone` closed 2026-11-14 (block below). `f_halftone`, `f_vf_erode`, `f_separate`, `f_poincare` and `f_util_vary` are closed and stable. `f_engrave` specified, nothing built; `f_paper` needs a spec; `f_misregister` is folded into `f_util_vary` (the look is an ordinary Vsynth chain, Matt live 2026-11-12). `f_wave_field` is finished except T041.

**`f_halftone`: CLOSED 2026-11-14, moved to `.specify/stable/f_halftone/`** (record there; `docs/f-reference/f_halftone.md`; helpfile passed Matt's preflight look). Dot, Line, Threshold, Bayer, Blue, Random; Channels / Single / Plates; plate outlets 2-4, Gray or Color, for per-plate effects such as `f_vf_erode`. Last runs: codebox 20/20 and module 9/9 (`tests/logs/20261114-143501-bench.log`), contract bench clean (`tests/logs/20261114-144008-bench.log`). Left open on purpose: T011 linear light (`G-linear-light`, deferred by Matt); the jitter-1 cost at 1080p is unmeasured (BenchBusy); menu category provisional (`G-menu`).
- Findings to keep (jit.gl.pix): a Param named `shape` never received its value; `vec(vec3, scalar)` does not build a vec4 (take components); per-component `switch` / `zap` calls tipped the GL3 capture budget where plain arithmetic did not; a live Int parameter spans 256 values; the contract bench leaves controls at 37% of range before its bypass click; a Max launched before a package file existed cannot find it.
- Known, not mine: `tests/build/test_build_multistage.py` fails on `f_vf_fluid` "enc follows the render size".
- Session end 2026-11-14: `test_gates.py` 5/5 after the move to stable, with Matt's go (`tests/logs/20261114-153202-offline.log`).
- Matt, 2026-11-14: `f_vf_erode` has a significant learning curve (a candidate for its helpfile or a recipe).

**`f_util_vary`:** closed 2026-11-13 (record `.specify/stable/f_util_vary/`). Matt, 2026-11-14: leave vary alone for now, including `f_util_vary_row` failing `tests/contracts/test_module_contracts.py` (unrouted tokens).
- Known, not mine: `tests/build/test_layout.py` fails on `f_vf_erode` (1 overlapping pair), also on a clean tree. An older `git stash` (WIP on `e2ca2a4`) is still in the repo; Matt said keep it.

**Candidates (Matt decides):**
- `f_wave_field` T041: the `f_cymascope` front end (an LFO texture for inlet 1, strike triggers); not started.
- `f_masonry` adopts tagged textures (design discussion first; 6 x 3 = 18 depths; the never-regenerate module, `G-masonry`).
- The UI design conversation (`ideas/ui_design_concepts.md`, `G-ui-density`): the scoped-presets and randomizer ideas are now part of it.
- `f_weave` name (keeping `weave` for now); `f_ks` docs (T040).
- `f_vf_erode` open, not blocking: the cost at a 1920 x 3840 atlas is unmeasured; the menu category is provisional (`G-menu`).
- `f_vf_fluid` fails the contract bench as a whole on its frame size (bypassed frame 640 x 640 against an expected 512 x 512): update the expectation or fix the module (Matt's call).
- **Skill trigger evals (latest entry below):** sets written for all ten skills; the first baseline run (jit-gen-codebox, gen-tilde-codebox) is owed, with `ANTHROPIC_API_KEY` unset so it runs on Matt's Pro account.
- **Skills, skill-creator pass (2026-11-15):** group 1 done (bench-test-authoring, max-advanced-object-methodology, module-preflight, max-patch-notation: symptom-led description, Quick rules, stale pointers fixed); group 2 done (pfft-spectral-processing, f-helpfile); vsynth-bpatcher split (284-line SKILL.md + 7 references/, stale menu table, `boundmode` note, `.specify` layout and test paths fixed). All ten uploaded and stamped by Matt 2026-11-15 (`check.sh`: all current); `check.sh` now also flags descriptions over 1024 chars or with < >.
- Skills: written 2026-11-14 (night), uploaded and stamped by Matt the same night: `skills/jit-gen-codebox/SKILL.md` (call sites of big functions count toward the GL3 "too many captures" budget; `Param shape`; the sin hash vs the mirror; `exp(-(a + b))`) and `skills/vsynth-bpatcher/SKILL.md` (the `vs_black` wording: 1x1, does not trigger a render; relaunch Max for new package files; `package/media/` and the `static` key). `docs/vsynth-reference/patterns.md` `vs_black` wording fixed too.
- `f_vf_seeds` cost at 1080p is unmeasured; optional cap on the `f_vf_advect` Trail dial.

**Process:** discuss design before code; one phase per turn. **Benches (Matt, 2026-11-10):** run one after a NEW codebox step, then plan benches once per major feature evolution (ask once, fold the commit into that ask); no bench for dial, panel, docs or helpfile changes; offline tier-1, contract and drift tests are free to run as you go. The plain Bash tool runs on the Mac. numpy scripts: `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy); the benches go through `tests/bench.sh -q <file>`; if it says the bench is not reachable, `uv run --no-project --with numpy python3 tests/lib/benchclient.py health` reopens a wedged one. `BENCH_MODULES=<module>` does not narrow the contract bench's printout (it lists all modules). `sed -i` needs an extension on this Mac, so edit with Python. `test_gates.py` is run with Matt's go before the last commit of a session. Do not mention or follow up on demo `.maxpat` files Matt edits (Matt, 2026-11-01); keep them out of commits. `scratch/` is gitignored (local). Helpfiles: the `f-helpfile` skill, model on `package/help/f_vf_stamp.maxhelp`. Hand-authored `.maxpat` JSON is fine only for bpatcher-composition scratch patches (`skills/vsynth-bpatcher`).

**End of session:** update this block and the `.specify/gates.md` rows you touched. Keep the new entry under about 15 lines; narrative goes in the commit message.


## 2026-11-15: skill trigger evals; `.claude/settings.json`

- **Why:** discussion of Lilian Weng's harness-engineering post (2026-07-04). Four proposals: (1) trigger evals per skill, (2) each skill edit's commit names the symptom fixed and the behavior at risk, (3) stable IDs on Quick rules, (4) a line budget for this START HERE block. Matt chose 1 first; 2-4 not started.
- **Done:** `skills/evals/<skill>.json`, 7 should-trigger plus 5 near-miss prompts each, skill-creator's `run_eval.py` format, outside the skill folders so `check.sh` hashes are unchanged (`91574a6`). `.claude/settings.json`: bench, `tests/check.sh full`, `release.sh` and `skills/check.sh stamp` ask; named offline tests, `bg.sh status/log/list`, `skills/check.sh` and the generators' `--check` allowed; `settings.local.json` gitignored (`d2faf2c`). Not yet observed in a live session; whether `ask` rules prompt in auto mode is unverified.
- **Failed run, discarded:** the first baseline gave 0/72 triggers because every `claude -p` returned "Credit balance is too low": `~/.zshrc` line 8 exports `ANTHROPIC_API_KEY` (Matt uses his Pro login, not a key). Results deleted, never committed.
- **Runner notes (offline by Claude, 2026-11-15):** stock `run_eval.py` picks its root by walking up to a `.claude/` folder, which before `d2faf2c` meant `~`; it also scores a call to the installed `anthropic-skills:<name>` copy as a miss. A patched copy in the session scratchpad (may be cleared) fixed both: count `:<name>"` or a Read of `skills/<name>/SKILL.md` as a hit. Re-patch the second point for the rerun. Each query is killed at its first tool call, so nothing in the repo runs.
- **Next:** rerun the two codebox skills with `env -u ANTHROPIC_API_KEY` (72 calls), record the baseline in `skills/evals/`, then the other eight.
