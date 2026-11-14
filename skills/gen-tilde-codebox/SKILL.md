---
name: gen-tilde-codebox
description: Empirically verified rules for gen~ codebox code (GenExpr at audio rate, on the CPU) in Max/MSP. Use this skill whenever writing, reviewing, or debugging code inside a gen~ object, or building a scratch patch to test one, even if the user only says "gen~", "codebox" or "GenExpr". Load it especially on these symptoms: "patchcord inlet out of range" on a codebox; "extra arguments for message" on a Param; a gen~ patch that compiles but stays silent; a latch or History feedback loop stuck at 0; a Data/peek wavetable that steps or won't null; a scope~ that goes blank or a peakamp~ reading that makes no sense. Covers Param vs in1...inN inlets, reserved names, Data/peek/poke, History and latch, self-timed noise() randomization, and how to verify slow audio signals. For jit.gl.pix (the GPU dialect) use jit-gen-codebox instead: the two share syntax but not rules (noise() works in gen~ and fails on the GPU), so a finding from one does not carry over to the other unverified.
---

# gen~ Codebox Reference (audio domain)

**Canonical docs:** https://docs.cycling74.com/userguide/gen/gen_genexpr/

Empirically verified findings for GenExpr code inside `gen~` objects. This is
the CPU/audio-rate dialect — no texture inlets, no GL context, no
`jit.gl.pix`-specific coordinate globals (`norm`, `snorm`, `cell`, `dim`).
See `jit-gen-codebox` for the GPU dialect; the two are related but not
interchangeable, and at least one rule (`noise()`) is a direct reversal
between them. Importing GPU-path constraints wholesale into a `gen~` codebox
is an easy mistake if most of your codebox experience is GPU-side.

Findings are dated and were observed on Max 9. Items marked unverified or
hypothesis are exactly that.

---

## Quick rules

Each rule links to the section with the evidence; read that section when a
rule's reason matters for the case at hand.

1. **Use `in1`...`inN` in the code body for independent signal inlets;
   `Param` is only the single message inlet.** Extra `Param`s never create
   inlets, and Max deletes the extra patchcords. (Inlets)
2. **Keep at least one `in N` object in the gen~ subpatcher**, even if the
   code reads no signal; without it, `Param` messages never arrive and the
   patch is silently mute. (Inlets)
3. **Name one-shot trigger Params `trig`, not `reset`:** `reset` is a gen~
   built-in message and errors on every trigger. Suspect the same with other
   built-in-sounding names. (Reserved-word collisions)
4. **Don't use `latch` in a self-dependent feedback loop:** it starts at 0
   whatever the `History` initializer, and can deadlock. Use
   `x = trig ? target : held;`. (History and latch pitfalls)
5. **Read a `History` into a local before writing it** when its old value is
   needed after other work in the same block. (History and latch pitfalls)
6. **`peek` floors fractional indices; it doesn't interpolate.** Size `Data`
   tables generously before blaming the logic around them. (Data / poke / peek)
7. **`noise()` works in gen~** (fresh value in [-1, 1] per call); the GPU
   sin-hash workaround doesn't apply here. (Relationship to jit-gen-codebox)
8. **`pfft~` needs its subpatch as a separate file on disk;** `gen~`,
   `poly~` and `bpatcher` can embed theirs inline. (pfft~ as a gen~ container)
9. **When testing, freeze time behind a `run` Param, log to the console
   rather than reading live numbers, and use low test frequencies.**
   (Known-good patterns; Testing-methodology lessons)
10. **When a scope or meter looks wrong, check the meter first:** `scope~`
    blanks above about 200 Hz at default settings, and `peakamp~` is linear,
    not dB. (Testing-methodology lessons)

---

## Relationship to jit-gen-codebox

Shared: `Param`, basic math/trig operators, `twopi`/`pi`/other Constants,
`if`/`else`/`for`, user-defined functions (same `funcname(args) { ... return
val; }` syntax, declared before `Param` statements).

**Not yet cross-verified — treat jit.gl.pix findings as hypotheses here, not
facts, until independently confirmed in a gen~ codebox:**
- Component-access-on-stored-variable silent failure (`col = sample(...);
  col.x` -> black on GPU)
