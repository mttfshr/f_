# Named mod textures — tagged texture messages on a single inlet

**Status:** UNVERIFIED HYPOTHESIS. Raised by Matt 2026-07-29. Nothing
built, nothing scratch-tested. The mechanism is plausible and partly
grounded in canonical Vsynth code (below), but the load-bearing claims
have **not** been tested in Max. Do not design anything on top of this
until the tests in "Verification plan" pass.

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
Result: _untested_

**T2 — multiple tagged streams on one inlet.**
Two texture sources, `[prepend a_tex]` and `[prepend b_tex]`, both
cabled into the *same* inlet, `[route a_tex b_tex]` inside, each to a
different `jit.gl.pix` inlet. Do both arrive every frame, or does one
clobber the other? Tests the many-cables-to-one-inlet claim, which is
the whole point.
Result: _untested_

**T3 — per-frame ordering / staleness.**
With T2 running, confirm no dropped or stale frames — e.g. drive the
two sources at visibly different rates and check neither freezes or
lags. Texture messages are per-frame; several sharing an inlet may
interleave badly.
Result: _untested_

**T4 — `vs_inState` compatibility.**
Vsynth modules put `vs_inState` on their inlets. Does a tagged texture
message pass through it, or does it choke / swallow the tag? Check
against a real Vsynth-conformant module, not a bare `jit.gl.pix`.
Result: _untested_

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
  how textures get routed
- `definition.py`'s existing `mod_inlets` key as the declaration site
- **masonry is not convention authority** (developed in isolation)

## Next step

Run T1. It is cheap, it is load-bearing, and until it passes this file
is speculation. Record results inline above with dates.
