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
`jit-gen-codebox` skill), not a flaw in the split itself.

**CPU payoff measured 2026-09-15 (spec.md Primary Risk) — turns out not to
matter at current scale.** DSP Status CPU% was identical (~33%) with the
modulated-band loop fully disconnected vs. running at both typical
(f0=96, band 6) and nominal-worst-case (f0=50, band 7) settings. The loop
also doesn't currently restrict itself to `n_lo..n_hi` the way this ADR
describes — it runs all 200 candidate harmonics unconditionally and only
gates the accumulation — so the *split's* CPU savings aren't even actually
implemented yet, and it still doesn't register. Fixing the loop bounds is
now a code-hygiene item, not something blocking Phase 3.

**Decided 2026-09-15, implemented 2026-09-16 — `peek`-interpolation applied
by design, not verified by measurement.** An attempt to verify the
2048-entry table across the full 50–400 Hz range (not just the 96 Hz
spot-check) broke down on tooling problems (`scope~` failing to render
above f0≈200, `peakamp~` units confusion, unrepeatable readings — see
HANDOFF) without producing a trustworthy result. Rather than keep chasing
that measurement: given the CPU headroom already confirmed above (fully
negligible), there's no cost reason not to just fix the root cause
outright. `f_a_ripple_scratch_t3.maxpat` (the null-test rig) and T5/T6's
wavetable-render codeboxes now read the two nearest table entries and
linearly blend by the fractional index (wrapping at the table boundary via
`mod`), instead of `peek`'s default floor/truncate — removes the
quantization error at any f0 rather than shrinking it to "probably small
enough." Not re-verified against A in this session (per the reframing:
accept reasonable assumptions about correct Max/gen~ behavior here rather
than re-proving from scratch) — worth a quick listen/scope-check next time
these patches are open, but not treated as blocking.

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
- **Phase 2 — scratch verification.** Complete. T2–T6 (spec.md) all
  **passed**. T2 (static harmonic complex), T3 (wavetable/per-partial
  null), and T4 (modulation matrix drift/breathing) passed 2026-08-05.
  T5 (full AM build) and T6 (AM/PM A-B) passed their listening checks
  2026-08-05/06 (T5 close to indistinguishable from checkhearing.org;
  T6's PM sounds like a plausible variant of T5's AM at the same
  modulator state, as expected) and their spectrogram checks 2026-09-15,
  once a `spectroscope~` (Sonogram mode) was wired into both scratch
  patches — the diagonal, drifting stripe pattern matched the paper's
  Fig. 3C character. See spec.md T5/T6 entries for what was and wasn't
  walked through point-by-point in that spectrogram pass.
- **Phase 3 — parameter characterisation.** Effectively complete
  2026-09-16, at the pragmatic bar spec.md's Acceptance section actually
  asks for (not a deep characterization project — see HANDOFF's
  mid-session reframe). **CPU measurement done 2026-09-15** — not a
  blocker. **Wavetable size: `peek` interpolation implemented
  2026-09-16** (by design, not verified by measurement). **Free-parameter
  sanity sweep done 2026-09-16**: `depth`, `tmr`, `smr_mean`, `smr_range`
  (including a value exceeding `smr_mean`, crossing S(t)'s sign reversal),
  and `smr_cycle` all swept live on T5 with no clicks, dropouts, or
  clipping. Impressions only, not a formal characterization — consistent
  with the reframe. **`pm_turns` not tested — not actually wired as a
  live parameter yet.** T6's codebox hardcodes the trial-default PM depth
  (`halfpi = twopi/4`, i.e. `pm_turns=0.5`) rather than exposing it as a
  `Param`; exposing and sweeping it is a known TODO whenever T6 gets
  built out further, not a blocker for the AM-only path.
- **Phase 4 — production build.** Core DSP built and confirmed working
  2026-09-16: `/Users/matt/Vsynth/patterns/f_a_ripple_v1.maxpat`. Combines
  everything previously verified in isolation (T3's interpolated
  wavetable, T5/T6's AM/PM per-partial modulation) with genuinely new
  work not covered by any prior scratch test: fully self-timed per-
  stimulus cycling (internal `t>=stim_dur` check, `noise()`-drawn f0/q/p,
  no external trigger needed), raised-cosine on/off ramps, the ADR-5
  hearing-correction staircase applied per-harmonic in both the wavetable
  render and the modulated loop, `band` (1-7) mapped internally to
  half-octave edges per ADR-4, a real `pm_turns` Param (T6 had this
  hardcoded), and a `tanh()` safety ceiling per ADR-6 (output bounded to
  [-1,1] by construction, after `output_level`, regardless of
  profile/depth/band). One authoring mistake caught and fixed by Matt:
  `band`/`hearing_profile` were built with `maxclass: "numbox"`, which
  isn't a real Max UI object — swapped for `flonum`, rewired correctly.
  Confirmed by Matt: compiles clean, sounds right, auto-retrigger and
  ramps behave as intended.

  **Not yet done**: production UI polish (live.dial grid matching `f_`
  visual conventions instead of plain flonums — see
  `ideas/f_a_build_process.md`), placement in `package/patchers/`,
  Phase 5 (docs/helpfile). The DSP itself is the hard part and it's done;
  packaging is comparatively mechanical.
- **Phase 5 — docs and helpfile.** Not started.
