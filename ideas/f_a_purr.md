# f_a_purr — Parametric Purr Synthesis Engine

_Last updated: 2026-07-27_
_Status: Layers 0–2, 4 + resonator built and verified in scratch. Q1, Q3
(partial), Q5 resolved; Q2, Q4, Q6, Q7 open._

## Concept

A fully parametric cat-purr audio engine. Not sample playback, not looping —
a synthesis model built from purr acoustics, producing a purr that never
repeats and evolves across three timescales.

## Prefix: f_a_

`f_a_` denotes an **audio module**: audio-domain synthesis or conditioning,
no texture inlet, no texture outlet, no vsynth GL context. `f_a_purr` is the
first member.

Most `f_` structural conventions do not apply — no `jit.gl.pix`, no
`routepass jit_gl_texture`, no `moduleSize.js`, and `build_patcher.py` cannot
generate it. What does carry over: the three-stage lifecycle
(`ideas/` → `.specify/` → `docs/f-reference/`), UI styling (Ableton Sans Light,
black panel with blue border, `live.dial` conventions), named control-message
dispatch, and the session-end update discipline.

`ideas/f_a_breath_phase.md` is the sibling member — audio-domain conditioning
(`adc~` in, control out). Its open question about needing a `f_bio_` prefix is
resolved by `f_a_`.

## Why synthesis rather than samples

The perceptual signature of a real purr is *non-repetition*. A purr is a train
of glottal clicks at ~25 Hz, not a waveform with a pitch — the perceived rate
is the repetition rate of broadband transients, so there is no fundamental to
loop or resynthesise harmonically. Any looped recording is caught by the ear
within a few cycles.

Realism comes from the modulation stack, not from click fidelity. Per-cycle
irregularity, per-breath asymmetry, and per-minute behavioural drift are what
make it read as alive.

## Layer Architecture

| Layer | Content | Timescale |
|---|---|---|
| 0 | Glottal click — noise burst through fast decay env (~3–8ms) | per-click |
| 1 | Pulse train — ramp ~25 Hz + per-cycle jitter (rate, amp, decay) | ~40ms |
| 2 | Breath cycle — asymmetric two-ramp phase, ~0.3–0.5 Hz | ~2–3s |
| 3 | Resonance — parallel biquad bank, chest + tract formants | static-ish |
| 4 | Breath noise — filtered, gated by breath envelope | ~2–3s |
| 5 | Behavioural — stochastic meow/chirp scheduler, slow state drift | minutes |

### Established principles

- **Jitter is sampled once per cycle and held**, not continuously modulated.
  Continuous modulation of ramp frequency is vibrato; per-cycle resampling is
  biological irregularity. Different sound entirely.
- **The breath oscillator must be asymmetric** — exhale longer than inhale.
  A symmetric LFO reads as tremolo, not breathing. Ingressive phase is
  typically slower, quieter, duller than egressive.
- **Layer 3 carries model identity.** Chest resonance and click spectral tilt
  are what distinguish a kitten from a heavy adult purr, along with base rate.
- **The felt band** (~25–150 Hz) matters as much as the audible one. Small
  speakers cannot reproduce it.

### Core mechanisms (worked out 2026-07-27, verified in Max the same session)

**Cycle detect — hand-rolled accumulator, not `phasor` + delta detection.**

```
ph   = ph_prev + rate_held / samplerate
trig = (ph >= 1)
ph   = ph - trig
```

`ph_prev` via `history`. Wrap and trigger are the same event rather than the
trigger lagging a sample, and the fractional overshoot is available if
sub-sample accuracy is ever wanted.

The latch is `sah` on `trig`, feeding rate, amplitude, and decay. This is a
feedback loop — `rate_held` determines `ph`, which produces `trig`, which
latches `rate_held` — so gen~ requires a `history` in the cycle. One sample of
delay, irrelevant here, but gen~ will not compile without it and the error
will not obviously point here.

**Click decay — separate one-pole, reset by trigger. Not driven by the ramp.**