- `inN`-shaped variable name collision (`in0`, `in1`...) — note that in
  gen~, `in1`...`inN` are real signal-inlet keywords (see "Multi-inlet
  codebox signals" below), so don't use them as plain variable names here
  either
- `active` as a variable name colliding
- Variables first assigned inside a `for` loop being out of scope after it
- `Param` named `mix` colliding with the `mix()` operator
- Assigning to a predefined constant (`PI = ...`) failing to compile: found
  on Max 9.2.0 in a `jit.gl.pix` codebox (whole pix dead, params report
  "invalid message"). Plausibly the same compiler rule applies in `gen~`,
  but it has not been tried here. Don't assign to `pi`, `twopi`, etc.;
  use another variable name.

None of these have broken a gen~ codebox yet, but none have been
deliberately tested here either — if one of these patterns is suspected as
the cause of a gen~ bug, treat it as plausible (same general class of risk:
parser reads a token as a reserved word instead of an identifier) but
verify it directly rather than assuming the GPU-dialect writeup applies
unchanged.

**Confirmed present in gen~ but not documented for jit.gl.pix:**
- `History` — persists a value across samples (`History t(0)` declares a
  sample-persistent variable initialized to 0). Useful for one-shot gates
  and running accumulators (see below). Not mentioned anywhere in the
  jit-gen-codebox skill — likely a gen~-specific (or at least
  audio-rate-specific) keyword, not a general GenExpr feature.
- `Data` / `poke` / `peek` — table storage, read/write. See below.

**Reversed between the dialects:**
- **`noise()` is valid in gen~.** On the `jit.gl.pix` GPU path, `noise()`
  compiles silently but always outputs black, and the fix there is a sin
  hash. In gen~, `noise()` is a real, working operator returning a fresh
  value in [-1, 1] on each call (2026-07-27; per-call independence
  confirmed 2026-09-16, see the randomization pattern below). Do not
  reflexively swap it for a sin hash in audio-domain code; that GPU-path
  fix does not apply here.

---

## Reserved-word collisions (confirmed)

### `Param` named `reset` collides with a `gen~` built-in system message — confirmed 2026-08-05

Naming a `Param` `reset` and sending it a value via a `reset <n>` message
(the usual `prepend reset` -> gen~ inlet pattern for a one-shot trigger)
produced, on every single trigger:

```
gen~ • extra arguments for message "reset"
: bad number
```

`reset` is very likely a `gen~` built-in system message (probably for
clearing internal buffer/`History` state) that intercepts the message before
it reaches `Param` dispatch, rather than an ordinary available identifier.
Confirmed by direct A/B: error present with `Param reset(0)`, gone
immediately after renaming to `Param trig(0)` (and the outer `prepend reset`
-> `prepend trig`), no other change. Same *fix shape* as the `jit-gen-codebox`
skill's documented `mix()`-operator collision (rename only the internal
codebox identifier; UI-facing labels, `attrui`/`live.*` `varname`s, etc. can
keep the original name) — but a different word, in a different dialect,
found independently. Treat `reset` as reserved; if a similarly-named `Param`
(`clear`, `stop`, anything that sounds like a plausible built-in transport/
state message) produces the same error shape, suspect this same collision
class before suspecting wiring (unverified for those other words).

**Practical habit:** for one-shot trigger Params in gen~, use `trig` rather
than `reset`.

---

## `Data` / `poke` / `peek` — confirmed 2026-08-05

- **Argument order:** `poke(buf, value, index)` to write, `peek(buf, index,
  channel)` to read. Confirmed via a manual round-trip test (write 0.5 at
  index 10, read index 10, got exactly 0.5).
- **`peek` floors/truncates fractional indices — it does NOT interpolate.**
  `idx_test = 31.5` read back exactly `table[31]`, not an interpolated value
  between `table[31]` and `table[32]`. This is plausible, unbuggy default
  behavior for a table-lookup opcode, not itself a bug — but it has real
  consequences: a small `Data` table read with a slowly-incrementing
  fractional index will show *quantization* artifacts (a deterministic,
  phase-locked stepping error), not smooth interpolation. Confirmed as the
  root cause of a large structured residual in a wavetable-vs-per-partial
  null test at table size 64 — the same test passed cleanly once the table
  was sized up to 2048. **If a `Data`-table-based signal doesn't null against
  an expected reference, check table size relative to how many samples each
  table entry has to stand in for before suspecting the surrounding logic.**
  Not yet independently tested whether `peek`'s interpolation behavior
  (floor vs. round vs. something else) is table-size-dependent — treat the
  floor behavior as confirmed only at the table sizes actually tested (64,
  2048), not as a universal guarantee.

---

## Inlets: `Param` messages vs `in1`...`inN` signals

### Multi-inlet codebox signals — confirmed 2026-08-07

