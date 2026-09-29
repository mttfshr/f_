"""T038a: cost and noise gain of the adv force tap grid vs taps, at HD and 4K force sizes.
Needs the stage bench open.  uv run --no-project --with numpy python3 -u scratch/measure_adv_taps.py
"""
import sys
sys.path.insert(0, "tests")
import numpy as np
import bench_fluid as b
import fluid_mirror as fm
from fluid_mirror import Params
from test_fluid_mirror import rand_force, smooth_state

N = b.N
st = smooth_state(N, 1)
for (fh, fw, name) in ((1080, 1920, "HD"), (2160, 3840, "4K")):
    force = rand_force(fh, fw, 31)
    ideal = ((b._area(fh) @ force[..., 0].astype(np.float64) @ b._area(fw).T) - 0.5).std() * 2.0
    for taps in (1, 4, 6, 8, 10, 12, 16):
        ms, chain, bound = b.stage_cost("adv", [b.BANG, force, st], (N, N), {"taps": taps})
        out = b.g_adv(fm.zero_state(N), force, Params(dt=0.0, force=1.0, src_vecfield=1.0, taps=taps))
        gain = float(out[..., 0].std()) / ideal
        print(f"{name} taps={taps:2d}: adv {ms:6.3f} ms/pass ({'GPU bound' if bound else 'upper bound'})   noise gain {gain:5.2f}", flush=True)
