"""Scratch diagnostic: which feature of the chain makes GPU and mirror diverge first (frame-by-frame)."""
GROUP = "record"
ORDER = 91
import paths as _paths
import sys
sys.path.insert(0, str(_paths.REPO / "tests" / "modules" / "wave_field"))
import numpy as np
import bench_wave_field as bw
import wave_field_mirror as wfm
from harness import note, run

CASES = {
    "strike only": (dict(speed=0.25, damping=0.05), dict(speed=0.25, damping=0.05, strike_id=1.0), False),
    "strike + edge": (dict(speed=0.25, damping=0.05, edge=0.5), dict(speed=0.25, damping=0.05, edge_amt=0.5, strike_id=1.0), False),
    "strike + exciter": (dict(speed=0.25, damping=0.05, amplitude=1.0, x=0.4, y=0.6),
                         dict(speed=0.25, damping=0.05, amplitude=1.0, exc_x=0.4, exc_y=0.6, strike_id=1.0), False),
    "strike + force": (dict(speed=0.25, damping=0.05, force=0.5),
                       dict(speed=0.25, damping=0.05, force=0.5, src_force=1.0, strike_id=1.0), True),
}


def test_diag():
    for label, (mkw, gkw, use_force) in CASES.items():
        errs, m, g, ph = bw.chain_vs_mirror(8, tuple(range(1, 9)), mkw, gkw, use_force=use_force)
        note(label, "  ".join(f"{f}:{e:.1e}" for f, e in errs.items()))


if __name__ == "__main__":
    sys.exit(run(globals()))
