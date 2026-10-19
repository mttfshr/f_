# Implementation Plan: f_tf_glyph

_Date: 2026-10-17_
_Spec: .specify/f_tf_glyph/spec.md_
_Triage: ideas/f_tf_triage.md (build order 2 of 6, confirmed 2026-10-17)_

---

## Summary

`f_tf_glyph` is the tensor family's first consumer: a stateless, essentially
single-stage `pix` renderer drawing one closed-form glyph per grid cell, decoded
in-pixel from tensormap outlet 0. No loops in the glyph math; the only bounded
iteration is the cell lookup (collapses to arithmetic under a jitter-free grid, see
ADR-4). It is the validator for the per-consumer decode path and the family's debug
view, and **its plan is where the canonical decode idiom is written down** for
sharpen, aniso_blur and hatch to copy.

```
in0 (raw tensor, f_tf_tensormap outlet 0) ─┐
in1 (source texture, tint) ────────────────┤→ stage_glyph (decode → gate → closed-form draw) → out0
params ────────────────────────────────────┘
```

Risk is low and mostly visual: the decode math has independent ground truth
(`np.linalg.eigh`), the axis math reuses tensormap's stage C verbatim, and the
draw is one rotation plus a smoothstep — `f_weave`'s mark-rendering pattern
(`ideas/f_vf_seeds.md` §"Mark rendering") applied in a rotated cell frame. The open
questions are judgment calls (variant menu, tint behavior, gain-free vs
gain-scaled radius), i.e. tier-3 questions, plus one small plan-level fork (ADR-4/5).

## Technical Context

**Environment:** Max 9, Vsynth, `jit.gl.pix` gen codeboxes, `@type float32` throughout.
**Build method:** NumPy mirror (tier 1) → codebox on the bench (tier 2) → scratch
patch (tier 3) → `src/f_tf_glyph/definition.py` → `build/build_patcher.py`.
**Codebox budget:** well under the ~450-statement capture ceiling
(`skills/jit-gen-codebox`) — this design is naturally tiny; if it ever approaches
the ceiling the design is wrong, not the budget.
**Encode contract:** `docs/f-reference/f_tensor_type.md` outlet 0 (cited, never
re-derived in code comments beyond the decode block itself).
**Producer:** `docs/f-reference/f_tf_tensormap.md`; tensormap plan ADR-5 (bench GPU
wraps out-of-range reads → clamp sample coords to texel centers in-shader) and
ADR-6 (eps_trace neutral rule) are inherited behaviors.
**Lookup precedent:** `ideas/f_vf_seeds.md` — nearest-seed solve and "sample the
field at the seed position, not the pixel".
**Decode precedent:** `jit.fx.cf.kuwahara` in-consumer eigen decode, cited with
source evidence from `ideas/f_tf_jitfx_audit.md` §2.1.
**GPU budget:** M3 Max measured, M1 unmeasured (ways-of-working); expect tensormap
stage-C-class cost (closed form, one texture read of the tensor per cell center
plus the source tap).

## Files

```
.specify/f_tf_glyph/
  spec.md             done
  plan.md             this file
  tasks.md            next to this file
  codebox_glyph.gen   Phase 1 (single codebox; name under the module-prefix convention)
  definition.py       Phase 3

tests/
  test_tf_glyph.py    tier 1 NumPy mirror: decode + aspect/axis + gate + draw       (Phase 0)
  bench_tf_glyph.py   tier 2, real codebox on the GPU                               (Phase 1)

~/Vsynth/patterns/ (not in repo)
  tf_glyph_scratch.maxpat   tier 3 judgment — variants, tint, debug modes          (Phase 2)

docs/f-reference/
  f_tf_glyph.md       as-built reference                                            (Phase 5)
```

## Architecture Decisions

### ADR-1: Single-stage, closed-form codebox; no chain

**Context:** tensormap needed four stages because smoothing is a windowed sum.
Glyph needs one tensor read at a cell center, a closed-form eigen solve, and a
closed-form distance test. No accumulation, no neighborhood of texture samples
beyond the lookup.

**Decision:** One `pix` codebox does everything: cell lookup → decode → gate →
draw. If the tint pass proves to want un-tensor inputs handled separately, it
stays inside the same codebox (it is two more statements); a second stage is added
only if the bench says the combined compile struggles, which is not expected.

**Rationale:** Every extra stage is a capture hop and a bench cycle for zero math
benefit. The tensormap chain argument (ADR-1 there) applies to windowed sums; this
is not one.

