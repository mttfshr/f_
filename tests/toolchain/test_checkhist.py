"""Offline tests for tests/lib/checkhist.py (the check() history) and its harness hook. No Max, no NumPy."""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import checkhist
from harness import check, run
from paths import TESTS


def _rows(n_runs, key_values, kind="offline", start=0):
    """Rows for n runs; key_values: label -> (list of per-run values, tol)."""
    out = []
    for i in range(n_runs):
        for label, (vals, tol) in key_values.items():
            out.append({"ts": "t", "run": f"r{start + i:03d}-{kind}", "kind": kind, "file": "f.py", "test": "t",
                        "label": label, "value": vals[i], "tol": tol})
    return out


def _flags(rows):
    flags, n = checkhist.analyze(rows)
    return {f["key"].split("::")[-1]: f["tags"] for f in flags}, n


def test_a_check_near_its_tolerance_is_flagged_tight():
    flags, n = _flags(_rows(1, {"near": ([7e-6], 1e-5), "far": ([1e-7], 1e-5)}))
    check("near flagged tight", 0 if flags.get("near") == ["tight"] else 1, 0)
    check("far not flagged", 0 if "far" not in flags else 1, 0)
    check("both counted", abs(n - 2), 0)


def test_booleans_counts_and_over_tolerance_values_are_not_headroom():
    flags, n = _flags(_rows(1, {"boolean": ([1.0], 1.0), "zero_tol": ([0.0], 0.0), "over": ([2.5e-1], 1e-5),
                                "just_inside": ([1e-5], 1e-5)}))
    check("boolean and count skipped", 0 if "boolean" not in flags and "zero_tol" not in flags else 1, 0)
    check("a deliberate failure (value over tol) is not tight", 0 if "over" not in flags else 1, 0)
    check("exactly at tolerance still counts as tight", 0 if flags.get("just_inside") == ["tight"] else 1, 0)
    check("only the two measured checks are counted", abs(n - 2), 0)


def test_a_value_well_above_its_own_median_is_flagged_rising_even_with_headroom():
    flags, _ = _flags(_rows(6, {"drift": ([1e-7, 1.1e-7, 0.9e-7, 1e-7, 1.05e-7, 3e-7], 1e-5),
                                "steady": ([1e-7] * 6, 1e-5)}))
    check("drift flagged rising", 0 if flags.get("drift") == ["rising"] else 1, 0)
    check("steady not flagged", 0 if "steady" not in flags else 1, 0)


def test_rising_needs_enough_history_and_a_nonzero_median():
    flags, _ = _flags(_rows(3, {"short": ([1e-7, 1e-7, 9e-7], 1e-5)}))   # only 2 previous runs
    check("too little history is not rising", 0 if "short" not in flags else 1, 0)
    flags, _ = _flags(_rows(5, {"zeros": ([0.0, 0.0, 0.0, 0.0, 1e-9], 1e-5)}))   # median 0: no ratio exists
    check("a zero median is not rising", 0 if "zeros" not in flags else 1, 0)


def test_a_partial_run_does_not_hide_the_last_full_run_but_a_long_absent_check_goes_stale():
    rows = _rows(2, {"old": ([9e-6, 9e-6], 1e-5)}) + _rows(1, {"new": ([1e-9], 1e-5)}, start=2)
    flags, n = _flags(rows)
    check("a check missing from the newest (partial) run is still reported", 0 if flags.get("old") == ["tight"] else 1, 0)
    check("both checks counted", abs(n - 2), 0)
    rows = _rows(1, {"old": ([9e-6], 1e-5)}) + _rows(checkhist.STALE_AFTER_RUNS, {"new": ([1e-9] * 99, 1e-5)}, start=1)
    flags, n = _flags(rows)
    check("a check unseen for STALE_AFTER_RUNS runs is dropped", 0 if "old" not in flags else 1, 0)
    check("only the current check counted", abs(n - 1), 0)


def test_kinds_are_judged_separately_and_a_loop_label_counts_its_worst_value():
    rows = _rows(1, {"cpu": ([6e-6], 1e-5)}, kind="offline") + _rows(1, {"gpu": ([1e-9], 1e-5)}, kind="bench", start=5)
    rows += [dict(rows[0], value=8e-6)]   # the same label twice in one run: the worst (8e-6) wins
    flags, n = _flags(rows)
    check("offline check still counted next to a newer bench run", abs(n - 2), 0)
    tight = [f for f in checkhist.analyze(rows)[0] if f["key"].endswith("cpu")][0]
    check("worst value per run", abs(tight["latest"] - 8e-6), 1e-12)


