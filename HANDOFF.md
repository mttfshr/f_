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

### f_vf_potential — scratch patch experiment IN PROGRESS
Explored a scalar potential field integrator using ping-pong feedback (same pattern
as f_vf_advect). The experiment is working — the potential_pix produces a smooth
scalar gradient field whose level sets correspond to the repulse field structure.

**Scratch patch location:** `~/Vsynth/patterns/f_vf_potential_scratch.maxpat`

**Current state of scratch patch:**
- `potential_pix` — jit.gl.pix with codebox below, 3 inlets
- `pass_pix` — identity pix @adapt 1, holds previous frame
- Feedback loop: potential_pix out0 → pass_pix in0 → potential_pix in1 (prev frame)
- f_vf_repulse → potential_pix in0 (vecfield source)
- Two waveform generators driving repulse source texture (X and Y)
- params: dt=0.01, decay=0.98, src_vecfield=1.0

**Current codebox in potential_pix:**
```
Param dt(0.01);
Param decay(0.99);
Param src_vecfield(0.0);

uv = norm;

fx = (sample(in1, uv).x - 0.5) * 2.0;
fy = (sample(in1, uv).y - 0.5) * 2.0;

connected = step(0.5, src_vecfield);
fx = fx * connected;
fy = fy * connected;

field_mag = sqrt(fx * fx + fy * fy);

src_uv = vec(clamp(uv.x - fx * dt, 0.0, 1.0), clamp(uv.y - fy * dt, 0.0, 1.0));

prev = sample(in2, src_uv).x;
potential = clamp(prev * decay + field_mag * dt, 0.0, 1.0);

_dummy = sample(in3, uv).x;

out1 = vec(potential, potential, potential, 1.0);
```

**Key finding from experiment:**
The potential field works and produces smooth scalar gradients whose level sets
correspond to the repulse field structure. However, feeding it into f_weave's
existing vecfield inlet doesn't work correctly — the vecfield inlet expects float32
RG (XY direction vectors), but the potential is a scalar (same value in R/G/B).
F_weave reads R as X and G as Y direction, getting equal vx/vy at every pixel →
always 45° perturbation, unrelated to field structure.

**Two ideas captured along the way:**
- f_vf_lic (Line Integral Convolution streamlines) — captured in scratchpad.md
- f_vf_potential — captured in scratchpad.md

## What's next — immediate

### 1. f_weave v2: scalar `across` inlet (highest priority)

F_weave needs a dedicated scalar inlet that bypasses the internal `across` computation.
When connected, replace:
```
across = norm.x * cs + norm.y * sn;
```
with:
```
across = sample(in_potential, norm).x * density_scale;
```

This means the potential field drives the isoline structure directly. The signal chain
becomes:
```
f_vf_repulse → potential_pix → f_weave scalar inlet
```

Implementation plan:
- Add a second mod_inlet to f_weave definition.py (float32 scalar, no vs_inState
  needed since zero input = zero across = valid neutral state)
- Add `src_potential` internal param driven by vs_inState
- In codebox: if src_potential connected, use sampled potential for across;
  otherwise use existing rotation-based across
- Rebuild and test

### 2. f_vf_potential — spec and build as proper module

Once f_weave scalar inlet is confirmed working in scratch patch, build f_vf_potential
as a proper registered module. Architecture is confirmed from scratch patch experiment.

Definition will be similar to f_vf_advect (pix_chain with pass + compute pix).
Output: float32 scalar (greyscale). Not a vecfield — a scalar potential field.

Params needed:
- dt — accumulation step size per frame
- decay — how quickly old accumulation fades (controls tracking speed vs stability)
- strength — output scale

### 3. f_vf_lic (lower priority, separate track)
Streamline renderer — lines parallel to field direction, weather map character.
Different from f_vf_potential (isolines perpendicular to field).
Captured in scratchpad.md. Not blocking anything.

## Uncommitted work

The following need commits before next session:
```
git add .specify/f_weave/ patchers/f_weave.maxpat
git add .specify/f_vf_prism/codebox_v15.gen .specify/f_vf_prism/definition.py patchers/f_vf_prism.maxpat
git add javascript/f_addmod.js .specify/f_modules/build_modules.py patchers/f_modules.maxpat
git add tools/build_patcher.py
git add ideas/scratchpad.md
```

Suggested commit messages:
```
# 1. Planning docs
git add .specify/f_weave/
git commit -m "plan: f_weave spec, plan, and tasks"

# 2. f_weave patcher
git add patchers/f_weave.maxpat .specify/f_weave/definition.py
git commit -m "feat: add f_weave generator — continuous line-mark texture"

# 3. f_vf_prism fix
git add .specify/f_vf_prism/codebox_v15.gen .specify/f_vf_prism/definition.py patchers/f_vf_prism.maxpat
git commit -m "fix: f_vf_prism desaturation — per-channel gate sampling"

# 4. Registration + build fix
git add javascript/f_addmod.js .specify/f_modules/build_modules.py patchers/f_modules.maxpat tools/build_patcher.py
git commit -m "feat: register f_weave; fix build_patcher.py source archetype r draw"

# 5. Ideas
git add ideas/scratchpad.md
git commit -m "docs: capture f_vf_potential and f_vf_lic ideas"
```

## Known issues / loose threads

- f_masonry square output at non-square render dimensions still unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- text_button param type only reliably supports two options
- `rename strength → amount` across modules still parked
- f_weave: vecfield at high field strength produces interference (physical, not bug)
- f_weave: isoline character requires scalar potential inlet (v2, next session)

## Key learnings this session

- **`r draw` not `r dim`** — source archetype render trigger is `r draw` wired to
  pix inlet 0 in outer patcher. Fixed in build_patcher.py.

- **Continuous distance fields vs grid identity** — fract-based mark placement needs
  no band/slot structure. line_idx used only as hash seed, never as grid identity.

- **Vecfield orientation via basis perturbation** — adding vecfield XY to cos/sin
  rotation basis (with normalization) avoids atan2 discontinuity.

- **Isoline weave requires scalar potential field** — per-pixel orientation rotation
  aliases at density > 1. True curved lines need isolines of integrated field.
  f_vf_potential (ping-pong) is confirmed working architecture.

- **Scalar potential ≠ vecfield** — the potential output is a scalar (greyscale),
  not a vecfield (RG). F_weave needs a dedicated scalar inlet, not the vecfield
  inlet, to use it correctly.

- **f_vf_prism per-channel gate** — gate function must sample the corresponding
  color channel (.x for R, .y for G, .z for B). Luma gate → desaturation.
