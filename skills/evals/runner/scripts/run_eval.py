#!/usr/bin/env python3
"""Trigger eval for a skill description (f_ repo copy).

Derived from skill-creator's scripts/run_eval.py (Apache-2.0, LICENSE.txt here).
Changes for the f_ repo:
  - runs in /Users/matt/Github/f_ (the project root is fixed);
  - a Skill call to the installed `anthropic-skills:<name>`, to the runner's own
    temporary command, or to another worker's temporary command (same
    description), or a Read of skills/<name>/SKILL.md, counts as a hit;
  - every run records why it ended: hit_*, other_tool (name + short input),
    no_tool (turn ended with text only), timeout, or exited;
  - `claude -p` gets --strict-mcp-config (no MCP servers; measured 21% cheaper);
  - run counts: near-misses run once, should-trigger prompts run once and are
    rerun only on a miss (up to --max-reruns times).

Run (from the repo root, PYTHONPATH = the folder holding scripts/):
  env -u ANTHROPIC_API_KEY PYTHONPATH=skills/evals/runner python3 -m scripts.run_eval \
    --eval-set skills/evals/<skill>.json --skill-path skills/<skill> --model opus --verbose
"""

import argparse
import json
import os
import select
import subprocess
import sys
import time
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

from scripts.utils import parse_skill_md

PROJECT_ROOT = Path("/Users/matt/Github/f_")
SNIPPET = 140


def _hit_kind(acc: str, clean_name: str, skill_name: str) -> str | None:
    """Which kind of hit the accumulated tool input is, or None."""
    if clean_name in acc:
        return "hit_command"          # this run's own temporary command
    if f"{skill_name}-skill-" in acc:
        return "hit_sibling_command"  # another worker's command, same description
    if f':{skill_name}"' in acc or f'"{skill_name}"' in acc:
        return "hit_installed"        # anthropic-skills:<name>
    if f"skills/{skill_name}/SKILL.md" in acc:
        return "hit_read"
    return None


def _record(reason, start, tool=None, tool_input=None, text=None, **extra):
    rec = {"reason": reason, "hit": reason.startswith("hit_"),
           "seconds": round(time.time() - start, 1)}
    if tool is not None:
        rec["tool"] = tool
    if tool_input is not None:
        rec["input"] = tool_input[:SNIPPET]
    if text:
        rec["text"] = text.strip()[:SNIPPET]
    rec.update(extra)
    return rec


