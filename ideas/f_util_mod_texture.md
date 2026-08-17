# Mod-texture assignment convention

**(File was originally "externalized mod texture util" — that framing was
investigated and rejected. See "Rejected branches" below. Kept at this
path so the original idea remains findable.)**

**Status:** discussed to a conclusion 2026-07-29, not yet specced. No
code written. Some claims verified directly against `f_masonry` and
`src/` during that discussion (marked **verified**); the rest is
inference and still needs checking.

---

## Conclusion

> **⚠️ 2026-07-29, same session: a possible alternative to this whole
> approach was raised — see `ideas/named_mod_textures.md`.** Tagging
> texture streams with `prepend` and demultiplexing with `route` inside
> the module would solve the same scaling problem *without* breaking
> Kevin's 1:1 binding, without a matrix, and without an assignment UI.
> It is **unverified** — nothing scratch-tested — so the conclusion
> below stands for now, since it is at least grounded in a shipped
> working implementation. But do not build on this file until
> `named_mod_textures.md` T1/T2 have been run, because passing tests
> there would make most of what follows obsolete.

A module exposes a small fixed number of mod texture inlets (**2 as the
working default**), and *what those textures drive* is set in the UI at
runtime rather than fixed by which inlet you patched into. Assignment
lives **inside the module**, not in an external routing util.

The mechanism is per-param weighted accumulation in the codebox:

```
param_eff = clamp(param + a_sample * param_mod_amt_a
                        + b_sample * param_mod_amt_b, lo, hi);
```

Every modulatable param carries one amount `Param` per mod inlet.
Unused ones sit at zero — a multiply-add against zero is free on GPU.

**Caveat added 2026-07-29:** the formula above is written in
`f_masonry`'s *unipolar* form (black = neutral). Kevin's canonical
Vsynth modules use a *bipolar* form (0.5 grey = neutral, via
`scale 0. 1. -1. 1.` before the depth multiply). That conflict is
unresolved and must be settled before this becomes a convention — see
"Scalar modulation vs. texture modulation" below. Also note this
shared-inlet + assignment model is a **deliberate break** from Kevin's
1-inlet-per-param convention, not an extension of it.

This is not new machinery — it is what `f_masonry` already does
(**verified**, `src/f_masonry/definition.py`):

```
mortar_eff = clamp(mortar + a_sample * mortar_mod_amt_a
                          + b_sample * mortar_mod_amt_b
                          + c_sample * mortar_mod_amt_c, 0.0, 1.0);
```

The convention generalizes that pattern; it does not invent it.

---

## What is durable vs. what is UI

The contract is the durable part and should be settled first:

1. `definition.py` declares the mod inlets (the `mod_inlets` key
   **already exists and does this** — see below).
2. `definition.py` declares, **per texture-modulatable param, a triple**:
   the base scalar param, a paired mod-depth scalar (`_m` / `_mod_amt_`),
   and the binding to a mod texture inlet. Modulatability is *not* a
   boolean property of a param — see "Scalar modulation vs. texture
   modulation" below, this distinction was originally conflated here.
3. Codegen emits the `_mod_amt_<inlet>` `Param`s and the accumulation
   line per modulatable param.
4. Amount `Param`s are addressable by name.

Get that right and **the UI is entirely downstream** — grid, `(+)`-row
list, context strip, or something not yet imagined, swappable without
touching a single module. Get it wrong and every UI built on it
inherits the mistake.

Explicit decision from the discussion: **do not bank on any existing
UI.** All of it is up for revision. Build the contract, ship it on one
module with whatever minimal UI is fastest, then design the real UI
once it has been used and the interaction is understood.

---

## Scalar modulation vs. texture modulation — NOT the same thing

Clarified 2026-07-29 after this file originally conflated them.
Reference implementation: **Kevin's `vs_displacement`**
(`Vsynth/patchers/vs_displacement.maxpat`, gen patcher inside
`jit.gl.pix`) — **verified** by reading it directly.

Sending `[param zoom 1.2]` sets a scalar. Texture-modulating `zoom` is
a different mechanism requiring **three** things, not one flag:

| piece | Kevin's naming | role |
|-------|----------------|------|
| base scalar param | `param zoom 1.` | the value being modulated |
| mod-depth scalar | `param zoom_m 0.` | how much the texture moves it |
| bound texture inlet | `in 5` | the modulating texture itself |

The depth is itself an ordinary scalar param, so it is
`[param $1]`-controllable like any other. `vs_displacement`'s route
list — `angle zoom x y xm ym rotm zm kmode mmode` — exposes base
scalars and mod depths side by side.

**Bipolar remap (important).** Every mod texture in `vs_displacement`
passes through `scale 0. 1. -1. 1.` before being multiplied by its
depth. So **0.5 grey is neutral** and the texture is a *signed
deviation* — consistent with the `f_vf_` family's 0.5-is-zero-vector
convention.

