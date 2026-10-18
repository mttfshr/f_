"""
checkhist.py -- history of harness.check() results, so measured errors and tolerance headroom can be tracked.

harness.check(label, value, tol) appends one JSON line per call to tests/.state/check_results.jsonl (gitignored,
per machine: GPU and Max versions change the numbers) when a runner set TEST_RUN_ID (tests/_log.sh does, for
run.sh and bench.sh). Stdlib only, so benchdeps and the system python3 can use it.

    python3 tests/lib/checkhist.py report [--top N]   what is close to its tolerance, or rising
    python3 tests/lib/checkhist.py summary            one line (tests/check.sh full prints it)
    python3 tests/lib/checkhist.py prune [KEEP]       keep the last KEEP runs per kind (default 30); run at run start

A "run" is one run.sh or bench.sh invocation. A check's key is file::test::label; a check repeated in a loop
under one label counts as its worst value per run. Each check is judged on its own latest value, and only if it was
seen in the last STALE_AFTER_RUNS (10) runs of its kind, so a one-file run does not hide the last full run:
  tight   latest value is within tolerance but at least HEADROOM_WARN (50%) of it
  rising  latest value is more than TREND_FACTOR (2x) the median of its previous runs (needs MIN_HISTORY of them)
Left out of the analysis: integer-valued checks against an integer tolerance (booleans and counts, which have no
headroom), and values over their tolerance (a real failure fails the run; deliberate failures come from tests that
prove other tests can fail). Only check() calls are recorded; a plain `assert` is not.
"""
import json
import os
import statistics
import sys
import time
from pathlib import Path

DEFAULT = Path(__file__).resolve().parent.parent / ".state" / "check_results.jsonl"
KEEP_RUNS = 30
HEADROOM_WARN = 0.5
TREND_FACTOR = 2.0
MIN_HISTORY = 3
HISTORY_WINDOW = 10   # previous runs the median is taken over
STALE_AFTER_RUNS = 10  # a check not seen in this many recent runs of its kind is dropped from the report


def path():
    return Path(os.environ.get("TEST_RESULTS_FILE") or DEFAULT)


def record(file, test, label, value, tol):
    """Append one result. A no-op unless TEST_RUN_ID is set; never raises."""
    run = os.environ.get("TEST_RUN_ID")
    if not run:
        return
    try:
        row = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "run": run,
               "kind": os.environ.get("TEST_RUN_KIND", "unknown"), "git": os.environ.get("TEST_RUN_GIT", ""),
               "dirty": os.environ.get("TEST_RUN_DIRTY", ""), "max": os.environ.get("TEST_RUN_MAX", ""),
               "file": file, "test": test, "label": label, "value": float(value), "tol": float(tol)}
        p = path()
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(p, "a") as f:
            f.write(json.dumps(row) + "\n")   # one small write in append mode: concurrent runs do not interleave
    except Exception:
        pass


def load(p=None):
    """All rows, oldest first; unreadable lines are skipped."""
    p = Path(p) if p else path()
    rows = []
    try:
        with open(p) as f:
            for line in f:
                try:
                    rows.append(json.loads(line))
                except ValueError:
                    pass
    except OSError:
        pass
    return rows


def _run_order(rows):
    """{kind: [run id, ...]} in order of first appearance."""
    order = {}
    for r in rows:
        runs = order.setdefault(r.get("kind", "unknown"), [])
        if r["run"] not in runs:
            runs.append(r["run"])
    return order


def prune(keep=KEEP_RUNS, p=None):
    """Keep only the last `keep` runs of each kind. Returns the number of rows dropped."""
    p = Path(p) if p else path()
    rows = load(p)
    order = _run_order(rows)
    keepers = {(k, run) for k, runs in order.items() for run in runs[-keep:]}
    kept = [r for r in rows if (r.get("kind", "unknown"), r["run"]) in keepers]
    if len(kept) == len(rows):
        return 0
    tmp = p.with_suffix(".tmp")
    with open(tmp, "w") as f:
        for r in kept:
            f.write(json.dumps(r) + "\n")
    os.replace(tmp, p)
    return len(rows) - len(kept)


