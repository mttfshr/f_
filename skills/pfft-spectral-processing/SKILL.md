---
name: pfft-spectral-processing
description: Canonical reference for building spectral/FFT-domain audio processors with pfft~ in f_a_ modules (e.g. f_a_decorrelate). Use when writing, reviewing, or debugging any pfft~ subpatch. RESOLVED 2026-08-07 -- getting a live control value into per-bin pfft~ processing does NOT work reliably via a gen~ nested inside pfft~ (four architectures tried, all failed identically, root cause never found). The working solution uses buffer~/index~/peek~/expr instead -- see "THE WORKING PATTERN" below, which supersedes any gen~-inside-pfft~ approach for this purpose. See gen-tilde-codebox for codebox syntax that still applies to any gen~ used elsewhere (e.g. the carrier/control-value generators outside pfft~).
---

# pfft~ Spectral Processing Reference

**Read `max-advanced-object-methodology/SKILL.md` before writing any new
`pfft~` integration.** This file's own history — four failed architectures
before the actual working pattern was found by reading Cycling '74's own
example patches — is the case study that skill exists to prevent repeating.

**Canonical docs:** `.maxref.xml` files at `/Applications/Max.app/Contents/
Resources/C74/docs/refpages/msp-ref/` — `pfft~`, `fftin~`, `fftout~`,
`index~`, `peek~`, `buffer~`. **Also check help patches and example
patches, not just reference prose** — `/Applications/Max.app/Contents/
Resources/C74/help/msp/pfft_loadme*.maxpat` and, critically,
`/Applications/Max.app/Contents/Resources/Examples/gen/pfft.pfftgen.maxpat`
and `/Applications/Max.app/Contents/Resources/Examples/fft-fun/lib/
fp_fft.maxpat` — these two show the actual working idiom for getting a
live, externally-controllable value into per-bin `pfft~` processing, and
reading reference prose alone never surfaced it.

---

## THE WORKING PATTERN: `buffer~`/`index~`/`peek~`, not a nested `gen~`

**Confirmed working 2026-08-07** (`f_a_ripple` T7a, after four failed
`gen~`-based architectures — see "What didn't work" below). Cycling '74's
own examples apply a per-bin gain curve inside `pfft~` using plain MSP
objects, not `gen~`:

**Inside the `pfft~` subpatch** (this can now be extremely simple):
```
fftin~ 1 → outlet2 (bin index) → index~ <bufname> → gain value (signal)
fftin~ 1 → outlet0 (real), outlet1 (imag) → *~ each by the gain signal → fftout~ 1
```
No `gen~`, no `Param`, no message inlet into `pfft~` needed at all — `index~
<bufname>` just reads one value per bin, per frame, straight out of a named
`buffer~`, indexed by `fftin~`'s own bin-index output.

**Outside `pfft~`**, the gain curve is precomputed into that named `buffer~`
periodically (e.g. every ~50ms), using a **message-rate** sweep — this part
matters and is not optional:

1. `buffer~ <bufname> <size-ms>` — declare it once, sized comfortably above
   `fftsize/2` samples (e.g. `buffer~ T7a_gain 50` gives ~2205 samples at
   44.1kHz, safely above the 1024 needed for a 2048-point FFT's half
   spectrum).