**Consequences:** Internal/external boundary is trivial; only the final stage
exists, and it is the only clamp point (family hard rule: stage outputs unbounded
float32, final stage clamps/encodes).

### ADR-2: The canonical decode idiom lives HERE, in this file

**Context:** Triage review 2026-10-17 confirmed per-consumer in-pixel decode; no
`f_tf_decode` module; the name is retired. Later consumer plans (sharpen,
aniso_blur, hatch) need one authoritative text to copy instead of three ad-hoc
variants.

**Decision:** This plan owns the idiom. Canonical text (decode block, with the
strength-cancellation identity, the axis-unoriented property, and the θ+180°
symmetry caveat):

```gen
// in: t = sample(tensor_tex, clamp(cell_uv_to_texel))   // tensormap ADR-5 clamp
// encoding: f_tensor_type.md outlet 0 — R>=0 G:0.5=zero B>=0 A=1 (all × strength)
Jxx = t.r / strength;  Jxy = (t.g - 0.5) * 2.0 / strength;  Jyy = t.b / strength;
trace = Jxx + Jyy;  diff = Jxx - Jyy;  root = sqrt(diff*diff + 4.0*Jxy*Jxy);
lambda1 = 0.5*(trace + root);  lambda2 = 0.5*(trace - root);
theta = 0.5 * atan2(2.0*Jxy, diff);      // GRADIENT axis (across the edge); along = theta + pi/2
// Gain-free identities (strength is a common factor on R, G-0.5, B):
//   tan(2*theta) = 2*(t.g-0.5)/(t.r - t.b);   aspect = (trace+root)/(trace-root)
// CAVEAT: 0.5*atan2 confines theta to (-pi/2, pi/2]; a near-vertical axis
// decodes sign-flipped. Safe ONLY for consumers symmetric to theta+180°
// (glyphs, blur, hatch, sharpen, coherence). Sign-sensitive consumers must
// route through f_tf_axisflow (f_tensor_type.md consumer rule 2).
```

**Rationale:** C74's own consumer decodes per-frame in-shader
(`jit.fx.cf.kuwahara`; audit §2.1: `lambda1/2 = 0.5*(l0±l1)`, `A=(l1−l2)/(l1+l2)`,
`phi = −atan(t.y,t.x)`). The three-line closed form does not justify an adapter
module, and the brief's own "adapters become the interface" warning (`f_tf_tensor_strategy.md`)
says no. Recording it once here keeps the family's copies verbatim-checkable.

**Consequences:** Later plans cite this file by path; if a future tensormap v2
ever grows a decoded outlet, this idiom becomes the migration spec for it (a doc
change, not a consumer rewrite — consumers keep working, the idiom note gets a
"prefer the outlet" line).

**ADR-2 amendment (2026-10-17, tier-2 bench findings — three live GPU facts):**
1. **Runtime `atan2(0,0)` returns NaN on this GPU** (compile-time literals fold to 0;
   runtime (0,0) does not — probe: bisect read theta=NaN at jxy2_s = diff_s = 0.0 at every
   dim). The constant-isotropic tensor (Jxx = Jyy, Jxy = 0 — any flat, noise-free content)
   rendered an all-black frame while the mirror drew fine. A `mix()`-based guard CANNOT clear
   it (NaN·0 = NaN arithmetic; GenExpr has no `isnan()`). The codebox fix is a `+1e-7` bias
   on the atan2 denominator argument — (0,0) never reaches atan2; where the bias matters the
   tensor is near-isotropic (aspect ≈ 1), the ring is rotation-invariant, and the swung angle
   renders identically. The mirror carries the equivalent guard.
2. **`sample()` is NOT bilinear when its coordinate is data-dependent and jumps** — the
   cell-lattice read (tu teleporting 1/grid per cell step) dropped the sampler to nearest
   (the cell (2,6) read texel (22,90) pure where the mirror's bilinear read a blend; worst
   diff 0.98). Fixed with the skill doc's four-tap `nearest()` hand-bilinear idiom (tensor
   read AND tint read). First draft of that fix passed RAW texel indices as tap coords —
   wrong: `nearest()` takes normalized texel-center coords, same as `sample`.
3. **Residual GPU-vs-mirror after fixes: 2.3e-4 at the 49-tap extreme** — the hardware's own
   interpolation weights are 8-bit (skill: "median 2e-5, max 1.2e-4" per read; this kernel
   stacks several reads). Bench tolerance aligned (2e-4 class); invisible in render.

These are family property, not glyph trivia: sharpen's decode is atan2-free by design
(unaffected); hatch hits the same huge-argument-sine ceiling in its line hash and its bench
documents it; aniso_blur's marched taps are the same data-dependent-jump class (its bench
runs green with pinned params). Consumers copy the AMENDED idiom text above, not the earlier
draft.

