"""test_vary_engine.py -- tier-1 check of the f_util_vary engine (T001): runs vary_engine_check.js under Node with a Max-js shim.

Covers: an empty table is a transparent wire (every base out of every outlet), a row varies only its own outlet, seed recall, clamp, amount 0,
group correlation across outlets, chance, sign, drunk, trim, param range defaults, per-row wobble on its own stream, settings-name collisions
(a base named `amount` is a base), table re-apply keeps the bases, bad rows reported. Offline only: Max's own js handling is not covered (T003).

Run:  tests/run.sh -q tests/modules/f_util_vary/test_vary_engine.py
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
node = shutil.which("node")
if node is None:
    print("SKIP: node not found; the f_util_vary engine check was not run")
    sys.exit(0)
r = subprocess.run([node, os.path.join(HERE, "vary_engine_check.js")], capture_output=True, text=True)
sys.stdout.write(r.stdout)
sys.stderr.write(r.stderr)
if r.returncode != 0 or "ok" not in r.stdout:
    print("FAIL: f_util_vary engine check")
    sys.exit(1)
print("PASS: f_util_vary engine check")
