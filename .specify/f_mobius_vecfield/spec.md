# Spec: vecfield-aware f_mobius warp

_Created: 2026-10-10._
_Status: Draft — problem characterized and queued (Matt's call, 2026-10-10: "spec a corrected variant," not build it today). Not built, not scheduled against the work queue in plan.md yet._

---

## Problem

`f_mobius`'s codebox (`src/f_mobius/definition.py`) does a generic UV
resample: `effect_out = sample(in1, vec(uv_x, uv_y, 0))`. There is no
vector-aware special case. If a `f_vf_` vecfield texture is piped into `in1`
as though it were any other texture, its R/G channels get carried to a new
pixel location completely unmodified — the field *value* is never
rotated/scaled to match the local transform, even though the transform
itself (rotate+zoom path, or the `invert` path) is doing exactly that to
everything else in the frame.

Characterized in `tests/spike_mobius_vecfield_transform.py` (2026-10-10,
diagnostic only, no production code changed — see `HANDOFF.md`):

- Both of `f_mobius`'s paths are conformal (holomorphic): `rotate+zoom` is
  `g(z) = scale * e^{i*angle} * z`; `invert` is `g(z) = 1/z` (corrected from
  an initial misread as anti-holomorphic — `inv_x = zx/mag_sq, inv_y =
  -zy/mag_sq` is plain `1/z`, no conjugate flip). `z = norm - center`.
- At a representative rotate+zoom setting (45°, ~1.78x), the naive-vs-correct
  direction error is a **constant 45° everywhere** — exactly the rotation
  angle, since this path's derivative is a position-independent constant.
- On the `invert` path, the error is **position-dependent**, up to 180°
  (full reversal) near the transform's own singularity, with the correct
  field's local scale factor ranging from 2x out to 8192x across the tested
  domain as you approach the center.
- `f_droste`/`f_poincare` not yet characterized the same way as of this
  writing — their transforms are *not* guaranteed conformal (see Open
  Questions) and should not be assumed to behave like `f_mobius`.

## The correct transform, if built

For a point `z = output_norm - center`, `f_mobius` samples the source at
`uv = center + g(z)`. If a vecfield's X/Y channels (decoded to signed
`[-1,1]`, treated as a complex number `v`) are piped through the same
sample, the geometrically correct carried vector is:

```
v' = v_source(uv) / g'(z)
```

— the standard pushforward-of-a-vector-field-under-a-diffeomorphism rule,
`g'(z)` being the map's local complex derivative:

```
rotate+zoom:  g'(z) = scale * e^{i*angle}                (constant)
invert:       g'(z) = -1/z^2                              (position-dependent)
```

`v / g'(z)` is a complex division: `v * conj(g'(z)) / |g'(z)|^2`. Both
quantities are cheap to compute inline in a codebox (no transcendental
functions beyond what the existing codebox already uses for `rotate+zoom`;
`invert`'s derivative is a few multiplies).

## Open questions (resolve before building)

1. **New module, or a mode/second outlet on `f_mobius`?** The existing
   outlet's behavior (resample color/any texture) is correct and should not
   change — this is an *additional* capability, not a fix to the existing
   one. Candidates:
   - A second outlet on `f_mobius` that only makes sense when a vecfield is
     connected to a *new* dedicated vecfield inlet (mirrors how `f_vf_warp`
     adds a `vecfield` mod inlet via `state_param`).
   - A standalone module (e.g. `f_vf_conformal_warp`) that takes a vecfield
     in and a vecfield out, parallel to `f_mobius` rather than bolted onto
     it, keeping `f_mobius` purely a color/texture processor.
   - Precedent check: no existing `f_` module both consumes and re-emits a
     vecfield through a geometric transform (`f_vf_warp` consumes a vecfield
     to displace a *texture*, but passes no vecfield through).
2. **Does this generalize to `f_droste`/`f_poincare`, or is it `f_mobius`-
   specific?** Checked numerically 2026-10-10 (`tests/spike_droste_conformality.py`,
   finite-difference Jacobian against the real codebox, not symbolic algebra
   — a hand-derivation attempt first and got this wrong). Result: `f_droste`
   is **essentially never conformal**, for a more fundamental reason than
   `twist`/`n_arms` — its log-polar step scales the radial axis (`s`) by
   `1/log(zoom)` and the angular axis (`t`) by `1/(2*pi)`, two *different*
   constants whenever `log(zoom) != 2*pi` (zoom ≈ 535, far outside the UI's
   1.1–100 range). Measured eccentricity at `zoom=2.0, twist=0, n_arms=1`
   (the case a first-pass hand-derivation predicted was conformal) is a
   constant **9.065** everywhere — matches `2*pi / log(2)` exactly, and
   setting `zoom` so `log(zoom) == 2*pi` drives it to exactly `1.000000`,
   confirming the mechanism directly rather than by elimination. `twist`/`n_arms`
   add further anisotropy on top (measured 3.0–9.1x across the configs
   tried) but aren't the primary cause. Net effect: a vecfield-aware
   `f_droste` warp needs a full 2x2 matrix transform (`v' = J(z)^{-1} · v`),
   not a complex division — meaningfully different and heavier than the
   `f_mobius` case, and not a simple reuse of this spec's math.
   `f_poincare` has **no codebox yet to check** — `ideas/f_poincare.md` is
   "Planned — not yet specced" (Phase 0–2 claims in `plan.md`'s
   paused/blocked section don't correspond to any file found in this repo;
   worth flagging to Matt as a possible stale reference, not assumed
   correct). By the idea doc's own design ("a group of Möbius
   transformations," accumulated-matrix composition), it would be conformal
   *if* built as pure Möbius composition — composition of conformal maps is
   conformal — but that's inference from a design doc, not a verified
   result, and doesn't carry the same weight as the `f_mobius`/`f_droste`
   findings above.
3. **Precision/cost near singularities.** `invert`'s `g'(z) = -1/z^2` blows
   up the same way the forward map's own `1/z` does near `z=0` — the
   existing `mag_sq` guard (clamped to `0.0001`) already handles the forward
   sample; the derivative's guard needs the same treatment (squared again,
   so effectively a `1e-8`-scale floor) to avoid NaN/Inf on the GPU. Spiked
   in NumPy with a `1e-8` floor on `|g'(z)|^2`; not yet verified against
   GenExpr's actual float32 behavior at that range.
4. **Is this wanted aesthetically, or just correct?** The naive (current)
   behavior is not "broken" in the sense of looking wrong by accident — it's
   a different, currently-undocumented visual character (arrows point a
   fixed source-space direction regardless of local warp). Worth deciding
   whether the corrected version is additive (a new, more "physically
   coherent" look) or whether the naive version already serves whatever use
   case prompted piping a vecfield through a UV warper in the first place —
   no concrete downstream use case motivated this yet; it came from reading
   the Wikipedia vector-field/tensor-field articles (`ideas/vector_field_math_concepts.md`
   #6/#10), not from a module needing it.

## Not in scope here

- Building any of the above.
- `f_droste`/`f_poincare`'s own conformality — tracked as a separate
  diagnostic pass (`tests/spike_droste_vecfield_transform.py` or similar, if
  it turns out `f_droste`'s general case is interesting enough to spike the
  same way).

## References

- `tests/spike_mobius_vecfield_transform.py`, `scratch/mobius_vecfield_rotate_zoom.png`,
  `scratch/mobius_vecfield_invert.png` — the characterization this spec is built from.
- `ideas/vector_field_math_concepts.md` #6, #10.
- `src/f_mobius/definition.py`, `src/f_vf_warp/definition.py` (precedent for a
  `state_param` vecfield mod inlet).
