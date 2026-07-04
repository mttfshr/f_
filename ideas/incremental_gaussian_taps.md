> **Author:** Claude, GPU Gems 3 research sweep (2026-07-03)
> **Status:** tabled — real, small, well-scoped optimization

# Incremental Gaussian tap computation — from GPU Gems 3 Ch. 40

Sparked by reading GPU Gems 3 Ch. 40 (Turkowski, "Incremental Computation
of the Gaussian") against `f_vf_glow`'s 48-tap loop and `f_vf_prism`'s
11-tap Gaussian blur.

## The chapter's technique

For a fixed-step tap loop that evaluates a Gaussian (or any smooth
exponential-family curve) at each step, replace the per-tap `exp()` call
with a **forward-differencing recurrence**: precompute a per-step
multiplicative update so each tap's weight is derived from the previous
tap's weight via one multiply, rather than a fresh transcendental
evaluation. Same output values, cheaper per-tap cost — no texture lookup
into a precomputed coefficient table needed either.

## Where this applies in `f_`

Both `f_vf_glow` (`w = exp(-i*i*falloff)`, 48 taps) and `f_vf_prism`
(11-tap Gaussian blur) call `exp()` fresh inside their per-tap loop today.
This is a direct drop-in optimization candidate for both — same math,
cheaper evaluation. Worth checking `f_vf_streak` and any other
fixed-tap-count accumulation loop for the same pattern.

## Status

Not urgent — this is a performance optimization, not a capability gap or
quality fix. Worth doing opportunistically next time either module's
codebox is open for other reasons (e.g. alongside the dual-curve profile
work already tabled in `ideas/glow_profile_and_afterimage.md`), rather
than as its own session.

**UNVERIFIED:** whether the recurrence-vs-`exp()` cost tradeoff is even
meaningful inside GenExpr/`jit.gl.pix` — GPU shader `exp()` cost
characteristics on this hardware/pipeline haven't been profiled, and
the constant-per-tap overhead in a 48-tap loop may or may not be
GPU-bound in the first place. Worth a quick before/after fps check if
ever pursued, not worth assuming the win without measuring.

## Cross-references

- `ideas/glow_profile_and_afterimage.md` (f_vf_glow's existing open threads)
- `ideas/gpu_gems_research.md` — Vol 3 Ch. 40 entry
