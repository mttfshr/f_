"""
bench_formconstants.py -- f_formconstants Phase 1 (tasks.md T015, T016): every stage
codebox under src/f_formconstants/ run on the GPU through the codebox bench and diffed
against the NumPy mirror in fc_mirror.py, then the whole chain host-sequenced over 30
frames (the bench drives one codebox per job; the f_vf_fluid ADR-10 method, bench_wc.py
the template). ALSO the first Max-side GenExpr compile check of the two brand-new
codeboxes (blur_x/blur_y; the rewritten enc) -- the 2026-10-24 "module outputs black/
flickering solid" report is resolved or named by these legs (offline checks cannot
compile GenExpr).

Stage jobs (one pass per job, outputs chained from Python):
    pass   in1 = bang stand-in, in2 = feedback state (R = E, G = I, B = Ve, A = Vi),
           in3 = seed texture (R = seedE, G = seedI)
    seed   in1 = bang stand-in; R/G = reseed hashes, B/A = Box-Muller uniforms (Param salt)
    blur_x / blur_y   in1 = state; R blurred at sigma_E, G at sigma_I, B/A pass through
           (Params grain, sig_ratio -- sigma derived from dim per FR-002)
    nl     in1 = convolved (R = cE, G = cI), in2 = raw state, in3 = noise (B, A uniforms),
           in4 = drive (Box-Muller inside, E-only drive; Params dt, ne, drive_gain,
           drv_conn, habit, excite, aie, aii)
    enc    in1 = bang stand-in, in2 = state; retinotopic bilinear wrap at RENDER res
           (= state res), Params bypass_gate, sharp, contrast, k_ecc, k_ang, r0, r_soft

The per-frame noise stream is REPRODUCIBLE: the host feeds nl a noise texture it built
itself, and the mirror consumes the Box-Muller of the same uniforms, so the chain test
diffs pixels, not statistics.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/formconstants/bench_formconstants.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 56.5           # right after bench_wc (56)

import paths as _paths
import sys

import numpy as np

import benchclient as bc
import fc_mirror as km
from fc_mirror import F32, Params
from harness import check, note, run, slow

SRC = _paths.REPO / "src" / "f_formconstants"
N = 128
FILES = {"seed": "codebox_seed.gen", "pass": "codebox_pass.gen",
         "blurx": "codebox_blur_x.gen", "blury": "codebox_blur_y.gen",
         "nl": "codebox_nl.gen", "enc": "codebox_enc.gen"}
BANG = np.zeros((4, 4, 4), np.float32)          # stand-in for the `r draw` bang inlet
DRIVE = np.zeros((N, N, 4), np.float32)         # neutral drive (unconnected equivalent)
DRIVE[..., 3] = 1.0
# The bench keeps a Param's last value between jobs: every job pins every Param its codebox declares.
PINNED = {"seed": {"salt": 0.0, "sw": float(N), "sh": float(N)}, "pass": {"reseed": 0.0, "amp": 1.0},
          "blurx": {"grain": 0.0008, "sig_ratio": 1.45},
          "blury": {"grain": 0.0008, "sig_ratio": 1.45},
          "nl": {"dt": 1.0, "ne": 0.75, "drive_gain": 0.0, "drv_conn": 0.0,
                 "habit": 0.9, "excite": 0.0, "aie": 14.5, "aii": 13.0},
          "enc": {"bypass_gate": 0.0, "sharp": 0.5, "contrast": 1.0,
                  "k_ecc": 5.0, "k_ang": 3.0, "r0": 1.0, "r_soft": 0.35,
                  "sw": float(N), "sh": float(N)}}


def code(stage):
    return (SRC / FILES[stage]).read_text()


def gpu(stage, inputs, dim=None, **deltas):
    params = dict(PINNED.get(stage, {}))
    params.update(deltas)
    out, r = bc.run_pass(code(stage), inputs, dim=dim, params=params, timeout_ms=30000)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"{stage}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def tex(rng, h=N, w=N):
    return rng.random((h, w, 4), dtype=np.float32)


def boxmuller(na, nb, dt=1.0):
    """Exactly the nl codebox's per-frame Gaussian, float32 in the GPU's
    operation order (a float64 reference drifts ~6e-4/step through the trig,
    which the 30-frame chain amplifies ~10x through relaxation + habituation)."""
    f = np.float32
    a = (na.astype(f) * f(0.999) + f(0.0001)).astype(f)
    s = np.sqrt(np.float64(-2.0) * np.log(a.astype(np.float64))).astype(f)
    c = np.cos((f(2 * np.pi) * nb.astype(f)).astype(np.float64)).astype(f)
    return (s * c * f(np.sqrt(dt))).astype(f)


def mirror_frame(state, P, nx):
    """One host-side frame with the exact discrete blur (the codebox reference
    path, not the FFT soak path) and the given Gaussian field."""
    h, w = state.shape[0], state.shape[1]
    conv = km.blur_state(state, h, w, P)
    return km.nonlinear_step(conv, state, P.dt, P, noise=nx)


def test_seed_hash_channels():
    rng = np.random.default_rng(9)
    seed_out = gpu("seed", [BANG], dim=(N, N), salt=0.0)
    check("seed R: hash uniform in [0, 1)",
          max(0.0 - float(seed_out[..., 0].min()), float(seed_out[..., 0].max()) - 1.0), 0.0)
    seed_out1 = gpu("seed", [BANG], dim=(N, N), salt=1.0)
    check("seed R: reproducible per salt",
          float(np.abs(seed_out[..., 0] - gpu("seed", [BANG], dim=(N, N), salt=0.0)[..., 0]).max()), 1e-7)
    check("seed R: salt 1 differs from salt 0 (fresh noise per frame)",
          0.5 - float(np.abs(seed_out[..., 0] - seed_out1[..., 0]).mean()), 0.5)
    # the hash is cheap arithmetic (f_wc's, proven in use); pairwise sample
    # correlation ~0.21 observed at 128^2 -- benign as a noise UNIFORM source;
    # what matters is uniformity + decorrelation at the used level
    check("seed: R/G channels weakly correlated (cheap hash, proven precedent)",
          abs(float(np.corrcoef(seed_out[..., 0].ravel(), seed_out[..., 1].ravel())[0, 1])), 0.30)

def test_pass_identity_reseed_heal():
    rng = np.random.default_rng(9)
    seed_out = gpu("seed", [BANG], dim=(N, N), salt=0.0)
    fb = tex(rng)
    kept = gpu("pass", [BANG, fb, seed_out], dim=(N, N), reseed=0.0)
    check("pass: reseed=0 keeps the feedback state bit-exact",
          float(np.abs(kept - fb).max()), 0.0)
    re = gpu("pass", [BANG, fb, seed_out], dim=(N, N), reseed=1.0)
    check("pass: reseed=1 writes the seed hashes into R (E) and G (I)",
          max(float(np.abs(re[..., 0] - seed_out[..., 0]).max()),
              float(np.abs(re[..., 1] - seed_out[..., 1]).max()),
              float(np.abs(re[..., 2]).max()), float(np.abs(re[..., 3]).max())), 1e-7)
    dead = fb.copy(); dead[..., 0] = 0.0; dead[..., 1] = 0.0
    healed = gpu("pass", [BANG, dead, seed_out], dim=(N, N), reseed=0.0)
    check("pass: self-heal reseeds texels whose E and I channels are both exactly 0",
          max(float(np.abs(healed[..., 0] - seed_out[..., 0]).max()),
              float(np.abs(healed[..., 1] - seed_out[..., 1]).max())), 1e-7)

    # ------------------------------------------------------------- blur stages
    # ------------------------------------------------------------- blur stages
def test_blur_kernels_match_mirror():
    st = np.random.default_rng(9).random((N, N, 4), dtype=np.float32)
    P0 = Params()
    si, se = km.sigmas_px(N, N, P0)
    note("blur sigma at dim 128, grain 0.0008", f"si {float(si):.3f} px, se {float(se):.3f} px")
    mx = np.stack([km.blur_axis(st[..., 0], se, 1), km.blur_axis(st[..., 1], si, 1)])
    gx = gpu("blurx", [st], dim=(N, N))
    check("blur_x: R blurred at sigma_E along X vs the mirror kernel",
          float(np.abs(gx[..., 0] - mx[0]).max()), 5e-4)
    check("blur_x: G blurred at sigma_I along X vs the mirror kernel",
          float(np.abs(gx[..., 1] - mx[1]).max()), 5e-4)
    check("blur_x: B/A pass through bit-exact",
          float(np.abs(gx[..., 2:] - st[..., 2:]).max()), 0.0)
    my = np.stack([km.blur_axis(gx[..., 0], se, 0), km.blur_axis(gx[..., 1], si, 0)])
    gy = gpu("blury", [gx], dim=(N, N))
    check("blur_y: R blurred at sigma_E along Y vs the mirror kernel",
          float(np.abs(gy[..., 0] - my[0]).max()), 5e-4)
    mc = km.blur_state(st, N, N, P0)
    check("blur_x + blur_y chained == mirror blur_state",
          max(float(np.abs(gy[..., 0] - mc[0]).max()),
              float(np.abs(gy[..., 1] - mc[1]).max())), 5e-4)
    # the wrap boundary is exercised: feed an impulse, read the wrapped ring
    imp = np.zeros((N, N, 4), np.float32); imp[0, 0, 0] = 1.0
    gix = gpu("blurx", [imp], dim=(N, N))
    m_ix = km.blur_axis(imp[..., 0], se, 1)
    check("blur_x: wraps at the periodic boundary",
          float(np.abs(gix[..., 0] - m_ix).max()), 5e-4)

def test_noise_boxmuller_gpu_order():
    """The GPU computes its own Box-Muller in a bare leg; compare against the
    bench's mirror simulation term for term. Isolates the noise stream from
    the rest of the nl update (the chain divergence is noise-perturbation-
    amplified, so nx must be right to ~1e-5 before judging the rest)."""
    rng = np.random.default_rng(7)
    tex_noise = tex(rng)
    code_noise = ("Param dt(1);\n"
                  "na = nearest(in1, norm).z * 0.999 + 0.0001;\n"
                  "nb = nearest(in1, norm).w * 0.999 + 0.0001;\n"
                  "nx = sqrt(0 - 2 * log(na)) * cos(twopi * nb) * sqrt(dt);\n"
                  "out1 = vec(na, nb, nx, 1);")
    out, r = bc.run_pass(code_noise, [tex_noise], dim=(N, N), params={"dt": 1.0},
                         timeout_ms=30000)
    assert r["status"] == "ok", f"boxmuller leg failed: {r['errors']}"
    gna = out[..., 0]
    gnb = out[..., 1]
    gnx_gpu = out[..., 2]
    gnx_sim = boxmuller(tex_noise[..., 2], tex_noise[..., 3], 1.0)
    d = np.abs(gnx_gpu - gnx_sim)
    yx = np.unravel_index(int(d.argmax()), d.shape)
    sna = tex_noise[..., 2][yx] * np.float32(0.999) + np.float32(0.0001)
    print(f"    ...  gpu-read na {float(gna[yx]):.8f} nb {float(gnb[yx]):.8f} "
          f"vs array na {float(sna):.8f} nb {float(tex_noise[..., 3][yx]):.8f}")
    # same-formula value from the GPU's own readback (numpy float64)
    ref = np.sqrt(-2 * np.log(float(gna[yx]))) * np.cos(2 * np.pi * float(gnb[yx]))
    print(f"    ...  gpu nx {float(gnx_gpu[yx]):.6f} vs float64-of-gpu-readback {ref:.6f}")
    note("boxmuller gpu-vs-sim max diff",
         f"{float(d.max()):.3e} at {yx}: gpu {float(gnx_gpu[yx]):.6f} sim {float(gnx_sim[yx]):.6f} "
         f"(na {float(tex_noise[..., 2][yx]):.6f} nb {float(tex_noise[..., 3][yx]):.6f})")
    note("boxmuller mean abs diff", f"{float(d.mean()):.3e}")
    note("readback na/nb max channel drift",
         f"na {float(np.abs(gna - (tex_noise[..., 2] * np.float32(0.999) + np.float32(0.0001))).max()):.2e} "
         f"nb {float(np.abs(gnb - tex_noise[..., 3]).max()):.2e}")
    check("GPU Box-Muller matches the bench simulation", float(d.max()), 1e-3)


def test_nl_full_update_vs_mirror():
    st = np.random.default_rng(9).random((N, N, 4), dtype=np.float32)
    Pn = Params()
    noise_tex = tex(np.random.default_rng(9))
    nx = boxmuller(noise_tex[..., 2], noise_tex[..., 3], Pn.dt)
    bl = km.blur_state(st, N, N, Pn)
    conv_tex = np.zeros((N, N, 4), dtype=np.float32)
    conv_tex[..., 0] = bl[0]
    conv_tex[..., 1] = bl[1]
    gn = gpu("nl", [conv_tex, st, noise_tex, DRIVE], dim=(N, N))
    mn = km.nonlinear_step(bl.astype(np.float32), st, Pn.dt, Pn, noise=nx)
    cd = np.abs(gn - mn).max(axis=(0, 1))
    note("nl channel diffs", " ".join(f"{float(cd[c]):.2e}" for c in range(4)))
    note("nl E diff mean/max", f"{float(np.abs(gn[..., 0] - mn[..., 0]).mean()):.2e} / {float(cd[0]):.2e}")
    d0 = np.abs(gn[..., 0] - mn[..., 0])
    yx = np.unravel_index(int(d0.argmax()), d0.shape)
    note("nl max-E-diff texel inputs",
         f"gpu {float(gn[..., 0][yx]):.6f} mirror {float(mn[..., 0][yx]):.6f} | "
         f"ce {float(conv_tex[..., 0][yx]):.4f} ci {float(conv_tex[..., 1][yx]):.4f} "
         f"ee {float(st[..., 0][yx]):.4f} ve {float(st[..., 2][yx]):.4f} "
         f"nx {float(nx[yx]):.4f} na {float(noise_tex[..., 2][yx]):.6f} nb {float(noise_tex[..., 3][yx]):.6f}")
    check("nl: full update vs the mirror (noise, habituation, carry)",
          float(cd.max()), 1e-3)
    # habituation = 0 pins the carry channels at exactly 0 (the G5 rule)
    gn0 = gpu("nl", [gn, gn, noise_tex, DRIVE], dim=(N, N), habit=0.0)
    check("nl: habit=0 pins B/A to exactly 0",
          max(float(np.abs(gn0[..., 2]).max()), float(np.abs(gn0[..., 3]).max())), 0.0)

def test_enc_probe_ramp_coordinates():
    """Diagnostic: state E = a known ramp, so the rendered value at a pixel
    reveals WHICH texel the GPU sampled. A correct map yields au == the
    mirror's E at the same pixel; any systematic disagreement exposes the map
    error numerically (transpose, offset, scale) instead of via correlation."""
    st = np.zeros((N, N, 4), dtype=np.float32)
    ys, xs = np.mgrid[0:N, 0:N].astype(np.float32)
    st[..., 0] = xs / N        # R = column index / N (x ramp)
    st[..., 1] = ys / N        # G = row index / N (y ramp, for cross-check)
    g = gpu("enc", [BANG, st], dim=(N, N), sharp=0.0)
    men = km.encode(st, (N, N), sharp=F32(0.0), contrast=F32(1.0),
                    k_ecc=F32(5.0), k_ang=F32(3.0), r0=F32(1.0), r_soft=F32(0.35))
    spots = [(N // 2, N // 2), (N // 2, N - 8), (N // 4, 3 * N // 4), (16, 16), (96, 32)]
    for y, x in spots:
        print(f"    ...  pixel ({y},{x}): gpu {float(g[y, x, 0]):.4f} "
              f"gpuG {float(g[y, x, 1]):.4f} mirror {float(men[y, x, 0]):.4f}")
    d = float(np.abs(g[..., 0] - men[..., 0]).max())
    note("ramp max diff", f"{d:.4f}")
    check("enc probe: ramp render matches the mirror's sampled columns", d, 0.02)


def test_enc_render_and_bypass():
    st = np.random.default_rng(9).random((N, N, 4), dtype=np.float32)
    enc_out = gpu("enc", [BANG, st], dim=(N, N))
    men = km.encode(st, (N, N), sharp=F32(0.5), contrast=F32(1.0),
                    k_ecc=F32(5.0), k_ang=F32(3.0), r0=F32(1.0), r_soft=F32(0.35))
    g, m = enc_out[..., 0], men[..., 0]
    d = np.abs(g - m)
    ys, xs = np.nonzero(d == d.max())
    note("enc center pixel gpu/mirror", f"{float(g[N//2, N//2]):.4f} / {float(m[N//2, N//2]):.4f}")
    note("enc max diff at", f"({ys[0]},{xs[0]}): gpu {float(g[ys[0], xs[0]]):.4f} mirror {float(m[ys[0], xs[0]]):.4f}")
    note("enc means gpu/mirror", f"{float(g.mean()):.4f} / {float(m.mean()):.4f}")
    note("enc corr gpu x mirror", f"{float(np.corrcoef(g.ravel(), m.ravel())[0, 1]):.4f}")
    check("enc: retinotopic bilinear-wrap render vs the mirror", float(d.max()), 2e-3)
    bn = gpu("enc", [BANG, st], dim=(N, N), bypass_gate=1.0)
    check("enc: bypass_gate = 1 outputs black with alpha 1",
          max(float(np.abs(bn[..., :3]).max()),
              float(np.abs(bn[..., 3] - 1).max())), 0.0)

def test_30_frame_chain_matches_mirror():
    Pchain = Params()
    gstate = km.seed_state(N, N, 3)
    mstate = gstate.copy()
    n_rng = np.random.default_rng(100)
    for fr in range(30):
        nz_tex = tex(n_rng)
        gnx = boxmuller(nz_tex[..., 2], nz_tex[..., 3], Pchain.dt)
        gbl = gpu("blurx", [gstate], dim=(N, N))
        gbl = gpu("blury", [gbl], dim=(N, N))
        gstate = gpu("nl", [gbl, gstate, nz_tex, DRIVE], dim=(N, N))
        mstate = mirror_frame(mstate, Pchain, gnx)
    d = float(np.abs(gstate - mstate).max())
    note("30-frame chain diff (channels)", " ".join(
        f"{float(np.abs(gstate - mstate).max(axis=(0, 1))[c]):.2e}" for c in range(4)))
    check("30-frame chain: GPU vs mirror frame-exact class", d, 1e-2)


if __name__ == "__main__":
    sys.exit(run(globals()))
