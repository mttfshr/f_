# f_weave — orientation response to vecfield input

## Status: RESOLVED 2026-10-13 (Matt)

Decision, after the live scratch-patch A/B (`scratch/experiments/f_weave_orientation_ab/`):
**not a one-time pick between Fix A and Fix B — ship both, as live dials.**
`f_weave` now has `field_amount` (depth, 0–2, default 1.0 = original implicit
depth) and `fix_blend` (0 = Fix A/vector-add+renormalize, 1 = Fix B/true
angular blend via `atan2`, continuous between). This is "performable" by
design, per Matt — the A/B question turned out not to need a winner.
Shipped in `src/f_weave/definition.py`, regenerated, drift-clean. See
`docs/f-reference/f_weave.md` for the final algorithm.

The scratch patch stays in `scratch/experiments/f_weave_orientation_ab/` as
the record of how the two mechanisms were built and compared, not as a
live-vs-shipped reference anymore (the real module now has both built in).

## The observation
Matt fed `f_weave` a video→optical-flow vecfield on `in1`. Output was dense,
organic, scribble/hatching-like, and tracked scene structure — visually
strong, but felt "uncontrolled," specifically in **orientation response**
(not density/spacing, which felt fine).

## Root cause
The orientation block does vector addition + renormalize, not angular
blending:

```
cs = base_cs + (-vy); sn = base_sn + vx;
mag = sqrt(cs*cs+sn*sn); cs/=mag; sn/=mag;
```

Two problems:
1. Field contribution depth is implicit and fixed (ratio of unit base
   vector to ±0.5-range field vector) — not an exposed/dialable param.
2. Vector-add renormalization isn't proportional to angular difference —
   response isn't linear/predictable, and near-zero (flat/no-motion) field
   regions still get normalized into *some* direction rather than falling
   back cleanly to the base angle.

## Two candidate fixes, neither chosen

**A — exposed depth param, same mechanism.** Scale the field term before
adding (`field_amount` param). Minimal change, inherits the non-proportional
response behavior.

**B — true angular blend.** Compute field angle directly (`atan2` or
equivalent — verify availability/safety in GenExpr first, per
`jit-gen-codebox` skill conventions), circular-interpolate with the base
angle, weighted by depth and optionally by field magnitude (so flat regions
fall back to base automatically). More correct, bigger change to the block.

Matt was unsure which would feel better in practice — this is explicitly an
empirical question, not one to resolve by reasoning alone.

## Tensor-field framing (cross-ref, added 2026-10-11)
This bug is the structural case `vector_field_math_concepts.md` #9 names
directly: thread orientation has no sign — a fiber at 30° and one at 210°
are the same line — so vector-add + renormalize is fighting the
representation, not just the blend math. Fix B's `atan2`-based angular
blend is closer but still starts from a signed vector; the structurally
correct fix is the angle-doubled (2θ) encoding `f_tensorfield.md`'s
`f_tf_structure` producer already uses for exactly this reason — no sign
to normalize away in the first place. This doesn't settle which fix to
ship here (still the empirical A/B below). ~~Fix B and
`f_tensorfield.md`'s Open Question 6 share the identical blocker —
GenExpr `atan2` safety in `jit.gl.pix`, unverified in either place —
so whoever checks it first closes it for both files.~~ **Closed
2026-10-12: `atan2` verified GPU-safe on decoded sampled-texture input**
(`tests/spike_atan2_safety.py`, all four quadrants to 5.6e-7 rad,
branch cut correctly wrapped, half-angle and doubled round trip both
pass; one ±π convention quirk at the degenerate `Fy == 0, Fx < 0`
boundary — benign for blending). Fix B is unblocked; the live A/B below
is now purely the empirical taste question it always was.

## Next step
~~Scratch patch with both mechanisms wired side-by-side/switchable, same
video→flow source used in the original screenshot, A/B live before
committing to either.~~ Done 2026-10-13 — see Status above. No next step;
closed.

## Relationship to other open f_weave threads
This is a separate axis from the already-open orientation A/B naming
question elsewhere and from the sketchy/uncertainty perturbation idea
(`ideas/sketchy_uncertainty_perturbation.md`) — not a resolution to either,
a third independent thread.
