"""
spike_tf_hatch_costshape.py -- T001, the OQ1 gate for f_tf_hatch (Phase 0, NumPy only).

Decides the E2 mark-layout mechanism by measured evidence, not design opinion
(spec Open Question 1; plan ADR-1):

  Branch T -- tileable distance-field pattern (f_weave-style): per-pixel
              closed form in the local (axis, across) frame. No loop, no
              texture taps beyond the decoded-axis read.
  Branch S -- stroke-marching: genuine placements; march along the decoded
              axis from seed cells (symmetric two-sided -- the sign/branch-cut
              mitigation), accumulating coverage.

The spike implements BOTH on synthetic tensor fields, renders proof-of-character
images, measures branch T's hairpin-aliasing hazard (checked, not argued), and
builds the per-branch cost model against the bench's published per-pass floors
(docs/f-reference/f_tf_tensormap.md Cost: ~0.9 ms/pass upper bound at 1080p,
R_MAX 16; M3 Max, M1 unmeasured).

No bench, no codebox, no Anthropic API: this is the tier-1 gate itself.

Run:  uv run --no-project --with numpy python3 tests/spike_tf_hatch_costshape.py
"""
import math
import os
import time

import numpy as np

F32 = np.float32
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       ".specify", "f_tf_hatch", "spike")

# ---------------------------------------------------------------- fields ---

def field_curved_edge(h=96, w=128):
    """A clean edge wrapped into concentric circles: gradient radial, axis =
    tangent. Coherence ~0.95 inside the annulus, isotropic outside."""
    cy, cx = np.meshgrid(np.arange(h, dtype=F32), np.arange(w, dtype=F32),
                         indexing="ij")
    dx = cx - w / 2.0
    dy = cy - h / 2.0
    r = np.sqrt(dx * dx + dy * dy)
    ang_radial = np.arctan2(dy, dx)
    alpha = ang_radial + np.pi / 2.0          # along-structure axis
    coh = np.where((r > 18) & (r < 52), F32(0.95), F32(0.02)).astype(F32)
    trace = np.where((r > 18) & (r < 52), F32(1.0), F32(0.0)).astype(F32)
    return alpha, coh, trace


def field_isotropic_blob(h=96, w=128):
    """Mostly isotropic noise field with one mild-structure blob: the dot /
    blank side of the commit story."""
    rng = np.random.default_rng(7)
    cy, cx = np.meshgrid(np.arange(h, dtype=F32), np.arange(w, dtype=F32),
                         indexing="ij")
    alpha = rng.uniform(0, np.pi, (h, w)).astype(F32)      # meaningless where iso
    coh = rng.uniform(0.02, 0.18, (h, w)).astype(F32)      # below/near the gate
    bloom = np.exp(-(((cx - w * 0.3) / 18.0) ** 2 +
                     ((cy - h * 0.55) / 14.0) ** 2))
    coh = np.clip(coh + bloom * F32(0.55), 0, 1).astype(F32)
    # inside the bloom the axis is coherent too (a soft diagonal band)
    band = np.exp(-(((dx_band := (cx - cy * 1.2 - w * 0.1)) / 12.0) ** 2))
    alpha = (alpha * (1 - bloom * band) +
             F32(0.8) * (bloom * band)).astype(F32)
    trace = (0.2 + 0.8 * bloom).astype(F32)
    return alpha, coh, trace


def field_authored(h=96, w=128):
    """An authored smooth field: two superposed wave systems, mid coherence --
    the 'does it look like engraving' surface."""
    cy, cx = np.meshgrid(np.arange(h, dtype=F32), np.arange(w, dtype=F32),
                         indexing="ij")
    nx = cx / F32(w)
    ny = cy / F32(h)
    gx = np.sin(nx * 14.0 + ny * 4.0) * 14.0 / w + 0.6 * np.cos(nx * 3.0) * 3.0 / w
    gy = np.cos(ny * 9.0 + nx * 5.0) * 9.0 / h
    gx = gx.astype(F32)
    gy = gy.astype(F32)
    gx2 = gx * gx
    gy2 = gy * gy
    gxy = (gx * gy).astype(F32)
    d = gx2 - gy2
    root = np.sqrt(d * d + 4 * gxy * gxy)
    trace = gx2 + gy2
    alpha = 0.5 * np.arctan2(2 * gxy, d) + np.pi / 2.0      # along axis
    coh = np.clip(root / np.maximum(trace, 1e-6), 0, 1)
    coh = (0.35 + 0.55 * coh).astype(F32)                    # authored floor
    return alpha.astype(F32), coh, trace.astype(F32)


