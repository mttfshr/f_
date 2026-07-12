# Spec: f_vf_warp

_Created: 2026-06-07_
_Revised: 2026-06-07_
_Status: Revised — architecture clarified_

---

## What it does

A vecfield-based UV warp processor for Vsynth. Takes a source texture and a vector field (as a float32 RG f_vecfield texture), and displaces each pixel's UV coordinates based on the XY vector sampled from the field at that location.

**Two outlets** — corrected 2026-07-11 against actual `definition.py`; this doc previously described a single-outlet design that no longer matches shipped code:
- **out1 (composite)**: `mix(warped, source, bypass)` — the warped result, or source when bypassed. Note this is *not* currently a wet/dry blend of warped-vs-source the way `f_mobius`/`f_droste`/`f_lens` are — `strength=0` degenerates the warp to zero offset (visually equivalent to passthrough), but there's no independent blend control separate from the warp depth itself. This module is the replacement-type shape in finding 1's classification (out2 is a full remapped image, not an additive layer) but doesn't yet have the crossfader that shape calls for — see this doc's 2026-07-11 reframe.
- **out2 (warped)**: the warped sample, unconditionally (not bypass-gated, not blended) — a genuine second outlet, not documented anywhere in the original version of this spec

**Consumer in the f_vecfield family.** Expects a valid f_vecfield texture in the vecfield inlet. Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, etc.

**Pure Processor archetype.** Requires an upstream source texture on in0. The vecfield inlet is optional — if unconnected, output passes through unwarped. Bypass passes the source texture through unmodified.

---

## Warp Algorithm

At each pixel:

1. Sample the vecfield texture at the current UV coordinates
2. Remap the XY vector from [0, 1] to [-1, 1] (f_vecfield convention: 0.5 = zero vector)
3. Scale by `strength` parameter
4. Add the scaled offset to the current UV
5. Sample the source texture at the displaced UV (clamp to edge)
6. Output the result

Codebox pseudocode:

```glsl
Param strength(0.1);
Param src_vecfield(0.0);   // system param: 0 = no field connected, 1 = connected
Param bypass(0.0);

vec2 uv = norm;
vec2 field = sample(in2, uv).rg;
vec2 raw_offset = (field - 0.5) * 2.0 * strength;

// When no vecfield is connected, in2 delivers vs_black (all zeros),
// which would produce a constant offset of -strength. We suppress this
// via src_vecfield state: offset is zeroed when inlet is unconnected.
vec2 offset = mix(vec(0.0, 0.0), raw_offset, step(0.5, src_vecfield));

vec2 warpedUV = clamp(uv + offset, 0.0, 1.0);
vec4 warped = sample(in1, warpedUV);
warped.a = 1.0;

out1 = mix(warped, sample(in1, uv), bypass);
out2 = warped;  // unconditional — not bypass-gated (see note below); added at some point after this spec was originally written, never documented until 2026-07-11
```

**Note on out2's actual bypass behavior**: `definition.py`'s codebox has
`out2 = warped_sample;` with no `mix(..., bypass)` wrapper — meaning out2
does **not** go to source or black on bypass, it stays warped
regardless. This is worth confirming is intentional in Max (does a
performer expect out2 to also respect bypass?) rather than assumed
correct just because it's what shipped.

**Strength:** At `strength = 1.0`, the full dynamic range of the field maps to ±1 UV offset. Useful range is typically 0.0–0.3 in practice; full range kept for expressive headroom.

**Edge behavior:** UV coordinates are clamped to [0,1], giving a stretched/smeared appearance at boundaries. No wrap or mirror modes in v1.

**`src_vecfield` state param:** Hidden system parameter driven by `vs_inState` outlet 1 on the vecfield inlet. Not user-facing — absent from route, UI, and parameters block.

---

## Inlets

| Inlet | Type | Label | Required | Description |
|---|---|---|---|---|
| 0 | texture + control | texture | Yes | Source texture to warp; control messages |
| 1 | f_vecfield texture | vecfield | No | Deformation field (float32, RG=XY, 0.5=zero) |

When in1 is unconnected: `vs_inState` delivers `vs_black` to pix in2, and `src_vecfield` is set to 0 — suppressing the offset. Output matches input.

When in0 is unconnected: pix receives no texture, output is black.

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `strength` | live.dial | 0.0–1.5 | 0.0 | Warp depth. 0 = no warp, 1 = ±1 UV offset, >1 = overdrive past ±1. Corrected 2026-07-11 — was documented as 0.0–1.0/0.1. |
| `bypass` | bypass_toggle.js | 0/1 | 0 | Passes source texture through unmodified. |

Hidden system params (not in UI, route, or parameters block):

| Param | Source | Notes |
|---|---|---|
| `src_vecfield` | vs_inState out1 on in1 | 0 = no field connected, 1 = connected |

**Prefix:** `vfwarp`
**Object name:** `vfwarp_pix`
**Output type:** `@type char`

---

## Signal Flow

```
in0 (texture + control) → routepass jit_gl_texture jit_matrix
  jit_gl_texture branch → vfwarp_pix in0      [source texture, direct — no vs_inState]
  unmatched → route strength → live.dial → attrui (strength) → vfwarp_pix in0

in1 (vecfield texture) → vs_inState in0
  vs_inState out0 (texture or vs_black) → vfwarp_pix in1   [gen in2]
  vs_inState out1 (0/1) → prepend param src_vecfield → vfwarp_pix in0

bypass_toggle.js → attrui (bypass) → vfwarp_pix in0

vfwarp_pix out0 → out0 (warped texture, @type char)
```