### ADR-3: Inlet contract is outlet-0-exact, enforced by docs/helpfile

**Context:** Nothing mechanically distinguishes tensormap outlet 0 from outlet 1
or from a vecfield at the inlet — same float32 texture class. The rejected-
alternative history (`f_tensorfield.md`, audit) is precisely about lookalike
encodings.

**Decision:** Inlet 0 expects outlet 0's encoding exactly (`f_tensor_type.md`);
any encoding mismatch is a wiring error, handled the way the family handles it:
an explicit contract line in the reference doc and helpfile (and the tensormap →
glyph wiring as the canonical demo chain), NOT a runtime sniff. Outlet 1's packed
R/G would decode to a doubled angle here — visibly wrong, self-diagnosing, but
never blessed.

**Rationale:** Adding a magic-byte/tag scheme is a type system the family does not
have and `signal_type` tagging (tensormap T030) already covers documentation at
the header level.

**Consequences:** Test fixtures build outlet-0-format textures; the bench tests
decode from that format only.

### ADR-4: Jitter-free grid; cell center = arithmetic lookup (no neighbor search)

**Context:** `f_vf_seeds` runs a bounded 3×3 nearest-seed search because its seeds
jitter. `f_tf_glyph` does not (currently) promise jitter, and the spec's "no
loops" claim is a hard family rule.

**Decision:** Cells are a uniform `grid × grid` lattice over the frame: cell
center = `(floor(p * grid) + 0.5) / grid`, no texture-space search, no loop at
all. `jitter` stays out of v1. If a future revision wants jitter, the correct
mechanism is the bounded 3×3 search (`f_vf_seeds.md` Q4 precedent) as a v2
change with its own ADR — not baked in speculatively.

**Rationale:** An exact lattice is also easier to mirror exactly in NumPy
(tier 1), and removes the one place a loop could sneak in.

**Consequences:** Glyph field is a perfectly regular lattice — visually stiffer
than a jittered one but honest; judged in tier 3 (if Matt wants organic
placement, that is the v2 trigger).

### ADR-5: Aspect from the eigenvalue ratio; radius `scale`-driven, gain-free (provisional, tier-2/3 confirm)

**Context:** Spec OQ3 — absolute eigenvalues (gain-scaled glyph size, honest
about gradient energy) vs ratio-only aspect with a performer `scale` (gain-free,
stable across tensormap `strength` changes).

**Decision (provisional):** `aspect = clamp(sqrt(lambda1/lambda2), 1, max_aspect)`
and glyph radius comes from `scale × cellsize`, not from absolute λ. The decode
therefore needs NO `strength` echo param and stays correct when Matt re-gains
tensormap live. sqrt because eigenvalues are intensity². Guard λ2 ≤ epsilon →
aspect clamps to `max_aspect` (thin line, drawn only if gate passes).

**Rationale:** The gain-free identity in ADR-2 makes ratio-only decode
parameter-free and mirror-simple; absolute-λ sizing would re-couple this module
to tensormap's calibration dial, which is exactly a coupling the family's
producer/consumer split should not have. The absolute-λ alternative stays
recorded here and is the fallback if tier 3 says size-meaning matters
(`scale` may then become λ1-driven with a gain param).

**Consequences:** Glyph density of marks communicates anisotropy via aspect only;
absolute strength is invisible (a coherent-but-faint edge draws a strong glyph).
Tier-3 task T-…-… checks whether that reads wrong on real content.

### ADR-6: Gate inherits the eps_trace convention; neutral is no-mark

**Context:** Where the tensor is ~zero, θ is undefined (tensormap ADR-6 already
forces a neutral at the producer). A consumer must not resurrect an angle from
noise below the producer's own epsilon regime.

**Decision:** A cell draws only if decoded trace ≥ `gate` (a live param,
default provisional ~0.05 pre-gain units, tuned in tier 3). Below it: nothing
drawn (neutral background), with the isotropic-but-traceable
case (λ1≈λ2, trace ≥ gate) drawing an aspect-1 circle. The gate threshold is a
renderer-local aesthetic control; tensormap's eps_trace stays the producer's
correctness floor. No new convention is invented — this is `f_weave`'s
draw-or-not smoothstep philosophy applied to a confidence signal.

**Rationale:** The spec's failure mode ("pushed toward isotropic, axis-dependent
consumers get an undefined direction everywhere and fall back to their own
neutral — circle / no-mark", `f_tf_expressive_consumers.md` §f_tf_sharpen
failure modes) is exactly this; it was designed in, not patched later.

