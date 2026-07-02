# HANDOFF — f_ library

Last session: 2026-07-01 (4-stage forward-chain scratch test — TOP OPEN
QUESTION RESOLVED, plus a new displacement/valid-region constraint found)

## f_stereogram — forward-chain architecture PROVEN via 4-stage scratch test

File: `/Users/matt/Vsynth/patterns/stereogram_scratch_alt.maxpat` (new
file — do not confuse with the older `stereogram_scratch.maxpat`, which
contains the pre-correction v1/v2 attempts described further down this
document and is now superseded for this line of testing).

**The top open question from the previous session — "revisit whether the
strip algorithm can just be a straight `jit.gl.pix` chain" — is answered
YES, empirically, end to end.** Built a 4-stage fixed-N proof: `stage0_pix`
through `stage3_pix`, each a plain `jit.gl.pix` object wired in a straight
forward chain (`stage_N out0 → stage_N+1 in0`), each also fed `depth_source`
on `in1`. Each stage's codebox implements the passthrough/compute split
directly: within its own hardcoded strip range (`uv.x` quartiles), sample
the previous stage's output at a depth-displaced coordinate; outside that
range, pass the previous stage's output straight through unchanged. Stage 0
is the base case (no previous stage — pattern sampled directly, black
outside its own strip).

**Confirmed by direct observation, stage by stage:**
- `stage0_pix` alone: pattern tiled correctly into strip 0's quarter, black
  elsewhere.
- `stage1_pix`: at `depth_factor=0`, quarter 1 shows stage 0's content
  passed through undisplaced (shift cancels exactly) — proved the
  passthrough/region-split wiring before testing displacement at all. Then
  swept `depth_factor` and confirmed only quarter 1 (and downstream)
  responded — `preview_1` (pure stage-0 output) stayed completely static,
  ruling out any cross-talk between the separate `jit.gl.pix` instances.
- `stage2_pix`/`stage3_pix`: same pattern extended, full 4-strip chain
  confirmed live in a single preview window, each stage responding only to
  its own `depth_factor`.

**No `jit.gl.node`, no `jit.gl.pass`, no manual node-chaining needed for
this mechanism.** The architecture question that's been open since
2026-06-30 is closed: a plain forward chain of `jit.gl.pix` objects is
sufficient for the strip algorithm's intra-frame dependency structure.
This doesn't retroactively waste the `jit.gl.pass` research — it's a
confirmed-viable alternative and may still be worth it for other reasons —
but it's no longer required to make this algorithm work at all.

**Render-clock gotcha recurred, worth naming as a pattern now (second
occurrence):** the first attempt at viewing `stage0_pix`'s output showed
all-black across every preview. Root cause was not the shader — it was
`vs_render`'s own `ON`/`OFF` toggle defaulting to `OFF`, with the render
window's fps readout showing `0.00000`. Last session it was `jit.world`'s
`@enable` defaulting to 0; this session it was a different control with
the same failure signature. **Standing check going forward: before
debugging any shader/patch logic that's producing black output, check the
render window's fps counter first.** A `0.00000` reading means nothing
downstream can be trusted as evidence about anything else yet.

**New finding — displacement magnitude is bounded by previous-stage valid
region, not free:** swapping `pattern_source` for a noise generator
(`N0ISE 3`) surfaced black seams between strips at `depth_factor=0.2` that
were not present with the original edge-shaped test pattern. Diagnosed by
setting `depth_factor` back to `0` on both live stages — seams vanished
completely, full continuous noise texture across all four strips,
confirming this is not a wiring/compositing bug. Root cause: in this
4-stage test, each stage's "valid" content is confined to its own
strip-width quarter (stage 0 is black outside its own strip, and that
constraint propagates forward through the passthrough chain). When
`shift_x = uv.x - strip_width + depth_val * depth_factor * strip_width`
pushes the sample coordinate past the edge of the previous stage's
populated region, it samples black — visible as a seam. **This is a real
constraint the production version needs to account for, not an artifact of
the test rig**, though the test rig's per-stage confinement to exactly one
strip-width of valid content is more restrictive than a production version
would likely be. Needs resolving before the live-`num_strips` architecture
is built: either bound max displacement to stay within available valid
content, or redesign what "valid region" means per stage so it isn't
confined to that one stage's own quarter.

