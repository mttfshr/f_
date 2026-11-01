"""
test_gates.py -- offline check that .specify/gates.md has not gone stale against the module
task records. No Max needed.

A "Waiting" gate (a decision is needed) is flagged when
  * every task it cites (T0nn, resolved in the `.specify/<module>/tasks.md` files the row also
    cites) is ticked [x]: the gate looks closed but is still listed, or
  * a task it cites is not in those files, or a `.specify/`, `ideas/` or `docs/` path it
    names does not exist: the row points at something that is not there.
`[~]` and `[ ]` count as not ticked. Parked rows are not checked (a tripwire, not a task, reopens
them), and a row that cites no task ids is not checked beyond its paths.

This catches only rows that cite task ids; the Clears-when column is free text. It was added
2026-11-01 after a closed workstream (Hatch) was reported closed while its gate row was still
listed.

Run:  tests/run.sh -q tests/build/test_gates.py
"""
import paths as _paths
import re
import sys
import tempfile
from pathlib import Path

from harness import check, note, run

REPO = Path(str(_paths.REPO))
GATES = REPO / ".specify" / "gates.md"

TASK_RE = re.compile(r"\bT(\d{3})\b")
TASKFILE_RE = re.compile(r"\.specify/([A-Za-z0-9_\-]+)/tasks\.md")
PATH_RE = re.compile(r"`((?:\.specify|ideas|docs)/[^`\s]+)`")
BOX_RE = re.compile(r"^\s*-\s*\[(.)\]\s+T(\d{3})\b", re.M)


def waiting_rows(text):
    """The table rows under '## Waiting' as (id, full row text)."""
    rows, inside = [], False
    for line in text.split("\n"):
        if line.startswith("## "):
            inside = line.startswith("## Waiting")
            continue
        if not inside or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if not cells or cells[0] in ("ID", "") or set(cells[0]) <= set("-: "):
            continue
        rows.append((cells[0], " ".join(cells[1:])))
    return rows


def task_status(repo, module):
    """{'052': 'x' | ' ' | '~'} from .specify/<module>/tasks.md ({} if there is no file)."""
    f = Path(repo) / ".specify" / module / "tasks.md"
    if not f.is_file():
        return {}
    return {n: m for m, n in BOX_RE.findall(f.read_text(encoding="utf-8"))}


def problems(text, repo):
    out = []
    for gid, row in waiting_rows(text):
        ids = sorted(set(TASK_RE.findall(row)))
        mods = sorted(set(TASKFILE_RE.findall(row)))
        if ids and mods:
            status = {}
            for m in mods:
                for n, mark in task_status(repo, m).items():
                    status.setdefault(n, mark)
            missing = [n for n in ids if n not in status]
            for n in missing:
                out.append(f"{gid}: cites T{n}, not found in {', '.join(mods)}")
            if not missing and all(status[n] == "x" for n in ids):
                out.append(f"{gid}: every cited task is ticked ({', '.join('T' + n for n in ids)}): "
                           "looks closed, still listed")
        for p in PATH_RE.findall(row):
            p = p.rstrip(".,;:)")
            if not (Path(repo) / p).exists():
                out.append(f"{gid}: names {p}, which does not exist")
    return out


def _tmp_repo(tasks_text):
    d = Path(tempfile.mkdtemp(prefix="gates_test_"))
    (d / ".specify" / "mod").mkdir(parents=True)
    (d / ".specify" / "mod" / "tasks.md").write_text(tasks_text, encoding="utf-8")
    return d


def _gates(rows, section="Waiting (a decision is needed)"):
    return (f"# Gates\n\n## {section}\n\n| ID | Question | Decider | Since | Clears when |\n"
            "|---|---|---|---|---|\n" + "\n".join(rows) + "\n\n## Parked (a tripwire reopens it)\n")


TASKS = "- [x] T001 done\n- [x] T002 done\n- [ ] T003 open\n- [~] T004 partly\n"


def test_committed_gates():
    text = GATES.read_text(encoding="utf-8")
    check("Waiting rows found in gates.md (0 = parser sees them; 1 = none, the parser is broken)",
          0 if waiting_rows(text) else 1, 0)
    found = problems(text, REPO)
    for p in found:
        note("stale gate", p)
    check("stale or dangling Waiting gates in .specify/gates.md", len(found), 0)


def test_all_ticked_is_flagged():
    repo = _tmp_repo(TASKS)
    t = _gates(["| G-x | Close it (T001, T002). `.specify/mod/tasks.md` | Matt | 2026-11-01 | soon |"])
    check("row whose cited tasks are all ticked flagged (count)", len(problems(t, repo)), 1)


def test_open_task_passes():
    repo = _tmp_repo(TASKS)
    t = _gates(["| G-x | T001 done, T003 open. `.specify/mod/tasks.md` | Matt | 2026-11-01 | soon |",
                "| G-y | T002 done, T004 partly. `.specify/mod/tasks.md` | Matt | 2026-11-01 | soon |"])
    check("row with an open or partly done cited task flagged (count)", len(problems(t, repo)), 0)


def test_missing_task_and_path_flagged():
    repo = _tmp_repo(TASKS)
    t = _gates(["| G-x | T009 is open. `.specify/mod/tasks.md` | Matt | 2026-11-01 | soon |",
                "| G-y | See `.specify/nope/spec.md`. | Matt | 2026-11-01 | soon |"])
    check("missing task and missing path flagged (count)", len(problems(t, repo)), 2)


def test_parked_and_taskless_rows_ignored():
    repo = _tmp_repo(TASKS)
    parked = _gates(["| P-x | T001, T002. `.specify/mod/tasks.md` | 2026-11-01 | tripwire |"],
                    section="Parked (a tripwire reopens it)")
    check("parked row checked (count)", len(problems(parked, repo)), 0)
    taskless = _gates(["| G-x | A question with no task ids. `.specify/mod/tasks.md` | Matt | 2026-11-01 | soon |"])
    check("row with no task ids flagged (count)", len(problems(taskless, repo)), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
