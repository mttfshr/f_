"""test_fc_parity.py -- tier-1 tests for fc_parity_mirror.py (f_formconstants
Revision 2, tasks T042): the faithful port of WC_Example_10_fullscreen.html.

Ground truth is the SOURCE, transcribed independently of the mirror where it
can be: createGaussianConvolution is re-typed here as the JS loop; the page's
s expression is s_source(); encode() is checked against a per-pixel scalar
float64 transcription of the map shader.

  a  blur kernel = createGaussianConvolution(sigma, true, 6) for sigma 1 and 2
  b  quantization: q idempotent; every blur / wc output is a multiple of 1/255
     exactly where S2 puts it; B comes from the UNquantized E, I
  c  s: values, period, and agreement with the page's sign(sin) form for t > 0
  d  sustain (MEASURED, not assumed -- see tests/records/spike_fc_parity_sustain.py):
     the s wave sustains the pattern; without it the field dies; 8-bit
     quantization is NOT required at the source's kernel widths
  e  pass stage: A is the lost flag (E = I = 0 with A = 1 is held), reseed, NaN guard
  f  encode vs the scalar transcription, non-square (crop) and square outputs

Run:  tests/run.sh -q tests/modules/formconstants/test_fc_parity.py
"""
import math

import numpy as np

from harness import check, note, run  # noqa: E402
import fc_parity_mirror as m  # noqa: E402

F32 = np.float32


# ----------------------------------------------------------------- (a) kernel
def _js_kernel(sigma, radius):
    """lib/gpugaussian.js createGaussianConvolution(sigma, true, radius), typed
    as the JS runs it (double accumulation, Float32Array storage)."""
    kernel = [0.0] * (2 * radius + 1)
    total = 0.0
    for i in range(2 * radius + 1):
        v = math.exp(-0.5 * ((i - radius) / sigma) ** 2)
        kernel[i] = float(np.float32(v))
        total += v
    return [float(np.float32(k / total)) for k in kernel]


def test_blur_kernel_matches_source():
    hk = m.half_kernel()
    worst = 0.0
    for c, s in enumerate(m.SIGMAS):
        js = _js_kernel(s, m.RADIUS)
        for i in range(m.RADIUS + 1):
            worst = max(worst, abs(float(hk[i, c]) - js[i + m.RADIUS]))
    check("half-kernel vs createGaussianConvolution transcription", worst, 1e-7)
    check("sigma=1 full kernel sums to 1",
          abs(float(m.createGaussianConvolution(1.0).sum()) - 1.0), 1e-6)
    check("sigma=2 full kernel sums to 1",
          abs(float(m.createGaussianConvolution(2.0).sum()) - 1.0), 1e-6)
    # ONE shared radius: the sigma = 1 kernel is still 13 taps and its +-6 tap is nonzero
    assert float(hk[m.RADIUS, 0]) > 0.0, "sigma=1 tap at +-6 must be nonzero (shared radius)"
    note("sigma=1 tap at +-6", f"{float(hk[m.RADIUS, 0]):.3e}")


def test_blur_of_constant_and_mode():
    const = np.full((32, 32, 4), 0.4, dtype=F32)
    got = m.blur(const, levels=None)
    check("blur of a constant (float)", float(np.abs(got - 0.4).max()), 1e-6)
    n = 64
    ys = np.arange(n, dtype=np.float64)
    ky = 2 * np.pi * 3 / n
    mode = np.zeros((n, n, 4), dtype=F32)
    mode[..., :] = (0.5 + 0.25 * np.cos(ky * ys))[:, None, None].astype(F32)
    out = m.blur_pass(mode, 0, levels=None)
    amp = float((out[:, 0, 1] - 0.5).max())          # G channel: sigma = 2
    want = 0.25 * math.exp(-0.5 * (2.0 * ky) ** 2)
    note("sigma=2 mode gain (got / analytic)", f"{amp:.5f} / {want:.5f}")
    check("sigma=2 mode amplitude vs analytic Gaussian", abs(amp - want), 2e-3)