**Still open / not addressed this session:** the live-`num_strips`
architecture itself (fixed max chain, e.g. up to 24 stages, only the first
`num_strips` active per the live param — discussed and agreed on
2026-07-01 prior to this test, not yet built). The strip-count ceiling is
still unknown empirically (per Matt: "we don't know yet"). Circular-screen
presentation is confirmed out of scope for this module — masking happens
downstream, `f_stereogram` stays naive rectangular UV.

**Next step:** resolve the displacement/valid-region constraint (likely
needs its own small scratch test — e.g. does giving stage 0 a wider
initial valid region, or redefining "valid" more generously per stage,
eliminate the seam at higher `depth_factor` without the artificial
4-strip-test confinement?), then move to building the real fixed-max-chain
architecture per the live-`num_strips` design agreed earlier this session.

---

Last session: 2026-07-01 (`jit.gl.pass` research + scratch-test session —
key open question RESOLVED)

## jit.gl.pass — no-3D-content question RESOLVED via scratch test

Full writeup: `docs/max-reference/jit_gl_pass_architecture.md`. Started
from C74 documentation research, then confirmed empirically in
`/Users/matt/Vsynth/patterns/glpass-scratch.maxpat`.

**The single highest-priority open question is now answered: `jit.gl.pass`
renders correctly against a `jit.world` context with zero 3D geometry.**
A single subpass sourcing `TEXTURE0` (fed via `jit.gl.pass`'s own
`@texture` attribute, built at runtime by combining two dynamically-named
Vsynth module outputs — `route jit_gl_texture` → `pack s s` → `prepend
texture`) rendered a known-good C74 shader (`cf.edgedetect.jxs`) correctly
with no `jit.gl.material`/`jit.gl.gridshape`/any 3D content present.
Removing 3D content that had briefly been added as a positive control made
no difference — tested both with and without, closing/reopening the patch
between. The "geometry must have a material attached" language in C74's
docs turns out to be specific to `NORMALS`/`VELOCITY`/`ALBEDO`/
`ROUGHMETAL`/`ENVIRONMENT` sources, not a blanket requirement.

**Real bug hit and resolved along the way, worth remembering on its own:**
`jit.world`'s `@enable` attribute defaults to 0 — confirmed in the local
maxref ("Enable automatic rendering (default = 0)"). A bare `jit.world`
never renders a single frame without `@enable 1` or an external bang. This
produced identical black output across every variable tested in a long
diagnostic chain (missing `jit.gl.layer`, context ambiguity, a bad
`.genjit` reference, a known-good shader, the no-geometry test itself) —
none of those were the actual problem; the window had simply never
rendered. Same category as the stale-`.maxpat`-reload gotcha already
documented above: check the boring, easy-to-overlook setting before
trusting a "still broken" result as evidence about the real question.

**RESOLVED, same session:** the actual `PREVIOUS`/multi-subpass chaining
this whole research thread exists for. `jit_gl_pass_scratch_B_fxname.jxp`
(subpass 0 samples `TEXTURE0`, subpass 1 mixes `PREVIOUS` + `TEXTURE1` via
`mix_test.genjit`) rendered a clean 50/50 blend of the two Vsynth source
textures in `testworld` — visually confirmed, not inferred. **Both halves
of the core mechanism question are now settled: no 3D content required,
same-frame sequential dependency via `PREVIOUS` works as documented.**

**Still open, unaffected by this result:** the Vsynth-integration and
`build_patcher.py`-fit concerns from the original fit assessment (points 2
and 3 in the reference doc) — a `jit.gl.pass`-based module is still a
structurally different bpatcher shape than everything else in f_, JXP file
and all. Resolving the geometry question makes this path *viable*, not
necessarily *preferable* to the node-chain approach or the plain pix-to-
pix wire — see below, now also resolved.

