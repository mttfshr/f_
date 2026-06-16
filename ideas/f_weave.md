# f_weave

**Status:** Idea
**Lifecycle stage:** ideas/ — concept capture, not yet specced

---

## Design requirement: distance field mark rendering

f_weave must be implemented as a **distance field** rather than a boundary transition. This is a hard requirement, not a preference, for two reasons.

**UV transform compatibility.** If mark edges are defined as smoothstep transitions at specific UV coordinates (the approach masonry uses), the texture contains high spatial frequency content that aliases badly through UV-transforming processors — droste near the singularity, mobius near fixed points, lens with strong distortion. A distance field has gradient information that any UV transform can sample gracefully: sampling farther into the field just means sampling farther from the edge, which is still smooth. No Nyquist problem.

**Proof of concept for masonry refactor.** Masonry's smoothstep boundary approach is the root cause of the masonry→droste aliasing problem. A masonry refactor to distance-field mark rendering would fix this, but masonry is already built and the refactor is non-trivial. Weave, being unbuilt, can be written distance-field-native from the start. A working weave codebox becomes the reference implementation — concrete evidence that the approach works, and a direct model for what the masonry refactor would look like.

This means weave + droste can be the test case for UV-transform-friendly periodic mark geometry, with lower stakes than modifying a working patcher. The direct comparison will be visible in the library: masonry (smoothstep boundary) vs weave (distance field) through the same droste chain.

**The codebox structure is already distance-field-adjacent.** The `euclidean_hit` function returns a float representing distance to nearest hit — that value *is* a distance field. The current sketch immediately thresholds it with smoothstep:

```
hit_dist = euclidean_hit(along_phase, beats, period, swing, band_idx)
mark = smoothstep(softness, 0.0, hit_dist)
```

The fix is to preserve `hit_dist` as the primary signal and use a falloff function rather than a hard threshold — the distance field is already being computed, just discarded too early. This makes the architecture shallower to fix than masonry.

**Euclidean rhythm and UV transforms.** Weave's mark clustering (hits at rhythmic positions with gaps between) means edge content isn't uniformly distributed. Through droste, some regions would alias and some wouldn't, with the variation following the weave rhythm. Even before the distance field approach is fully implemented, this structured variation may produce interesting rather than broken behavior — worth testing both approaches empirically.

---

## Concept

A parametric woven texture source in the same family as `f_grain`. Where `f_grain` is fundamentally 2D and cellular — each cell has an independent hash identity — `f_weave` is fundamentally **linear**: structure is composed of bands running along a locally-varying direction, with rhythm along those bands.

The central insight is that warp/weft is too literal a model. In denim, bands are parallel and run continuously — that's a special case. In fingerprints, there's no grid at all: bands run along a slowly-varying **orientation field**, break off, fork, and restart. The woven quality comes from the rhythm *along the local direction*, not from any global axis alignment.

The orientation field model generalizes across the whole character space:
- Zero curl, high continuity → denim (parallel throughlines, consistent rhythm)
- Low curl, low continuity → canvas or burlap (parallel-ish bands that break)
- Higher curl, low continuity → fingerprint (flowing broken bands, whorls and arches)
- Higher curl, high continuity → rope or contour (continuous bands that curve)

Warp and weft are emergent when curl is low — they appear as two families of nearly-perpendicular bands — but they are not the underlying model.

**The drumbeat connection:** The rhythm *along* each band maps cleanly onto Euclidean rhythm concepts from MIDI drumbeat generation:

| Drumbeat concept | Weave equivalent |
|---|---|
| Slots | Possible shape/mark positions along a band |
| Hits | Where marks actually land |
| Velocity | Mark size or visual weight |
| Swing | Positional jitter — marks drift from their ideal positions |
| Pattern length | How many slots before the rhythm repeats |
| E(k, n) | k marks in n slots, maximally evenly distributed |
| Phase offset | Where in the pattern each band starts |

The **Euclidean rhythm** E(k, n) — distributing k hits as evenly as possible across n slots — is the regularity dial along a band. E(4,8) gives strict, mechanical rhythm. E(7,13) gives complex, irregular rhythm at similar density.