def run_single_query(query, skill_name, skill_description, timeout, project_root, model=None):
    """Run one `claude -p` and return a record of how it ended."""
    unique_id = uuid.uuid4().hex[:8]
    clean_name = f"{skill_name}-skill-{unique_id}"
    commands_dir = Path(project_root) / ".claude" / "commands"
    command_file = commands_dir / f"{clean_name}.md"
    start = time.time()

    try:
        commands_dir.mkdir(parents=True, exist_ok=True)
        indented = "\n  ".join(skill_description.split("\n"))
        command_file.write_text(
            f"---\ndescription: |\n  {indented}\n---\n\n"
            f"# {skill_name}\n\nThis skill handles: {skill_description}\n"
        )

        cmd = ["claude", "-p", query, "--output-format", "stream-json", "--verbose",
               "--include-partial-messages", "--strict-mcp-config"]
        if model:
            cmd.extend(["--model", model])
        env = {k: v for k, v in os.environ.items()
               if k not in ("CLAUDECODE", "ANTHROPIC_API_KEY")}

        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                   cwd=project_root, env=env)
        buffer = ""
        tool_name = None      # first tool_use block of the turn, once started
        tool_json = ""
        text = ""             # text written before any tool call
        saw_event = False

        try:
            eof = False
            while time.time() - start < timeout:
                ready, _, _ = select.select([process.stdout], [], [], 1.0)
                if not ready:
                    continue
                chunk = os.read(process.stdout.fileno(), 8192)
                eof = not chunk
                buffer += chunk.decode("utf-8", errors="replace")
                if eof:
                    buffer += "\n"

                while "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        event = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    saw_event = True
                    etype = event.get("type")

                    if etype == "stream_event":
                        se = event.get("event", {})
                        st = se.get("type", "")
                        if st == "content_block_start":
                            cb = se.get("content_block", {})
                            if cb.get("type") == "tool_use" and tool_name is None:
                                tool_name = cb.get("name", "")
                                tool_json = ""
                        elif st == "content_block_delta":
                            d = se.get("delta", {})
                            if d.get("type") == "input_json_delta" and tool_name is not None:
                                tool_json += d.get("partial_json", "")
                            elif d.get("type") == "text_delta" and tool_name is None:
                                text += d.get("text", "")
                        elif st == "content_block_stop" and tool_name is not None:
                            kind = (_hit_kind(tool_json, clean_name, skill_name)
                                    if tool_name in ("Skill", "Read") else None)
                            if kind:
                                return _record(kind, start, tool_name, tool_json, text)
                            return _record("other_tool", start, tool_name, tool_json, text)
                        elif st == "message_stop" and tool_name is None:
                            return _record("no_tool", start, text=text)

                    elif etype == "assistant":
                        # Fallback when stream events are missing.
                        for c in event.get("message", {}).get("content", []):
                            if c.get("type") == "text" and tool_name is None:
                                text += c.get("text", "")
                            if c.get("type") == "tool_use":
                                name = c.get("name", "")
                                inp = json.dumps(c.get("input", {}))
                                kind = (_hit_kind(inp, clean_name, skill_name)
                                        if name in ("Skill", "Read") else None)
                                return _record(kind or "other_tool", start, name, inp, text)

                    elif etype == "result":
                        return _record("no_tool", start, text=text,
                                       subtype=event.get("subtype"))

                if eof:
                    return _record("exited", start, text=text,
                                   returncode=process.wait(), saw_event=saw_event)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()

        return _record("timeout", start, tool_name, tool_json or None, text,
                       saw_event=saw_event)
    finally:
        if command_file.exists():
            command_file.unlink()


def _run_batch(jobs, skill_name, description, num_workers, timeout, project_root, model, verbose):
    """jobs: list of (query_index, query). Returns list of (query_index, record)."""
    out = []
    with ProcessPoolExecutor(max_workers=num_workers) as ex:
        futs = {ex.submit(run_single_query, q, skill_name, description, timeout,
                          str(project_root), model): i for i, q in jobs}
        for f in as_completed(futs):
            i = futs[f]
            try:
                rec = f.result()
            except Exception as e:  # noqa: BLE001
                rec = {"reason": "error", "hit": False, "error": str(e)[:SNIPPET]}
            out.append((i, rec))
            if verbose:
                extra = rec.get("tool", "") + " " + rec.get("input", rec.get("text", ""))[:60]
                print(f"  q{i} {rec['reason']:<20} {rec.get('seconds', '')}s {extra}",
                      file=sys.stderr)
    return out


