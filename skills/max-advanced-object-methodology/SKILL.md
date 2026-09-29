---
name: max-advanced-object-methodology
description: Mandatory workflow for any Max/MSP/Gen object outside Claude's well-worn set (gen~ codeboxes, jit.gl.pix, basic UI objects). Use BEFORE writing any patch, wiring, or codebox involving an object not already covered by an existing project skill. Exists because the alternative — architecting from the reference docs' prose and debugging failures after the fact — burned an entire session on f_a_ripple's T7a (pfft~) without ever finding the root cause. Read this before touching pfft~, poly~, fft~/ifft~, mc.*, or any other object family not yet in this project's skill set.
---

# Advanced Object Methodology

**This skill exists because of a specific, expensive failure.** `f_a_ripple`'s
T7a scratch test (2026-08-07) spent an entire extended session trying to get
a `depth` parameter into a `pfft~`-nested `gen~` codebox. Four different
inlet/routing architectures were built, each compiling cleanly, each
producing audibly-different output from the last, and **none of them ever
made `depth` do anything** — confirmed by direct A/B listening at `depth=0`
vs. `depth=100`, a control-value print tap before `pfft~`, a print tap
*inside* `pfft~` at the message inlet, a hand-typed message bypassing the
entire control chain, a rename to rule out a reserved-word collision, and
`@nocache 1` plus a full Max restart to rule out compile caching. **The root
cause was never found.** Every fix was a plausible-sounding guess based on
reading `.maxref.xml` reference prose, not on a verified working example —
and Cycling '74's own example patches (`Examples/gen/pfft.pfftgen.maxpat`),
when finally read partway through, revealed the actual idiomatic pattern
looks nothing like any of the four architectures tried. That discovery came
*after* the guessing, not before it, because the help patches and example
patches weren't checked until explicitly requested.

**The rule going forward, unconditionally:** for any object outside the
small set this project already has empirical, working experience with —
before writing a single line of integration code —

## 1. Read the actual help patch and example patches, not just reference prose

`.maxref.xml` files (`/Applications/Max.app/Contents/Resources/C74/docs/
refpages/`) describe *arguments and messages*. They do not reliably show
*idiomatic working structure* — how real patches actually combine an
object with the others it's meant to be used alongside. For that:

- **Help patches:** `/Applications/Max.app/Contents/Resources/C74/help/
  <category>/<objectname>.maxhelp`, plus whatever subpatcher files it loads
  (check for `<objectname>_loadme*.maxpat` alongside it — help patches for
  container objects like `pfft~` often load a separate subpatch file that's
  the actual demonstrated content).
- **Example patches:** `/Applications/Max.app/Contents/Resources/Examples/`
  — search by object name or category (`find /Applications/Max.app -iname
  "*<objectname>*"` surfaces help files, example patches, snippets, and the
  external itself in one pass). For Gen-family objects specifically, check
  `Examples/gen/` — these are usually small, real, working demonstrations of
  exactly the kind of integration this project needs, built by the people
  who wrote the object.
- Read the actual **JSON structure** of at least one working example before
  designing an original architecture from scratch. If a project convention
  (e.g. this project's `Param`-in-a-shared-inlet pattern for ordinary
  `gen~`) doesn't obviously extend to the new object, that's a signal to go
  find a worked example of the new object specifically — not to assume the
  familiar pattern generalizes and debug from there if it doesn't.

**Do this even when reference-doc prose feels sufficient to proceed.** The
T7a failure didn't happen because the `.maxref.xml` docs were skipped —
they were read carefully, upfront, for `pfft~`, `fftin~`, `fftout~`,
`cartopol~`, `poltocar~`. The docs were simply the wrong source for the
specific question ("how does a control value actually get into a per-bin
`gen~` inside `pfft~`") — only a worked example answered it, and it was
never consulted until asked for directly.

## 2. Build the smallest possible verified increment before adding complexity

Do not architect a full multi-hundred-line integration (control chain +
message packing + nested containers + per-bin math) and then debug it as
one unit when it doesn't work. Build one new mechanism at a time, confirm
it does the one thing it's supposed to do, *then* add the next layer:

- New container object (`pfft~`, `poly~`, etc.) — first confirm a trivial
  pass-through works and is audible/visible, before adding any processing
  inside it.
- New way of getting a value from outside into a nested structure — first
  confirm a single hardcoded test value can move from the outer patch to
  a directly-observable readout at the innermost point, before wiring the
  value into any real computation.
- Suspect arithmetic or logic — isolate it in the simplest tool already
  proven to work (an ordinary top-level `gen~`, no unfamiliar container),
  with hand-typed stand-in inputs, before assuming a bug lives in the more
  complex integration. (This part of the methodology *did* get followed in
  T7a — the standalone `bandcheck` patch correctly isolated and confirmed
  the frequency/band arithmetic — and it worked exactly as intended: a
  real, valuable negative result, cheaply obtained. Apply the same
  isolation instinct to container/routing mechanics, not just to
  arithmetic.)

Each increment should have an unambiguous, low-interpretation pass/fail
readout — a console print of a real value, not a live flonum, not a
subjective listening impression (see the existing testing-methodology
notes in `gen-tilde-codebox/SKILL.md` on why quantitative logging beats
live readouts).

## 3. Eliminate guesswork — treat an unconfirmed assumption as untested, not as background knowledge

A specific discipline for reporting to the user: when a fix is proposed
based on reading documentation rather than a verified working example,
say so plainly — "this is my best reading of the docs, not something I've
seen demonstrated working" — rather than presenting it with the same
confidence as an empirically-confirmed pattern. T7a's post-mortem showed
several fixes presented as corrections ("the real fix is...") that were,
underneath the confident framing, still guesses built on documentation
prose. Confidence framing should track actual evidence, not the
plausibility of the reasoning that produced the guess.

When several independent, structurally-different attempts all fail
identically, that is itself informative — it means the shared assumption
underneath all of them (not any one specific implementation detail) is
probably wrong, and is worth naming explicitly as the next thing to
question, rather than continuing to vary implementation details around an
unexamined shared premise.

## When this skill applies

Any object or object family without an existing empirically-tested skill
in this project. Currently covered (do NOT need this extra research step,
though it never hurts): `gen~` codeboxes (`gen-tilde-codebox`), `jit.gl.pix`
codeboxes (`jit-gen-codebox`), standard Vsynth bpatcher UI objects
(`vsynth-bpatcher`). Currently NOT covered, and genuinely uncertain even
after a full session's attention: `pfft~` control-value routing into a
nested `gen~` (`pfft-spectral-processing` — see that skill's "STILL
UNRESOLVED" section). Anything else not yet touched in this project:
assume it needs this research step, including objects that sound similar
to something already covered (`poly~` is not `gen~`; `mc.*` objects are
not their non-mc counterparts).
