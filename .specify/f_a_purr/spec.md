# f_a_purr — Specification

_Created: 2026-07-27, refreshed 2026-11-03 to match tasks.md_
_Status: Phase 2 mostly done — layers 0–4 built in scratch. Layers 0–3 and the
breath asymmetry verified (tasks.md T005–T014); layer 4 (breath noise, T016) is
built but not yet heard in Max (Matt, 2026-11-03). Jitter bands and the
interface questions (T024, T025) are open._

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

**Out of scope for v1:** layer 5 (behavioral meow/chirp scheduler).
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

**Indexing:** the table above is 0-indexed to match the rest of `f_`. The gen~
codebox and Max's physical outlets are 1-indexed: audio is codebox `out1` (first
outlet), breath phase is codebox `out2` (second outlet). See tasks.md T014.

**Decided 2026-11-03 (Matt), not yet built:** v1 adds a signal inlet for an
external 0–1 breath phase and a `breath_src` param (0 internal, 1 external)
that selects it (tasks.md T025). v1 is "playable by construction": no macro,
mapping or scheduler layer (T024).

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
| `breath_hz` | 0.05–2 | 0.4 | 2 |
| `breath_skew` | 0–1 | 0.3 | 2 |
| `breath_depth` | 0–1 | 0.3 | 2 |
| `breath_rate_mod` | -0.5–0.5 | 0.2 | 2 |
| `breath_noise` | 0–1 | 0 | 4 |

The breath rows were built 2026-07-27 (tasks.md T012, T016). `breath_skew` and
the breath phase were verified by ear and at the 0.5 crossover (T013, T014);
`breath_noise` has not been heard in Max.

**Ranges are provisional.** The table gives the original dial ranges. Jitter was
first set to 0–0.2, **not** 0–1: jitter multiplies bipolar `noise()`, so values
far above ~0.5 drive targets negative and slam the floor clamp, producing
near-silence (found after a dragged value of 4.6 caused a confusing debugging
detour). But the codebox clamps (read from the scratch patch, 2026-11-03) are
wider than the table: `rate_jit` 0.5, `amp_jit` 0.9, `decay_jit` 0.9, `res_hz`
up to `samplerate * 0.25`. The by-ear preset in tasks.md T011 uses
`decay_jit` 0.6 and `res_hz` 215.5, both outside the table. So the ranges above
need revising when T011 is finished, per parameter, not as one shared jitter
range. The ranges the production module ships with are not decided.

## How you know it's working

**Verified 2026-07-27 in `/Users/matt/Vsynth/patterns/f_a_purr_scratch.maxpat`:**

- [x] Codebox compiles, both outlets carry signal
- [x] Accumulator produces a 25 Hz pulse train; `rate_hz` audibly changes rate
- [x] Click envelope decays independently of pulse rate
- [x] Per-cycle latch holds rate/decay for a full cycle
- [x] Resonator gives the click train a body — "thin and buzzy" becomes tonal
- [x] Params clamp; out-of-range values no longer poison state

**Verified 2026-07-27 after the breath layer was added (tasks.md T013, T014):**

- [x] Breath layer produces breathing rather than tremolo (`breath_skew` 0 vs high)
- [x] Breath phase is continuous across the 0.5 crossover in practice

**Not yet demonstrated:**

- [ ] Jitter parameters have identifiable useful bands (T011). Partial: one
      whole-preset combination found by ear, not per-parameter bands
- [ ] Breath noise (layer 4, `breath_noise`) sounds right in Max (T016)
- [ ] `bcurve` shape is right: peaks at the crossover, or mid-exhale? (T015)
- [ ] The whole thing reads as a cat rather than as a machine
- [ ] A 10-minute render has no audibly repeating passage

## Acceptance

v1 is done when a naive listener, given 30 seconds of output, identifies it
as a purring cat without prompting — and when a 10-minute render contains no
audibly repeating passage.

## Primary risk — resolved 2026-07-27 (tasks.md T010)

**Resolved:** jitter is a real lever (outcome A, judged by ear; exact band edges
were not logged). The whole-preset listening pass in T011 also showed that the
high-Q clean resonator ring was a major contributor to the "motorcycle" sound,
not only the missing jitter. What remains is T011's per-parameter bands.
The original statement is kept below for the record.

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
