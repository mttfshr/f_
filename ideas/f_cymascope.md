# f_cymascope — Bpatcher Spec

_Last updated: 2026-06-07_
_Status: Concept — not yet built_

## Reframe (2026-06-07)

Originally conceived as a direct visualizer — FDTD wave simulation producing visual output. That framing has been superseded.

**f_cymascope is an audio-to-vecfield transducer.** Its primary output is a float32 f_vecfield texture encoding the gradient field ∇u of the wave amplitude, consumed by f_caustic (or any other vecfield consumer). The visual character — organic, fluid, caustic light bands forming along wave crests — emerges from the f_caustic consumer, not from direct rendering in f_cymascope itself.

This places f_cymascope in the same family as f_chladni, which is also an audio-to-vecfield transducer using modal superposition. The two patches are distinguished by physics model and audio interface:

| | f_chladni | f_cymascope |
|---|---|---|
| Physics | Modal superposition (Bessel basis) | Wave propagation (FDTD) |
| Medium | Solid plate | Fluid (water) |
| Field origin | Gradient of modal amplitude sum | Gradient of propagated wave amplitude u |
| Audio interface | 8-band filterbank → modal amplitudes | Pitch tracker + envelope → frequency + amplitude |
| GLSL approach | Analytic (per-pixel, stateless) | Iterative (ping-pong texture, temporal state) |
| Visual character via caustic | Crisp geometric nodal rings | Organic fluid wave patterns |

---

## Concept

FDTD wave propagation through a fluid medium — a computational model of the CymaScope instrument, which photographs sound passing through water in a shallow dish. A point source injects energy at a driven frequency; waves reflect off the dish boundary, interfere, and are damped by viscosity. The resulting amplitude field u is differentiated spatially to produce a gradient vector field ∇u, which encodes convergence at wave peaks and divergence at wave troughs. f_caustic accumulating along those streamlines produces bright bands at crests and dark valleys at troughs.

---

## Physics

Finite difference wave equation, iterated per frame:

```
u[t+1] = 2*u[t] - u[t-1] + c² * laplacian(u[t]) - damping * u[t]
```

Where:
- `u` — wave amplitude field (ping-pong texture, temporal state across frames)
- `c` — wave speed (determines pattern scale relative to dish size)
- `damping` — energy loss per step (surface tension / viscosity approximation)
- `laplacian` — 2D spatial second derivative (5-point stencil)

**Vecfield output:** encode ∇u as f_vecfield float32 texture (RG = XY gradient, 0.5 = zero).

---

## Audio Interface

Simpler than f_chladni — one frequency drives the pattern geometry, one amplitude drives energy injection:

```
mic → pitch tracker (fiddle~ or similar) → frequency param
mic → peakamp~ → amplitude param
```

---

## Planned Parameters

| Name | Type | Description |
|------|------|-------------|
| `frequency` | float | Driver frequency — determines pattern geometry |
| `amplitude` | float | Source drive amplitude |
| `damping` | float | Wave damping / viscosity |
| `wave_speed` | float | Propagation speed (scales pattern) |
| `source_x` | float | Driver position X |
| `source_y` | float | Driver position Y |
| `bypass` | toggle | Bypass |

---

## Open Questions

- **Ping-pong texture architecture:** FDTD requires u[t-1] to compute u[t+1] — frame-to-frame temporal state. This almost certainly requires explicit ping-pong texture management rather than a simple jit.gl.pix codebox. Investigate vs_chemical_osc architecture (Kevin uses chained pix objects for temporal state) before committing to implementation approach. This is the primary architectural risk.
- **Boundary conditions:** hard reflection vs absorbing edges vs periodic. Hard reflection is simplest and physically closest to a dish.
- **dish_shape param:** circular boundary sufficient to start; morphing to other shapes deferred.
- **Gradient encoding:** ∇u computed via finite differences in the codebox; magnitude needs normalization to use full 0–1 vecfield range meaningfully.

---

## Relationship to f_chladni

f_chladni should also be understood as a vecfield producer (gradient of modal amplitude field → f_vecfield). Both patches sit in the same conceptual slot in the signal chain:

```
audio → [f_chladni | f_cymascope] → f_vecfield → f_caustic → visual output
```

f_chladni is stateless (analytic per-pixel); f_cymascope requires temporal state (FDTD). This makes cymascope significantly more complex to implement — build f_chladni vecfield output first as the simpler proof of concept.

---

## Source File

Not yet created.
