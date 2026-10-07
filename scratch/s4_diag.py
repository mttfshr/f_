"""s4_diag.py -- is the S4 load multiplier (K meshes) linear, or does each mesh carry fixed overhead?
Throwaway diagnostic for tests/spike_scatter.py stage S4. Run:
  uv run --no-project --with numpy --with matplotlib python3 scratch/s4_diag.py
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tests"))
import spike_scatter as ss   # noqa: E402
import caustic_fidelity as cf   # noqa: E402

ss.ensure_bench()
ss.TEX_FIELD = np.asarray(cf.field_texture(), np.float32)
dstar = cf.first_fold_distance()
d, fy = 3.5 * dstar, -1.0

# (label, n, r, psize, K)
cases = [
    ("tiny lattice 64^2 (4k pts), K=32     -> pure per-mesh overhead?", 64, 1024, 3, 32),
    ("tiny lattice 64^2 (4k pts), K=8      -> same, smaller K", 64, 1024, 3, 8),
    ("1M pts, psize 1 (no fill), K=16      -> vertex/CPU side only", 1024, 1024, 1, 16),
    ("1M pts, psize 3, K=16 (repeat A)", 1024, 1024, 3, 16),
    ("1M pts, psize 3, K=16 (repeat B)", 1024, 1024, 3, 16),
    ("1M pts, psize 3, K=4, again          -> noise at the cap", 1024, 1024, 3, 4),
]
for label, n, r, ps, k in cases:
    ms, errs = ss._period_ms(n, r, d, fy, ps, k)
    print(f"  {label}: {ms:6.1f} ms/frame (errors {errs})", flush=True)
ss.run(ss.white(), ss.TEX_FIELD, [["k", 1], ["n", 64]], settle=6)
