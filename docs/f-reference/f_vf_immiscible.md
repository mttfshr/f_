# f_vf_immiscible

**Type:** Processor (texture + two f_vecfield in → phase texture + f_vecfield out) — **temporal / has memory**
**Status:** Complete (live-checked by Matt 2026-10-28; defaults kept)

---

## What it does

An oil-and-water light show for velocity fields. Two upstream velocity vecfields, normally two `f_vf_fluid` modules set to different `viscosity`, each own one phase. A persistent **phase field φ** decides, pixel by pixel, which flow shows: φ = −1 is flow A, φ = +1 is flow B, in between is a convex mix. φ is carried along by the blended flow and **phase-separates** every frame (a Cahn–Hilliard step), so the two regions bead into droplets, coalesce, and keep a controlled edge instead of smearing into a grey mix. The blended velocity comes out as a normal f_vecfield, ready for `f_vf_advect`, `f_vf_warp` and friends; φ comes out as a grey texture so you can look at (or colour) the pattern itself.

It does **not** move any image and it does **not** run a fluid. The two upstream Fluids do the physics; this module only decides where each shows and keeps the boundary between them crisp. Nothing is fed back into the two Fluids (v1 is one-way).

Typical use: a force producer → two `f_vf_fluid` (say `viscosity` 0.05 and 0.6, same force) → `f_vf_immiscible` in1 and in2 → out1 → `f_vf_advect`. A camera or `f_grain` on in0 drops phase B in where it is bright.

There is **no single-fluid mode**: both vecfield inlets are required. An unconnected inlet, or a texture that is not a vecfield (B ≠ 0.5, such as `vs_black`), reads as zero velocity, not as `vs_black`'s decoded −1.

---

## Signal Flow

```
inlet 0 (control / φ source texture) → routepass
  texture → vs_inState → fanout → adv in2 (source); flag → prepend param src_phi → adv
  unmatched → route dt iface coarsen inject thresh pull fill mix_pct taps reset → dials → prepend param <name> → stage(s)
inlet 1 (velocity A) → vs_inState → inab in1;  flag → src_a → inab
inlet 2 (velocity B) → vs_inState → inab in2;  flag → src_b → inab

r draw → inab, pass, enc

hold → pass (in1) → adv (in0, HOT) → fx → fy → spec → iy → ix → hold        (feedback, one-frame latency)
inab → adv (in1, cold) ;  inab → enc (in1) ;  ix → enc (in2)
enc out0 = φ grey,  out1 = blended velocity ;  bypass jsui → prepend param bypass_gate → enc
```

### Stages

| # | Node (`#0_imm_…`) | Does | Size |
|---|---|---|---|
| 0 | `inab` | decodes, content-gates and minifies BOTH vecfields (`taps × taps` average) into one packed texture (R,G = uA, B,A = uB) | 256² |
| 1 | `hold` | identity; keeps last frame's state | 256² |
| 2 | `pass` | holds the state, or reseeds it (`fill` plus small deterministic noise; salt changes the pattern each reset) | 256² |
| 3 | `adv` | blends the two velocities by φ, backward-advects φ (periodic bilinear), injects the source, clamps, packs φ and φ³ | 256² |
| 4–5 | `fx`, `fy` | forward DFT along x, then y (φ and φ³ as two complex fields) | 256² |
| 6 | `spec` | the stabilised Cahn–Hilliard step per Fourier bin, plus the `pull` on the k = 0 bin | 256² |
| 7–8 | `iy`, `ix` | inverse DFT; `ix` keeps the real part | 256² |
| 9 | `enc` | render-size outlets: out0 φ grey, out1 blended velocity as an f_vecfield; bypass gate | render res |

Solver stages are `@adapt 0 @dim 256 256 @type float32`; the four DFT codeboxes are baked from one template and checked identical to `f_vf_fluid`'s. `adv` and `enc` are generated from one blend block (`gen_blend.py`): edit the generator, never the `.gen`.

---

## Outlets

