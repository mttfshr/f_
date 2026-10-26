# f_wave_field — wave and oscillator fields (working name `f_wave`)

_Status: 🟡 specced 2026-10-23 as `.specify/f_wave_field/spec.md` (working name `f_wave_field`). Drafted from the
webgpgpu mining run (`webgpgpu-ideas-1`). Not tried in Max._

**The spec settled the open question below in favour of the spectral solver** (the `f_ks` / `f_wc_fft` chain, exact per-bin step) and generalised
the three modes into one dispersion relation, `omega^2 = ring^2 + speed^2 k^(2 dispersion)`. The spec is authoritative.

## Concept

A temporal generator whose state is a field that propagates: drop an impulse
(or let a source texture drive it) and rings expand, reflect and interfere. Three
related webgpgpu techniques give three modes of one module:

1. **Classical wave equation** (potential + velocity). `Example_24`: velocity is
   updated from the Laplacian times c*c, potential from velocity, c = 12.5,
   dt = 0.1, ten steps per frame. The Laplacian is taken on a Gaussian-smoothed
   copy of the potential (two blur passes), not the raw one.
2. **Leapfrog wave driven by a texture.** `Vision_010_..._2`: the same idea
   with the smoothed Laplacian feeding two state buffers (U position, V velocity),
   dt = 0.4, so any texture can act as forcing.
3. **Rotation oscillator.** `Vision_006`: every pixel holds a complex value that
   is rotated by theta and decayed each frame (damped-resonator, ring frequency
   and forgetting time as dials) while the frame injects. `Vision_014` adds a
   Laplacian into the rotation so the ringing travels as waves.

Mode 3 is the only one that is driven by *video rhythm* rather than by impulses:
each pixel rings up when its input keeps hitting the ring frequency.

## What f_ has today (checked against the inventory)

- `f_chladni`: standing modal figure, audio-driven, no propagation.
- `f_ks`: chaotic, self-sustaining, sourceless; spectral.
- `f_vf_fluid` / `f_vf_lbm`: flow, not waves.
- Nothing propagates ripples or rings a field at a set frequency.
- Existing idea file: `f_cymascope.md` (audio to vecfield through FDTD ping-pong).
  Mode 1 is exactly the core that note calls for. Reading the two together:
  `f_cymascope` = this solver plus an audio front end (pitch + envelope) and a
  gradient vecfield output for `f_caustic`.

## Proposed shape

- Signature: texture (optional drive) -> scalar field (luma) + vecfield (gradient
  of the field), temporal. The gradient outlet follows the `f_chladni` precedent
  and is what `f_caustic` / `f_vf_warp` want.
- Mode menu: Wave (impulse/texture-driven), Resonator (per-pixel ringing),
  Coupled (resonator + Laplacian).
- Dials (per mode): wave speed, damping, ring frequency, drive gain, exciter
  position/strength, coupling radius.
- State on float32 ping-pong, same pattern as `f_ks` / `f_vf_advect`. The web
  versions pack state into 8-bit channels around 0.5; none of that carries over.
- A shared helper worth keeping on its own: the isotropic nine-point Laplacian
  (-10/3 centre, 2/3 edges, 1/6 diagonals) used in `Vision_008/013/014`.
  `f_` has gradient operators but no reusable second derivative.

## Tier-1 checks (all closed form)

- Wave: total energy 0.5 v^2 + 0.5 c^2 |grad u|^2 is conserved up to damping; small
  amplitude dispersion omega^2 = |k|^2.
- Resonator: amplitude decays exactly as decay^n and phase advances n*theta; an
  injected constant rings up as a bounded geometric series.
- Laplacian stencil: eigenvalue matches -k^2 h^2 near zero and is zero at DC.

## Risks and open questions

- **Stability and cost.** The worker flagged a CFL limit (c*dt under half a texel)
  and the real-space multi-pass Laplacian per frame; the index already records
  that Jacobi-style iterations were judged impractical once. Possible answer
  (my addition, not from the run): the linear wave equation is exactly solvable
  per Fourier mode, so the `f_ks` / `f_wc_fft` pattern (exact linear stage, spectral)
  would remove the CFL limit. Cost is the `f_ks` DFT cost, and edges become
  periodic instead of reflecting. Decide before speccing.
- Resonator mode is frame-rate dependent (ring frequency in radians per frame).
  Consider seconds-based dials.
- The coupled mode needs an amplitude homeostat (Vision_014) or it saturates or
  dies; benching territory.
- Check `docs/vsynth-reference/module-inventory.md` for core Vsynth feedback
  modules before committing; the run could not see that file.

## Related

`f_cymascope.md`, `f_chladni`, `f_ks`, `f_vf_wilson_cowan.md` (same family of
temporal generators), `f_adapt.md` (the temporal band-pass there is the natural
drive for Resonator mode: it is exactly the forcing `Vision_013` uses).

## Provenance

webgpgpu (michaelerule/webgpgpu) at 5997061, omp run `webgpgpu-ideas-1`,
2026-10-23. Source drafts: `f_omp_runs/webgpgpu-ideas-1/ideas_draft/`
40, 57, 58, 59 (wave solver, damped oscillator, oscillator wave field, real-space
solver) and the Laplacian helper in `SUGGESTIONS.md`. Each was checked by a
verifier against the shader files and the f_ inventory; I spot-checked the wave
constants. Nobody has judged whether the result looks good.
