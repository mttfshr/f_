# f_a_decorrelate — Specification

_Created: 2026-08-04_
_Status: **Module complete 2026-10-12, at the `f_a_ripple` packaging bar.**
Phase 2: all four acceptance boxes ticked (T7 Max+mirror, T8 synthetic +
two real-world music carriers — varying-SMR correlation drift beats
fixed on both, the paper's actual claim; bin artifacts characterised; PM
verified equivalent-enough, ADR-4 un-scoped). Phase 3: parameters swept,
v1 scope decided (AM+PM, depth 0–1, tmr 0.1–4 Hz, 2048/4). Phase 4: DSP
built and shipped — `package/patchers/f_a_decorrelate.maxpat` +
`f_a_decorrelate_inner.maxpat` (pfft~ subpatch, loaded by name). Phase
5: `docs/f-reference/f_a_decorrelate.md` written, README Audio row (⚠),
NOT_IN_MENU registered, launcher regenerated, drift baseline entry
recorded. **Remaining is the shared f_a_ packaging workstream**
(build_patcher.py audio archetype, live.dial UI grid, audio-module
helpfile format — the same items `f_a_ripple` owes); this module joins
that workstream rather than blocking on it._

## What it does

A processor: applies the same cross-frequency de-correlating modulation as
`f_a_ripple` to arbitrary input audio, via `pfft~`, instead of generating its
own carrier. Audio in, de-correlated audio out.

## Why this is the module worth having

Yukhnovich et al. (2025) note explicitly that the modulation needn't be
applied to a synthetic harmonic complex — it could go on any sound with
sufficient high-frequency content. The paper never builds this version. It's
the one that behaves like the rest of `f_`: a processor with an input, not a
stimulus renderer with none. `f_a_ripple` exists as ground truth for this
module's correctness, not as a design template to copy — a `pfft~` bin-gain
or bin-phase operation is a structurally different implementation of the same
modulation matrix, and has no independent way to prove it's right.

## Scope

**In scope for v1** _(updated 2026-10-12 per Phase 3/ADR-4 verdicts)_:
- AM mode (per-bin gain, following `Mₙ(t)`) on a single selected octave band
- **PM mode (per-bin phase rotation, ψ=(π/2)(1+d·M))** — verified
  equivalent-enough 2026-10-12 (mirror + Max listen; plan.md ADR-4),
  packaged after AM; same depth range as AM
- Same targeting parameters as `f_a_ripple` (`band`, modulation-matrix
  parameters): one shared mental model across both modules

**Out of scope for v1:**
- **tmr above 4 Hz** (Phase 3/T010 finding: at tmr ≥ 10 the bin-gain
  formulation is limited by the 2048-sample analysis window itself —
  per-frame refresh doesn't help; higher tmr wants a smaller-FFT mode,
  a v2 question, not a parameter extension)
- Noise-replacement mode — same reasoning as `f_a_ripple`'s v1 scope.
- Multi-band / simultaneous modulation of more than one octave at once.

## Interface

| Inlet/Outlet | Content |
|---|---|
| `in0` | Audio signal — arbitrary carrier |
| `out0` | Audio signal — de-correlated output |

Unlike `f_a_ripple`, this module has an audio inlet — the first `f_a_`
processor rather than generator. Everything else about the `f_a_` contract
(no texture path, no GL context) still applies.

## Parameters

Only the modulation-matrix parameters carry over from `f_a_ripple` — nothing
carrier-related (`f0`, `stim_dur`, `carrier_phase`) applies, since there's no
carrier to generate.

