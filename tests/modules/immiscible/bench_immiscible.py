"""
bench_immiscible.py -- f_vf_immiscible Phase 1 (tasks.md T016): every stage codebox under
src/f_vf_immiscible/ run on the GPU through the codebox bench and diffed against the NumPy mirror in
immiscible_mirror.py, then the whole chain host-sequenced over many frames (the bench drives one codebox
per job; plan ADR-10), then spec success criteria 1-4 on the GPU path.

Stage jobs (one pass per job, outputs chained from Python):
    inab  in1 = bang stand-in, in2 = velocity A (render res), in3 = velocity B
    pass  in1 = bang stand-in, in2 = held state
    adv   in1 = phi state (hot), in2 = packed velocities, in3 = phi source (render res)
    fx, fy, iy, ix  in1 = previous stage
    spec  in1 = spectral texture
    enc   in1 = bang stand-in, in2 = packed velocities, in3 = phi state; BOTH outlets compared

TOLERANCES are first-run provisional (modelled on bench_fluid) until measured; every check prints its
measured number. The bench keeps Params between jobs, so every job pins ALL the stage's Params.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/immiscible/bench_immiscible.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 65

import paths as _paths
import time

import numpy as np

import benchclient as bc
import fluid_mirror as fm
import immiscible_mirror as im
from immiscible_mirror import Params
from gpu_sim import F32
from harness import check, note, run
from dft_mirror import make_image, pack, rel_err
from test_fluid_mirror import rand_force, smooth_state

SRC = _paths.REPO / "src" / "f_vf_immiscible"
N = 256
FILES = {"inab": "codebox_inab.gen", "pass": "codebox_pass.gen", "adv": "codebox_adv.gen",
         "fx": "codebox_dft_fx.gen", "fy": "codebox_dft_fy.gen", "spec": "codebox_spec.gen",
         "iy": "codebox_dft_iy.gen", "ix": "codebox_dft_ix.gen", "enc": "codebox_enc.gen"}
BANG = np.zeros((4, 4, 4), np.float32)          # stand-in for the `r draw` bang inlet
NOSRC = np.zeros((4, 4, 4), np.float32)         # phi source stand-in when src_phi = 0


def code(stage):
    return (SRC / FILES[stage]).read_text()


def gpu(stage, inputs, dim=None, params=None, timeout_ms=30000, all_outputs=False):
    out, r = bc.run_pass(code(stage), inputs, dim=dim, params=params or {}, timeout_ms=timeout_ms,
                         all_outputs=all_outputs)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"{stage}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def g_inab(A, B, p):
    return gpu("inab", [BANG, A, B], dim=(N, N), params={"taps": p.taps, "src_a": p.src_a, "src_b": p.src_b})


def g_pass(hold, reseed, salt=0.0, fill=0.0):
    return gpu("pass", [BANG, hold], dim=(N, N), params={"reseed": reseed, "salt": salt, "fill": fill})


def g_adv(state, uab, src, p):
    return gpu("adv", [state, uab, NOSRC if src is None else src], dim=(N, N),
               params={"dt": p.dt, "inject": p.inject, "taps": p.taps, "freeze": p.freeze, "src_phi": p.src_phi})


def g_spec(tex, p):
    return gpu("spec", [tex], params={"iface": p.iface, "coarsen": p.coarsen, "freeze": p.freeze})


def g_enc(state, uab, p, size):
    h, w = size
    o = gpu("enc", [BANG, uab, state], dim=(w, h), params={"bypass_gate": p.bypass_gate}, all_outputs=True)
    return o[0], o[1]


def g_step(state, uab, src, p):
    """One solver frame from real GPU passes: adv -> fx -> fy -> spec -> iy -> ix."""
    t = g_adv(state, uab, src, p)
    t = gpu("fx", [t])
    t = gpu("fy", [t])
    t = g_spec(t, p)
    t = gpu("iy", [t])
    return gpu("ix", [t])


def rel(a, b):
    return float(np.max(np.abs(a - b)) / max(float(np.max(np.abs(b))), 1e-30))


def smooth_phi(seed=3, amp=1.0):
    return im.phi_state(smooth_state(N, seed, amp=amp)[..., 0])


def smooth_uab(seed=11, amp=0.8):
    a, b = smooth_state(N, seed, amp=amp), smooth_state(N, seed + 1, amp=amp)
    u = np.zeros((N, N, 4), F32)
    u[..., 0], u[..., 1], u[..., 2], u[..., 3] = a[..., 0], a[..., 2], b[..., 0], b[..., 2]
    return u


def smooth_vecfield(seed, amp=0.8, n=N):
    s = smooth_state(n, seed, amp=amp)
    t = np.zeros((n, n, 4), F32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = 0.5 + 0.5 * s[..., 0], 0.5 + 0.5 * s[..., 2], 0.5, 1.0
    return t


def smooth_source(seed, n=N):
    s = smooth_state(n, seed, amp=0.5)
    t = np.zeros((n, n, 4), F32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = 0.5 + s[..., 0], 0.5 + s[..., 2], 0.5 + 0.5 * s[..., 0], 1.0
    return t


# ----------------------------------------------------------------- compile and run

def test_every_stage_compiles_and_runs():
    st = smooth_phi()
    spectral = fm.fft2_np(im.pack_phi(st[..., 0]))
    runs = {
        "inab": lambda: gpu("inab", [BANG, rand_force(64, 64, 2), rand_force(80, 80, 3)], dim=(N, N)),
        "pass": lambda: gpu("pass", [BANG, st], dim=(N, N)),
        "adv": lambda: gpu("adv", [st, smooth_uab(), NOSRC], dim=(N, N)),
        "fx": lambda: gpu("fx", [st]), "fy": lambda: gpu("fy", [st]),
        "spec": lambda: gpu("spec", [spectral]),
        "iy": lambda: gpu("iy", [spectral]), "ix": lambda: gpu("ix", [spectral]),
        "enc": lambda: gpu("enc", [BANG, smooth_uab(), st], dim=(120, 90), all_outputs=True),
    }
    for name, fn in runs.items():
        out = fn()
        arrs = [o for o in out if o is not None] if isinstance(out, list) else [out]
        assert all(np.isfinite(a).all() for a in arrs), f"{name}: non-finite output"
        print(f"    ok   {name}: compiles, runs, {len(arrs)} output(s) finite")


# ----------------------------------------------------------------- inab

def test_inab_matches_mirror_and_gates():
    B128 = rand_force(128, 128, 5)
    for label, A, B, taps, tol in (("1:1, taps 8", rand_force(256, 256, 4), rand_force(256, 256, 5), 8, 1e-4),
                                   ("1:1, taps 1", rand_force(256, 256, 4), rand_force(256, 256, 5), 1, 1e-4),
                                   ("A 1:1, B 128 magnified, taps 2", rand_force(256, 256, 4), B128, 2, 1e-3)):
        p = Params(taps=taps, src_a=1.0, src_b=1.0)
        err = np.max(np.abs(g_inab(A, B, p) - im.inab(A, B, taps, 1.0, 1.0, N)))
        check(f"inab {label}: max err vs mirror", err, tol)
    A, B = rand_force(256, 256, 4), rand_force(256, 256, 5)
    black = np.zeros((256, 256, 4), F32)                       # vs_black: all zeros, B != 0.5
    p = Params(taps=2.0, src_a=1.0, src_b=1.0)
    out = g_inab(black, B, p)
    check("inab: vs_black on A with src_a=1 reads as zero velocity", np.max(np.abs(out[..., 0:2])), 1e-6)
    check("inab: ... and leaves B alone (vs mirror)", np.max(np.abs(out - im.inab(black, B, 2.0, 1.0, 1.0, N))), 1e-4)
    for flag, name in (((0.0, 1.0), "src_a=0"), ((1.0, 0.0), "src_b=0")):
        p = Params(taps=2.0, src_a=flag[0], src_b=flag[1])
        out = g_inab(A, B, p)
        dead = out[..., 0:2] if flag[0] == 0 else out[..., 2:4]
        live = out[..., 2:4] if flag[0] == 0 else out[..., 0:2]
        check(f"inab {name}: that input is exactly zero", np.max(np.abs(dead)), 1e-6)
        assert np.max(np.abs(live)) > 0.1, f"inab {name}: the other input vanished"
        check(f"inab {name}: whole texture vs mirror", np.max(np.abs(out - im.inab(A, B, 2.0, *flag, N))), 1e-4)
    note("inab minified 2x (512 source, taps 2) vs mirror (informational)",
         np.max(np.abs(g_inab(rand_force(512, 512, 6), B, Params(taps=2.0, src_a=1.0, src_b=1.0))
                       - im.inab(rand_force(512, 512, 6), B, 2.0, 1.0, 1.0, N))))
    g_inab(A, B, Params(taps=2.0, src_a=1.0, src_b=1.0))        # leave the Params at the defaults


# ----------------------------------------------------------------- pass

def test_pass_hold_reseed_and_self_heal():
    hold = smooth_phi(4)
    out = g_pass(hold, 0.0, 3.0, 0.0)
    check("pass hold: R equals the held state exactly", np.max(np.abs(out[..., 0] - hold[..., 0])), 0)
    check("pass hold: G, B, A are zero", np.max(np.abs(out[..., 1:])), 0)
    for salt, fill in ((3.0, 0.0), (7.0, 0.3)):
        got = g_pass(hold, 1.0, salt, fill)
        want = im.pass_stage(hold, 1.0, salt, fill)
        d = np.abs(got - want)
        # The hash is chaotic by design: fract((hx + hy) * hz) is taken at magnitude ~2e3, where float32
        # resolves ~2e-4 of the fraction, so GPU and NumPy agree exactly on most texels (median err ~1e-9),
        # differ by ~1e-4 on ~7.5% (rounding), and wrap-flip a full 2*amp = 0.1 on ~0.05% (fract boundary).
        # Measured 2026-10-27: p99 2.9e-4, fraction > 1e-2 3e-4..5e-4. The bit-match the T012 note hoped for
        # is not attainable at float32; what matters is determinism, uniformity and salt decorrelation.
        check(f"pass reseed salt={salt:g} fill={fill:g}: fraction of texels wrap-flipped vs the mirror (> 1e-2)",
              float(np.mean(d[..., 0] > 1e-2)), 2e-3)
        check(f"pass reseed salt={salt:g} fill={fill:g}: 99th percentile |err| vs the mirror", float(np.percentile(d[..., 0], 99)), 5e-4)
        note(f"pass reseed salt={salt:g} fill={fill:g}: fraction off by > 1e-4 (rounding, informational)", float(np.mean(d[..., 0] > 1e-4)))
        z = (got[..., 0] - fill) / 0.05
        check(f"pass reseed salt={salt:g}: noise mean (uniform in [-1, 1) is 0)", abs(float(z.mean())), 0.02)
        check(f"pass reseed salt={salt:g}: noise std (uniform is 0.5774)", abs(float(z.std()) - 0.5774), 0.02)
    a, b = g_pass(hold, 1.0, 3.0, 0.0), g_pass(hold, 1.0, 3.0, 0.0)
    check("pass reseed: same salt gives the identical field on the GPU (FR-014)", float(np.max(np.abs(a - b))), 0)
    c = g_pass(hold, 1.0, 7.0, 0.0)
    check("pass reseed: a different salt gives a different field (fraction of texels equal)", float(np.mean(np.abs(a[..., 0] - c[..., 0]) < 1e-3)), 0.05)
    bad = hold.copy()
    bad[10, 5, 0], bad[20, 7, 0], bad[30, 9, 0] = np.nan, np.inf, -np.inf
    got = g_pass(bad, 0.0, 3.0, 0.0)
    assert np.isfinite(got).all(), "pass let a non-finite value through"
    want = im.pass_stage(bad, 0.0, 3.0, 0.0)
    keep = np.ones((N, N), bool)
    keep[10, 5] = keep[20, 7] = keep[30, 9] = False
    check("pass self-heal: non-finite texels are reseeded (vs mirror)", max(abs(got[10, 5, 0] - want[10, 5, 0]),
          abs(got[20, 7, 0] - want[20, 7, 0]), abs(got[30, 9, 0] - want[30, 9, 0])), 1e-4)
    check("pass self-heal: every other texel untouched", np.max(np.abs(got[..., 0][keep] - bad[..., 0][keep])), 0)
    for val in (1.0, -1.0, 0.0):                                 # FR-010: uniform states are legitimate
        u = im.phi_state(np.full((N, N), val, F32))
        check(f"pass: a uniform phi = {val:+g} state is left alone", np.max(np.abs(g_pass(u, 0.0, 3.0, 0.5)[..., 0] - val)), 0)


# ----------------------------------------------------------------- adv

def test_adv_matches_mirror():
    st, uab = smooth_phi(3), smooth_uab()
    p = Params(dt=0.05, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0)
    err = np.max(np.abs(g_adv(st, uab, None, p) - im.adv(st, uab, None, p)))
    check("adv blend + advect, no source: max err vs mirror", err, 1e-4)
    for label, size, tol in (("source 256 (1:1)", 256, 1e-4), ("source 128 (magnified 2x)", 128, 1e-3)):
        src = smooth_source(7, size)
        p = Params(dt=0.05, inject=0.5, taps=2.0, freeze=0.0, src_phi=1.0)
        err = np.max(np.abs(g_adv(st, uab, src, p) - im.adv(st, uab, src, p)))
        check(f"adv inject {label}: max err vs mirror", err, tol)
    p0 = Params(dt=0.05, inject=0.5, taps=2.0, freeze=0.0, src_phi=0.0)
    check("adv src_phi=0 with a source present: equals the source-free mirror",
          np.max(np.abs(g_adv(st, uab, smooth_source(7), p0) - im.adv(st, uab, None, p0))), 1e-5)
    pf = Params(dt=0.05, inject=0.5, taps=2.0, freeze=1.0, src_phi=1.0)
    got = g_adv(st, uab, smooth_source(7), pf)
    check("adv freeze=1: phi passes through unchanged", np.max(np.abs(got[..., 0] - st[..., 0])), 1e-6)
    check("adv freeze=1: packed as (phi, 0, phi^3, 0) vs mirror", np.max(np.abs(got - im.adv(st, uab, None, pf))), 1e-5)
    # clamp: phi = 3 everywhere comes out at the 1.25 bound (and freeze leaves it alone)
    big = im.phi_state(np.full((N, N), 3.0, F32))
    z = np.zeros((N, N, 4), F32)
    got = g_adv(big, z, None, Params(dt=0.05, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0))
    check("adv clamp: phi = 3 -> 1.25", np.max(np.abs(got[..., 0] - 1.25)), 1e-6)
    check("adv clamp: B carries 1.25^3", np.max(np.abs(got[..., 2] - 1.25 ** 3)), 1e-5)
    got = g_adv(big, z, None, Params(dt=0.05, inject=0.0, taps=2.0, freeze=1.0, src_phi=0.0))
    check("adv freeze=1: phi = 3 is not clamped", np.max(np.abs(got[..., 0] - 3.0)), 1e-6)
    # seam: whole-texel x shifts are an exact wrapped gather (any edge clamping shows at once)
    col = np.random.default_rng(9).uniform(-1, 1, N).astype(F32)
    s2 = im.phi_state(np.tile(col, (N, 1)))
    for u, dt in ((0.25, 0.25), (0.5, 0.25), (0.75, 0.25)):
        uu = np.zeros((N, N, 4), F32)
        uu[..., 0] = uu[..., 2] = u
        got = g_adv(s2, uu, None, Params(dt=dt, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0))
        shift = int(round(u * dt * N))
        want = col[(np.arange(N) - shift) % N]
        check(f"adv periodic seam, shift {shift} texels: exact wrapped gather", np.max(np.abs(got[..., 0] - want[None, :])), 1e-6)


# ----------------------------------------------------------------- spec

def test_spec_matches_mirror():
    rng = np.random.default_rng(6)
    phi = rng.uniform(-1, 1, (N, N)).astype(F32)               # white noise: Nyquist bins included
    tex = fm.fft2_np(im.pack_phi(phi))
    cases = [(4.0, 0.3, 0.0), (1.5, 1.0, 0.0), (8.0, 0.1, 0.0), (2.0, 0.6, 0.0), (4.0, 2.0, 0.0), (4.0, 0.3, 1.0),
             (4.0, 0.0, 0.0)]
    for iface, c, fr in cases:
        p = Params(iface=iface, coarsen=c, freeze=fr)
        err = rel(g_spec(tex, p), im.spec(tex, p))
        check(f"spec iface={iface:g} coarsen={c:g} freeze={fr:g}: rel err vs mirror", err, 1e-4)
    g_spec(tex, Params())                                       # back to the defaults
    p = Params(iface=4.0, coarsen=1.0, freeze=0.0)
    out = g_spec(tex, p)
    check("spec: the k = 0 bin is exactly its input (factor 1, fn 0)", float(np.max(np.abs(out[0, 0, 0:2] - tex[0, 0, 0:2]))), 1e-4)
    check("spec: B and A are zero on output", float(np.max(np.abs(out[..., 2:]))), 0)


# ----------------------------------------------------------------- DFT

def test_dft_stages():
    phi = make_image(N, N, 1) * 2 - 1
    phi3 = (phi ** 3).astype(F32)
    tex = pack(phi.astype(F32), phi3)
    fwd = gpu("fy", [gpu("fx", [tex])])
    for c, name, ref in ((0, "phi", phi), (2, "phi^3", phi3)):
        z = fwd[..., c].astype(np.float64) + 1j * fwd[..., c + 1]
        check(f"forward fx->fy {name} vs np.fft.fft2 (rel)", rel_err(z, np.fft.fft2(ref.astype(np.float64))), 1e-5)
    back = gpu("ix", [gpu("iy", [fwd])])
    check("round trip: |phi' - phi|", np.max(np.abs(back[..., 0] - phi)), 1e-5)
    check("round trip: |phi^3' - phi^3|", np.max(np.abs(back[..., 2] - phi3)), 1e-5)
    check("ix outputs Im = 0 exactly", np.max(np.abs(back[..., [1, 3]])), 0)
    clean = gpu("ix", [fwd])
    dirty = fwd.copy()
    dirty[10, 5, 0], dirty[10, 90, 2] = np.nan, np.inf
    g = gpu("ix", [dirty])
    assert np.isfinite(g).all(), "ix let a non-finite value through"
    rows = np.arange(N) != 10
    check("ix guard: contaminated row -> 0", np.max(np.abs(g[10])), 0)
    check("ix guard: other rows unchanged", np.max(np.abs(g[rows] - clean[rows])), 0)


# ----------------------------------------------------------------- enc

def test_enc_matches_mirror_on_both_outlets():
    st, uab = smooth_phi(5), smooth_uab(13)
    for (h, w) in ((90, 120), (60, 100), (256, 256)):
        for gate in (0.0, 1.0):
            p = Params(bypass_gate=gate)
            o0, o1 = g_enc(st, uab, p, (h, w))
            w0, w1 = im.enc(st, uab, p, (h, w))
            check(f"enc {h}x{w} gate={gate:g} out1 (phi grey): max err vs mirror", np.max(np.abs(o0 - w0)), 1e-5)
            check(f"enc {h}x{w} gate={gate:g} out2 (velocity): max err vs mirror", np.max(np.abs(o1 - w1)), 1e-5)
    o0, o1 = g_enc(st, uab, Params(bypass_gate=1.0), (90, 120))
    neu = fm.neutral(90, 120)
    check("bypass: out1 is exactly neutral mid grey", np.max(np.abs(o0 - neu)), 1e-6)
    check("bypass: out2 is exactly the neutral vecfield", np.max(np.abs(o1 - neu)), 1e-6)
    o0, o1 = g_enc(st, uab, Params(bypass_gate=0.0), (90, 120))
    check("out1 alpha is 1 and R = G = B", float(np.max(np.abs(o0[..., 3] - 1)) + np.max(np.abs(o0[..., 0] - o0[..., 1]))
                                                 + np.max(np.abs(o0[..., 1] - o0[..., 2]))), 1e-6)
    check("out2 B = 0.5 and A = 1 (f_vecfield contract)", float(np.max(np.abs(o1[..., 2] - 0.5)) + np.max(np.abs(o1[..., 3] - 1))), 1e-6)


# ----------------------------------------------------------------- the chain over many frames

def test_multiframe_matches_mirror():
    """100 frames of the real stage chain (Python passes each stage's GPU output to the next) vs the
    mirror, from the GPU's own reseeded noise state, with two different smooth flows blended by phi."""
    A, B = smooth_vecfield(21), smooth_vecfield(22)
    p = Params(dt=0.02, iface=4.0, coarsen=1.0, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0, src_a=1.0, src_b=1.0)
    uab_g = g_inab(A, B, p)
    check("multiframe: inab vs mirror", np.max(np.abs(uab_g - im.inab(A, B, p.taps, 1.0, 1.0, N))), 1e-4)
    st0 = g_pass(np.zeros((N, N, 4), F32), 1.0, 3.0, 0.0)
    g = m = st0
    worst, t0 = 0.0, time.time()
    for f in range(1, 101):
        g = g_step(g, uab_g, None, p)
        m = im.step(m, A, B, None, p)
        worst = max(worst, float(np.max(np.abs(g[..., 0] - m[..., 0]))))
        if f % 20 == 0:
            note(f"frame {f}: |GPU - mirror| running max {worst:.2e}; phi std {float(g[..., 0].std()):.3f}", float(np.max(np.abs(g[..., 0] - m[..., 0]))))
    # Measured 2026-10-27: 3.8e-5 at frame 20, 1.5e-4 at 40, 3.8e-4 at 60, 7.8e-4 at 80, 1.3e-3 at 100 -- a smooth
    # rise from float32 rounding (stage errors are ~1e-6) carried through the nonlinear Cahn-Hilliard dynamics.
    # The pointwise bound is therefore a time-dependent allowance; the free energy is the invariant that must agree.
    check("100 frames: max |GPU - mirror| over all frames", worst, 3e-3)
    eg, em = im.free_energy(g[..., 0], p.iface), im.free_energy(m[..., 0], p.iface)
    check(f"100 frames: free energy GPU {eg:.5f} vs mirror {em:.5f} (rel)", abs(eg - em) / em, 1e-3)
    assert float(g[..., 0].std()) > 0.5, "the field never separated: the loop is not exercising Cahn-Hilliard"
    print(f"    ...  100 frames x 6 jobs in {time.time() - t0:.0f}s")


def test_multiframe_with_injection_matches_mirror():
    A, B = smooth_vecfield(23), smooth_vecfield(24)
    p = Params(dt=0.02, iface=4.0, coarsen=0.5, inject=0.3, taps=2.0, freeze=0.0, src_phi=1.0, src_a=1.0, src_b=1.0)
    src = smooth_source(25, 128)
    uab_g = g_inab(A, B, p)
    g = m = g_pass(np.zeros((N, N, 4), F32), 1.0, 5.0, -0.3)
    worst = 0.0
    for f in range(1, 31):
        g = g_step(g, uab_g, src, p)
        m = im.step(m, A, B, src, p)
        worst = max(worst, float(np.max(np.abs(g[..., 0] - m[..., 0]))))
    check("30 frames with injection: max |GPU - mirror|", worst, 1e-3)
    check("30 frames with injection: |mean(GPU) - mean(mirror)|", abs(float(g[..., 0].mean()) - float(m[..., 0].mean())), 1e-3)


def test_nan_in_the_state_heals_and_stays_finite():
    A, B = smooth_vecfield(26), smooth_vecfield(27)
    p = Params(dt=0.02, iface=4.0, coarsen=1.0, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0, src_a=1.0, src_b=1.0)
    uab = g_inab(A, B, p)
    st = g_pass(np.zeros((N, N, 4), F32), 1.0, 3.0, 0.0)
    st[40, 40, 0], st[41, 41, 0] = np.nan, np.inf                # a poisoned feedback state
    g = g_pass(st, 0.0, 3.0, 0.0)
    for f in range(10):
        g = g_step(g, uab, None, p)
        assert np.isfinite(g).all(), f"non-finite state at frame {f + 1}"
        g = g_pass(g, 0.0, 3.0, 0.0)
    print("    ok   NaN/Inf texels in the state: reseeded by pass, 10 frames finite")


# ----------------------------------------------------------------- spec success criteria on the GPU path

def test_SC1_SC2_mean_conserved_and_energy_falls_on_the_gpu():
    z = np.zeros((N, N, 4), F32)                                # no flow, no injection
    p = Params(dt=0.02, iface=4.0, coarsen=1.0, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0)
    g = g_pass(np.zeros((N, N, 4), F32), 1.0, 3.0, 0.2)
    mean0, e_prev, worst_drift, worst_rise = float(g[..., 0].mean()), im.free_energy(g[..., 0], p.iface), 0.0, -1e9
    for f in range(60):
        g = g_step(g, z, None, p)
        worst_drift = max(worst_drift, abs(float(g[..., 0].astype(np.float64).mean()) - mean0))
        e = im.free_energy(g[..., 0], p.iface)
        worst_rise = max(worst_rise, e - e_prev)
        e_prev = e
    check("SC1 (GPU, 60 frames): max |mean(phi) - mean(0)| (spec target 1e-6 per frame)", worst_drift, 1e-5)
    check("SC2 (GPU, 60 frames): largest frame-to-frame free-energy rise", max(worst_rise, 0.0), 1e-5)
    assert g[..., 0].std() > 0.5, "the field never separated"


def test_SC3_mode_growth_rate_on_the_gpu():
    x = (np.arange(N) + 0.5) / N
    amp0 = 1e-3
    phi = np.tile((amp0 * np.cos(2 * np.pi * 3 * x)).astype(F32), (N, 1))
    z = np.zeros((N, N, 4), F32)
    p = Params(dt=0.02, iface=4.0, coarsen=0.3, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0)
    g = im.phi_state(phi)
    for f in range(6):
        g = g_step(g, z, None, p)
    amp = float(np.mean(g[..., 0] * np.cos(2 * np.pi * 3 * x)[None, :]) * 2)
    k2 = (2 * np.pi * 3) ** 2
    mdt, kap = im.coarsen_to_mdt(0.3), im.kappa_of(4.0, N)
    xx = mdt * k2
    fa = (1 + xx * (im.A_STAB + 1)) / (1 + xx * (im.A_STAB + kap * k2))
    want, got = np.log(fa), np.log(amp / amp0) / 6
    check(f"SC3 (GPU): per-frame growth rate {got:.5f} vs analytic ln fa {want:.5f} (rel)", abs(got - want) / want, 0.02)


def test_SC4_interface_profile_on_the_gpu():
    x = np.arange(N) + 0.5
    z = np.zeros((N, N, 4), F32)
    p = Params(dt=0.02, iface=4.0, coarsen=2.0, inject=0.0, taps=2.0, freeze=0.0, src_phi=0.0)
    g = im.phi_state(np.tile(0.98 * np.sign(np.sin(2 * np.pi * 2 * x / N)), (N, 1)).astype(F32))
    for f in range(40):
        g = g_step(g, z, None, p)
    row = g[0, :, 0].astype(np.float64)
    j = next(i for i in range(N - 1) if row[i] < 0 <= row[i + 1])
    x0 = j + (-row[j]) / (row[j + 1] - row[j])
    sel = np.arange(j - 12, j + 14)
    err = float(np.abs(row[sel] - np.tanh((sel - x0) / (np.sqrt(2) * 4.0))).max())
    check("SC4 (GPU, 40 frames): stripe interface vs tanh(x / (sqrt2 iface)), max err (spec: within 10%)", err, 0.05)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