---

## Architecture

Three conceptual layers, computed per pixel:

**1. Orientation field**
A smooth function that returns a local direction angle at every point. Parameterized simply — not user-drawn. A primary angle plus a spatial curl amount that rotates the field across the image. At zero curl: all bands parallel (denim). At nonzero curl: bands curve, producing whorls and arches (fingerprint territory). The field varies slowly and smoothly — no discontinuities.

**2. Local coordinate frame**
Each pixel rotates into the orientation field's local frame: one axis *along* the band, one axis *across* the band. All subsequent rhythm and continuity calculations happen in this rotated frame. This is what makes the structure follow the field rather than the global axes.

**3. Rhythm and continuity**
Along the band: Euclidean rhythm determines where marks land and how wide they are.
Across the band: a continuity function determines whether the band is present at this point or has broken. Low continuity produces ridge endings and forks (fingerprint character). High continuity produces throughlines (denim character).

The mark's luminance is a smooth function of distance to the nearest hit in the along-axis, modulated by continuity in the across-axis. No hard boundaries — the `euclidean_hit` function returns a float (distance to nearest hit) for smooth `softness` blending.

---

## Parameters (v1 — start simple, extend later)

| Param | Range | Default | Description |
|---|---|---|---|
| `density` | 0.0–1.0 | 0.5 | Overall scale — band spacing and mark frequency (log-mapped) |
| `angle` | 0.0–1.0 | 0.0 | Primary orientation of bands (mapped to 0–π) |
| `curl` | 0.0–1.0 | 0.0 | How much the orientation field rotates across the image — 0 = denim, higher = fingerprint whorls |
| `beats` | 1–16 | 4 | k in E(k, n) — how many marks per rhythm period |
| `period` | 1–16 | 8 | n in E(k, n) — rhythm period length |
| `regularity` | 0.0–1.0 | 1.0 | 1 = pure Euclidean rhythm, 0 = random at same density |
| `swing` | 0.0–1.0 | 0.0 | Positional jitter along the band |
| `continuity` | 0.0–1.0 | 1.0 | How likely bands are to persist vs break and restart |
| `weight` | 0.0–1.0 | 0.5 | Mark size / visual weight |
| `softness` | 0.0–1.0 | 0.2 | Edge softness of marks |
| `bypass` | 0/1 | 0 | Standard bypass |

**beats/period constraint:** `beats` ≤ `period`. Enforce in patcher before values reach codebox.

---

## Codebox Architecture

```
// Per-pixel signal flow:

1. Look up orientation angle θ at (px, py) from field function
   - θ = angle_param * π  +  curl_field(px, py, curl_param)
   - curl_field is a smooth spatial function — e.g. a low-frequency sine variation

2. Rotate pixel into local frame
   - along  = px * cos(θ) + py * sin(θ)
   - across = -px * sin(θ) + py * cos(θ)

3. Compute band index and phase
   - band_idx = floor(across * density_scale)
   - phase_offset = hash(band_idx) * regularity  [pinned hash — stable per band]
   - along_phase = (along * density_scale + phase_offset) mod period

4. Euclidean hit distance
   - hit_dist = euclidean_hit(along_phase, beats, period, swing, band_idx)
   - returns float: 0.0 = on a hit, 1.0 = maximally between hits

5. Continuity
   - continuity_val = continuity_function(px, py, band_idx, continuity_param)
   - a slow hash-based smooth function; low continuity = band absent at this point

6. Mark luminance
   - mark = smoothstep(softness, 0.0, hit_dist) * continuity_val * weight

7. mix(mark, 0.5, bypass)
```

**Swing:** Per-hit hash-based offset scaled by `swing` param. Seeds from hit index and band index — stable across frames, same pinned-hash approach as `f_grain`.

**Euclidean hit position:** Beat `i` in E(k, n) lands at slot `floor(i * n / k)`. Closed-form, no iteration. For bounded period (≤ 16) this is an unrolled comparison in the codebox.

---

## Character Space

