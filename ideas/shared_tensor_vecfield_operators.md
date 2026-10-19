# Shared operators across tensor and vecfield: can one module take either?

_Captured 2026-10-18 from Matt's question: could a subset of processors work on a tensor
or a vecfield (maybe on separate inlets), e.g. the tensor sharpen or smooth, given that
the same operators keep coming up for vecfields?_

**Status:** analysis only. Nothing built, specced or run. Read for this note: README,
HANDOFF, `.specify/plan.md`, `docs/f-reference/{f_tensor_type,f_vecfield_type,f_tf_smooth,
f_tf_sharpen,f_tf_glyph}.md`, `ideas/{f_tf_research,f_vf_mix,f_vf_temporal_smooth}.md`.
**Not read:** any codebox, `build/build_patcher.py`, `.specify/f_mobius_vecfield/spec.md`.
Claims that rest on those are marked [unchecked] or [inference].

---

## Short answer

Possible and cheap for a narrow class of operators; wrong as a general design principle.

The dividing line is what the operator needs from the data. If it only does component-wise
arithmetic about a neutral value, it does not care what the texture means, and one codebox
serves both. If it needs the algebra of the type (eigenvalues, a transformation law, a
sign), it cannot be shared. `f_tf_smooth` is the first kind: its doc says the codeboxes are
"4-channel arithmetic only", with no decode and no `atan2`. `f_tf_sharpen` is the second
kind: a vector has no eigengap, so it has no vecfield meaning.

Two further points shape the answer. "Tensor" is two encodings and only one is linear
(section 1). And the maintenance win people want from "one module" can mostly be had by
sharing source at build time, with no runtime polymorphism and none of its UI cost
(sections 3 and 6).

---

## 1. Three encodings, not two

| Encoding | Channels | Neutral | Component-wise blend meaningful? |
|---|---|---|---|
| f_vecfield | R = Fx·0.5+0.5, G = Fy·0.5+0.5, B = 0.5, A = 1 | (0.5, 0.5, 0.5, 1) | Yes. Vector average: opposite vectors cancel |
| Raw tensor (tensormap out 0) | R = Jxx·s, G = Jxy·s·0.5+0.5, B = Jyy·s, A = 1 | (0, 0.5, 0, 1) | Yes. Tensor-space average: opposite axes reinforce |
| Packed tensor (tensormap out 1) | cos 2θ, sin 2θ, trace, coherence | (0.5, 0.5, 0, 0) | No. Coherence of the average is not the average of coherence, so A would have to be recomputed |

So "either" realistically means vecfield or raw tensor. Nothing that blends or smooths should
ever be pointed at outlet 1.

The operator is the same on the two linear encodings. The tensor's advantage is that its
representation has no sign, not that its smoother is different. `f_tf_smooth`'s own mirror
test makes the point: it contrasts the tensor one-pole with a signed-vector one-pole on a
flipping gradient, and the vector one collapses to 25% in three frames. Same recurrence,
different data.

---

## 2. Four classes of operator

| Class | Examples (built / candidate) | What it needs | Shareable? |
|---|---|---|---|
| A. Arithmetic about a neutral | smooth (`f_tf_smooth`; twin `f_vf_temporal_smooth` parked), mix (`f_tf_mix` backlog; `f_vf_mix` idea), isotropic blur, gain about neutral, hold / delay | `N + k·(in − N)`, no clamp, N per kind | Yes. One uniform |
| B. Type algebra | sharpen, anisotropy threshold, rotate | eigenvalues, or the spin of the type | Mostly no |
| C. Geometric resampling | `f_mobius`, `f_droste`, warping a field | a transformation law | Same structure, different law |
| D. Consumers and renderers | glyph, aniso_blur, hatch, and their vecfield siblings | closed-form drawing or kernels from the field | Infrastructure only |

### A. Arithmetic about a neutral: the real overlap

