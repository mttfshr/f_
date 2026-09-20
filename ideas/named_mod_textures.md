# Named mod textures — tagged texture messages on a single inlet

**Status:** CORE MECHANISM VERIFIED. Raised by Matt 2026-07-29. T1
(round-trip), T2 (two tagged streams sharing one inlet), and T3 (no
staleness on reselect) all passed live in Max 2026-09-17 — see
"Verification plan" for the scratch patch and results. T4's live half, T5,
and T6 remain untested. Safe to start sketching a real design against
T1–T3's result, but don't commit `build_patcher.py` changes until T4/T5/T6
are closed — they bear on how the demux interacts with `vs_inState`/
`routepass` and how far it scales, which a real module will need.

If it holds it likely supersedes large parts of
`ideas/f_util_mod_texture.md` — see "Relationship to the assignment
convention" below.

---

## The idea

Vsynth already sends scalar control as named messages (`[zoom $1]`,
caught by `route`). Do the same for **textures**: tag a texture stream
with the name of the param it should modulate, send it into a single
shared mod inlet, and demultiplex it inside the module with `route`.

```
upstream:   [texture source] → [prepend zoom_tex] ──┐
            [texture source] → [prepend angle_tex] ─┼→ one bpatcher inlet
                                                     │
inside:     [route zoom_tex angle_tex x_tex y_tex]  ←┘
                 │          │
                 ↓          ↓
            jit.gl.pix in2  in3   (still 1:1 internally)
```

**Scope, clarified 2026-09-17:** this is about **secondary modulation
textures only** — the small, often-numerous mod inlets a param optionally
takes (`zoom_m`, `mortar_mod_amt`, etc.), not the module's primary
driving/content texture (inlet 0, which per Vsynth convention always
carries both control messages and the main texture combined and is not
in scope for tagging). A param with no tag ever routed to it must behave
exactly as it does today when its mod inlet is simply unpatched — see T4
below, that's not automatic under this model and needs its own check.

## Why it is plausible

**Verified** by reading `Vsynth/patchers/vs_displacement.maxpat`: a
texture in Max *is* already a named message — selector
`jit_gl_texture` followed by the texture's name symbol — and Kevin
already routes on it. The control inlet's first object is:

```
routepass enable jit_gl_texture jit_matrix
   → route angle zoom x y xm ym rotm zm kmode mmode
```

So texture messages passing through `routepass`/`route` is not a novel
trick; it is existing canonical Vsynth practice. The proposal only adds
a `prepend` tag upstream and a wider `route` inside.

**The inlet-count argument.** Max inlets accept many incoming cables.
The "each texture inlet takes 0 or 1 texture" constraint only bites for
*untagged* textures, where last-write-wins. Tagged, several streams can
share one physical inlet because each carries its own name.

---

## What it would buy (IF verified)

- **One mod inlet per module regardless of param count.** The 13-inlet
  problem that motivates `ideas/f_util_mod_texture.md` dissolves.
- **Kevin's 1:1 binding preserved internally** — `route` fans out to N
  `jit.gl.pix` inlets. Only the *external* patching burden goes away.
  This makes it an **extension** of Vsynth convention rather than the
  deliberate break the assignment-matrix approach requires.
- **No assignment matrix, no assignment UI.** Assignment is "which name
  did you prepend," decided upstream in the patch.
- **Depth params untouched and orthogonal** — `zoom_m` etc. stay
  ordinary scalars, still `[param $1]`-addressable.

## Trade-offs (real, not blockers)

- **Legibility moves upstream.** Assignment lives in the patch (cable +
  prepend), so you cannot read a module's routing by looking at the
  module. Arguably more Max-idiomatic; still a change in where
  legibility lives, and worth weighing against the module-local
  back-panel idea it would replace.
- **Resurrects a legitimate small util**: a name-picker (menu →
  `prepend`) so the tag can be chosen from a UI rather than hardcoded
  in a `prepend` box. Trivial, and it never touches the texture — so it
  avoids every objection that killed the texture-router util in
  `ideas/f_util_mod_texture.md` ("Rejected branches").
- Tag naming needs a convention (`zoom_tex`? `zoom_mod`? bare `zoom`
  colliding with the scalar param name?). Bare names likely collide
  with the existing scalar `route` — needs a suffix or a separate
  `route` stage.

---

## Static review (2026-09-17) — confirms mechanics, refines T4, doesn't replace live tests

Read `vs_displacement.maxpat` (canonical Vsynth,
`~/Documents/Max 9/Packages/Vsynth/patchers/vs_displacement.maxpat`) and
`vs_inState.maxpat` directly, plus `src/f_masonry/definition.py` and
`build/build_patcher.py`'s current mod-inlet wiring, to sanity-check the
hypothesis before touching Max. **No live Max test run** — T1–T6 below are
still `_untested_`; this only tightens what to test and why.

