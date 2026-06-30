# f_vf_advect

_Status: Built — 2026-06-09._

## Concept

Temporal fluid advection. Each frame, transports pixel values backwards along the vector field — `color[t] = sample(previous_frame, uv - field * dt) * decay + source * injection`. With feedback this accumulates into genuine flow: content injected into the field spreads, advects, and dissipates over many frames.

Visually distinct from f_vf_streak and f_vf_warp: those are stateless single-pass effects. Advection has memory — things actually flow through the field over time.

## Architecture

Two chained jit.gl.pix (Pattern 1 from `docs/max-reference/temporal_synthesis_architecture.md`): `pass_pix` holds the previous frame as a stable texture reference; `advect_pix` reads source, vecfield, and previous frame to compute the new advected state. The GL pipeline's one-frame latency makes the loop stable without explicit buffer management.

## Key expressive findings

- **Fluid zone:** dt 0.005–0.02, decay 0.95–0.99, injection 0.01–0.03. Content disappears into the flow and accumulates along streamlines.
- **Displacement zone:** higher injection (0.05+) gives streak/warp character — source is visible every frame.
- **Excitable fluid (decay > 1.0):** content amplifies rather than decays; regions of field convergence saturate to white. Qualitatively different operating mode, not just a range extension.
- **Best sources:** f_grain, f_stipple, f_caustic — isotropic texture gives maximum flow legibility.
- **Best fields:** f_vf_fieldmap (organic, non-repeating), f_vf_vortex_multi (structured curl).
- **Self-advection:** output → input with a different field produces strange accumulation behavior worth exploring.
