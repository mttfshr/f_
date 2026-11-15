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
