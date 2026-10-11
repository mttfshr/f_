"""
spike_droste_conformality.py -- is f_droste's UV transform conformal like
f_mobius's, or does it produce real elliptical (anisotropic) distortion?
(ideas/vector_field_math_concepts.md #10, extended beyond f_mobius; see
.specify/f_mobius_vecfield/spec.md open question #2.)

Hand-derivation (2026-10-10, before writing this script): f_droste's
log-polar step is itself conformal (complex log), and the twist shear is a
constant-coefficient linear map of (s, t) = (1 + i*twist) * (s_in, t_in) --
also conformal (complex multiplication). But the FINAL sample coordinates
are (u, v) = (n_arms * t_sp, s_sp), i.e. only the u-axis gets scaled by
n_arms, not both axes together -- unless n_arms == 1, that breaks the
"[[a,-b],[b,a]]" structure a conformal 2x2 Jacobian must have. Worked out
on paper: the only conformal case is twist == 0 AND n_arms == 1 exactly
(even then only anti-holomorphically -- a reflection, still angle-magnitude
preserving). This script checks that numerically rather than trusting the
algebra, via a finite-difference Jacobian straight from the codebox's own
function (src/f_droste/definition.py) -- no symbolic derivative to get
wrong.

Diagnostic only -- no production code touched, not a regression gate.

Run:
  uv run --no-project --with numpy --with matplotlib python3 tests/spike_droste_conformality.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import gpu_sim as g  # noqa: E402

F32 = np.float64  # finite differences want headroom; this is diagnostic math, not GPU-matching
TWO_PI = 2.0 * np.pi


def droste_T(nx, ny, zoom, n_arms, twist, rotation, time_s):
    """Pre-fract sample coordinates (u, v), straight port of the codebox
    (src/f_droste/definition.py). fract() is omitted deliberately -- for a
    LOCAL Jacobian, the wrap is irrelevant away from its own seam, same
    reasoning as the Mobius script's center-relative treatment."""
    dx = nx - 0.5
    dy = ny - 0.5
    r = np.sqrt(dx * dx + dy * dy)
    theta = np.arctan2(dy, dx)
    log_zoom = np.log(max(zoom, 1.001))
    s = np.log(np.maximum(r, 1e-5)) / log_zoom
    t = (theta / TWO_PI) + rotation
    s = s + time_s
    s_sp = s - t * twist
    t_sp = t + s * twist
    u = t_sp * n_arms
    v = s_sp
    return u, v


def local_jacobian(cx, cy, zoom, n_arms, twist, rotation=0.0, time_s=0.0, h=1e-4):
    """2x2 Jacobian of droste_T at (cx, cy) via central finite differences."""
    def T(x, y):
        return droste_T(x, y, zoom, n_arms, twist, rotation, time_s)

    u_xp, v_xp = T(cx + h, cy)
    u_xm, v_xm = T(cx - h, cy)
    u_yp, v_yp = T(cx, cy + h)
    u_ym, v_ym = T(cx, cy - h)
    du_dx, dv_dx = (u_xp - u_xm) / (2 * h), (v_xp - v_xm) / (2 * h)
    du_dy, dv_dy = (u_yp - u_ym) / (2 * h), (v_yp - v_ym) / (2 * h)
    return np.array([[du_dx, du_dy], [dv_dx, dv_dy]])


def eccentricity(J):
    """Ratio of singular values of J -- 1.0 means the local map sends a
    circle to a circle (conformal); > 1.0 means a real ellipse."""
    svals = np.linalg.svd(J, compute_uv=False)
    return svals[0] / svals[1]