**Consequences:** `gate` to 0 on a live-noise source will fill the screen with
noise-orientation glyphs; the tier-2 mirror asserts the mathematical behavior,
tier 3 asserts the aesthetic. **Unconnected-wire hazard (coordination with
f_tf_aniso_blur, 2026-10-17):** an all-zeros texture (0,0,0,0) — what an
unconnected wire carries, distinct from tensormap's bypass output (0,0.5,0,1) —
decodes via the outlet-0 G offset to Jxy·s = −1, giving λ1 = 1, λ2 = −1 (non-SPD)
with a plausible atan2 orientation. Glyph is incidentally safe because decode
trace is still 0 < `gate` (no-mark). This is an inlet-neutral, not a decode
change; energy-gated consumers (f_tf_aniso_blur's `strength_scale` gate on
λ1·scale) cannot rely on trace and need an explicit SPD check — their plan owns
that guard, cited adapted from `f_tensor_type.md` consumer rule 5.

### ADR-7: Inlet order = tensor first (in 0), source second (in 1); source absence renders untinted

**Context:** Spec fixes tensor-as-primary in principle; actual inlet order and
the unconnected-source behavior are plan-level.

**Decision:** in 0 = raw tensor (driving, required; unconnected → empty render,
gated to nothing), in 1 = source for tint (vs_black fallback → glyphs render in
their neutral ink, geometry unaffected). Matches the discrete-item convention
(`f_vf_seeds.md`: vecfield primary on in 1 there because "in 0 is
control/texture" is the Vsynth convention — here the tensor IS the driving
texture, so it takes in 0 and control rides with it, tensormap-style).

**Rationale:** Primary-content-first mirrors `driving_inlet`; source-tint is
auxiliary by design (spec: geometry must never depend on it).

**Consequences:** Tint pass reads in 1 at the cell center too (one luma/color
tap); no fallback chain beyond the vs_black neutral.

### ADR-8: Variant and debug-mode plumbing built shape-generic, menu shipping deferred

**Context:** Spec OQ1/OQ2: variant menu and debug tints are open questions, not
param promises.

**Decision:** The codebox implements the ellipse distance exactly, but is written
so a cross/tick distance function is a self contained branch (compile-time
`#define`-style constant in the codebox for the bench, not a live param) so
tier 3 can flip variants by editing one constant and rebuilding the scratch
patch's codebox — no live-menu plumbing exists until the decision closes.
Debug tints, if tier 3 wants them, likewise enter as a scratch-only constant
first.

**Rationale:** Satisfies both "cheap shape-function swap"
(`f_tf_expressive_consumers.md`) and "no param until it earns it"
(UI-density discipline, `mod_depth_ui_density.md` context) without deleting
the exploratory option.

**Consequences:** The shipping codebox in Phase 4 contains the decided variant
only; the scratch builds may carry extra branches that never enter `src/`.

### ADR-9: Verification tiers

**Decision (recorded as the Phase 0 gate, TG001):**
- **Tier 1 (NumPy mirror): applies.** Decode has independent ground truth
  (`np.linalg.eigh` on the decoded tensor), analytic ramps give known θ and
  aspect, and the cell lattice is exactly mirrorable. Also verifies the
  gain-free identity and the gate behavior numerically.
- **Tier 2 (bench): applies.** One real codebox to compile; border/clamp
  behavior (tensormap ADR-5) must be re-confirmed for THIS module's cell-center
  sampling; cost measured (a single cell-center tap makes it trivially cheap,
  but it is still recorded, not assumed).
- **Tier 3 (scratch patch): applies.** Glyph look, variant choice, tint
  behavior, `gate`/`grid`/`scale`/`thickness`/`softness`/`max_aspect` defaults
  and the legibility-through-smooth/sharpen debug role are all judgment.

**Consequence:** Test discipline as always: one affected test at a time, `-q`,
background via `tests/bg.sh`; **ask before any bench run** (ways-of-working).

## Dependency Blocks

### Block 1: Decode + draw math settled in NumPy
**Dependencies:** none
**Builds:** `tests/modules/tf_glyph/test_tf_glyph.py` — mirror of the ADR-2 decode, ADR-4 lattice,
ADR-5 aspect, ADR-6 gate, and the ellipse cover function; ground truth
`np.linalg.eigh`, analytic ramps, gain-free identity check, one mutation check.
**Verification:** eigh agreement, ramp angles, aspect ratios, gain-invariance,
gate floor; one injected bug caught.

