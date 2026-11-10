"""vf_erode_mirror.py -- float32 NumPy mirror of f_vf_erode, the erosion model (spec 2026-11-10, plan ADR-1 to ADR-6, T073).

Written offline by Claude from the spec, the plan and the form of scratch/experiments/f_ink_look/vecfield_mock.py (local). Nothing here
has run against Max; every constant marked INFERRED is a starting value to be tuned live. The stage split follows the plan:
load (wetting), step = flow + pigment (one solver step), enc (composite and thickness).

State: water depth w (h,w); pigment in suspension s (h,w,3); pigment on the paper p (h,w,3); loaded (the ADR-5 flag);
escaped (float64, the net pigment per channel that went into the cells beyond the frame edge) and escaped_w (water), and entered / entered_w
(what came back in, which must stay 0), kept only so conservation can be tested.

Units: texels at one size. Scaling every length and rate to the render size (spec FR-111) is NOT mirrored yet; the bench decides how.
The mirror scatters face fluxes with array slices; the codebox gathers the same four faces per cell. The two are the same sums in a
different order, so float32 rounding can differ at the 1e-7 level (inferred).
"""
import numpy as np

F32 = np.float32

GAMMA = 2.2          # INFERRED: display to linear light by a plain power (T068); the real transfer curve is a tuning choice
EPS = 0.004          # INFERRED: smallest linear value taken by the log (Darker); the mocks used 0.004
LUMA = np.array([0.2126, 0.7152, 0.0722], F32)
RELIEF = 6.0         # INFERRED: terrain luma 0..1 to height; the mock's hills were 0..6
FIELD_SCALE = 0.1    # INFERRED: decoded vecfield (-1..1) to a face velocity at push 1; the mock's tilt was 0.06

DEFAULTS = dict(
    polarity="darker",   # T060, T075
    flow=0.4,            # mock G
    push=1.0,
    lift=0.9,            # mock KE
    settle=0.004,        # mock KD
    dry=0.0016,          # mock evaporation per step
    speed=1.0,           # step size multiplier, bounded by vmax
    flood=1.0,           # depth a wetting adds
    wlim=0.5, film=0.15, mix=0.04, vmax=0.2, sp0=0.03,   # mock constants; vmax and mix chosen so no cell can give away more than it holds
    edge="open",         # T066; "closed" exists for the conservation test only
)


def zap(a):
    a = np.asarray(a, dtype=F32)
    return np.where(np.isfinite(a), a, F32(0)).astype(F32)


def to_linear(x):
    return (np.maximum(zap(x), 0) ** F32(GAMMA)).astype(F32)


def to_display(x):
    return (np.maximum(zap(x), 0) ** F32(1.0 / GAMMA)).astype(F32)


def pigment_from_picture(img, polarity):
    """Darker: absorbance, the negative log of linear light, bounded to 0 .. -log(EPS) so no layer goes negative. Lighter: linear light."""
    lin = to_linear(img[..., :3])
    if polarity == "darker":
        return (-np.log(np.clip(lin, F32(EPS), F32(1)))).astype(F32)
    return lin


def new_state(h, w):
    return dict(w=np.zeros((h, w), F32), s=np.zeros((h, w, 3), F32), p=np.zeros((h, w, 3), F32),
                loaded=False, escaped=np.zeros(3), escaped_w=0.0, entered=np.zeros(3), entered_w=0.0)


def load(st, img, polarity="darker", flood=1.0):
    """A wetting: the picture becomes the pigment on the paper, the suspension is emptied, the frame is flooded (T061, FR-107)."""
    st = dict(st)
    st["p"] = pigment_from_picture(img, polarity)
    st["s"] = np.zeros_like(st["s"])
    st["w"] = (st["w"] + F32(flood)).astype(F32)
    st["loaded"] = True
    return st


def terrain_height(tex):
    if tex is None:
        return None
    return (zap(tex[..., :3]) @ LUMA * F32(RELIEF)).astype(F32)


def field_uv(field):
    """Decoded (Fx, Fy) in -1..1; None (unconnected, from the flag, not the value) is zero."""
    if field is None:
        return None
    f = zap(field[..., :2])
    return ((f[..., 0] - F32(0.5)) * 2).astype(F32), ((f[..., 1] - F32(0.5)) * 2).astype(F32)


