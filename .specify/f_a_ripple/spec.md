# f_a_ripple — Specification

_Created: 2026-08-04_
_Status: Phase 2 (scratch verification) complete — T2–T7 all passed. See
plan.md Phases._

## What it does

A parametric generator of the cross-frequency de-correlating stimulus
modulation described in Yukhnovich et al. (2025) — a broadband harmonic
carrier with a dynamic spectral ripple applied to one octave band, where the
ripple's own rate of change varies sinusoidally so no frequency pair holds a
stable correlation. Outputs audio only.

Second member of the `f_a_` class, alongside `f_a_purr`: no texture path, no
GL context, gen~-domain synthesis.

## Why faithful reproduction, not a from-scratch design

The published equations and the authors' own MATLAB disagree in two places
that change the sound (sine-phase carrier vs. random phase; PM depth of π vs.
the paper's stated 2π) — see `ideas/f_a_spectral_ripple.md`, "MATLAB code —
what it actually does." `f_a_ripple`'s default configuration must reproduce
the trial's actual code path, not the paper's prose, so its output can be
checked against the paper's own figures and against the free reference
implementation at checkhearing.org. Everything beyond the trial's tested
values (see Parameters) is exposed as free parameters, because the paper's own
stated next step is exploring exactly that space.

## Scope

**In scope for v1:**
- AM and PM modes, on a single user-selected octave band
- The trial's default parameter set, reproduced exactly (ADR-3, `f_a_ripple`
  plan)
- Free exploration of the untested parameter space: SMR range/rate, TMR up to
  audio rate, PM depth beyond one turn, arbitrary bandwidth
