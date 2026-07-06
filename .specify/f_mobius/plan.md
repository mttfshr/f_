# Plan: f_mobius

_Last updated: 2026-05-26_

## Architectural Decisions

### ADR-1: Decomposed transformation paths
Use two separate computation paths blended by `invert`, rather than a general `(az+b)/(cz+d)` parameterization.
- **Identity path**: complex multiply by `e^(iθ) * scale` — rotation + zoom
- **Inversion path**: `1/z` (conjugate / |z|²)
- **Blend**: `mix(identity, inversion, invert)`

Rationale: performable parameter space; `invert` 0.2–0.8 produces loxodromic behavior as an emergent property of the blend rather than a derived parameter. A full Möbius parameterization would expose a, b, c, d directly — not performable.

### ADR-2: Singularity guard on denominator
Clamp `|z|²` before division: `max(dot(z, z), 0.0001)`.
- Keeps inversion numerically finite everywhere
- Near-pole pixels get a large but bounded warp, then wrap via `fract()`
- No NaN detection or conditional branching needed

Rejected: clamping UV output — produces visible stuck-band artifact at edges near pole.

### ADR-3: Edge wrap via fract()
Use `fract()` for repeat wrap, consistent with f_droste.
Spec said "mirror" — corrected to repeat after checking f_droste codebox.

### ADR-4: vec() constructor, 3-component sample
- Complex arithmetic: `vec(x, y)` for 2-component intermediates
- Sampling: `sample(in1, vec(x, y, 0))` — third component always 0
- No vec4(), no vec2() — matches gen codebox conventions

### ADR-5: Python build script for wrapper
6 params (cx, cy, rotate, zoom, invert, bypass) plus full signal chain warrants
a Python build script rather than hand-written JSON. Consistent with f_texrouter precedent.

---

## Implementation Phases

### Phase 0 — Codebox (verify math before building wrapper)
Write codebox, paste into scratch patch, verify all three acceptance criteria pass.
Singularity guard confirmed working at cx=0.5, cy=0.5, invert=1.

### Phase 1 — Bpatcher wrapper
Python build script → f_mobius.maxpat. All required objects per checklist.
Verify loads in Vsynth, bypass works, all params respond.

### Phase 2 — Performance validation
cx/cy via xy encoder confirmed. Zoom range tuned empirically.
Loxodromic territory (invert 0.2–0.8 + rotate) explored — findings noted in spec open questions.

### Phase 3 — Documentation
docs/f_mobius.md written. README updated.
