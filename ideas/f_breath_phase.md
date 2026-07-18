# f_breath_phase (working name) — respiratory phase/character input utility

**Status:** idea only, not specced, not scheduled. Captured from a pure
ideation session (2026-07-12) that explicitly had no clear next step.
Do not treat any naming here (`f_breath_phase`, tier names, etc.) as
locked — nothing has been confirmed against real hardware or a real
signal yet.

## Core idea

An input utility that reads the wearer's breathing pattern from some
external sensor and uses it to modulate the phase of a generator's
internal cycle — sitting *upstream* of GL modules the way `f_vf_fieldmap`
sits upstream of vecfield consumers. Not a vecfield producer itself;
more like a conditioning stage that hands a phase (and potentially other
derived signals) to whatever downstream module wants to consume it.

Originating motivation: sync visuals to breath rate. Explicitly the
"breath directly drives phase" mode (vs. a free-running clock merely
perturbed by breath) — chosen over the alternative early in the
discussion.

## Hardware landscape (as surveyed, not decided)

No single "auscultation → MIDI" product exists. Two real but distinct
adjacent products surfaced:

- **MIDI breath controllers** (e.g. MIDI Solutions Breath Controller,
  compatible with Yamaha BC2/Kelfar BCK-1/TEControl) — real, off-the-shelf,
  converts *mouth* breath pressure to MIDI (CC/aftertouch/pitch bend).
  Measures effort at the mouth, not chest/torso expansion — a different
  signal than what's wanted here.
- **Digital/electronic stethoscopes** (Littmann 3200, Thinklabs One,
  ) — real medical devices, acoustic pickup of heart/lung sound,
  output audio (some over Bluetooth), not MIDI or structured data.

**Resolved direction:** audio is fine — Max doesn't care what kind of
signal arrives at `adc~`, so any of the following work identically once
plugged in: contact mic or piezo disc on the chest/diaphragm, a DIY
stethoscope-style membrane-over-mic-capsule, or in principle a chest
accelerometer. No serial/OSC/MIDI bridge needs to be built; this is
audio-domain conditioning entirely inside Max.

Sensor *character* still matters even though the plumbing is uniform:
- Contact mic at sternum/diaphragm: percussive rustle/friction texture.
- Stethoscope-style diaphragm over a mic: closer to true auscultation,
  breathier/tonal, most likely to carry genuine "character."
- Piezo flat against chest: picks up gross chest-wall motion, lower
  frequency, smoother mechanical displacement curve rather than sound.

Not decided: which sensor to actually build/buy. Deferred until there's
a concrete reason to pick one (see Open questions).

## Signal chain (conceptual, not built)

Rough shape agreed on, audio-rate throughout in Max's native domain:

1. Raw signal in via `adc~`.
2. Bandpass/highpass to remove handling noise / mic self-noise.
3. Rectify + lowpass → envelope follower (`rampsmooth~`/`slide~`-style).
4. **This conditioned envelope is itself a first-class output** — see
   Tiered model below. Everything past this point is a *reduction* of
   this signal, not a replacement for it.
5. Decimate down from audio-rate to whatever control-rate GL params
   actually need (`snapshot~`/`edge~`-style) before touching any
   `jit.gl.pix` param.

## Tiered model (the actual design decision from this session)

Rather than choosing one fidelity level, capture-breath-character work
naturally layers into three tiers built on a shared base, closer to how
`f_vf_fieldmap` offers a single conditioning stage with multiple
downstream consumers:

1. **Conditioned envelope** — the cleaned, smoothed breath signal itself.
   The base signal everything else derives from. Should be exposed as
   an output from day one, even before phase or character taps exist,
   so nothing built later has to re-derive it.
2. **Derived phase** — a reduction of tier 1 into a 0–1 phase value
   suitable for driving a generator's cycle directly (see Phase
   construction below for the current best candidate).
