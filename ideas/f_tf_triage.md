# f_tf triage — one verdict per catalog item

_Created: 2026-10-17. Status: Phase 1, awaiting review before any `.specify/` work._
_Inputs: `ideas/f_tf_build_brief.md` (§4 catalog, §5 ranked chains, §6 open questions),
Phase 0 findings `ideas/f_tf_jitfx_audit.md` (shipped-Look coverage), and the ranked-chain
reasoning in `f_tf_expressive_consumers.md`._

_Verdict vocabulary, per the brief: **build as proposed** / **kill — redundant** /
**merge** / **defer**._

---

## Operators

**`f_tf_smooth` — build as proposed, first.** Phase 0 found a shipped temporal filter
(`jit.fx.tp.filter`, source-read: the same two-pole recurrence over MRT feedback, storage-
agnostic channels), so the *math* is stock — but nothing shipped is a one-knob performable
tensor-space smoother with float32 guarantees and the family's neutral conventions, and the
family's own precedent (`f_vf_temporal_smooth`, parked in `ideas/`) is to re-shape base
recurrences into semantic modules rather than adopt color-pipeline tools. Every chain in §5
consumes it; video flicker is the whole family's blocker (brief OQ2); cost is negligible.
Caveat carried into its spec: the audit must be cited, and the honest framing repeated —
the contribution is semantics/integration, not algorithm.