**Declaring multiple `Param`s does NOT create multiple physical codebox
inlets.** A per-bin FFT-processing codebox needed 10 true independent
per-sample signal inputs (real, imaginary, bin-index from `fftin~`, plus 7
control values). Declared all 10 as `Param`, wired 10 separate `in N`
pass-through objects to the codebox's 10 declared inlets (`numinlets: 10`
in the JSON). Result, every time:

```
codebox • patchcord inlet out of range: deleting patchcord
```

...nine times, for every inlet past the first. Max only ever recognized
**one** real physical inlet on the codebox, regardless of the declared
`numinlets` count or how many `Param`s existed in the code.

**Root cause:** `Param` is specifically the mechanism for the single shared
*message-dispatched* control inlet (`prepend paramname` → one inlet →
named message matched to the `Param`). It is not a general "declare an
inlet" mechanism.

**Fix:** for true independent multi-signal inlets, reference the built-in
`in1`, `in2`, ... `inN` keyword syntax **directly in the code body** —
no `Param` declaration for these at all:

```
// external "in N" pass-through objects still wired to the codebox exactly
// as before (in1 -> codebox inlet0, in2 -> inlet1, etc) -- that part was
// already correct. Only the CODE changed:

freq_bin = in3 * in10 / fftsize;
modband = (freq_bin >= in8) && (freq_bin < in9);
gain = modband ? (1.0 + in7 * mbin) : 1.0;

out1 = in1 * gain;
out2 = in2 * gain;
```

Confirmed: switching from `Param`-per-inlet to `in1`...`in10` eliminated
every `patchcord inlet out of range` error, with the exact same external
wiring otherwise unchanged. This is a different, unrelated mechanism from
the `inN`-as-variable-name *collision* documented for `jit.gl.pix` (naming
a plain variable `in0`/`in1` silently breaks output there) — here `inN` is
a real, intentional, working keyword.

**Rule of thumb:** `Param` for the one shared control inlet (settable by
name via message); `in1`...`inN` for genuine independent per-sample signal
inlets. Don't mix up which mechanism a given inlet actually needs.

### A gen~ codebox needs at least one `in` object for `Param` messages to arrive — confirmed 2026-07-27

Without an `in N` object present in the gen~ subpatcher — even when the
codebox uses no signal input at all and every parameter arrives as a
`Param` message — `Param` values never reach the codebox. The patch
compiles clean and runs, but is silent, with an empty console and no
error pointing at the cause. Confirmed empirically after two incorrect
assertions to the contrary.

---

## `History` and `latch` pitfalls — confirmed 2026-07-27

### `latch` zero-initializes regardless of any `History` initializer — deadlocks self-dependent feedback

`latch` outputs 0 before its first trigger, ignoring whatever initial
value a feeding `History` was declared with. In a self-dependent feedback
loop (a per-cycle accumulator whose own held rate depends on a trigger
that in turn depends on the accumulator advancing), this is a permanent
deadlock: `latch` outputs 0, the accumulator never advances, so the
trigger never fires, so `latch` never updates. **Use a self-referential
conditional instead of `latch`:**

```
// WRONG — deadlocks permanently in a self-dependent feedback loop
rate_h = latch(rate_target, trig);

// CORRECT
rate_h = trig ? rate_target : r_held;   // r_held read from History before this line
```

### Read every `History` into a local before writing it, when both happen in one block

Reading and writing the same `History` variable within one expression
block is the pattern that caused the `latch` failure above and is worth
treating as a general precaution in gen~: read the held value into a
local name first, use the local for computation, then write the
`History` once, near the end of the block.

```
r_held = rate_h;                       // read first
rate_target = ...;                     // compute using r_held
rate_h = trig ? rate_target : r_held;  // write once, using the local for the untriggered case
```

Simple single-read-then-single-write History updates (e.g. a plain
accumulator: `ph_acc = ph_prev + step; ...; ph_prev = ph_acc - trig;`)
are fine without a separate local — this precaution matters most when the
same History's old value is needed again *after* something else has
already been computed from it, which is exactly the shape that broke with
`latch`.

---

## Known-good patterns

### One-shot gate via `History` + a changed-value flag

Used for "only recompute this expensive thing when a trigger value changes"
(e.g. rebuilding a `Data` table only on an explicit render/trigger, not every
sample):

```
Param trig(0);
History rendered_flag(-1);

if (trig != rendered_flag) {
    // expensive one-shot work here (e.g. a nested for-loop table render)
    rendered_flag = trig;
}
```