## Plain pix-to-pix wire delay question — RESOLVED, no scratch test needed

The original HANDOFF item flagging this as **UNVERIFIED — first empirical
test to run** is resolved, via a different route than planned: not a
clean scratch-test result (the actual test hit real friction — `jit.world`
render isn't bang-steppable, flicker rate is too fast to eyeball, and an
early "still black with parity forced" result turned out to just be
screenshot-vs-flicker timing, confirmed after the fact) but via web
research plus reconciling against `temporal_synthesis_architecture.md`'s
already-working, already-built modules.

**Answer: a straight-line forward pix-to-pix chain (A→B→C, no loop back to
an earlier point) does not carry an inherent one-frame delay.** The
one-frame latency Vsynth's temporal modules rely on
(`pass_pix`/`slide_pix`, see `temporal_synthesis_architecture.md`) is a
property of **closing a feedback loop** specifically — both `jit.gl.pix`
and `jit.gl.slab` copy their incoming texture, which is what prevents a
feedback loop from becoming an infinite instantaneous regress, and that
copy-on-cycle behavior is what produces the settle, not texture handoff in
general. Corroborated three ways: `jit.gl.pix`'s documented default `thru`
attribute (synchronous output when input is received), the fact that
texture-delay tooling (`jit.gl.textureset`, texture-bank tricks) has to be
built deliberately rather than being free, and — most concretely — every
existing f_ processor module already chains `jit.gl.pix` objects sampling
an upstream inlet in production with no observed frame-lag artifact. If
forward chaining carried an inherent delay, it would show up as a full
frame of lag on every processor module in the library, not just in an
edge-case test.

**Practical implication for f_stereogram:** a plain forward chain of
`jit.gl.pix` objects (source → strip 1 → strip 2 → ... ) should be safe
for the strip algorithm's intra-frame dependency structure, with no need
for the node-chain architecture or `jit.gl.pass` specifically to avoid a
delay problem. This doesn't mean `jit.gl.pass` was wasted effort — it's
now a confirmed-viable, real option, and may still be worth it for other
reasons (cleaner multi-subpass expression, no `build_patcher.py` extension
for multi-pix bpatchers) — but it's no longer *the* answer to "how do we
avoid a frame delay," because there may not be one to avoid in the first
place. **Next actual step for f_stereogram: revisit whether the strip
algorithm can just be a straight `jit.gl.pix` chain**, before reaching for
node-chaining or `jit.gl.pass` complexity at all.

`temporal_synthesis_architecture.md` updated same session to sharpen its
"GL texture pipeline has one frame of inherent latency" language — that
phrasing overstated the claim; scoped now to feedback loops specifically.

**No skill files or module code touched this session.** Still deferred —
worth revisiting once the `PREVIOUS`-chain test is done and there's a
fuller picture of what a `jit.gl.pass`-based module would actually cost to
build and maintain.

---

Last session: 2026-06-30 (scratch patch + research session — RESOLVED via web research, corrected mental model)

## f_stereogram — jit.gl.node / jit.gl.pix interaction: RESOLVED (wrong mental model, not a binding bug)

Full spec at `.specify/f_stereogram/spec.md`.

