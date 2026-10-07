# f_vf_glass — animated glass height field → f_vecfield

_Created: 2026-10-06_
_Status: ON HOLD (2026-10-06, Matt). Vsynth already ships smooth, morphing sources (`vs_noise_*`,
`vs_chemical_osc`, low-pass filters); revisit only if they fall short as glass. Concept — not yet built. Nothing here is tested; "measured" below means measured in the
2026-10-06 caustic/scatter work (`ideas/optics_map.md`), "inferred" means it is reasoning._

## Why it exists

The light-through-glass work (`f_lumia.md`, `optics_map.md`) modelled glass as a **height field**: its
slope deflects light, its curvature focuses it. Everything downstream (warp, caustic, dispersion, streak)
reads the same vecfield, the gradient of that height. Today that field has to be assembled from a
`jit.gl.bfg` noise (or another scalar) into `f_vf_fieldmap`, and animation is whatever the noise source
can do. The `jit.gl.bfg` refpage lists a two-component `@offset` and `@scale` and no time axis (a hidden
third axis is not ruled out, not checked), and translating a field only slides one caustic pattern
sideways; the look the Lumia work is after (bright lines that **split, merge and shift**) needs the
height to *evolve*.

Decision (2026-10-06, with Matt): make the glass a first-class **producer**, separate from the scatter
module (`.specify/f_caustic_scatter/`), because one animated glass can then drive a whole stack of
existing consumers, it is a pix-only module (builder, NumPy and bench tiers, no GL scene), it gives the
scatter module a realistic test bed, and a lag or aliasing problem in the scatter cannot block it.

## What it would be

A generator (self-generating; no input needed) of smooth **analytic** height fields `h(u, t)` and their
**exact** gradient. Analytic means an exactly known curvature and a gradient with no registration offset. (It does **not** mean
better caustics than a smooth float32 height through `f_vf_fieldmap`; see "Findings" below, which corrected
an earlier version of this paragraph.)

Candidate outlets (not locked):

| Outlet | Content | Why |
|---|---|---|
| 1 `vecfield` | `F = gain * grad h`, f_vecfield (float32, RG = XY, 0.5 = zero) | the refraction/deflection field every consumer reads |
| 2 `height` | `h`, scalar, mapped to 0..1 | displacement (`vs_xyz_disp`), relief shading, thin-film palette, masks |
| 3 `focus` | divergence of `F` (signed, 0.5 = zero) or a curvature measure | where light will converge; masks; a cheap preview of caustic regions |

## Glass families

All v1 candidates are **mode sums** `h = sum_k a_k cos(2π (kx_k x + ky_k y) + φ_k(t))`, so one codebox
covers them; they differ only in the wave-vector set:

| Family | Wave vectors | Look |
|---|---|---|
| `modes` | N seeded integer vectors (N ≈ 3–8), mixed amplitudes | irregular glass; the family used as the test glass in `scratch/caustic_fidelity.py` (5 modes, `|k|` ≤ 3), where it gave clean caustic networks |
| `fluted` | 1 vector | parallel ribs → parallel line caustics |
| `hobnail` | 2 orthogonal vectors, equal amplitude | square lattice of bumps |
| `hex` | 3 vectors at 60° | hexagonal lattice |

