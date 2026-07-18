# f_vf_optical_flow — Idea

_Last updated: 2026-07-17_
_Status: Concept — cheap frame-diff approximation tested and ruled out (structural reason, see below); real Lucas-Kanade-style optical flow is the only remaining path if this gets built, not yet specced_

## What it does

Estimates the motion field between two consecutive frames of an input texture and outputs it as an f_vecfield. Turns any animated texture into its own flow field — the field reflects where image content is moving, not an analytically defined geometry.

## Why it's interesting

Every other f_vf_ generator produces fields defined by parameters or input scalar textures. f_vf_optical_flow produces a field that is *derived from motion in the image itself* — the field is emergent from the source content rather than imposed on it. Feeding this back into f_vf_warp or f_vf_glow creates self-referential effects where the image's own movement drives its distortion.

Also useful for connecting live video or external texture sources into the f_vecfield pipeline — camera input, video playback, generative animation all become field sources automatically.

## Approach

Lucas-Kanade or Horn-Schunck optical flow — both implementable in a jit.gl.pix gen shader, though neither is trivial.

**Simpler approximation: frame difference as flow proxy**
Temporal difference between frame T and frame T-1, treated as a flow magnitude. Doesn't give true directional flow but is cheap and visually interesting. Requires ping-pong texture (Pattern 1 from temporal_synthesis_architecture.md).

**True optical flow (Lucas-Kanade)**
Computes spatial and temporal gradients, solves for per-pixel velocity. More correct, more expensive, requires multiple render passes. Likely needs the multi-pix bpatcher pattern.

Start with the frame difference approximation; upgrade to true optical flow if the approximation is insufficient.

## Proposed signal flow

```
in0 (texture / control) — animated source texture
out0 (f_vecfield — estimated motion field)
```

## Params

- `strength` — scales output field magnitude
- `smoothing` — spatial smoothing of estimated field (reduces noise)
- `bypass`

## Key design questions

- **Frame difference approach: TESTED AND RULED OUT 2026-07-17** — see Scratch test result below. Fieldmap's gradient-of-a-blob is structurally the wrong direction to extract from an accumulated trail (perpendicular-to-contour, not tangent-to-trail); not a tuning problem, a real dead end for this specific approach.
- **True optical flow:** significant complexity, multiple render passes, may need `pix_chain` architecture. Now the only remaining path if this module gets built at all — the cheap approximation has been tested and found insufficient, for a specific structural reason (see below), not just "didn't look good."
- **Temporal state:** requires storing previous frame — confirmed pattern from f_vf_advect; known-good in the build system.

## Notes

- True optical flow is a significant build — scope carefully before committing.
- Most computationally expensive module in the f_ family if built to full optical flow spec — performance implications at Vsynth resolutions need evaluation.

## Scratch test result (2026-07-17): frame-diff + fieldmap approximation ruled out, with reason