| Outlet | Content |
|---|---|
| 0 | φ as a grey texture: `w = (φ + 1) / 2`, RGB equal, A = 1. Neutral (bypass) = mid grey. Uses the **unshifted** weight, so `Mix` never changes it. |
| 1 | The blended velocity: f_vecfield, float32, R,G = 0.5 + 0.5·v, B = 0.5, A = 1. Neutral (bypass) = (0.5, 0.5, 0.5, 1). |

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `dt` | 0–0.05 | 0.01 | Advection step: how far the pattern is carried by the flow each frame. 0 freezes the pattern in place. |
| `iface` | 1.5–12 | 4 | Interface width in solver texels. Small = crisp edge, large = soft blend zone. The floor 1.5 is where the interface profile still matches `tanh` to 1e-3. |
| `coarsen` | 0–1 | 0.3 | How fast the phases pull together into bigger blobs. Mobility is `0.1 · coarsen³` per frame, so most of the dial is in the lower half. 0 = the pattern is only carried, never re-forms. |
| `inject` | 0–1 | 0.3 | How strongly bright parts of the input-0 texture deposit phase B. Cubic: rate = `inject³` (0.3 → 0.027 per frame). |
| `thresh` | 0–0.9 | 0.5 | Luma the input-0 texture needs before it deposits: `smoothstep(thresh, thresh + 0.15, luma)`. |
| `pull` | 0–1 | 0.3 | Relaxes the overall mean of φ toward `fill`, rate `0.05 · pull³` per frame, so a held source settles into a balance instead of flooding to all-B. 0 = off. |
| `fill` | −0.6–0.6 | 0 | Mean φ at reset, and the balance point `pull` relaxes toward: negative = mostly A, positive = mostly B. |
| `mix_pct` (`Mix`) | 0–100 | 50 | Biases the VELOCITY weight only: 0 = everything moves like A, 50 = φ decides, 100 = everything moves like B. φ itself is still carried by the biased flow; the φ outlet is not shifted. |
| `taps` | 1–16 | 2 | Input filter: `taps × taps` samples per solver texel for the vecfield and source inputs. Control message only, no panel slot. |
| `reset` | button / message | — | Reseeds φ (mean = `fill`, plus noise, new salt each time). Also fires once ~200 ms after load. |
| `src_a`, `src_b`, `src_phi` | internal | — | Driven by `vs_inState` (1 = that inlet connected). |
| `reseed`, `salt` | internal | — | Driven by the reset logic. |
| `bypass_gate` | internal | — | Driven by the bypass jsui. |
| `bypass` | 0/1 | 0 | See Notes: neutral outlets; the solver keeps running. |

**Prefix:** `vfimm`. Ranges and defaults were judged by Matt live in Max (2026-10-28), two `f_vf_fluid` at different viscosity: "in good shape, the defaults are good", so nothing was changed. Settings Matt found working with a camera on in0 (not baked): `thresh` 0.85, `pull` 0.64, `fill` 0.22, `inject` 0.5, `coarsen` 0.02, `iface` 1.5, `dt` 0.

---

## Algorithm

```
uA, uB   = decode(vecfield A, B) * gate, box-filtered by taps               // zero if unconnected / not a vecfield
bw       = clamp((φ + 1) / 2, 0, 1)
mv       = (mix_pct - 50) * 0.02
bm       = bw + (1 - bw) * max(mv, 0) - bw * max(0 - mv, 0)                 // Mix bias, velocity weight only
u        = mix(uA, uB, bm)

φ_adv    = sample_periodic(φ, x - u * dt)
φ_new    = φ_adv + inject³ * smoothstep(thresh, thresh + 0.15, luma(src)) * (1 - φ_adv) * connected
φ_new    = clamp(φ_new, -1.25, 1.25)                                         // safety net only

φ̂, (φ³)^ = FFT(φ_new), FFT(φ_new³)
x        = 0.1 * coarsen³ * k²,   κ = (iface / N)²,   den = 1 + x (1.5 + κ k²)
φ̂'       = ((1 + 2.5 x) φ̂  -  x (φ³)^) / den                              // stabilised semi-implicit Cahn-Hilliard
φ̂'(0)   += 0.05 pull³ (fill N² - φ̂(0))                                     // only the k = 0 bin
φ        = Re(IFFT(φ̂'))

out0     = grey((φ + 1) / 2)
out1     = 0.5 + 0.5 * mix(uA, uB, bm)                                       // blended with the new φ
```

