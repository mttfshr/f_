# f_a_decorrelate — Specification

_Created: 2026-08-04_
_Status: Phase 1 — concept complete, nothing scratch-tested. **Blocked on
`f_a_ripple` reaching its Acceptance bar** — see Primary risk._

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

**In scope for v1:**
- AM mode (per-bin gain, following `Mₙ(t)`) on a single selected octave band
- Same targeting parameters as `f_a_ripple` (`band`, modulation-matrix
  parameters): one shared mental model across both modules

**Out of scope for v1:**
- PM mode. Phase modification inside an overlap-add `pfft~` is not obviously
  equivalent to true per-partial phase advancement (idea file Q3) — this
  needs to be verified against `f_a_ripple`'s PM output before it's trusted,
  and that verification is itself a v1 deliverable (see How you know it's
  working), not a prerequisite to starting.
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
| `depth` | 0–1 | 1.0 | `d` |
| `tmr` | 0.1–256 Hz | 1.0 | `ω` |
| `smr_mean` | 0–12 cyc/oct | 4.5 | `μ` |
| `smr_range` | 0–12 | 3.0 | `r` |
| `smr_cycle` | 1–60 s | 8.0 | `scyc` |

`gain`/`mix` **do** apply here in the library's canonical sense — there's a
dry signal to blend against. `mix` (0–100%, `live.numbox`) is the wet/dry
control; `gain` is unbounded post-modulation trim.

## How you know it's working

Maps to T7–T8 in `ideas/f_a_spectral_ripple.md`. Neither can run until
`f_a_ripple` clears its own Acceptance bar.

- [ ] T7 — `f_a_decorrelate` fed a synthetic harmonic complex matching
      `f_a_ripple`'s carrier, AM mode, same parameters → output nulls or
      closely matches `f_a_ripple`'s AM output
- [ ] T8 — off-diagonal correlation matrix of band envelopes (the paper's
      actual claim, not just its sound) computed for `f_a_decorrelate`'s
      output on a real-world carrier (music, voice, room tone), confirming
      the fixed-SMR-vs-varying-SMR de-correlation effect holds on non-
      synthetic input
- [ ] Bin-resolution artifacts at the low end of the band (4.5 cyc/oct ripple
      density across 1–2 kHz is fine relative to typical bin spacing) are
      either absent or characterised
- [ ] PM mode's phase-advance-via-overlap-add is verified equivalent (or
      documented as inequivalent and shipped only as AM) before PM is
      un-scoped from v1

## Acceptance

v1 is done when T7 shows `f_a_decorrelate`'s AM output matches `f_a_ripple`'s
on a matched synthetic input, and T8 confirms the de-correlation effect on at
least one real-world (non-synthetic) carrier.

## Primary risk

**No ground truth exists yet.** Every correctness criterion here is defined
*relative to* `f_a_ripple`. If `f_a_ripple` hasn't cleared T2–T6, there is no
way to tell a `pfft~` bin-resolution artifact from a working de-correlation —
this module cannot be meaningfully scratch-tested out of sequence.