# ------------------------------------------------------------ (b) quantization
def test_quantization_points():
    x = np.random.default_rng(0).random((64, 64, 4)).astype(F32)
    check("q idempotent", float(np.abs(m.q(m.q(x)) - m.q(x)).max()), 0.0)

    def on_grid(a):
        return float(np.abs(a * 255.0 - np.round(a * 255.0)).max())

    st = m.seed_state(48, np.random.default_rng(1))
    bx = m.blur_pass(st, 1)
    by = m.blur_pass(bx, 0)
    check("blur-x output on the 1/255 grid", on_grid(bx), 1e-3)
    check("blur-y output on the 1/255 grid", on_grid(by), 1e-3)
    unq = m.blur_pass(st, 1, levels=None)
    assert float(np.abs(unq * 255.0 - np.round(unq * 255.0)).max()) > 0.05, \
        "levels=None must leave the blur unquantized (control)"

    out = m.wc_step(st, by, 3)
    for ch, name in ((0, "E"), (1, "I"), (2, "B")):
        check(f"wc output {name} on the 1/255 grid", on_grid(out[..., ch]), 1e-3)
    check("wc output A == 1", float(np.abs(out[..., 3] - 1.0).max()), 0.0)

    # B is built from the UNquantized updated E, I (the page's `abs(Ue-Ui)*3.0`)
    e, i = st[..., 0], st[..., 1]
    ce, ci = by[..., 0], by[..., 1]
    s = m.s_of_t(3)
    en = e + (m.F(F32(m.AEE) * ce - F32(m.AIE) * ci - F32(m.HE) + s) - e) * F32(m.DT / m.TE)
    inn = i + (m.F(F32(m.AEI) * ce - F32(m.AII) * ci - F32(m.HI)) - i) * F32(m.DT / m.TI)
    b_unq = m.q8_store(np.abs(en - inn) * F32(3.0))
    b_qd = m.q8_store(np.abs(m.q(en) - m.q(inn)) * F32(3.0))
    check("B equals q8(3|Ue-Ui|) from unquantized values",
          float(np.abs(out[..., 2] - b_unq).max()), 0.0)
    assert float(np.abs(b_unq - b_qd).max()) > 0.0, \
        "test is vacuous: quantized-input B would be identical"


# ------------------------------------------------------------------------ (c) s
def test_s_wave():
    vals = {float(m.s_of_t(t)) for t in range(0, 2000)}
    assert vals == {0.0, float(F32(0.6))}, vals
    diff = [t for t in range(1, 3000)
            if abs(float(m.s_of_t(t)) - float(m.s_source(t))) > 1e-6]
    # the only allowed differences: exact half-period frames (t = 1250 k), where
    # the page's truncated pi decides the sign (see s_source's docstring)
    bad = [t for t in diff if t % 1250 != 0]
    assert not bad, f"s_of_t != the page's sign(sin) form at t = {bad[:5]}"
    note("single-frame differences vs the page (t = 1250 k)", diff)
    note("t = 0", f"module {float(m.s_of_t(0)):.2f}, page {float(m.s_source(0)):.2f} (one-frame difference, documented)")
    edges = [t for t in range(1, 3000)
             if float(m.s_of_t(t)) > 0 and float(m.s_of_t(t - 1)) == 0]
    gaps = np.diff(edges)
    note("rising edges / mean period", f"{len(edges)} / {gaps.mean():.2f} frames")
    check("period vs 500/3.4", abs(float(gaps.mean()) - 500.0 / 3.4), 1.0)


# ------------------------------------------------------------------ (d) sustain
def _sustain(n, frames, levels, depth, seed, window=500):
    old = m.S_DEPTH
    m.S_DEPTH = depth
    try:
        st = m.seed_state(n, np.random.default_rng(seed))
        es = []
        for fr in range(frames):
            st = m.step(st, fr, levels)
            es.append(float(st[..., 0].std()))
    finally:
        m.S_DEPTH = old
    es = np.array(es[-window:])
    return float(es.min()), float(es.max())


def test_sustain_is_the_s_wave():
    """MEASURED 2026-10-24 (tests/records/spike_fc_parity_sustain.py, N 128/256,
    two seeds): last-window E std is 0.044-0.22 with s (quantized or float) and
    0.001-0.012 without it. Thresholds leave a wide margin on both sides."""
    n = 128
    qs = _sustain(n, 3000, 255.0, 0.6, 1)
    fs = _sustain(n, 3000, None, 0.6, 1)
    qn = _sustain(n, 1500, 255.0, 0.0, 1)
    fn = _sustain(n, 1500, None, 0.0, 1)
    note("quantized + s  std min/max", f"{qs[0]:.3f} / {qs[1]:.3f}")
    note("float + s      std min/max", f"{fs[0]:.3f} / {fs[1]:.3f}")
    note("quantized, no s std max", f"{qn[1]:.4f}")
    note("float, no s     std max", f"{fn[1]:.4f}")
    assert qs[0] > 0.03 and qs[1] > 0.1, f"quantized + s must sustain: {qs}"
    assert fs[0] > 0.03 and fs[1] > 0.1, \
        f"float + s must sustain at the source's kernel widths (the T002 record claimed it dies): {fs}"
    assert qn[1] < 0.02, f"quantized without s must die: {qn}"
    assert fn[1] < 0.02, f"float without s must die: {fn}"