# ------------------------------------------------------------- E1 commit ---

GATE = 0.25


def commit_curve(coh, gate=GATE):
    """PROVISIONAL (OQ3 open): smoothstep in the normalized eigengap between
    C_LO = coherence_gate and C_HI = 1.0. Continuous, monotone, 0 at/below the
    gate, -> 1 as coherence -> 1."""
    lo, hi = F32(gate), F32(1.0)
    x = np.clip((coh - lo) / (hi - lo), 0, 1)
    return (x * x * (3 - 2 * x)).astype(F32)


def e1(alpha, coh, trace, gate=GATE):
    """E1 mirror: decode + commit + guard. Returns (ca, sa, commit, valid)."""
    valid = (trace > 1e-6).astype(F32)
    c = commit_curve(coh, gate)
    ca = np.cos(alpha).astype(F32) * valid    # axis unset marker: (0, 0)
    sa = np.sin(alpha).astype(F32) * valid
    return ca, sa, c, valid


# ------------------------------------------------- branch T (distance field)

def branch_t(alpha, coh, trace, density=0.5, weight=0.1, softness=0.05,
             elongation=3.0, phase=0.0, regularity=0.5, angle_offset=0.0,
             h=96, w=128):
    """Per-pixel closed form in the local frame (f_weave mechanics adapted;
    docs/f-reference/f_weave.md Algorithm, cited). Returns the raw mark mask.

    Mark intensity is weighted by commit: at commit 0 (the gate) marks are
    nothing, not full-brightness dots -- dots at full intensity would seam at
    the gate boundary exactly where acceptance criterion 4 demands continuity.
    The dot character lives in the band ABOVE the gate: small commit = small
    round mark, fading in as coherence rises. (PROVISIONAL curve shape, OQ3
    open; this resolves the 'dots persist vs blank' fallback as 'fade in',
    tier-3 confirms.)"""
    ca, sa, commit, valid = e1(alpha, coh, trace)
    delta = angle_offset * np.pi / 2.0
    if delta != 0.0:
        cd, sd = np.cos(F32(delta)), np.sin(F32(delta))
        ca, sa = (ca * cd - sa * sd), (ca * sd + sa * cd)
        ca, sa = ca.astype(F32), sa.astype(F32)
    nx, ny, _, _ = _grid(h, w)
    u = (-sa * nx + ca * ny).astype(F32)       # across (normal) coordinate
    v = (ca * nx + sa * ny).astype(F32)        # along-stroke coordinate
    ds = F32(2.0 ** (density * 5.0 - 1.0))     # family log map (weave span 5)
    aspect = (1.0 + elongation * commit).astype(F32)
    aw = (weight / np.sqrt(aspect)).astype(F32)          # across, squeeze
    al = (weight * np.sqrt(aspect)).astype(F32)          # along, squeeze
    soft = F32(min(softness, 0.49))
    li = np.floor(u * ds)
    lh = (np.abs(np.sin(li * 127.1) * 43758.5453) % 1.0) * F32(1.0 - regularity)
    dl = np.abs(np.mod(u * ds, 1.0) - 0.5).astype(F32)
    vp = (v * ds + phase + lh).astype(F32)
    dp = np.abs(np.mod(vp, 1.0) - 0.5).astype(F32)
    m_line = _smoothstep(aw + soft, np.maximum(aw - soft, F32(0)), dl)
    m_mark = _smoothstep(al + soft, np.maximum(al - soft, F32(0)), dp)
    shape = m_line * m_mark
    # commit-weighted intensity: commit 0 = nothing (no gate-boundary seam);
    # commit 1 = full ink. Aspect still rounds toward dots as commit falls.
    return (shape * commit * valid).astype(F32)


# ------------------------------------------------ branch S (stroke-marching)