| Name | Range | Default | Note |
|---|---|---|---|
| `band` | 1–7 | 6 | matches `f_a_ripple`'s band numbering exactly |
| `depth` | 0–1 | 1.0 | `d` — hard ceiling 1.0 (Phase 3: >1 sends bin gain negative = phase inversion, a character change the additive reference doesn't share) |
| `tmr` | 0.1–4 Hz | 1.0 | `ω` — ceiling 4 Hz at 2048/4 (Phase 3/T010: window-limited above that; paper's tested value is 1 Hz) |
| `smr_mean` | 0–12 cyc/oct | 4.5 | `μ` |
| `smr_range` | 0–12 | 3.0 | `r` — verified smooth through 6+ (Phase 3 sweep) |
| `smr_cycle` | 1–60 s | 8.0 | `scyc` |
| `mod_type` | AM / PM | AM | PM verified equivalent-enough (ADR-4 verdict 2026-10-12); code-accurate PM depth π/2 as in `f_a_ripple` |

`gain`/`mix` **do** apply here in the library's canonical sense — there's a
dry signal to blend against. `mix` (0–100%, `live.numbox`) is the wet/dry
control; `gain` is unbounded post-modulation trim.

## How you know it's working

Maps to T7–T8 in `ideas/f_a_spectral_ripple.md`.

- [x] T7 — `f_a_decorrelate` fed a synthetic harmonic complex matching
      `f_a_ripple`'s carrier, AM mode, same parameters → output closely
      matches `f_a_ripple`'s AM output. **NumPy tier done
      2026-10-12** (`tests/spike_a_decorrelate_t7.py`): at 2048/4 the
      per-bin chain tracks the additive reference at −15.6 dB residual,
      corr 0.986 — and a waveform *null* is provably not the right bar:
      Hann leakage × per-bin gain on non-bin-centered partials is an
      inherent floor of windowed per-bin processing (frame-hold and
      bin-quantization of M each cost only ~−33 dB; the STFT round-trip
      itself is exact to −180 dB). "Closely matches" = the −15 dB class
      plus the envelope metric below. **Max tier passed 2026-10-12**
      (`f_a_decorrelate_scratch_null.maxpat`): the rig's residual landed
      in the −15 dB class, matching the mirror._
- [x] T8 — off-diagonal correlation matrix of band envelopes (the paper's
      actual claim, not just its sound) computed for `f_a_decorrelate`'s
      output on a real-world carrier (music, voice, room tone), confirming
      the fixed-SMR-vs-varying-SMR de-correlation effect holds on non-
      synthetic input. **Done 2026-10-12**: synthetic half (pfft AM 0.313
      vs additive 0.320, fixed-SMR control 0.594) plus two real-world
      music carriers via the spike's CLI (wav paths). The paper's claim
      is about correlation *stability*, so the acceptance metric is
      cross-segment matrix drift, and both carriers show the claimed
      direction: varying-SMR drift 0.569/0.375 vs fixed 0.459/0.264.
      Honest caveat: on music the varying-vs-fixed margin is modest
      (music's correlations are already nonstationary); the chain's
      dominant real-world effect is decorrelation vs the raw carrier
      (0.94→0.59, 0.77→0.45). Numbers and method in
      `tests/spike_a_decorrelate_t7.py`._
- [x] Bin-resolution artifacts at the low end of the band (4.5 cyc/oct ripple
      density across 1–2 kHz is fine relative to typical bin spacing) are
      either absent or characterised. **Characterised 2026-10-12**: band 6
      attribution (dominant term is leakage × gain, not bin spacing) and
      band 1 closed the same day — band 1 actually IMPROVES at 2048/4
      (−22.7 dB, corr 0.997; 10 partials vs band 6's 59), envelope-corr
      matches its additive reference (0.350 vs 0.363), fixed-SMR control
      separates at 0.838. **One FFT size serves all bands** (plan.md
      ADR-5 fully closed).
- [x] PM mode's phase-advance-via-overlap-add is verified equivalent (or
      documented as inequivalent and shipped only as AM) before PM is
      un-scoped from v1. **Verified equivalent-enough 2026-10-12**:
      mirror (−11.2 dB, corr 0.962 vs additive PM; envelope-corr 0.237
      vs 0.202) + the Max listen passed (`f_a_decorrelate_scratch_t7b.maxpat`
      — no glitching, plausible PM character; plan.md ADR-4 verdict:
      un-scoped for v1, packaged after AM). Extreme-depth/high-tmr
      corners re-test in Phase 3._

## Acceptance

v1 is done when T7 shows `f_a_decorrelate`'s AM output closely matches
`f_a_ripple`'s on a matched synthetic input — **measured, not eyeballed, and
in envelope-correlation terms (the paper's actual claim), not waveform-null
terms: a −15 dB-class waveform residual is the physics of windowed per-bin
processing, not a failure (see T7 entry above)** — and T8 confirms the
de-correlation effect on at least one real-world (non-synthetic) carrier.

## Primary risk

**Resolved 2026-10-12.** The original risk — no ground truth until
`f_a_ripple` clears T2–T6 — no longer holds: `f_a_ripple`'s T2–T6 all
passed, and its Phase 4 core DSP is built and confirmed working
(`f_a_ripple_v1.maxpat`, 2026-09-16), giving this module a real
reference for the T7 null test. Remaining risk is narrower: `f_a_ripple`'s
DSP exists but is not yet packaged (its tasks.md T002), so acceptance
comparisons run against a scratch/working patch, not a shipped module —
if `f_a_ripple`'s packaging changes the DSP, T7 must be re-run against
the new output.
