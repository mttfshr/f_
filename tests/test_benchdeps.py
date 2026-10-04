"""
test_benchdeps.py -- tests/benchdeps.py, which decides what `bench.sh --changed`
runs. A skipped bench file must be one that last passed on identical inputs, so
the cases here are the ways that could go wrong: an input that is not hashed, a
change that does not change the hash, a failure that leaves a stale green record,
a renamed file that silently drops coverage.

Offline (no Max). Run:  tests/run.sh tests/test_benchdeps.py
"""
import contextlib
import io
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import benchdeps as bd
from harness import check, run

REPO = Path(__file__).resolve().parent.parent


def _t(label, cond):
    check(label, 0 if cond else 1, 0)


def _raises(fn):
    try:
        fn()
    except bd.MissingInputs:
        return True
    return False


# ---- a throwaway repo layout

def _repo(tmp):
    root = Path(tmp)
    for d in ("tests", "build", "data", "package/patchers"):
        (root / d).mkdir(parents=True, exist_ok=True)
    (root / "tests/bench_a.py").write_text("import helper\nimport os\n")
    (root / "tests/helper.py").write_text("import deep\n")
    (root / "build/deep.py").write_text("X = 1\n")
    (root / "tests/unrelated.py").write_text("Y = 1\n")
    (root / "data/one.gen").write_text("one")
    (root / "data/two.gen").write_text("two")
    (root / "data/other.txt").write_text("other")
    (root / "package/patchers/f_x.maxpat").write_text("x")
    (root / "package/patchers/f_y.maxpat").write_text("y")
    return root


DATA = {"bench_a": ["data/*.gen"]}


def test_python_deps_are_transitive_local_and_nothing_else():
    with tempfile.TemporaryDirectory() as tmp:
        root = _repo(tmp)
        names = {p.name for p in bd.python_deps("bench_a", root)}
        _t("the file, its import, and that import's import from build/",
           names == {"bench_a.py", "helper.py", "deep.py"})
        _t("an unrelated module and the standard library are not deps",
           "unrelated.py" not in names and "os.py" not in names)
        _t("a file that does not exist is an error", _raises(lambda: bd.python_deps("bench_nope", root)))


def test_input_hash_changes_exactly_when_an_input_changes():
    with tempfile.TemporaryDirectory() as tmp:
        root = _repo(tmp)
        h0 = bd.input_hash("bench_a", root, DATA)
        _t("stable when nothing changed", bd.input_hash("bench_a", root, DATA) == h0)
        (root / "tests/unrelated.py").write_text("Y = 2\n")
        _t("an unrelated python file does not change it", bd.input_hash("bench_a", root, DATA) == h0)
        (root / "data/other.txt").write_text("changed")
        _t("a data file outside the globs does not change it", bd.input_hash("bench_a", root, DATA) == h0)
        (root / "build/deep.py").write_text("X = 2\n")
        h1 = bd.input_hash("bench_a", root, DATA)
        _t("a transitive python dependency changes it", h1 != h0)
        (root / "data/one.gen").write_text("one!")
        h2 = bd.input_hash("bench_a", root, DATA)
        _t("a data file in the globs changes it", h2 != h1)
        (root / "data/three.gen").write_text("three")
        h3 = bd.input_hash("bench_a", root, DATA)
        _t("a NEW file matching a glob changes it", h3 != h2)
        (root / "data/two.gen").rename(root / "data/twp.gen")   # same content, same sort position
        _t("renaming a matched file changes it (the path is hashed, not only the content)",
           bd.input_hash("bench_a", root, DATA) != h3)
        (root / "data/twp.gen").rename(root / "data/two.gen")
        _t("renaming it back restores the hash", bd.input_hash("bench_a", root, DATA) == h3)
        (root / "tests/bench_a.py").write_text("import helper\nimport os\n# edited\n")
        _t("the bench file itself is an input", bd.input_hash("bench_a", root, DATA) != h3)


