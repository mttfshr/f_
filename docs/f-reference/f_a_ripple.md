# f_a_ripple — Patch Reference (As-Built DSP)

**Type:** Audio generator (no audio input, audio out) — `gen~`, no texture path, no GL context
**Status:** ⚠ Unfinished. DSP is built and confirmed working (2026-09-16); the UI is plain flonums and there is no helpfile. Shipped in `package/patchers/` as a hand-built prototype, not in the `f_modules` menu.

_Reference written 2026-10-22 from `package/patchers/f_a_ripple.maxpat` (including its `gen~` codebox), `.specify/f_a_ripple/{spec,plan,tasks}.md`. Where the spec and the shipped patch differ, this doc follows the shipped patch._

---

## What it does

A parametric generator of the **cross-frequency de-correlating stimulus** from Yukhnovich et al. (2025): a broadband harmonic carrier with a dynamic spectral ripple applied to one octave band, where the ripple's own rate of change varies sinusoidally so that no pair of frequencies holds a stable correlation. It makes a new randomized stimulus every `stim_dur` seconds, forever, with no trigger.

It is the second `f_a_` module (with `f_a_purr`) and the ground truth for `f_a_decorrelate`, which applies the same modulation matrix to arbitrary input audio. `f_a_ripple` only generates its own carrier; it does not process audio.

The defaults reproduce what the trial's MATLAB actually ran, not the paper's prose. Two defaults deliberately deviate from the paper's stated equations: `carrier_phase` is sine (not the random phase Eq. 1 describes), and PM depth is π/2 × (1 + modulator), i.e. `pm_turns = 0.5` (not the 2π Eq. 3 describes). Defaulting to the prose would silently build the wrong carrier.

---

## Signal Flow

The shipped patch is a **standalone prototype**, not a bpatcher. It has no `inlet` or `outlet` object. It contains the `gen~`, a column of flonums with `prepend <name>` into the `gen~` inlet, a `scope~`, a `spectroscope~` (set the inspector to Sonogram, FFT ≥ 2048), diagnostic number boxes and its own `dac~ 1 2`.

```
flonum / toggle -> prepend <param> -> gen~ (one inlet, 14 Params)
gen~ out 1 (audio) -> dac~ 1 2 (both channels), scope~, spectroscope~
gen~ out 2 (render_count), out 3 (f0_h) -> snapshot~ (metro 200) -> number boxes
loadbang -> message boxes that set every control to its default
```

| `gen~` outlet | Signal |
|---|---|
| 1 | The stimulus, `tanh`-limited to [−1, 1] |
| 2 | `render_count`: how many stimuli have been rendered (shows the auto-retrigger is happening) |
| 3 | `f0_h`: the current stimulus's fundamental, Hz |

The spec calls for a single audio outlet and no control outlet. The shipped patch exposes the audio on `gen~` out 1 only inside the patch (to `dac~` and the scopes).

---

## Parameters

Ranges are from the spec and are **intended, not enforced**: the shipped controls are plain flonums with no minimum or maximum. **[free]** marks values outside what the trial tested.

| Name | Range | Default | Description |
|---|---|---|---|
| `band` | 1–7 | 6 | One of seven overlapping octave bands (1–2 kHz … 8–16 kHz). Internally two adjacent half-octave bands: edges `1000·2^((band−1)/2)` to `1000·2^((band+1)/2)` Hz (band 6 = 5657–11314 Hz) |
| `mod_type` | 0 = AM, 1 = PM | 0 | Final per-partial formula only; everything else is shared, so flipping it mid-stimulus is a like-for-like A/B |
| `depth` | 0–1 | 1.0 | Modulation depth `d` |
| `tmr` | 0.1–256 Hz **[free above ~10 Hz]** | 1.0 | Temporal modulation rate `ω` |
| `smr_mean` | 0–12 cyc/oct **[free]** | 4.5 | Mean spectral modulation rate `μ` |
| `smr_range` | 0–12 **[free]** | 3.0 | Range `r`. `r > μ` lets `S(t)` go negative and reverses the ripple slope |
| `smr_cycle` | 1–60 s **[free]** | 8.0 | Period of the SMR sinusoid, `scyc` |
| `pm_turns` | 0.5–8 **[free above 0.5]** | 0.5 | PM depth. The phase offset is `pm_turns·π·(1 + depth·m)`, so at the default the swing runs from 0 to π radians. The spec calls the unit full cycles; 0.5 is the trial's actual depth |
| `f0_lo`, `f0_hi` | 50–400 Hz | 96 / 256 | A new random f0 in this range per stimulus |
| `stim_dur` | 1–30 s **[free]** | 4.0 | Stimulus length; deviating changes the stimulus |
| `ramp_pct` | 5–50 % | 25 | Raised-cosine on/off ramp, each end, as a share of `stim_dur` |
| `hearing_profile` | 0–3 | 0 | Hearing-correction staircase: 0 = NH, 1 = mild (15 dB), 2 = moderate (30 dB), 3 = severe (45 dB) maximum boost |
| `output_level` | 0 and up | **0 (silent)** | Final gain before the `tanh`. The patch note says to raise it slowly, e.g. 0.05–0.2 |

The spec lists a `carrier_phase` (sine / random) control. **The shipped codebox has no such Param**: the carrier is sine-phase only, so the random-phase configuration is not reachable.

There is no dry/wet control, because there is no input; if one is ever wanted it belongs in the patcher.

---

## Algorithm