```
coeff = exp(-1 / (decay_ms * samplerate / 1000))
env   = trig ? amp_held : env_prev * coeff
```

Deriving the decay envelope from the ramp phase (an earlier idea) is wrong: it
couples decay time to pulse rate, so changing rate silently changes every
click's length and `rate_jit` and `decay_ms` can never be tested
independently. An absolute one-pole keeps them orthogonal. It also allows
`decay_ms` to exceed the cycle period, giving overlapping clicks — probably
ugly, but a real region of the space that should not be structurally excluded.

**Asymmetric breath — piecewise-linear warp of a uniform ramp.**

```
fi    = 0.5 - 0.4 * breath_skew        // inhale fraction of period
phase = p < fi  ?  0.5 * p / fi
                :  0.5 + 0.5 * (p - fi) / (1 - fi)
```

where `p` is a plain uniform ramp at `breath_hz`. `breath_skew` 0 is
symmetric; 1 is fast inhale, long exhale. Stateless, exact by construction.
This is the generative mirror of `f_a_breath_phase`'s two-ramp tier-2 model —
same phase convention, none of the recovery problems, because the durations
are chosen rather than measured.

**The 0.5 crossover needs no smoothing.** Shape gain as a raised cosine of the
*warped* phase, `0.5 - 0.5*cos(2π*phase)`. Its derivative with respect to
phase is zero exactly at phase 0.5 and at the 0→1 wrap, so the warp's slope
discontinuity is multiplied by zero precisely where it occurs. Output is C¹
continuous for free.

**gen~ is not jit.gl.pix.** `noise` is a hard failure on the GPU codebox path
(see `skills/jit-gen-codebox/SKILL.md`) but is valid in `gen~` — different
compiler, different domain. Easy trap given how much codebox experience is
GPU-side. Do not import GPU-path constraints wholesale.

## Outlets

| Outlet | Content |
|---|---|
| `out0` | Audio signal — the purr |
| `out1` | Control signal — breath phase, 0–1 |