def run_eval(eval_set, skill_name, description, num_workers, timeout, project_root,
             runs_should=1, runs_near=1, max_reruns=2, trigger_threshold=0.5,
             model=None, verbose=False):
    runs: dict[int, list[dict]] = {i: [] for i in range(len(eval_set))}

    first = []
    for i, item in enumerate(eval_set):
        n = runs_should if item["should_trigger"] else runs_near
        first += [(i, item["query"])] * n
    if verbose:
        print(f"Round 1: {len(first)} runs", file=sys.stderr)
    for i, rec in _run_batch(first, skill_name, description, num_workers, timeout,
                             project_root, model, verbose):
        runs[i].append(rec)

    # Reruns: should-trigger prompts with no hit yet, one more run per round.
    for r in range(max_reruns):
        todo = [(i, eval_set[i]["query"]) for i in runs
                if eval_set[i]["should_trigger"] and not any(x["hit"] for x in runs[i])]
        if not todo:
            break
        if verbose:
            print(f"Rerun {r + 1}: {len(todo)} runs", file=sys.stderr)
        for i, rec in _run_batch(todo, skill_name, description, num_workers, timeout,
                                 project_root, model, verbose):
            runs[i].append(rec)

    results = []
    reasons: dict[str, int] = {}
    for i, item in enumerate(eval_set):
        recs = runs[i]
        hits = sum(r["hit"] for r in recs)
        rate = hits / len(recs) if recs else 0.0
        st = item["should_trigger"]
        results.append({
            "query": item["query"], "should_trigger": st,
            "trigger_rate": rate, "triggers": hits, "runs": len(recs),
            "first_run_hit": bool(recs and recs[0]["hit"]),
            "pass": rate >= trigger_threshold if st else rate < trigger_threshold,
            "run_log": recs,
        })
        for r in recs:
            reasons[r["reason"]] = reasons.get(r["reason"], 0) + 1

    passed = sum(r["pass"] for r in results)
    should = [r for r in results if r["should_trigger"]]
    return {
        "skill_name": skill_name,
        "description": description,
        "settings": {"model": model, "timeout": timeout, "num_workers": num_workers,
                     "runs_should_trigger": runs_should, "runs_near_miss": runs_near,
                     "max_reruns": max_reruns, "threshold": trigger_threshold,
                     "flags": ["--strict-mcp-config"]},
        "results": results,
        "summary": {
            "total": len(results), "passed": passed, "failed": len(results) - passed,
            "total_runs": sum(r["runs"] for r in results),
            "should_trigger_first_run_hits": f"{sum(r['first_run_hit'] for r in should)}/{len(should)}",
            "reasons": reasons,
        },
    }


def main():
    p = argparse.ArgumentParser(description="Run trigger evaluation for a skill description")
    p.add_argument("--eval-set", required=True)
    p.add_argument("--skill-path", required=True)
    p.add_argument("--description", default=None, help="Override description to test")
    p.add_argument("--num-workers", type=int, default=6)
    p.add_argument("--timeout", type=int, default=120, help="Seconds per run")
    p.add_argument("--runs-should-trigger", type=int, default=1)
    p.add_argument("--runs-near-miss", type=int, default=1)
    p.add_argument("--max-reruns", type=int, default=2,
                   help="Extra runs for a should-trigger prompt, only while it has no hit")
    p.add_argument("--only", default=None,
                   help="Comma-separated query indexes to run (0-based), for plumbing checks")
    p.add_argument("--trigger-threshold", type=float, default=0.5)
    p.add_argument("--model", default=None)
    p.add_argument("--verbose", action="store_true")
    a = p.parse_args()

    eval_set = json.loads(Path(a.eval_set).read_text())
    if a.only:
        keep = {int(x) for x in a.only.split(",")}
        eval_set = [q for i, q in enumerate(eval_set) if i in keep]
    skill_path = Path(a.skill_path)
    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)
    name, original, _ = parse_skill_md(skill_path)
    description = a.description or original

    out = run_eval(eval_set, name, description, a.num_workers, a.timeout, PROJECT_ROOT,
                   a.runs_should_trigger, a.runs_near_miss, a.max_reruns,
                   a.trigger_threshold, a.model, a.verbose)

    if a.verbose:
        s = out["summary"]
        print(f"Results: {s['passed']}/{s['total']} passed, {s['total_runs']} runs, "
              f"reasons {s['reasons']}", file=sys.stderr)
        for r in out["results"]:
            tag = "PASS" if r["pass"] else "FAIL"
            print(f"  [{tag}] {r['triggers']}/{r['runs']} expected={r['should_trigger']}: "
                  f"{r['query'][:70]}", file=sys.stderr)
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()