**Divergence, unresolved:** `f_masonry` does **not** remap.
`a_sample = sample(in2, brick_uv).r` is used raw, so **black is
neutral** and modulation is unipolar-additive. The library currently
carries two incompatible mod-texture conventions. This must be decided
before any library-wide convention lands — and note the conclusion at
the top of this file was drafted from the masonry (unipolar) form
without noticing the divergence.

**Kevin's model is 1 texture inlet : 1 param.** Canonical Vsynth, but
it does not scale — masonry's 13 modulatable params would need 13
inlets, which is precisely why it went to shared inlets plus an
assignment matrix. **So "2 inlets + assignment" is a deliberate break
from Vsynth convention, not a refinement of it.** That should be an
explicit argued decision, not something that happens by default,
especially given Kevin's modules are the canonical reference for
conventions in this library.

---

## Why break Kevin's convention at all — the motivating problem

Stated by Matt 2026-07-29, and the reason this whole line of thinking
exists:

**`f_` modules tend to have substantially more params than Kevin's
do.** Kevin's 1-texture-inlet-per-modulatable-param convention works
fine at his scale — `vs_displacement` modulates four things and has
four mod inlets. It degrades badly as param count grows: `f_masonry`
has 13 modulatable params and would need 13 mod inlets under that
convention, which is unpatchable in practice.

So the break is **deliberate and motivated**, not an oversight. This
file is an experiment in what can replace 1:1 inlet binding once param
count makes it untenable. That reframes the open question below from
"should we break convention?" (answered: yes, we have to) to "what is
the right replacement, and how far does it diverge?"

**Related, and a caution:** `f_masonry`'s mod inlets were developed
**in isolation, without reference to Kevin's conventions** — Matt's own
assessment. That is how the unipolar/bipolar divergence got in. So
masonry should be treated as evidence about *scaling pressure* (it
demonstrates the real problem) but **not** as a source of convention
authority. Where masonry and Kevin disagree on a detail that isn't
about param count, Kevin is the reference.

---

## Discovery: already solved, was never the problem

Much of the original discussion theorized about how a util could
"discover" a module's modulatable inlets. **Verified**: the metadata
already exists in `definition.py` as the `mod_inlets` key, with
human-readable labels. From `f_masonry`:

```python
"mod_inlets": [
    {"label": "slot mod",  "vs_instate": False},
    {"label": "brick mod", "vs_instate": False},
    {"label": "pixel mod", "vs_instate": False},
],
```

Self-declaration in `definition.py` was the fallback plan in the
original version of this file. It turns out to be the existing state of
affairs, not a fallback. What may still need adding is a *modulatable
params* declaration (which params get `_mod_amt_` pairs emitted) —
probably explicit rather than inferred from the full param list, since
not every param wants texture modulation.

**Caution** (**verified**): `f_masonry`'s `mod_inlets` key was once
missing from `definition.py` while three inlets were live in
production, hand-wired into the `.maxpat` and never captured back.
Rebuilding silently dropped them. Declarations drifting from reality is
a demonstrated failure mode here, not a hypothetical one.

---

## Why `f_masonry` is the wrong template

`f_masonry` has three mod inlets, but they are **not three
interchangeable sources — they are three different coordinate spaces**
(**verified**, `src/f_masonry/definition.py`):

| inlet | label     | sampled at            | meaning                  |
|-------|-----------|-----------------------|--------------------------|
| `in2` | slot mod  | `brick_uv`            | winner's slot identity   |
| `in3` | brick mod | `(along_frac, across_phase)` | position within brick |
| `in4` | pixel mod | `norm`                | screen space             |

Masonry affords three spaces because it is built around slot/course
geometry. That is unusual. Most modules afford one (screen space only —
`f_droste`, `f_lens`, `f_tone_curve` have no per-item identity to
sample). Discrete-item generators (`f_grain`, `f_stipple`,
`f_vf_seeds`) plausibly afford two: item identity and pixel.

**Therefore the inlet count is not a number to standardize on — it
falls out of each module's geometry.** Masonry is the maximal case and
generalizing from it would over-engineer everything else. Two is a
sensible *default ceiling* for ordinary modules, not a law.

Also **verified**: masonry's matrix is asymmetric. Only six params
(mortar, softness, width, roundness, course_color, brick_color) get all
three sources; drift, offset, speed_var, regularity, phase, skip have
`_a` only. At least `offset` is structurally forced — it samples `in2`
before the winner search runs, so it cannot use winner-keyed sampling.

---

## Existing UI, for reference only

**Verified**: `package/javascript/f_util_matrix_grid.js` (436 lines) is
already generic and data-driven — `params <name1> <name2> …` rebuilds
its rows, and it has scroll state, a scrollbar, and a **strip mode**
(`strip`, `focus <param>`) for a single-row context strip. `f_masonry`
instantiates it twice: full grid at 211×289, context strip at 211×22.

So the grid is further along than "unwieldy flat table" suggested — it
*is* scrollable. The likely real complaint is scroll *quality*: 13 rows
at 20px ≈ 260px against a 289px box, so it barely scrolls and the
scrollbar is near-vestigial. Worth confirming which before assuming a
rewrite is the fix.

