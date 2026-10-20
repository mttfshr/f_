"""
vf_repulse_mirror.py -- NumPy mirror of the f_vf_repulse shader (the codebox inline in
src/f_vf_repulse/definition.py),
float32 throughout, in the codebox's own order of operations:

  1. the norm -> [reach, 1-reach] remap (zu, zv) -- a codebox-only behavior the doc's
     Algorithm block does not mention; the mirror follows the codebox,
  2. the 16 unrolled ring samples at zu/zv + dir*reach through gpu_sim.sample (bilinear,
     texel-centre, clamp-to-edge -- the codebox's default boundmode),
  3. Rec. 601 luma (x*0.299 + y*0.587 + z*0.114) of each sample,
  4. thresholded weights w_i = max(luma_i - threshold, 0) times the OOB step gate
     (second codebox-only behavior; inert for reach >= 0 because the remap keeps every
     ring position inside [0, 1]),
  5. the four floor(mode) branches (Cancel / Max / Abs Add / Turbulent) with the
     codebox's own scan order and guard constants (0.0001, turb scale 0.2),
  6. the encoding clamp(fx * gain * 0.5 + 0.5, 0, 1) and the bypass mix to the neutral
     vecfield (0.5, 0.5, 0.5, 1.0).

Input: in1 = source texture, (H, W, 4) float32. Returns the f_vecfield output (H, W, 4).

`bug` values are the mutations the tests must catch, each a plausible real mistake:
  - "attract"   the ring direction sign flipped (field points toward bright regions)
  - "swap_xy"   the field's x and y channels swapped before encoding
  - "no_gate"   the out-of-bounds step gate dropped (clamped OOB reads keep their weight)
  - "rec709"    Rec. 709 luma coefficients (0.2126/0.7152/0.0722) instead of Rec. 601
  - "no_scale"  the encoding's 0.5 field scale dropped (fx * gain + 0.5)
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32

# The codebox's 16 evenly spaced unit directions, exactly as written there (four decimals).
DX = np.array([1.0000, 0.9239, 0.7071, 0.3827, 0.0000, -0.3827, -0.7071, -0.9239,
               -1.0000, -0.9239, -0.7071, -0.3827, 0.0000, 0.3827, 0.7071, 0.9239], F32)
DY = np.array([0.0000, 0.3827, 0.7071, 0.9239, 1.0000, 0.9239, 0.7071, 0.3827,
               0.0000, -0.3827, -0.7071, -0.9239, -1.0000, -0.9239, -0.7071, -0.3827], F32)


def repulse(src, gain=4.0, reach=0.1, threshold=0.3, mode=0.0, bypass=0.0, bug=None):
    """One frame. src: (H, W, 4) float32. Returns the f_vecfield output (H, W, 4)."""
    h, w = src.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    r = F32(reach)
    thr = F32(threshold)
    zu = (nx * (F32(1.0) - F32(2.0) * r) + r).astype(F32)
    zv = (ny * (F32(1.0) - F32(2.0) * r) + r).astype(F32)

    if bug == "rec709":
        cr, cg, cb = F32(0.2126), F32(0.7152), F32(0.0722)
    else:
        cr, cg, cb = F32(0.299), F32(0.587), F32(0.114)

    ws = []
    for i in range(16):
        su = (zu + DX[i] * r).astype(F32)
        sv = (zv + DY[i] * r).astype(F32)
        s = g.sample(src, su, sv)
        luma = (s[..., 0] * cr + s[..., 1] * cg + s[..., 2] * cb).astype(F32)
        w_i = np.maximum(luma - thr, F32(0.0))
        if bug != "no_gate":
            gate = ((su >= F32(0.0)).astype(F32) * (su <= F32(1.0)).astype(F32)
                    * (sv >= F32(0.0)).astype(F32) * (sv <= F32(1.0)).astype(F32))
            w_i = (w_i * gate).astype(F32)
        ws.append(w_i.astype(F32))

    # The codebox negates every direction (-dx_i, -dy_i); "attract" flips that sign.
    sgn = F32(1.0) if bug == "attract" else F32(-1.0)

    m = np.floor(F32(mode))
    if m < F32(0.5):
        # Mode 0: Cancel -- straight accumulation of (-dir_i * w_i)
        fx, fy = F32(0.0), F32(0.0)
        for i in range(16):
            fx = (fx + sgn * DX[i] * ws[i]).astype(F32)
            fy = (fy + sgn * DY[i] * ws[i]).astype(F32)
    elif m < F32(1.5):
        # Mode 1: Max -- running-max scan, strongest single sample wins (ties: last wins)
        bx = np.zeros((h, w), F32)
        by = np.zeros((h, w), F32)
        bw = np.zeros((h, w), F32)
        for i in range(16):
            t = (ws[i] >= bw).astype(F32)          # step(bw, w_i)
            bx = (bx * (F32(1.0) - t) + (sgn * DX[i]) * t).astype(F32)
            by = (by * (F32(1.0) - t) + (sgn * DY[i]) * t).astype(F32)
            bw = (bw * (F32(1.0) - t) + ws[i] * t).astype(F32)
        fx = (bx * bw).astype(F32)
        fy = (by * bw).astype(F32)
    elif m < F32(2.5):
        # Mode 2: Abs Add -- magnitudes summed, normalized to the cancel direction
        cx, cy, am = F32(0.0), F32(0.0), F32(0.0)
        for i in range(16):
            cx = (cx + sgn * DX[i] * ws[i]).astype(F32)
            cy = (cy + sgn * DY[i] * ws[i]).astype(F32)
            am = (am + ws[i]).astype(F32)
        cm = np.maximum(np.sqrt(np.maximum(cx * cx + cy * cy, F32(0.0))), F32(0.0001))
        fx = (cx / cm * am).astype(F32)
        fy = (cy / cm * am).astype(F32)
    else:
        # Mode 3: Turbulent -- cancel vector plus perpendicular curl in cancellation zones
        cx, cy, am = F32(0.0), F32(0.0), F32(0.0)
        for i in range(16):
            cx = (cx + sgn * DX[i] * ws[i]).astype(F32)
            cy = (cy + sgn * DY[i] * ws[i]).astype(F32)
            am = (am + ws[i]).astype(F32)
        cm = np.sqrt(np.maximum(cx * cx + cy * cy, F32(0.0)))
        curl_x = (-cy).astype(F32)
        curl_y = cx
        ratio = (am / np.maximum(cm, F32(0.0001))).astype(F32)
        turb = np.clip((ratio - F32(1.0)) * F32(0.2), F32(0.0), F32(1.0))
        fx = (cx + curl_x * turb).astype(F32)
        fy = (cy + curl_y * turb).astype(F32)

    if bug == "swap_xy":
        fx, fy = fy, fx
    enc = F32(gain)
    if bug != "no_scale":
        enc = enc * F32(0.5)
    field_x = np.clip(fx * enc + F32(0.5), F32(0.0), F32(1.0)).astype(F32)
    field_y = np.clip(fy * enc + F32(0.5), F32(0.0), F32(1.0)).astype(F32)

    # mix(vec(field_x, field_y, 0.5, 1.0), vec(0.5, 0.5, 0.5, 1.0), bypass)
    b = F32(bypass)
    out = np.stack([field_x * (F32(1.0) - b) + F32(0.5) * b,
                    field_y * (F32(1.0) - b) + F32(0.5) * b,
                    np.full((h, w), F32(0.5)),
                    np.ones((h, w), F32)], axis=-1).astype(F32)
    return out