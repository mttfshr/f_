# Stochastic "uncertainty" perturbation for hand-drawn character — from GPU Gems 2 Ch. 15 (Blueprint Rendering and "Sketchy Drawings")

Sparked by reading GPU Gems 2 Ch. 15 (Nienhaus/Dollner) against `f_weave`.
Narrow, single-idea finding — general enough across the discrete-item and
line-rendering family that it's worth its own note rather than living
only against one module.

## The chapter, briefly

Two bundled techniques. Blueprint Rendering extracts 3D silhouette/
border/crease edges via normal-buffer and depth-buffer discontinuity
detection (a G-buffer technique — no fit for f_, same 3D-scene mismatch
as the Ch 39 / Ch 42 reads: needs real geometry, camera, normal buffer,
depth buffer, none of which exist in f_'s pure 2D pipeline).

Sketchy Drawing is the relevant half: once edges and surface-color
patches exist, apply spatially-varying **"uncertainty"** — random
image-space perturbation, applied non-uniformly rather than as a single
global jitter amount — to roughen them so they read as hand-drawn rather
than mechanically precise.

## Why the useful part doesn't need the rest of the chapter

The uncertainty concept doesn't actually depend on Blueprint Rendering's
3D edge-extraction machinery. It's a general NPR trick: take line/mark
parameters that would otherwise be uniform or smoothly-varying (width,
position, opacity, edge crispness) and perturb them with spatially-varying
noise, non-uniformly across the image rather than as one global amount.
Anything in f_ that already draws procedural lines or marks — where the
geometry is computed directly rather than extracted from a rendered scene
— can use this without any of the surrounding chapter's machinery.

## Where it's relevant

- **f_weave** — dense procedural line/hash geometry
  (`dist_to_line`/`dist_to_mark` smoothstep gates, per HANDOFF). Perturbing
  line width/position/opacity with a small per-mark hash-driven jitter
  would add hand-drawn character. Explicitly a **different, additive**
  control from the already-open orientation A/B question (vector-add-
  renormalize vs. true angular blend, vecfield-driven) — orientation is
  about directional response to flow, this is about stylistic precision
  vs. roughness of individual marks. Not a resolution to that question,
  a separate axis.
- Plausibly relevant to any other line/mark-drawing module in the
  discrete-item family (`f_vf_seeds`, `f_grain`) if a "hand-drawn" or
  "imprecise" character is ever wanted there — same mechanism, same
  cheap cost (a hash-driven perturbation on existing geometry params, no
  new rendering pass).

## What "non-uniform" actually buys over a single jitter param

The chapter's specific framing — apply uncertainty *non-uniformly*, not
as one global jitter amount — is the detail worth holding onto. A single
global "roughness" dial makes everything equally imprecise. Non-uniform
application (varying the perturbation amount spatially, or per-mark via
hash) reads as more genuinely hand-drawn, since real sketching isn't
uniformly shaky — some strokes are more confident than others.

## Status

Tabled. No scratch patch, no code. Cheap to test whenever `f_weave` (or
another line/mark module) is next touched — small, additive, doesn't
block or depend on the orientation A/B decision.

## Open questions to resume with

- Per-mark hash-driven perturbation (deterministic, stable frame-to-frame)
  vs. per-frame noise (animated, shimmering unsteadiness)? Different
  character — worth an A/B before committing, consistent with the
  scratch-patch-before-code working style.
- Which params benefit most: width, position, opacity, or some
  combination? Chapter's framing (edges *and* surface color patches both
  get uncertainty) suggests both geometric and tonal perturbation matter,
  not just one axis.
- Does this want to be a single "sketchy"/"uncertainty" param, or does it
  decompose into more specific controls once tried live?