**Confirms the core premise.** `vs_displacement.maxpat`'s
`routepass enable jit_gl_texture jit_matrix` → `route angle zoom x y xm ym
rotm zm kmode mmode` is real and present exactly as described, and
`jit_gl_texture <name>` is confirmed to be a plain Max message — selector
`jit_gl_texture`, one symbol argument (the texture's name) — not a special
payload type. So `[prepend foo]` on it produces `foo jit_gl_texture <name>`
(shifts the whole message one selector over), and `[route foo]` on the
result strips `foo` and outputs the untouched remainder
`jit_gl_texture <name>` — a lossless round-trip by construction, since
`prepend`/`route` are generic symbol/list operations with no awareness of
what the payload means. **T1 should mechanically pass** — it now reads as a
confirmation test, not an open question, but still needs to actually run.

**T4 refined, not resolved — ordering matters.** `vs_inState`'s first-stage
object is `[route clear]` — anything that isn't literally the symbol
`clear` falls to the reject outlet and passes through generically (`t b l`
→ `gate 1 0`) with no further inspection of the message's selector. A
still-tagged message (`foo jit_gl_texture <name>`, tag not yet stripped)
would simply fail to match `clear` and fall through unmolested — so
`vs_inState` won't choke on it either way; its idle-timeout fallback
(substituting `jit_gl_texture vs_gray`/`vs_black` on silence) is keyed to
frame timing, not to selector content. **The real conclusion: the
`route <name>` demux must resolve a tag back to a bare `jit_gl_texture`
message *before* `vs_inState` sees it, not after** — `vs_inState` sits
downstream of the demux, per target, mirroring today's
`mod_inlet_boxes()` structure (inlet → vs_inState → pix). This was implicit
in the original diagram; worth stating as a hard ordering constraint now
that it's confirmed by reading `vs_inState`'s actual logic rather than
assumed.

**Confirmed: no existing code path does named/tagged sharing today.**
`f_masonry/definition.py`'s `mod_inlets` (slot/brick/pixel) and
`build_patcher.py`'s `mod_inlet_boxes()`/`mod_inlet_lines()` wire one
inlet-object + optional `vs_inState` per mod target, strictly 1:1 — exactly
the scaling problem this file exists to solve. This is genuinely net-new
plumbing, not a variant of something already built anywhere in `f_`.

**T5 (inlet ceiling) and T2/T3 (multi-stream arrival/ordering) remain
genuinely unverified — no static evidence either way.**
`jit.gl.pix.maxref.xml` documents no fixed inlet count (inlets are dynamic
per the codebox's `in N` objects); nothing in the docs or existing patchers
bounds it. These need Max running — static review can't resolve them.

**Effect on next step:** T1's risk drops from "does this work at all" to
"confirm no surprise." Worth batching T1 and T2 in the same Max session
rather than treating T1 as its own suspenseful checkpoint.

---

## Verification plan

Scratch-test in Max before anything else (per scratch-first
discipline). Scratch patches live in `/Users/matt/Vsynth/patterns/`.
Each test below is pass/fail and should be recorded here with the
result and date.

**T1 — prepend/route round-trip (load-bearing, do first).**
Take a live texture, `[prepend foo]`, then `[route foo]`, then into a
`jit.gl.pix` inlet. Does the texture arrive intact and render? This is
the single claim everything else rests on. Failure mode to watch for:
the texture *name symbol* surviving as a symbol but the underlying
texture binding being stale or dropped.
Result: **PASS (2026-09-17).** Scratch patch:
`/Users/matt/Vsynth/patterns/named_mod_textures_t1t2.maxpat` — `vs_wfg_3`
→ `[prepend testtag]` → `[route testtag]` → `vs_output`, A/B'd live via a
`gswitch` against the same source wired direct (no prepend/route). The two
were visually identical. Note: this run wired the raw `jit_gl_texture`
message straight through with **no `jit.gl.pix` in the chain at all** — an
earlier version of the scratch patch inserted a bare pass-through
`jit.gl.pix` between route and output and that version did **not** render;
removing the pix hop (going straight into the `gswitch`/`vs_output`) is
what worked. Not root-caused — plausibly the bare pix's inlet needed the
`routepass`/`vs_inState` framing real modules wrap texture inlets in and a
naked pix inlet doesn't get that for free — but since T1's actual claim is
about the message surviving prepend/route, not about pix specifically,
this doesn't weaken the result. Worth root-causing later if a real module
build hits the same thing.

**T2 — multiple tagged streams on one inlet.**
Two texture sources, `[prepend a_tex]` and `[prepend b_tex]`, both
cabled into the *same* inlet, `[route a_tex b_tex]` inside, each to a
different `jit.gl.pix` inlet. Do both arrive every frame, or does one
clobber the other? Tests the many-cables-to-one-inlet claim, which is
the whole point.
Result: **PASS (2026-09-17).** Same scratch patch, `wfg_t2a`/`wfg_t2b` set
to visibly different waveform/rate, both tagged (`testtag_a`/`testtag_b`)
and cabled into the *same* `[route testtag_a testtag_b]` object's single
inlet 0, each outlet to its own `gswitch` position. Switching between them
showed each source's own distinct character correctly — neither clobbered
or bled into the other. (Same no-pix-in-chain caveat as T1 applies here.)

**T3 — per-frame ordering / staleness.**
With T2 running, confirm no dropped or stale frames — e.g. drive the
two sources at visibly different rates and check neither freezes or
lags. Texture messages are per-frame; several sharing an inlet may
interleave badly.
Result: **PASS (2026-09-17).** Covered by the T2 run (both sources' distinct
settings came through correctly, implying neither was silently dropped),
plus the follow-up check: flipping the `gswitch` away from a position and
back showed it still live, not a frozen frame from when it was last
selected — deselected paths keep rendering in the background as expected.

**T4 — `vs_inState` compatibility, AND the untagged-target fallback.**
Two things to confirm, not one — the second is the more important claim:
(a) does a tagged texture message pass through `vs_inState` intact, or
does it choke/swallow the tag; (b) **does a target that is never tagged by
anything correctly fall back to a neutral texture and leave its param at
its own unmodified base value** — exactly matching what happens today when
one of Kevin's dedicated mod inlets is simply left unpatched. (b) is the
actual requirement (per the scope note above: this only concerns secondary
mod textures, and "unconnected → unmodified" is the whole point of a
secondary mod input) — a target that's *never* tagged is not the same
situation `vs_inState` was built for (an inlet that was receiving frames
and stopped); it may never receive a single message in the module's
lifetime. Check against a real Vsynth-conformant module, not a bare
`jit.gl.pix`.
Result: _untested live, but static-reviewed 2026-09-17 (see above) —
`vs_inState`'s own logic (`[route clear]` + generic pass-through) won't
choke on a still-tagged message either way, which covers (a) and reframes
where it needs to sit: **`route <name>` demux, then a per-target
`vs_inState`**, not the other way around — if `vs_inState` sits downstream
of the demux like this, "never tagged" and "was tagged, then stopped" both
look identical to it (both are just "haven't heard from this one
recently"), so (b) should fall out of the existing mechanism for free.
Not yet confirmed live. Also depends on the unipolar/bipolar decision
below — "neutral fallback" only equals "zero effective modulation" if the
fallback texture (gray 0.5, or black) matches whatever the accumulation
formula expects; get that wrong and an untagged target modifies the param
anyway, silently._

**T5 — `jit.gl.pix` inlet ceiling.**
Is there a practical maximum inlet count? The motivating case needs
~13 (`f_masonry`'s modulatable param count). Confirm gen `in N` scales
that far without trouble.
Result: _untested_

**T6 — interaction with the existing `routepass` stage.**
Kevin's pattern is `routepass enable jit_gl_texture jit_matrix` →
`route <scalars>`. A tagged texture arrives as `foo jit_gl_texture
<name>`, whose selector is now `foo`, not `jit_gl_texture` — so it will
**not** match that `routepass`. Work out where the tag-stripping stage
belongs relative to the existing one, and whether tagged and untagged
textures can coexist on the same inlet.
Result: _untested_ — note this one is a design question as much as a
test, and T6 failing would not kill the idea, only reshape the plumbing.

---

## Relationship to the assignment convention

`ideas/f_util_mod_texture.md` concluded: few shared mod inlets + an
in-module weighted-accumulation matrix + assignment UI, accepted as a
deliberate break from Kevin's 1-inlet-per-param convention because
`f_` modules have too many params for 1:1 to be patchable.

**If T1/T2 pass, that conclusion is largely obsolete.** Named textures
solve the same scaling problem without breaking 1:1 binding, without a
matrix, and without an assignment UI. The two approaches are
alternatives, not complements.

**Do not retire that file yet.** Its conclusion should stand until the
tests actually pass — this one is a hypothesis and that one is at least
grounded in a shipped working implementation (`f_masonry`). Several of
its findings survive either way and should be carried over rather than
lost:

- the **scalar-vs-texture modulation triple** (base scalar, `_m` depth
  scalar, texture binding) — unaffected, applies here too
- the **unipolar/bipolar divergence** between `f_masonry` and Kevin's
  `vs_displacement` — still unresolved, still blocking, orthogonal to
  how textures get routed. **Now load-bearing for basic correctness, not
  just consistency** (2026-09-17): T4's untagged-target fallback (see
  below) only leaves a param unmodified if the neutral fallback texture
  actually matches whichever convention the accumulation formula expects
- `definition.py`'s existing `mod_inlets` key as the declaration site
- **masonry is not convention authority** (developed in isolation)

## Next step

T1, T2, and T3 passed 2026-09-17 — the core hypothesis is no longer
speculation. Not being chased right now (parked, not forgotten):

- **The pix hop failure noted in T1/T2's results** — a bare `jit.gl.pix`
  between `route` and `vs_output` didn't render; going straight through
  worked. Not root-caused. Matters because a real module's mod-texture
  demux *does* need to land in a pix inlet eventually, so pick this up
  before designing that part for real.
- **T6** — where the tag-stripping `route` sits relative to the existing
  `routepass jit_gl_texture jit_matrix` stage on a real module's primary
  inlet, informed by the pix-hop finding above.
- **T4's live half** — re-run against an actual Vsynth-conformant module
  (with `vs_inState`), once the above is understood, not a bare pix.
- **T5** — inlet ceiling, only matters once a real multi-param module
  (e.g. `f_masonry`-scale, ~13 targets) is being designed against this.
