# f_vf_seeds

*Captured 2026-06-27. Emerged from discrete-item family comparative analysis.*

---

## What it is

A discrete-item generator where items are marks placed at stable seed positions
distributed across the frame, rendered as short streamline marks oriented by an
incoming vecfield. Each seed is a hash-stable point; its mark follows the local
field direction at that position.

Character: somewhere between f_grain (stationary cells), f_weave (line-oriented
marks), and f_vf_lic (continuous streamline convolution). Closest visual analogy:
weather-map wind barbs, or ink marks brushed along a flow field.

---

## Why it exists

f_vf_seeds is the **reference implementation** for the discrete-item family's
standard inlet/outlet architecture. Because its vecfield inlet is primary and
load-bearing — there is no meaningful fallback to a global angle param — it
forces the architecture to be designed properly from day one.

It is also the first module to implement the **identity coordinate output**,
which exposes each pixel's item identity UV for downstream use.

See `ideas/discrete_item_family.md` for the full family framework.

---

## Architecture

**Single-pass, stateless.** No ping-pong feedback required. Each pixel:
1. Finds its nearest seed point (Voronoi-style, hash-stable)
2. Reads the vecfield at that seed position to get local orientation
3. Projects its position into the seed's local coordinate frame (along/across)
4. Renders a mark based on `along` (trail length) and `across` (mark width)

This is analogous to f_weave's mark rendering but with seed-local rather than
global-line coordinate frames. The key insight: sample the vecfield at the
**seed position** (stable, identity UV), not at the current pixel (screen UV).
This gives each mark a coherent single orientation rather than a per-pixel
orientation that would shear the mark.

### Seed distribution

Seeds are placed at Voronoi centroids (same hash approach as f_grain). Density
and jitter control how many seeds exist and how evenly spaced they are.

Alternatively: seeds on a regular grid with hash jitter — simpler math, less
organic. Decision point when building the scratch patch.

### Mark rendering

Once the seed's local frame is established (along/across relative to field
direction at seed), mark rendering follows f_weave's smoothstep pattern:

```
mark = smoothstep(weight, 0.0, abs(across))
     * smoothstep(marklen * 0.5, 0.0, abs(along - 0.5 * marklen));
```

Mark is asymmetric along the field direction — a teardrop or dash shape
rather than a symmetric oval — to convey directionality.

---

## Inlets and outlets

Following the discrete-item family standard:

**Inlets:**
- `in 0` — control/texture (Vsynth convention)
- `in 1` — vecfield (float32 RG, primary — drives mark orientation at each seed)
- `in 2` — identity texture (sampled at seed position UV, per-seed character mod)

**Outlets:**
- `out 0` — composite output
- `out 1` — mark mask (isolated seed marks)
- `out 2` — identity coordinate texture (each pixel → its seed's position UV)

The identity coordinate output is novel: a texture where each pixel's RGB encodes
the (u, v) position of its nearest seed. Feed this into another generator or
processor, then connect the result back to `in 2` for external-feedback-driven
per-seed character control.

---

## Parameters

### Arrangement (global topology)
- `density` — seed count / spacing (log-mapped, matches f_weave/f_grain convention)
- `jitter` — how far seeds deviate from regular grid (0 = perfect grid, 1 = fully stochastic)

### Item character (intrinsic)
- `weight` — mark width (across-axis extent)
- `marklen` — mark length (along-axis extent, in field direction)
- `softness` — edge falloff width (independent of weight, per weave convention)
- `shape` — mark profile blend (0 = flat-top rectangle, 1 = raised cosine)
- `taper` — asymmetry along field direction (0 = symmetric, 1 = full teardrop)

### Field response
- `strength` — vecfield influence depth (0 = no orientation, 1 = full field-driven)
- `mag_weight` — field magnitude → mark weight modulation depth

### Animation
- `phase` — scroll marks along field direction (standard animation entry point)

### Mod depths (for identity texture inlet)
- `weight_mod` — identity texture → weight
- `marklen_mod` — identity texture → mark length
- `softness_mod` — identity texture → softness

---

## Vecfield magnitude as second parameter

The vecfield inlet provides direction (used for orientation) and magnitude (currently
unused in all other modules). In f_vf_seeds, magnitude should drive mark weight:

```
weight_eff = weight + field_magnitude * mag_weight;
```

This gives dense marks where the field is strong, sparse where weak — a direct
perceptual mapping between field energy and visual density.

---

## Identity coordinate output (out 2)

For each pixel, `out 2` outputs `vec(seed_u, seed_v, 0, 1)` where `(seed_u, seed_v)`
is the position of that pixel's nearest seed in normalized screen coordinates.

Use cases:
- Feed into f_grain or f_masonry as a spatial modulator
- Feed into f_vf_fieldmap to generate a vecfield derived from seed positions
- Feed back into f_vf_seeds in 2 (self-modulating: seed character driven by
  spatial relationships between seeds)
- Feed into f_tone_curve to color-map seed positions

This output is cheap — it's computed as part of the Voronoi solve and requires
no additional passes.

---

## Relationship to other modules

| Module | Relationship |
|---|---|
| f_grain | Same Voronoi seed solve; f_vf_seeds adds vecfield orientation, removes era/temporal layer |
| f_weave | Same mark rendering (smoothstep along/across); f_vf_seeds uses per-seed local frame rather than global lines |
| f_vf_lic | Both render field-aligned marks; LIC uses continuous convolution, seeds uses discrete marks at stable positions |
| f_vf_warp | Can feed vecfield into f_vf_seeds in 1 |
| f_vf_repulse | Texture-driven repulsion field → f_vf_seeds for mark clustering around bright regions |
| f_vf_potential | Potential gradient → f_vf_seeds for marks aligned to isolines |

---

## Open questions for scratch patch phase

1. **Seed distribution:** Voronoi centroids (organic, f_grain-like) vs. regular
   grid + jitter (simpler, more controllable density)? Try both.

2. **Vecfield sampling at seed vs. at pixel:** Sampling at seed position gives
   coherent marks but ignores within-mark field variation. Sampling at pixel gives
   more field-accurate orientation but shears the mark. The seed-position approach
   is probably correct — test this.

3. **Mark asymmetry / taper:** A symmetric dash conveys presence; a teardrop
   conveys direction. Is taper always desirable or should it be a param?
   Start with taper as param, see what feels natural.

4. **Nearest-seed lookup cost:** 3×3 neighborhood search (like f_grain) should
   be sufficient for reasonable density ranges. Test performance at high density.

---

## Status

Idea. Graduate to `.specify/f_vf_seeds/` when ready to build.

Pre-requisites:
- f_vf_potential built and registered (in progress)
- discrete_item_family.md framework settled (done, this session)
- f_weave softness/shape additions complete (planned this session)