Each stimulus draws `f0` uniformly in `[f0_lo, f0_hi]` and two random phases `q` and `p`. Harmonics `n = 1…200` of `f0` that fall in 1–16 kHz make up the carrier.

- **Unmodulated partials** (outside the chosen band) are rendered once per stimulus into a 2048-entry `Data` wavetable (sine-phase, 1/√(count) normalized, with the hearing correction applied per harmonic) and played by a phase accumulator with linear interpolation between the two nearest entries (wrapped with `mod`). They are strictly periodic at f0.
- **Modulated band partials** run per sample in a loop over `n = 1…200`, gated to the band edges:
  - modulator `m = sin(2π(q + tmr·t + fn·S(t)))` with `fn = log2(freq / geomean_of_band)` and `S(t) = smr_mean + smr_range·sin(p + 2π·t / smr_cycle)`
  - AM: `(1 + depth·m)·sin(2π n phase)`; PM: `sin(2π n phase + pm_turns·π·(1 + depth·m))`
  - contributions are summed and divided by `√(modulated count)`
- **Mix:** `raw = 0.3·wavetable + 0.3·modulated`.
- **Envelope:** raised-cosine rise and fall, each `stim_dur·ramp_pct/100` long.
- **Output:** `tanh(raw · env · output_level)`.
- **Hearing correction** is the boost-only piecewise staircase by half-octave index (`[0, 0, .125, .375, .625, .875, 1, 1] × profile dB`), reproducing the MATLAB's behavior rather than the paper's Fig. 1 caption, which does not match the code.
- **Self-timing:** a `History t` starts at 1000, so the first sample triggers a render; afterwards `t ≥ stim_dur` re-triggers. No external trigger and no loadbang wiring is needed to start (the loadbang only sets the controls).

---

## Notes

- **Silent by default.** `output_level` defaults to 0. Nothing is heard until it is raised.
- **Level safety is a ceiling, not a loudness guarantee.** The `tanh` bounds the output to [−1, 1] by construction regardless of profile, depth or band. The hearing profile only boosts, so a severe-HL setting is much louder than normal-hearing at the same `output_level`. Start low.
- **CPU.** DSP CPU was identical (~33%) with the modulated-band loop disconnected versus running at typical (f0 96, band 6) and worst-case (f0 50, band 7) settings, so it is not a performance problem. The loop does not yet restrict itself to the harmonics that fall in the band: it runs all 200 per sample and gates the accumulation (T001).
- **Wavetable interpolation was applied by design, not measured.** The 2048-entry null test against per-partial synthesis passes at 96 Hz; the full 50–400 Hz range was not verified after tooling problems, so interpolation was added to remove quantization at any f0.
- **A `gen~` gotcha found here:** naming a `Param` `reset` collides with a `gen~` system message (console error on every trigger); it was renamed `trig` during scratch work.
- **Licensing.** Built from the paper's published equations (corrected against the code where they disagree), verified against MATLAB-rendered output, with no MATLAB code or structure transcribed (the data deposit is CC BY-NC-SA 4.0).

## Known issues / open

- **UI:** plain flonums rather than the `live.dial` grid of other `f_` modules (T002). No `.maxhelp` exists.
- **Integration (tabled 2026-10-18):** it is hand-built, `NOT_IN_MENU`, drift `out_of_scope`; its build script lives outside the repo (`~/Vsynth/patterns/`). Texture modules chain via `jit.gl.pix` messages and audio via MSP cables, so audio sits beside the video modules but never plugs into them. The options (sibling family, an audio archetype in `build_patcher.py`, bridge-only audio-to-control modules) are in `.specify/plan.md` Still open 1.
- **Acceptance box still unchecked:** the perceptual comparison against checkhearing.org at matched settings (the trial-default configuration should null or come acceptably close, given no shared RNG seed).
- **Out of scope for v1:** the noise-replacement mode (the third trial condition), automatic sham/active band selection from a tinnitus match, a visual companion.
- **Spec lag:** `spec.md` says one audio outlet and a `carrier_phase` control; the patch has three `gen~` outlets (two diagnostic) and no `carrier_phase`.

## Verification

- Scratch tests T2–T6 all passed (spec.md): static harmonic complex (T2), wavetable-versus-per-partial null at 2048 entries (T3), modulation matrix drifts and breathes on `smr_cycle` (T4, via a live console table), AM and PM spectrograms (T5/T6, `spectroscope~` Sonogram, judged by eye against the paper's Fig. 3C character), plus a listening A/B of AM versus PM. The spectrogram passes are real but not point-by-point.
- Free-parameter sanity sweep of `depth`, `tmr`, `smr_mean`, `smr_range` (including a value above `smr_mean`) and `smr_cycle` on T5: no clicks, dropouts or clipping (impressions only). `pm_turns` was not swept in scratch.
- `f_a_decorrelate`'s NumPy mirror (`tests/records/spike_a_decorrelate_t7.py`) was measured against this module's additive synthesis, which is the ground truth for that module.

## References

- Yukhnovich et al. (2025), the cross-frequency de-correlating stimulus; reference implementation at checkhearing.org. Research notes: `ideas/f_a_spectral_ripple.md`.
- Related: `f_a_decorrelate.md` (the processor version, same modulation matrix, `pfft~`), `ideas/f_a_build_process.md`.

## Source Files

`package/patchers/f_a_ripple.maxpat` (hand-built; `gen~` codebox inside), `.specify/f_a_ripple/{spec,plan,tasks}.md`, `ideas/f_a_spectral_ripple.md`.