`curl` × `continuity` define the primary texture character:

| | High continuity | Low continuity |
|---|---|---|
| **Low curl** | Denim — parallel throughlines | Canvas — parallel bands that break |
| **High curl** | Rope / contour lines — continuous curves | Fingerprint — flowing broken bands, whorls |

`regularity` × `swing` define the rhythm character within bands:

| | Low swing | High swing |
|---|---|---|
| **High regularity** | Mechanical — crisp, even marks | Regular structure, organic edges |
| **Low regularity** | Aperiodic — irregular spacing | Fully organic, no obvious repeat |

---

## Relation to Other Bpatchers

**Same family as:**
- `f_grain` — both are stochastic texture sources in `jit.gl.pix`; f_weave replaces the 2D Voronoi hash with a rhythmic band structure following an orientation field

**Works well with:**
- `f_droste` — weave pattern into log-polar spiral; band rhythm becomes a spiral rhythm
- `f_mobius` — Möbius-warped weave; bands bend into circles, local regularity preserved
- `f_lens` — weave as surface texture into surface mod inlet; gradient emboss gives woven relief
- `f_grain` composited — layering cellular and band structures

**Possible follow-on:**
- `f_weave_proc` — processor variant using the band/gap mask to selectively process an incoming texture

---

## Open Questions

- **Curl field function:** A low-frequency sine varying across the image is probably sufficient — f_weave doesn't need to render topologically correct fingerprints. Downstream processors (f_droste, f_mobius, f_lens) handle complex spatial deformation. The field just needs to be smooth and interesting.
- **Continuity implementation:** A slow spatially-varying hash acting as a gate on band presence. Doesn't need to model ridge endings with spatial extent — a smooth noise function is fine. Complex topology is downstream's job.
- **Integer beat/period params:** Naturally integers; `live.numbox` in int mode is likely right. Check Vsynth convention.
- **Animation:** A `phase` inlet (like f_droste's `time_s`) scrolling the along-band phase would animate the pattern. Worth designing the inlet in v1 even if not the primary feature.
- **Swing rhythm:** If swing itself followed a sub-rhythm (alternating early/late), it would produce more pressure-variation character. Emergent territory, not v1.
- **Color:** v1 luminance only. Future: map band direction or hit/gap classification to hue.
- **Second band family:** A perpendicular family of bands producing explicit crossings would be a different patch with a different model — not a v2 extension of f_weave. The polyrhythm in f_weave is between the rhythm *along* bands and the spacing *across* bands, not between two crossing families.

---

## Collision events / weave-as-vector-field (2026-05-31)

A distinct reframe worth holding alongside the band-structure model — may become its own patch or inform a v2.

**The reframe:** Threads aren't marks, they're *directions of travel*. The warp and weft families define two competing vector fields across the frame. Every pixel belongs to both fields simultaneously. Crossings aren't intersections of marks — they're *collision events* where two flows meet.

**What happens at collision — options:**
- **Interference** — field values add or cancel. Controlled moiré with intentional field structure.
- **Occlusion with energy** — one field dominates (over/under rule). Dominant field brightens at crossing; subordinate dims or redirects. The over/under alternation becomes an energy routing decision.
- **Scattering** — crossing becomes a source point radiating in bisector directions. Generates a secondary field from the collision geometry — diffraction-like pattern seeded by weave structure.
- **Phase disruption** — traveling wave hits crossing, phase is offset. Accumulated phase disruptions across many crossings produce complex interference derived from but not identical to the underlying weave.

**Animation:** Fields moving (phase advancing over time) means crossings propagate across the frame. Two families at different speeds = temporal polyrhythm — beating interference pattern with period LCM(speed_warp, speed_weft).

**Open questions:**
- Is this a texture source or a processor (two incoming textures define the two fields)?
- Which collision model is most visually interesting and tractable in a single-pass shader?
- Phase disruption may require feedback (accumulated state across crossings) — check if single-pass is sufficient.
- Relationship to f_vecfield: different generative logic (two competing periodic flows vs single field with fixed-point geometry), possibly shared vocabulary.