Gradient `grad h = -sum_k a_k 2π (kx_k, ky_k) sin(arg_k)` and Hessian
`H = -sum_k a_k (2π)^2 [kx², kx ky; kx ky, ky²] cos(arg_k)` are closed forms.
Integer wave vectors make the unrotated field seamlessly periodic (matters to a consumer's wrap mode).

Later families, not mode sums (need per-cell structure): lens array (parabolic cells), rain-glass
ripples (radial waves), Fresnel rings.

## Animation (the expressive surface)

- **evolve**: each mode's phase drifts, `φ_k(t) = φ_k + ω_k t`, with incommensurate rates so the pattern
  does not repeat. This evolves the height through time, so caustic lines split and merge. (Inferred
  from the maths; the look is untested.)
- **drift x/y**: translate the pattern.
- **rotate** (and a rotation rate): a gobo wheel. Rotating the coordinates leaves a smooth field
  everywhere, but breaks the tile periodicity.
- **Time source is open.** A pix codebox has no obvious clock (not verified for `jit.gl.pix`). Options: a
  plain `phase` param that a user can automate or LFO, plus an internal counter chain fed by `r draw`
  (as the 2026-10-06 lag spike used) for the free-running `evolve`.

## Regime normalisation (idea, untested)

Measured: the first fold forms at `d* = 1 / (most negative Hessian eigenvalue)`; the thin-line regime is
`d` up to about `d*`, the translucent-sheet regime is beyond about 2 `d*` (`optics_map.md`). Because the
Hessian here is closed-form, the module can bound its peak curvature from its parameters
(`sum_k a_k (2π|k_k|)^2`) with no GPU reduction pass. If the field were scaled so that bound is a
convention, a consumer's `distance` control could mean "in units of the first fold", and a glass change
would not silently move the regime. Open: the interaction with the `|F| <= 1` encoding limit (field
amplitude shrinks as pattern scale shrinks), and how a consumer would learn the convention (the vecfield
type carries only RG).

## What it would unlock (documented consumers; looks untested)

One animated glass feeding several existing modules, all agreeing on where the glass is:
`f_vf_warp` (the image seen through the glass), `f_vf_prism` / `f_vf_chroma` (dispersion fringes),
`f_caustic` (soft convergence glow, accurate only to about 1 `d*`), `f_vf_streak` / `f_vf_glow` (silky
smear along the slopes), `f_vf_advect` (flow along the slopes), `f_lens` field inlet, and the scatter
module (`f_caustic_scatter`, the sheet regime). The height outlet opens `vs_xyz_disp` relief, relief
shading from the vecfield as a surface normal, and the thin-film iridescence idea in the optics map.

## Relationship to existing modules

- `f_vf_fieldmap` stays: it maps *any* scalar texture (video luma, other generators) to a field. The glass
  is for the case where the scalar is a designed, evolving, analytic glass.
- `f_chladni` is already an audio-driven plate with a vecfield outlet. The glass is not audio-driven in v1;
  a `phase` or `evolve` control can be modulated by an envelope in the patch.
- `jit.gl.bfg` stays the source for organic noise glass through `f_vf_fieldmap`.

## Findings: versus "any height texture → f_vf_fieldmap" (2026-10-06, NumPy only)

Question raised by Matt: how is this different from an arbitrary, maybe symmetric, texture through
`f_vf_fieldmap`? Checked with `scratch/glass_vs_fieldmap.py` and `glass_vs_fieldmap_noinset.py` on the test
glass of `scratch/caustic_fidelity.py` (seed 7), scoring each route by the caustic it produces (scatter
emulation, 16 points per pixel). The fieldmap route is emulated from `docs/f-reference/f_vf_fieldmap.md`,
**not** run in Max.

- **Precision is not a differentiator.** The same height as an 8-bit (char) texture gives caustics almost
  identical to float32 through fieldmap (r 0.994–0.999 between them, at `scale` 0.012 and 0.024). The earlier
  idea that an exact gradient matters because 8-bit heights would be stepped is not supported.
- **The finite difference is not the issue either.** With the UV inset removed, fieldmap matches the analytic
  field (RMS error 0.8%) and the caustic (r 0.9999 at 1 d*, 0.9933 at 3.5 d*).
- **What does differ is the fieldmap's UV inset** (`suv = norm*(1-2s)+s`): it stretches the field in space by
  up to ±s, a 12.7% RMS field error at `scale` 0.012 (about double at 0.024), and caustic r drops to 0.93 at
  1 d* and 0.77 at 3.5 d* against the analytic field. It is a registration change, not noise: the result is a
  slightly different, equally valid glass. It matters only where the field must register with something else
  (the height outlet, a source feature, a second consumer built from the height directly).
- **The fieldmap gain range is enough** for this glass: the gain that recovers the physical gradient was 3.9
  at `scale` 0.012 (module range -10..10).

Consequence: a smooth float32 (or even 8-bit) height already makes a valid glass through the existing
`f_vf_fieldmap`, and a symmetric texture would give symmetric caustics **if it is smooth**. What an arbitrary
texture does not guarantee is smoothness (a hard edge is infinite curvature, and there is no blur module in
f_), and bounded curvature. So the genuinely new capability is a **smooth, evolving height generator**; the
vecfield outlet is a convenience (one pass instead of two, no inset, exact `focus`), not a quality gain.
The one thing a texture route cannot offer is regime normalisation, because that needs the generator's own
parameters; whether it is worth having is untested. The spec already carries a `height` outlet, so the
module can be used either way; the open design question is whether the vecfield outlet earns its place.

Not tested: textures with hard edges or noise, other glass seeds, a fieldmap run in Max.

## Open questions

- Does `jit.gl.bfg` have a usable time/third axis? (Refpage says two components; not checked in Max.)
- Time source for `evolve` (see Animation).
- Dual-mode: should an upstream scalar on in0 be added to the analytic glass as a base height, making the
  module a superset of the fieldmap use case? Not decided; keep out of v1 unless wanted.
- What is `focus` exactly: divergence (what `f_caustic` weights) or a Hessian determinant? The determinant
  needs a distance, so it belongs to a consumer; divergence is distance-free.
- Mode count and cost in a pix codebox, and `|F| <= 1` clipping behaviour at high `gain` (soft limit?).
- The one-frame lag of the scatter module against same-frame pix consumers (`optics_map.md`): visible on
  fast glass motion when warp and caustic share one glass.

## Verification plan (tiers, per the constitution)

1. **Math, NumPy mirror:** analytic gradient and Hessian against central differences of `h`; encode/decode
   round trip; periodicity for integer vectors; continuity of `h` in `phase`; if normalisation is adopted,
   the predicted `d*` against the photon-counting truth in `scratch/caustic_fidelity.py` (same glass family).
2. **Execution, test bench:** the real codebox against the mirror, every outlet, bypass passthrough
   (neutral field 0.5/0.5 on the vecfield outlet, black on scalars, per the 2026-10-05 convention).
3. **Judgement, scratch patch:** feed `f_vf_warp`, `f_vf_prism`, `f_caustic` and look; judge evolve rates,
   ranges and which families are worth keeping.

## Related

`f_lumia.md`, `optics_map.md` (map, caustic and scatter findings), `f_vf_fieldmap` (as built),
`f_chladni`, `f_cymascope.md`, `.specify/f_vf_glass/` (spec), `.specify/f_caustic_scatter/` (spec).
