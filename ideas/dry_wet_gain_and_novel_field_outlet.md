# Dry/wet/gain reframe + "novel field only" outlet heuristic

**Status:** Captured 2026-07-11, discussion only — no pilot module chosen
yet, nothing implemented. Deliberately stopped before picking a target so
the discovery itself didn't get lost waiting on a pilot decision.

## The trigger

Matt raised four related questions about modules that take a
texture + vecfield inlet and currently produce composite/isolated
outlet pairs (`f_vf_glow`, `f_vf_chroma`, `f_vf_prism`, `f_vf_streak`,
`f_caustic`, plus the differently-shaped `f_mobius`/`f_droste`/`f_lens`/
`f_vf_warp`):

1. Reframe the "composite" outlet as an audio-sidechain-style dry/wet mix
2. Replace the strength/mix dial with a crossfader-style control
3. Rename the `composite` outlet to `mix`
4. Add a vecfield as a 3rd outlet — scope unclear, needs a closer look

## Finding 1: two structurally different module shapes, not one

Read `f_vf_glow`'s actual codebox (`.specify/f_vf_glow/codebox_v1.gen`)
to ground this rather than reasoning about it abstractly. Current
behavior:

```
comp_r = clamp(src_r + glow_r * strength, 0.0, 1.0);   // outlet 1
glow_out = mix(glow_rgb, black, bypass);                 // outlet 2
```

This is **additive layering** (`strength` 0–1.5, allows overdriving past
"fully wet"), not a crossfade. This shape repeats across `f_vf_glow`,
`f_vf_chroma`, `f_vf_prism`, `f_vf_streak`, `f_caustic` — the "composite"
outlet is source-plus-effect-layer, and the "isolated" outlet is the
layer alone, not an alternate full image.

`f_mobius`, `f_droste`, `f_lens`, `f_vf_warp` are the other shape:
**replacement**, where the processed output is a full remapped frame, not
a layer added to source. Dry/wet maps directly and idiomatically here:
`out = mix(src, processed, wet)`, textbook sidechain crossfade, no
ambiguity.

For the additive-layer group, a literal crossfade is lossy — collapsing
`strength` (which currently permits overdrive above 1:1) into a 0–1 `wet`
fader loses that headroom.

## Finding 1 resolution: separate gain from wet

Matt's call: keep **two controls**, not one, for additive-layer modules —

- **`gain`** (can exceed 1.0) — controls how strong the effect itself is,
  independent of blend. Preserves current overdrive range.
- **`wet`** (0–1, crossfader) — controls how much of that computed layer
  blends against dry source, as a separate later stage: `out = mix(src,
  src + layer * gain, wet)`.

This is the actual audio-sidechain shape (send level vs. return blend are
different controls), not a cosmetic rename of `strength`. It adds one
control to every affected module's UI — a real cost, worth confirming
per-module rather than assuming it's free.

Naming note: avoid calling the new blend param `mix` — `f_vf_advect`
already has an internal `Param` named `mix_amt` (the exact param the
HANDOFF bug was about — dial labeled "Strength," wired to `mix_amt`).
Reserve "mix" for the *outlet* rename (finding 3, below); use `wet`/`dry`
or `blend` for the new param to avoid two different things both being
called "mix" in the same module.

## Finding 2: crossfader is a UI/param-type swap only

No signal-flow implications — same underlying float 0–1 param, different
widget (`live.slider` horizontal, possibly styled, vs. `live.dial`).
Before deciding, check `vsynth-bpatcher/SKILL.md` for whatever param-
widget convention already exists, so this doesn't become an unexplained
one-off next to every other module's dials.

## Finding 3: outlet rename

`composite` → `mix` as the outlet comment is straightforward and
independent of the param-naming question above (see naming note).

## Finding 4: the real discovery — "novel field only" heuristic

Original framing ("should processors get a 3rd vecfield outlet") was
under-scoped — genuinely didn't know what such a field would even
represent. Reframed into a checkable test:

> **A processor only needs a vecfield 3rd outlet if what it derives
> internally from the field is informationally different from the input
> field itself.** Passthrough, remap, or simple gating of the input
> field fails the test — that field is already available upstream in the
> patch, re-exposing it adds nothing. Something the module accumulates,
> weights, or synthesizes that didn't exist in the input passes it.

### Inventory against source (2026-07-11)

Read the actual codeboxes for all five additive-layer candidates plus
`f_vf_warp` (`f_caustic` v3, `f_vf_warp`, `f_vf_streak` v1, `f_vf_chroma`
v10, `f_vf_prism` v15) rather than reasoning from memory of their
descriptions. Two of the original in-conversation guesses turned out
wrong once actually read — chroma in particular was assumed to pass by
pattern-matching to prism's description; the source reversed that call.
`f_vf_advect` not re-read this pass — already covered in the original
discussion, no new info, call stands.

- **`f_vf_warp` — fails.** `offset_x/offset_y` are just the raw field,
  remapped `[0,1]→[-1,1]` and scaled by a constant `strength`. Nothing
  novel is derived — a 3rd outlet would just re-expose a scaled copy of
  the input field. Separately worth noting: `f_vf_warp`'s current
  "composite"/"warped" outlets are actually the *replacement* shape
  (`out1 = mix(warped, source, bypass)`, `out2 = warped` is a full image,
  not an additive layer) despite being grouped with the additive-layer
  modules in the original framing — for finding 1's dry/wet purposes it
  belongs with `f_mobius`/`f_droste`/`f_lens`, not with glow/chroma/prism.
- **`f_vf_chroma` — fails, correcting the earlier guess.** The field is
  used only to pick march positions (`dx,dy = fx,fy * radius`, no
  recursive walk); the actual gate determining where color shows is a
  **luma** threshold (`fwd_luma`/`bwd_luma`, scalar) at each marched tap.
  There is no per-channel direction split here — that's prism, not
  chroma, and the two were conflated in the original guess. Nothing
  vecfield-shaped is novel; the only candidate novel signal (the
  luma-gate accumulation weight) is scalar, same shape as caustic's
  finding below.
- **`f_vf_prism` — passes, and it's the cleanest confirmed case.** Each
  color channel gets its own **rotated perpendicular direction**
  (`px,py` rotated by `±spread_eff`, distinct per R/G/B) scaled by
  `reach_eff * field_mag` — genuinely different from the input field, not
  just a scaled copy. Real open question this raises: it's *three*
  distinct per-channel vectors, not one RG pair — a 3rd outlet would need
  to decide whether to expose one channel's direction, an average, or
  something else. Not resolved here, but this is the strongest "novel and
  vecfield-shaped" case in the group, probably the best concrete case to
  work out that sub-question against.
- **`f_vf_streak` — leans pass, still genuinely ambiguous.** Matches the
  original `f_vf_glow` read almost exactly (same 8-step recursive
  field-walk structure, `pos0→pos7` each derived from the previous step's
  sampled field). The resolved multi-step trajectory (`pos7 - pos0`, or a
  falloff-weighted average direction across the walk) is arguably novel
  and *could* be vecfield-shaped — unlike glow, which normalizes down to
  scalar accumulation weights before output. Worth a closer look
  specifically at whether the walked displacement can be cleanly captured
  as one RG pair, rather than assuming it either passes or fails by
  analogy to glow.
- **`f_vf_glow`** — unchanged from the original read: ambiguous, leans
  toward scalar accumulation weight rather than a clean vector.
- **`f_caustic` — fails, confirmed.** The 8-step backward walk computes a
  **convergence weight** (`w = max(-divergence, 0.0)`) at each step via
  finite differences on the field — a genuinely novel per-step quantity,
  but scalar, not vecfield-shaped. Confirms the corollary flagged
  originally: caustic's novel signal wants a scalar 3rd outlet (or none),
  not a vecfield one.
- **`f_vf_advect`** — not re-read this pass; original call stands
  (cleanest pass in the library, temporal accumulation is unambiguously
  novel, has prior wiring precedent from the reverted vorticity fold-in
  — see HANDOFF's `f_vf_advect` entry, which already added and then
  reverted a 3rd outlet "exposing the real enhanced displacement field").