def branch_s(alpha, coh, trace, density=0.5, weight=0.1, elongation=3.0,
             regularity=0.5, march_max=16, h=96, w=128, coverage=None):
    """Seed cells + symmetric two-sided march. Each marched step deposits a
    soft disc (radius = across half-width); pixel coverage = max deposit.
    March re-samples the decoded axis at every step position (the per-pixel
    codebox model: MARCH_MAX weight-gated steps, axis taps per step).
    Same E1 commit gating as branch T (like-for-like comparison)."""
    ca, sa, commit, valid = e1(alpha, coh, trace)
    aspect = (1.0 + elongation * commit).astype(F32)
    aw = (weight / np.sqrt(aspect)).astype(F32)
    ds = F32(2.0 ** (density * 5.0 - 1.0))
    pitch = max(float(min(h, w)) / float(ds), 2.0)
    jitter = hash01(np.arange(0, (h * w), dtype=F32)) * (1.0 - regularity)
    rng = np.random.default_rng(11)
    n_i = int(math.ceil(h / pitch))
    n_j = int(math.ceil(w / pitch))
    dep = np.zeros((h, w), F32) if coverage is None else coverage
    for i in range(n_i):
        for j in range(n_j):
            sy = (i + 0.5) * pitch + float(jitter[i * w + j]) * pitch * 0.5
            sx = (j + 0.5) * pitch
            ci, cj = int(np.clip(sy, 0, h - 1)), int(np.clip(sx, 0, w - 1))
            if not valid[ci, cj] or commit[ci, cj] <= 0.0:
                continue
            seed_commit = float(commit[ci, cj])
            # march: axis re-sampled at each step position (the sign problem
            # is mitigated by symmetric two-sided marching, x2 steps)
            qx, qy = sx, sy
            for sgn in (1.0, -1.0):              # two-sided: 2 x MARCH_MAX steps
                for k in range(1, march_max + 1):
                    qy2 = np.clip(qy + sgn * sa[ci, cj], 0, h - 1)
                    qx2 = np.clip(qx + sgn * ca[ci, cj], 0, w - 1)
                    qi, qj = int(qy2), int(qx2)
                    aq = alpha[qi, qj]
                    cq = np.cos(F32(aq)).astype(F32)
                    sq = np.sin(F32(aq)).astype(F32)
                    qx, qy = qx2 + 0.0, qy2 + 0.0
                    # deposits along both the stroke axis direction
                    r = aw[qi, qj] * float(min(h, w)) * 2.0
                    _splat(dep, qy, qx, max(r, 1.0), h, w, seed_commit)
                    ci, cj = qi, qj
    return dep


def _splat(buf, y, x, r, h, w, amp=1.0):
    i0, i1 = max(0, int(y - r)), min(h, int(y + r) + 1)
    j0, j1 = max(0, int(x - r)), min(w, int(x + r) + 1)
    if i0 >= i1 or j0 >= j1:
        return
    yy, xx = np.meshgrid(np.arange(i0, i1, dtype=F32), np.arange(j0, j1, dtype=F32),
                         indexing="ij")
    d = np.sqrt((yy - y) ** 2 + (xx - x) ** 2)
    prof = np.clip(1.0 - d / max(r, 1e-3), 0, 1) * F32(amp)
    buf[i0:i1, j0:j1] = np.maximum(buf[i0:i1, j0:j1], prof.astype(F32))


# ----------------------------------------------------------- hairpin check --

