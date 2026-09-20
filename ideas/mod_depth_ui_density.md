# Mod-depth UI — density vs. legibility vs. clickability

**Status:** Brainstorm session, 2026-09-20, paused mid-thread (Matt: "put a
pin in this... I'll look at how some Max4Live devices handle this type of
UI problem"). Nothing decided, nothing built. This is an instance of the
long-open **UI density / control surface design** question tracked in
`.specify/plan.md` (open since 2026-06-17, blocks `f_util_matrix` jsui
refinement and any composite-dial widget) — not a separate problem.

## The core problem, in Matt's words

> higher density of information while maintaining legibility and
> clickability

Sharpened further mid-session: the actual performance context is
**performing in the dark** — UI has to be large/unambiguous enough to see
and hit reliably under those conditions, not just visually tidy.

## How this session got here

Emerged from `ideas/named_mod_textures.md`: once texture *assignment*
moves upstream (tag via `prepend`, picked from a menu), each modulatable
param still needs a **depth** control on the module itself (the base/`_m`
triple is unaffected by how the texture arrives — see
`ideas/f_util_mod_texture.md`). With 12+ modulatable params realistically
possible on one module (`f_masonry`-scale), showing a permanent depth
dial per param regardless of connection state just relocates the old
13-inlet scaling problem from inlets to panel space. Matt's constraint,
stated directly: **no scrolling** — either everything fits on the front
panel, or splits across front+back via the existing shipped `panel_toggle`
mechanism (front/back panel switching). That makes "how many dial-sized
slots fit" a real, calculable ceiling, not an abstract one.

**Important scope-narrowing that happened mid-session:** initially assumed
a "generic reassignable slot pool" (unknown params, dynamic relabeling)
was needed. Corrected — every modulatable param is known at *build* time
(`definition.py`), so there's no reassignment/relabeling problem at all,
just a straightforward per-param **hide when unconnected, show when
connected**. Much simpler than the reactive-relabeling machinery first
proposed; don't reintroduce that complexity without a reason.

**Also resolved:** depth should stay **on the module's own panel**, not
move upstream alongside the assignment menu (an idea floated and then
walked back) — because every core Vsynth module already puts mod amounts
in its main UI (`zoom`/`zoom_m` side by side), and departing from that
risks the same kind of isolated-convention-drift that already happened
once with `f_masonry`'s unipolar mod textures (built without reference to
Kevin's conventions — see `ideas/f_util_mod_texture.md`). Assignment
(which name) living upstream is a smaller departure than it first looked,
too — in Kevin's convention, "which source feeds a mod inlet" is already
an upstream, patch-cord-level decision; only the *value* you'd tweak live
has an expectation of living on the module's face.

## Concrete Max facts established this session (verified, not assumed)

Checked directly against Max's reference docs rather than reasoned from
memory — worth trusting these without re-deriving:

- **`slider` has no native bipolar/centered-fill rendering.** Its `min`/
  `mult` attributes only remap the *output value* after the fact; the fill
  is always drawn from a fixed edge to the thumb, regardless of what value
  range results. Confirmed via the full attribute list — no
  bipolar/centered option exists.
- **`dial`/`live.dial` have no bipolar-specific attribute either.**
  Dials read as bipolar-friendly for a structural reason, not a coded
  feature: an arc-fill is anchored to a rotational reference point
  (typically straight up), which gives a symmetric range a natural "zero"
  reference that a linear slider's edge-anchored fill doesn't have.
- **`live.numbox` *does* have a native bipolar display mode** — its
  `appearance` attribute: 0 default, 1 triangle, 2 slider, **3 bipolar**,
  4 LCD. Established this after initially (wrongly) treating "no native
  bipolar widget anywhere in Max" as settled — that was only ever true of
  `slider`.
- **Matt's own empirical finding, not documented in the maxref attribute
  list at all:** `live.numbox` is height-locked (can't drag-resize taller
  in the patcher editor) in appearance modes 0-3, but **not** in mode 4
  (LCD). This is internal resize-handling behavior, invisible to a
  reference-doc attribute scan — the kind of thing only hands-on testing
  surfaces. Net effect: the one native mode with correct bipolar
  rendering is also the one that's click-target-constrained; LCD escapes
  the height lock but presumably has no fill-bar visual at all.
- **Live UI objects (`live.*` family) cannot be subclassed.** They're
  compiled/closed externals; Max has no inheritance mechanism for native
  object classes. "Cloning" `live.numbox` means building an equivalent
  custom `jsui` from scratch, not extending the real one.

## UI concepts explored (none chosen, several genuinely different)

Prompted by: Matt's two sketches (dense `live.numbox`-with-fill rows vs.
wider numbox+slider rows) and the observation that a compound
concentric-ring dial (inner ring = base, outer ring = mod depth,
discussed in an earlier session) risks mis-clicking the wrong ring under
performance pressure — radial-distance targeting needs more precision
than the failure mode (dark, fast, live) can tolerate.

