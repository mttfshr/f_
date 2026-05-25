# f_ — Bpatcher Ideas

Low-friction scratchpad for half-formed bpatcher ideas. No structure required.
When an idea has a name, concept, and rough parameter contract, graduate it to `.specify/bpatchers/f_name.md`.

---

## f_cymascope
Wave propagation through a fluid medium (FDTD). Needs feasibility discussion re: ping-pong texture technique in Vsynth before speccing further. See `.specify/bpatchers/f_cymascope.md` — already graduated.

---

## Optics family — f_lens, f_caustic, f_flare, f_diffraction

**Unifying concept:** The incoming texture *is* the light source. Bright regions are where light originates. Each bpatcher simulates what happens to that light as it passes through a real optical element or phenomenon. This is physically coherent — in the real world all of these involve a light source, a medium or surface, and a transformed output.

**The optical element framing:**
- Incoming texture = light source (bright regions = light origin)
- Bpatcher = virtual optical element
- Output = light after passing through / interacting with that element

**Individual bpatchers (separate GLSL, shared conceptual frame):**

- **f_lens / f_aberration** — refractive lens displaces RGB channels by different amounts (lateral chromatic aberration), scaled by distance from center or by luma. Prior session work exists, review before speccing.
- **f_caustic** — focused light from a refractive surface produces additive brightness field. Bright input regions seed caustic sources. Output composited additively over input or as a separate texture.
- **f_flare** — bright source regions scatter light inside a virtual lens housing. Radial streaks, rings, polygonal aperture artifacts. Purely additive.
- **f_diffraction** — wave-optics interference at an aperture edge. Produces fine fringe patterns around bright regions. Most physically subtle of the group.

**Argument for separate bpatchers:** The GLSL is genuinely different for each — aberration is UV displacement per channel, caustics are an additive brightness accumulation, flare is radial streak geometry, diffraction is interference fringe math. One codebox would be unwieldy.

**Shared parameter vocabulary (use consistently across the family):**
- `source_brightness` or just drive from input luma
- `intensity` — effect strength
- `focal_length` / `aperture` where physically meaningful
- `refraction_index` for lens/caustic

**Note on caustics:** also related to f_cymascope (light on fluid surface) — shared aesthetic territory, different implementation path. The optics-family caustic is driven by a texture source; cymascope caustic emerges from wave simulation.

Prior session work on aberration to review before speccing any of these.

---

## Apollonian fractal

Circular Apollonian gasket — iterative circle packing fractal. Known to be possible in Vsynth GLSL (a fully controllable, animating implementation exists but source is not public). 

Key appeal: the fractal is defined by a small number of geometric parameters (seed circles, recursion depth) and is naturally animatable by slowly varying those. Potentially very controllable as a generative texture source.

Open questions:
- GLSL implementation approach — distance field? iterative inversion? ray-marching?
- What the natural parameter space is for animation
- Whether it fits the bpatcher model or wants to be a standalone patch

---

## Non-Euclidean geometry / space

Brainstorm-level — not sure yet what form this takes as a bpatcher. The question is whether you can render or transform textures *as if* the underlying space has non-zero curvature.

Possible angles:
- **Hyperbolic tiling** — Poincaré disk model, tessellate a texture through hyperbolic reflections. Escher's Circle Limit prints are the visual reference. Surprisingly tractable in GLSL — the Möbius transformations that tile hyperbolic space are closed-form.
- **Spherical projection** — map texture through a spherical coordinate system, producing the visual distortion of a curved surface. Controllable curvature as a parameter is the interesting part.
- **Geodesic displacement** — use non-Euclidean distance as a displacement or color-selection field rather than rendering the geometry directly. More abstract, potentially more useful as a processor.

The Möbius transformation connection to Apollonian fractals is worth noting — same underlying math, possibly shared implementation ideas.

---

## Light caustics

Very high visual appeal. Caustics are the focused light patterns produced when light refracts through or reflects off a curved surface — the shimmering nets of light on a pool floor, bright curves inside a glass.

Two distinct approaches:
- **Analytic / noise-based** — approximate caustic patterns using layered noise or wave interference fields. Fast, controllable, not physically accurate but visually convincing. Probably the right starting point.
- **Physical simulation** — photon tracing through a refractive surface in GLSL. More of a research project than a bpatcher, but worth understanding the ceiling.

Natural parameters: scale, animation rate, refraction index, brightness, color tint. Could be a pure generator or react to an incoming texture (bright regions seed caustic sources).

Visually related to f_cymascope — both involve light interacting with a fluid surface. Might share aesthetic DNA even if the implementation differs.

---