**Net result**: only `f_vf_prism` and `f_vf_advect` are confirmed clean
passes; `f_vf_streak` is a real maybe worth digging into further;
`f_vf_glow`, `f_vf_chroma`, `f_caustic`, and `f_vf_warp` all fail the
heuristic as currently built. More of the additive-layer group fails
than passes — the 3rd-outlet idea is the exception across this module
family, not the default, and shouldn't ride along as a blanket change
alongside findings 1–3 (which *do* apply broadly across the group).

**A parallel question surfaced, not explored here**: `f_caustic`'s
convergence weight and `f_vf_chroma`'s luma-gate weight are both real
novel per-pixel signals that just aren't vector-shaped. Whether a scalar
3rd outlet is a worthwhile parallel convention (same heuristic, different
output type) is open — flagged, not decided.

## Finding 5: full-library check — did we actually get all the candidates?

Matt asked directly whether every module taking a vecfield *inlet* had
been checked — the answer was no, only the modules already framed as
composite/isolated in the original discussion had been read. Grepped
`.specify/**/definition.py` for `vecfield`/`mod_inlets` across the whole
library to close that gap, then read enough of each new hit to classify
it rather than assume from the name.

**Confirmed out of scope** (checked, don't fit the texture-in +
vecfield-in + composite/isolated-or-replacement-outlet shape this
discussion is about):

- **`f_vf_fieldmap`, `f_vf_repulse`, `f_vf_flow`, `f_vf_potential`,
  `f_vf_vortex`, `f_vf_vortex_multi`** — all vecfield *generators* or
  *derivers*: they take a texture (or nothing) and produce a vecfield
  (or, for `f_vf_potential`, a scalar) as their entire output. Single
  outlet, no source-texture passthrough, no composite/isolated pair —
  the outlet the heuristic would gate isn't a "3rd outlet," it's the
  whole module.
- **`f_vf_split`** — takes a vecfield in, but no texture inlet; splits
  the field into two scalar channel outlets. Pure utility, not this
  shape.
- **`f_chladni`** — pure generator, no inlets at all; already emits both
  a texture (`out1`) and a gradient-derived vecfield (`out2`) as its two
  outputs. Structurally interesting (texture+vecfield dual-output from
  zero inlets) but not a candidate for a *3rd* outlet since it only has
  two to begin with.
- **`f_weave`**, checked directly — its `mod_inlets` entry is a scalar
  (`state_param: src_potential`), not a vecfield, single texture outlet.
  Not in scope despite HANDOFF's separate note about `f_weave` needing a
  "vecfield" port *label* — that's a labeling task on a different port,
  unrelated to this heuristic.
- **`f_mobius`, `f_droste`** — checked directly, zero `vecfield` matches
  in either file. They take no vecfield inlet at all; their place in this
  discussion is only via finding 1 (they're the *replacement*-shape
  modules for dry/wet purposes), not finding 4.
