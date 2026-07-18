# Idea: build_patcher.py schema gaps — downstream-target params, panel_toggle

_Created: 2026-07-15_
_Status: Mostly DONE 2026-07-15 (same day) — see Resolution below. Kept as
a record of the original problem and one still-open piece._

---

## Origin

Surfaced while regenerating `f_lens.maxpat` from `.specify/f_lens/definition.py`
during the v2 ghost-images build. A structural diff between the live
shipped patcher and the regenerated output showed the regeneration would
have silently dropped two real, working UI features — not because
anything was broken, but because `definition.py`'s schema (per
`build/spec.md`) has no way to represent either of them. `f_lens`'s own
`definition.py` had been carrying an incorrect comment claiming these
were "not yet wired in codebox -- UI-only for now," which turned out to
be wrong in a specific way: they're not internal/unwired at all, they're
real live-dial, route-dispatched params — just targeting a different
object than the primary pix.

---

## Gap 1: downstream-target params

**Problem:** `f_lens`'s `tilt`/`tilt_axis`/`tilt_pos`/`slope`/`mode`
have real `live.dial`/`live.text` UI and real `route` dispatch, but
their messages target `jit.fx.cf.tiltshift` (a separate object
downstream of the primary `lens_pix`), not the primary pix's message
inlet. The current param schema has exactly two categories — a normal
param (dial/numbox/menu, always routes to the primary pix) and
`"internal"` (no UI, no route entry, codebox-only) — with nothing in
between for "has UI and route dispatch, but targets a non-primary
object."

**Candidate fix:** a new param variant, something like:
```python
{
    "name": "tilt", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0,
    "label": "Tilt",
    "target_object": "tiltshift",   # symbolic id of a declared secondary object
    "target_attr": "blur_amount",   # attribute name on that object, if different from param name
}
```
Would need a way to declare the secondary object itself (`tiltshift`)
in `definition.py` — possibly reusing/extending the existing
`pix_chain` mechanism (which already models a primary + support objects
with cross-wiring), since `jit.fx.cf.tiltshift` downstream of `lens_pix`
is structurally similar to a `pix_chain` support node, just a non-pix
object type.

## Gap 2: `panel_toggle` / front-back panel switching

**Problem:** `f_lens` has a real, working front/back panel toggle
(`panel_toggle` button + `lens_toggle.js`, switching visibility between
a "front" set of dials and a "back" set) — entirely hand-built in Max,
not represented anywhere in `definition.py`'s schema. This is plausibly
a **generalizable UI feature**, not an `f_lens`-specific one-off — any
module with more params than comfortably fit one panel could want it
(this session's own Phase 0 T005 panel-layout discussion for `f_lens`
v2 flagged the same underlying density problem, resolved for now by
just putting everything on one panel rather than reaching for this
mechanism).

**Candidate fix:** a `panel_toggle` key at the top level of
`definition.py`, declaring which named params belong to a "back" panel;
`build_patcher.py` generates the toggle button, `lens_toggle.js`-style
wiring, and visibility-switching logic automatically. Needs Matt's
input on whether `lens_toggle.js` itself should become a shared,
generically-named JS file (like `bypass_toggle.js` already is) rather
than staying `f_lens`-specific in name.

---

## Why this matters beyond `f_lens`

Until both gaps are fixed, **`definition.py` cannot be trusted as a
safe source for full regeneration of any module that uses either
pattern** — running `build_patcher.py` against an otherwise-accurate
`definition.py` would silently produce a patcher missing real, working
UI. `f_lens` is the first place this was caught, but the underlying gap
is in shared build infrastructure (`build/`), so it could resurface on
any future module reaching for a downstream secondary object or a
multi-panel layout.

## Not yet decided

- Priority / when to pick this up — not scheduled.
- Whether `target_object`/`target_attr` should reuse `pix_chain`'s
  existing mechanism or be a genuinely separate concept (`pix_chain`
  nodes are pix objects; `jit.fx.cf.tiltshift` is not).
- Whether to backfill `f_lens`'s `definition.py` with a corrected,
  accurate representation once the schema exists, or leave it as a
  known-incomplete record until `f_focus` ships and the tilt-shift
  params are removed from `f_lens` entirely (at which point Gap 1
  becomes moot for this specific module, though it'd still apply to
  whatever future module needs the same pattern).

---

## Resolution (2026-07-15, same day)

**Gap 2 (`panel_toggle`) — fully resolved as originally scoped.**
`build_patcher.py` now has real `panel_toggle` schema support:
declare `{"front": [...], "back": [...], "front_label": str,
"back_label": str}` in `definition.py`, and the build generates the
toggle button, a per-module toggle JS file (written to
`package/javascript/<prefix>_toggle.js`), and all wiring automatically.
Also fixed a prerequisite bug found along the way: `label_box()` wasn't
setting a `varname` at all, so param labels couldn't be targeted by
`script sendbox` — needed for any toggle mechanism to hide/show labels,
not just this one. `f_lens`'s own `definition.py` now uses this for
real, generating `lens_toggle.js` (functionally equivalent to the
original hand-built version, extended with the new ghost params).

**Gap 1 (downstream-target params) — resolved for the general case, via
a narrower mechanism than originally proposed.** Once the actual tilt-
shift wiring was traced (see `f_lens/plan.md` ADR-6 addendum for the
trace), it turned out to involve genuine bespoke per-param transform
logic (`lens_tiltcenter.js` combining `tilt_axis`+`tilt_pos`; a
`sel`-based dispatch for `mode`) — not just "route to a different
object." That specific bespoke case is handled by `raw_ui` +
`raw_boxes`/`raw_lines` (verbatim splice, no schema understanding
needed) rather than a generic mechanism, since it was scheduled for
deletion the moment `f_focus` ships anyway.

But the *narrower*, more common case — "a param needs real generated
UI, just targeting a different object's matching-named attribute, no
custom transform" — turned out to have a clean answer after all, found
while building halation (same day): **`pix_target` on a normal param**.
Since `jit.gl.pix` attrui messages are generic attribute-set messages,
bound by name on whichever object receives them, a normal param's
existing dial/label/route-dispatch generation didn't need to change at
all — only the final attrui wire's destination did. `pix_target` accepts
either a `pix_chain` node id or a literal `raw_boxes` object id, so it
works whether or not the primary pix itself uses `pix_chain`. This is
the mechanism halation actually uses (`raw_boxes` for the manually-
declared support pix object itself, `pix_target` for its two real,
fully-UI-generated params) — genuinely reusable, not an `f_lens`-only
hack.

**One real follow-up surfaced during this work, not yet fixed:** the
`panel_toggle` JS-file-writing side effect in `build_patcher.py` isn't
gated by output path — a build call that only writes its `.maxpat`
output to a scratch/dry-run path still unconditionally overwrites the
live `package/javascript/<prefix>_toggle.js`. Caught when a supposed
"dry run" during `f_lens` v2 testing silently overwrote the live
`lens_toggle.js` (harmlessly, in that instance — the content was
correct — but the principle stands). Needs a `dry_run` flag threaded
through `build()` before this bites someone on a module where the
generated content *isn't* what was wanted yet.