`out = N + k·(in − N)` with `N` the kind's neutral 4-vector (table above) covers smooth
(decay target is `N`), mix (an unconnected side contributes `N`), gain about neutral, and
hold / delay. The whole per-kind difference is that one uniform plus the unconnected-input
guard. Two constraints carry over from the tensor work: no clamp inside a feedback path
(smooth's ADR-3), and the unconnected-input trap differs per kind (a vecfield decodes
`vs_black` as a full −1 field, a raw tensor as a non-SPD phantom; `f_tensor_type.md` rule 5,
`f_vecfield_type.md` producer note 4).

`f_tf_research.md` already reaches the same conclusion from the other side: component-wise
crossfade of two float32 textures "is exactly tensor-space mixing, the weakest 'needs the
type' case in the catalog", and `f_tf_mix`'s only differentiators are float32 guarantees,
family labeling and neutral handling. All three transfer to a vecfield mix unchanged.

Worth checking before generalizing smooth [unchecked]: its doc says an unconnected inlet
"decays to the zero-tensor neutral", but rule 5 says `vs_black` reads all zeros, which is
not `(0, 0.5, 0, 1)`. Which one the state pix actually decays to is in `codebox_state.gen`.

### B. Type algebra: mostly not shareable

- **Sharpen.** `λ' = trace/2 + γ·(λ − trace/2)` scales the traceless part and holds the
  trace. A vector has no isotropic part, so "scale the deviation" is just a gain, which
  every `f_vf_` consumer already has. A magnitude curve (`|v| → |v|^p`, direction fixed)
  is a real vecfield operator, but a different one: a new module, not a mode.
- **Rotate.** Both kinds are representations of rotation, but the vector turns by φ and
  the tensor transforms as `R·T·Rᵀ` (the packed doubled angle turns by 2φ). Same angle
  dial, different math, small enough to branch on `kind` if it is ever built.
- **Threshold / gate.** Gates on a different quantity (trace and coherence vs magnitude).

### C. Geometric resampling: best shared-to-different ratio

Plan item 5 and the 2026-10-10 spikes: `f_mobius` and `f_droste` resample a piped-through
vecfield without transforming it (up to 180° direction error near `1/z`'s pole; `f_droste`
is essentially never conformal). The fix is the Jacobian of the UV map, which is the costly
shared part; only the last few lines differ per kind. The same defect would hit a raw
tensor sent through them [inference, not run].

The laws differ in kind, not just in form [inference, standard differential geometry]:
a flow vector transforms as `v' = J·v`, while a structure tensor built from gradients
transforms like a gradient, `T' = J⁻ᵀ·T·J⁻¹`. A tensor built from a metric would differ
again. So a kind-aware warp must also know what the tensor means. The `f_mobius_vecfield`
spec's open question ("new module vs a mode") could take this in as a third option [unchecked:
spec not read].

### D. Consumers: the vecfield twins mostly exist already

| Tensor | Vecfield twin | Why they stay separate |
|---|---|---|
| `f_tf_aniso_blur` (symmetric elliptical kernel along the axis) | `f_vf_streak` (signed streamline accumulation) | different kernel, different sign semantics |
| `f_tf_hatch`, via `f_tf_axisflow` | `f_vf_seeds`, `f_weave` | marks differ; axisflow already bridges |
| `f_tf_glyph` (ellipse per cell) | none in the README table | see below |

`f_tf_glyph` is where one module with two modes would pay off most among consumers. It is
the family's universal debug view, and there is no vecfield arrow / needle view in the
README table (nearest workaround: `f_vf_seeds` with an arrow shape texture, untested for
that). What would be shared is the cell lattice and the four-tap `nearest()` reads, which
is exactly the hard-won part (`f_tensor_type.md` rule 6). The ellipse draw would not be.

---

## 3. How would a module know which kind it has?

Not from content. By contract a vecfield has B = 0.5 and A = 1, but a raw tensor reaches
B = 0.5 whenever `Jyy·s = 0.5`, and an unconnected inlet (zeros) matches neither. Sniffing
per pixel would also let the kind change across a single frame. `f_tf_glyph`'s doc says
nothing mechanically sniffs its input; the contract is convention plus labels.

