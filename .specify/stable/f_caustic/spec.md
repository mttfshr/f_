# Spec: f_caustic

_Created: 2026-06-07_
_Status: Draft_

---

## What it does

An optical caustic processor. Takes an image (the light source) and a vector field
(the refracting medium) and redistributes the image's brightness according to the
field's convergence and divergence structure. Bright bands accumulate where the field
converges (negative divergence); relative darkening occurs where it diverges.

**Consumer in the f_vecfield family.** The vector field inlet is structurally required
— f_caustic's core operation (streamline accumulation weighted by local convergence)
requires a coherent two-channel field. Patching a non-field texture into in2 will
produce output but not meaningful caustic structure.

**Processor archetype.** in1 is the light source image. out1 composites the caustic
additively over that source. out2 is the isolated caustic layer.

---

## Shader Architecture

Additive streamline accumulation — distinct from UV displacement (f_lens) underneath.

At each output pixel:

1. Decode the vector field at the current pixel: `field = (sample(in2, uv) - 0.5) * 2.0`
2. Trace a short streamline *backward* through the field — step opposite to field
   direction for N fixed steps, each of length `step_size` (derived from `scale`)
3. At each step position along the streamline, sample the source texture (in1)
4. Compute local divergence at each step via finite differences on the field:
   `div = dFx/dx + dFy/dy` (approximated with small UV offsets `h`)
5. Weight each sample's contribution by `max(-div, 0.0)` — only convergence zones
   accumulate brightness; divergence zones contribute nothing
6. Sum weighted samples, multiply by `intensity`
7. Apply chromatic dispersion: sample R, G, B channels with slightly offset step sizes
   (controlled by `color_shift`) to produce hue variation in bright bands
8. Apply `softness` — smoothstep on the per-pixel accumulation total to control
   band sharpness
9. out2 = accumulated caustic (pre-composite)
10. out1 = additive composite: `clamp(source + caustic, 0, 1)`, bypass-respecting

**Step count:** fixed compile-time constant (8 steps). Not a runtime parameter.
Higher step counts produce richer banding at higher GPU cost; 8 is the working
default. Adjust in codebox if performance requires it.

**Finite difference offset `h`:** fixed at `1.0 / 512.0` normalized — a half-pixel
at 1024 resolution. Divergence quality scales with field texture resolution.

**Backward tracing rationale:** forward tracing accumulates at the *destination* of
streamlines, which is geometrically correct but requires knowing where streamlines
end up — impossible per-pixel without iteration from source. Backward tracing finds
which source regions would have contributed light to the current pixel given the
field, which is the correct per-pixel accumulation framing.

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | bang + control | — | Vsynth standard. Control messages route to params. |
| 1 | texture (required) | light src | Source image. Bright regions are where light originates. |
| 2 | texture (required) | vec field | f_vecfield output. Describes convergence/divergence structure. No fallback — unconnected produces flat output. |

in2 has no vs_inState / vs_black fallback. Unconnected = zero field = zero caustic
accumulation = passthrough source on out1, black on out2. This is the correct
behavior: an unconnected field inlet should be silent, not produce a misleading
radial caustic.

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `mix` | live.numbox | 0.0–100.0% | 0.0 | Dry/wet crossfade — `composited = mix(source_pass, composite, mix_pct/100.0)`. Renamed from `strength` 2026-07-12 (library-wide `gain`/`mix` naming convention, vsynth-bpatcher skill); range capped to true 0–100% (dropping the old 0–1.5 extrapolation zone). Internal codebox `Param` is `mix_pct` (external label/attr/varname stay `mix`) to avoid colliding with the codebox's own `mix()` operator. Default kept at 0 (off by default, matching this module's original load behavior — not 100 like `f_vf_prism`/`f_vf_advect`'s convention; Matt's explicit call 2026-07-12) |
| `gain` | live.dial | 0.0–2.0 | 0.5 | Overall caustic brightness scale. Renamed from `intensity` 2026-07-12 to match the library-wide naming convention — same math, name only |
| `scale` | live.dial | 0.0–1.0 | 0.3 | Streamline trace distance. 0 = no trace (no caustic). 1 = full-frame trace. |
| `softness` | live.dial | 0.0–1.0 | 0.3 | Band sharpness. 0 = hard bright lines. 1 = diffuse glow. |
| `color_shift` | live.dial | 0.0–1.0 | 0.0 | Chromatic dispersion. 0 = monochrome bands. >0 = warm/cool hue split across bands. |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Bypass — out1 passes source unmodified, out2 is black. |

