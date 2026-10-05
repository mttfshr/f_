#!/usr/bin/env python3
"""
benchdeps.py -- which bench files need to run?  (tests/bench.sh --changed)

A bench file's result is a function of its inputs: the Python it imports
(derived from the imports, transitively), the data files it reads (DATA below),
and the environment (Max and Vsynth versions, which changed results on
2026-10-04). If all of those equal what they were at the file's last green run,
running it again tells you nothing new, so --changed skips it and says so.

State lives in tests/jobs/bench_green.json (gitignored, local to a checkout;
BENCH_GREEN=path overrides it, which the tests use):
{"files": {"bench_fluid": {"inputs": <hash>, "env": "...", "slow": false,
"when": "...", "modules": {...}}}}. An entry is written only after a file passes
and removed when it fails, so a skipped file is always one that last passed.

bench_modules is tracked per module (each shipped patcher is independent): when
only patchers changed, only those modules run (bench.sh passes BENCH_MODULES).

    python3 tests/benchdeps.py plan [--slow] FILE...        what to run; reasons on stderr
    python3 tests/benchdeps.py snapshot FILE                inputs now, as JSON
    python3 tests/benchdeps.py record FILE --snapshot PATH [--slow] [--modules a,b]
    python3 tests/benchdeps.py forget FILE

A bench file with no DATA entry always runs and is never recorded; a glob in
DATA that matches nothing is an error (a rename must not silently drop coverage).
tests/test_benchdeps.py checks both against the real repo.

Not covered, on purpose: GPU driver, macOS, what else is open in Max. Run
tests/bench.sh (no flag) for the full regression set.
"""
import ast
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RECORD = Path(os.environ.get("BENCH_GREEN") or ROOT / "tests" / "jobs" / "bench_green.json")

_MACHINERY = ["tests/bench/bench.js", "tests/bench/bench.maxpat",
              "tests/bench/bench_default.genjit", "tests/bench/codeboxes/*.gen"]
_MODULE_BENCH = ["tests/bench/bench_module.js", "tests/bench/bench_module.maxpat",
                 "tests/bench/bench_module_empty.maxpat", "package/javascript/*.js"]
_FLUID_CODEBOXES = ["src/f_vf_fluid/codebox_*.gen"]

# Data inputs per bench file, globs relative to the repo root. Python imports are
# derived, so they are not listed here. Every tests/bench_*.py needs an entry.
DATA = {
    "bench_control": _MACHINERY,
    "bench_selftest": _MACHINERY,
    "bench_fft": _MACHINERY,
    "bench_temporal": _MACHINERY,
    "bench_perf": _MACHINERY,
    "bench_fluid": _MACHINERY + _FLUID_CODEBOXES,
    "bench_fluid_probes": _MACHINERY + _FLUID_CODEBOXES,
    "bench_modules": _MODULE_BENCH,            # plus one patcher per module, see PER_MODULE
    "bench_fluid_module": _MODULE_BENCH + ["package/patchers/f_vf_fluid.maxpat"] + _FLUID_CODEBOXES,
}
PER_MODULE = {"bench_modules"}                 # also tracked per patcher in package/patchers/


class MissingInputs(Exception):
    pass


# ----------------------------------------------------------------- hashing

def _sha(path):
    return hashlib.sha256(Path(path).read_bytes()).digest()


def _local_modules(root):
    names = {}
    for d in (root / "tests", root / "build"):
        for p in d.glob("*.py"):
            names.setdefault(p.stem, p)
    return names


def python_deps(stem, root=ROOT):
    """Transitive local imports of tests/<stem>.py (tests/ and build/), as paths."""
    local = _local_modules(root)
    if stem not in local:
        raise MissingInputs(f"no tests/{stem}.py")
    seen, todo = {}, [stem]
    while todo:
        cur = todo.pop()
        if cur in seen or cur not in local:
            continue
        seen[cur] = local[cur]
        for node in ast.walk(ast.parse(local[cur].read_text())):
            if isinstance(node, ast.Import):
                todo += [a.name.split(".")[0] for a in node.names]
            elif isinstance(node, ast.ImportFrom) and node.module:
                todo.append(node.module.split(".")[0])
    return sorted(seen.values())


def input_files(stem, root=ROOT, data=DATA):
    files = set(python_deps(stem, root))
    for pattern in data[stem]:
        hits = [p for p in root.glob(pattern) if p.is_file()]
        if not hits:
            raise MissingInputs(f"{stem}: input glob {pattern!r} matches nothing (renamed or moved?)")
        files.update(hits)
    return sorted(files)


def input_hash(stem, root=ROOT, data=DATA):
    h = hashlib.sha256()
    for p in input_files(stem, root, data):
        h.update(p.relative_to(root).as_posix().encode() + b"\0" + _sha(p))
    return h.hexdigest()


def definition_archetype(root, name):
    """The archetype tests/modulebench.py reads from src/<name>/definition.py (None if there is
    none). The module bench's checks depend on it, but it lives in a definition, not the patcher,
    so it has to be part of the module's hash or changing it would never trigger a rerun."""
    d = Path(root) / "src" / name / "definition.py"
    if d.exists():
        m = re.search(r'"archetype"\s*:\s*"(\w+)"', d.read_text())
        if m:
            return m.group(1)
    return None


def module_hashes(root=ROOT):
    out = {}
    for p in sorted((root / "package" / "patchers").glob("f_*.maxpat")):
        h = hashlib.sha256(p.read_bytes())
        arch = definition_archetype(root, p.stem)
        if arch:                         # no definition, or none read: the plain patcher hash
            h.update(f"\0archetype={arch}".encode())
        out[p.stem] = h.hexdigest()
    return out


