# f_lumia — animated refraction-glass caustics (Lumia-style)

_Created: 2026-10-06._ **Status: ⚪ concept only.** Nothing here has been scratch-tested; every claim about how existing modules behave comes from `docs/f-reference/module-inventory.md`, not from the per-module docs or a live patch. Verify before building on any of it.

## The idea

Thomas Wilfred's Lumia (Clavilux lineage; see the color-organs passage in `entrainment.md`, which sets it aside as a different project from entrainment) has several implementations. The one this note targets is physical optics: a gobo or laser sent through an **irregular glass substrate** (often moving: rotating disc, translating plate, oil wheel) onto a screen. The result is bright bands and filaments where the glass focuses light, and dark where it spreads it. The expressive element is **animation**: the areas of compression (caustics) move, split, merge and shift.

The softer reading of Lumia (translucent veils and ribbons from fluid advection) was considered first and is a different thing; see "Rejected / not this" below.

## Framing: the glass is a height field

- The glass is a **scalar height map**. Local slope sets the deflection direction and strength, so `f_vf_fieldmap` (central-difference gradient, "any scalar texture into a field") is the natural height-to-refraction-field adapter. Sign is a gain inversion.
- The **source** (gobo, laser dot/line, solid color, or an image) is what the glass acts on. It is *not* the thing that carries the animation.
- Caustics come from **curvature**, not slope: bright lines form where the second derivative of the height reaches a critical value. So the height wants smooth, moderate-scale curvature. Fine noise gives sparkle, not Lumia.

## Warp vs. caustic: two views of one field

- `f_vf_warp` displaces where the source samples from. A solid color warped by any field is still a solid color, so it shows nothing. An image through warp looks like *seen through* the glass.
- `f_caustic` redistributes brightness (builds up where the field converges). A solid color comes out as bands and filaments of that color on dark. An image looks like *light focused onto a screen*.
- A real gobo shows both at once. Working hypothesis: the module centers on `f_caustic`, with an optional warp of the source before accumulation, both driven by the **same** field. Solid color = pure Lumia; image = richer.

## Animation axes (the actual expressive surface)

Per the inventory `f_caustic` is not marked temporal, so all motion would come from the height map or from the caustic's own parameters:

1. **Evolve the height through a third (time) axis.** Scrolling 2D noise only slides one caustic pattern sideways; evolving through time makes lines drift, split and merge. Open: whether `jit.gl.bfg` exposes a time/offset axis for this.
2. **Rotate / translate the height.** The physical rotating disc or gobo wheel. Suits the circular screen (`circular_screen.md`).
3. **Throw distance.** `f_caustic`'s streamline length is effectively propagation distance after the glass. Animating it pulls caustics in and out of focus. Cheap second axis.
4. **Audio drive.** `f_chladni` outputs a luma figure and could serve as an audio-driven glass.

## Other physical elements

- **Dispersion:** real glass bends colours differently. `f_vf_chroma` / `f_vf_prism` split colour along the field and look like the right tools (isolated layers available).
- **Laser source:** same chain with a point or thin line as the source; expect speckled bright filaments.
- **Beam divergence:** a projector or laser diverges from a point, a flat source texture does not. A radial term added to the glass field (maybe `f_vf_vortex` with convergence only) could stand in. Untested.
- **Glow / halation:** `f_vf_glow`, `f_lens` halation for the diffused-screen quality.

## Trap: do not drive this with `f_vf_fluid`

`f_vf_fluid` looks like an obvious way to animate, but its `project` control makes the velocity field divergence-free, and `f_caustic` brightens where the field **converges**. A fully projected fluid field would give little or no caustic. A gradient of a height map is curl-free and strongly divergent, which is the case wanted here. Keep fluid out unless `project` is low and this is deliberately tested.

## Risks to check