def test_a_glob_that_matches_nothing_is_an_error_not_silence():
    with tempfile.TemporaryDirectory() as tmp:
        root = _repo(tmp)
        _t("a pattern matching no file raises",
           _raises(lambda: bd.input_hash("bench_a", root, {"bench_a": ["data/*.nope"]})))
        _t("even when other patterns match",
           _raises(lambda: bd.input_hash("bench_a", root, {"bench_a": ["data/*.gen", "gone/*.js"]})))


def test_module_hashes_are_per_patcher():
    with tempfile.TemporaryDirectory() as tmp:
        root = _repo(tmp)
        a = bd.module_hashes(root)
        _t("one entry per f_*.maxpat", sorted(a) == ["f_x", "f_y"])
        (root / "package/patchers/f_x.maxpat").write_text("x2")
        b = bd.module_hashes(root)
        _t("editing one patcher changes only its hash", b["f_x"] != a["f_x"] and b["f_y"] == a["f_y"])


# ---- the decision table

def _snap(inputs="h1", env="Max 9.2.0; Vsynth 1.7.0", modules=None):
    s = {"inputs": inputs, "env": env}
    if modules is not None:
        s["modules"] = modules
    return s


def _green(snap, slow=False, when="2026-10-04 12:00"):
    return dict(snap, slow=slow, when=when)


def test_decide_runs_unless_the_last_green_run_matches_in_every_respect():
    s = _snap()
    _t("no record: run", bd.decide("b", None, s, False)[0] == "run")
    _t("identical: skip", bd.decide("b", _green(s), s, False)[0] == "skip")
    _t("skip says when and on what", "2026-10-04 12:00" in bd.decide("b", _green(s), s, False)[2]
       and "Max 9.2.0" in bd.decide("b", _green(s), s, False)[2])
    _t("inputs changed: run", bd.decide("b", _green(s), _snap(inputs="h2"), False)[0] == "run")
    act, _, why = bd.decide("b", _green(s), _snap(env="Max 9.3.0; Vsynth 1.7.0"), False)
    _t("Max changed: run, and the reason names both versions",
       act == "run" and "9.2.0" in why and "9.3.0" in why)
    _t("Vsynth changed: run", bd.decide("b", _green(s), _snap(env="Max 9.2.0; Vsynth 1.8.0"), False)[0] == "run")
    _t("slow requested but last green skipped slow tests: run",
       bd.decide("b", _green(s, slow=False), s, True)[0] == "run")
    _t("slow requested and last green included them: skip",
       bd.decide("b", _green(s, slow=True), s, True)[0] == "skip")
    _t("a slow-green run satisfies a fast request",
       bd.decide("b", _green(s, slow=True), s, False)[0] == "skip")


def test_decide_per_module_runs_only_the_patchers_that_changed():
    base = _snap(modules={"f_a": "1", "f_b": "2", "f_c": "3"})
    rec = _green(base)
    _t("nothing changed: skip", bd.decide("m", rec, base, False)[0] == "skip")
    act, mods, _ = bd.decide("m", rec, _snap(modules={"f_a": "1", "f_b": "X", "f_c": "3"}), False)
    _t("one patcher changed: run only it", act == "run" and mods == ["f_b"])
    act, mods, _ = bd.decide("m", rec, _snap(modules={"f_a": "1", "f_b": "2", "f_c": "3", "f_d": "4"}), False)
    _t("a new module: run only it", act == "run" and mods == ["f_d"])
    act, mods, _ = bd.decide("m", rec, _snap(modules={"f_a": "1", "f_b": "2"}), False)
    _t("a module removed: nothing to run", act == "skip")
    act, mods, _ = bd.decide("m", rec, _snap(inputs="h2", modules=base["modules"]), False)
    _t("the shared inputs changed: run ALL modules (no subset)", act == "run" and mods is None)
    act, mods, _ = bd.decide("m", {k: v for k, v in rec.items() if k != "modules"}, base, False)
    _t("no per-module record: run all", act == "run" and mods is None)