Two concrete defects if it is ever reused as-is:
- `NUM_SOURCES = 3` and `SOURCE_LABELS = ["A","B","C"]` are hardcoded.
- Masonry feeds it 13 param names × 3 columns = 39 cells, but only
  ~25 are wired in the codebox. Roughly a third of the grid does
  nothing.

**But per the decision above, none of this should be built on.** It is
recorded so the next UI attempt knows what exists and what went wrong,
not as a starting point.

Note on the `(+)`-row idea (Ableton-mapping-style growable list, one
row per live assignment): at two sources with sparse usage a grid is
mostly whitespace, so a row list is the natural presentation — a
one-column matrix degenerates into exactly that. The `(+)`-row and the
grid may not be rival designs so much as the same widget at different
source counts. Unverified: whether Max can add rows without dynamic
object creation, or whether it must be N pre-built hidden rows.

---

## Rollout sequencing

**Verified**: `f_sirds`, `f_vf_advect`, and `f_vf_seeds` each have a
dedicated build script alongside `definition.py`
(`build_sirds.py`, `build_advect.py`, `build_seeds_multistage.py`) —
all multi-stage modules. They are regenerable, just through their own
path, so the rollout cost is teaching four builders one pattern rather
than hand-editing four patchers.

`f_masonry` has `definition.py` only, no build script — it is the
genuine manual case. It also already has a working version of this
mechanism, so it is arguably the *last* module to touch, not the first.

Proposed order:
1. Settle the `definition.py` declaration format (mod inlets +
   modulatable params + ranges).
2. Implement codegen in `build_patcher.py`.
3. Prove it on one simple single-stage module with minimal UI.
4. Propagate to the three custom builders.
5. Design the real UI, informed by actual use.
6. Consider migrating `f_masonry` — or leave it alone.

---

## Rejected branches

Recorded so they are not re-litigated.

- **External routing util (the original premise).** Rejected. It cannot
  remove the in-module accumulation, only shadow it — the params live
  in the shader and their use sites are hardcoded, so assignment cannot
  leave the module. A util would create two sources of truth for the
  weights and fragment preset recall across two objects.
- **External util justified by fan-out** (one texture to many modules).
  Rejected: Max cables already fan out natively. One outlet drives many
  inlets; each texture inlet takes 0 or 1 cable. No util needed.
- **External util justified by keeping module UI clean.** Rejected: the
  module needs the inlets and the accumulation regardless, so the only
  thing externalized is the UI — at the cost of the sync and preset
  problems above.
- **Channel muxing** (pack 4 mod sources into RGBA, unpack in the
  codebox). Rejected: it only compresses fan-in. The matrix, the
  mapping UI, and the param list all still exist, and it adds a
  slot-index abstraction the performer must track plus pack/unpack
  machinery in every codebox. Capacity nobody was short on, in exchange
  for a concept everybody must learn.
- **Dynamic outlet/inlet counts.** Rejected as almost certainly
  impossible — Max bpatcher I/O is fixed at patch-load by the physical
  `in`/`out` objects. Fixed small counts instead.
- **Standardizing on masonry's three-space model.** Rejected — see
  "Why `f_masonry` is the wrong template" above.

---

## Open questions

- **Unipolar or bipolar mod textures?** `f_masonry` is unipolar (black
  = neutral), Kevin's `vs_displacement` is bipolar (0.5 = neutral).
  Blocking — decide before anything else, since it changes every
  accumulation line and every module's neutral state. **Leaning
  bipolar**: it matches both canonical Vsynth and the `f_vf_` family,
  and masonry's unipolar form came from isolated development rather
  than a considered choice (see above), so it carries little weight as
  precedent. Cost if bipolar wins: masonry's existing accumulation
  lines and any saved presets change meaning.
- **What replaces 1:1 inlet binding, and how far to diverge?** The
  break itself is settled (param count forces it — see "Why break
  Kevin's convention"). Open: whether shared-inlets-plus-assignment is
  the best replacement, and whether anything else of Kevin's
  convention (naming, depth-param shape, bipolar remap) should be
  preserved even while the binding model changes. Default assumption:
  preserve everything except the 1:1 binding.

- **`(+)`-row feasibility in Max**: can rows be created on demand, or
  must it be N pre-built rows hidden until used?
- **Is the existing grid's problem scroll quality or scroll absence?**
  Confirm against the running patch before deciding a rewrite is
  warranted.
- **Modulatable-param declaration format**: how to express the
  base/depth/inlet-binding triple in `definition.py` (a flag per param
  is insufficient — see the scalar-vs-texture section). Needs the
  effective-result clamp range too, which is not necessarily the base
  param's own range.
- **`Param` namespace cost**: a 12-param module at 2 inlets carries 24
  `_mod_amt_` Params, mostly zero. Cheap on GPU, but 24 entries in
  preset state per module. Probably fine — worth confirming before it
  becomes a library-wide convention.
- **Does the two-inlet default hold for discrete-item generators?**
  They plausibly want item-identity space *and* pixel space, which is
  exactly two — but that should be checked against `f_grain` /
  `f_stipple` / `f_vf_seeds` rather than assumed.