# ------------------------------------------------------------------- (e) pass
def test_pass_stage_flag_and_reseed():
    rng = np.random.default_rng(2)
    seed = m.seed_state(8, rng)
    fb = np.zeros((8, 8, 4), dtype=F32)
    fb[..., 3] = 1.0                                  # a live field with E = I = 0 everywhere
    fb[2, 3, :3] = [0.0, 0.0, 0.5]
    held = m.pass_stage(fb, seed, reseed=0)
    check("E = I = 0 with A = 1 is HELD (not reseeded)", float(np.abs(held - fb).max()), 0.0)

    fresh = np.zeros((8, 8, 4), dtype=F32)             # a fresh / reallocated texture: A = 0
    got = m.pass_stage(fresh, seed, reseed=0)
    check("A = 0 texels take the seed", float(np.abs(got - seed).max()), 0.0)

    mixed = fb.copy()
    mixed[5, 5, 3] = 0.0
    got = m.pass_stage(mixed, seed, reseed=0)
    check("only the A = 0 texel reseeds",
          float(np.abs(got[5, 5] - seed[5, 5]).max()), 0.0)
    keep = np.ones((8, 8), dtype=bool)
    keep[5, 5] = False
    check("the rest is held", float(np.abs(got[keep] - mixed[keep]).max()), 0.0)

    got = m.pass_stage(fb, seed, reseed=1)
    check("reseed=1 takes the seed everywhere", float(np.abs(got - seed).max()), 0.0)

    bad = fb.copy()
    bad[1, 1, 0] = np.nan
    bad[1, 2, 1] = np.inf
    got = m.pass_stage(bad, seed, reseed=0)
    assert np.isfinite(got).all()
    check("NaN/Inf zapped to 0, texel held (A = 1 kept)",
          float(abs(got[1, 1, 0]) + abs(got[1, 2, 1]) + abs(got[1, 1, 3] - 1.0)), 0.0)


# ------------------------------------------------------------------ (f) encode
def _scalar_map(state, ox, oy, ow, oh):
    """One output pixel of the page's retinalmap shader, float64, scalar."""
    nh, nw = state.shape[0], state.shape[1]
    L = max(ow, oh)
    zx = ((ox + 0.5) / ow * 2 - 1) * (ow / L)
    zy = ((oy + 0.5) / oh * 2 - 1) * (oh / L)
    r = max(math.hypot(zx, zy), 1e-6)
    u = math.atan2(zy, zx) / (2 * math.pi)
    v = math.log(r) / (2 * math.pi)
    fx, fy = u * nw - 0.5, v * nh - 0.5
    x0, y0 = math.floor(fx), math.floor(fy)
    tx, ty = fx - x0, fy - y0
    out = np.zeros(4)
    for dy, wy in ((0, 1 - ty), (1, ty)):
        for dx, wx in ((0, 1 - tx), (1, tx)):
            out += wy * wx * state[(y0 + dy) % nh, (x0 + dx) % nw].astype(np.float64)
    out[3] = 1.0
    return out


def test_encode_matches_scalar_map():
    rng = np.random.default_rng(3)
    state = rng.random((64, 64, 4)).astype(F32)
    for ow, oh in ((96, 54), (64, 64), (54, 96)):
        img = m.encode(state, ow, oh)
        assert img.shape == (oh, ow, 4)
        worst = 0.0
        for _ in range(60):
            ox, oy = int(rng.integers(0, ow)), int(rng.integers(0, oh))
            worst = max(worst, float(np.abs(img[oy, ox] - _scalar_map(state, ox, oy, ow, oh)).max()))
        check(f"encode vs scalar map, {ow}x{oh}", worst, 2e-4)
        check(f"alpha is 1, {ow}x{oh}", float(np.abs(img[..., 3] - 1.0).max()), 0.0)
    assert np.isfinite(m.encode(state, 33, 33)).all()      # odd size: a pixel sits on the centre


