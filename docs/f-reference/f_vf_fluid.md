# f_vf_fluid

**Type:** Processor (f_vecfield in → f_vecfield out) — **temporal / has memory**
**Status:** Complete

---

## What it does

A spectral (FFT) incompressible-flow **velocity solver**. A force vecfield goes in; an evolving velocity vecfield comes out. Each frame the flow carries itself along (self-advection), takes in the force, is made divergence-free, and is damped by viscosity and drag. The result is a persistent, swirling field that keeps moving after the force that stirred it has gone — the property `f_vf_advect` and the stateless field consumers do not have on their own.

It does **not** move any texture. Dye and image transport are left to the consumers: feed Fluid's outlet to the vecfield inlet of `f_vf_advect`, `f_vf_warp`, `f_vf_glow`, `f_vf_streak` and friends.

Typical use: a force producer (`f_vf_optical_flow` on video is the most expressive; `f_vf_vortex`, `f_vf_flow` and `f_vf_repulse` are cleaner) → `f_vf_fluid` → one or more consumers.

The solver is a fixed 256×256 grid regardless of render size, on a periodic unit square. Only the final encode stage follows the render resolution, so the outlet is always a normal render-size f_vecfield.

---

## Signal Flow

```
inlet 0 (force vecfield / control) → routepass
  texture → vs_inState
    vs_inState out0 (force texture or vs_black) → adv in1, enc in1
    vs_inState out1 (0/1)                       → prepend param src_vecfield → adv, enc
  unmatched → route force dt viscosity project drag gain taps → dials → prepend param <name> → stage(s)

r draw → adv in0            (advances the solver exactly once per frame)
r draw → enc in0            (gives enc the render-context size, never 1×1)

pass → adv (in2) → fx → fy → spec → iy → ix → pass            (feedback, one-frame latency)
                                              ix → enc (in2) → outlet 0
bypass jsui → prepend param bypass_gate → enc
```

One inlet, one outlet. Unlike the two-inlet consumers, the force arrives on the same inlet as the control messages.

### Stages

| # | Node (`#0_fluid_…`) | Does | Size |
|---|---|---|---|
| 0 | `pass` | identity; holds last frame's velocity | 256² |
| 1 | `adv` | backward self-advection (periodic 4-tap bilinear) + `force · F`; runs every frame even with no force | 256² |
| 2–3 | `fx`, `fy` | forward DFT along x, then y | 256² |
| 4 | `spec` | projection blend, then viscosity and drag decay, per Fourier bin | 256² |
| 5–6 | `iy`, `ix` | inverse DFT along y, then x; `ix` keeps the real part and clears NaN/Inf | 256² |
| 7 | `enc` | periodic 4-tap upsample, `gain`, clamp, encode, bypass gate | render res |

Solver stages are `@adapt 0 @dim 256 256 @type float32`. The four DFT codeboxes are baked from one template (`gen_dft.py`).

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `force` | 0–0.2 | 0.02 | Velocity gained per frame from the force input at full scale. |
| `dt` | 0–0.05 | 0.01 | Speed: the self-advection step, and the time step of drag. Does not change smoothing. |
| `viscosity` | 0–1 | 0.085 | Smoothing dial, independent of `dt`. 0 = off, high = honey (only the biggest swirls survive). Per-frame ν·dt = 1.6e-3·v³, so most of the useful range is in the lower half. |
| `project` | 0–1 | 1 | 0 = compressible (shock fronts), 1 = divergence-free swirl. |
| `drag` | 0–5 | 0.5 | Linear damping. Keeps sustained or uniform force bounded. |
| `gain` | 0–10 | 1.0 | Output scale on the velocity before encoding (clamped to the vecfield range). |
| `taps` | 1–16 | 8 | Force filter: `taps × taps` samples per solver texel. Control message only — no panel slot. |
| `src_vecfield` | internal | — | Driven by `vs_inState` (1 = force inlet connected). Not user-facing. |
| `bypass_gate` | internal | — | Driven by the bypass jsui, not by the route. Not user-facing. |
| `bypass` | 0/1 | 0 | See Notes: gates the output only; the solver keeps running. |

**Prefix:** `vffluid` — **Object names:** `#0_fluid_pass`, `_adv`, `_fx`, `_fy`, `_spec`, `_iy`, `_ix`, `_enc`