**Gen subpatcher inlets:**
- `in 1` → source texture (from routepass texture branch)
- `in 2` → vecfield texture or vs_black (from vs_inState out0)
- Codebox `numinlets`: 2

---

## Acceptance Criteria

- **Basic warp:** Connect a source texture to in0 and `f_vf_vortex` to in1. The source should appear warped around the vortex center.
- **Strength control:** Increasing `strength` from 0 to 1 scales distortion smoothly from none to ±1 UV offset.
- **Edge behavior:** Pixels displaced outside texture bounds smear/stretch the edge pixels — no wrap or mirror.
- **No vecfield connected:** With in1 unconnected, output matches the source texture exactly.
- **No source connected:** With in0 unconnected, output is black.
- **Bypass:** With bypass enabled, output exactly matches source texture regardless of vecfield or strength.
- **Accepts any f_vf_ producer:** Works with f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap without artifacts.
- **Resolution independence:** Warp is consistent regardless of source and vecfield texture resolutions.
- **Loads in Vsynth.** Survives a save/load cycle in a Vsynth patch without crashing.

---

## Out of Scope

- Wrap/mirror edge modes — clamp to edge sufficient for v1
- Separate X/Y strength controls — single `strength` param sufficient
- Multi-step streamline tracing (flow warp) — v1 is single-sample only
- Strength modulation via texture inlet — v1 keeps param surface minimal
- ~~Vecfield passthrough outlet — single outlet design~~ — **struck
  2026-07-11**: this was wrong even at the time this doc claims to
  describe (a 2nd outlet, `warped`, exists in `definition.py` and this
  doc's own Signal Flow section only ever showed one — see the
  What-it-does correction above)

---

## Open Questions

- **Strength upper bound:** Range 0–1 maps to ±1 UV offset. May be insufficient for very small-scale fields (e.g. tight vortex with low divergence). Revisit after testing — could extend to 0–2 if needed. **Resolved by definition.py already**: shipped range is 0.0–1.5, see corrected params table above.
- **out2 bypass behavior:** should `warped` respect bypass (go to source, or some other neutral) the way every other module's isolated/raw outlet does, or is unconditional-always-warped intentional here specifically? Not decided as part of this correction pass — flagging for the reframe below to pick up, since it's directly related to the crossfader work.

---

## Reframe (2026-07-11): dry/wet crossfader (finding 1)

### Context

`f_vf_warp` is the **replacement-type** shape in finding 1's
classification — `out1`/`out2` are full remapped images, not an additive
layer over source (unlike `f_vf_glow`/`f_vf_streak`/`f_caustic`). Finding
1 identified this shape as the textbook case for a direct
`out = mix(src, processed, wet)` crossfade — no additive-layer
ambiguity, no gain/wet split needed the way the additive-layer group
required (there's only one thing to blend, not a layer-then-blend
two-stage question).

Unlike `f_vf_advect` and `f_caustic`, though, this module currently has
**no dry/wet blend at all** — `out1 = mix(warped, source, bypass)` only
ever returns fully-warped (or fully-source-on-bypass), with no
performable control over the balance between them. `strength` controls
warp depth, not blend — at `strength=0` the warp collapses to zero
offset, which looks like passthrough but isn't a designed crossfade, it's
a degenerate case of the depth parameter. This is genuinely new
architecture for this module, not a rename.

### Decision

- Add `wet` param, float 0–1, crossfader-styled UI widget (check
  `vsynth-bpatcher/SKILL.md` convention before building)
- Rewrite `out1`: `out1 = mix(mix(source, warped, wet), source, bypass)`
  — wet blend first, bypass still takes final precedence
- Leave `strength` as-is (0–1.5, warp depth) — this is the correct
  "gain"-equivalent for a replacement-type module: it controls how
  strong the underlying transformation is, independent of how much of
  it gets blended into the output
- Resolve the open out2-bypass question as part of this same change:
  **decision — make out2 respect bypass** (`out2 = mix(warped, source,
  bypass)`), matching every other module's isolated/raw outlet
  convention in this library, rather than leaving it as the one
  exception
- Outlet comment: `composite` → `mix`

### Rationale

This module's two params (`strength`, new `wet`) map directly onto the
gain/wet split without any of the additive-layer complications
(no layer to compute before blending — the "layer" *is* the warped
image, so `wet` blends directly between source and warped, no
intermediate additive step needed). Simpler than the additive-layer
group's two-stage form for exactly the reason finding 1 predicted for
this shape.

### Acceptance criteria (addition)

- `wet=0` → out1 is clean source regardless of `strength`
- `wet=1` → out1 matches current (pre-change) behavior exactly at any
  given `strength` — regression check
- `strength` still controls warp depth independent of `wet`
- out2 now respects bypass (goes to source, not unconditionally warped)
  — behavior change from current shipped code, confirmed deliberate per
  the decision above
- No vecfield connected: `wet` and `strength` still behave sensibly
  (offset suppressed via `src_vecfield`, so warped≈source regardless of
  `wet`/`strength` values)
