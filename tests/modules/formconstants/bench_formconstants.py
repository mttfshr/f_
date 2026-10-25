"""
bench_formconstants.py -- f_formconstants PARITY build, tasks T046: every stage codebox
under src/f_formconstants/ run on the GPU through the codebox bench and diffed against the
parity mirror (fc_parity_mirror.py), then the chain host-sequenced for 5 frames (texel-exact
class) and, @slow, 150 frames (statistics). THIS IS THE FIRST MAX COMPILE of the parity
codeboxes: a compile error or a readback mismatch here is the finding; do not tune around it
(tasks.md agent brief, rules 2, 3, 5).

(The steady-web bench this replaces is in git history: commit c367543 and earlier.)

Tolerance, stated in advance (tasks.md T046): quantized outputs pass if max |diff| <= 1/255
AND at most 0.1% of values differ at all (GPU vs NumPy float32 rounding can flip a value that
sits within an ulp of a (k + 0.5)/255 boundary; single flips are not chased). Continuous
outputs (the enc render) pass at 2e-3. The chain legs use the SAME tolerance every frame; if
they fail, the numbers are reported, not loosened.

Stage jobs (one pass per job; the bench drives one codebox per job, up to 3 inputs):
    seed   in1 = bang stand-in; out = four uint8-like hash channels (Params salt, n)
    pass   in1 = bang, in2 = feedback state, in3 = seed; A == 0 or reseed -> seed (Param reseed)
    blurx / blury   in1 = state; 13-tap per-channel kernel, wrap, quantized (Param n)
    nl     in1 = convolved, in2 = raw state; Params frameno, s_depth, s_rate
    enc    in1 = bang, in2 = state; the retinal map at (ow, oh) (Params ow, oh, n, bypass_gate)

The grid size is pinned with Param n = 128 for the stage legs (the codebox default is the real
1024; test_fc_codebox_static.py asserts it equals the definition's @dim).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/formconstants/bench_formconstants.py
      (add --slow for the 150-frame statistics leg)
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 56.5           # right after bench_wc (56)

import paths as _paths
import sys

import numpy as np

import benchclient as bc
import fc_parity_mirror as m
from harness import check, note, run, slow

SRC = _paths.REPO / "src" / "f_formconstants"
N = 128
Q = 1.0 / 255.0
F32 = np.float32
FILES = {"seed": "codebox_seed.gen", "pass": "codebox_pass.gen",
         "blurx": "codebox_blur_x.gen", "blury": "codebox_blur_y.gen",
         "nl": "codebox_nl.gen", "enc": "codebox_enc.gen"}
BANG = np.zeros((4, 4, 4), np.float32)          # stand-in for the `r draw` bang inlet
# The bench keeps a Param's last value between jobs: every job pins every Param its codebox declares.
PINNED = {"seed": {"salt": 0.0, "n": float(N)},
          "pass": {"reseed": 0.0},
          "blurx": {"n": float(N)},
          "blury": {"n": float(N)},
          "nl": {"frameno": 0.0, "s_depth": 0.6, "s_rate": 0.0068},
          "enc": {"bypass_gate": 0.0, "ow": float(N), "oh": float(N), "n": float(N)}}


def code(stage):
    return (SRC / FILES[stage]).read_text()


def gpu(stage, inputs, dim=None, **deltas):
    params = dict(PINNED.get(stage, {}))
    params.update(deltas)
    out, r = bc.run_pass(code(stage), inputs, dim=dim, params=params, timeout_ms=30000)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"{stage}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def qstate(rng, live=True):
    """A random uint8-like state (k/255); A = 1 when `live` (what nl would have written)."""
    s = (rng.integers(0, 256, size=(N, N, 4)).astype(F32) / F32(255.0))
    if live:
        s[..., 3] = 1.0
    return s


def check_q(label, g, mm):
    d = np.abs(g.astype(np.float64) - mm.astype(np.float64))
    mx, frac = float(d.max()), float((d > 1e-6).mean())
    note(label + " max diff / values differing", f"{mx:.3e} ({mx / Q:.2f} levels) / {frac:.4%}")
    note(label + " per-channel max (levels) R G B A",
         " ".join(f"{float(d[..., c].max()) / Q:.2f}" for c in range(4)))
    check(label + ": max diff <= 1/255", mx, Q + 1e-6)
    check(label + ": values differing <= 0.1%", frac, 1e-3)


# ---------------------------------------------------------------------- seed / pass

def test_seed_stage():
    s0 = gpu("seed", [BANG], dim=(N, N), salt=0.0)
    on_grid = float(np.abs(s0 * 255.0 - np.round(s0 * 255.0)).max())
    check("seed: every channel on the 1/255 grid", on_grid, 2e-3)
    check("seed: values in [0, 1]", max(0.0 - float(s0.min()), float(s0.max()) - 1.0), 0.0)
    note("seed means (want ~0.5)", " ".join(f"{float(s0[..., c].mean()):.3f}" for c in range(4)))
    check("seed: mean ~ 0.5 on every channel",
          max(abs(float(s0[..., c].mean()) - 0.5) for c in range(4)), 0.03)
    check("seed: std ~ 0.289 on every channel",
          max(abs(float(s0[..., c].std()) - 0.2887) for c in range(4)), 0.03)
    check("seed: reproducible per salt",
          float(np.abs(s0 - gpu("seed", [BANG], dim=(N, N), salt=0.0)).max()), 0.0)
    s1 = gpu("seed", [BANG], dim=(N, N), salt=1.0)
    check("seed: salt 1 differs from salt 0", 0.2 - float(np.abs(s0 - s1).mean()), 0.2)
    corr = max(abs(float(np.corrcoef(s0[..., a].ravel(), s0[..., b].ravel())[0, 1]))
               for a, b in ((0, 1), (0, 2), (1, 3)))
    check("seed: channels weakly correlated (cheap hash, f_wc precedent)", corr, 0.30)


def test_pass_stage_flag_and_reseed():
    rng = np.random.default_rng(9)
    seed = gpu("seed", [BANG], dim=(N, N), salt=0.0)
    fb = qstate(rng)
    kept = gpu("pass", [BANG, fb, seed], dim=(N, N), reseed=0.0)
    check("pass: reseed=0 keeps a live (A=1) state bit-exact", float(np.abs(kept - fb).max()), 0.0)
    re = gpu("pass", [BANG, fb, seed], dim=(N, N), reseed=1.0)
    check("pass: reseed=1 writes the seed into all four channels", float(np.abs(re - seed).max()), 0.0)
    zero = fb.copy()
    zero[..., 0] = 0.0
    zero[..., 1] = 0.0                                   # E = I = 0 with A = 1: a LEGITIMATE state
    held = gpu("pass", [BANG, zero, seed], dim=(N, N), reseed=0.0)
    check("pass: E = I = 0 with A = 1 is HELD, not reseeded", float(np.abs(held - zero).max()), 0.0)
    lost = fb.copy()
    lost[: N // 2, :, 3] = 0.0                           # the top half is lost (A = 0)
    got = gpu("pass", [BANG, lost, seed], dim=(N, N), reseed=0.0)
    check("pass: A = 0 texels take the seed",
          float(np.abs(got[: N // 2] - seed[: N // 2]).max()), 0.0)
    check("pass: the live half is held",
          float(np.abs(got[N // 2:] - lost[N // 2:]).max()), 0.0)


# ---------------------------------------------------------------------- blur

def test_blur_stages_vs_mirror():
    st = qstate(np.random.default_rng(9), live=False)
    gx = gpu("blurx", [st], dim=(N, N))
    check_q("blur_x", gx, m.blur_pass(st, 1))
    gy = gpu("blury", [gx], dim=(N, N))
    check_q("blur_y (on the GPU's own blur_x output)", gy, m.blur_pass(gx, 0))
    check_q("blur_x + blur_y chained vs the mirror's blur()", gy, m.blur(st))
    imp = np.zeros((N, N, 4), np.float32)
    imp[0, 0, :] = 1.0                                   # an impulse in the corner: the wrap ring
    check_q("blur_x: impulse at (0,0) wraps (periodic)", gpu("blurx", [imp], dim=(N, N)),
            m.blur_pass(imp, 1))
    check_q("blur_y: impulse at (0,0) wraps (periodic)", gpu("blury", [imp], dim=(N, N)),
            m.blur_pass(imp, 0))


# ---------------------------------------------------------------------- nl

def test_nl_vs_mirror():
    st = qstate(np.random.default_rng(11))
    conv = m.blur(st)
    for t in (0, 100, 2400):                             # s on, off, on
        g = gpu("nl", [conv, st], dim=(N, N), frameno=float(t))
        mm = m.wc_step(st, conv, t)
        note(f"s at t={t}", f"{float(m.s_of_t(t)):.1f}")
        check_q(f"nl at t={t}", g, mm)
        check(f"nl at t={t}: alpha is exactly 1", float(np.abs(g[..., 3] - 1.0).max()), 0.0)
    g0 = gpu("nl", [conv, st], dim=(N, N), frameno=0.0, s_depth=0.0)
    check_q("nl with s_depth = 0", g0, _wc_no_s(st, conv))


def _wc_no_s(st, conv):
    old = m.S_DEPTH
    m.S_DEPTH = 0.0
    try:
        return m.wc_step(st, conv, 0)
    finally:
        m.S_DEPTH = old


# ---------------------------------------------------------------------- enc

def test_enc_render_vs_mirror():
    st = qstate(np.random.default_rng(13))
    for ow, oh in ((N, N), (160, 90), (90, 160)):
        g = gpu("enc", [BANG, st], dim=(ow, oh), ow=float(ow), oh=float(oh))
        assert g.shape[:2] == (oh, ow), g.shape
        mm = m.encode(st, ow, oh)
        d = np.abs(g[..., :3] - mm[..., :3])
        note(f"enc {ow}x{oh} max / mean diff", f"{float(d.max()):.2e} / {float(d.mean()):.2e}")
        note(f"enc {ow}x{oh} corr (E)", f"{float(np.corrcoef(g[..., 0].ravel(), mm[..., 0].ravel())[0, 1]):.5f}")
        check(f"enc {ow}x{oh}: retinal map vs the mirror (E, I, contour)", float(d.max()), 2e-3)
        check(f"enc {ow}x{oh}: alpha is 1", float(np.abs(g[..., 3] - 1.0).max()), 0.0)
    bn = gpu("enc", [BANG, st], dim=(N, N), bypass_gate=1.0)
    check("enc: bypass_gate = 1 outputs black with alpha 1",
          max(float(np.abs(bn[..., :3]).max()), float(np.abs(bn[..., 3] - 1).max())), 0.0)


# ---------------------------------------------------------------------- chain

def _gpu_frame(state, t):
    conv = gpu("blury", [gpu("blurx", [state], dim=(N, N))], dim=(N, N))
    return gpu("nl", [conv, state], dim=(N, N), frameno=float(t))


def _gpu_seed_state():
    seed = gpu("seed", [BANG], dim=(N, N), salt=0.0)
    return gpu("pass", [BANG, np.zeros((N, N, 4), np.float32), seed], dim=(N, N), reseed=1.0)


def test_chain_5_frames_texel_exact_class():
    gs = _gpu_seed_state()
    ms = gs.copy()                                       # the mirror starts from the GPU's own seed
    for fr in range(5):
        gs = _gpu_frame(gs, fr)
        ms = m.step(ms, fr)
        check_q(f"chain frame {fr + 1}", gs, ms)


def test_each_frame_is_stage_exact_given_identical_input():
    """Attribution leg for test_chain_5_frames: the GPU frame is stepped from the MIRROR's own
    state every frame, so any difference is the frame's own, not inherited. If the chain leg
    diverges but this one does not, the divergence is upstream rounding flips cascading through
    the frame (B = 3|E - I| triples a 1-level flip in E or I), not a stage error."""
    ms = _gpu_seed_state()
    for fr in range(5):
        g = _gpu_frame(ms, fr)
        ms = m.step(ms, fr)
        check_q(f"frame {fr + 1} stepped from the mirror's own state", g, ms)


@slow
def test_chain_150_frames_statistics():
    """After a few frames rounding flips cascade, so only statistics are compared: the mean and
    std of E over the last half-period (frames 75-149, the s-off stretch), GPU vs mirror, 10%."""
    gs = _gpu_seed_state()
    ms = gs.copy()
    g_std, m_std, g_mean, m_mean = [], [], [], []
    for fr in range(150):
        gs = _gpu_frame(gs, fr)
        ms = m.step(ms, fr)
        if fr >= 75:
            g_std.append(float(gs[..., 0].std())); m_std.append(float(ms[..., 0].std()))
            g_mean.append(float(gs[..., 0].mean())); m_mean.append(float(ms[..., 0].mean()))
    gsd, msd, gmn, mmn = np.mean(g_std), np.mean(m_std), np.mean(g_mean), np.mean(m_mean)
    note("E std (GPU / mirror)", f"{gsd:.4f} / {msd:.4f}")
    note("E mean (GPU / mirror)", f"{gmn:.4f} / {mmn:.4f}")
    check("E std agrees within 10%", abs(gsd - msd) / max(msd, 1e-9), 0.10)
    check("E mean agrees within 10%", abs(gmn - mmn) / max(mmn, 1e-9), 0.10)


if __name__ == "__main__":
    sys.exit(run(globals()))
