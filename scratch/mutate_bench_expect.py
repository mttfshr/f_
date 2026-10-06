#!/usr/bin/env python3
"""Mutation check for tests/test_bench_expect.py against tests/bench_modules.py.
Baseline must be green first; every mutant must turn the test red; the file is always restored."""
import hashlib
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TARGET = REPO / "tests/bench_modules.py"
orig = TARGET.read_text()
sha = hashlib.sha256(orig.encode()).hexdigest()

MUTANTS = [
    ("never flags (d > tol + 1)", "        if d > tol:\n", "        if d > tol + 1:\n"),
    ("no implicit processor out1", "and 1 not in expect:", "and 1 not in expect and False:"),
    ("implicit out1 reported when missing", "            if k not in implicit:\n", "            if True:\n"),
    ("explicit missing frame silent", "            if k not in implicit:\n", "            if False:\n"),
    ("vec compares the wrong channel", "a[..., 2] = np.float32(0.5)", "a[..., 1] = np.float32(0.5)"),
    ("vec ignores its alpha rule", "        a[..., 3] = np.float32(1.0)\n        return a, spec[2]", "        return a, spec[2]"),
    ("in always uses inlet 1", "return inputs[spec[1]], 0.0", "return inputs[1], 0.0"),
    ("vec always uses inlet 1", "a = inputs[spec[1]].copy()", "a = inputs[1].copy()"),
    ("tolerance ignored for vec", "return a, spec[2]", "return a, 0.0"),
    ("shape check dropped", 'if spec[0] != "const" and want.shape != got.shape:', "if False:"),
    ("const shape check applied", 'if spec[0] != "const" and want.shape != got.shape:', "if want.shape != got.shape:"),
    ("table: f_grain dropped", '    "f_grain": {1: IN1, 2: IN1, 3: IN1},', ""),
    ("table: f_chladni out3 dropped", '        3: ("const", (0.0, 0.0, 0.0, 1.0), 0.0),        # magnitude: black\n', ""),
    ("table: f_masonry dropped", '    "f_masonry": {2: IN1},', ""),
    ("table: prism out3 dropped", '"f_vf_prism": {2: IN1, 3: ("vec", 2, 0.0042)},', '"f_vf_prism": {2: IN1},'),
    ("table: outlet past n_out", '"f_masonry": {2: IN1},', '"f_masonry": {2: IN1, 7: IN1},'),
    ("table: inlet the module lacks", '"f_stipple": {1: IN1, 2: IN1, 3: IN1},', '"f_stipple": {1: IN1, 2: IN1, 3: ("in", 4)},'),
]


def run_tests():
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", PATH="/opt/homebrew/bin:" + os.environ["PATH"])
    for p in (REPO / "tests").rglob("__pycache__"):
        subprocess.run(["rm", "-rf", str(p)])
    r = subprocess.run(["uv", "run", "--no-project", "--with", "numpy", "python3", "tests/test_bench_expect.py"],
                       cwd=REPO, env=env, capture_output=True, text=True)
    return r.returncode


try:
    if run_tests() != 0:
        sys.exit("ABORT: the baseline is red; a mutation run is only evidence on a green baseline")
    print("baseline green")
    survivors = []
    for label, old, new in MUTANTS:
        if orig.count(old) != 1:
            print(f"SKIP  {label}: anchor found {orig.count(old)} times")
            survivors.append(label + " (anchor)")
            continue
        TARGET.write_text(orig.replace(old, new))
        rc = run_tests()
        print(("caught  " if rc != 0 else "SURVIVED") + "  " + label)
        if rc == 0:
            survivors.append(label)
finally:
    TARGET.write_text(orig)
    assert hashlib.sha256(TARGET.read_text().encode()).hexdigest() == sha, "restore failed"
    for p in (REPO / "tests").rglob("__pycache__"):
        subprocess.run(["rm", "-rf", str(p)])
print("restored; survivors:", survivors or "none")