# ---- recording

def test_record_green_full_and_partial():
    snap = _snap(modules={"f_a": "1", "f_b": "2"})
    full = bd.record_green({}, "m", snap, False, None, when="t")
    _t("a full run records every module", full["m"]["modules"] == {"f_a": "1", "f_b": "2"})
    nxt = _snap(modules={"f_a": "1", "f_b": "NEW"})
    part = bd.record_green(full, "m", nxt, False, ["f_b"], when="t2")
    _t("a partial run updates only the modules that ran", part["m"]["modules"] == {"f_a": "1", "f_b": "NEW"})
    stale = bd.record_green(full, "m", _snap(inputs="h9", modules={"f_a": "1", "f_b": "NEW"}), False, ["f_b"])
    _t("if the shared inputs changed since, only what ran is known green",
       stale["m"]["modules"] == {"f_b": "NEW"})
    gone = bd.record_green(full, "m", _snap(modules={"f_a": "1"}), False, None)
    _t("a removed module drops out of the record", gone["m"]["modules"] == {"f_a": "1"})
    other = bd.record_green({"x": {"inputs": "keep"}}, "m", snap, False)
    _t("other files' entries are untouched", other["x"] == {"inputs": "keep"})
    _t("the slow flag is stored", bd.record_green({}, "f", _snap(), True)["f"]["slow"] is True)
    _t("and defaults to false", bd.record_green({}, "f", _snap(), False)["f"]["slow"] is False)


def test_record_file_is_robust_and_atomic():
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "jobs" / "bench_green.json"
        _t("missing file: nothing known green", bd.load_record(path) == {})
        bd.save_record({"f": {"inputs": "h"}}, path)
        _t("round trip", bd.load_record(path) == {"f": {"inputs": "h"}})
        _t("no temp file left behind", not list(path.parent.glob("*.tmp")))
        path.write_text("{ not json")
        _t("corrupt JSON: nothing known green, no crash", bd.load_record(path) == {})
        path.write_text('{"files": [1, 2]}')
        _t("wrong shape: nothing known green", bd.load_record(path) == {})
        path.write_text("[]")
        _t("not even an object: nothing known green", bd.load_record(path) == {})


# ---- the command line, in-process, against the real repo and a temp record

def _cli(argv):
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        code = bd.main(argv)
    return code, out.getvalue(), err.getvalue()


def _with_record(fn):
    with tempfile.TemporaryDirectory() as tmp:
        old = bd.RECORD
        bd.RECORD = Path(tmp) / "bench_green.json"
        try:
            fn(bd.RECORD, Path(tmp))
        finally:
            bd.RECORD = old


def test_cli_plan_record_forget_cycle():
    def body(rec, tmp):
        f = "tests/bench_control.py"
        code, out, err = _cli(["plan", f])
        _t("never recorded: planned to run", out.strip() == f"{f}\t-" and err.startswith("run "))
        snap = tmp / "snap.json"
        code, out, _ = _cli(["snapshot", f])
        snap.write_text(out)
        _cli(["record", f, "--snapshot", str(snap)])
        code, out, err = _cli(["plan", f])
        _t("recorded green: skipped, with the reason on stderr", out.strip() == "" and err.startswith("skip "))
        code, out, err = _cli(["plan", "--slow", f])
        _t("--slow after a fast-green run: runs again", out.strip() == f"{f}\t-")
        _cli(["forget", f])
        code, out, err = _cli(["plan", f])
        _t("after a failure (forget): runs again", out.strip() == f"{f}\t-")
    _with_record(body)


