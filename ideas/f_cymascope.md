# f_cymascope — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Concept — not yet built_

## Concept

Wave propagation through a fluid medium — a computational model of the CymaScope instrument, which photographs sound passing through water in a shallow dish. Unlike `f_chladni` (modal superposition on a solid plate), this models the *continuous physics* of wave propagation: a source drives the medium, waves reflect off the dish boundary, interfere, and are damped by viscosity.

The visual character is organic and fluid rather than crisp and geometric — patterns emerge from propagation rather than being analytically computed.

## Physics Approach

Finite difference wave equation, iterated per frame in GLSL:

```
u[t+1] = 2*u[t] - u[t-1] + c² * laplacian(u[t]) - damping * u[t]
```

Where:
- `u` — wave amplitude field (ping-pong texture)
- `c` — wave speed (determines pattern scale relative to dish size)
- `damping` — energy loss per step (surface tension / viscosity approximation)
- `laplacian` — 2D spatial second derivative (5-point stencil)

A point source (or boundary driver) injects energy at a driven frequency.

## Planned Parameters

| Name | Type | Description |
|------|------|-------------|
| `frequency` | float | Driver frequency — determines pattern geometry |
| `amplitude` | float | Source drive amplitude |
| `damping` | float | Wave damping / viscosity |
| `wave_speed` | float | Propagation speed (scales pattern) |
| `source_x` | float | Driver position X (0=center) |
| `source_y` | float | Driver position Y (0=center) |
| `dish_shape` | float | Boundary geometry (circular → other) |
| `bypass` | toggle | Bypass |

## Signal Chain (Intended)

Audio input maps to driver frequency and amplitude — much simpler than f_chladni's 8-band model. A pitch tracker or FFT peak picker feeds one frequency; amplitude follows envelope.

```
mic → pitch tracker (fiddle~ or similar)
    → frequency param
mic → peakamp~
    → amplitude param
```

## Relationship to f_chladni

| | f_chladni | f_cymascope |
|---|---|---|
| Physics | Modal superposition | Wave propagation (FDTD) |
| Medium | Solid plate | Fluid (water) |
| Pattern origin | Bessel basis functions | Emergent from propagation |
| Visual character | Crisp, geometric | Organic, fluid |
| Signal input | 8 band amplitudes | 1 frequency + amplitude |
| GLSL approach | Analytic (per-pixel) | Iterative (ping-pong texture) |

## Open Questions

- Ping-pong texture approach in jit.gl.pix — confirm this is feasible in Vsynth context before committing to FDTD
- Boundary conditions: hard reflection vs absorbing edges vs periodic
- Whether `dish_shape` is worth building or circular is sufficient to start

## Source File

Not yet created.
