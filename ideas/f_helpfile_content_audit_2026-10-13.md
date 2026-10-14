# f_ Helpfile Content Audit — 2026-10-13

## What this is

The 2026-10-13 sizing fix repaired 17 `.maxhelp` files whose preview
bpatcher box was hardcoded to `f_vf_vortex`'s footprint (154x91),
cropping their UI. That fix is layout-only. This is a separate pass
applying `skills/module-preflight/SKILL.md`'s Part 2 judgment gate —
digest framing, recipe/signal-flow comments, status-caveat
consistency, and reference honesty — to the same 17 modules' helpfile
*content*. No helpfile, patcher, or other source file was edited;
this is audit-only.

## Scope

`f_grain`, `f_lens`, `f_ngon`, `f_sirds`, `f_tone_curve`, `f_vf_advect`,
`f_vf_chroma`, `f_vf_flow`, `f_vf_glow`, `f_vf_potential`, `f_vf_prism`,
`f_vf_repulse`, `f_vf_seeds`, `f_vf_split`, `f_vf_vortex_multi`,
`f_vf_vorticity`, `f_weave`.

## Method

For each module: read the `.maxhelp` JSON directly (digest, External
Control Messages, References, and any recipe/signal-flow comment box),
cross-checked against `docs/f-reference/<name>.md`'s own "what it does"
framing, and whichever of `.specify/<name>/`, `.specify/stable/<name>/`,
`.specify/paused/<name>/` exists, plus the module's README.md row for
status-mark consistency. Verdicts use the SKILL.md categories: `pass`,
`thin — digest`, `thin — recipe`, `thin — status caveat`,
`thin — reference`, or a combination.

---

## f_grain

**Verdict: thin — digest.**