| Option | How | Cost / risk |
|---|---|---|
| 1. `kind` menu, one inlet | explicit, performable | wrong setting is silently wrong (glyph's outlet-1 mistake "self-diagnoses on sight"; this would not) |
| 2. Two inlets, kind = the connected one | `vs_inState` `src_*` flags | those flags lag about 180 ms at connect / disconnect; a feedback smoother keeps the wrong-neutral residue for `release^k`; both-connected and neither-connected need defined behavior; one more texture inlet |
| 3. Tag on the wire | `prepend` / `route`, the `named_mod_textures` mechanism | verified for mod textures only; T4-T6 still open, plus the unexplained "pix hop" failure; not usable yet |
| 4. Shared source, two modules | one codebox template, kind constants substituted at build, two patchers | no runtime ambiguity; needs a small templating step in the build [unchecked: `build_patcher.py` not read] |

Options 1-3 also hit the module type system: the title-bar labels, the type dots, the menu
kind letters (N / V / T / VT) and the rule that a `T_` category holds only tensor modules
all assume each module has fixed in / out kinds. A polymorphic module needs a new kind and
decisions on how its label, dots and menu slot read. Option 4 changes none of that.

---

## 4. Bridges instead of polymorphism

- **Lower (built):** `f_tf_axisflow`, tensor to vecfield. It needs a reference direction
  because the sign is not in the tensor.
- **Lift by outer product:** `v⊗v` gives `Jxx = vx²`, `Jxy = vx·vy`, `Jyy = vy²`: rank 1,
  coherence 1, trace `|v|²`, and sign-blind. After the lift every tensor operator applies,
  but the semantics change: opposing flows reinforce instead of cancelling. Right for axis
  questions, wrong for transport, and the way back needs a reference direction again.
- **Lift by Jacobian:** the strain tensor of a vecfield (`f_tf_jacobian` in the backlog).
  The physically motivated lift, and a different thing from the outer product.

A possible by-product [inference, untested, not proposed for building]: the lift gives a
neighborhood the second moment (nematic order) where the plain average gives the mean
(polar order). Their gap would flag places where flow runs along one axis in both senses,
which a vector average reads as "no flow". Convergence lines are an obvious case.

---

## 5. What a true polymorphic module costs

For class A the codebox change is tiny (a `neutral` uniform). The cost is everywhere else:
tier-1 mirrors and tier-2 benches run per kind, docs and the helpfile cover both, the type
dots cannot show both, and a wrong `kind` fails quietly. Several of these are one-time.
None of it is hard; it is just more than the saving unless the module is meant to be swapped
between kinds in performance.

---

## 6. Lean, for discussion (item 2 revised by Matt's answers at the end)

1. Do not adopt polymorphism as a principle. Decide per class.
2. Class A (smooth, mix): lean toward shared source, two modules (option 4). It keeps the
   typed labels, dots and menu honest and fits `definition.py` as source of truth. The
   case for a single module is real if "one smoother in the toolbox" matters more to
   performing than the maintenance; then option 1, with a new label kind.
3. Sharpen stays tensor-only. A vecfield magnitude curve would be a separate idea.
4. Class C: fold the kind question into the `f_mobius_vecfield` decision.
5. Glyph: if a vecfield debug view is wanted, build it from the glyph lattice code.
6. Never point blend or smooth at packed tensor outlet 1.
7. Demand check: `f_vf_temporal_smooth` and `f_vf_mix` are both parked "build when a chain
   needs it". If neither is needed, the vecfield half of this has no customer yet.

## Questions for Matt

1. Is the goal fewer modules and one gesture in the toolbox, or less code to maintain?
   They point to different options in section 3.
2. Would the `kind` switch ever be performed (same smoother, swapped between a tensor and
   a vecfield mid-set), or set once? Set once favors option 4.
3. Do you want the vecfield twins (`f_vf_temporal_smooth`, `f_vf_mix`) at all, now that
   tensor smooth exists and tensor mix is in the backlog?
4. Is a vecfield arrow view worth having on its own, whatever happens to the rest?

## Cheap next steps (nothing run)

- Read `src/f_tf_smooth/codebox_state.gen` for what the unconnected neutral really is.
- Check whether `build_patcher.py` can substitute constants into a shared codebox.
- If option 4 is chosen, smooth is the pilot: its codebox is already kind-free.
- Check the `f_mobius_vecfield` spec's open question against section 2C.

---

## Matt's answers (2026-10-18) and what they change

1. **Goal:** not sure it is about less code to maintain; leans toward a personal preference for good
   general-purpose tools over single-use ones, wherever a real generalization exists.
2. **Kind switch:** not performed. Set once.
3. **Vecfield twins** (`f_vf_temporal_smooth`, `f_vf_mix`): probably wanted, but tabled.
4. **Vecfield arrow view:** wanted.

**Effect on the lean (SUPERSEDED by the correction below; kept as the record of an over-reading).** Item 2 of section 6 (shared source, two builds) was argued on
maintenance and on keeping labels honest. A style preference for one general tool
outweighs that, and "set once" removes the main objection to a `kind` menu (silent
mis-setting during performance). So the revised lean for class A is **option 1: one
module, a `kind` menu on a single inlet, set once.** Option 4 stays as the fallback if the
label / menu work below turns out to be ugly.

This also resolves item 3 cleanly. If smooth and mix become `kind` modules, the vecfield
twins arrive as modes, not as separate modules, so tabling them costs nothing.

**Consequences to decide before any build (not decided):**

- **Prefix.** `f_tf_` and `f_vf_` encode the family. A module that serves both needs a
  home: a new neutral prefix, or living in one family and being labeled for both.
- **Label, dots, menu kind.** Needs a new kind beyond N / V / T / VT. The type dots are
  static, so they would have to show "either" (for example both colors) rather than
  follow the `kind` setting. The `T_` category rule (tensor-only) needs an exception or a
  different category.
- **How far to generalize.** The neutral-uniform design is not specific to two types.
  A `kind` menu could also offer scalar (neutral 0) and plain color, which fits the
  general-tool taste, but each added kind is another row in the tier-1 / tier-2 matrix
  and another unconnected-input guard. Probably start with the two linear field kinds
  and add others when a chain asks.
- **Glyph is the same call.** By the same taste, the arrow view is a vecfield mode of
  `f_tf_glyph` (arrow for vector, ellipse for tensor) rather than a new `f_vf_glyph`.
  Shared lattice and reads, different draw. Same prefix and label questions apply.
- **Pilot.** Smooth is still the right first candidate (its codebox is already
  kind-free, pending the neutral check in the next steps below).

Sharpen, class C and the packed-outlet rule are unchanged: general-purpose only where the
generalization is real, and those are not.

### Correction (2026-10-18, later): style does not trump maintenance

The first revision above treated "I don't know if it's about less code to maintain, more an
aesthetic preference" as a ranking. It was a leaning, not a ruling, and maintenance counts.
**The lean is back to undecided between option 1 (one module, `kind` menu) and option 4
(shared source, two modules).** Items 2-4 of the answers stand (set once; twins tabled;
arrow view wanted).

The two options trade different maintenance costs, so neither wins on maintenance by default:

| | Option 1: one module, `kind` menu | Option 4: shared source, two modules |
|---|---|---|
| Per shared module | one patcher, definition, helpfile, drift entry | two of each, one codebox |
| Tests | tier-1 / tier-2 per kind in one module | per module, shared codebox |
| One-time infra | new kind in the label / dots / menu system, a `T_` category exception, a prefix decision | a codebox templating step in the build [unchecked] |
| Failure mode | wrong `kind` is silent (mitigated: set once) | none new |
| Style | one general tool | two tools that share an origin |

**The deciding variable is how many modules would share.** The one-time infra cost of
option 1 is paid once and the duplication cost of option 4 is paid per module. Current
candidates: smooth, mix, a glyph arrow mode, plus possible gain / hold / isotropic blur.
With two or three, option 4 may be cheaper overall; with five or six, option 1 probably is.
[inference, not counted against real effort.] A sensible next step is to count the
candidates honestly before choosing, and to read how much of the label / dots / menu
system would really need to change.