The trigger value itself doesn't need to mean anything — an incrementing
counter fed by a button, sent as `trig <n>`, is enough; the gate fires
whenever `n` differs from the last-seen value. Confirmed 2026-08-05
compiling and running correctly through a ~410,000-iteration nested-loop
table render (2048 x 200) with no hang and no re-firing on subsequent
samples.

### Self-contained per-stimulus randomization via `noise()` + a time gate — confirmed 2026-09-16

The obvious way to "redraw a random value once per stimulus" is from
*outside* the codebox: a Max message-domain `random` object, triggered by
an external button click and fed in via `Param`. Works, but needs an
external button, a `counter` for the trigger value, and message-domain
wiring outside the codebox — real plumbing for something conceptually
simple.

**Cleaner pattern, confirmed working**: do the entire "pick a new random
value, hold it for N seconds, then repeat" cycle *inside* the codebox,
using `noise()` (valid in `gen~`, see "Reversed between the dialects"
above) sampled only at the instant a time-gate condition becomes true:

```
Param stim_dur(4.0);
History t(1000.0);      -- large initial value forces an immediate
                         -- first trigger on load, no external loadbang
                         -- needed to kick off the first cycle
History f0_h(150.0);

if (t >= stim_dur) {
    f0_h = f0_lo + (noise() * 0.5 + 0.5) * (f0_hi - f0_lo);  -- noise()
                         -- returns a fresh value in [-1,1] each call;
                         -- *0.5+0.5 remaps to [0,1] before scaling into
                         -- the target range
    -- ...any other one-shot per-cycle work (table rebuild, etc.)...
    t = 0.0;
}

-- ... later, unconditionally, every sample ...
t = t + 1.0 / samplerate;
```

Each call to `noise()` inside the gated block draws an independent fresh
value (confirmed: three separate calls for three separate randomized
parameters in the same block produced three independent draws, not the
same value three times). No external button, counter, or message-domain
`random` object needed — the whole per-stimulus lifecycle is self-timed
and self-contained. The `History` initial value trick (set it above the
trigger threshold) is a cheap way to make the first cycle fire
immediately on patch load without a separate `loadbang` chain for that
specific purpose.

### Freezing time for reproducible manual reads

When a scratch test needs a human to read a value produced by a
continuously-running time accumulator, **do not rely on reading fast enough**
— click-then-screenshot latency is not negligible against anything with a
multi-second period (an 8 s cycle, for example), and will produce readings
that look like noise but are actually just uncontrolled elapsed time. Gate
the time increment behind its own toggle, separate from the reset trigger:

```
Param run(0);   // off by default
History t(0);

// ... reset logic sets t = 0 elsewhere, unconditionally ...

if (run != 0) {
    t = t + 1 / samplerate;
}
```

With `run` off, `t` stays locked at exactly whatever the last reset set it
to (typically 0) indefinitely — read at total leisure, no timing race.
Flip `run` on only when you actually want the signal to move (e.g. to watch
a scope or log a time-series). Confirmed after an earlier attempt
without this pattern produced wildly inconsistent point-in-time reads.

### Deterministic multi-value logging via `trigger`

When printing/packing more than one snapshot-read value per event (e.g. a
`t, S, M` triple to the Max console), a single bang fanned out to multiple
`snapshot~` objects does NOT guarantee which one updates first — if they
feed a `pack`, the printed row can silently mix a fresh value with a stale
one from the previous tick. Force explicit ordering with `trigger` (`t b b
b`, one bang output per value needed), remembering Max fires trigger outputs
**right-to-left**:

```
[metro 200]
     |
[t b b b]              -- fires right-to-left: rightmost first
   |   |   |
   |   |   [snapshot~ M]  -- cold value, update first
   |   [snapshot~ S]      -- cold value, update second
   [snapshot~ t]          -- feeds pack's HOT (leftmost) inlet, fires LAST,
                             triggering pack's output using the now-current
                             S and M values alongside the fresh t
                |
            [pack 0. 0. 0.]
                |
            [print MyLabel]
```

The value that should trigger the combined row must be wired to `pack`'s
hot (leftmost) inlet and must be the *last* thing the trigger fires.
Confirmed producing coherent per-row console output.

---

## `pfft~` as a gen~ container — confirmed 2026-08-07

Unlike `gen~`, `poly~`, and `bpatcher` (which all happily embed their
subpatch content inline in the `.maxpat` JSON via a nested `"patcher"` key
— confirmed working repeatedly), **`pfft~` requires a real, separate
`.maxpat` file on disk**, loaded by name. Giving it an inline `"patcher"`
key produced, on load:

```
pfft~ • no patcher t7a_inner
: bad number
```