- **Two-zone fused control** — one object, split top/bottom (or
  left/right) by a hard line, not nested by radius. Same readability as
  stacked rows, less per-object border/margin overhead, and zones
  separated by *position along an axis* (coarse, easy to judge in the
  dark) rather than *radial distance* (needs precision).
- **Single strip, two markers** — base and depth share one control;
  depth appears as a second marker/color on the *same* bar rather than a
  new row. Nothing new ever occupies space when a connection appears —
  sidesteps the "does the module grow" question entirely. Open risk:
  disambiguating a click near marker A vs. marker B.
- **Reveal-on-engage** — depth is normally just a small indicator; press/
  hold to pop up a large temporary control, gone on release. Trades
  permanent space for an extra interaction step.
- **Panel-wide mode flip** — one toggle repurposes every visible control
  between "base" and "depth" meaning, panel-wide, rather than each param
  getting two controls. Every control stays big and unambiguous; you
  can't see base and depth simultaneously. Structurally the same move as
  the `gswitch` already proven out in `named_mod_textures.md`'s T1-T3
  scratch test (cycle what something *means* rather than reserve space
  for everything at once), applied to UI instead of texture selection.
- **XY-pad** — one 2D control per param, horizontal = base, vertical =
  depth (or vice versa). Biggest, most literal "easy to hit in the dark"
  target. Real cost: accidental diagonal drag nudges both values;
  fixable with axis-locking after initial gesture direction, but that's
  a real interaction detail, not free.
- **Hybrid, not a from-scratch widget:** keep a real `live.numbox`
  (bipolar or LCD mode) for its native rendering/typing/number-formatting,
  and layer an invisible `jsui` "drag-catcher" over/around it, sized as
  large as needed, translating drag deltas into `set <value>` messages
  fed into the real numbox underneath. Much smaller build than a full
  custom-painted clone — reuses everything the native object already does
  correctly, only adds the missing grab-area.

## LOE anchors, if a custom `jsui` path is chosen

Not estimated in a vacuum — grounded against what's already shipped in
this codebase:

- `ideas/f_util_compound_dial.md` scoped a comparable custom widget
  (two concentric rings, radial hit-testing, two independent values) at
  roughly 200-300 lines of JS.
- `package/javascript/f_util_matrix_grid.js` — 436 lines, real and
  shipped — does considerably more (a whole scrollable multi-row grid
  with a strip mode), and is proof this class of object is buildable and
  maintainable here, not hypothetical.
- A single fused two-zone or single-strip control (simpler geometry, one
  or two values, no radial hit-testing) should land well under the
  compound-dial estimate for a drag-only v1. Type-to-enter precision
  entry is the one piece with no cheap native equivalent inside a custom
  `jsui` — `live.numbox` gives it for free; a custom widget would need
  deliberate extra work to match it, reasonably deferred past v1.

## Next step

Paused here. Matt is looking at how existing Max4Live devices handle this
general problem (dense per-param controls, legible/clickable, presumably
under similar space constraints) before picking a direction — grounding
this in prior art rather than continuing to reason about it from first
principles. Resume by reviewing whatever that turns up against the
concepts list above.

## Cross-references

- `ideas/named_mod_textures.md` — the trigger; T1-T3's `gswitch` pattern
  is the direct precedent for the panel-wide mode-flip concept.
- `ideas/f_util_mod_texture.md` — the scalar/depth/texture triple and the
  unipolar/bipolar divergence this UI sits on top of (a different
  unipolar/bipolar question than the slider-fill one here — don't
  conflate the two).
- `ideas/f_util_compound_dial.md` — sibling idea blocked on the same
  UI-density question, LOE anchor for custom-widget estimates.
- `.specify/plan.md`, "UI density / control surface design" — the
  umbrella tracking entry this file now hangs off of.