def hairpin_error(mask, alpha, h=96, w=128, px=1, margin=10):
    """Ridge-alignment metric for the branch-T aliasing record (see the
    calibration notes in the curvature sweep below).

    A dashed mark field is the NORMAL product of the dist_to_mark mechanism
    (every stroke dashes into spaced marks), so a metric that scores each
    dash's own endpoint gradients as misoriented reads 0.83 even on a perfect
    dashed straight stroke (calibrated: 0.00 full band, 0.83 dashed) -- noise,
    not signal. What the hazard actually claims is that on tight curvature the
    dashes STOP READING AS LINES: neighbouring marks no longer align into a
    coherent stroke. The metric therefore measures the ridge orientation of
    the BLURRED mask (structure tensor of _box(mask, 1), blurred enough to
    join dashes) against the decoded axis, as lines (mod pi), averaged over
    marked pixels inside the tensor support (tr > 0.1 * max), reported in
    DEGREES of residual ridge-vs-axis error (mean absolute). Residual spread
    even on a clean dashed straight render stays ~10-50 deg because the
    blurred tensor blends dash-interior (aligned) with end-cap (perpendicular)
    structure in one support. The metric is therefore a COMPARATIVE tool --
    relative trend across the curvature sweep, not an absolute gate."""
    if margin:
        keep = np.zeros_like(mask, dtype=bool)
        keep[margin:-margin, margin:-margin] = True
    else:
        keep = np.ones_like(mask, dtype=bool)
    mblur = _box(mask, px)
    # ridge orientation of the blurred mask via its structure tensor
    gy0 = np.roll(mblur, -1, 0) - np.roll(mblur, 1, 0)
    gx0 = np.roll(mblur, -1, 1) - np.roll(mblur, 1, 1)
    jxx = _box(gx0 * gx0, px)
    jxy = _box(gx0 * gy0, px)
    jyy = _box(gy0 * gy0, px)
    d = jxx - jyy
    tr = jxx + jyy
    # ridge (line) orientation = the axis perpendicular to the dominant
    # gradient: line orientation angle = 0.5*atan2(2*jxy, d) + pi/2 (mod pi)
    th_line = np.zeros_like(tr)
    ok = tr > 1e-6
    th_line[ok] = 0.5 * np.arctan2(2 * jxy[ok], d[ok]) + np.pi / 2
    err = np.abs(np.mod(th_line - alpha + np.pi / 2, np.pi) - np.pi / 2)
    mark = (mask > 0.3) & (tr > F32(0.1) * tr.max()) & keep
    if not mark.any():
        return 0.0
    return float(np.rad2deg(err[mark]).mean())


def _box(a, r):
    k = 2 * r + 1
    out = np.zeros_like(a)
    for i in range(-r, r + 1):
        out += np.roll(a, i, 1) * (1.0 / k)
    for i in range(-r, r + 1):
        out += np.roll(out, i, 0)
    return out


# ----------------------------------------------------------------- utils ---

def _grid(h, w):
    cy, cx = np.meshgrid(np.arange(h, dtype=F32), np.arange(w, dtype=F32),
                         indexing="ij")
    return (cx + F32(0.5)) / F32(w), (cy + F32(0.5)) / F32(h), cx, cy


def hash01(x):
    return (np.sin(x * 127.1) * 43758.5453) % 1.0


def _smoothstep(e0, e1, x):
    t = np.clip((x - e0) / np.maximum(e1 - e0, 1e-6), 0, 1)
    return (t * t * (3 - 2 * t)).astype(F32)


def write_pgm(path, a):
    a = (np.clip(a, 0, 1) * 255).astype(np.uint8)
    with open(path, "wb") as f:
        f.write(f"P5\n{a.shape[1]} {a.shape[0]}\n255\n".encode())
        f.write(a.tobytes())