Defaults were judged by eye in Vsynth (2026-09-29) and left as built. The ranges were not judged separately.

---

## Algorithm

```
force_xy  = (sample(force, uv, box-filtered by taps) - 0.5) * 2 * gate     // gate: connected AND real vecfield
u_adv     = sample_periodic(u, x - u * dt) + force * force_xy               // backward self-advection

û         = FFT(u_adv)
û_p       = û - k (k·û) / |k|²                                              // Helmholtz projection, Nyquist zeroed in k
û         = mix(û, û_p, project)
û         = û * exp(-(nu_dt * |k|² + drag * dt))                            // nu_dt = 1.6e-3 * viscosity³
u         = Re(IFFT(û))                                                     // NaN/Inf → 0

out       = 0.5 + 0.5 * clamp(gain * u)                                     // encoded, B = 0.5, A = 1
```

Domain: periodic unit square, wavevector `k = 2π · signed_index`. Velocity is in decoded f_vecfield field units; displacement per frame is `u · dt`, the same meaning as `f_vf_advect`'s `dt`.

---

## Notes

- **Periodic domain.** Flow leaving one edge re-enters at the opposite edge. There are no boundaries.
- **Fixed 256² solver.** Independent of render size. The force, which arrives at render resolution, is minified into the solver grid by a `taps × taps` box of samples. A single tap would alias a noisy force badly at HD and 4K (about 6× and 11.6× the noise of an area average); the default 8 brings that to about 1× and 1.4×. `taps = 1` restores the single-tap read. Smooth forces are unaffected.
- **`project`.** It removes the compressive (curl-free) part of the velocity, so it can only make a difference where there is compressive flow. On a force that is already rotational — a vortex with convergence 0, a uniform `f_vf_flow`, mostly rigid video motion — 0 and 1 are expected to look the same, and were not distinguishable by eye on the force tried during tuning. A compressive force such as `f_vf_repulse`, or a vortex with convergence, should show the difference; that case was not tested.
- **Bypass** does not use the native pix `@bypass`. It sets a gate on `enc` only: a connected inlet passes the force through unmodified, an unconnected one passes a neutral field. The solver keeps running underneath, so releasing bypass resumes from the accumulated flow. It follows that toggling bypass does not tell you the solver's cost.
- **Unconnected or disconnected force.** The solver keeps running and the existing flow coasts down at the drag rate. The force is also gated by content (a real f_vecfield has B = 0.5, `vs_black` has B = 0), because `vs_black` decodes to −1 and the connected flag lags about 180 ms at load and disconnect. Without the gate the solver injected a phantom −1 force for the first frames after load.
- **Outlet size** is the render-context size whether or not the inlet is connected, because `enc` is triggered by `r draw` and not by the incoming texture.
- **Cost.** At 256² on the bench (`enc` at 1280×720), about 2.4–2.8 ms per frame at `taps 1`; 2.49 ms measured at the default `taps 8`. Budget was 3 ms. The four DFT passes are most of it (about 0.5–0.65 ms each); `adv` is 0.36–0.7 ms at `taps 8` and about 1.2–1.7 ms at `taps 16`, which is why 8 is the default. Figures vary run to run with GPU state. In a real patch at 3840×2160, Fluid plus one consumer chain held 59–60 fps; four parallel consumer chains ran about 42 fps, so the overrun came from the extra consumers. 59–60 fps is the vsync ceiling, so the real margin is not measured.
- **Containment.** `ix` discards the numerical imaginary residue every frame and replaces non-finite values with 0 (`abs(x) < 1e30` — `x == x` does not work on this GPU), so a NaN cannot persist in the feedback loop. `enc` clamps to [0, 1].
- **Verification** (as of 2026-09-28): a NumPy mirror of every stage is checked against independent physics (single-mode decay, Taylor–Green vortex decay 0.85% off analytic at frame 100, divergence-free after projection, Nyquist and Hermitian symmetry, no NaN over 10⁴ frames at extremes), and each real codebox is checked on the GPU against the mirror, including a 100-frame host-sequenced run within 3e-6. The 10-minute in-Vsynth soak was not run.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract, `docs/f-reference/f_vf_advect.md` for the consumer this pairs with, and `.specify/f_vf_fluid/{spec,plan,tasks}.md` for the design record and findings.
