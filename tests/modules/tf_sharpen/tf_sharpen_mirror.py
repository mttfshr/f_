"""
tf_sharpen_mirror.py -- NumPy mirror of the tf_sharpen shader: the functions (and the constants and
fixtures they need) that tests/modules/tf_sharpen/bench_tf_sharpen.py imports. Extracted
from test_tf_sharpen.py in Phase C, 2026-10-18; the tests stay there.
"""
import numpy as np
import gpu_sim as g  # noqa: E402

F32 = np.float32
EPS_TRACE = F32(1e-6)   # plan ADR-3: tensormap T019 convention, encoded units
H = W = 32

nx, ny, _, _ = g.grid(H, W)


# --- mirror -------------------------------------------------------------

def sharpen(t, sharpen=1.0, eps=EPS_TRACE, clip=True, mutate=None, bypass=False):
    """One pass of the planned codebox. t: outlet-0-format RGBA texture.

    mutate: None | "drop_max" (T009a: gamma used without max(gamma, 0))
            | "swap"    (T009b: gap sign error == swapped diagonals).
    bypass: module bypass -> exact passthrough (spec acceptance row).
    Floor gate: trace < eps -> exact passthrough of the sampled input.
    """
    s = g.nearest(t, nx, ny)
    xx = s[..., 0]
    xy = (s[..., 1] - F32(0.5)) * F32(2)
    yy = s[..., 2]
    tr = xx + yy
    gam = F32(sharpen) if mutate == "drop_max" else np.maximum(F32(sharpen), F32(0))
    iso_part = (F32(1) - gam) * F32(0.5) * tr
    if mutate == "swap":
        ox = gam * yy + iso_part
        oz = gam * xx + iso_part
    else:
        ox = gam * xx + iso_part
        oz = gam * yy + iso_part
    oy = gam * xy * F32(0.5) + F32(0.5)
    out = g.texture(H, W)
    if clip:
        out[..., 0] = np.clip(ox, 0, 1)
        out[..., 1] = np.clip(oy, 0, 1)
        out[..., 2] = np.clip(oz, 0, 1)
    else:
        out[..., 0], out[..., 1], out[..., 2] = ox, oy, oz
    out[..., 3] = F32(1)
    iso = tr < eps
    # floor/vs_black passthrough: rgb exactly the input's, but the OUTLET
    # contract is A = 1 always (f_tensor_type.md outlet 0) — the codebox's
    # vec(..., 1.0) never transmits the incoming alpha; the mirror matches
    # (2026-10-17: the first draft copied s[iso] whole, keeping the
    # vs_black block's alpha 0 — a one-per-block false diff on the bench).
    out[iso, :3] = s[iso, :3]
    out[iso, 3] = F32(1)
    if bypass:
        out[...] = s                  # exact passthrough (module bypass)
    return g.store_float32(out)
