# f_a_purr — Specification

_Created: 2026-07-27_
_Status: Phase 2 partial — layers 0/1 + resonator verified in scratch_

## What it does

A parametric cat-purr synthesis engine. Generates a purr that never repeats,
from a model of purr acoustics rather than sample playback. Outputs audio and
a breath-phase control signal.

First member of the `f_a_` class: audio-domain modules with no texture path
and no vsynth GL context.

## Why synthesis

The perceptual signature of a purr is non-repetition. A purr is a train of
glottal clicks at ~25 Hz, not a waveform with a pitch — there is no
fundamental to loop or resynthesise harmonically, and the ear catches a loop
within a few cycles. Realism comes from the modulation stack across three
timescales (per-click, per-breath, per-minute), not from click fidelity.

## Scope

**In scope for v1:** layers 0–4 (click, pulse train, breath, resonance,
breath noise). Two outlets: audio, breath phase.

**Out of scope for v1:** layer 5 (behavioural meow/chirp scheduler).
Deferred — it is a scheduler, not DSP, and belongs in the patcher.

**Explicitly not built:** any visual coupling. `f_a_purr` is an audio module.
Downstream consumers read `out1` as a control signal like any other.

## Interface

| Outlet | Content |
|---|---|
| `out0` | Audio signal — the purr |
| `out1` | Control signal — breath phase, 0–1 |

`out1` follows `f_a_breath_phase`'s tier-2 convention: 0→0.5 inhale,
0.5→1.0 exhale, asymmetric halves. The engine generates this phase rather
than recovering it, so none of `f_a_breath_phase`'s detection problems apply.

The engine knows its own state exactly. Downstream consumers must read `out1`
directly — a purr has no pitch, so a pitch follower cannot track it, and
onset detection on the click train is strictly worse than ground truth.

## Parameters (as verified in scratch, 2026-07-27)

| Name | Range | Default | Layer |
|---|---|---|---|
| `rate_hz` | 1–200 | 25 | 1 |
| `rate_jit` | 0–0.2 | 0 | 1 |
| `amp_jit` | 0–0.2 | 0 | 1 |
| `decay_ms` | 0.2–200 | 5 | 0 |
| `decay_jit` | 0–0.2 | 0 | 0 |
| `tilt` | 0.02–1 | 0.5 | 0 |
| `res_hz` | 20–200 | 90 | 3 |
| `res_q` | 0.5–0.999 | 0.98 | 3 |

Jitter ranges are 0–0.2, **not** 0–1. They multiply against bipolar `noise()`,
so values above ~0.5 drive `rate_target` negative and slam the floor clamp,
producing near-silence. Established empirically after a dragged value of 4.6
caused a confusing debugging detour.

Layer 2 and 4 params (`breath_hz`, `breath_skew`, `breath_depth`,
`breath_rate_mod`, breath-noise level) are specified in the idea file but not
yet implemented or range-verified.

## How you know it's working

**Verified 2026-07-27 in `/Users/matt/Vsynth/patterns/f_a_purr_scratch.maxpat`:**

- [x] Codebox compiles, both outlets carry signal
- [x] Accumulator produces a 25 Hz pulse train; `rate_hz` audibly changes rate
- [x] Click envelope decays independently of pulse rate
- [x] Per-cycle latch holds rate/decay for a full cycle
- [x] Resonator gives the click train a body — "thin and buzzy" becomes tonal
- [x] Params clamp; out-of-range values no longer poison state

**Not yet demonstrated:**

- [ ] Jitter parameters have identifiable useful bands (see Risk below)
- [ ] Breath layer produces breathing rather than tremolo
- [ ] `out1` phase is C¹ continuous across the 0.5 crossover in practice
- [ ] The whole thing reads as a cat rather than as a machine

## Acceptance

v1 is done when a naive listener, given 30 seconds of output, identifies it
as a purring cat without prompting — and when a 10-minute render contains no
audibly repeating passage.

## Primary risk

**Per-cycle jitter may not be the main realism lever.** During the first
sweep session the useful bands for `rate_jit`, `amp_jit`, and `decay_jit`
could not be identified by ear, even after adding a resonator. Two readings:

1. The test method was wrong (creeping up from zero rather than bracketing
   down; no A/B against a mechanical reference).
2. The breath layer carries more of the perceived realism than per-cycle
   jitter does, and the layer ordering in the test protocol is backwards.

If (2) is true, the spec's emphasis on per-cycle irregularity is misplaced and
the parameter set may simplify. Resolving this is the next substantive
question, not a tuning detail.
