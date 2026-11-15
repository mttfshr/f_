# Skill trigger evals

One JSON file per skill, in skill-creator's trigger-eval format:
`[{"query": "...", "should_trigger": true|false}, ...]`. Each set has 7 prompts
that should load the skill and 5 near-misses that should not, mostly prompts that
belong to a sibling skill (gen~ vs pix, maxpat JSON vs vsynth-bpatcher, helpfile
vs preflight).

They live here, outside the skill folders, so `check.sh` hashes and the Discord
copies are unaffected (`check.sh` only counts folders with a `SKILL.md`).

**Use:** after a skill's description changes, run its set and compare with the
last result. A skill edit's commit message names the symptom it fixes and the
behavior at risk; the at-risk side is checked against these sets.

**Run** (skill-creator's `scripts/run_eval.py`, 3 `claude -p` runs per query by
default, so 36 runs per skill; ask Matt first):

    python3 <skill-creator>/scripts/run_eval.py \
      --eval-set skills/evals/<skill>.json --skill-path skills/<skill> --verbose

Results are in `results/` (table in `results/README.md`). Set `ANTHROPIC_API_KEY`
unset, and the runner needs `PYTHONPATH` pointing at the folder that holds its `scripts/`.

## Cost (measured 2026-11-15, offline by Claude)

Each run is a full Claude Code session on Matt's Pro account. The 2026-11-15
baseline (about 420 runs on Opus) used about 20% of a session's usage. **State the
run count, model and a token estimate, and get a go, before any run.**

Per run of `claude -p "reply with just: ok"` (Haiku, sequential; Opus is similar):

| Flags | Cache creation | Cache read |
|---|---|---|
| none (2nd+ run) | 16.2k | 28.2k |
| `--strict-mcp-config` | 12.8k | 28.2k |
| + `--exclude-dynamic-system-prompt-sections` | 12.8k | 27.9k |

About 13k is written fresh every run even with identical runs, so warming the cache
and dropping the runner's per-run command file do not help much (why it is not
reused is unknown). Levers that work: `--strict-mcp-config` (-21%), fewer runs
(near-misses once, should-trigger once plus reruns only on a miss, only the
changed skill's set). Keep Opus for real baselines (triggering depends on the
model); use Haiku for plumbing checks.