Tested the proposed cheap chain live in Max: `source → diff_pix (abs(cur-prev), pass_pix feedback) → accum_pix (decay/inject accumulation, accum_pass_pix feedback) → f_vf_fieldmap → f_vf_advect → CORNERPINS`. Frame-diff and accumulation stages built and wired correctly (confirmed against `f_vf_advect`'s two-pix feedback pattern, including the correct `jit.gl.pix` outlet numbering — rightmost outlet is always `dumpout`, not a data outlet, a real point of confusion corrected mid-session). Result on the actual displayed output (post-`Advect`, not the intermediate vecfield preview): **not visually interesting, no sense of coherent motion-following** — described by Matt as "not interesting yet, maybe wrong elements in the chain."

**Root cause identified, not just a tuning failure:** `f_vf_fieldmap`'s gradient computes a vector pointing from dim toward bright — i.e. *perpendicular* to the contours of whatever scalar blob it's given, the correct derivation for a height-field-like scalar where "which way is uphill" is the meaningful question. An accumulated motion trail is a different kind of shape: its meaningful direction is its *long axis* — tangent to the trail, not perpendicular to its edges. Gradient-of-a-blob instead gives vectors pointing toward/away from the trail's brightest ridge — "attraction toward recent change," not "which way did the content move." This is a structural mismatch between what a trail shape means and what `f_vf_fieldmap` was built to extract from a scalar field, not something fixable by tuning `decay`/`injection`/`gain` — the *direction* itself is the wrong kind of answer, regardless of magnitude tuning.

**Conclusion: the frame-diff + fieldmap approximation is a dead end for actual flow direction**, for this specific structural reason (not "wasn't tuned enough," not "wrong parameters"). It may still have value as its own distinct effect — an "attraction toward recent on-screen change" behavior — but that's a different aesthetic than optical flow and would need to be pursued on its own terms, not as a flow proxy, if ever revisited.

**This is why real optical flow (Lucas-Kanade or similar) is now the path forward if this module gets built at all** — it directly solves for per-pixel velocity via spatial+temporal gradient correlation, rather than deriving a direction from the shape of an accumulated diff blob, so it doesn't inherit this structural problem. Confirmed as the harder, multi-pass build already flagged above; no shortcut around that complexity remains once the cheap approximation is ruled out for the reason above. Not started — this file remains concept-only until Lucas-Kanade gets speced out for real.

## Lucas-Kanade architecture (2026-07-17, discussion only — not yet built or scratch-tested)

Real Lucas-Kanade genuinely derives motion direction rather than inheriting the frame-diff/fieldmap structural mismatch above: for each pixel, assumes a small local window moves with uniform velocity between frames, and solves a 2×2 linear system built from spatial gradients (`Ix`, `Iy`) and the temporal gradient (`It`) within that window:

```
[ΣIx²   ΣIxIy] [u]   [-ΣIxIt]
[ΣIxIy  ΣIy² ] [v] = [-ΣIyIt]
```

**Mapping onto known-good techniques in this pipeline:**
- Previous frame — the confirmed `pass`/`state` feedback pattern from `f_vf_advect`, no new technique.
- `Ix`/`Iy` (spatial gradients) — central-difference sampling, same idiom `f_vf_fieldmap` already does.
- `It` (temporal gradient) — `current - previous`, literally the frame-diff codebox already built during the ruled-out scratch test. Not wasted work — a real ingredient here, just not sufficient alone the way it was in the ruled-out approach.
- Windowed summation (Σ over a local neighborhood) — the one piece with no existing precedent in the library. Multi-tap sampling itself is known-good (`f_vf_glow`/`f_vf_prism` blur loops already do this); summing several different products across the same neighborhood for LK's five accumulator terms is the new part.
- 2×2 linear solve — trivial once the five sums exist; closed-form (Cramer's rule), a few lines.

**Proposed 3-stage `pix_chain`** (plus the existing previous-frame feedback loop, so 4 pix objects total, same shape-of-solution as the ruled-out attempt's 4-pix build, different math):
- **Stage A** — compute `Ix`, `Iy` (central difference on current frame) and `It` (current − previous); output as an intermediate texture.
- **Stage B** — windowed-sum stage: tap a neighborhood of Stage A's output per pixel, accumulate `Ix²`, `Iy²`, `IxIy`, `IxIt`, `IyIt`. The stage most likely to hit the GL2→GL3 capture-group ceiling, depending on window size.
- **Stage C** — solve the 2×2 system per-pixel from Stage B's five sums, output `(u,v)` as the vecfield. Also computes the determinant of the 2×2 matrix as a natural confidence signal (near-zero exactly where the solve is unreliable — see Confidence output below).

**Decisions locked 2026-07-17:**
1. **Window size: 5×5** (25 taps). Chosen as a real working size rather than starting minimal — larger windows give smoother, more noise-resistant flow at higher per-pixel cost; back off to 3×3 only if the GL2→GL3 capture-group ceiling actually bites in Stage B (per `jit-gen-codebox` skill's documented ceiling-avoidance approach — split the stage further rather than debug the math if params gray out or the pix goes invalid).
2. **Confidence/mask output: yes.** The 2×2 system is singular or near-singular in flat, textureless regions (the classic aperture-problem failure mode) — no gradient information to solve from, so LK produces garbage there. Rather than let that garbage pass through untagged, Stage C outputs the matrix determinant (or a normalized version of it) as a confidence value alongside `(u,v)`, so downstream `f_vf_` consumers (or a future masking stage) can suppress/attenuate flow in unreliable regions instead of it silently contaminating the field.
3. **Single-scale only, no pyramid.** Real LK implementations often use a coarse-to-fine image pyramid to handle large frame-to-frame displacements (single-scale LK only sees small motions reliably within its window). Pyramid explicitly out of scope for a first build — much larger undertaking, deliberately deferred rather than silently assumed away. If single-scale proves too limited for fast motion once tested, pyramid is the documented next step, not a surprise gap.

**Not yet decided / not yet touched:**
- Exact output signal shape — does confidence ride as a 3rd/4th channel of the same vecfield-typed texture (`x, y, confidence, ...`), or as a separate scalar outlet? Vsynth's `f_vf_` outlet convention (plain `"vecfield"` label, standard 2-channel x/y encoding) doesn't currently have a precedent for a bundled confidence channel — worth checking against `f_vf_split`'s scalar-extraction convention before deciding, since confidence-as-extractable-scalar is conceptually adjacent to what that module already does in reverse.
- Whether Stage A should use current-frame-only gradients or an average of current+previous (Horn-Schunck-style averaging reduces noise, but is a refinement on top of core LK, not required for a first version).
- No scratch test yet — this is architecture discussion only, not yet tried in Max.
- No `definition.py` — not clear yet whether this needs a new `pix_chain` schema capability beyond what `f_vf_advect` already established, or fits within it. Worth checking once stage boundaries are more concrete.
