# CLAUDE.md

Directions for Claude working in this repo, moved out of `README.md` on 2026-10-18 so the
README stays about the package. Claude Code loads this file by itself; in other sessions it
has to be read at the start along with the files named below.

## Session rules

Neither of us can see token usage, so the session is paced by things we can both count.

- **One phase, or one coherent group of tasks, per turn.** Then stop with three lines: what is done, what is committed, what is next, and wait for a go. Matt decides whether to continue or start fresh.
- **Count tool calls.** Suggest a new session after each commit checkpoint, or around 25-30 tool calls, whichever comes first.
- **No test or bench runs without asking.** The exception is one named test for the thing just changed. Always `-q`: `tests/run.sh -q`, `tests/bench.sh --changed -q`. No re-runs after doc-only edits.
- **No polling loops.** Start a long run and ask Matt to say when it is done.
- **State lives in the repo, not the chat:** `.specify/<module>/tasks.md` (the record), `HANDOFF.md` (a short scratch note), and a commit at every checkpoint. A fresh session starts by reading `README.md`, `HANDOFF.md` and `.specify/plan.md`.
- **Modules in `.specify/paused/` are excluded from analysis and planning.** They're paused for a reason; don't treat them as blockers, candidates, or examples when scoping a spike or feature elsewhere in the library. If a paused module's own resumption is genuinely in scope, that's a separate, explicit decision — not something to fold into unrelated planning (2026-10-11).
- **Commits:** a plain message is fine for files Claude did not work on (a save checkpoint). Chain a commit to the edit that precedes it, so a failed edit cannot be committed.

## Editing the README Patches table

The table is the source for the launcher patcher `package/extras/f_Launch.maxpat`. Keep each description to 110 characters, and after editing the table run `build/py.sh build/generate_launch.py` to regenerate the launcher (`tests/run.sh tests/build/test_launch.py` fails if it is stale).

## Build system rules

Modules are built from definition files, not patched by hand. `definition.py` is the source of truth: a change made by hand in Max has to be written back into it. `tests/build/test_drift.py` enforces that; the modules that don't yet reproduce from their definitions are listed in `tests/build/drift_baseline.json`, a list that only shrinks. Hand-tuning the schema doesn't model (a compact dial, a moved jsui, a label color) is written back into the definition's `overrides` block by `build/capture.py`; see `build/spec.md`.

The `f_modules` menu (`package/patchers/f_modules.maxpat`) and the size table in `package/javascript/f_addmod.js` are generated, like `f_Launch`: edit `src/f_modules/menu.py` and run `build/py.sh build/generate_menu.py` (`--check` reports a stale file). One-off scripts from earlier sessions were removed; they remain in git history.

## Helpfiles

`build/generate_helpfiles.py` only builds the prompt; the helpfile itself is written in a Claude session, never by an API call from a script.