def test_encode_crop_is_the_long_axis_square():
    """Square crop: the visible z range is +-1 on the long axis and
    +-(short/long) on the short one (the page's CSS stretch)."""
    state = np.zeros((16, 16, 4), dtype=F32)
    ow, oh = 160, 90
    L = max(ow, oh)
    top = ((oh - 1 + 0.5) / oh * 2 - 1) * (oh / L)
    right = ((ow - 1 + 0.5) / ow * 2 - 1) * (ow / L)
    check("long axis reaches ~1", abs(right - (1 - 1.0 / ow)), 1e-9)
    check("short axis reaches ~short/long", abs(top - (oh / L) * (1 - 1.0 / oh)), 1e-9)
    assert m.encode(state, ow, oh).shape == (oh, ow, 4)


# ------------------------------------------------- (g) Phase D T061: the pulse (s_pulse)
def test_pulse_unplugged_is_the_parity_wave():
    """Unplugged at the defaults, s_pulse(t) (t / period form) equals the parity s_of_t (t * rate
    form) except on exact half-period frames (t = 1250 k, the documented knife edge); a different
    period changes only the period."""
    ts = np.arange(0, 5000)
    diff = [t for t in ts if m.s_pulse(t) != m.s_of_t(t)]
    note("frames where s_pulse != s_of_t (t < 5000)", diff)
    check("mismatches only on exact half periods (t = 1250 k)",
          float(any(t % 1250 for t in diff)), 0.0)
    w = np.array([m.s_pulse(t, period=200.0) for t in range(4000)])
    rises = int(np.sum((w[1:] > 0) & (w[:-1] == 0)))
    check("period 200: 19 rising edges in 4000 frames (|count - 19|)", abs(rises - 19), 0.0)
    check("depth scales the wave (max at depth 1.3 = 1.3)",
          abs(max(m.s_pulse(t, depth=1.3) for t in range(300)) - 1.3), 1e-6)


def test_pulse_connected_replaces_the_wave():
    """Connected (conn 1) the pulse texture's luma times depth IS s at every t (REPLACE, Matt
    2026-10-24); conn 0 ignores a supplied texture; depth 0 is exactly zero (the fade gesture)."""
    rng = np.random.default_rng(3)
    tex = rng.random((16, 16, 4)).astype(F32)
    want = F32(0.6) * m.luma(tex)
    worst = max(float(np.abs(m.s_pulse(t, pulse=tex, conn=1.0) - want).max()) for t in (0, 50, 100, 147))
    check("conn 1: s = depth * luma(pulse) at every t (max |diff|)", worst, 1e-7)
    off = m.s_pulse(100, pulse=tex, conn=0.0)              # t = 100 is in the wave's low half
    check("conn 0: the internal wave, texture ignored (max |s|)", float(np.abs(off).max()), 0.0)
    check("depth 0: s == 0 everywhere", float(np.abs(m.s_pulse(10, depth=0.0, pulse=tex, conn=1.0)).max()), 0.0)
    check("luma weights sum to 1 (white -> 1)", abs(float(m.luma(np.ones((1, 1, 4), F32))[0, 0]) - 1.0), 1e-6)


def test_pulse_is_per_texel_and_E_only():
    """A per-texel s changes E only where s differs, and never I (s enters the E sigmoid only,
    S4); wc_step with an array s equals wc_step with that texel's scalar s."""
    rng = np.random.default_rng(4)
    st = (rng.integers(0, 256, (24, 24, 4)) / 255.0).astype(F32)
    conv = m.blur(st)
    s_arr = np.zeros((24, 24), F32)
    s_arr[:, 12:] = 0.6
    a = m.wc_step(st, conv, 0, s=s_arr)
    b0 = m.wc_step(st, conv, 0, s=F32(0.0))
    b6 = m.wc_step(st, conv, 0, s=F32(0.6))
    check("I identical whatever s is (max |dI|)", float(np.abs(a[..., 1] - b0[..., 1]).max()), 0.0)
    check("s = 0 half equals the scalar-0 step (max |diff|)", float(np.abs(a[:, :12] - b0[:, :12]).max()), 0.0)
    check("s = 0.6 half equals the scalar-0.6 step (max |diff|)", float(np.abs(a[:, 12:] - b6[:, 12:]).max()), 0.0)


