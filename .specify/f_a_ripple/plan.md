# f_a_ripple — Implementation Plan

_Created: 2026-08-04_

## Architecture Decisions

### ADR-1 — `f_a_` prefix, generator archetype
Established by `f_a_purr`: no texture inlet/outlet, no vsynth GL context.
`f_a_ripple` is a pure generator like `f_a_purr` — no audio input, single
audio outlet, no control-signal outlet (see spec, Interface). Most `f_`
structural conventions (`jit.gl.pix`, `routepass jit_gl_texture`,
`moduleSize.js`, `build_patcher.py`) don't apply, per `f_a_purr` ADR-1.

### ADR-2 — Wavetable/per-partial split for CPU
The synthesis is a stateless function of `(t, n)` — phase is `2π n f0 t`, not
an accumulator (see idea file). Unmodulated partials (`Aₙ=1, ψₙ=0`) sum to a
signal strictly periodic at f0: rendered once per 4 s stimulus to a `buffer~`,
played with `phasor~`/`wave~`. Only the modulated band's harmonics (11–84
depending on band) run per-sample in the `gen~` codebox.

**Correctness confirmed 2026-08-05 (T3, spec.md).** The wavetable-vs-
per-partial null holds at a 2048-entry table and in-range f0 (96 Hz); it
visibly fails at a 64-entry smoke-test table, but that failure is
table-resolution quantization (`peek` floors rather than interpolates — see
`jit-gen-codebox` skill), not a flaw in the split itself. **Still open, and
now the actual blocker for this ADR:** the CPU payoff this split exists for
is unmeasured, and the production table size hasn't been chosen — a
2048-entry table works at f0=96 Hz but hasn't been checked against the full
50–400 Hz `f0_lo`/`f0_hi` range (spec.md Parameters), where the
samples-per-cycle-to-table-entries ratio changes. Two candidate fixes if a
fixed table proves insufficient across that range: a larger table, or
`peek`-based linear interpolation between adjacent entries. Neither has been
tried. This decision belongs in Phase 3 (parameter characterisation,
spec.md/plan.md Phases) alongside the CPU measurement itself, since table
size and interpolation both trade against the render-time cost this ADR was
meant to keep cheap.

### ADR-3 — Default configuration matches the code, not the paper
Two defaults deliberately deviate from the paper's stated equations to match
what the trial's MATLAB actually ran: `carrier_phase = sine` (not the random
phase Eq. 1 describes), and `pm_turns = 0.5` giving π depth (not the 2π Eq. 3
describes). Both are exposed as parameters so the untested configurations
(random phase, full-cycle PM) are reachable, but the module's *default* must
reproduce the studied stimulus, per spec.md's "Why faithful reproduction."
Getting this backwards — defaulting to the paper's prose — would silently
build the wrong carrier and no external reference would catch it, since
checkhearing.org is itself built to the tested configuration.

### ADR-4 — Internal half-octave bands, external octave bands
The MATLAB's real unit is eight half-octave bands (`1000·2^(0:0.5:4)`);
each user-facing octave band is two adjacent half-octave bands
(`fband_mod = b + [0,1]`). The module's `band` parameter (1–7) is user-facing;
internally the codebox indexes the half-octave grid. Keeping the internal
representation half-octave, rather than collapsing to the user's 7 bands,
preserves the ability to later expose arbitrary/asymmetric bandwidth (a
free-parameter direction flagged in the idea file) without restructuring.

### ADR-5 — Hearing correction folded in as a per-half-octave gain staircase
Reproduces the MATLAB's actual behaviour (piecewise-linear staircase,
boost-only, values `[0, 0, .125, .375, .625, .875, 1, 1] × profile_dB`) rather
than the paper's Fig. 1 caption, which doesn't match the code (see idea file,
discrepancy 5). Folded into `f_a_ripple` rather than split out as a standalone
`f_a_tilt` (idea file Q6) — decided in favour of self-containment, since the
correction is structurally simple (8 fixed gains) and splitting it buys
nothing for v1's scope.

### ADR-6 — Boost-only correction requires peak normalisation
Because `hearing_profile` only ever boosts, a severe-HL configuration is
substantially louder than normal-hearing at the same `depth`/`gain`. The
MATLAB driver peak-normalises per file after rendering. `f_a_ripple` must
apply an equivalent safety ceiling by construction (a limiter or continuous
peak-tracking normalisation on the output), not merely document a recommended
level — an additive synth with ~150 partials and depth-1 AM has an easy path
to unexpectedly loud output if partial count or profile changes. This is a
non-negotiable per the idea file's Safety section.

### ADR-7 — Reimplementation from equations, not MATLAB translation
The data deposit (containing the MATLAB) is CC BY-NC-SA 4.0. `f_a_ripple` is
built from the paper's published equations (corrected against the code where
they disagree — ADR-3) and verified against MATLAB-rendered output, but no
MATLAB code or structure is transcribed into the `.gen` codebox. See idea
file, Licensing.

## Phases

- **Phase 1 — concept and interface.** Complete. `ideas/f_a_spectral_ripple.md`,
  this spec.
- **Phase 2 — scratch verification.** In progress. T2–T6 (spec.md). T2
  (static harmonic complex), T3 (wavetable/per-partial null), and T4
  (modulation matrix drift/breathing) all **passed** as of 2026-08-05.
  T5 (full AM build) and T6 (AM/PM A-B) both **partially passed** —
  T5 2026-08-05, T6 2026-08-06. Both listening comparisons sound right
  (T5 close to indistinguishable from checkhearing.org; T6's PM sounds
  like a plausible variant of T5's AM at the same modulator state, as
  expected) and DSP held up clean at audio rate in both, but **the
  spec.md-mandated spectrogram comparisons for both T5 and T6 haven't been
  run** — no spectrogram tool was available in either session. This phase
  isn't done until that gap closes.
- **Phase 3 — parameter characterisation.** Not started, and blocked on
  Phase 2 finishing — the sweeps below need a working modulated signal to
  sweep. Sweep the six **[free]** parameters; find where TMR crosses from
  ripple into audio-rate roughness (idea file Q5); confirm SMR-range > mean
  doesn't produce silence or artifacts at its sign-reversal boundary. Also
  now includes the two open items from ADR-2: a real CPU measurement of the
  modulated-band path (T5's listening test showed no glitching at band 6,
  a first good sign, but that's not a profiled measurement and hasn't
  touched the worst-case band 7 at ~84 partials), and settling production
  wavetable size (or interpolated `peek`) across the full 50–400 Hz f0
  range, not just the 96 Hz spot-check.
- **Phase 4 — production build.** Not started. No `definition.py` equivalent
  exists for `f_a_` modules yet — same open build-path question as
  `f_a_purr`.
- **Phase 5 — docs and helpfile.** Not started.