### Block 2: Codebox on the bench
**Dependencies:** Block 1
**Builds:** `codebox_glyph.gen`, `tests/modules/tf_glyph/bench_tf_glyph.py` (registered in
`tests/lib/benchdeps.DATA`; not in `bench.sh DEFAULT` until Matt makes it a gate).
**Verification:** compiles well under the statement budget; matches the mirror
channel-by-channel incl. border cells (texel-center clamp confirmed for cell
sampling); bypass/unconnected behaviors; per-pass cost at 1080p/4K recorded.

### Block 3: Judgment on real content (tier 3)
**Dependencies:** Block 2
**Builds:** `~/Vsynth/patterns/tf_glyph_scratch.maxpat` only — variants
(ellipse/cross/tick via the ADR-8 constant), tint behavior, debug-tint
feasibility, all default values, legibility as a debug sidecar behind
`f_tf_smooth`/`f_tf_sharpen` when those exist in a scratch rig.
**Verification:** Matt-judged look; variant/debug-mode open questions close here
or are explicitly deferred; provisional params become real or the spec says why.

### Block 4: Patcher
**Dependencies:** Block 3 (param values from the gate); contract questions from
Block 2
**Builds:** `src/f_tf_glyph/definition.py`, generated `package/patchers/f_tf_glyph.maxpat`,
modules-menu registration, contract tests, drift check, live load check.
**Verification:** loads in Vsynth; params addressable; bypass/unconnected
neutrals; drift-clean; contract tests green.

### Block 5: Docs and handoff
**Dependencies:** Block 4
**Builds:** `docs/f-reference/f_tf_glyph.md` (with the decode idiom restated as
the citation target for later consumers), README/status-table/inventory rows,
constitution naming entry if needed, helpfile + preflight, `HANDOFF.md`.
**Verification:** module-preflight gate incl. content judgment; hub/triage
cross-links updated so sharpen/aniso_blur/hatch can cite the idiom.

## Implementation Phases

### Phase 0: Gates + tier-1 mirror (BLOCKING)
Record the tier gate (TG001) and write/verify the NumPy mirror: decode, lattice,
aspect, gate, ellipse cover; ground truth via `np.linalg.eigh` + analytic ramps +
gain-free identity; mutation check. Exit: mirror agrees with ground truth; one
injected bug is caught.

### Phase 1: Codebox on the bench (BLOCKING)
Write `codebox_glyph.gen` against the mirror; compile; bench diff channel-by-channel
incl. border cells; confirm clamp behavior for cell-center taps; measure cost at
1080p/4K and register the bench file. Exit: matches mirror on the GPU; borders exact;
cost recorded; statement budget confirmed comfortably under the ceiling.

### Phase 2: Scratch patch, judgment tier
Variants via ADR-8 constants; tint behavior; debug-tint feasibility; calibrate
`grid`/`scale`/`thickness`/`softness`/`gate`/`max_aspect` defaults; the
debug-sidecar check. Exit: every spec Open Question 1/2/3/4 decided or explicitly
deferred with a reason; spec defaults replaced by confirmed values.

### Phase 3: definition.py and build
Read the tensormap `definition.py` first (the family's own precedent for params,
routing, bypass, wiring); write `src/f_tf_glyph/definition.py`; build; validate
JSON; register in the modules menu; drift check; contract tests; **ask before any
bench run**; live load in Vsynth. Exit: shipped patcher, clean, live-confirmed.

### Phase 4: Integration check without downstream consumers
Prove the producer→consumer path end to end: `jit.gl.bfg → f_tf_tensormap →
f_tf_glyph` as the canonical demo chain; rotate the input 90° and confirm glyph
rotation; dial tensormap `strength` and confirm glyphs do NOT change (ADR-5
gain-free path). Exit: the chain is the reference wiring captured in the docs.

### Phase 5: Docs and handoff
Reference doc (carrying the canonical decode idiom), helpfile + preflight,
README/inventory/constitution rows, triage/hub cross-links, HANDOFF. Exit: sharpen/
aniso_blur/hatch plans have a citation target for the decode idiom and a reference
wiring to copy.

## Out of this plan

- All sibling consumer modules (sharpen, aniso_blur, hatch, mix) and any chain
  assembly beyond the single demo wiring in Phase 4.
- Tensormap changes of any kind (incl. the hypothetical v2 decoded outlet).
- A shared decode module (`f_tf_decode` is retired by decision; do not resurrect).
- `jitter` on the glyph lattice (v2 change with its own ADR if ever wanted).
- Live variant/debug-mode params (only if Block 3's gate says they earn it).