def analyze(rows=None):
    """Flag the checks of each kind's newest run. Returns (flags, n_checked) with flags a list of dicts."""
    rows = load() if rows is None else rows
    order = _run_order(rows)
    recent = {k: set(runs[-STALE_AFTER_RUNS:]) for k, runs in order.items()}   # a one-file run must not hide a full one
    series = {}   # key -> {run: worst value}; tol is the newest one seen
    tols = {}
    for r in rows:
        key = (r.get("file"), r.get("test"), r.get("label"))
        per_run = series.setdefault(key, {})
        v = r["value"]
        per_run[r["run"]] = max(per_run.get(r["run"], v), v) if v == v else v
        tols[key] = (r["tol"], r.get("kind", "unknown"))
    flags, n = [], 0
    for key, per_run in series.items():
        tol, kind = tols[key]
        if not (set(per_run) & recent.get(kind, set())):
            continue   # not seen in the last STALE_AFTER_RUNS runs of its kind: stale (renamed or removed test)
        runs = [x for x in order[kind] if x in per_run]
        latest = per_run[runs[-1]]
        if latest == latest and float(latest).is_integer() and float(tol).is_integer():
            continue   # a boolean or a count (value 0/1 against tol 0/1), not a measured error: headroom means nothing
        n += 1
        prior = [per_run[x] for x in runs[:-1]][-HISTORY_WINDOW:]
        tags = []
        headroom = (latest / tol) if tol > 0 else None
        # Only a PASSING check has headroom. A value over its tolerance either failed the run (reported by the run
        # itself) or is a deliberate failure (test_mutations_are_caught feeds broken code through check()).
        if headroom is not None and HEADROOM_WARN <= headroom <= 1.0:
            tags.append("tight")
        med = statistics.median(prior) if len(prior) >= MIN_HISTORY else None
        if med and med > 0 and latest > TREND_FACTOR * med:
            tags.append("rising")
        if tags:
            flags.append({"key": "::".join(str(x) for x in key), "tags": tags, "latest": latest, "tol": tol,
                          "headroom": headroom, "median": med, "n_prior": len(prior)})
    flags.sort(key=lambda f: (-(f["headroom"] or 0), f["key"]))
    return flags, n


def summary_line(rows=None):
    flags, n = analyze(rows)
    if not n:
        return "check history: nothing recorded yet"
    tight = sum("tight" in f["tags"] for f in flags)
    rising = sum("rising" in f["tags"] for f in flags)
    return (f"check history: {n} measured checks seen recently, {tight} at or above {HEADROOM_WARN:.0%} of tolerance, "
            f"{rising} rising (python3 tests/lib/checkhist.py report)")


def report(top=25, rows=None):
    flags, n = analyze(rows)
    lines = [summary_line(rows)]
    for f in flags[:top]:
        hr = "  n/a" if f["headroom"] is None else f"{f['headroom']:4.0%}"
        med = "" if f["median"] is None else f"  median {f['median']:.2e} (n={f['n_prior']})"
        lines.append(f"  {'+'.join(f['tags']):12s} {hr}  {f['key']}  latest {f['latest']:.2e}  tol {f['tol']:.0e}{med}")
    if len(flags) > top:
        lines.append(f"  ... {len(flags) - top} more (--top N)")
    return "\n".join(lines)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "report"
    if cmd == "report":
        top = int(sys.argv[sys.argv.index("--top") + 1]) if "--top" in sys.argv else 25
        print(report(top))
    elif cmd == "summary":
        print(summary_line())
    elif cmd == "prune":
        prune(int(sys.argv[2]) if len(sys.argv) > 2 else KEEP_RUNS)
    else:
        print(__doc__)
        sys.exit(2)