- Built-in hearing-correction tilt (the trial's four-profile staircase)
- Level safety: output is limited by construction, not just by convention

**Out of scope for v1:**
- Noise-replacement mode (third trial condition) — different premise
  (removing informational content, not decorrelating), and the trial's own
  data shows it behaving unpredictably (sham outperformed active). Candidate
  for v2 once v1's correctness is established.
- Sham/active band auto-selection from a tinnitus-frequency match — v1 takes
  the band directly; the match-to-band lookup table (`ideas/f_a_spectral_
  ripple.md`) is a thin wrapper that can sit in the patcher, not the module.
- Any visual companion (Jitter modulation-matrix display) — real idea, gated
  on v1 existing first.

**Explicitly not built:** processing of external audio. That's
`f_a_decorrelate`, a separate module and a separate spec. `f_a_ripple` only
generates its own carrier.

## Interface

| Outlet | Content |
|---|---|
| `out0` | Audio signal — the modulated stimulus |

Single outlet. No control-signal outlet is needed — unlike `f_a_purr`, there
is no downstream consumer waiting on a phase signal; the ripple is not driving
anything else in this library (yet — see visual-companion note above).

## Parameters

Trial-default values first, matching the corrected equation set in the idea
file exactly (not the paper's prose). Ranges marked **[free]** are outside
what the trial tested.

**Targeting**

| Name | Range | Default | Note |
|---|---|---|---|
| `band` | 1–7 | 6 | one of the 7 overlapping octave bands (1–2 … 8–16 kHz) |
| `mod_type` | AM / PM | AM | noise-replace deferred to v2 |

**Modulation**

| Name | Range | Default | Note |
|---|---|---|---|
| `depth` | 0–1 | 1.0 | `d` |
| `tmr` | 0.1–256 Hz **[free above ~10 Hz]** | 1.0 | `ω` — periodotopy argument from the paper untested above ~10 Hz |
| `smr_mean` | 0–12 cyc/oct **[free]** | 4.5 | `μ` |
| `smr_range` | 0–12 **[free]** | 3.0 | `r` — `r > μ` lets `S(t)` go negative, reversing ripple slope |
| `smr_cycle` | 1–60 s **[free]** | 8.0 | `scyc` |
| `pm_turns` | 0.5–8 **[free above 0.5]** | 0.5 | PM depth in full cycles; 0.5 = the trial's actual π depth |

**Carrier**

| Name | Range | Default | Note |
|---|---|---|---|
| `f0_lo` / `f0_hi` | 50–400 Hz | 96 / 256 | new random f0 per 4 s stimulus |
| `stim_dur` | 1–30 s **[free]** | 4.0 | trial value; Q2 in idea file — deviating changes the stimulus |
| `ramp_pct` | 5–50% | 25% | of `stim_dur`, each end |
| `carrier_phase` | sine / random | sine | **sine is what the trial actually ran** — see Why, above |
| `hearing_profile` | NH / mild / mod / severe | NH | trial's four staircase profiles |

`gain`/`mix` (the library's canonical names) don't apply here — there's no
blend with a dry signal, since there's no input. If a wet/dry control is ever
wanted it belongs in the patcher, not the module.

## How you know it's working

Maps to T1–T6 in `ideas/f_a_spectral_ripple.md`.

- [x] T1 — MATLAB read, equations corrected, discrepancies documented
- [x] T2 — static harmonic complex, sine-phase, matches expected impulse-like
      timbre (not noise-like — that would mean `φₙ` crept back in). **PASSED
      2026-08-04** — compiles, sounds right in Max.
- [x] T3 — unmodulated-partial wavetable nulls against the full per-partial
      render. **PASSED 2026-08-05** at production-realistic table size
      (2048) and in-range f0 (96 Hz). See `ideas/f_a_spectral_ripple.md`
      scratch-test log for the full trace. `poke`/`peek` args, the one-shot
      render gate, and the phase accumulator were each individually
      confirmed correct across seven isolation tests. The remaining
      question — the actual nested-loop table render, compared against A —
      was run twice: at the original smoke-test table size (64 entries) it
      produced a large, structured, periodic residual (three repeating
      sawtooth-envelope bursts per stimulus window); at 2048 entries, same
      f0, same codebox otherwise unchanged, the residual collapsed to a
      dense low-amplitude band with no periodic structure, and A/B's own
      scopes became visually near-identical. Confirmed by eye, not yet by a
      numeric peak/SNR readout (deferred — visual read judged sufficient for
      now). **Root cause identified: table-resolution quantization**, not a
      logic bug — `peek` floors/truncates rather than interpolating (per
      HANDOFF's confirmed `Data`/`poke`/`peek` semantics), so a 64-entry
      table at f0=96 Hz (~459 samples/cycle) forces each table index to
      stand in for ~7 consecutive samples, producing a deterministic,
      phase-locked stepping error. This reframes ADR-2's open question: not
      "is the split logic correct" (yes) but "does production need a large
      fixed table, `peek` interpolation, or both" — see plan.md ADR-2
      update. `render_count` confirmed sane (2, after two manual clicks) at
      the larger table size too, ruling out the render-gate as a
      contributing factor.
- [x] T4 — modulation matrix, viewed as a signal, drifts and breathes on the
      configured `smr_cycle`. **PASSED 2026-08-05.** Verified via a live
      console table (t, S, M every 200ms), not by eyeballing a scope — a
      first attempt at visual-only verification was correctly rejected as
      unreliable. Found and fixed a real `gen~` dialect gotcha along the way:
      naming a `Param` `reset` collides with a `gen~` built-in system
      message (console errors on every trigger until renamed to `trig`) —
      same collision class as the `mix()` operator issue already documented
      in `jit-gen-codebox/SKILL.md`, but in the audio dialect. Full trace in
      `ideas/f_a_spectral_ripple.md` T4 log.
- [x] T5 — AM output's spectrogram matches the paper's Fig. 4 by eye.
      **PASSED 2026-09-15.** Built
      `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t5.maxpat`: T3's
      wavetable (unmodulated partials, now correctly excluding the
      modulated band) combined with T4's modulator applied as real AM to
      the modulated band's own per-sample partials, each with a real
      per-harmonic `Fₙ` derived from a one-shot `geomean_mod` computation.
      At defaults (band 6, f0=96) it sounds close to indistinguishable from
      the checkhearing.org reference by ear — real signal, not noise, not
      obviously wrong (2026-08-05). **The spectrogram gap closed
      2026-09-15**: a `spectroscope~` (Sonogram display mode, FFT ≥ 2048)
      was wired to the gen~'s audio outlet, output raised, and the resulting
      time-frequency view showed the expected diagonal, curving stripe
      pattern — fixed-frequency harmonic lines whose brightness is
      modulated by a slowly-drifting spatial grating — the same qualitative
      character as the paper's Fig. 3C, confirmed across two consecutive
      4 s stimulus re-triggers. Judged a pass by Matt directly against the
      live sonogram; the finer checks discussed (stripe pattern confined to
      band 6's edges specifically, tilt-angle drift visible within one 4 s
      window) weren't walked through point-by-point in the record here, so
      treat this as a real but not maximally rigorous spectrogram pass — a
      step up from T5's original listening-only result, one step below
      T3/T4's numeric-verification standard. Also confirmed: **DSP held up
      clean at low `output_level`, no glitching**, despite the
      modulated-band `for (n=1..200)` loop running per-sample at audio rate
      (44.1k iterations/sec × up to 200 = real load) — first actual data
      point against the Primary Risk section's "CPU cost... unmeasured"
      flag below. Not a full CPU measurement (no profiling, no worst-case
      band 7 tested), but a real signal the wavetable split's payoff is
      doing its job. Full trace in `ideas/f_a_spectral_ripple.md` T5 log.
- [x] T6 — PM output's spectrogram is visibly distinct from AM's in the
      expected way (frequency wobble vs. amplitude wobble on each harmonic).
      **PASSED 2026-09-15.** Built
      `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t6.maxpat` as a clone
      of T5 with one addition: a `mod_type` toggle (0=AM, 1=PM) switching
      only the final per-partial formula — wavetable, `geomean_mod`,
      `q`/`p` draw, `Mₙ(t)`/`S(t)` all shared and identical between the two,
      so flipping `mod_type` mid-stimulus (without re-triggering "new
      stimulus") is a genuine like-for-like A/B rather than two
      independently-randomized builds. Uses the code-accurate PM depth
      (`π/2`, not the paper's stated `π` — MATLAB discrepancy #2, idea
      file). **A/B by ear passed 2026-08-06**: PM "sounds a little
      different, a plausible variant" of T5's AM at the same modulator
      state. **Spectrogram gap closed 2026-09-15** with the same
      `spectroscope~` Sonogram setup as T5, judged a pass by Matt directly
      in Max. Full trace in `ideas/f_a_spectral_ripple.md` T6 log.
- [ ] Trial-default configuration produces output perceptually comparable to
      the checkhearing.org reference at matched settings

## Acceptance

v1 is done when the trial-default configuration nulls (or comes acceptably
close, given no shared RNG seed) against a MATLAB-rendered reference stimulus
in spectrogram comparison, and every free parameter can be swept live without
clicks, denormal silence, or clipping.

## Primary risk

**Resolved 2026-09-15 — CPU cost of the modulated-band partials is
negligible.** Measured on T5 via Max's Audio Status/DSP Status CPU% (Signal
CPU), comparing `gen~` fully disconnected (from `*~`/`dac~`, `scope~`, and
`spectroscope~` — a true idle floor) against fully connected, at both the
current default (`f0=96`, band 6) and the nominal worst case for the
current implementation (`f0=50`, band 7, low end of the `f0` range): all
three readings held at ~33% CPU, no measurable difference. **Caveat worth
recording**: the codebox's `for (n=1..200)` loop currently runs all 200
iterations (full `log`/two `sin` calls each) every sample regardless of
`band`/`f0` — it doesn't actually restrict itself to the harmonics inside
`flo_mod`/`fhi_mod` the way ADR-2 describes, only gates the *accumulation*.
This is a real latent inefficiency (the honest fix loops `n_lo..n_hi`,
computed from the band edges and `f0`, same idiom the MATLAB itself uses)
but the measurement shows it isn't costing anything detectable even
unfixed — so the fix is a code-hygiene item, not a performance blocker.
Not yet fixed in T5/T6's `.maxpat`.

**New, narrower risk from the T3 finding:** table size can't be pushed
indefinitely for free — a 2048-entry table costs ~410,000 loop iterations on
render (2048 × 200 harmonics) versus 64's ~12,800, all still one-shot/gated,
but worth keeping in mind if `band` or harmonic count grows. Whether
production needs a table this large, `peek` interpolation instead, or some
combination, is an open decision — see plan.md ADR-2.
