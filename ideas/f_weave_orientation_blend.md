# f_weave — orientation response to vecfield input

## Status: open, needs a live scratch-patch A/B before deciding

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

## Next step
Scratch patch with both mechanisms wired side-by-side/switchable, same
video→flow source used in the original screenshot, A/B live before
committing to either.

## Relationship to other open f_weave threads
This is a separate axis from the already-open orientation A/B naming
question elsewhere and from the sketchy/uncertainty perturbation idea
(`ideas/sketchy_uncertainty_perturbation.md`) — not a resolution to either,
a third independent thread.