3. **Derived character descriptors** — a separate reduction of tier 1:
   peak sharpness, plateau/hold detection at top or bottom of a cycle,
   ramp shape (linear vs. exponential vs. S-curve), and cycle-to-cycle
   regularity itself as a signal (steady vs. ragged breathing). Runs
   alongside phase, not instead of it. Not designed yet — flagged as
   real future work once there's an actual sensor signal to look at.

**Agreed first-build target:** expose the raw conditioned envelope
(tier 1) from the start, even if phase (tier 2) is the only thing
initially wired to a visual. Character (tier 3) is additional taps off
the same base signal, designed once a real signal exists to design
against — not attempted speculatively.

## Phase construction — candidates considered, current best

Three approaches surfaced, in order of how the discussion evolved:

1. **Peak-to-peak rate only** — simplest; measure time between
   inhale peaks, drive a `phasor~`-equivalent at that rate. Rejected
   as insufficient once "capture breath character" became the goal —
   this discards *all* shape, including the inhale/exhale asymmetry
   that motivated the next step.
2. **Full quadrature/analytic-signal phase** (`hilbert~`-style) — true
   instantaneous phase, captures asymmetry faithfully, but more
   machinery than initially seems warranted for a first build.
   Not rejected outright — worth returning to for tier 3 (character)
   work — but set aside as the *first* build's phase mechanism.
3. **Two-ramp asymmetric model (current best candidate for tier 2):**
   detect both inhale-peak and exhale-peak (trough) — not just one
   edge — splitting each full cycle into independently-timed inhale
   and exhale halves. Phase ramps 0→0.5 across the inhale duration and
   0.5→1.0 across the exhale duration, each at its own measured rate.
   Cheap (no analytic-signal machinery), and directly captures real
   timing asymmetry (a fast inhale produces a fast-moving first half
   of the phase cycle) without capturing full shape — a deliberate
   middle ground between (1) and (2).

A **rate-averaging vs. per-breath-reset fork** was also named as a real
design axis independent of the above: a *steady/quantized* mode
(phase driven by a smoothed average rate, immune to single-breath
jitter) vs. a *direct-trigger* mode (phase resets and ramps between
actual detected peaks, tracking real irregularity including gasps or
held breaths). Not resolved — flagged as something to try both ways
once there's something to test against, and separately, as something
the two-ramp asymmetric model would need to pick one behavior for
before it could be built.

## Open questions (real, unresolved)

- Which sensor to actually prototype with — no hardware in hand yet;
  deferred until there's a concrete reason to choose (see Sensor
  character above).
- Trough detection is expected to be noisier than peak detection (the
  bottom of an exhale is typically a shallower/mushier minimum than
  the sharper top of an inhale) — envelope smoothing time-constant is
  a real tuning variable for the two-ramp model, not a footnote.
- Held-breath / breath-holding behavior: does a hold freeze phase, or
  does some fallback force phase to keep moving so visuals never
  fully stall? Not decided — flagged as a real design fork the
  two-ramp model needs an answer for before it's buildable, and
  directly related to the rate-averaging-vs-reset fork above.
- Whether this is architecturally closer to `f_chladni`'s
  audio-companion-patch pattern (audio-domain conditioning living
  outside the GL layer, feeding in via a simple interface) or needs
  its own new prefix/family (e.g. `f_bio_`) if this grows siblings —
  not decided, and not urgent until there's a second module in this
  family to compare against.

## Explicitly not decided / not in scope yet

- No spec, no plan, no build. This file exists purely to preserve the
  architecture of the conversation, per standing rule (capture
  valuable architectural discussion into docs rather than losing it to
  session-log compression).
- No naming is locked (`f_breath_phase` is a placeholder).
- No relationship to the parked entrainment/perceptual work
  (`f_ganzflicker`, `f_dreamachine`, Muse Athena EEG) has been asserted —
  worth a glance later since both are biosignal-adjacent, but not
  explored this session.
