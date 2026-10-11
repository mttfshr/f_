# Spec: vecfield-aware UV warps (f_mobius, f_droste)

_Created: 2026-10-10. Expanded 2026-10-10 to cover f_droste (Matt's call: fold
it into this spec rather than leave it HANDOFF-only, once its conformality
was checked)._
_Status: Draft — both problems characterized and queued (Matt's call,
2026-10-10: "spec a corrected variant," not build either today). Not built,
not scheduled against the work queue in plan.md beyond the pointer at item 5._

---

## Problem (shared across both modules)

Both `f_mobius`'s and `f_droste`'s codeboxes (`src/f_mobius/definition.py`,
`src/f_droste/definition.py`) do a generic UV resample: `sample(in1, vec(uv_x,
uv_y, 0))`. Neither has a vector-aware special case. If a `f_vf_` vecfield
texture is piped into `in1` as though it were any other texture, its R/G
channels get carried to a new pixel location completely unmodified — the
field *value* is never rotated/scaled to match the local transform, even
though the transform itself is doing exactly that to everything else in the
frame.

The two modules differ enough in their math that they need different fixes
(see below) — this isn't one shared codebox change.

### f_mobius

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

Because both paths are conformal, the correct transform is a **complex
division** — see below.

### f_droste

Checked numerically in `tests/spike_droste_conformality.py` (2026-10-10,
finite-difference Jacobian against the real codebox — a hand-derivation
attempt first and got this wrong, worth remembering before trusting algebra
over a direct check next time):

- `f_droste` is **essentially never conformal**, for a more fundamental
  reason than its `twist`/`n_arms` params — its log-polar step scales the
  radial axis (`s`) by `1/log(zoom)` and the angular axis (`t`) by
  `1/(2*pi)`, two *different* constants whenever `log(zoom) != 2*pi` (zoom ≈
  535, far outside the UI's 1.1–100 range).
- Measured eccentricity at `zoom=2.0, twist=0, n_arms=1` (the one case a
  first-pass hand-derivation predicted was conformal) is a constant **9.065**
  everywhere — matches `2*pi / log(2)` exactly. Setting `zoom` so
  `log(zoom) == 2*pi` drives it to exactly `1.000000`, confirming the
  mechanism directly rather than by elimination.
- `twist`/`n_arms` add further anisotropy on top (measured 3.0–9.1x across
  the configs tried) but aren't the primary cause.
- One finite-difference artifact hit and fixed along the way: a test point
  sitting exactly on `atan2`'s branch cut gave a bogus 693x "eccentricity" —
  not a finding, a numerical artifact, caught by cross-checking against
  three other points before trusting the number.

Because the local map is a general (non-conformal) linear map, the correct
transform is a **full 2x2 matrix multiply**, not a complex division — see
below.

### f_poincare

**No codebox exists to check.** `ideas/f_poincare.md` is "Planned — not yet
specced." `plan.md`'s paused/blocked claim of "Phases 0–2 confirmed working,
closed-form {p,q} formula derived for {4,5}" did not correspond to any file
found in this repo; corrected in `plan.md` 2026-10-10 (Matt confirmed stale,
not lost elsewhere). By the idea doc's own design ("a group of Möbius
transformations," accumulated-matrix composition), it would likely be
conformal if built as pure Möbius composition — composition of conformal
maps is conformal — but that's inference from a design doc, not a verified
result, and shouldn't carry the same weight as the two findings above. Check
it the same way (finite-difference Jacobian against the real codebox) once
one exists, rather than trusting this inference.

## The correct transform, if built

### f_mobius (conformal — complex division)

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

### f_droste (non-conformal — matrix division)

Same pushforward rule, but since the local map isn't conformal, `g'(z)`
isn't a single complex number — it's a real 2x2 Jacobian `J(z)`, and the
carried vector is `v' = J(z)^{-1} · v` (an actual 2x2 linear solve, not a
scalar division).

`tests/spike_droste_conformality.py` computes `J(z)` via finite differences
(central difference, `h=1e-4`, straight against the codebox's own function)
— robust for a diagnostic, but **not yet reduced to a closed form**. The
codebox's `droste_T` is an explicit function of `(norm.x, norm.y)` via
`atan2`/`log`/`sqrt`/the `twist` shear, so an analytic Jacobian is tractable
by hand (ordinary chain rule, nothing exotic) — just not done as part of
this spec. Whoever builds this should derive it analytically rather than
evaluate 4 extra `droste_T` calls per pixel on the GPU (finite differences
are fine for a NumPy diagnostic, wasteful as a shipped codebox's per-pixel
cost).

## Open questions (resolve before building)

1. **New module, or a mode/second outlet on the existing modules?** The
   existing outlets' behavior (resample color/any texture) is correct and
   should not change — this is an *additional* capability, not a fix.
   Candidates:
   - A second outlet that only makes sense when a vecfield is connected to a
     *new* dedicated vecfield inlet (mirrors how `f_vf_warp` adds a
     `vecfield` mod inlet via `state_param`).
   - A standalone module per warp family (e.g. `f_vf_conformal_warp` for the
     `f_mobius` case), parallel to the existing module rather than bolted
     onto it, keeping `f_mobius`/`f_droste` purely color/texture processors.
   - Given `f_mobius` and `f_droste` need genuinely different math (complex
     division vs. matrix solve), a single shared module covering both seems
     unlikely to be the right shape — probably two separate pieces of work,
     not one.
   - Precedent check: no existing `f_` module both consumes and re-emits a
     vecfield through a geometric transform (`f_vf_warp` consumes a vecfield
     to displace a *texture*, but passes no vecfield through).
2. **Precision/cost near singularities.** `f_mobius`'s `invert` path:
   `g'(z) = -1/z^2` blows up the same way the forward map's own `1/z` does
   near `z=0` — the existing `mag_sq` guard (clamped to `0.0001`) already
   handles the forward sample; the derivative's guard needs the same
   treatment (squared again, so effectively a `1e-8`-scale floor) to avoid
   NaN/Inf on the GPU. Spiked in NumPy with a `1e-8` floor; not yet verified
   against GenExpr's actual float32 behavior at that range. `f_droste`'s log
   singularity at `r=0` has the same flavor of problem and isn't guarded in
   this spec's analysis at all yet.
3. **Is this wanted aesthetically, or just correct?** The naive (current)
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
- `f_poincare`'s own conformality — no codebox exists yet to check.
- An analytic (closed-form) Jacobian for `f_droste` — only the
  finite-difference version has been verified so far.

## References

- `tests/spike_mobius_vecfield_transform.py`, `scratch/mobius_vecfield_rotate_zoom.png`,
  `scratch/mobius_vecfield_invert.png` — the f_mobius characterization.
- `tests/spike_droste_conformality.py`, `scratch/droste_conformality_spike.png`
  — the f_droste characterization.
- `ideas/vector_field_math_concepts.md` #6, #10.
- `src/f_mobius/definition.py`, `src/f_droste/definition.py`,
  `src/f_vf_warp/definition.py` (precedent for a `state_param` vecfield mod
  inlet).