Note: this table uses 0-indexed naming to match the rest of `f_`'s
conventions. The actual gen~ codebox and Max's physical outlets are
1-indexed — audio is codebox `out1` (the module's first physical outlet)
and breath phase is codebox `out2` (second physical outlet). See
`.specify/f_a_purr/tasks.md` T014.

The engine knows its own state exactly, so any downstream consumer should read
`out1` directly rather than re-deriving it. A purr has no pitch, so a pitch
follower will not track it, and onset detection on the click train is strictly
worse than the ground truth the engine already holds.

### Breath phase convention (shared with f_breath_phase)

`out1` follows the same convention as `ideas/f_breath_phase.md`'s tier-2
two-ramp asymmetric model:

```
0.0 → 0.5   inhale, at its own rate
0.5 → 1.0   exhale, at its own rate
```

The two modules run this in **opposite directions**. `f_breath_phase` recovers
the phase from a noisy sensor signal — hence its open questions about trough
detection, smoothing constants, and held-breath behaviour. `f_a_purr` generates
it, so none of those problems exist.

Honouring the same convention makes them interchangeable at the same downstream
socket, which gives two useful consequences:

- `f_a_purr` is a clean synthetic test signal for developing `f_breath_phase`
  before any sensor hardware exists.
- A real breath sensor can drive `f_a_purr`'s layer 2, so the synthetic purr
  breathes with the wearer.

## Prototype Parameter Contract (as verified in scratch, 2026-07-27)

Layers 0–2 and 4 plus the resonator (layer 3) are all built. Jitter ranges
are **0–0.2, not 0–1** — they multiply against bipolar `noise()`, so values
above ~0.5 drive targets negative and slam the floor clamp, producing
near-silence (found empirically after a dragged value of 4.6 caused a
confusing debugging detour). All params are clamped inside the codebox
(ADR-6, `.specify/f_a_purr/plan.md`) since the message path bypasses dial
ranges and an out-of-range value can drive the resonator unstable.

| Name | Layer | Range | Default | Description |
|---|---|---|---|---|
| `rate_hz` | 1 | 1–200 | 25 | Base pulse rate |
| `rate_jit` | 1 | 0–0.2 | 0 | Per-cycle rate deviation |
| `amp_jit` | 1 | 0–0.2 | 0 | Per-cycle amplitude deviation |
| `decay_ms` | 0 | 0.2–200 | 5 | Click decay time |
| `decay_jit` | 0 | 0–0.2 | 0 | Per-cycle decay deviation |
| `tilt` | 0 | 0.02–1 | 0.5 | Click spectral tilt (one-pole on noise pre-envelope) |
| `res_hz` | 3 | 20–200 | 90 | Resonator center frequency |
| `res_q` | 3 | 0.5–0.999 | 0.98 | Resonator Q (hand-rolled two-pole, ADR-5) |
| `breath_hz` | 2 | 0.05–2 | 0.4 | Breath cycle rate |
| `breath_skew` | 2 | 0–1 | 0.3 | Inhale/exhale asymmetry |
| `breath_depth` | 2 | 0–1 | 0.3 | Gain modulation amount |
| `breath_rate_mod` | 2 | -0.5–0.5 | 0.2 | Pulse rate offset across breath cycle |
| `breath_noise` | 4 | 0–1 | 0 | Breath-noise mix level, fixed-color one-pole lowpass, gated by breath envelope |

Not yet range-characterized: exact usable bands within the jitter ranges
above (`.specify/f_a_purr/tasks.md` T011, deferred pending a fuller
listening pass against the now-complete engine).

## Open Questions

### Q1. RESOLVED — gen~ / patcher boundary
Layers 0–4 built into a single `gen~` codebox; layer 5 (behavioural) remains
a patcher-level scheduler, not yet built. Breath lives inside `gen~` as
planned — the per-cycle jitter reads it sample-accurately, and phase is
emitted on the second physical outlet anyway.

### Q2. Presets vs. continuous morphing
Named models, or a continuous parameter space with presets as saved points?
Leaning continuous — the purr should be able to evolve during a piece. Needs
the prototype to reveal which parameters actually distinguish models.

### Q3. RESOLVED (partial) — Click generation — parametric vs. wavetable
Built parametric (noise-burst through envelope, per ADR from
`.specify/f_a_purr/plan.md`). Confirmed audible and non-repeating in
scratch. "Wavetable bank" alternative not pursued — parametric approach
carries the layer stack fine on its own so far.

### Q4. Per-breath resonator detune
The tract does change shape across the breath cycle. Is slight resonator detune
audible, or wasted complexity? Layer 3 (resonator) now exists and is verified
working — this is testable. Tracked as `.specify/f_a_purr/tasks.md` T017,
not yet run.

### Q5. RESOLVED — breath modulates rate via the latch, not continuously
Original concern: `breath_rate_mod` varying the fast ramp's frequency
continuously would smear per-cycle hold semantics. It would — so fold the
breath contribution into the value being latched instead:

```
rate_target = rate_hz * (1 + breath_rate_mod * breath_curve)
                      * (1 + rate_jit * noise)
rate_held   = sah(rate_target, trig)
```

Breath's influence on rate is now sampled once per cycle along with the
jitter. Rate is constant within a cycle, hold semantics stay clean, and the
purr still speeds and slows across the breath. Correct on physical grounds
too, not just convenience: a real purr's rate changes between cycles, not
within one.

### Q6. Performance instrument vs. fixed piece
Propagates into whether the parameter layer needs to be playable and whether
latency matters. Deferred.

### Q7. Does f_a_purr accept an external breath phase?
If `out1`'s convention is shared, the inverse is natural: an inlet that
overrides the internal breath oscillator with an external 0–1 phase. Cheap to
add, and it is what lets a real sensor drive the purr. Not yet decided whether
this belongs in the first build.

## Test Protocol

Set all jitter to zero first and listen to the mechanical baseline — that
reference is needed to judge everything else. Then, one parameter at a time:

1. `rate_jit` alone — find where it goes from mechanical to alive, and where
   it tips over into nervous.
2. `amp_jit` alone — hypothesis: tolerates a wider range than rate does.
3. `decay_jit` alone — hypothesis: matters least. Falsifying this is useful.
4. `breath_skew` at zero vs. strongly asymmetric, `breath_depth` fixed — the
   tremolo-vs-breathing test.

Record the usable ranges. Those numbers turn this layer sketch into a real
spec, and they are what Q2 needs to resolve.

Test with a metronome and hand-drawn parameter sweeps as well as by ear —
developing only against "does this sound like a cat" risks overfitting the
mechanism to one target.

## Research Needed

- [x] Purr rate ranges — adult vs. kitten, published measurements.
      **Found 2026-07-27.** Consensus fundamental range is ~25–150 Hz
      across sources, with most domestic cats clustering 25–50 Hz; a
      commonly cited figure is ~26.3 Hz. Kittens tend slightly higher,
      roughly 30–60 Hz, attributed to faster-contracting laryngeal
      muscles in development. `rate_hz`'s existing 1–200 clamp comfortably
      covers this; the *useful* default/testing range for an adult-purr
      character should center closer to 25–50 rather than the full clamp
      span. A 2023 excised-larynx study (Herbst et al., Current Biology)
      found cat larynges self-oscillate at 25–30 Hz even with no neural
      input, via a vocal-fold tissue specialization — relevant to Q6/Q7's
      "how much of this needs to be neurally-modeled vs. just mechanical"
      framing, though not directly actionable for the codebox.
- [x] Ingressive vs. egressive phase: actual rate / amplitude / timbre
      deltas. **Found 2026-07-27, inconclusive/contested.** One source
      (Remmers & Gautier) reports fundamental frequency changing during
      exhalation; another reports little change; a third reports the
      opposite direction (increase during inspiration); a fourth reports
      a small 2–3 Hz variation across the respiratory cycle. No settled
      consensus on direction or magnitude — the literature itself
      disagrees, plausibly due to differing arousal states across study
      subjects. Practical takeaway for `breath_rate_mod`: current default
      (0.2, meaning a real but moderate rate swing across the breath
      cycle) is a reasonable engineering choice not strongly contradicted
      by any single source, but there's no authoritative target number to
      tune toward. Treat by ear (T013/T014 already passed on this basis).
- [ ] Glottal click duration and spectral envelope — still not found
      published; confirms the idea file's original suspicion. Plan to
      derive from own spectrograms of recorded purrs stands.
- [ ] Chest and tract resonance frequencies in domestic cats — **searched
      2026-07-27, no direct published numbers found.** Literature centers
      on the purr-generation mechanism itself (glottal/laryngeal, not
      chest/tract formants) — one 2023 paper (Herbst et al.) discusses
      subglottal and supraglottal tract resonances affecting the signal,
      and vocal fold length (~7.5mm used in their simulation), but doesn't
      give chest-resonance formant numbers usable for `res_hz` tuning.
      `res_hz`'s current 90 Hz default/20–200 range remains an ear-tuned
      guess, not literature-derived — still open.
- [x] Prior art: existing academic purr synthesis models, if any exist.
      **Found 2026-07-27, none specific to purring.** No dedicated
      academic cat-purr synthesis model found. Adjacent, general work
      exists: a genetic-algorithm approach fits generic synthesizer
      parameters (pitch, duration) to animal vocalization categories
      including cats, but treats purring as one data point among general
      animal sounds, not as its own model, and doesn't address the
      layered jitter/breath structure this project is building. Confirms
      the idea file's original assumption — building from acoustics
      first-hand, not reverse-engineering, remains the only real option.

## Notes

- Existing purr generators on the web are reference-by-ear only. Build from
  acoustics; do not reverse-engineer or use third-party generator output.
- Related: `ideas/f_breath_phase.md` — shares the tier-2 phase convention.
  See Outlets section above.

## Source File

Not yet created.