def test_cli_files_without_dependencies_always_run_and_are_never_recorded():
    def body(rec, tmp):
        f = "tests/bench_not_registered.py"
        code, out, err = _cli(["plan", f])
        _t("unregistered file: runs", out.strip() == f"{f}\t-" and "no dependency entry" in err)
        code, out, _ = _cli(["snapshot", f])
        _t("snapshot prints nothing for it", out == "")
        empty = tmp / "empty.json"; empty.write_text("")
        _cli(["record", f, "--snapshot", str(empty)])
        _t("record is a no-op for it", not rec.exists())
    _with_record(body)


def test_cli_a_missing_input_glob_fails_loudly():
    def body(rec, tmp):
        old = bd.DATA.get("bench_control")
        bd.DATA["bench_control"] = ["tests/bench/does_not_exist_*.js"]
        try:
            code, out, err = _cli(["plan", "tests/bench_control.py"])
        finally:
            bd.DATA["bench_control"] = old
        _t("exit code 3 and the pattern named", code == 3 and "does_not_exist_" in err)
        _t("nothing is printed to run", out == "")
    _with_record(body)


# ---- the real repo: coverage guards

def test_every_real_bench_file_is_registered_and_its_globs_match():
    on_disk = {p.stem for p in (REPO / "tests").glob("bench_*.py")}
    _t("every tests/bench_*.py has a DATA entry (a new bench file must register)",
       on_disk <= set(bd.DATA))
    _t("every DATA entry is a real file", set(bd.DATA) <= on_disk)
    for stem in sorted(bd.DATA):
        bd.input_files(stem)                       # raises MissingInputs on a dead glob
    _t("every glob matches at least one real file", True)
    _t("PER_MODULE names registered files", bd.PER_MODULE <= set(bd.DATA))
    default = re.search(r"^DEFAULT=\(([^)]*)\)", (REPO / "tests/bench.sh").read_text(), re.M).group(1).split()
    _t("every file in bench.sh's DEFAULT is registered", all(f"bench_{n}" in bd.DATA for n in default))


def test_the_machinery_is_an_input_of_every_bench_file():
    for stem in sorted(bd.DATA):
        names = {p.name for p in bd.input_files(stem)}
        _t(f"{stem} depends on harness and benchclient", {"harness.py", "benchclient.py"} <= names)


def test_snapshot_records_the_environment():
    _t("an explicit environment is stored as given", bd.snapshot("bench_control", env="E1")["env"] == "E1")
    old = bd.detect_env
    bd.detect_env = lambda: "detected"
    try:
        _t("otherwise the detected one", bd.snapshot("bench_control")["env"] == "detected")
    finally:
        bd.detect_env = old
    _t("detect_env names Max and Vsynth", re.fullmatch(r"Max \S+; Vsynth \S+", bd.detect_env()) is not None)


def test_only_bench_modules_is_tracked_per_module():
    snap = bd.snapshot("bench_modules", env="e")
    _t("bench_modules snapshots carry one hash per patcher",
       "modules" in snap and len(snap["modules"]) == len(list((REPO / "package/patchers").glob("f_*.maxpat"))))
    _t("other files' snapshots do not", "modules" not in bd.snapshot("bench_fft", env="e"))
    _t("fluid_module depends on the fluid patcher and its codeboxes",
       {"f_vf_fluid.maxpat", "codebox_adv.gen"} <= {p.name for p in bd.input_files("bench_fluid_module")})


# ---- the shell glue, end to end without Max

def _bench_sh(env_extra, *args):
    env = dict(os.environ, **env_extra)
    return subprocess.run(["bash", str(REPO / "tests/bench.sh"), *args], cwd=REPO, env=env,
                          capture_output=True, text=True, timeout=120)


