#!/usr/bin/env python3
"""Measure a candidate f_vf_seeds definition against the shipped patcher (T019).
Renders the salted search codeboxes next to the candidate, builds it, compares with drift.compare.
Usage: build/py.sh scratch/seeds_measure.py [candidate_dir]   (default scratch/seeds_cand)
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp   # noqa: E402
import drift                 # noqa: E402
import types
_src = Path(drift.__file__).read_text().replace('len(ex[cat]) < 6', 'len(ex[cat]) < 400')
drift = types.ModuleType('drift_full'); drift.__file__ = str(ROOT / 'build' / 'drift.py'); exec(compile(_src, 'drift_full', 'exec'), drift.__dict__)

cand = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "src" / "f_vf_seeds"
defn = bp.load_definition(cand / "definition.py")
built = json.loads(json.dumps(bp.build(defn)))
shipped = json.load(open(ROOT / "package/patchers/f_vf_seeds.maxpat"))["patcher"]
counts, ex = drift.compare(built["patcher"], shipped)
print({k: v for k, v in counts.items() if v} or "EXACT")
for k, lst in ex.items():
    for e in lst:
        print(f"  {k}: {e}")