def step(st, terrain=None, field=None, bug=None, **kw):
    """One solver step: water through the faces, pigment carried with it, drying, then lift and settle (plan ADR-3)."""
    P = dict(DEFAULTS, **kw)
    w, s, p = st["w"], st["s"], st["p"]
    h, wd = w.shape
    T = np.zeros((h, wd), F32) if terrain is None else terrain
    fx, fy = (np.zeros((h, wd), F32),) * 2 if field is None else field
    fx, fy = fx * F32(P["push"] * FIELD_SCALE), fy * F32(P["push"] * FIELD_SCALE)
    if bug == "push_backward":
        fx, fy = -fx, -fy
    flow, speed, vmax = F32(P["flow"]), F32(P["speed"]), F32(P["vmax"])

    # Water. The virtual cell beyond the edge has the terrain continued linearly and the edge cell's own depth for the slope
    # (so a flat frame has no edge flow and a terrain that slopes out drains), and depth 0 as a donor (nothing comes back in).
    Tp = np.pad(T, 1, mode="reflect", reflect_type="odd")
    eta = Tp + np.pad(w, 1, mode="edge")
    eta[1:-1, 1:-1] = T + w
    Fxp, Fyp = np.pad(fx, 1, mode="edge"), np.pad(fy, 1, mode="edge")
    vx = speed * (-flow * (eta[1:-1, 1:] - eta[1:-1, :-1]) + F32(0.5) * (Fxp[1:-1, 1:] + Fxp[1:-1, :-1]))
    vy = speed * (-flow * (eta[1:, 1:-1] - eta[:-1, 1:-1]) + F32(0.5) * (Fyp[1:, 1:-1] + Fyp[:-1, 1:-1]))
    if bug != "no_flux_cap":
        vx, vy = np.clip(vx, -vmax, vmax), np.clip(vy, -vmax, vmax)
    wz = np.pad(w, 1, mode="edge" if bug == "edge_reenter" else "constant")
    wl, wr, wu, wdn = wz[1:-1, :-1], wz[1:-1, 1:], wz[:-1, 1:-1], wz[1:, 1:-1]
    wux, wuy = np.where(vx > 0, wl, wr), np.where(vy > 0, wu, wdn)
    qx = vx * np.minimum(wux, F32(P["wlim"])) * np.clip(wux / F32(P["film"]), 0, 1)
    qy = vy * np.minimum(wuy, F32(P["wlim"])) * np.clip(wuy / F32(P["film"]), 0, 1)
    if P["edge"] == "closed":
        qx[:, 0] = qx[:, -1] = 0
        qy[0, :] = qy[-1, :] = 0
    conc = np.pad(s / np.maximum(w, F32(1e-3))[..., None], ((1, 1), (1, 1), (0, 0)), mode="edge" if bug == "edge_reenter" else "constant")
    cl, cr, cu, cd = conc[1:-1, :-1], conc[1:-1, 1:], conc[:-1, 1:-1], conc[1:, 1:-1]
    mix = F32(P["mix"])
    sx = np.where((vx > 0)[..., None], cl, cr) * qx[..., None] + (mix * np.minimum(np.minimum(wl, wr), 1))[..., None] * (cl - cr)
    sy = np.where((vy > 0)[..., None], cu, cd) * qy[..., None] + (mix * np.minimum(np.minimum(wu, wdn), 1))[..., None] * (cu - cd)
    if P["edge"] == "closed":
        sx[:, 0] = sx[:, -1] = 0
        sy[0, :] = sy[-1, :] = 0
    wz[1:-1, :-1] -= qx; wz[1:-1, 1:] += qx; wz[:-1, 1:-1] -= qy; wz[1:, 1:-1] += qy
    sz = np.pad(s, ((1, 1), (1, 1), (0, 0)))
    sz[1:-1, :-1] -= sx
    if bug != "drop_receiver":
        sz[1:-1, 1:] += sx
    sz[:-1, 1:-1] -= sy; sz[1:, 1:-1] += sy
    out_w = float(wz.sum(dtype=np.float64) - wz[1:-1, 1:-1].sum(dtype=np.float64))
    out_s = sz.sum(axis=(0, 1), dtype=np.float64) - sz[1:-1, 1:-1].sum(axis=(0, 1), dtype=np.float64)
    bs, bw = sz.copy(), wz.copy()
    bs[1:-1, 1:-1] = 0
    bw[1:-1, 1:-1] = 0
    in_s = -np.minimum(bs, 0).sum(axis=(0, 1), dtype=np.float64)      # pigment that came back in through the edge (must stay 0)
    in_w = float(-np.minimum(bw, 0).sum(dtype=np.float64))
    w, s = wz[1:-1, 1:-1].copy(), sz[1:-1, 1:-1].copy()

    w = np.maximum(w - F32(P["dry"]) * speed, 0).astype(F32)
    # Lift and settle, cell by cell, from the current slope and push (plan ADR-3; the speed measure is INFERRED).
    gy, gx = np.gradient(T + w)
    cx, cy = fx - flow * gx, fy - flow * gy
    spd = np.minimum(np.sqrt(cx * cx + cy * cy) * speed, vmax) * np.clip(w / F32(P["film"]), 0, 1)
    lift = p * np.clip(F32(P["lift"]) * spd * np.minimum(w, 1), 0, 0.5)[..., None]
    p, s = p - lift, s + lift
    drop = s * np.clip(np.maximum(F32(P["settle"]) * speed * np.clip(1 - spd / F32(P["sp0"]), 0, 1), np.clip(1 - w / F32(0.08), 0, 1)), 0, 1)[..., None]
    p, s = p + drop, s - drop
    return dict(w=w, s=s.astype(F32), p=p.astype(F32), loaded=st["loaded"], escaped=st["escaped"] + out_s, escaped_w=st["escaped_w"] + out_w,
                entered=st["entered"] + in_s, entered_w=st["entered_w"] + in_w)


def run(st, steps, terrain=None, field=None, **kw):
    for _ in range(steps):
        st = step(st, terrain, field, **kw)
    return st


def enc(st, picture, bg=None, polarity="darker"):
    """Outlet 0 (the composite, display encoded) and outlet 1 (thickness: pigment on the paper, as luma). Before the first wetting the
    picture is shown as if loaded (ADR-5, T076). Alpha comes from the picture."""
    if st["loaded"]:
        p, s = st["p"], st["s"]
    else:
        p, s = pigment_from_picture(picture, polarity), np.zeros_like(st["s"])
    if polarity == "darker":
        base = np.ones_like(p) if bg is None else to_linear(bg[..., :3])
        lin = base * np.exp(-(p + s))
    else:
        base = np.zeros_like(p) if bg is None else to_linear(bg[..., :3])
        lin = base + p + s
    out = np.zeros(picture.shape[:2] + (4,), F32)
    out[..., :3] = to_display(lin)
    out[..., 3] = picture[..., 3]
    return out, (p @ LUMA).astype(F32)


def totals(st):
    """Pigment per channel, on the paper plus in suspension, as float64."""
    return st["p"].sum(axis=(0, 1), dtype=np.float64) + st["s"].sum(axis=(0, 1), dtype=np.float64)