def test_prune_keeps_the_last_runs_of_each_kind():
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / "h.jsonl"
        rows = _rows(5, {"a": ([1.0] * 5, 2.0)}, kind="offline") + _rows(2, {"b": ([1.0] * 2, 2.0)}, kind="bench", start=10)
        p.write_text("".join(json.dumps(r) + "\n" for r in rows) + "not json\n")
        dropped = checkhist.prune(2, p)
        left = checkhist.load(p)
        runs = sorted({r["run"] for r in left})
        check("dropped 3 offline rows", abs(dropped - 3), 0)
        check("kept the 2 newest offline runs and both bench runs", abs(len(runs) - 4), 0)
        check("newest offline run kept", 0 if "r004-offline" in runs and "r000-offline" not in runs else 1, 0)
        check("nothing more to drop", abs(checkhist.prune(2, p)), 0)


def test_record_is_a_no_op_without_a_run_id_and_survives_an_unwritable_path():
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / "h.jsonl"
        saved = {k: os.environ.get(k) for k in ("TEST_RUN_ID", "TEST_RESULTS_FILE")}
        try:
            os.environ["TEST_RESULTS_FILE"] = str(p)
            os.environ.pop("TEST_RUN_ID", None)
            checkhist.record("f.py", "t", "x", 1.0, 2.0)
            check("nothing written without TEST_RUN_ID", 0 if not p.exists() else 1, 0)
            os.environ["TEST_RUN_ID"] = "r1"
            checkhist.record("f.py", "t", "x", 1.0, 2.0)
            check("one row written", abs(len(checkhist.load(p)) - 1), 0)
            os.environ["TEST_RESULTS_FILE"] = str(p / "inside-a-file" / "h.jsonl")   # parent is a file: unwritable
            checkhist.record("f.py", "t", "x", 1.0, 2.0)   # must not raise
        finally:
            for k, v in saved.items():
                os.environ.pop(k, None) if v is None else os.environ.__setitem__(k, v)


def test_the_harness_records_each_check_with_its_file_and_test():
    snippet = (
        "import harness\n"
        "def test_alpha():\n    harness.check('err', 1e-6, 1e-5)\n"
        "def test_beta():\n    harness.check('err', 2e-6, 1e-5)\n"
        "harness.run(globals())\n")
    with tempfile.TemporaryDirectory() as d:
        script = Path(d) / "test_fake.py"
        script.write_text(snippet)
        results = Path(d) / "h.jsonl"
        env = dict(os.environ, TEST_RESULTS_FILE=str(results), TEST_RUN_ID="r1", TEST_RUN_KIND="offline",
                   PYTHONPATH=str(TESTS / "lib") + os.pathsep + os.environ.get("PYTHONPATH", ""))
        env.pop("TEST_QUIET", None)
        subprocess.run([sys.executable, str(script)], env=env, capture_output=True, check=True)
        rows = checkhist.load(results)
        check("two rows", abs(len(rows) - 2), 0)
        check("tests named", 0 if [r["test"] for r in rows] == ["test_alpha", "test_beta"] else 1, 0)
        check("file recorded", 0 if all(r["file"] and r["file"].endswith("test_fake.py") for r in rows) else 1, 0)
        check("value and tol kept", 0 if rows[1]["value"] == 2e-6 and rows[1]["tol"] == 1e-5 else 1, 0)


def test_a_failing_check_is_recorded_before_it_raises():
    with tempfile.TemporaryDirectory() as d:
        results = Path(d) / "h.jsonl"
        snippet = ("import sys, harness\ndef test_bad():\n    harness.check('err', 5e-5, 1e-5)\n"
                   "sys.exit(harness.run(globals()))\n")
        script = Path(d) / "test_bad.py"
        script.write_text(snippet)
        env = dict(os.environ, TEST_RESULTS_FILE=str(results), TEST_RUN_ID="r1",
                   PYTHONPATH=str(TESTS / "lib") + os.pathsep + os.environ.get("PYTHONPATH", ""))
        env.pop("TEST_QUIET", None)
        proc = subprocess.run([sys.executable, str(script)], env=env, capture_output=True)
        rows = checkhist.load(results)
        check("the run failed", 0 if proc.returncode != 0 else 1, 0)
        check("the failing value is in the history", 0 if rows and rows[0]["value"] == 5e-5 else 1, 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
