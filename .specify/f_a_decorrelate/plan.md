# f_a_decorrelate — Implementation Plan

_Created: 2026-08-04_

## Architecture Decisions

### ADR-1 — `f_a_` prefix, first processor archetype
Every existing `f_a_` module (`f_a_purr`, `f_a_ripple`) is a pure generator:
no audio inlet. `f_a_decorrelate` is the first `f_a_` processor: audio in,
audio out, no texture/GL involvement either way. Worth naming explicitly as
a new archetype within the prefix, since `build_patcher.py` and any future
`f_a_` tooling decisions (Phase 4, both modules) should account for both
shapes, not assume "no audio inlet" as an `f_a_` invariant.

### ADR-2 — `pfft~`, per-bin gain (AM) / per-bin phase advance (PM)
`Mₙ(t)` — the same modulation matrix `f_a_ripple` computes per-harmonic — is
instead computed per-FFT-bin and applied as either a bin gain multiplier (AM)
or a bin phase rotation (PM). `Fₙ` becomes bin log-frequency relative to the
band's geometric centre, matching `f_a_ripple`'s ADR-3 correction (mean-
centred over the modulated *bins in this case*, not the nominal band centre).

### ADR-3 — `f_a_ripple` is a hard dependency, not a parallel effort
Despite being separate projects/specs, `f_a_decorrelate`'s scratch tests (T7,
T8) cannot run meaningfully until `f_a_ripple` has cleared T2–T6. This is a
sequencing dependency, not a scheduling preference: there is no independent
way to verify a `pfft~` implementation is doing the right thing (spec.md,
Primary risk). Do not begin `f_a_decorrelate` Phase 2 work before
`f_a_ripple` Phase 2 is complete.

### ADR-4 — PM equivalence is unproven, not assumed
`ψₙ` in the additive domain is an unambiguous phase offset per partial.
Rotating a `pfft~` bin's phase by the equivalent amount is not obviously the
same operation — bin phase in an overlap-add STFT conflates true carrier
phase with windowing and frame-boundary effects in ways the additive
synthesis does not. Ship AM only in v1; treat PM as blocked on the T7-style
comparison, not as "probably fine, ship it and see."

### ADR-5 — FFT size is an open scratch-test question, not a fixed choice
Bin resolution trades against ripple density at the low end of the band (idea
file: 4.5 cyc/oct across 1–2 kHz is a fine ripple in linear bin spacing at
typical FFT sizes). No size is chosen here — determining a workable size (or
concluding low bands need a different FFT size than high bands) is part of
Phase 2, not a prerequisite decision.

### ADR-6 — Band model and licensing carry over unchanged
Same 7-octave/8-half-octave band model as `f_a_ripple` (ADR-4, that plan),
same reimplementation-from-equations approach with MATLAB used only for
verification (ADR-7, that plan). Not re-litigated here.

### ADR-7 — No shared codebase with `f_a_ripple` in v1
The two modules compute structurally similar but not identical modulation
math (per-harmonic vs. per-bin `Fₙ`). Starting duplicated is simpler than
factoring out a shared `.gen` abstraction prematurely — revisit only if T7
shows the two implementations converge closely enough that a shared core
would still produce correct output in both domains.

## Phases

- **Phase 1 — concept and interface.** Complete. `ideas/f_a_spectral_
  ripple.md`, this spec.
- **Phase 2 — scratch verification.** Blocked on `f_a_ripple` Phase 2
  (ADR-3). T7, T8 once unblocked.
- **Phase 3 — parameter characterisation.** Not started. FFT size (ADR-5),
  PM equivalence (ADR-4) resolved here if T7/T8 don't rule PM out entirely.
- **Phase 4 — production build.** Not started. `pfft~`-based modules have no
  existing `f_` build-path precedent — a second, related open question
  alongside `f_a_ripple`'s Phase 4.
- **Phase 5 — docs and helpfile.** Not started.
