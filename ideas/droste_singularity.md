# f_droste singularity region — emergent visual behavior

## Discovery (2026-06-05)

During f_stipple e2e testing, observed a persistent shadow shape in the center of droste output when stipple is used as source. The shape is stable, always present, and changes character depending on the source texture fed into droste.

## What the shape is — precise explanation

The shape is the **innermost tile boundary** in droste's log-polar tiling — the seam where `s_sp = 0`, which in the untwisted case corresponds to `r = 1/zoom` from center, distorted by twist into a curved form.

Droste's core transform:
```
r = sqrt(dx*dx + dy*dy);
s = log(r) / log(zoom);         // log-radial coordinate — how many zoom levels from center
t = (theta / TWO_PI) + rotation;

s_sp = s - t * twist;           // sheared log-radial
t_sp = t + s * twist;

out = sample(in1, vec(fract(t_sp * n_arms), fract(s_sp)));
```

The `fract()` calls create the recursive tiling by wrapping both coordinates. The **seam** is where `s_sp` crosses an integer — where one zoom level ends and the next begins. The innermost seam (`s_sp = 0`) is the shape you see.

Inside the boundary: `s_sp < 0`, meaning `r < zoom^(t*twist)` — pixels closer to center than one full zoom level. This is the true singularity zone.

## Why it's that specific shape

- **twist = 0**: seams are perfect circles (s_sp = s is purely radial)
- **twist > 0**: the shear couples s and t, distorting circles into curved spiral-edged forms — exactly the geometry of Escher's Circle Limit prints
- **rotation**: shifts t uniformly → shifts t_sp uniformly → seam location in s_sp unchanged. Shape doesn't move or rotate. Confirmed empirically.
- **zoom**: changes the radial scale → moves the boundary inward/outward. Confirmed empirically.
- **arms/twist**: changes the shear → distorts the shape. Confirmed empirically.
- **stipple params**: no effect — the shape is purely a droste geometry property. Stipple just reveals it.

## Why it delimits the masonry→droste problem zone

The shape is a **sampling rate isocontour** — the exact boundary where:

```
droste_samples_per_pixel = masonry_feature_frequency
```

Inside the boundary: droste is sampling masonry at a spatial frequency higher than one feature (brick/mortar line) per pixel. Multiple mortar lines fall within a single output pixel → catastrophic aliasing → extreme pixelation.

Outside the boundary: sampling rate is coarser than the aliasing threshold → masonry's AA approximation holds adequately.

The shape literally draws the line between where the pipeline works and where it doesn't. It's not a coincidence that it's the same shape as the singularity — they're the same phenomenon viewed two ways: geometrically (tile boundary) and signal-theoretically (Nyquist threshold).

## Hyperbolic geometry connection

This is the same phenomenon as tile edges in hyperbolic tiling (Poincaré disk, Escher Circle Limit). In hyperbolic tiling, the conformal map compresses space toward the boundary; tile edges are isocontours of that compression. In droste, compression is toward the center rather than the boundary, self-similarity is radial rather than angular — but the mathematics is the same family (conformal maps, log-polar coordinates, Möbius transformations).

twist > 0 makes droste directly analogous to Escher's spiral tilings — coupling radial and angular coordinates exactly as Escher's conformal maps did.

**f_poincare** (in build queue) works with this geometry explicitly. The droste singularity shape is a preview of the tile boundary structure f_poincare will be designed around. Knowing this geometry in advance means f_poincare can be designed around the singularity rather than discovering it empirically.

## f_raster implication

f_raster (supersampling utility) would push the singularity boundary inward — by pre-rendering masonry at higher resolution, the Nyquist threshold rises and the problem zone shrinks toward the true mathematical singularity at r=0. The singularity can't be eliminated (it's always there) but can be made arbitrarily small with sufficient supersampling.

## Exploiting the shape explicitly

The seam distance is computable inside droste's codebox:
```
seam_dist = abs(fract(s_sp) - 0.5) * 2.0;  // 0 at seam, 1 at midpoint between seams
singularity_mask = step(s_sp, 0.0);          // 1.0 inside singularity zone, 0.0 outside
```

Possible uses:
- Highlight seams explicitly (blend color at seam_dist < threshold)
- Expose singularity_mask as second outlet — modulation texture for downstream use
- Blend different sources inside vs outside the boundary

## Source textures — how each reveals the shape

- **Stipple** — reveals it as beautiful interference/shadow structure. Hash field responds to compressed/wrapped UV near singularity producing emergent moiré-like pattern. Compositionally interesting, feels intentional.
- **Masonry** — reveals it as extreme pixelation. Hard edges alias into pixel blocks inside boundary, more or less fine outside.
- **Smooth WFG sources** — probably hide it entirely; smooth signals don't alias visibly under compression.
- **Grain** — untested; likely similar to stipple given stochastic nature.
- **Chladni** — untested; modal patterns may produce interesting interference at the boundary.

## Stipple + droste as named pairing

Stipple's frequency characteristics are naturally compatible with droste's UV transform. The aliasing near the singularity becomes expressive rather than broken. The inside/outside contrast (chaotic interference inside, clean directional lines outside) is controllable via droste's zoom and arms/twist params — the boundary can be placed deliberately. Strong performance pairing worth exploiting.

## Status

Conceptual understanding complete. Implementation ideas noted but not planned. f_poincare design should incorporate this geometry explicitly from the start.
