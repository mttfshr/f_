# Spec: f_focus

_Created: 2026-07-15_
_Status: Draft — not yet built_
_Origin: `ideas/f_lens_tiltshift_split.md` (tabled architecture question,
resolved this session) + `.specify/f_lens/spec.md` v2 Clarifications_

---

## Clarifications

### Session 2026-07-15

- Q: Split or don't split tilt-shift out of `f_lens`? → A: Split. Real
  precedent: `f_stereogram`→`f_sirds` rename logic — name matches where
  the module is going, not just what it does today.
- Q: Name? → A: `f_focus`, not `f_tiltshift` — leaves room to grow past
  the gradient-band character into other focus-blur approaches (Phase 2
  below) without a second rename later.
- Q: Blur engine — keep `jit.fx.cf.tiltshift`, add a second GenExpr mode,
  or replace outright? → A: Phased. **Phase 1**: keep
  `jit.fx.cf.tiltshift` as-is, near-mechanical port from `f_lens`.
  **Phase 2**: add content-driven focus-map gather-blur (GPU Gems Ch. 28
  recipe) as a second mode alongside it, not a replacement — same
  "complementary, not superseding" relationship as `f_vf_streak`/
  `f_vf_glow`. Matt confirmed this phasing 2026-07-15.
- Q: Does `f_lens` keep a lightweight tilt-shift after the split? → A:
  No — full extraction. `f_lens` v2 spec removes `tilt`/`tilt_axis`/
  `tilt_pos`/`mode`/`slope` and the `jit.fx.cf.tiltshift` object
  entirely (see `.specify/f_lens/spec.md` v2 Scope).

---

## Phase 1 — Tiltshift extraction (near-mechanical port)

Straight port of the tilt-shift architecture already built and
confirmed working inside `f_lens` v1. No new capability, no new
verification of the underlying mechanism — just a new bpatcher shell
around the existing proven object.

**Chain position:** Processor — same position `f_lens`'s tilt-shift
occupied. Sits between any source and downstream display layer.

**Object:** `jit.fx.cf.tiltshift` — confirmed working in the Vsynth
context during `f_lens` Phase 0 (see `.specify/f_lens/spec.md` Session
2026-05-27 clarifications). No jit.gl.pix codebox needed for Phase 1 —
this is a single native object plus standard Vsynth wrapper (routepass,
route, autopattr, bypass toggle, moduleSize.js).

### Parameters (ported directly from f_lens v1)

| Param | Range | Default | jit.fx param | Description |
|-------|-------|---------|--------------|-------------|
| `blur` | 0–1 | 0.0 | `blur_amount` | Focal plane tilt — amount of tilt-shift blur. 0 = uniform focus. |
| `axis` | 0–1 | 0.0 | `angle` | Angle of the tilt band across the frame. 0 = horizontal, 0.5 = vertical, wraps. |
| `pos` | 0–1 | 0.5 | `center` | Position of the sharp band along the tilt axis. 0.5 = center of frame. |
| `mode` | enum | linear | `mode` | Focus shape — linear (band across frame) or radial (focus falloff from center point). |
| `slope` | 0–1 | 0.5 | `slope` | Sharpness of the transition from sharp to blurred. Low = gradual, high = abrupt. |
| `bypass` | 0/1 | 0 | — | Standard bypass — raw texture passthrough. |

Param names shortened from `tilt`/`tilt_axis`/`tilt_pos` (f_lens
namespacing, which needed the `tilt_` prefix to disambiguate from other
effect families sharing the module) to `blur`/`axis`/`pos` — `f_focus`
has no other effect families to disambiguate against, so the shorter
names read cleanly on their own. Confirm no collision with Vsynth
reserved param names before building (per the `active`/`length`/`width`
collision class documented in `jit-gen-codebox` skill).

**Acceptance criteria (ported from f_lens v1):**
- All params at default → passthrough
- `blur` swept with `axis` at 45° → visible sharp band crossing the
  frame diagonally, blurring above and below it
- `axis` rotates band angle; `pos` moves band position along that axis
- `mode` switches between linear (band) and radial (falloff from
  center) character
- Bypass passes raw texture unaltered
- Loads in Vsynth, composes cleanly upstream/downstream of other f_
  bpatchers, including in place of where `f_lens`'s tilt-shift used to
  sit in existing chains

**Inlets:** Single inlet (in1, texture + control) — no surface/field
texture inlets needed, this is a pure screen-position-driven effect
with no spatial modulation input in Phase 1.

---

## Phase 2 — Content-driven focus-map gather-blur (not yet scoped in detail)

Tracked here as a placeholder; real architecture/build planning deferred
until Phase 1 ships. Recipe already researched — see
`ideas/f_lens_tiltshift_split.md` Addendum (2026-07-03), GPU Gems 3 Ch.
28 (Hammon).

**Core idea:** a per-pixel scalar "circle of confusion" (CoC) map — in
`f_`'s case, synthetic (no depth buffer), sourced from a settable
screen-space focus point/distance, an arbitrary mod texture, or
potentially an `f_vf_` scalar-potential output — drives a variable-width
gather blur. Second mode alongside Phase 1's `jit.fx.cf.tiltshift`, not
a replacement.

**Known unresolved before this can be scoped as a real phase:**
- **CoC source** — which of the three candidate sources (radial
  distance-from-point, arbitrary mod texture, `f_vf_` scalar input)
  ships in v1 of this mode, vs. deferred.
- **Variable-radius blur cost** — whether GenExpr exposes any mip/LOD
  control for cheap variable-radius sampling, or whether this needs a
  fixed max-tap-count loop sized for the worst case. Real unknown,
  needs an empirical scratch test before committing to the architecture
  — same "test the cost model before believing it" instinct as the
  parked Jacobi diffusion scratch-test item.
- **Foreground-bleed fix** — the two-pass CoC-blur-then-combine
  algorithm (`D = 2*max(D0, DB) - D0`) is a multi-stage `pix_chain`
  (CoC blur pass → combine → image gather-blur pass), comparable in
  build weight to `f_vf_advect`/`f_vf_seeds`, not a single codebox.
  Chapter's own caveat: doesn't fully eliminate discontinuity artifacts,
  only dampens them — set that expectation honestly if built.

**Not blocking Phase 1.** Phase 1 ships as a complete, working module on
its own; Phase 2 is additive.

---

## Out of Scope (This Version)

Nothing else currently proposed for `f_focus` beyond the two phases
above. If other focus/depth-of-field techniques surface (e.g. from
further GPU Gems research), they'd be evaluated as additional modes
under the same "complementary, not replacing" pattern.