**`f_tf_sharpen` — build as proposed, second wave.** Open ground at the platform level
(audit §3: eigen-gap operators unheard of); closed-form and trivial; every renderer's
character shifts with it (the brief's "most leveraged gesture"). Nothing to kill or merge.
Sequence after `f_tf_smooth`, not before: sharpening a flickery tensor amplifies its coherence
noise (the brief's own floor-gate concern), so the stabilizer should exist first.

**`f_tf_mix` — build, but explicitly against Open Question 7, not before two real consumers.**
The audit's closest-to-shipped finding: component-wise xfade of two float32 textures *is*
tensor-space mixing (math identical to stock `co.xfade` etc.). The legitimate reasons to build
it are guarantees, not math: family float32 @type, the `vs_black`-decodes-to-garbage-axes
neutral handling (stock xfades would silently mix invalid c2/s2 when one side is unconnected),
and family labeling. Its ranked position (last among operators) stands: chain B — its main
consumer — also depends on `f_tf_authored`, which is UI-blocked. Defer-building is wrong (it
has unique semantics); defer-*building-now* is right. Concretely: spec after smooth/sharpen/
glyph exist, when chain B is actually being assembled.

## Render / filter consumers

**`f_tf_glyph` — build as proposed, second overall.** Nothing ships anywhere near it (audit
§2.3: the ecosystem has no tensor/eigen readout at all; `ge.flowfield` draws flow lines via a
geometry shader, which gen cannot even produce). Purest full-tensor consumer, closed-form,
cheapest, and the debug tool all other modules will be tuned through. Brief's revision stands:
second after smooth, since it decodes *something stable*.

**`f_tf_hatch` — build as proposed, but its Phase 0 gate is the cost-shape question (brief
OQ1), not the shipped-look question.** The look is confirmed open ground (audit §2.4: no
hatching/stipple/halftone shipped; `ge.lineinterp`/`ge.randlines` are line primitives from
point data, not orientation-field renderers). Open Question 1 (stroke-marching vs
`f_weave`-style tileable distance-field pattern) stays its first blocking task, decided by a
NumPy spike + cost estimate, not by this triage.

**`f_tf_glint` — defer, with the view-in-disguise flag unresolved, not merely "flagged".**
Phase 0 strengthens the kill case: the shipped analog (`f_lens` halation/ghosts, radial)
already demonstrates the dial-width-lobe look locally, and a dial is exactly what makes glint
a view wearing a tensor costume (brief's own flag). Nothing in the chains requires it: chain
C's `glint` slot is satisfied by `aniso_blur`'s elliptical accumulation until the per-pixel
coherence-width design proves itself. Revisit only if/when a live rig actually wants it —
the flag converts to a gate: build only with per-pixel coherence lobe width.

**`f_tf_glow — build last, or merge into Q12 (the parked `f_vf_glow` anisotropy inlet).**
Borderline as the brief says. Phase 0 adds one fact in favor of building our own: shipped glow
is either isotropic (`co.glow`, source-read: composite formula only) or 3D-world-only
(`jit.gl.pass` bloom, unusable in Vsynth bpatcher chains) — the *local* stack
(`f_vf_glow`/`f_vf_streak`) is the only field-following glow. But that same fact supports the
*cheaper* path: `f_vf_glow` already runs the bounded bidirectional loop; Q12's parked design
(anisotropy inlet scaling its existing weights) delivers most of the gesture at near-zero
build cost. Decision gate, not a verdict I should pick alone: **merge with Q12's parked
`.specify/f_vf_glow` tasks unless chain B/C live-testing shows the tensor-inlet shape (radius
∝ eigenvalue, weight ∝ coherence, both) is materially different from Q12's gate-only
anisotropy scaling.** Not specced in this phase either way.

## Producers from non-image sources

**`f_tf_jacobian` — defer, spike-only.** Open ground (audit §2.5: no field-derivative anything
ships), and chain C (its consumer) is the brief's own lowest-priority chain, blocked on
`f_vf_fluid` being wired as a force source. No consumer exists to validate the output against
yet — the brief's OQ3 asks exactly this, and the answer is: spend one NumPy spike worth of
effort only when chain C is being assembled. Keep the curl-scalar split (non-symmetric part)
in the spike scope so the decision is made with full information.

**`f_tf_motion` — defer behind a one-line contract check; then it joins `f_tf_jacobian`'s
spike.** Chain D is camera-adjacent (performable in a show right away) but its producer
`f_vf_optical_flow` is confirmed (brief: standard vecfield out0 + confidence out1 — gateable).
Same logic as jacobian: no renderer validated yet. The one thing worth doing *now* is recording
the confirmed output contract in the eventual spec's header (done: it's in the brief), so the
defer doesn't rot.

**`f_tf_hessian` — defer, but pre-load a consumer anchor.** Open ground (audit §2.5: 
`cf.laplace` is literally the collapsed trace-view of the idea — nice contrast for the spec's
tensor-native paragraph). But no chain includes it (§5 chains A-D all run on structure-tensor
or motion sources), and `f_vf_potential` as first input is itself unwired-to-consumers.
Same consumer-existence test as jacobian/motion. Anchor: chain C expansion.

**`f_tf_authored` — defer with an explicit UI-density decision gate.** The brief's flag is
correct and Phase 0 doesn't change it: chain B (`engraving instrument`) wants it, but it
inherits the paused `mod_depth_ui_density.md` question (a hand/LFO-swept analytic field is
"new dials on an already-dense panel" territory). Interim, non-blocking, per the expressive-
consumers doc: the **zero-code interim** (LFO-swept analytic tensor patched from whatever
cheap source) can be tested in a scratch patch during any consumer's tier-3 phase, without
building this module. Gate: when chain B is assembled, ask Matt whether `f_tf_authored`
unblocks the paused UI question or waits for it.

## The architecture question

**`f_tf_decode` (centralized eigen decode) — resolve the question in the first spec, not by
building the module.** Phase 0's finding is decisive precedent rather than proof: C74's own
only tensor consumer, `jit.fx.cf.kuwahara`, decodes eigenvalues/coherence/angle **per-consumer,
in-shader, every frame** from a raw tensor texture (source-read: `lambda1/2 = 0.5*(l0±l1)`,
`A = (l1−l2)/(l1+l2)`, `phi = −atan(t.y,t.x)` — three lines of closed form). A dedicated
module adds a pipeline hop plus another adapter — exactly the "adapters become the interface"
failure the strategy note warned about. **Recommendation: per-consumer in-pixel decode, no
`f_tf_decode` module; the first consumer spec (f_tf_smooth or f_tf_glyph) records the decode
idiom in its plan so the second consumer copies it.** If per-consumer decode proves noisy at
review, the fallback (a new third outlet on tensormap, λ1/λ2/θ/coherence) is a tensormap
v2 question, not a new module — name `f_tf_decode` never becomes a module name unless triage
review overrides this.

## Kill / merge summary

- **Kill: none.** The platform audit found no shipped duplicate for anything in the catalog
  (the kuwahara look-duplication precedent doesn't trigger: its tensor is untouchable, and
  nothing else in `jit.fx`/`jit.*` ships an anisotropic, tensor-input, or eigen-based look).
- **Merge candidates: exactly one** — `f_tf_glow` into the parked Q12 design, conditional
  (see above). Everything else stands alone.
- **Deferred: `f_tf_glint`** (flagged view, unconditional defer), **`f_tf_jacobian`,
  `f_tf_motion`, `f_tf_hessian`** (no consumer yet; spike-on-demand), **`f_tf_authored`**
  (UI-density gate + zero-code interim). Deferred items stay in the catalog with their entry
  conditions written down; none is killed.

## Build order this triage proposes (unchanged from brief §5, now confirmed)

1. `f_tf_smooth` (first; every chain needs it; carries the decode idiom)
2. `f_tf_glyph` (second; validator + debug tool)
3. `f_tf_sharpen` (closed-form; after stabilizer)
4. `f_tf_aniso_blur` (the standout look; curved-axis design question is its own Phase-0 gate)
5. `f_tf_hatch` (cost-shape gate first: OQ1)
6. `f_tf_mix` (when chain B assembles; needs `f_tf_authored` decision)

Open questions 2-6 of the brief are all resolved by the above ordering (each is a
sequence question), with OQ7 (decode) resolved as "per-consumer, record the idiom in
consumer specs." Open question 1 (hatch cost shape) stays open as hatch's own Phase-0 gate.

## What review should confirm or override

1. `f_tf_glow`: merge-with-Q12 vs build-tensor-in — the one verdict needing Matt's call.
2. `f_tf_mix` deferral timing (spec after two consumers exist) vs building it early as the
   operator-proving module.
3. The per-consumer decode recommendation (OQ7) vs a tensormap v2 third outlet.
4. Whether the three deferred producers (jacobian/motion/hessian) should get their NumPy
   spikes now (cheap, parallel) or strictly on-demand.

## Review outcome (2026-10-17, Matt)

All four recommendations confirmed:

1. **`f_tf_glow`: merge-with-Q12** — folded into the parked `f_vf_glow` anisotropy-inlet
   design rather than a new module; revisit only if live A/B against the gate-only version
   proves the full tensor-inlet shape materially different.
2. **`f_tf_mix` deferral timing stands** — spec when chain B assembles.
3. **Per-consumer decode confirmed** — no `f_tf_decode` module; the name is retired unless a
   later review reopens it; consumers record the decode idiom in their plans (first: glyph).
4. **Producer spikes stay strictly on-demand** — jacobian/motion/hessian get NumPy spikes only
   when their chains are assembled.

Phase 2 proceeds on the confirmed build order: smooth → glyph → sharpen → aniso_blur → hatch
(with its OQ1 cost-shape gate) → mix (with chain B). Spec/plan/tasks triads go into
`.specify/<module>/` mirroring the tensormap structure; per-consumer decode idiom and the
jitfx-audit citations are carried into every spec.

## Phase 2 outcome (2026-10-17)

Five triads written, none built:

- `.specify/f_tf_smooth/` — two-domain state+render feedback (advect precedent), one-pole
  release-only; ADR-3 no-clamp feedback write; bypass-as-passthrough (not freeze).
- `.specify/f_tf_glyph/` — plan ADR-2 is the **family's canonical decode idiom**
  (GenExpr block, gain-free identities, θ+180° caveat); every other consumer cites it.
- `.specify/f_tf_sharpen/` — single-pass gap operator; ADR-2 forbids the negative-gap
  eigenvalue swap (the 90°-axis-flip hazard); dial mapping and name are Phase 2 gates.
- `.specify/f_tf_aniso_blur/` — kernel-shape decision gate presents both families
  (fixed-tap line integration vs ellipse-grid bounded loop), chooses neither until the
  Phase 1 mirror+cost spike; straight-axis v1, curved integration documented open.
- `.specify/f_tf_hatch/` — Phase 0 gate = the cost-shape branch (marching vs distance-
  field pattern), neither branch picked anywhere in the docs until it lands.

One genuine design finding came out of sibling coordination and was amplified into the
family contract: **the all-zeros unconnected-input decode on outlet 0 is a non-SPD
phantom tensor** (trace 0, λ1 = 1/strength, plausible axis) — recorded in
`docs/f-reference/f_tensor_type.md` consumer rule 5 and in aniso_blur's guard design;
glyph is incidentally safe via its trace gate.

Everything else stands as-is. Next session picks up at Phase 0 of `f_tf_smooth`'s tasks
(the confirmed first build), not at any unconfirmed decision.