def test_bench_sh_changed_skips_green_files_and_lists_the_rest():
    with tempfile.TemporaryDirectory() as tmp:
        green = Path(tmp) / "green.json"
        env = {"BENCH_GREEN": str(green)}
        r = _bench_sh(env, "--changed", "--list")
        listed = r.stdout.split()
        _t("empty record: --changed --list names all 7 default files", len(listed) == 7)
        files = {}
        env_now = bd.detect_env()
        default = re.search(r"^DEFAULT=\(([^)]*)\)", (REPO / "tests/bench.sh").read_text(), re.M).group(1).split()
        for n in default:
            files = bd.record_green(files, f"bench_{n}", bd.snapshot(f"bench_{n}", env=env_now), False,
                                    when="seeded by test")
        bd.save_record(files, green)
        r = _bench_sh(env, "--changed", "--list")
        _t("everything green: nothing to run, exit 0",
           r.returncode == 0 and "nothing to run" in r.stdout and r.stdout.count(".py") == 0)
        _t("--changed with a record never needs Max (no preflight)", "not reachable" not in r.stdout)
        files.pop("bench_fft")
        bd.save_record(files, green)
        r = _bench_sh(env, "--changed", "--list")
        _t("one record removed: only that file is listed", r.stdout.split() == ["tests/bench_fft.py"])
        files["bench_fluid_module"]["env"] = "Max 0.0.1; Vsynth 0"
        bd.save_record(files, green)
        r = _bench_sh(env, "--changed", "--list")
        _t("a different environment on record: that file runs too",
           sorted(r.stdout.split()) == ["tests/bench_fft.py", "tests/bench_fluid_module.py"])
        r = _bench_sh(env, "--changed", "--slow", "--list")
        _t("--slow: every file whose green run skipped slow tests runs",
           len(r.stdout.split()) == 7)
        r = _bench_sh(env, "--list")
        _t("without --changed: all 7, the record is ignored", len(r.stdout.split()) == 7)


def _fails(fn):
    """True if fn raises AssertionError. Its own printed check line is swallowed so
    an expected failure does not read as a failure in this test's output."""
    with contextlib.redirect_stdout(io.StringIO()):
        try:
            fn()
        except AssertionError:
            return True
    return False


def test_a_module_subset_run_does_not_call_other_modules_known_issues_fixed():
    """bench_modules.py with BENCH_MODULES set: known issues of modules that did not
    run cannot appear, and must not be reported as 'now passing'."""
    import bench_modules as bm
    saved = (bm.ONLY, dict(bm.KNOWN), set(bm._seen))
    try:
        bm.KNOWN.clear()
        bm.KNOWN[("f_b", "unused", "x")] = "a known issue of f_b"
        bm._seen.clear()
        bm.ONLY = {"f_a"}
        bm.test_known_live_issues_still_present()          # f_b not run: must not fail
        _t("a subset run that excludes the module: not reported fixed", True)
        bm.ONLY = {"f_b"}
        failed = _fails(bm.test_known_live_issues_still_present)   # f_b ran and did not show it: fixed
        _t("the module did run and the issue is gone: reported (remove it from KNOWN)", failed)
        bm.ONLY = set()
        failed = _fails(bm.test_known_live_issues_still_present)   # full run: unchanged behaviour
        _t("a full run still reports every known issue that is gone", failed)
    finally:
        bm.ONLY = saved[0]
        bm.KNOWN.clear(); bm.KNOWN.update(saved[1])
        bm._seen.clear(); bm._seen.update(saved[2])


def _fake_uv(tmp):
    """A `uv` that stands in for running a bench file: preflight (-c) succeeds, a
    file run prints BENCH_MODULES/BENCH_SLOW and exits with $FAKE_RC."""
    bindir = Path(tmp) / "fakebin"
    bindir.mkdir()
    uv = bindir / "uv"
    uv.write_text('#!/bin/bash\n'
                  'case " $* " in *" -c "*) exit 0 ;; esac\n'
                  'echo "fake run: BENCH_MODULES=[$BENCH_MODULES] BENCH_SLOW=[$BENCH_SLOW]"\n'
                  'exit ${FAKE_RC:-0}\n')
    uv.chmod(0o755)
    py = bindir / "python3"                      # logs each benchdeps call, then runs the real one
    py.write_text('#!/bin/bash\necho "$@" >> "$PY_LOG"\nexec "$REAL_PY" "$@"\n')
    py.chmod(0o755)
    return bindir


