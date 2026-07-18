# Implementation Plan: f_vf_optical_flow

_Date: 2026-07-17_
_Spec: .specify/f_vf_optical_flow/spec.md_

---

## Summary

`f_vf_optical_flow` is a new vecfield-producing module implementing
single-scale Lucas-Kanade optical flow. Replaces the ruled-out cheap
frame-diff + `f_vf_fieldmap` approximation (see spec.md Clarifications
and `ideas/f_vf_optical_flow.md`'s Scratch test result). Built as a
4-node `pix_chain`: one previous-frame feedback pair plus a 3-stage
forward chain (gradients → windowed sum → solve). Confirmed to fit the
existing `build_patcher.py` schema with no new capability needed,
unlike `f_focus`.

---

## Architecture Decisions

### ADR-1: Real Lucas-Kanade over the cheap approximation

**Context:** Frame-diff + `f_vf_fieldmap` was scratch-tested live in
Max and produced no coherent motion-following behavior. Root cause
identified, not just observed: `f_vf_fieldmap`'s gradient is
perpendicular-to-contour, correct for a height-field scalar; an
accumulated diff trail's meaningful direction is tangent-to-trail — a
structural mismatch, not a tuning gap.

**Decision:** Build real Lucas-Kanade — a 2×2 linear system per pixel
solved from spatial+temporal gradients over a local window — since it
directly derives velocity rather than inferring direction from a diff
blob's shape.

**Consequences:** Larger build than the ruled-out approach — 3 forward
stages instead of a single diff codebox, plus the one genuinely new
technique in the library (windowed multi-term accumulation). Already
flagged as the most computationally expensive module in the family if
built to full spec.

### ADR-2: Confidence as a separate outlet, not a bundled channel

**Context:** Lucas-Kanade's 2×2 system is singular or near-singular in
flat/textureless regions (the aperture problem) — no existing `f_vf_`
consumer reads a 3rd channel of a vecfield texture.

**Decision:** Output the solve's matrix determinant as its own scalar
outlet, separate from the `(u,v)` vecfield outlet.

**Consequences:** Zero changes required to any existing `f_vf_`
consumer. Mirrors `f_vf_split`'s existing precedent of extracting scalar
information out of/alongside a vecfield as its own outlet. Any future
masking/suppression logic that consumes this confidence signal is
explicitly out of scope for this module (see spec.md Out of Scope) —
this module only produces the signal.

### ADR-3: Single-scale only, pyramid explicitly deferred

**Context:** Real Lucas-Kanade implementations often use a
coarse-to-fine image pyramid to handle large frame-to-frame
displacements; single-scale LK only sees small motions reliably within
its window.

**Decision:** Ship single-scale only for a first version. Pyramid is a
much larger undertaking — deliberately named and deferred, not silently
assumed away.

**Consequences:** If Phase 3 testing shows fast motion breaks down (the
expected failure mode for single-scale LK), that's a known, documented
next step (pyramid), not a surprise gap requiring re-scoping from
scratch.

### ADR-4: 4-node `pix_chain`, one shared previous-frame loop

**Context:** Initially assumed each stage might need its own feedback
loop (mirroring the ruled-out approach's 4-pix build, which had two
separate feedback pairs — one for frame-diff, one for accumulation).

**Decision:** Only Stage A needs a previous-frame feedback loop, since
`It = current − previous` is computed inside Stage A itself. Stages B
and C are purely forward — they consume the immediately-prior stage's
fresh output each frame, no feedback of their own.

**Consequences:** Total node count is 4: `pass_pix` (previous-frame
identity) + Stage A + Stage B + Stage C — same total as the ruled-out
attempt, restructured around real math instead of a diff-blob gradient.

### ADR-5: `pix_chain` schema confirmed sufficient — no new build-system capability needed

**Context:** `f_focus` needed a new `primary_object` schema mode because
its render object wasn't a `jit.gl.pix` at all. Worth checking whether
this module hits a similar gap before assuming it doesn't.

**Decision:** Read `build_pix_chain()` in `build_patcher.py` directly
(not assumed from memory/pattern-matching). Confirmed: `pix_wires` is
an unrestricted list of `[src_id, src_out, dst_id, dst_in]` tuples, with
no limit to a single feedback loop or a fixed chain shape. This module
is built entirely from `jit.gl.pix` codeboxes (unlike `f_focus`'s native
`jit.fx` object), so it fits the existing schema as-is.

**Consequences:** No `build_patcher.py` changes required before writing
`definition.py`, once stage codeboxes exist.

---

## Dependency Blocks

### Block 0: Stage A scratch test (Phase 0 of spec.md)
**Dependencies:** None — reuses only already-confirmed techniques
(`f_vf_advect`'s feedback pattern, `f_vf_fieldmap`'s central-difference
idiom).
**Builds:** `pass_pix` + `stage_a_pix` scratch patch computing
`Ix`/`Iy`/`It`.
**Verification:** Per spec.md Phase 0 acceptance criteria — renders
standalone, all three outputs visibly respond to motion, feedback loop
confirmed via draw order.

### Block 1: Windowed sum (Phase 1 of spec.md)
**Dependencies:** Block 0
**Builds:** `stage_b_pix` — 5×5 windowed accumulation of five per-pixel
products (`Ix²`, `Iy²`, `IxIy`, `IxIt`, `IyIt`).
**Verification:** Per spec.md Phase 1 acceptance criteria — compiles
without hitting the capture-group ceiling at 5×5 (fallback: split into
sub-stages, don't hand-optimize the math first); five sums spot-checked
against a manually-computed expectation on a simple test pattern.

### Block 2: Solve + confidence (Phase 2 of spec.md)
**Dependencies:** Block 1
**Builds:** `stage_c_pix` — closed-form 2×2 solve for `(u,v)` plus
matrix-determinant confidence output.
**Verification:** Per spec.md Phase 2 acceptance criteria — `(u,v)`
loads into `f_vf_fieldmap`'s expected format with no adapter;
confidence visibly near-zero in flat regions, higher in textured
regions; determinant range checked empirically before any
normalization decision.

### Block 3: `definition.py` and full build
**Dependencies:** Blocks 0–2 all individually confirmed correct as
standalone scratch-tested codeboxes.
**Builds:** Full `.specify/f_vf_optical_flow/definition.py` using
`pix_chain`/`pix_wires`, standard Vsynth wrapper (routepass, autopattr,
bypass, moduleSize.js), confidence as a genuine second outlet (per
ADR-2 — check whether `build_patcher.py`'s `outlets` mechanism already
supports a non-`jit_gl_texture` outlettype for a scalar confidence
signal, or whether that itself needs a small schema check before
assuming).
**Verification:** JSON validation, then Max load.

### Block 4: Real-consumer wiring and expressive verification (Phase 3 of spec.md)
**Dependencies:** Block 3
**Builds:** Nothing new — wiring into an existing consumer
(`f_vf_warp` recommended, per spec.md).
**Verification:** Visual judgment of whether flow reads as
motion-following, not just numerically plausible. This is the phase
that actually answers whether the module succeeded.

### Block 5: f_modules registration and docs
**Dependencies:** Block 4 confirmed working
**Builds:** Category entry (likely alongside other `f_vf_` vecfield
producers), `SIZES` dict entry, `.maxhelp` file, README update.
**Verification:** Appears correctly in `f_modules` menu; loads cleanly.

---

## Complexity Notes

This is a larger build than anything else currently in the `f_vf_`
family — already flagged in the idea file as the most computationally
expensive module if built to full spec. The real complexity is
concentrated entirely in Block 1 (windowed sum) — Blocks 0 and 2 reuse
known-good techniques (central-difference gradients, closed-form 2×2
solve), and Block 1 is the one place genuinely new ground is being
broken in this library. Treat Block 1's capture-group ceiling risk as
real, not hypothetical — the `jit-gen-codebox` skill's documented
"split, don't debug the math" response should be the default plan if
it bites at 5×5, not a last resort.