Digest ("Stochastic grain field with per-grain displacement and luma
gating") is a verbatim restatement of the doc's own Concept line —
mechanism only. Neither the helpfile nor the doc says when you'd reach
for grain over `f_stipple` or `f_masonry`, or what look it's chasing
(organic/filmic breakup vs. the others' more regular textures). There
is no recipe/signal-flow comment at all beyond the digest and param
list. References are an honest stub pointing at the doc plus the real
never-regenerate caveat (`src/f_grain/definition.py` is a record, not
a generator) — that part is fine, it's a real, specific fact, not a
placeholder. A real digest would say something like: "film-grain-style
breakup for sources that need organic, luma-reactive noise, as
distinct from f_stipple's more even hash-field texture."

## f_lens

**Verdict: thin — digest.**

Digest ("Filmic lens processor -- aberration, distortion, transmission,
ghosting, halation, tilt-shift") is a feature list, not a "for." The
doc's own Concept line supplies the missing "why" directly: "evocative,
not physically-accurate optics" — that framing never made it into the
helpfile. On the positive side, the References block is substantive,
not a stub: it names the real known bug (bypass only gates `lens_pix`;
halation/tiltshift stay live) and the tilt-shift-to-`f_focus` split
plan, both matching the doc's Loose Threads almost word for word — a
good example of a status caveat carried through correctly. Given
`f_lens` was just moved to `.specify/stable/f_lens/` this session with
tilt-shift still physically present (not yet extracted), the digest's
mention of tilt-shift is accurate to current shipped state, just still
mechanism-only.

## f_ngon

**Verdict: thin — reference (+ status caveat carried correctly).**

The status caveat is actually done right: digest says "(UNFINISHED --
not yet confirmed)", matching README's `⚠ Unfinished` mark exactly.
The recipe comment ("Pure generator; try n_mirrors sweeps for
kaleidoscope masks.") is a genuine, concrete suggestion, better than
most modules in this set. But the References block says "See
`docs/f-reference/f_ngon.md` if present" — and it is not present:
`docs/f-reference/` has no `f_ngon.md` at all. The hedge ("if present")
keeps the line technically honest, but it's pointing at a document that
doesn't exist, which is exactly the Part 1 "docs/f-reference must exist
first" prerequisite this module hasn't cleared. Worth noting this
module may also be failing the mechanical gate, not just Part 2.

## f_sirds

**Verdict: thin — reference.**

The References block names "the classic SIRDS technique (Thimbleby et
al.)" — but no "Thimbleby" appears anywhere in
`docs/f-reference/f_sirds.md`. That doc's own References section cites
Policarpo (GPU Gems Ch. 41), Otuyama's stereogram tutorial, and
Wikipedia's Autostereogram article — three real, specific, verifiable
citations — and the helpfile cites none of them by name, substituting
an attribution the source doc doesn't support. This isn't a stub, it's
a mismatch: the helpfile's citation and the doc's citations disagree.
Everything else here is solid — the digest is reasonably "for"-framed
(depth texture → autostereogram illusion), and the recipe comment
("Feed a luma depth texture into in1; defocus your eyes to fuse the
image.") is genuinely good, specific, and usage-oriented.

## f_tone_curve

**Verdict: thin — digest, thin — reference.**

Digest ("Shadow/midtone/highlight tone curve with adjustable band
crossovers") reinforces the exact misleading impression the doc's own
References section works to correct: "Despite the name, it is not a
curve editor." That correction — and the doc's note that
`ideas/lut_curve_and_color_controls.md` records the real successor
design Matt flagged as "wants this pursued for real" — appears nowhere
in the helpfile. The helpfile References block only says it shares a
convention with `f_luma_processor` and points at the doc; both the
naming caveat and the LUT pointer are dropped. No recipe comment
exists either.

## f_vf_advect

**Verdict: thin — recipe.**

Digest ("Advects source texture along a vecfield with temporal
feedback -- persistent flow trails") is above average for this set —
it names the actual effect, not just the mechanism. But the recipe
comment ("Feed a vecfield (vortex, fluid) into in2; any texture into
in1.") is the same generic inlet-feeding instruction used on several
other modules and drops the doc's real distinguishing point: unlike
`f_vf_streak`/`f_vf_warp` (stateless single-pass), advect's character
depends on accumulated history and is "genuinely excitable/amplifying
at `decay > 1.0`" — a user patching this in cold gets no hint that
the module rewards pushing decay past 1.0, which is the whole reason
to reach for it over its stateless siblings. References are solid
(the ADR-8 bypass-keeps-feedback-warm note is a real, specific fact).

## f_vf_chroma

**Verdict: pass (clean on status; minor digest polish possible).**

This is the strongest status-caveat example in the set. Digest reads
"...(v10, paused retool)" and the References block spells out the real
situation in detail: the shipped v10's accumulation washes the rainbow
to gray at high dispersion, the closest-emitter redesign is specced in
`.specify/paused/f_vf_chroma/`, and `direction=Bi` is unreachable from
the UI due to a build bug — all three facts verified directly against
the doc's own Notes. Nothing here overstates how finished the module
is. The only improvement available: the doc frames this module as "the
expressive, field-steered cousin of f_lens's aberration" (vs. f_lens's
fixed, physically-grounded centrifugal version) — that comparison would
strengthen the digest's "for" framing, but its absence doesn't rise to
"thin" given how much real caveat detail is already present. Separately
(not a helpfile defect): README.md's patch table lists this module with
no `⚠` mark at all, which undersells the paused status the helpfile and
doc are both honest about — a README gap, not a helpfile one.

## f_vf_flow

**Verdict: pass.**

Digest ("Dual-mode uniform / texture-perturbed direction field -- feeds
f_weave's vecfield inlet") actually says what it's for, not just what
it is — naming the specific downstream consumer. The recipe comment
("Designed to feed f_weave in2 or any vecfield consumer.") matches the
doc's own "Typical Use" section. References point at both the module
doc and the vecfield type doc. No status caveat needed — doc confirms
"Working," maintenance-audited. One of the cleanest helpfiles in this
set.

## f_vf_glow

**Verdict: thin — digest, thin — recipe.**

This is the clearest missed opportunity in the set. Digest ("Field-
aligned directional blur -- accumulates along streamlines with
exponential falloff") is pure mechanism. The recipe comment ("Feed a
vecfield into in2; any texture into in1.") is the same boilerplate used
on `f_vf_prism`/`f_vf_seeds`. But `docs/f-reference/f_vf_glow.md`
already contains a full "Signal chain recipes" section — three
concrete, ready-to-use recipes (radial bloom via `f_vf_vortex` with
negative convergence, comet-tail streaks via high curl + `direction=1`,
edge feathering via `f_vf_fieldmap`) written specifically to answer
"when would I reach for this over a neighboring module." None of that
made it into the helpfile; the generic line was used instead even
though real recipe text already existed to draw from. The doc also
flags an open cost item (the 48-step accumulation loop runs at full
cost even while bypassed) that isn't essential for a user-facing digest
but underscores how much the helpfile left on the table here.

## f_vf_potential

**Verdict: pass.**

This module's recipe comment — "Feed into f_weave's scalar inlet for
curved, field-informed isolines." — is the literal example
`skills/module-preflight/SKILL.md` cites as what a good recipe comment
looks like, and it's accurate: it matches the doc's "designed to feed
directly into f_weave's scalar inlet" framing. The References block
also carries a real, specific limitation forward correctly: "Integrates
field magnitude only -- axis-blind (a 180-degree flipped field looks
identical)," matching the doc's maintenance-audit finding almost word
for word. The one thing not mentioned is the doc's fuller intended
chain (`f_vf_repulse → f_vf_potential → f_weave`) — the helpfile only
names the downstream half — but given the recipe and reference are
otherwise this solid, that's a minor gap, not a stub.

## f_vf_prism

**Verdict: thin — digest, thin — recipe.**

Digest ("Vecfield-driven prism separation -- luma-gated RGB
displacement along the field") omits the one framing the doc leads
with: prism is "closely related to f_vf_chroma... but adds the
luma-gated threshold/feather mechanic — prism color appears
specifically where bright source content meets the field, rather than
uniformly everywhere the field is nonzero." That's exactly the
"when to reach for this over its neighbor" information Part 2 asks
for, and it's sitting right there in the doc, unused. The recipe
comment ("Feed a vecfield into in2; any texture into in1.") is the
same generic line used for glow/advect/seeds and says nothing about
the threshold-gated character that makes prism distinct.

## f_vf_repulse

**Verdict: thin — recipe.**

Digest ("Obstacle-style repulsion field from a source texture's luma --
divergent flow around bright areas") is one of the better ones — it
names the actual effect. But the recipe comment ("Feed any texture
into in1; the field pushes around its bright regions.") drops the
doc's explicitly stated "Primary use case: any texture source →
f_vf_repulse → f_vf_advect, producing fluid motion flowing away from
bright shapes." That specific downstream pairing is the real reason to
reach for this module, and it's missing. (Status note: the doc marks
this module "Complete (scratch-verified...; audit and build sign-off
still open per spec.md)" — a minor administrative open item, not a
functional caveat on the order of "paused"/"unverified," so its absence
from the digest doesn't rise to a status-caveat miss.)

## f_vf_seeds

**Verdict: thin — digest, thin — recipe.**

Digest ("Discrete marks placed on a hash grid, oriented and weighted by
a vecfield -- dual source/processor") is mechanism-only and misses what
the doc calls "the real payoff": multi-owner overlap via texture
bombing. More specifically, the doc's Key Findings state plainly that
"selection alone never produces overlap" — it's `mag_weight` (mark size
growing with field magnitude) combined with multi-owner compositing
that actually produces it. The recipe comment ("Feed a vecfield into
in2; optionally a shape texture into in1.") doesn't mention `mag_weight`
at all, so a user patching this in cold has no way to find the one
param that makes the module's headline feature work.

## f_vf_split

**Verdict: pass.**

A small utility, and the helpfile is appropriately minimal rather than
padded: digest ("Splits a vecfield's X/Y channels to two greyscale
outlets, unipolar or bipolar") and recipe ("Utility -- inspect vecfield
channels.") both say exactly what the module is and isn't overclaiming
a "for" framing it doesn't need. References point at the doc and the
vecfield type contract. Nothing to fix here.

## f_vf_vortex_multi

**Verdict: thin — digest.**

Digest ("Three-site additive vortex field -- per-site position/
convergence/curl, 4 global mod inlets") is a feature list. The doc's
own framing — "Drop-in replacement for f_vf_vortex wherever
multi-focal caustic/optical effects are wanted. Primary consumer:
f_caustic" — is exactly the "why reach for this over its single-site
sibling" information the digest should carry and doesn't. The recipe
comment ("Feed into f_vf_warp, f_caustic, or f_vf_streak to visualize
the field.") is reasonable and does name real consumers, though it
lists `f_caustic` as one of three equals rather than flagging it as
the doc's stated primary consumer. No status caveat needed; doc marks
this "Complete."

## f_vf_vorticity

**Verdict: thin — recipe (status caveat itself is handled well).**

Digest ("Vorticity-confinement processor -- amplifies curl in a
vecfield (UNVERIFIED -- do not rely on it)") correctly carries the
module's status: it matches both the doc's "UNVERIFIED — do not treat
as working" header and README's `⚠ Unverified` mark, word-for-word in
spirit. But the recipe comment ("Feed a vecfield in; output is the
confinement-processed field.") is the single most generic
inlet-feeding line in the entire set, and this is the module where that
matters most: the doc's Key Findings devote most of their length to
one specific, load-bearing fact — the effect is only visible through a
consumer with temporal feedback, and `f_vf_advect` is "currently the
only such consumer in f_." Every other consumer (`f_caustic`,
`f_vf_warp`, `f_lens`, `f_vf_glow`) samples the field fresh each frame
and shows no visible difference at all. A user who patches this
helpfile's generic recipe in cold, into any ordinary consumer, will see
nothing happen and have no way to know why. This is close to the exact
"feed X into inlet Y" anti-pattern `skills/module-preflight/SKILL.md`
names directly.

## f_weave

**Verdict: thin — digest (mild).**

Digest ("Parametric distance-field line texture with per-line phase
variation; optional vecfield + scalar inlets") is mechanism-only, but
the recipe comment ("Feed f_vf_flow into in2 and f_vf_potential into
in3 for field-curved lines.") is genuinely good — specific, names both
real upstream partners, and matches the doc's intended pairing exactly.
References point at the doc and `discrete_item_conventions.md`; weave's
technique is an original construction with no external citation to
omit, so this isn't a reference stub in the same sense as e.g.
`f_tone_curve`. The doc records a vague, still-open quality concern
from Matt ("can't put my finger on it yet") — reasonable to leave out
of the helpfile given it isn't yet a specific, statable caveat.

---

## Summary — punch list, worst first

| # | Module | Verdict | Core problem |
|---|---|---|---|
| 1 | `f_sirds` | thin — reference | Cites "Thimbleby et al.," an attribution absent from the doc, which instead cites Policarpo/Otuyama/Wikipedia — a mismatch, not a stub. |
| 2 | `f_vf_vorticity` | thin — recipe | Omits the one fact that makes the module usable: needs a temporal-feedback consumer (only `f_vf_advect` qualifies) or nothing visible happens. |
| 3 | `f_vf_glow` | thin — digest + recipe | Doc has three ready-made "Signal chain recipes"; helpfile uses generic boilerplate instead of any of them. |
| 4 | `f_tone_curve` | thin — digest + reference | Digest reinforces the "curve editor" misimpression the doc's own References explicitly correct; LUT-successor pointer dropped too. |
| 5 | `f_vf_seeds` | thin — digest + recipe | Omits `mag_weight`, the doc's own "real payoff" param — the only thing that makes overlap/bombing actually work. |
| 6 | `f_vf_prism` | thin — digest + recipe | Drops the doc's explicit prism-vs-chroma differentiation (luma-gated threshold) and the generic recipe says nothing of it. |
| 7 | `f_vf_repulse` | thin — recipe | Drops the doc's stated "primary use case" pairing with `f_vf_advect`. |
| 8 | `f_ngon` | thin — reference | Cites `docs/f-reference/f_ngon.md`, which does not exist (hedged with "if present," but still a missing doc). |
| 9 | `f_grain` | thin — digest | Pure mechanism restatement; no recipe comment at all; doesn't say when to prefer this over `f_stipple`/`f_masonry`. |
| 10 | `f_lens` | thin — digest | Feature-list digest; References, by contrast, carry the real bypass bug and f_focus split caveat well. |
| 11 | `f_vf_advect` | thin — recipe | Generic recipe omits the decay>1.0 excitable/temporal character that distinguishes it from stateless streak/warp. |
| 12 | `f_vf_vortex_multi` | thin — digest | Omits the doc's "drop-in replacement for f_vf_vortex, multi-focal caustic" framing. |
| 13 | `f_weave` | thin — digest (mild) | Mechanism-only digest; recipe and references are both already solid. |
| 14 | `f_vf_chroma` | pass | Status/caveat handling is the best in the set; only a minor digest comparison-to-f_lens could be added. |
| 15 | `f_vf_potential` | pass | Recipe is the skill's own cited good example; reference carries the axis-blind caveat correctly. |
| 16 | `f_vf_flow` | pass | Digest already says what it's for; recipe and references match the doc cleanly. |
| 17 | `f_vf_split` | pass | Minimal utility, appropriately minimal helpfile — nothing to fix. |

**Clean (4):** `f_vf_chroma`, `f_vf_potential`, `f_vf_flow`, `f_vf_split`.

**Worst three, if only three get fixed next session:** `f_sirds`
(fabricated/mismatched citation — a correctness issue, not just
thinness), `f_vf_vorticity` (recipe omits the module's single
load-bearing usage fact), `f_vf_glow` (real recipe text already exists
in the doc and was simply not used).

**Side finding, not a helpfile defect:** README.md's patch table lists
`f_vf_chroma` with no `⚠` mark, understating the paused-mid-retool
status that both the doc and (correctly) the helpfile itself disclose.
Worth a README fix in a packaging/maintenance pass, separate from this
helpfile-content punch list.