...and Max silently stripped the (unusable) inline content back out on
save, leaving `numinlets`/`numoutlets` at 0. Fix: extract the subpatch
content into its own file (e.g. `t7a_inner.maxpat`) in the same folder as
the parent patch, and give `pfft~` a plain `text` argument naming it
(`pfft~ t7a_inner 2048 4`) — no `"patcher"` key on that box at all.

A `gen~` nested *inside* that external `pfft~` subpatch file still embeds
inline exactly as usual — this only applies to `pfft~` itself, not to
objects nested within it.

---

## Codebox source in `.maxpat` JSON

When hand-writing or scripting a `.maxpat`, the GenExpr source goes under
the `code` key, not `text` (writing `text` silently gives the default
template). Details in `maxpat-json-authoring`.

---

## Testing-methodology lessons

- **Low test frequencies make waveform shape legible.** A signal with many
  compressed cycles in one scope window is easy to misread — a correct
  signal and a broken one can look nearly identical from a description of
  the pixels. Drop to a frequency low enough that 1-3 cycles are visible
  before trusting a scope-based shape judgment. (Found while debugging a
  phase accumulator; applies to any gen~ scratch test using `scope~`.)
- **"Eyeball a scope for a *change in rate*" is not a reliable verification
  method**, even at a legible frequency — a human can readily see whether a
  waveform is present/absent/roughly-periodic, but not reliably perceive
  subtle frequency modulation by eye. If the thing under test is "does rate
  X track slowly-varying parameter Y," build a numeric spot-check (known
  inputs -> hand-computable expected output, compared against a live
  readout) instead of relying on visual impression.
- **A live-updating flonum readout has the same problem as a scope, for the
  same reason: rate of display update is not the same thing as rate of
  underlying change, and a human watching a number refresh every 15ms will
  perceive "fast" regardless of whether the real signal underneath is
  moving slowly.** A jumpy on-screen flonum was once genuinely ambiguous
  between "real fast artifact" and "slow real signal, fast display."
  **Default to logging a real time-series to the Max console (`print`)
  instead of reading a live number off the patch, any time the question is
  about a signal's rate, period, or trend over time** — a printed list of
  values can be scanned for an actual period (count rows between
  repeats/peaks) or compared for exact repeats (a strong, cheap tell for a
  fixed short cycle, as opposed to noise), neither of which a glance at a
  moving number supports. Treat this as a standing default for this kind of
  question, not a one-off workaround — prefer building the console log from
  the start rather than reaching for it only after a live readout turns out
  ambiguous.

### Metering/display objects can be the broken thing, not the signal under test — confirmed 2026-09-16

Two separate cases in the same session where a metering/display object's
own limitation was initially mistaken for a DSP bug in the signal being
measured. Worth treating as one lesson: **when a scope or meter shows
something wrong (blank, nonsensical, or unexpectedly extreme), check
whether the *display/measurement object itself* has a known limitation at
these settings before concluding the signal under test is broken.**

- **`scope~` stops rendering above a certain fundamental-frequency-to-
  display-window ratio.** Above roughly f0≈200 Hz (at default `scope~`
  settings), the display went completely blank — no trace at all — while
  the actual audio signal was still present and correct (confirmed by
  adding a `dac~` tap and hearing sound at the exact settings where the
  scope showed nothing). This is a `scope~` display limitation, not a DSP
  problem. Don't trust a blank `scope~` as proof of silence without an
  independent check (listen via `dac~`, or read a different metering
  object) first, especially at higher fundamental frequencies.
- **`peakamp~` reports peak amplitude as a linear ratio, not decibels.**
  Assumed dB (the more common convention for Max metering objects) through
  several rounds of confusing, seemingly-nonsensical readings (numbers that
  never went negative, never approached zero, and didn't match expected
  dB-scale magnitudes) before empirically confirming linear output — a
  `[peakamp~] -> [atodb]` chain, or checking the object's own Reference/
  Help patch, gives the actual dB number. **Don't assume a Max metering
  object's output units — verify by feeding it a known reference value (or
  checking its Reference doc) before trusting a chain of readings,
  especially before concluding a measured value is anomalously large or
  small.**

Root-cause note for future confusion of this shape: when a measurement
comes back looking wrong (blank, or a magnitude that doesn't fit the
mental model), the failure could be in either half of the setup — the
signal under test, or the meter/display observing it. Rule out the
meter first if it's cheap to do so (an independent listen, a different
object, a known-reference-signal sanity check) before spending time
debugging the DSP.

---

If a `local.md` sits next to this file, read it too: it holds project-specific
tooling and conventions that extend this skill.