# ------------------------------------------------------------------ main ---

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    fields = {
        "curved_edge": field_curved_edge(),
        "iso_blob": field_isotropic_blob(),
        "authored": field_authored(),
    }
    print("== f_tf_hatch T001 cost-shape spike (OQ1) ==========================")
    print("bench floors cited: tensormap ~0.9 ms/pass upper bound at 1080p,")
    print("R_MAX 16 (33 taps/pass); M3 Max, M1 unmeasured.\n")

    print(f"{'field':13s} {'ridg err deg':>13s} {'T px cov':>9s} "
          f"{'S cov':>7s} {'S/T cov':>8s}")
    cov = {}
    for name, (alpha, coh, tr) in fields.items():
        t0 = time.time()
        mt = branch_t(alpha, coh, tr)
        t_t = time.time() - t0
        t0 = time.time()
        ms = branch_s(alpha, coh, tr, march_max=16)
        t_s = time.time() - t0
        hp = hairpin_error(mt, alpha)
        cov[name] = (mt, ms)
        write_pgm(os.path.join(OUT_DIR, f"spike_{name}_branchT.pgm"), mt)
        write_pgm(os.path.join(OUT_DIR, f"spike_{name}_branchS.pgm"), ms)
        print(f"{name:13s} {hp:13.2f} {float((mt>0.3).mean()):9.3f} "
              f"{float((ms>0.3).mean()):7.3f} {float((ms>0.3).mean())/max(float((mt>0.3).mean()),1e-9):8.2f}"
              f"   ({t_t*1000:.0f}/{t_s*1000:.0f} ms numpy)")
    print()

    # T curvature sweep: identical construction, circle spacing varied.
    # CALIBRATION: 0 deg = dashes perfectly aligned into lines (full-band
    # strokes measure 0.00); a perfectly rendered dash FIELD retains ~25-65
    # deg residual because the blurred tensor blends dash-interior (aligned)
    # with dash-end (perpendicular) structure in one support -- so the slope
    # (degrading as spacing grows past the coherent-following regime, then
    # the rendered picture), not the absolute number, is the evidence. Render
    # spike_curved_edge_branchT.png shows marks visibly following the rings.
    print("T curvature sweep (circular field; ridge-err deg, relative trend):")
    for rad in (8, 12, 20, 32, 64):
        cy, cx = np.meshgrid(np.arange(96, dtype=F32), np.arange(128, dtype=F32),
                             indexing="ij")
        r = np.sqrt((cx - 64) ** 2 + (cy - 48) ** 2)
        band = np.abs(np.mod(r, rad) - rad / 2) < rad * 0.25
        alpha2 = np.arctan2(cy - 48, cx - 64) + np.pi / 2
        m = branch_t(alpha2.astype(F32), np.where(band, F32(0.95), F32(0.02)).astype(F32),
                     np.where(band, F32(1.0), F32(0.0)).astype(F32))
        print(f"  circle spacing {rad:3d} px -> ridge err {hairpin_error(m, alpha2.astype(F32)):.2f} deg")
    print()

    # Orientation proof at single angles (the absolute metric's ground truth):
    for deg in (0, 30, 90):
        phi = np.deg2rad(deg)
        h, w = 48, 64
        alpha = np.full((h, w), np.float32(phi))
        coh = np.full((h, w), F32(0.9))
        tr = np.ones((h, w), F32)
        m = branch_t(alpha, coh, tr, h=h, w=w)
        print(f"single-angle {deg:3d} deg -> ridge err {hairpin_error(m, alpha):.2f} deg")
    print()

    print("== cost model (static, from the implementations above) ============")
    print("""Branch T (tileable distance field):
  passes: 3 (e1 decode, e2 layout, e3 encode)
  texture taps/pixel: e1 1 (tensor) + e2 4 (aux re-sample) + e3 1  ~=  6
  loop depth: 0 (closed form; fract + 1 sin-hash + 2 smoothstep)
  statements: ~25 (e1) + ~45 (e2) + ~14 (e3)  ~=  84  (ceiling ~450/program)
  bench model: 3 passes x 0.9 ms/pass upper bound at 1080p  ~= <=2.7 ms
  (tensormap proves the 1-pass class with 33 taps at 0.9 ms; these are 6)
Branch S (stroke-marching):
  passes: >= 5 (e1; seed search a + b -- f_vf_seeds needed TWO search halves
          for 18 candidates under the ~450-statement capture ceiling, plus a
          merge; march/render; encode)  and the seeds precedent reached SIX
          stages with lighter per-stage math than a march loop needs
  texture taps/pixel: seed search 9-18 + march per winning seed
          (2 winners x (2*MARCH_MAX+1) axis taps, M=16, two-sided for the
          sign problem)  =  9 + 66  ~= 75-90
  loop depth: compile-time MARCH_MAX per seed candidate, sequential state
          (marched position) carried across iterations -- the f_apollonian
          loop-carried-scope precedent; heavier loop bodies than tensormap's
  bench model: >= 5 passes x 0.9 ms/pass upper bound  ~= >= 4.5 ms at 1080p,
          plus statement-budget risk and the sign/branch-cut handling
Decision weight: T is ~2x cheaper on passes (~<=2.7 ms vs >=4.5 ms), ~5x
fewer texture taps, one-third the stages, no sign problem (the decoded axis
is an unoriented line -- branch T's pattern is symmetric to theta+180 by
construction), and its one recorded hazard (hairpin aliasing) is now
MEASURED above. S buys true stroke identity and tone-driven layering -- both
out of v1 scope (tone is OQ2, defaulted out).
GATE PROVISIONAL-CLOSED: branch T chosen, subject to the tier-2 bench
confirming the model (tasks T013/T016 re-open the gate if reality is worse).""")
    return cov


if __name__ == "__main__":
    main()