Periodic unit square, `k = 2π · signed_index`. The Cahn–Hilliard step conserves the mean of φ exactly (the k = 0 bin has x = 0); `pull` and the injection are the only things that change it, and the semi-Lagrangian advection of φ leaks a little (below).

---

## Notes

- **Settled model (gates).** G2 plain convex blend (the interface-aware and viscosity-weighted variants are not in the module). G5 bypass gives neutral outlets. G7 phase model Cahn–Hilliard. G3 `fill` default 0 kept. G6 the solver stays 256² (128² would cut the DFT chain roughly 8× but halve the look; not measured live). G4 φ grey encoding `w = (φ + 1) / 2` as proposed. G8 (momentum across the interface) is Phase 4, not built.
- **The blend cannot be divergence-free in general.** If both inputs are divergence-free, the plain blend `(1−w)·uA + w·uB` has divergence `∇w · (uB − uA)`; the integral of the divergence across the interface equals the normal jump `n·(uB − uA)` for **any** output-side rule. Measured with two stirred Fluids (rms |u| 0.82 vs 0.26): the plain blend's divergence is large in absolute terms (rms about 1.1× the sources' own gradient scale, max about 10×), and the interface-aware rule made it **worse** in every band tried, which is why G2 is plain. Consumers see real compression along the interface; only changing the flows themselves (Phase 4, nudging the Fluids toward the blend) removes it. For a smooth look, keep the normal components of the two Fluids similar (same force, different viscosity) or soften the edge with `iface`.
- **Why Cahn–Hilliard.** Under stirring it keeps the interface sharp (sharpness 0.98–1.0 of the flat-interface slope from frame 50 to 600, over `coarsen` 0.3 and 1.0), conserves each phase, and lets droplets bead and coalesce. Plain advection loses the droplets entirely (4→0), and pointwise sharpening collapses them (not conservative). The pre-registered mean-drift criterion failed by 0.006 (0.0264 against 0.02 at frame 600) and Matt accepted it on the long-run check below.
- **Small features dissolve.** A Cahn–Hilliard droplet below the critical size (Gibbs–Thomson effect) dissolves with no flow at all: a phase-B area of 3–4% as an 8-texel stripe or a pair of blobs vanished within 50–1200 frames, a 4.6% blob of radius 31 texels survived. Tiny drops from upstream (`f_grain`) at low `fill` will not persist; larger drops or a `fill` nearer 0 will.
- **Mean drift and `pull`.** Semi-Lagrangian advection of φ is not conservative. A 3600-frame mirror run (the stirring recipe) levelled off in every arm: stripes +0.035, noise start +0.015 (coarsen 0.3) or −0.008 (coarsen 1.0), droplets −0.081 (phase-B area 24.7% → 20.6%, flat from frame ~3000). So no restoring term is needed for the stirring case. A *held* source is different: with `pull` 0 a bright source floods the mean to exactly 1.000 (the mirror test), with `pull` 1 it settles at 0.064. `pull` is the only thing that bounds that, which is why its default is not 0.
- **Resolution limit.** φ lives on a fixed 256² grid and is bilinearly upsampled by `enc`, so detail finer than one solver texel (about 4.2 output pixels at 1080p, 8.4 at 4K) is not available. `iface` is in solver texels, so it scales with the picture; at `iface` 1.5 the edge is about one solver texel wide.
- **One-frame latency.** The state feeds back through `hold`, so the pattern lags its own velocity input by one frame, as in `f_vf_fluid`. The packed velocity (`inab`) lands before `pass` fires `adv` because `adv` in0 (the state) is the only hot inlet; this ordering cannot show on static inputs, so no bench covers it.
- **Reset on load.** A fresh load reseeds once after ~200 ms (φ std 0.78, fully separated by frame 40 at the defaults), so a new instance is never empty. `reset` reseeds with a new salt, so each press is a different pattern.
- **Bypass** does not use the native pix `@bypass`. It sets a gate on `enc` only: out0 goes mid grey and out1 the neutral vecfield. The solver keeps running underneath, so releasing bypass resumes from the accumulated pattern. Neutral outlets, not passthrough, were chosen because passing input A unmodified would need A at render size on `enc` (a fourth input).
- **Unconnected inputs.** In1 or in2 unconnected (or not a vecfield) reads as zero velocity, gated both by the `vs_inState` flag and by content (`|B − 0.5| < 0.25`), because the connected flag lags about 180 ms at load and disconnect. In0 unconnected means nothing is deposited.
- **Two instances** in one patch are independent (module bench).
- **Containment.** The state is clamped to ±1.25 (observed |φ| ≤ 1.03; a safety net), and `pass` reseeds NaN/Inf texels, so a bad value cannot persist in the loop.
- **Cost** (M3 Max, `bench_immiscible.py` slow test, `taps 2`): about 3.7 ms/frame at 1080p and 5.9 ms at 4K for this module alone (seven of eleven rows are bench-floor upper bounds, so the real figure is somewhat lower). The four-stage DFT chain is 2.06 ms, 56% of the total; `enc` dominates at 4K (2.76 ms). `taps 8` makes `inab` about three times dearer than 1–2. The slow cost test was not re-run after `pull`, `thresh` and `mix_pct` were added to the spec stage; the added operations are few. Two Fluids plus this module together were not measured.
- **Verification.** Tier 1 (NumPy mirror, 18 tests): mean conservation, linear-mode growth, `tanh` profile, free-energy descent, blend identities, threshold ramp, `pull` closed form, held-source settling, `Mix` identities; mutation-checked. Tier 2 on the GPU: stage bench 14/14 against the mirror (errors 1e-7 to 1e-6; the 100-frame chain drifts to 1.3e-3 pointwise by rounding, free energy agrees to 5.6e-6; growth rate 0.29814 vs analytic 0.29815), module bench 4/4 on the shipped patcher (fresh load seeded and neutral, once-per-frame update, vecfield blend and `Mix` exact, two instances independent), and the live contract run over 49 modules with 0 unexpected issues. Tier 3 (live look) by Matt 2026-10-28.
- See `docs/f-reference/f_vf_fluid.md` (the Fluids this pairs with, and the DFT chain this reuses), `docs/f-reference/f_vf_advect.md` (the consumer), `docs/f-reference/f_vecfield_type.md` for the vecfield contract, and `.specify/f_vf_immiscible/{spec,plan,tasks}.md` for the design record, the experiments and their pre-registered thresholds.

---

## References

The phase model is the Cahn–Hilliard equation for a conserved order parameter with a double-well free energy, advanced with a linearly stabilised semi-implicit step in Fourier space, as used for spectral phase-field solvers. The advection, the blend, the Mix bias, the mean `pull` and the injection ramp were derived in development. The stabiliser `a = 1.5`, the mobility law `0.1 · coarsen³`, the clamp and the reseed noise are tuned constants from this module's own experiments (`tests/records/spike_immiscible_constants.py`), not from a source. Citations below are given from memory and have not been re-checked against the originals.

- Cahn, J.W. & Hilliard, J.E. (1958). "Free Energy of a Nonuniform System. I. Interfacial Free Energy." J. Chem. Phys. 28, 258. The equation and the `tanh` interface profile it predicts (used as verification).
- Eyre, D.J. (1998). "Unconditionally Gradient Stable Time Marching the Cahn–Hilliard Equation." MRS Symp. Proc. 529, 39. The family of stabilised splittings the Fourier step belongs to; the version here was implemented from the equations and checked for energy descent, not copied.
- The Gibbs–Thomson dissolution of sub-critical droplets is standard Cahn–Hilliard behaviour, observed here in the T006 no-flow diagnosis.