def main():
    # avoid exact alignment with atan2's branch cut (theta = +-pi, i.e. dy=0,
    # dx<0 -- (0.3, 0.5) sits exactly there and gives a bogus finite
    # difference when perturbed across it; confirmed by hand, not guessed)
    test_points = [(0.32, 0.47), (0.5, 0.3), (0.7, 0.7), (0.35, 0.65)]
    zoom = 2.0
    zoom_isolating = float(np.exp(TWO_PI))  # log(zoom) == 2*pi exactly: isolates the s/t scale-mismatch effect
    configs = [
        ("zoom=2.0, twist=0, n_arms=1", zoom, 0.0, 1.0),
        (f"zoom={zoom_isolating:.1f} (log(zoom)=2pi), twist=0, n_arms=1", zoom_isolating, 0.0, 1.0),
        ("zoom=2.0, twist=0, n_arms=3", zoom, 0.0, 3.0),
        ("zoom=2.0, twist=0.4, n_arms=1", zoom, 0.4, 1.0),
        ("zoom=2.0, twist=0.4, n_arms=3 (shipped-range example)", zoom, 0.4, 3.0),
    ]

    print(f"{'config':<55} {'point':<14} {'eccentricity':>12}")
    results = {}
    for label, z, twist, n_arms in configs:
        eccs = []
        for (cx, cy) in test_points:
            J = local_jacobian(cx, cy, z, n_arms, twist)
            e = eccentricity(J)
            eccs.append(e)
            print(f"{label:<55} ({cx},{cy}){'':<4} {e:>12.4f}")
        results[label] = eccs
        print(f"{'':<55} {'max - 1.0':<14} {max(eccs) - 1.0:>12.4f}")
        print()

    baseline = results["zoom=2.0, twist=0, n_arms=1"]
    isolated = results[f"zoom={zoom_isolating:.1f} (log(zoom)=2pi), twist=0, n_arms=1"]
    print(f"zoom=2.0 baseline (twist=0, n_arms=1) eccentricity: {baseline[1]:.4f} "
          f"(predicted 2*pi/log(2) = {TWO_PI / np.log(2):.4f} from the s/t scale "
          f"mismatch alone -- CONTRADICTS the hand-derivation's 'this case is "
          f"conformal' claim)")
    isolated_verdict = ("confirms the scale-mismatch theory -- isolating it really does restore conformality"
                        if abs(isolated[1] - 1.0) < 1e-4 else "theory not confirmed, investigate further")
    print(f"zoom tuned so log(zoom)==2*pi, same twist/n_arms: eccentricity "
          f"{isolated[1]:.6f} ({isolated_verdict})")
    for label, z, twist, n_arms in configs[2:]:
        print(f"{label}: max eccentricity {max(results[label]):.3f}")

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, axes = plt.subplots(1, len(configs), figsize=(4 * len(configs), 4.4))
        theta = np.linspace(0, 2 * np.pi, 64)
        ring_r = 0.03
        for ax, (label, z, twist, n_arms) in zip(axes, configs):
            ax.set_title(label, fontsize=7)
            centers = np.linspace(0.2, 0.8, 4)
            for gy in centers:
                for gx in centers:
                    J = local_jacobian(gx, gy, z, n_arms, twist)
                    circle = np.stack([ring_r * np.cos(theta), ring_r * np.sin(theta)])
                    ellipse = J @ circle
                    # normalize displayed size (direction/shape is the point, not
                    # absolute scale, which varies hugely near the log singularity)
                    norm = np.max(np.abs(ellipse)) or 1.0
                    ellipse = ellipse / norm * ring_r
                    ax.plot(gx + ellipse[0], gy + ellipse[1], color="crimson", linewidth=1.0)
                    ax.plot(gx + ring_r * np.cos(theta), gy + ring_r * np.sin(theta),
                            color="0.8", linewidth=0.5)
            ax.set_xlim(0, 1)
            ax.set_ylim(0, 1)
            ax.set_aspect("equal")
            ax.invert_yaxis()
        fig.tight_layout()
        out_dir = HERE.parent / "scratch"
        out_dir.mkdir(exist_ok=True)
        fp = out_dir / "droste_conformality_spike.png"
        fig.savefig(fp, dpi=110)
        print(f"figure: {fp}")
    except ImportError:
        print("matplotlib not available -- numeric summary above still stands")


if __name__ == "__main__":
    main()