2. `uzi <half-fftsize> 0` — fires that many bangs as fast as possible;
   `base=0` (second argument) makes its index outlet (outlet 2, "Current
   Index") count `0`...`half-fftsize - 1`, matching bin indices directly.
3. **The per-bin gain formula must be computed by a plain message-rate
   object (`expr`, or built from ordinary scalar Max math objects), NOT a
   `gen~`.** `uzi` fires its 1024 bangs essentially instantaneously — far
   faster than a `gen~`'s signal-domain output can be read back via
   `snapshot~`, which only updates at audio-vector boundaries. A `gen~` +
   `snapshot~` round-trip driven at `uzi` speed will silently skip/average
   values rather than compute one correct answer per bang. `expr` evaluates
   synchronously the instant its hot inlet receives a value — no vector-
   boundary mismatch possible. (This is also documented in `expr`'s own
   `.maxref.xml`: cold inlets store a value without evaluating; the hot
   inlet, inlet 0, evaluates immediately using whatever is currently stored
   in every inlet — exactly the semantics needed here.)
4. Pack `(bin_index, gain)` into a 2-element list and send to `peek~
   <bufname>` — `peek~`'s documented `list` message writes `[index, value]`
   pairs directly into the buffer.
5. Any live/continuously-changing values the gain formula needs (e.g. a
   modulator phase driven by a running accumulator elsewhere) still need
   sampling via `snapshot~` — but only **once per sweep**, before the `uzi`
   burst starts, not once per bin. Use the same right-to-left `trigger`
   ordering already established in `gen-tilde-codebox/SKILL.md` to
   guarantee the snapshot(s) land in `expr`'s cold inlets before the sweep
   begins: `[t b b b]` with the snapshot triggers on the earlier-firing
   (rightmost) outlets and the `uzi`-start bang on the last (leftmost).

**`expr` mechanics actually used** (`f_a_ripple` T7a): up to 9 inlets
(`$f1`...`$f9`), the hot inlet is always inlet 0 (`$f1`). No multi-statement
support — the whole formula must be one nested expression, no named
intermediate variables. A ternary-free conditional trick that worked
cleanly: instead of `cond ? a : b` (not confirmed supported), multiply a
0/1 boolean flag built from comparisons directly into the term you want
gated — `1.0 + ((freq>=lo)*(freq<hi)) * depth * mbin` is exactly equivalent
to "apply the modulation only when in-band, else gain=1" without needing
any conditional syntax at all.

Since the curve only refreshes every ~50ms rather than every sample, this
is explicitly an approximation (same caveat as the message-rate control
values used throughout this project's `pfft~` work) — audibly confirmed
good enough for a scratch test, not claimed to be sample-accurate.

---

## What didn't work: `gen~` nested inside `pfft~` for control-value delivery

**Four structurally different architectures, all built and tested, all
failed identically** — `depth`/`dpth` had zero effect on the output every
time, confirmed via direct `depth=0` vs. `depth=100` A/B listening:

1. 10 physical inlets on the `gen~` (`in1`...`in10`, one per control value
   plus real/imag/bin_idx).
2. 4 inlets — real/imag/bin_idx plus one dedicated inlet for all
   `Param`-message dispatch.
3. `Param` messages routed into inlet 0, the same inlet carrying `fftin~`'s
   real signal (matching how every other `gen~` in this project, T2-T6, has
   always dispatched `Param` messages successfully).
4. A hand-typed message sent directly into `pfft~`'s second inlet,
   bypassing the entire outer control chain.

Also ruled out independently, in case they resurface elsewhere: compile
caching (`@nocache 1` plus a full Max restart — no change), a silent
reserved-word collision (renamed `depth`→`dpth` — no change), and spectral
leakage diluting the effect (`depth=100` would have made even a diluted
effect obvious — it didn't).

**The root cause of why all four failed was never found**, and given the
working `buffer~`/`index~` pattern above fully resolves the actual need,
it likely won't be investigated further in this project. If a future
`gen~`-inside-`pfft~` control-value need arises anyway (e.g. something the
buffer/index pattern genuinely can't express), treat it as unexplored
territory again, not as "should work now that we understand pfft~ better"
— nothing about *why* the four attempts failed was ever actually
established.

---

## Container behavior — `pfft~` is NOT like `gen~`/`poly~`/`bpatcher`

**Confirmed 2026-08-07.** Unlike `gen~`, `poly~`, and `bpatcher` — which all
embed their subpatch content inline in the `.maxpat` JSON via a nested
`"patcher"` key, and load correctly that way — **`pfft~` requires a real,
separate `.maxpat` file on disk**, loaded by name. An inline `"patcher"` key
on a `pfft~` box produces, on load:

```
pfft~ • no patcher <name>
: bad number
```

...and Max silently strips the (unusable) inline content back out on save
(box reverts to `numinlets: 1, numoutlets: 0`). **Fix:** extract the
subpatch content into its own file (e.g. `t7a_inner.maxpat`) in the same
folder as the parent patch, give `pfft~` a plain text argument naming it —
`pfft~ <filename-without-extension> <fftsize> <overlap>` — and no
`"patcher"` key at all on that box.

A `gen~` nested *inside* that external file still embeds inline exactly as
usual — this restriction is specific to `pfft~` itself. Still applies with
the working `buffer~`/`index~` pattern above (that pattern doesn't need a
`gen~` inside `pfft~` at all, but the external-file requirement is about
`pfft~`'s own subpatch, independent of what's inside it).

---

## `pfft~` arguments and structure

`pfft~ <subpatch-name> <fftsize> <overlap> <start-offset> <fullspectrum-flag>`
— only `subpatch-name` is required. `fftsize` defaults to 512, must be a
power of 2. `overlap` defaults to 2; **4 is recommended for most
applications** (hop size = fftsize/overlap; the `pfft~` help patch's own
text explains this is needed for a flat amplitude response after
windowing on both input and output). Number of inlets/outlets on the
`pfft~` box itself is determined by how many `fftin~`/`in` objects
(inlets) and `fftout~`/`out` objects (outlets) exist inside the loaded
subpatch — not declared directly on the `pfft~` box. With the working
pattern above, `pfft~` typically needs only 1 inlet (audio) and 1 outlet
(audio) — no message inlet required, since control arrives via the named
`buffer~` rather than through `pfft~` itself.

### `fftin~ <inlet-number> [window-function]`

Feeds `pfft~`'s Nth inlet (1-indexed) into the subpatch as **three signal
outlets**: real, imaginary, and bin-index (0 to `fftsize/2 - 1`). Window
function defaults to `hanning`. No incoming patchcord needed on `fftin~`'s
own inlet — it's automatically fed by `pfft~`'s own inlet routing.

### `fftout~ <outlet-number> [phase-offset] [window-function]`

Takes real (inlet 0) and imaginary (inlet 1) signals, does the inverse FFT,
writes into `pfft~`'s Nth outlet via overlap-add. No outlets of its own.

### AM doesn't need `cartopol~`/`poltocar~`

Amplitude modulation only scales magnitude and leaves phase untouched, so
the same gain factor applies directly to both real and imaginary without
converting to polar form: `real_out = real_in * gain; imag_out = imag_in *
gain`. **Confirmed working end-to-end** with the `buffer~`/`index~` pattern
above — audibly present, `depth` has a pronounced, correctly-scaling
effect. `cartopol~`/`poltocar~` would be needed if magnitude and phase ever
need to be manipulated independently — PM (T7b, not yet attempted) will
need this.

---

## Bin frequency

`freq_bin = bin_idx * samplerate / fftsize`. Confirmed correct via an
isolated standalone test (`f_a_ripple_scratch_t7a_bandcheck.maxpat` — plain
`gen~`, no `pfft~` involved) matching hand-computed expected values at
several test points, and now also confirmed correct in the actual working
`buffer~`/`expr` sweep (same formula, computed message-rate instead).
`samplerate` should still not be trusted as a `gen~` built-in inside any
`pfft~`-adjacent context without direct verification — in the working
pattern it's supplied as an explicit value from outside instead.

---

## Open question: PM in `pfft~` (T7b, not yet attempted)

Unlike additive synthesis, phase modulation in an overlap-add STFT context
is not obviously equivalent to true phase advancement of a partial. Each
analysis frame only gives a phase *snapshot*; naively adding a time-varying
phase offset independently frame-to-frame, without tracking phase
continuity across frames (the unwrapped-phase-accumulation technique phase
vocoders use for pitch-shifting), would likely produce inter-frame phase
discontinuities — audible as glitching rather than a clean modulated tone.
No longer blocked on a control-routing problem (the `buffer~`/`index~`
pattern resolves that generally) — the remaining open question is purely
the phase-continuity DSP problem itself. Will need `cartopol~`/`poltocar~`
to manipulate phase independently of magnitude, likely with a second
buffer~/index~ curve (or the same sweep extended) supplying the phase
offset per bin, same general shape as the AM pattern above.

---

## Testing methodology specific to `pfft~`

- **Isolate suspect arithmetic in an ordinary `gen~`, outside `pfft~`
  entirely, before assuming a bug is `pfft~`-specific.** Confirmed useful
  in practice — the bandcheck test correctly ruled out the arithmetic
  early, even though the real bug (architecture, not formula) was
  elsewhere.
- **When several structurally different fixes all fail identically, stop
  varying the implementation and go find a real working example instead
  of continuing to guess.** This is exactly what broke T7a open — reading
  `pfft.pfftgen.maxpat`/`fp_fft.maxpat` revealed a completely different,
  simpler paradigm (`buffer~`/`index~`) that none of the four `gen~`-based
  guesses had any reason to arrive at from reference prose alone. See
  `max-advanced-object-methodology/SKILL.md`.
- **A message-rate object driven by a fast bang-burst (`uzi`) needs a
  message-rate computation (`expr`), not a signal-rate one (`gen~` +
  `snapshot~`).** The vector-boundary mismatch is easy to miss when both
  "objects that compute things" look superficially similar.
- **A `depth=0` (or, better, `depth=0` vs. an absurdly large `depth`) A/B
  is a stronger correctness check than eyeballing or filter-tuning an
  envelope follower** — it was what ruled out spectral leakage as an
  explanation, and (once the real architecture was in place) confirmed the
  fix actually worked.