def detect_env():
    """'Max 9.2.0; Vsynth 1.7.0' ('unknown' for whatever cannot be read)."""
    def sh(*cmd):
        try:
            return subprocess.run(cmd, capture_output=True, text=True, timeout=10).stdout.strip()
        except Exception:
            return ""
    max_v = sh("defaults", "read", "/Applications/Max.app/Contents/Info", "CFBundleShortVersionString")
    vs = "unknown"
    try:
        vs = json.load(open(os.path.expanduser(
            "~/Documents/Max 9/Packages/Vsynth/package-info.json"))).get("version", "unknown")
    except Exception:
        pass
    return f"Max {max_v.split(' ')[0] or 'unknown'}; Vsynth {vs}"


def snapshot(stem, root=ROOT, data=DATA, env=None):
    snap = {"inputs": input_hash(stem, root, data), "env": env or detect_env()}
    if stem in PER_MODULE:
        snap["modules"] = module_hashes(root)
    return snap


# ----------------------------------------------------------------- record

def load_record(path=None):
    try:
        rec = json.loads(Path(path or RECORD).read_text())
        return rec["files"] if isinstance(rec.get("files"), dict) else {}
    except Exception:
        return {}                                   # missing or corrupt: nothing is known green


def save_record(files, path=None):
    path = Path(path or RECORD)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps({"files": files}, indent=1, sort_keys=True) + "\n")
    tmp.replace(path)


def decide(stem, rec, snap, slow):
    """-> ('run', modules_or_None, reason) | ('skip', None, reason). Pure."""
    if rec is None:
        return "run", None, "no green run on record"
    if rec.get("env") != snap["env"]:
        return "run", None, f"environment changed ({rec.get('env')} -> {snap['env']})"
    if rec.get("inputs") != snap["inputs"]:
        return "run", None, "its inputs changed"
    if slow and not rec.get("slow"):
        return "run", None, "last green run skipped the slow tests"
    if "modules" in snap:
        known = rec.get("modules")
        if known is None:
            return "run", None, "no per-module record"
        todo = sorted(m for m, h in snap["modules"].items() if known.get(m) != h)
        if todo:
            return "run", todo, f"{len(todo)} module patcher(s) changed or new: {', '.join(todo)}"
    return "skip", None, f"unchanged since green on {rec.get('env')} ({rec.get('when', '?')})"


def record_green(files, stem, snap, slow, modules_run=None, when=None):
    """Return the updated record dict after `stem` passed."""
    files = dict(files)
    old = files.get(stem) or {}
    entry = {"inputs": snap["inputs"], "env": snap["env"], "slow": bool(slow),
             "when": when or time.strftime("%Y-%m-%d %H:%M")}
    if "modules" in snap:
        fresh = (old.get("inputs") == snap["inputs"] and old.get("env") == snap["env"]
                 and old.get("modules") is not None)
        if modules_run is not None and fresh:       # partial run: keep the other modules' entries
            kept = {m: h for m, h in old["modules"].items() if m in snap["modules"]}
            kept.update({m: snap["modules"][m] for m in modules_run if m in snap["modules"]})
            entry["modules"] = kept
        elif modules_run is not None:               # base changed since: only what ran is known green
            entry["modules"] = {m: snap["modules"][m] for m in modules_run if m in snap["modules"]}
        else:
            entry["modules"] = dict(snap["modules"])
    files[stem] = entry
    return files


# ----------------------------------------------------------------- cli

def _stem(arg):
    return Path(arg).stem


def cmd_plan(args):
    slow = "--slow" in args
    names = [a for a in args if not a.startswith("--")]
    files = load_record()
    env = detect_env()
    out = []
    for arg in names:
        stem = _stem(arg)
        if stem not in DATA:
            print(f"run  {arg}: no dependency entry in tests/benchdeps.py", file=sys.stderr)
            out.append((arg, None))
            continue
        action, mods, why = decide(stem, files.get(stem), snapshot(stem, env=env), slow)
        print(f"{action:4s} {arg}: {why}", file=sys.stderr)
        if action == "run":
            out.append((arg, mods))
    for arg, mods in out:
        print(f"{arg}\t{','.join(mods) if mods else '-'}")
    return 0


def cmd_snapshot(args):
    stem = _stem(args[0])
    if stem not in DATA:
        return 0                                     # nothing to snapshot; record() will no-op
    json.dump(snapshot(stem), sys.stdout)
    return 0


def _opt(args, name):
    return args[args.index(name) + 1] if name in args else None


def cmd_record(args):
    stem = _stem(args[0])
    snap_path = _opt(args, "--snapshot")
    if stem not in DATA or not snap_path or not Path(snap_path).read_text().strip():
        return 0
    snap = json.loads(Path(snap_path).read_text())
    mods = _opt(args, "--modules")
    mods = [m for m in mods.split(",") if m and m != "-"] if mods else None
    save_record(record_green(load_record(), stem, snap, "--slow" in args, mods))
    return 0


def cmd_forget(args):
    files = load_record()
    if files.pop(_stem(args[0]), None) is not None:
        save_record(files)
    return 0


def main(argv):
    cmds = {"plan": cmd_plan, "snapshot": cmd_snapshot, "record": cmd_record, "forget": cmd_forget}
    if not argv or argv[0] not in cmds:
        print(__doc__)
        return 2
    try:
        return cmds[argv[0]](argv[1:])
    except MissingInputs as e:
        print(f"benchdeps: {e}", file=sys.stderr)
        return 3


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