def _glue_env(tmp, rc=0):
    return {"PATH": f"{_fake_uv_dirs[tmp]}:{os.environ['PATH']}", "FAKE_RC": str(rc),
            "BENCH_GREEN": str(Path(tmp) / "green.json"), "BENCH_LOG": str(Path(tmp) / "log.txt"),
            "PY_LOG": str(Path(tmp) / "pycalls.txt"), "REAL_PY": shutil.which("python3")}


_fake_uv_dirs = {}


def test_bench_sh_records_a_pass_and_forgets_a_failure():
    with tempfile.TemporaryDirectory() as tmp:
        _fake_uv_dirs[tmp] = _fake_uv(tmp)
        f = "tests/bench_selftest.py"
        r = _bench_sh(_glue_env(tmp, 0), f)
        _t("a passing run exits 0", r.returncode == 0)
        r = _bench_sh(_glue_env(tmp, 0), "--changed", f)
        _t("and is recorded: --changed now has nothing to run",
           r.returncode == 0 and "nothing to run" in r.stdout and "fake run" not in r.stdout)
        r = _bench_sh(_glue_env(tmp, 1), f)
        _t("a failing run exits 1", r.returncode == 1)
        r = _bench_sh(_glue_env(tmp, 0), "--changed", "--list", f)
        _t("and its green record is forgotten: --changed runs it again", r.stdout.split() == [f])
        _bench_sh(_glue_env(tmp, 0), f)
        r = _bench_sh(_glue_env(tmp, 0), "--changed", "--slow", "--list", f)
        _t("a run without --slow does not satisfy --changed --slow", r.stdout.split() == [f])
        r = _bench_sh(_glue_env(tmp, 0), "--slow", f)
        _t("--slow exports BENCH_SLOW to the test", "BENCH_SLOW=[1]" in r.stdout)
        r = _bench_sh(_glue_env(tmp, 0), "--changed", "--slow", f)
        _t("a --slow pass is recorded as slow-green", "nothing to run" in r.stdout)
        _t("the log starts with the Max version and date",
           (Path(tmp) / "log.txt").read_text().startswith("# Max "))


def test_bench_sh_passes_only_the_changed_modules_and_records_them():
    with tempfile.TemporaryDirectory() as tmp:
        _fake_uv_dirs[tmp] = _fake_uv(tmp)
        f = "tests/bench_modules.py"
        green = Path(tmp) / "green.json"
        snap = bd.snapshot("bench_modules")
        recorded = bd.record_green({}, "bench_modules", snap, False, when="seeded")
        stale = sorted(snap["modules"])[0]
        recorded["bench_modules"]["modules"][stale] = "an older hash"
        bd.save_record(recorded, green)
        r = _bench_sh(_glue_env(tmp, 0), "--changed", f)
        _t("exactly the module whose patcher differs is run, and passed through",
           f"BENCH_MODULES=[{stale}]" in r.stdout and r.stdout.count("fake run") == 1)
        calls = (Path(tmp) / "pycalls.txt").read_text().splitlines()
        rec_calls = [c for c in calls if c.startswith("tests/benchdeps.py record tests/bench_modules.py")]
        _t("the shell tells `record` which modules it ran",
           len(rec_calls) == 1 and f"--modules {stale}" in rec_calls[0])
        r = _bench_sh(_glue_env(tmp, 0), "--changed", f)
        _t("once it passed, its new hash is recorded: nothing left to run", "nothing to run" in r.stdout)
        r = _bench_sh(_glue_env(tmp, 0), f)
        _t("a plain run is not limited to any module", "BENCH_MODULES=[]" in r.stdout)


if __name__ == "__main__":
    sys.exit(run(globals()))