**Prefix:** `caustic`
**Object name:** `caustic_pix`
**Type:** `@type float32` (overrides the processor-convention default of `char` — accumulation benefits from float32 headroom, decided in scratch validation; confirmed against `definition.py`'s `pix_type` field 2026-07-11)

---

## Outlets

| Outlet | Label | Description |
|---|---|---|
| out1 | composited | Caustic additively composited over source. Bypass-respecting. |
| out2 | caustic layer | Isolated caustic accumulation. Pre-composite. Black when bypass active. |

Matches the f_grain two-outlet pattern: out1 = integrated result, out2 = isolated
effect layer for downstream flexibility.

---

## Signal Flow

```
in0 (bang + control) → routepass jit_gl_texture jit_matrix
  routepass unmatched → route <params> → live.dials → prepend param <name> → caustic_pix in0

in1 (light source) → routepass jit_gl_texture jit_matrix → vs_inState → caustic_pix in1
in2 (vec field)    → routepass jit_gl_texture jit_matrix → caustic_pix in2
  (no vs_inState on in2 — zero field = silent, not fallback)

caustic_pix out1 → out1 (composited)
caustic_pix out2 → out2 (caustic layer)
```

---

## Compositing

out1 is additive: `clamp(source.rgb + caustic.rgb, 0.0, 1.0)`. Alpha passes from
source unchanged. Caustic brightness is always additive — it adds light, never
subtracts it. Darkening at divergence zones is achieved by the absence of
accumulation there, not by subtraction.

---

## Relationship to f_grain

Both use the two-outlet pattern (composited / isolated layer). Both are additive
processors. f_grain scatters grain over the source; f_caustic redistributes the
source's own brightness. The outlet convention is the same; the compositing math
is the same.

---

## Relationship to f_lens

| | f_lens | f_caustic |
|---|---|---|
| Primary operation | UV warp | Additive accumulation |
| Vector field use | Distortion direction | Convergence/divergence weighting |
| Effect on image | Spatial displacement | Brightness redistribution |
| Physical analog | Light bending through glass | Light focusing onto surface |
| Requires coherent field? | For spatially-varying character | Yes — structurally required |

When f_caustic and f_lens both read the same f_vortex output: aberration (f_lens)
is strongest where the field has high magnitude; caustic bright bands (f_caustic)
appear where the field has negative divergence. Both effects are consequences of
the same field geometry — coherent optical character without parameter coordination.

---

## Acceptance Criteria

- f_vortex (sink topology, defaults) → in2: bright caustic ring visible at convergence
  zone around fixed point. out1 shows source with bright overlay. out2 shows isolated
  ring.
- `scale = 0`: no streamline trace, no accumulation, out1 = source passthrough, out2 = black.
- `gain = 0`: caustic present structurally but invisible (multiplied out). out1 = source.
- `softness = 0`: hard bright lines at convergence zone boundaries.
- `softness = 1`: diffuse glow, no hard edges.
- `color_shift = 0`: monochrome caustic bands.
- `color_shift > 0`: visible warm/cool split across band edges.
- f_vortex (source topology, convergence < 0): divergence field → no accumulation
  → out1 = near-passthrough, out2 = near-black. (Diverging field produces no caustics —
  physically correct.)
- Bypass: out1 = source unmodified, out2 = black.
- in2 unconnected: out1 = source passthrough, out2 = black. No misleading radial caustic.
- Loads in Vsynth. Accepts output from f_vortex on in2 without type errors.

---

## Decisions (closed in scratch validation 2026-06-06)

- **`@type float32`:** accumulation benefits from float32 headroom. Processor convention (char) overridden. Use `@type float32`.
- **`scale` upper bound:** calibrated in scratch validation — range feels correct across 0–1. No change.
- **out2 range:** clamped to 0–1 in codebox. Keep clamp.
- **Divergence sign convention:** confirmed — f_vortex sink topology produces negative divergence at fixed point, which produces bright bands. Correct.

---

## Clarifications

### Session 2026-06-07

- Q: Inline radial fallback for unconnected in2? → A: No. Unconnected = silent (zero field, zero caustic). Misleading fallback rejected.
- Q: in3 surface texture at launch? → A: Deferred. Not in v1.
- Q: Step count as runtime param? → A: No. Fixed compile-time constant, documented here.
- Q: color_shift at launch? → A: Yes, included.
- Q: Outlet pattern? → A: Two outlets matching f_grain: out1 = composited, out2 = isolated caustic layer.
- Q: Compositing mode? → A: Additive over source on out1. out2 is pre-composite isolated layer.

---

## Reframe (2026-07-11): bug fix + gain/wet naming pass (findings 1–3)

### Bug fix (prerequisite to everything below)

`definition.py` was pointing at `codebox_v3.gen`, a stray earlier draft
(self-labeled `v1` internally, single-inlet, no `strength`) instead of
`codebox_v2.gen`, which has the correct two-inlet structure and the
`strength` crossfade this section originally failed to document at all.
Fixed: `codebox_v3.gen` deleted, `definition.py` now points at
`codebox_v2.gen`. Full account in `plan.md`'s bug-fix ADR and
`docs/f-reference/f_caustic.md`'s resolved discrepancy note. **This means
whatever `f_caustic.maxpat` currently exists on disk may have been built
from the broken file — rebuild and re-verify in Max before trusting
existing behavior.**

### Findings 1–3 status

Unlike every other module in this rollout so far, `f_caustic` doesn't
need new gain/wet architecture — `codebox_v2.gen` already has it:

```
composited = mix(source_pass, composite, strength);   // already a literal crossfade
```

`intensity` already functions as the gain-equivalent (scales
`caustic_r/g/b` before the additive layer is formed), and `strength`
already functions as the wet-equivalent (blends that layer against
clean source, bounded 0–1.5). This is the same shape `f_vf_advect`
turned out to already have — this rollout's findings 1–3 aren't always
new work; sometimes they're a naming/UI pass on an already-correct
architecture.

### Decision (resolved, and later renamed 2026-07-12)

- Rename `strength` → `mix`, **cap range at true 0–100%** (dropping the
  1.0–1.5 extrapolation zone) — matches the crossfader framing finding 2
  wants, rather than keeping the linear-extrapolation-past-composite
  behavior the old 0–1.5 range allowed. (Originally decided as a rename
  to `wet`; superseded 2026-07-12 by the library-wide canonical naming
  decision — `mix` is the one and only name for this role everywhere,
  never `wet`/`strength`/`blend`. See `vsynth-bpatcher/SKILL.md`'s
  "Canonical naming: `gain` vs `mix`" section.)
- Rename `intensity` → `gain` (not `wet`'s counterpart `gain` from the
  original ADR wording — same rename, same rationale, just also now the
  one canonical name for this role library-wide), keep its existing
  0–2.0 range and 0.5 default — it already functions as the gain-
  equivalent (scales `caustic_r/g/b` before the additive layer forms)
- `live.numbox` widget for `mix` (confirmed against `vsynth-bpatcher/SKILL.md`'s
  established convention) — internal `Param mix_pct` to dodge the
  `mix()` operator collision, external label/attr/varname stay `mix`
- Outlet comment: kept as `composite` — **not** renamed to `mix`,
  correcting the original ADR's plan. `f_vf_prism`'s own shipped module
  (the precedent this rollout is following) also kept its outlet
  comment as `composite`, never renamed it — the outlet-rename half of
  the original finding 3 never actually happened in practice for any
  module in this rollout, so `f_caustic` matches real precedent by not
  doing it either.

### Acceptance criteria (addition, done 2026-07-12)

- `mix=0` → out1 (composite) is clean source regardless of `gain` — ✓
  (matches original default-off load behavior)
- `mix=100` → matches the old `strength=1.0` behavior exactly — ✓
  (same formula, just renamed and rescaled from 0–1.5 dial to 0–100
  numbox)
- No change to out2 (caustic, isolated layer) — ✓
- Bypass behavior unchanged — ✓
- Rebuild verified via `build_patcher.py`; diff against pre-rename
  `.maxpat` showed only the expected renames (`route` message list,
  `attr`/`varname`/`parameter_longname`/`parameter_shortname`, widget
  class `live.dial`→`live.numbox` for `mix`, label text) — no
  unintended structural changes