- **Height precision.** An 8-bit height map makes the central-difference gradient stepped, and the caustics will show the steps. A float32 source (e.g. `jit.gl.bfg`, fieldmap's documented primary source) should avoid it; unconfirmed in practice.
- **Glass generator quality.** Smooth, irregular, low-frequency height is needed (see curvature note above). May need a dedicated generator rather than raw noise.
- **Does `f_caustic` behave like energy-conserving focusing, or just look plausible?** Checked 2026-10-06 in NumPy (`optics_map.md`, "Findings: caustic fidelity"): it is the first-order term only, so it gives soft convergence blobs that do not sharpen with distance and has no fold lines. A determinant-based gather tracks real caustics up to about the first fold; beyond about 2x that distance the true pattern becomes overlapping translucent folded sheets (the Lumia ribbon look), which a single-guess gather cannot produce and scatter can. **A multi-start gather (many starting guesses per pixel, NumPy only, same day) also reaches the sheets, less accurately and at much higher cost, and without a GL scene; see `optics_map.md`, "Findings: multi-guess gather".** **A scatter spike the same day, run in Max inside Vsynth's render context, shows scatter is feasible and matches the photon-counting truth (r 0.994 at 3.5 d*), at the cost of a one-frame lag against pix-chain modules; details and what is still untested are in `optics_map.md`, "Findings: scatter feasibility spike".**

## Proposed first step (scratch, no module yet)

Scratch chain in `~/Vsynth/patterns/`: slowly evolving smooth height -> `f_vf_fieldmap` -> `f_caustic`, first with a solid-color source, then an image; then try `f_vf_warp` on the source with the same field, then `f_vf_chroma` / `f_vf_prism`. Judge how the caustics move before deciding anything.

## Module question (superseded later on 2026-10-06; the earlier reasoning follows)

**Latest direction (Matt, 2026-10-06):** `f_vf_glass` is **on hold** (Vsynth already ships smooth, morphing
sources: `vs_noise_*`, `vs_chemical_osc`, low-pass filters), and the sheet regime goes into `f_caustic` as a
**second mode** rather than a separate module (soft = today's behaviour, unchanged; sheets = new). The method
for the sheets mode is **open**: scatter (GL scene; best quality; 1-frame lag, memory) or a multi-start gather
(ordinary pix codebox; weaker; heavy per-pixel cost). The spec in `.specify/f_caustic_scatter/` still describes
the separate-module scatter draft and needs rewriting as an addendum to `f_caustic`.

**Earlier decision (Matt, 2026-10-06, since superseded):** pursue the sheet-regime scatter module, as a consumer only
(`.specify/f_caustic_scatter/spec.md`), and make the glass a separate producer, `f_vf_glass`
(`f_vf_glass.md`, `.specify/f_vf_glass/spec.md`), so one animated glass can feed warp, prism, caustic and the
scatter together. "Lumia" is the look (a preset or demo patch built from these), not a module name.

A chain that only wraps existing modules is thin, the same objection that shelved `f_focus` (`.specify/plan.md`, Paused/blocked). The case for a module is if it **owns the glass**: an animated smooth-height generator with its own controls (scale, smoothness, evolve speed, drift/rotate, throw distance), feeding fieldmap, caustic and optional warp internally, with source in and a chroma stage on the outputs. The animation controls would then be the module's own expressive surface. As far as the inventory shows, nothing in `f_` is a purpose-built animated glass. Decide after the scratch chain. If built as a gather (soft, up to about the first fold), the multi-stage `pix_chain` builder path (as `f_vf_fluid`, `f_vf_seeds`) is the likely route, with a `definition.py` from the start. If built as a scatter (the sheet regime), it owns a GL scene (node, mesh, shader, lattice) and is closer in kind to Vsynth's `vs_xyz_disp` than to the f_ pix modules, so `pix_chain` does not apply and the builder would need a new mode or the module would be hand-built; that is a larger decision than the physics, and is open. (Superseded in the spec: the proposal is the builder's `definition.py` with the scene in `raw_boxes` / `raw_lines`, which `f_lens` and `f_grain` already use; Phase 0 confirms the contract tests accept it.)

## Related

- `f_vf_glass.md` (the glass producer), `.specify/f_vf_glass/spec.md`, `.specify/f_caustic_scatter/spec.md`
- `f_caustic.md` (idea), `docs/f-reference/f_caustic.md` (as built), `f_vecfield.md`, `f_vf_channelmap.md`
- `spectral_rainbow_colormap.md` (real spectral dispersion would be a gap in `f_vf_prism`)
- `glow_profile_and_afterimage.md`, `godray_radial_accumulation.md` (untested composition in the same family)
- `circular_screen.md`, `entrainment.md` (color-organs lineage)

## Rejected / not this

The first reading was Lumia as translucent flowing veils: `f_vf_fieldmap` -> `f_vf_fluid` -> `f_vf_advect` -> `f_vf_glow` -> `f_caustic` -> `f_vf_prism`. It is a different look (smeared sheets, not focused light), costs many stages, and the fluid step works against caustic as above. Open gaps from that reading, kept in case that look is wanted later: a pre-blur for smooth input, LIC (`f_vf_smear.md`) for silky texture, and a scalar-to-spectrum colormap.
