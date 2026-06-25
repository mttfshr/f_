# HANDOFF — f_ library

Last session: 2026-06-25

## What just happened

### f_weave — COMPLETE, registered
New generator: continuous line-mark texture. Distance field marks (droste-compatible),
per-line phase hash (regularity param), optional vecfield in1 for orientation steering.
Params: density, angle, weight, marklen, regularity, phase.

Key architectural finding: band_idx-as-grid-identity is a masonry concern. Weave uses
continuous fract-based distance fields — no slot structure, no Euclidean rhythm.

Vecfield inlet steers line orientation via basis vector perturbation (not atan2 — avoids
discontinuity). Works best at moderate field strength; strong fields produce
interference patterns (physical, not artifact).

### f_vf_prism desaturation — FIXED, committed
Bug: luma gate used for all three channels → B&W output.
Fix: three per-channel gate functions (channel_gate_r/g/b) each sampling .x/.y/.z
respectively. Full color preserved. Chromatic dispersion now correct.
Codebox: codebox_v15.gen

### build_patcher.py source archetype fix
Source archetype now generates `r draw` as outer patcher object wired to pix inlet 0.
Previously was using `r dim` inside gen (wrong). Fix applies to both no-mod-inlet and
mod-inlet source variants.

## What's next

1. **f_vf_potential** — scalar potential field integrator (ping-pong, like f_vf_advect).
   Enables isoline-based weave character (fingerprint/contour). Spec captured in
   ideas/scratchpad.md. Natural next module.

2. **f_weave v2** — `across` inlet for external potential field. Enables
   `f_vf_vortex → f_vf_potential → f_weave` isoline chain.

3. **Write help file** for f_vf_prism (f-helpfile skill)

4. **Audit in1/in2 bug** — check f_vf_warp, f_vf_streak, f_vf_glow, f_vf_advect
   for same inlet mixup found in f_caustic

## Known issues / loose threads

- f_masonry square output at non-square render dimensions still unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- text_button param type only reliably supports two options
- `rename strength → amount` across modules still parked
- f_weave: vecfield at high field strength produces interference (physical behavior,
  not bug — document as expected)
- f_weave: isoline character (fingerprint/contour) requires f_vf_potential (future)

## Key learnings this session

- **`r draw` not `r dim`** — source archetype render trigger is `r draw` wired to
  pix inlet 0 in outer patcher. `r dim` inside gen does not self-trigger. Fixed in
  build_patcher.py.

- **Continuous distance fields vs grid identity** — fract-based mark placement needs
  no band/slot structure. `line_idx` used only as hash seed, never as grid identity.
  This is the key distinction from f_masonry architecture.

- **Vecfield orientation via basis perturbation** — adding vecfield XY to cos/sin
  rotation basis (with normalization) avoids atan2 discontinuity. Works for any
  vecfield type, not just vortex.

- **Isoline weave requires scalar potential field** — per-pixel orientation rotation
  aliases at density > 1. True curved lines need isolines of integrated field.
  f_vf_potential (ping-pong) is the correct architecture.

- **f_vf_prism per-channel gate** — gate function must sample the corresponding
  color channel (.x for R gate, .y for G gate, .z for B gate). Luma gate produces
  desaturation. Per-channel gates produce color-correct chromatic dispersion.