- **`f_lens`** — checked directly: its "surf" inlet (`in5`) is a scalar
  heightmap, not a vecfield — the module derives its own displacement
  internally via finite differences on that scalar (same shape as
  `f_vf_fieldmap`'s gradient trick), rather than consuming an external
  field. Also not in scope for finding 4, for the same reason as mobius/
  droste.
- **`f_sirds`, `f_masonry`** — `mod_inlets` present but not
  vecfield-typed (discrete-item family, different inlet family entirely).
  Not re-verified line-by-line since neither has the composite/isolated
  outlet shape to begin with, per prior module-family knowledge.

**Net effect on finding 4's scope**: the inventory in the section above
was already complete — no additional true candidates turned up. But this
was worth actually checking rather than assuming, and it surfaced one
useful adjacent fact: **`f_vf_potential` is an existing, working
precedent for a vecfield-in → scalar-out module** ("Scalar potential
field integrator... Output is a 0-1 scalar... directly usable as
`f_weave` scalar inlet"). That's a real prior-art answer to the open
"should caustic/chroma get a scalar 3rd outlet" question raised above —
not a 3rd outlet on an existing module, but proof the vecfield-in/
scalar-out shape already has a place in the signal chain (`f_vf_repulse
→ f_vf_potential → f_weave`). Worth returning to when that scalar-outlet
question gets picked up.

## Finding 6: mirror question — generators leaving a novel scalar unexposed

Matt asked the inverse of finding 4: for the pure vecfield *generators*
found during the finding-5 sweep (`f_vf_fieldmap`, `f_vf_repulse`,
`f_vf_flow`, `f_vf_potential`, `f_vf_vortex`, `f_vf_vortex_multi`,
`f_chladni`), does it make sense to add a *scalar texture* 3rd output —
same heuristic, opposite direction: is something novel already computed
internally that never reaches an outlet?

**A necessary refinement surfaced while checking this, not just a list
of verdicts.** The first pass at answering this (before reading
`f_vf_vortex`'s full codebox) treated "is a scalar internally computed"
as sufficient. It isn't — the real question for a module whose *existing*
output already is a vecfield is: **is the candidate scalar recoverable by
just taking the magnitude of the vector already being output?** If the
existing vecfield encodes magnitude and direction together (not
unit-normalized before encoding), a "novel" scalar pulled from the same
internal math is often redundant — a downstream patch can already get it
via `sqrt((R-0.5)² + (G-0.5)²)` on the existing outlet. If the vecfield
is explicitly unit-normalized before encoding (direction only, magnitude
deliberately discarded), then a magnitude-shaped scalar is genuinely
new information, not reconstructible from what's already exposed. This
is a corollary to finding 4's core test, not a replacement for it — it
only bites when the existing outlet is itself vecfield-shaped, which
is exactly the situation all seven of these modules are in.

Read `f_vf_vortex`'s full codebox (not just the first half checked
during finding 5) and `f_vf_vortex_multi`'s in full to settle this:

- **`f_vf_vortex` — fails, on reflection.** `fx,fy` are the raw
  convergence+curl combination scaled by `exp(-r * falloff)`, encoded
  directly (`R = clamp(fx*0.5+0.5, ...)`) — never unit-normalized. The
  vector's own magnitude already *is* the falloff envelope, up to clamp
  saturation. A distance-from-center or envelope-strength scalar output
  would mostly duplicate what a downstream module could already compute
  off the existing single outlet.
- **`f_vf_vortex_multi` — also fails, reversing the guess from last
  turn.** Read in full: three sites' `fx,fy` are summed additively, but
  each site's own contribution is *also* not unit-normalized before the
  sum (`s1_fx = s1_fx * s1_strength`, etc.) — so the combined output
  vector's magnitude already reflects the combined envelope, same as the
  single-vortex case. The hope going in was that *combining* multiple
  sources would create genuinely new information beyond what survives to
  the output — it doesn't, because nothing about the combination is
  thrown away on the way to the final vector; it's a straight sum, fully
  present in the result.
- **`f_vf_repulse` — mode-dependent, and this is worth flagging as its
  own design smell rather than a clean yes/no.** Read the full codebox:
  in `Abs Add` mode, `fx,fy = (cancel_x/cancel_mag) * abs_mag` — the
  output vector's length *equals* `abs_mag` exactly, so a scalar 3rd
  outlet would be redundant with that mode's own output. In `Turbulent`
  mode, `fx = cancel_x + curl_x * turb_amt` mixes two components
  together, so the original `cancel_ratio`/`abs_mag` relationship that
  drove `turb_amt` is genuinely lost — a real case for novelty, but only
  in that one mode. `Cancel` and `Max` modes never compute `abs_mag` at
  all. So "does this module want a scalar 3rd outlet" doesn't have one
  answer for `f_vf_repulse` — it depends on which of four modes is
  selected, which is an awkward shape for a fixed outlet to have. Worth
  deciding whether that's acceptable (outlet is meaningful in 1 of 4
  modes, otherwise degenerate/zero) or a sign this doesn't fit the
  convention cleanly.
- **`f_vf_fieldmap` — narrower pass than first thought, but still a real
  one.** The encoded vecfield is not unit-normalized either, so gradient
  magnitude is *mostly* recoverable from the existing output the same
  way — except the encoding clamps to `[0,1]`, which saturates (and
  therefore loses) true magnitude at high-contrast edges specifically.
  The novel case here is narrower than "expose gradient magnitude
  generally" — it's specifically "preserve unclamped edge strength that
  the existing encoding clips off," which is a real but more limited
  case than originally stated.
- **`f_chladni` — confirmed, the cleanest case in this group.** Its
  vecfield is explicitly unit-normalized before encoding
  (`vf_out = vec(gx/gmag*0.5+0.5, gy/gmag*0.5+0.5, ...)`) — magnitude is
  deliberately thrown away, not just incidentally clamped. The raw modal
  `total` (used for the *texture* output only, and there transformed
  through `sqrt(abs(total))` and inverted into line thickness — a very
  different shape of signal, not a simple rescale) is genuinely
  unrecoverable from either existing outlet. Strongest, least ambiguous
  case in the whole generator group, and — per finding 5 — already sits
  as a plain unused local variable, so the practical cost of exposing it
  is closest to zero of any candidate discussed in this whole doc.
- **`f_vf_flow` — fails, unchanged from the earlier guess.** Direction in
  "connected" mode comes straight from input luminance with no
  accumulation step of its own; any candidate scalar would just be the
  input texture re-exposed, same failure mode as `f_vf_warp`.
- **`f_vf_potential`** — not applicable; its only output already is a
  scalar, there's no vecfield outlet for a scalar to be a "3rd" output
  alongside.

**Net result**: only `f_chladni` is an unambiguous pass, `f_vf_fieldmap`
passes narrowly (edge-clamp case only), `f_vf_repulse` is real but
mode-conditional, and `f_vf_vortex`/`f_vf_vortex_multi`/`f_vf_flow` fail.
Same overall shape as finding 4 — passes are the minority, and getting
here required actually reading full codeboxes rather than reasoning from
the first half of one file, since the initial read of `f_vf_vortex`
(finding 5) didn't go far enough to catch the normalization question.

## Finding 7: `f_vf_advect` correction — the field passthrough fails, but a self-referential gradient wins

Finding 4 originally called `f_vf_advect` "the cleanest pass in the
library," reasoning from HANDOFF's note about the reverted vorticity
fold-in rather than the module's current codebox. Reading the actual
source when this module came up for spec work reversed that: `fx,fy` are
gated passthrough of the input field (`fx * connected`, no further
computation) — structurally identical to `f_vf_warp`'s fail case, not a
novel derivation. The confinement-enhanced field that would have been
genuinely novel was exactly the vorticity work that got reverted; it
doesn't exist in the module as it stands. **Correction: the raw field
consumption fails finding 4's test.**

What *is* genuinely novel and temporal in this module is `result` (the
accumulated color state) — but that's a texture, already exposed as
outlet 2 (`advected`), not a vecfield. So there's no existing-and-unused
novel field here the way `f_chladni`'s `total` was; a 3rd outlet would
require new computation, and two real candidates came up:

1. **Gradient of the accumulated texture** — finite-difference `result`
   the way `f_vf_fieldmap` differentiates a source texture, turning the
   *shape* of the accumulated flow pattern into a direction field.
2. **Temporally-smoothed vecfield** — apply the same pass/state
   accumulation architecture already used for color to the field itself,
   producing a time-averaged flow direction with inertia.

**Decision: gradient of the accumulated texture.** Reasoning, since this
is worth generalizing beyond just this one module:

- The smoothed-field option is generic infrastructure — "give any
  vecfield inertia" isn't specific to what advection does, and reads
  more like its own module (`f_vf_smooth` or similar) than an addition to
  this one. It would also add a second feedback loop to a module where a
  feedback-loop experiment (vorticity confinement) already failed once
  and got reverted — a bad place to stack more of the same kind of
  complexity for a payoff that isn't even advect-specific. Parked as a
  separate idea rather than folded in.
- The gradient option is **self-referential in a way nothing else in the
  library can produce**: the shape the flow has drawn over time becomes
  a new field to flow *along*. Patched into another `f_vf_advect` or
  `f_vf_warp`, this creates a feedback loop at the patching level — flow
  reshaping its own future direction based on what it already drew —
  which is a more interesting and more general result than a smoothing
  filter, and it's specific to this module's actual identity rather than
  something any vecfield producer could equally want.
- It's also cheap and low-risk: same finite-difference-on-a-texture
  idiom already proven in `f_vf_fieldmap` and `f_chladni`'s vecfield
  outlet, no new pix stage or feedback wiring — just four extra samples
  on `result`, which the module already holds as `in3`'s next-frame
  source.

**General principle worth keeping from this**: when a module's own
accumulated *output* is genuinely novel but not vecfield-shaped, don't
assume the fix is deriving a vecfield from the *input* side (that's
often just the passthrough failure mode, as it was here) — check whether
deriving it from the module's own *output* state produces something
self-referential and specific to that module, rather than a generic
filter that would apply equally to any module of that signal type.

## Finding 8: `f_vf_prism` correction — geometry alone doesn't pass, gate-weighting does

Same shape of correction as finding 7, surfaced while writing `f_vf_prism`'s
spec (which also needed a full rewrite first — its `spec.md` had drifted
badly from the actual production module; see that file's 2026-07-11
rewrite note for the full account of the drift).

Finding 4 originally credited `f_vf_prism` as the cleanest confirmed pass
in the processor group, reasoning that each color channel's own rotated
perpendicular direction was novel. True of the geometry, but insufficient
alone: R/G/B are a fixed symmetric rotation of the *same* input field
(`R = rotate(f, +spread)`, `G = f`, `B = rotate(f, -spread)`), and
summing or averaging three vectors related by symmetric rotation cancels
the sine terms exactly — any unweighted linear combination of the three
collapses to a scalar multiple of the original field, recoverable from
the input and `spread` alone. That fails the test the same way
`f_vf_warp`'s passthrough did.

What actually passes: the per-channel post-blur **gate weights**
(`gr,gg,gb` — luma-thresholded at each channel's displaced sample
position, Gaussian-blurred) are independently, nonlinearly data-dependent
— genuinely new information the field doesn't carry, since it comes from
what's actually bright at each channel's sample position, not field
geometry. The corrected 3rd-outlet design is a **gate-weighted
combination** (`combined = gr*R + gg*G + gb*B`), which reduces to the
same trivial case when gates agree (no manufactured novelty where none
exists) but diverges meaningfully wherever channel gates disagree —
encoding "which side of the dispersion is visually active here," a
product of this module's own accumulation, not the input field.

**Pattern repeating across findings 7 and 8**: both processor-side
corrections to date involved a module whose *direct* candidate (raw
field passthrough for advect; unweighted multi-channel geometry for
prism) turned out to be recoverable from existing information, while the
genuinely novel signal was hiding one level deeper, in something the
module's own gating/accumulation computes that the input alone doesn't
determine. Worth checking for on any future finding-4/6 candidate before
taking a first-glance "this looks novel" read at face value.

## Not yet done

- No pilot module chosen. `f_vf_prism` (vecfield 3rd outlet, though the
  three-channels-vs-one-outlet question needs solving) and `f_vf_advect`
  (cleanest case, has precedent) look like the best concrete first
  targets for finding 4. `f_vf_streak` needs its own closer look before
  it can be called either way. `f_vf_glow`, `f_vf_chroma`, `f_caustic`,
  and `f_vf_warp` don't get a 3rd outlet under the current heuristic —
  findings 1–3 (gain/wet split, crossfader, mix rename) still apply to
  all of them independent of finding 4's result.
- `vsynth-bpatcher/SKILL.md` not yet checked for existing param-widget
  conventions (finding 2).
- The scalar-outlet parallel-convention question (caustic, chroma) not
  explored.
- No spec/plan/ADR started for any specific module yet — this is a
  cross-cutting convention note, deliberately captured before committing
  to a pilot.
