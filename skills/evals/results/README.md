# Trigger-eval results

One JSON per run, `<skill>.<date>.json`: `run_eval.py` stdout (description tested,
per-query trigger rate, summary). Newest baseline per skill in the table.

Runner: skill-creator's `run_eval.py`, 3 `claude -p` runs per query, threshold 0.5,
your default model, `ANTHROPIC_API_KEY` unset (Pro login). Patched in two places:
it runs in this repo, and a call to the installed `anthropic-skills:<name>` or a Read
of `skills/<name>/SKILL.md` counts as a hit. Each query stops at its first tool call,
so a should-trigger prompt whose first call is something else (Bash, Grep, another
skill) scores as a miss.

| Skill | Date | Passed | Should-trigger runs hit | Near-miss runs hit |
|---|---|---|---|---|
| jit-gen-codebox | 2026-11-15 | 10/12 | 16/21 | 0/15 |
| gen-tilde-codebox | 2026-11-15 | 7/12 | 9/21 | 0/15 |
| bench-test-authoring | 2026-11-15 | 12/12 | 21/21 | 0/15 |
| f-helpfile | 2026-11-15 | 12/12 | 21/21 | 0/15 |
| max-advanced-object-methodology | 2026-11-15 | 10/12 | 14/21 | 0/15 |
| max-patch-notation | 2026-11-15 | 9/12 | 13/21 | 0/15 |
| maxpat-json-authoring | 2026-11-15 | 12/12 | 20/21 | 0/15 |
| module-preflight | 2026-11-15 | 12/12 | 21/21 | 0/15 |
| pfft-spectral-processing | 2026-11-15 | 11/12 | 16/21 | 0/15 |
| vsynth-bpatcher | 2026-11-15 | 8/12 | 9/21 | 0/15 |

**2026-11-15 (offline by Claude):** both skills are precise (no near-miss ever
triggered) and gen~ is under-triggering. jit misses: the GLSL port (1/3) and the
.genjit review (1/3). gen~ misses: writing a one-pole codebox (0/3), a silent
outlet, 'extra arguments for message', the peakamp~ LFO reading and a code review
(1/3 each). Why the misses happened is not yet looked at (inferred candidates: the
description leads with symptoms and loses plain "write/review gen~ code" prompts).

**2026-11-15, the other eight (offline by Claude):** still no near-miss triggered
anywhere (0/150 across all ten). Four are clean. Misses: vsynth-bpatcher 8/12
(Strength dial on f_vf_glow, bypass outlet flip, a jsui move lost on rebuild 0/3,
dual-mode f_chladni); max-patch-notation 9/12 (task-note patch 0/3, reading back a
patch description 0/3, the handoff boundmode probe 1/3); max-advanced-object-methodology
10/12 (mc.* chain 0/3, jit.gl.mesh 0/3); pfft-spectral-processing 11/12 (bin
frequency question 0/3). Causes not looked at.

**Caution, same day (offline by Claude): the baseline is too noisy to steer edits.**
With the description unchanged, a direct probe of gen~'s 5 missed prompts (2 runs
each, plain `claude -p`, no timeout) loaded the skill 10/10, and a rerun of its set
with `--timeout 120` passed 10/12 (14/21; file `-t120`) against 7/12. The
'patchcord inlet' prompt went from 3/3 to 1/3 in the same rerun. The whole rerun took
43 s, so the 30 s timeout is probably not the cause (inferred). The runner scores a
run as a miss on timeout, on any first tool other than Skill/Read, or on a turn that
ends without a tool, and it does not record which of these happened. Before editing
any description: make the runner log the reason for each miss, and use more runs
per query.