**Algorithm is settled, not in question.** GPU Gems Chapter 41 ("Real-Time
Stereograms", Policarpo 2004) — strip-based, multi-pass, intra-frame texture
feedback. Single-pass `jit.gl.pix` confirmed insufficient (structural, not a
tuning problem — no cross-pixel reference means no fusible repeat structure).

**The empirical dead-end from earlier this session (Method 1 name/drawto
binding, Method 2 middle-outlet binding) was chasing the wrong mechanism
entirely.** Both methods assume `jit.gl.pix` needs to be bound *as a child
inside* a `jit.gl.node`'s sub-context, the same way a 3D scene object
(`jit.gl.plato`, `jit.gl.mesh`, `jit.gl.gridshape`, `jit.gl.videoplane`)
does. It doesn't work that way, and testing confirmed it doesn't — but the
correct conclusion isn't "which outlet/attribute is the right binding
mechanism," it's that **`jit.gl.pix`/`jit.gl.slab` are texture-domain
operators, not scene members, and were never going to bind via either
method.**

**Correct model (confirmed via Cycling '74 docs + the official jit.gl.pix
tutorial, which cites Andrew Benson's SceneWarp technique as the canonical
example):**
```
[jit.gl.node @capture 1]   <- 3D objects (mesh/plato/gridshape/videoplane)
        |                     bind here via name/drawto or middle outlet
        | left outlet = captured jit.gl.texture, output every draw
        v
[jit.gl.pix]                <- receives the captured texture as a NORMAL
                                INLET 0 INPUT, exactly like any other
                                texture source. No naming/drawto/outlet
                                trick on the pix side at all.
```
Direct doc quote: "When capture is enabled, jit.gl.node outputs a
jit.gl.texture out its left-most outlet every time it draws itself. In
this mode, jit.gl.slab and jit.gl.pix objects can be **chained to the
node**..." — "chained to" is ordinary patch-cord texture flow.

This also explains why the isolated learning-patch test (bright red
`@erase_color`, solid-green zero-input pix) necessarily failed under both
methods: that pix had zero texture inputs and neither method is a
texture-passing mechanism, so there was no path by which it could ever
have shown up in the node's capture regardless of which binding syntax
was used. The test was well-designed but tested the wrong hypothesis.

**`jit.gl.pass` researched (2026-07-01) — see
`docs/max-reference/jit_gl_pass_architecture.md`.** Confirmed via C74
canonical docs: subpasses do natively support `PREVIOUS` (prior subpass
output) and named-subpass/`SUBPASS0..N` sourcing — a real, documented
same-frame chaining mechanism. But it's architecturally a 3D-scene
post-processing system (binds to a `jit.gl.node`, documented precondition
of geometry with a material attached), a different bpatcher shape than the
rest of f_, and carries an unverified dependency on 3D scene/material
content that may or may not gate the plain-2D-texture case f_stereogram
needs. **Not established as simpler than the node-chain approach** — the
highest-priority open question (does a subpass chain work against an
empty node fed only via `@texture`, no 3D content?) is still untested.
See that doc's "Fit assessment" section before reaching for it.

**Workflow gotcha hit hard this session, worth remembering going
forward:** editing a `.maxpat` JSON file on disk while it's already open
in Max does NOT live-update the open patcher window. Several rounds of
edits appeared to have no effect because Max was still showing a stale
in-memory copy. **Always fully close and reopen a patch after any file-
level edit before treating a test result as meaningful.** This alone
explained at least one full round of false "still broken" reports.

**Files:**
- `/Users/matt/Vsynth/patterns/stereogram_scratch.maxpat` — original
  scratch test. Contains v1 single-pass (`obj-5`, confirmed insufficient,
  left untouched) and v2 2-strip multi-pass attempt (`obj-40`–`obj-48`,
  currently non-functional / black output, built on the now-corrected
  binding assumption). Do not resume debugging this file directly until
  the node→pix texture-chain pattern (or `jit.gl.pass` subpass approach)
  has been proven in the isolated learning patch first.
- Isolated learning patch — built directly in Max by Matt, not yet saved
  to a path visible to me. **Get this path at the start of next session**
  and read it via Desktop Commander before touching anything.
- `/Users/matt/Vsynth/sirds.genjit` — single-pass genjit reference,
  correct per-pixel displacement math, doesn't produce fusible results on
  its own (single-pass), useful only as a math reference for whichever
  strip codebox eventually gets built.

**Reference doc corrected (2026-06-30):**
`docs/max-reference/intraframe_multipass_architecture.md` has been updated
to retract the pix-drawto-node claim and mark several previously-confident
assertions as **UNVERIFIED** (notably: whether a plain pix-to-pix message
chain actually has a frame delay at all — that was asserted, never tested).
Read that doc's "Open questions" section at the start of next session.

**Next step, in order:**
1. Get the learning patch's file path from Matt, read it fresh.
2. **Cheapest test first, do this before anything else:** wire pix_A's
   outlet directly to pix_B's inlet (no `jit.gl.node` at all) and check
   whether there's actually a one-frame delay. If there isn't, the entire
   node-based architecture may be unnecessary for f_stereogram — worth
   knowing before investing more time in the node approach.
3. If pix-to-pix does have a delay: rework the node test instead — wire
   the node's left outlet (captured `jit.gl.texture`) into a pix's inlet 0
   as an ordinary texture input (not a binding), with the node containing
   a simple visible 3D object. Close/reopen Max fully, confirm.
4. `jit.gl.pass` researched (2026-07-01, see
   `docs/max-reference/jit_gl_pass_architecture.md`) — confirmed
   `PREVIOUS`/named-subpass chaining is real, but fit for f_stereogram is
   unresolved pending one specific test: does a subpass chain work against
   a `jit.gl.node` with no 3D scene content, using only `@texture`-fed
   inputs? If yes, worth evaluating in parallel with steps 2-3. If a 3D
   scene/material turns out to be a hard requirement, deprioritize it —
   it would be a heavier-weight, differently-shaped module than the rest
   of f_ for no clear benefit over the node-chain approach.
5. Once one of these is confirmed working in the isolated learning patch,
   port it back into `stereogram_scratch.maxpat`'s strip0/strip1
   structure — don't keep iterating on the compromised file until then.

## Discussion session — soft-mod, grain, weave

No code touched this session — pure architecture/strategy discussion across
three threads. Captured here so next session starts with full context.

**f_vf_seeds soft-mod — tabled, not decided.** Explored feather (cheap,
single-sample vignette on local-UV boundary distance — this is what f_grain's
`softness` actually does, via `shape_t`/`soft_falloff`) vs. true blur
(multi-tap neighborhood sampling, real cost, softens internal shape detail
not just silhouette edge). Conclusion: which one (or both, on different axes)
reads as the "disproportionately expressive" hard↔soft control depends
entirely on the upstream shape tex content, and isn't resolvable by reasoning
alone — needs a scratch-patch comparison across several shape sources (soft
blob, hard geometric mark, detailed/textured shape, asymmetric shape) before
committing to a mechanism. Explicitly tabled, come back to it.

**f_grain extension — resolved, see "Captured but not scheduled" section
below.** Ruled out shape-tex inlet (too disruptive to grain's core voronoi
identity) and vecfield-driven displacement-steering (displace only offsets
the *background sample* under each grain, not grain position/orientation —
no real anchor for field-steering). Landed on: a plain mod-texture inlet
blended into `cell_size`, new `size_mod` depth param. Small, scoped, additive.
Full reasoning + integration point captured below — ready to build next time.

**f_weave — open, needs a scratch-patch A/B before deciding anything.**
Started from the HANDOFF item "extend shape-tex-inlet pattern to f_grain and
f_weave" — on inspection this doesn't transfer cleanly. f_weave's marks are
procedural line/hash geometry (`dist_to_line`/`dist_to_mark` smoothstep
gates), not item-based like f_vf_seeds; there's no per-mark local-UV frame to
sample a shape tex against. Building one from scratch would be a real
architecture port, not an extension.

Separately, Matt shared a screenshot: f_weave fed a video→optical-flow
vecfield on in1 produces dense, organic, scribble/hatching-like output that
tracks scene structure — visually strong, but Matt described it as feeling
"uncontrolled," specifically in **orientation response**, not (or not only)
density/spacing.

Root cause identified in the orientation block:
```
cs = base_cs + (-vy); sn = base_sn + vx;
mag = sqrt(cs*cs+sn*sn); cs/=mag; sn/=mag;
```
This is vector addition + renormalize, not angular blending. Two problems:
(1) field contribution depth is implicit and fixed (ratio of unit base vector
to ±0.5-range field vector), not an exposed/dialable param; (2) vector-add
renormalization isn't proportional to angular difference — response isn't
linear/predictable, and near-zero (flat/no-motion) field regions still get
normalized into *some* direction rather than falling back to base angle.

Two candidate fixes discussed, not chosen:
- **A — exposed depth param, same mechanism.** Scale field term before
  adding (`field_amount` param). Minimal change, inherits non-proportional
  response behavior.
- **B — true angular blend.** Compute field angle directly (atan2 or
  equivalent — verify availability/safety in GenExpr first), circular-
  interpolate with base angle, weighted by depth and optionally by field
  magnitude (so flat regions fall back to base automatically). More correct,
  bigger change to the block.

Matt was unsure which would actually feel better — correctly identified as
an empirical question, not a reasoning-from-the-couch one. **Next step:**
scratch patch with both mechanisms wired side-by-side/switchable, same
video→flow source as the screenshot, A/B live before committing to either.
Stopped here — session ended due to fatigue, explicitly flagged by Matt.

---

## Prior session — full summary

### f_vf_seeds — shape-tex architecture (major revision) ✓

The original f_vf_seeds (internal smoothstep mark geometry, identity tex as
weight/marklen modulator) was superseded this session by a cleaner architecture:
external shape texture as the mark footprint, with f_vf_seeds reduced to a pure
placement/orientation engine.

**Architecture, current state:**
- Inlets: shape tex (in1), vecfield (in2), mod tex (in3). No source inlet —
  module is a generator (`archetype: source`), not a processor.
- Mark rendering: project pixel into seed-local (along, across) frame as before,
  but instead of computing geometry, normalize into a local UV and sample an
  external shape tex. Gate (hard clip) on UV bounds. No internal edge/profile
  logic at all.
- Outlets: mark color (out1, full RGB from shape tex), mark mask (out2, luma
  greyscale), seed coord (out3, RG seed UV per pixel).
- Passthrough convention: no shape connected → src_shape=0 → black output.
  No internal fallback shape; the module has no opinion about mark appearance.
- Shape tex canonical convention: square domain, mark centered, oriented
  rightward, any color/source (WFG, camera, gradient, jit.gl.pix generator —
  no dedicated shape-generator module family needed).

**Param simplification — `size` + `stretch` replaces `weight` + `marklen`:**
Independent per-axis scale params were fussy (dialing one threw off the other).
Replaced with a single `size` (overall scale) + `stretch` (aspect ratio) pair:
`marklen_eff = size_eff * (1+stretch)`, `weight_eff = size_eff / (1+stretch)`.
Reciprocal relationship keeps mark from collapsing/ballooning as stretch increases.

**Bipolar modulation depths:** `size_mod` and `stretch_mod` extended to -1..1
(from 0..1). Bipolar reads as substantially more expressive/alive than unipolar
for this kind of per-seed modulation — mod tex can grow or shrink the base value
around its set point rather than only adding.

**`softness` removed entirely.** Edge character now lives in the shape tex.
The footprint-boundary feather softness used to provide was a narrow effect
not worth a dedicated static dial — see "Near-term" below for a mod-tex-driven
revival of this idea.

**Both definition.py and codebox_seeds.gen synced to match current patcher.**
Findings captured in `docs/f-reference/discrete_item_conventions.md`:
- size+stretch pattern (recommended for future discrete-item modules)
- bipolar modulation depths (recommended as new default)
- shape-tex-inlet architecture (full writeup, mechanics, consequences)
- open flag: cross-module `density`/`size` semantic audit needed (not started)

**Original mark-quality refinement goals (analytical AA, taper, aspect
correction) are now moot** — taper and shape moved upstream to the shape tex
entirely, so there's no internal geometry left to refine. This is a good
outcome but worth naming explicitly: those HANDOFF items are obsolete, not
completed.

**Session also involved real Max-plumbing debugging** — inlet/outlet index
vs. patching_rect x-position ordering bugs, stale shader cache after codebox
edits, route numinlets/outlets mismatches after param count changes. None of
this was architecture-related, but it ate significant time. Worth hardening
the build/edit workflow before doing this kind of patcher surgery again on
f_grain or f_weave.

**Status: shape-tex architecture proven and working. Proof of concept succeeded.**

---

## What's next — priority order

### 1. f_vf_seeds: per-seed softness/low-pass mod
Static `softness` dial was removed (see above) since a fixed footprint feather
wasn't worth a dial. But a **mod-tex-driven** version is a stronger case — same
mechanism as `size_mod`/`stretch_mod`, modulating edge feather per-seed via the
mod tex rather than a static value. Worth adding as a third bipolar mod depth
(`soft_mod`?) once the gate logic supports a feathered (smoothstep) boundary
again, parameterized per-seed instead of globally.

### 2. f_vf_seeds helpfile
Write `help/f_vf_seeds.maxhelp` following f_droste.maxhelp conventions.
Read `skills/f-helpfile/SKILL.md` first. Deferred from prior session pending
architecture stabilization — architecture is now stable, ready to write.

### 3. Discrete-item family: cross-module semantic audit
Flagged in `docs/f-reference/discrete_item_conventions.md` (OPEN section at top): `density`
and `size` likely mean different things across f_grain/f_weave/f_masonry/
f_vf_seeds in ways that haven't been reconciled. Needs a deliberate side-by-side
pass before drawing conclusions.

### 4. Discrete-item family: extend shape-tex-inlet pattern
Candidate for f_grain and f_weave per the architecture validated in f_vf_seeds.
Own session each. Also reconsider size+stretch and bipolar-mod findings when
touching either module.

### 5. UI density pass
Section 1 (intrinsic character) / Section 2 (field response) layout for all
discrete-item modules. Blocked pending compound dial widget design.

---

## Captured but not scheduled — f_grain

- **f_grain: size mod inlet.** Decided NOT to extend f_grain with a shape-tex
  inlet (too disruptive to its core voronoi mechanism) or a vecfield inlet
  for displacement-steering (on inspection, `displace` only offsets the
  *background sample* under each grain — `uv_d` → `sample(in1, uv_d)` — it
  does not move or orient grains; grain has no position/orientation concept
  to redirect, so "field-steered displacement" doesn't have a real anchor
  here). Instead: a plain mod-texture inlet (not vecfield-typed) sampled
  per-cell at `(best_gx, best_gy)`, blended into the existing `cell_size`
  computation:
  ```
  cell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);
  ```
  New mod sample blends in here (e.g. `mix(cell_size, mod_sample, mod_depth)`),
  with a new `size_mod`/depth param controlling blend amount. `size_var` and
  its existing hash-based variation stay untouched when nothing's connected —
  this is additive, not a replacement. Small, contained: one new inlet, one
  new param, one line of codebox touched. Deliberately scoped to avoid the
  rest of grain's mechanism (displacement, era/fade, luma gate, shape).

## Captured but not scheduled — see ideas/

- **Breaking the grid entirely** (f_vf_seeds seed distribution): current 3x3
  neighborhood search assumes a roughly uniform grid with jitter. True
  non-grid placement (Poisson disk, density-field-driven scatter, or something
  else) is a different seed-distribution algorithm, not a parameter tweak.
  Captured as its own exploration in `ideas/` — see
  `ideas/seed_distribution_beyond_grid.md`.

---

## Known issues / loose threads

- f_masonry square output at non-square render dimensions — root cause unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- f_weave: mod inlets (identity tex + screen tex) — deferred
- f_grain: vecfield inlet — deferred
- `rename strength → amount` across modules — parked

---

## Module inventory (current)

**Generators:** f_masonry, f_chladni, f_stipple, f_grain, f_weave
**Processors:** f_droste, f_mobius, f_stereo, f_lens, f_caustic
**Color/Tone:** f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve
**Utilities:** f_texrouter, f_util_profile
**Vecfield:** f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, f_vf_warp,
  f_vf_streak, f_vf_advect, f_vf_glow, f_vf_repulse, f_vf_split, f_vf_chroma,
  f_vf_prism, f_vf_potential, f_vf_flow, f_vf_seeds
