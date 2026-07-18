# Idea: anamorphic vecfield displace/distort module (name TBD)

_Created: 2026-07-15_
_Status: Idea — graduated out of `f_lens` v2 scope, not yet named, not specced_

---

## Origin

Originally planned as part of `f_lens` v2 (see `.specify/f_lens/spec.md`
git history / `plan.md` ADR-6 for the full discussion). Pulled out after
a design conversation established:

1. **Static anamorphic** (fixed axis + squeeze ratio) is a real,
   non-redundant degree of freedom versus `f_lens`'s existing
   `distortion`/`distortion_mod` — a mod-texture can vary warp
   *magnitude* spatially (e.g. an angled sine WFG into `distortion_mod`
   produces directionally-patterned warp *strength*), but at any given
   pixel the existing distortion math is always isotropic (`warp_cx`
   and `warp_cy` share the same multiplier). Anamorphic squeeze is a
   *constant* per-axis scale ratio applied uniformly everywhere — a
   structurally different thing, not a spatial variant of what
   `distortion_mod` already does.
2. Despite being non-redundant, `f_lens` was judged "already very full
   of expressive potential" — Matt's call, 2026-07-15 — and the
   field-driven variant specifically needs a **vecfield inlet**, a
   signal type nothing else in `f_lens` uses, which is a structurally
   closer match to the `f_vf_` consumer family (`f_vf_warp`,
   `f_vf_streak`) than to `f_lens`'s own radial-optical character.
3. Decision: **both variants** (static + field-driven) move out
   together into their own module, rather than splitting static-stays/
   field-driven-leaves. One module owns the whole "anamorphic" concept;
   static is just the `field_amt=0` case of the same mechanism.

---

## Concept

A UV displace/distort processor providing anamorphic-style directional
squeeze — static (fixed axis + ratio) and field-driven (vecfield inlet
biases the squeeze axis per-pixel) in one module.

**Static half** — same math as would have gone into `f_lens`:
per-axis multiplier on a `(1.0 + k*r2)`-style radial scale, applied
along a chosen axis instead of uniformly.

**Field-driven half** — vecfield inlet (`f_vf_` consumer family
convention: `"vecfield in"` label, nabla in `f_modules` menu) biases the
static axis. Mechanism already worked out during the `f_lens` design
conversation (2026-07-15), reusable here directly:

1. Convert the static axis param to a unit vector:
   `theta = axis * pi; static_dx = cos(theta); static_dy = sin(theta);`
2. Decode the vecfield per `f_vecfield` convention (RG=XY, 0.5=zero):
   `field_dx = (sample(vf_in,uv).x - 0.5)*2.0; field_dy = (sample(vf_in,uv).y - 0.5)*2.0;`
3. **Hemisphere-align the field vector to the static axis before
   blending** — a squeeze axis is a *line*, not a direction (0° and
   180° mean the same thing), so the field vector needs to be flipped
   toward the "short way" before blending, or a naive angle-blend can
   land on the wrong side of the wraparound:
   `align = step(0.0, static_dx*field_dx + static_dy*field_dy) * 2.0 - 1.0;`
   `field_dx = field_dx * align; field_dy = field_dy * align;`
4. Blend the two *vectors* by `field_amt`, then re-derive the final
   angle via `atan2` — sidesteps the angle-wraparound discontinuity
   entirely, since vector blending has no discontinuity the way angle
   blending does.
5. Use the final angle to drive the per-axis squeeze multiplier.

---

## Rough param contract (candidate, not locked)

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `squeeze` | -1..1 | 0.0 | Squeeze amount (bipolar, per the library's current direction on aberration/distortion/etc. — confirm this convention still applies once this module is actually specced). |
| `axis` | 0–1 | 0.0 | Static squeeze axis angle, same wrap convention as `f_lens`'s old `tilt_axis`. |
| `field_amt` | 0–1 | 0.0 | Vecfield inlet's influence on axis. 0 = static axis only. 1 = axis fully field-driven. |

Names are placeholders — no naming-collision check done yet, no
`gain`/`mix` convention check done yet (this module has no
composite/blend outlet as currently conceived, so that convention may
not even apply — confirm when specced).

---

## Open questions (unresolved — this is an idea file, not a spec)

- **Module name.** Deferred (Matt's call, 2026-07-15). Something in the
  `f_vf_` family, per the consumer-family reasoning above.
- **Chain position / archetype.** Processor, presumably — needs upstream
  texture. Confirm against the two established archetypes in
  `vsynth-bpatcher/SKILL.md` once specced.
- **Does this want its own radial distortion math at all, or should it
  purely be a squeeze layer that composes with `f_lens` downstream/
  upstream in a chain** (i.e., no redundant `distortion`-style base warp
  of its own, just the anisotropic scale)? Not decided — the mechanism
  above assumes a `(1.0+k*r2)`-shaped base, but that was inherited
  wholesale from the `f_lens` design context, not re-derived for this
  module's own identity.
- **Relationship to `f_vf_warp`** — `f_vf_warp` is already "UV warp via
  f_vecfield" in the README's module table. Worth checking directly
  whether this new module is meaningfully different from `f_vf_warp`
  before speccing it as a separate thing, or whether it's actually a
  mode/extension of `f_vf_warp` itself. Not checked yet.