# ------------------------------------------------- (h) Phase D T060: output modes (encode_mode)
def test_out_modes():
    """RGB is encode() unchanged; E / Contour / Luma are grays of encode()'s R / B / Rec. 709 luma."""
    rng = np.random.default_rng(5)
    st = rng.random((32, 32, 4)).astype(F32)
    rgb = m.encode(st, 40, 24)
    check("mode 0 (RGB) == encode()", float(np.abs(m.encode_mode(st, 40, 24, 0) - rgb).max()), 0.0)
    for mode, want in ((1, rgb[..., 0]), (2, rgb[..., 2]), (3, m.luma(rgb))):
        o = m.encode_mode(st, 40, 24, mode)
        gray = float(max(np.abs(o[..., 1] - o[..., 0]).max(), np.abs(o[..., 2] - o[..., 0]).max()))
        check(f"mode {mode} ({m.OUT_MODES[mode]}) value (max |diff|)", float(np.abs(o[..., 0] - want).max()), 1e-7)
        check(f"mode {mode} is gray (max channel spread)", gray, 0.0)
        check(f"mode {mode} alpha is 1", float(np.abs(o[..., 3] - 1).max()), 0.0)


# ------------------------------------------------- (i) Phase D T062: quantization levels
def test_q_levels_menu():
    """Menu index -> levels (255 / 1023 / float); at 1023 every blur and wc output is a multiple of
    1/1023; at float the stages are unquantized (blur = the unrounded weighted sum)."""
    check("Q_LEVELS = (255, 1023, float)", float(m.Q_LEVELS != (255.0, 1023.0, None)), 0.0)
    rng = np.random.default_rng(6)
    st = (rng.integers(0, 256, (20, 20, 4)) / 255.0).astype(F32)
    for lv in (1023.0,):
        conv = m.blur(st, lv)
        out = m.wc_step(st, conv, 0, lv)
        for name, a in (("blur", conv), ("wc", out[..., :3])):
            k = a.astype(np.float64) * lv
            check(f"levels {int(lv)}: {name} on the 1/{int(lv)} grid (max off-grid)",
                  float(np.abs(k - np.round(k)).max()), 2e-3)
    cf = m.blur(st, None)
    k = cf.astype(np.float64) * 1023.0
    check("float: blur is NOT on the 1/1023 grid (some off-grid value > 0.01)",
          float(np.abs(k - np.round(k)).max() < 0.01), 0.0)


# ------------------------------------------------- (j) Phase D T070: Freeze
def test_freeze_holds_and_resumes():
    """Freeze writes the incoming state back unchanged (alpha 1), whatever s or the pulse; frozen for
    any number of frames the state does not move; unfreezing resumes exactly as an unfrozen step of
    that held state would."""
    rng = np.random.default_rng(7)
    st = (rng.integers(0, 256, (24, 24, 4)) / 255.0).astype(F32)
    st[..., 3] = 1.0
    conv = m.blur(st)
    held = m.wc_step(st, conv, 0, s=F32(0.6), freeze=True)
    check("frozen step == the incoming state (max |diff|)", float(np.abs(held - st).max()), 0.0)
    x = st
    for fr in range(50):
        x = m.step(x, fr, freeze=True)
    check("50 frozen frames: state unchanged (max |diff|)", float(np.abs(x - st).max()), 0.0)
    check("resume == an unfrozen step of the held state (max |diff|)",
          float(np.abs(m.step(x, 50) - m.step(st, 50)).max()), 0.0)


# ------------------------------------------------- (k) Phase D T065: Rate (step skipping)
def test_rate_is_slow_motion():
    """Rate 1 is the parity run; rate 0.5 for 2T frames equals rate 1 for T frames exactly (same look,
    half speed); rate 0.25 steps on exactly a quarter of the frames."""
    rng = np.random.default_rng(8)
    st0 = (rng.integers(0, 256, (24, 24, 4)) / 255.0).astype(F32)
    st0[..., 3] = 1.0
    a = st0
    for f in range(60):
        a = m.module_frame(a, f, 1.0)
    b = st0
    for f in range(60):
        b = m.step(b, f, s=m.s_pulse(f))
    check("rate 1 == the parity run (60 frames, max |diff|)", float(np.abs(a - b).max()), 0.0)
    c = st0
    for f in range(120):
        c = m.module_frame(c, f, 0.5)
    check("rate 0.5 x 120 frames == rate 1 x 60 frames (max |diff|)", float(np.abs(c - a).max()), 0.0)
    n_steps = sum(m.rate_clock(f, 0.25)[0] for f in range(400))
    check("rate 0.25: 100 steps in 400 frames (|count - 100|)", abs(n_steps - 100), 0.0)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
