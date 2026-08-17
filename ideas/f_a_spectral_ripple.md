# f_a_spectral_ripple — Cross-Frequency De-Correlating Modulation

_Last updated: 2026-08-05_
_Status: Idea only. **T1, T2 done. T3 partially run, verdict pending — see
scratch-test log.** Paper, data deposit, and full MATLAB stimulus code all
read; five paper-vs-code discrepancies found and recorded. Naming
provisional._

## Concept

A Max generator for the **cross-frequency de-correlating stimulus modulation**
described in Yukhnovich et al. (2025) — a broadband harmonic carrier with a
dynamic spectral ripple applied to one octave band, where the ripple's
*spectral modulation rate itself* varies sinusoidally over time, so that no
frequency pair maintains a stable correlation.

Two things make it worth building rather than just using the existing free web
version:

1. **The paper's own "next steps" are a parameter sweep.** The authors state
   they tested exactly one parameter combination and list the free parameters
   they expect to matter (modulation-rate range, rate of change, bandwidth,
   temporal modulation rate far above the <10 Hz they used, phase modulation
   beyond 2π, AM and PM combined with orthogonal ripples). A live-parametric
   Max patch is precisely the instrument for that space.
2. **The carrier need not be a synthetic harmonic complex.** The paper says so
   explicitly — the modulation could be applied to any sound with sufficient
   high-frequency content. That reframes the whole thing as a *processor*, and
   a processor is a much more interesting object than a stimulus renderer.

## Source material

- **Paper:** Yukhnovich, Harrison, Wray, Alter, Sedley (2025), _Chronic
  tinnitus is quietened by sound therapy using a novel cross-frequency
  de-correlating stimulus modulation_, Hearing Research 464.
  `doi:10.1016/j.heares.2025.109335`. Open access.
- **Data deposit:** `doi:10.25405/data.ncl.27109693`, deposited 15/10/2024,
  **licensed CC BY-NC-SA 4.0** (see Licensing below — this matters). Contains
  `README.txt`, `Final_Data_Set.xlsx` (anonymised participant demographics and
  questionnaire responses — outcome data, nothing needed for synthesis), and
  `Tinnitus_Spectral_Ripple_Sound_Therapy_Files.zip` (the MATLAB stimulus
  generation code). Retrieved 2026-08-04; **the MATLAB code has not been read
  yet** and remains the load-bearing item.
- **Existing implementation:** `checkhearing.org/spectralRipple.php` — free
  browser version by Christopher Chang MD. Takes tinnitus frequency (100–16000
  Hz), a four-step hearing-loss profile, and AM/PM choice; runs a timer and
  logs sessions. Faithful to the paper's *tested* configuration and exposes
  none of the free parameters above. Useful as a reference target: if a Max
  build can't match its output at default settings, the Max build is wrong.

## What the deposit's text files resolve (2026-08-04)

`Sound_files_notes.docx` is the authors' own stimulus-set inventory and is more
precise than the paper's prose in several places.

**Band assignment table, legible for the first time.** The paper's Table 1
renders as unreadable rubble in HTML. The full mapping from the 17 matching
frequencies to active (A) and control/sham (C) bands, where bands 1–7 are the
octaves 1–2, 1.4–2.8, 2–4, 2.8–5.7, 4–8, 5.7–11, 8–16 kHz respectively:

| Match | Freq | A1 | A2 | C1 | C2 |
|---|---|---|---|---|---|
| 1–3 | 1 / 1.2 / 1.4 kHz | 1 | — | 3 | — |
| 4 | 1.7 kHz | 2 | 1 | 4 | — |
| 5 | 2 kHz | 2 | — | 4 | — |
| 6 | 2.4 kHz | 3 | 2 | 5 | — |
| 7 | 2.8 kHz | 3 | — | 5 | — |
| 8 | 3.4 kHz | 4 | 3 | 6 | — |
| 9 | 4 kHz | 4 | — | 6 | — |
| 10 | 4.8 kHz | 5 | 4 | 3 | 2 |
| 11 | 5.7 kHz | 5 | — | 3 | — |
| 12 | 6.7 kHz | 6 | 5 | 4 | 3 |
| 13–14 | 8 / 9.5 kHz | 6 | — | 4 | — |
| 15–17 | 11 / 13 / 16 kHz | 7 | — | 5 | — |

A2/C2 are fallbacks used only when a frequency inside A1 is inaudible to that
participant. **The sham band is always two band-steps (one octave) from the
active band** — above it for matches 1–9, below it for 10–17. Since the modal
match was 8–9.5 kHz, sham was below for most participants, which is what the
paper's prose says.

**Other clarifications:**

- The seven bands are each one octave wide, spaced in **half-octave steps** —
  so adjacent bands overlap by half an octave. Confirms the band table.
- The third condition is called **"band-degraded"** here, "noise replacement"
  in the paper, and **"notched"/`noise` in the dataset README**. Three names,
  one thing. The dataset also calls phase modulation `freq`. Expect this when
  reading the MATLAB.
- Matching stimuli: 17 frequencies, 1–16 kHz in **quarter-octave** steps, 1 s
  duration with 1 s ISI, in tone and narrowband-noise versions × 4 hearing
  profiles = 8 files.
- Full stimulus set is 3 mod types × 4 hearing profiles × 7 bands = **84
  categories**, 2 demo files each = 168 files.
- **Discrepancy, now resolved:** the notes give file duration as 3:20 (50 × 4 s
  stimuli) while the paper says hour-long tracks. The MATLAB driver settles it —
  `n_per_file = 900` × 4 s = exactly 60 minutes. The deposited short files are
  the "demonstration of principle" set the notes describe; participants heard
  hour-long renders of the same generator.
- README gives collection dates as July 2020–April 2022; the paper says
  October 2020. Immaterial, noted only so it isn't mistaken for a
  transcription error later.
- `Final_Data_Set.xlsx` is participant demographics and questionnaire
  responses. Nothing in it bears on stimulus generation.

## Licensing — check before porting any code

The deposit is **CC BY-NC-SA 4.0**. That is a copyleft, non-commercial licence,
and it covers the MATLAB stimulus code. A Max patch that is a *translation* of
that code is a derivative work and would inherit BY-NC-SA — which is
incompatible with releasing it in a public `f_` repo under permissive terms,
and the NC clause is awkward for anything performed or sold.

The clean path is **independent reimplementation from the paper's published
equations** (the article is separately open access under a Creative Commons
licence, and mathematical methods described in a paper aren't themselves
restricted by the data deposit's licence). That means: use the MATLAB to
*resolve ambiguities and verify output*, not as a source to transcribe. The
equations are already transcribed above from the paper, which is the right
provenance — keep it that way, and don't paste MATLAB structure into the
codebox.

Not legal advice; if this ever ships publicly, the safest move is simply to
ask the authors, who released this to be used.

## The stimulus, exactly as specified

Transcribed from the paper so the build has a single authoritative reference.

**Carrier.** Hour-long concatenation of non-overlapping 4 s broadband harmonic
complexes. Each complex has a *new random fundamental* f0 ∈ [96, 256] Hz, with
all harmonics falling in 1–16 kHz included, each at a random starting phase
φₙ ∈ [0, 2π), and 1 s raised-cosine onset/offset ramps.

**Synthesis:**

```
s(t) = Σ_{n=nmin}^{nmax}  Aₙ(t) · sin(2π n f0 t + φₙ + ψₙ(t))
```

**One shared modulation matrix, two mappings.** Both modulation types are
driven by the same quantity — worth noting, because it means AM and PM are two
readouts of one signal, not two mechanisms:

```
Mₙ(t) = sin( 2π [ ω t + Fₙ · S(t) ] + q )

Aₙ(t) = 1 + d · Mₙ(t)          // amplitude mod: range 0–2, mean 1
ψₙ(t) = π ( 1 + d · Mₙ(t) )    // phase mod: range 0–2π (≡ frequency mod)
```

Outside the modulated band, and for the modulation type not in use:
`Aₙ = 1`, `ψₙ = 0`.

**Octave position and the varying ripple rate:**

```
Fₙ   = log2( n·f0 / c )        // harmonic's octave distance from band centre c
S(t) = μ + r · sin( p + 2π ν t )   // time-varying spectral modulation rate
```

**Tested values:** d = 1 (depth), ω = 1 Hz (temporal modulation rate),
μ = 4.5 cyc/oct (mean SMR), r = 3 (SMR variability), ν = 0.125 Hz (SMR cycle
= 8 s), q and p random per stimulus. Sample rate 44.1 kHz.

S(t) is constrained positive, which is why the ripples in the paper's figures
all slope downward — a consequence of the parameter choice, not a design
requirement.

**Band selection.** Modulation is applied to one octave from a fixed set of
seven: 1–2, 1.4–2.8, 2–4, 2.8–5.7, 4–8, 5.7–11, 8–16 kHz. The band chosen is
the one that places the matched tinnitus frequency closest to its centre. The
sham condition uses the nearest *non*-tinnitus octave (usually below). Matching
is deliberately approximate — tolerance to inexact matching is one of the
method's stated advantages.

**Hearing correction.** Four profiles applied to the carrier spectrum, differing
only in maximum correction: 0 / 15 / 30 / 45 dB. Shape: 0 dB up to 2 kHz, 1/9 of
max at 2.8 kHz, rising linearly to 8/9 of max at 8 kHz, at max above 8 kHz.

**Noise replacement (third condition).** Harmonics inside the band are replaced
by octave-wide noise matched to the band — preserves the power spectrum while
destroying fine temporal structure. Note this is a *different* therapy premise
(removing informational content), not a variant of the ripple.

## MATLAB code — what it actually does (read 2026-08-04)

**Files.** `mod_ripple.m` is the whole thing — one function, ~100 lines, no
dependencies beyond ramping. `Generate_Full_Experiment_Stimuli.m` is the driver
that produced the trial's 84 files and is stated to reproduce them exactly.
`Hearing_Tin_Stim_Generation.m` makes the 17-frequency matching stimuli.
`farpn.m` (fixed-amplitude random-phase noise via brickwall iFFT) and
`wind_ramp.m` are Griffiths/Newcastle Auditory Group toolbox helpers.
`wind.m` is byte-identical to `wind_ramp.m`; `freqfilter.m` and
`phase_randomise.m` are toolbox leftovers, unused by this pipeline.

### The three T1 questions, answered

- **`q` and `p` are redrawn per 4 s stimulus**, not per file — both are local to
  `mod_ripple`, which is called once per stimulus inside the 900-iteration loop.
- **`c` is the geometric mean of the modulated harmonics' frequencies**, not the
  band centre. The code computes `log2(fi/min(fi))` then subtracts its own mean,
  which is algebraically `log2(fi / geomean(fi))`. Because harmonics are
  uniformly spaced in *linear* frequency, their geometric mean sits ≈ 0.557
  octaves above the band's lower edge, not 0.5 — and it shifts slightly with f0,
  since f0 determines which harmonics land in the band.
- **Ramps are applied after modulation and are not aligned to it.** Modulation
  phase (`phase_off`) is independently random per stimulus, so the ripple is at
  an arbitrary point in its cycle when the 1 s ramp opens.

### Where the code and the paper disagree

Five. Two of them matter.

**1. The trial used sine-phase harmonics, not random phase. (Matters.)**
Eq. 1 in the paper specifies `φₙ` as a random phase offset per harmonic, and
the prose repeats it. The driver calls `mod_ripple(f0_tmp, 0, ...)` — the second
argument is `rand_phase`, and it is **0**. The function then builds `pmat` as
zeros. Every harmonic starts in sine phase, which makes the carrier an
impulse-like peaky waveform rather than the noise-like one random phase gives:
different crest factor, different timbre, different clipping behaviour. The
capability is in the function and was not used. Anyone reimplementing from the
paper alone would build the wrong carrier.

**2. Phase modulation depth is π, not 2π. (Matters.)**
Eq. 3 gives `ψₙ = π(1 + d·sin(…))`, range 0–2π, described as phase advancement
up to one full cycle. The code is `pi*(1+depth*sin(…))/2` — range 0–π, half a
cycle. The paper's stated PM depth is twice what was actually delivered.

**3. `q` sits inside the 2π multiply, and is drawn in the wrong units.**
Paper: `sin(2π[ωt + FₙS(t)] + q)`. Code: `sin(2π(phase_off + ωt + FₙS(t)))`, with
`phase_off = rand*2*pi`. So a value drawn as if radians is consumed as cycles
and wraps ~6.3 times. Since it is a uniform random offset either way, the
consequence is nil — but the equation as printed is not the equation as run.

**4. `Fₙ` is mean-centred over harmonics, not band-centred.** See above. A
constant offset in `Fₙ` is *not* a constant phase offset in the modulator,
because `Fₙ` is multiplied by the time-varying `S(t)` — a 0.057-octave shift
adds `0.057·S(t)` cycles, swinging over roughly 0.09–0.43 cycles across the 8 s
SMR cycle. It perturbs the ripple's drift trajectory rather than sliding it by a
fixed amount. Matters for bit-comparable reproduction; probably not for
character.

### Structural details the paper omits

- **Internally there are eight *half-octave* bands, not seven octave ones.**
  `fb = 1000*2.^(0:0.5:4)` gives nine edges; `fbands` is the eight half-octave
  spans between them. Modulation is applied to **two adjacent half-octave
  bands** (`fband_mod = b + [0,1]`, b = 1…7), which is how the seven overlapping
  one-octave regions arise. The hearing correction is applied *per half-octave
  band* as a staircase, not as a smooth curve — eight discrete gains.
- **Correction gains** are `[0, 0, 0.125, 0.375, 0.625, 0.875, 1, 1]` × the
  profile's max dB (0/15/30/45), applied as `10^(dB/20)`. Each band takes the
  template value at its own geometric centre (the even-indexed quarter-octave
  frequencies), which is a tidy detail worth copying.
- **The correction is boost-only** — no compensating cut — so a severe-HL file
  is substantially louder overall than a normal-hearing one. The driver has to
  peak-normalise to avoid clipping. Any Max build needs the same guard.
- **Level target: RMS 0.01.** `loud = 0.1` scaled by `loud/(10·std)`. The author
  flags it `%%%%% Needs optimising`.
- **Per-band ramping is a mathematical no-op.** The code sums each band, ramps
  each band separately, then sums the bands — and since the ramp is the same
  linear multiply for every band, this is identical to ramping the final sum
  (the whole-stimulus ramp is commented out). Leftover structure from when bands
  could presumably differ. Don't go looking for subtlety here.
- **Ramp shape:** `wind_ramp` builds a raised cosine over `sin(linspace(-π/2,
  1.5π, 2·win))`, applying the rising half to the first `win` samples and the
  falling half to the last. With `ramp_prop = 0.25` on a 4 s stimulus that's a
  1 s ramp each end, as the paper says.
- **Harmonic selection:** `ceil(f_lo/f0) : floor((f_hi−1)/f0)` — the stray −1 Hz
  prevents a boundary harmonic being counted in two adjacent bands.
- **`normfreq = 0`** in the trial call: flat harmonic amplitudes, no 1/f tilt.
  Matches the paper. The 1/f option exists in the function, unused.
- **Noise-replacement band edges are the *harmonics'* extremes**, `min(fimod)`
  to `max(fimod)`, not the nominal band edges (that version is commented out).
  Noise is RMS-matched to the harmonic sum it replaces and dropped into a single
  matrix row, so it inherits that band's ramp like everything else.
- **900 stimuli × 4 s = 3600 s.** Confirms the paper's hour-long files and
  confirms the earlier inference that the deposit's 3:20 files are the
  "demonstration of principle" set, not what participants heard.
- **`dur_range = [4,4]`** — the driver supports randomised per-stimulus duration
  (rounded to 0.1 s) and was deliberately pinned to a constant 4 s. Likewise
  `files_per_category = 1`, annotated *"higher number will reduce repetitiveness
  and predictability."* The author's own view is that the fixed 4 s block
  structure is a knob, and a slightly uncomfortable one. Relevant to Q2.

### The commented-out SMR line is not a behaviour change

`mod_ripple` carries a superseded line for `s`, and the driver carries a
superseded call using `smr = [3,6], scyc = 4`. Easy to misread as "the trial
used different values." It didn't: the old form was
`mean(smr) + |diff(smr)|·sin(2π·t/(2·scyc))` = `4.5 + 3·sin(2π t/8)`, and the
new form with `[1.5,7.5], scyc = 8` is `4.5 + 3·sin(2π t/8)`. Identical output.
The fix re-parameterised `smr` from an opaque pair into an honest
[min, max] and made `scyc` mean the actual cycle duration. **So the trial's SMR
really is μ = 4.5 cyc/oct, r = 3, 8 s cycle**, matching the paper.

### Corrected equation set (code-accurate)

```
Mₙ(t) = sin( 2π [ q + ω t + Fₙ · S(t) ] )      q ~ U(0, 2π), per stimulus
Fₙ    = log2( fₙ / geomean(f_modulated) )
S(t)  = μ + r · sin( p + 2π t / scyc )          p ~ U(0, 2π), per stimulus

AM:   sₙ(t) = (1 + d·Mₙ(t)) · sin(2π fₙ t)
PM:   sₙ(t) = sin( 2π fₙ t + (π/2)(1 + d·Mₙ(t)) )
none: sₙ(t) = sin(2π fₙ t)                      (harmonics outside the band)
```

with `d = 1`, `ω = 1 Hz`, `μ = 4.5 cyc/oct`, `r = 3`, `scyc = 8 s`, all
harmonics in sine phase, each scaled by its band's hearing-correction gain,
summed, RMS-normalised to 0.01, then given 1 s raised-cosine ramps.

## What the study actually found

Stated plainly, because it bears on how much effort this deserves:

- Primary outcome (self-rated loudness, 0–10 NRS) fell 0.47 after six weeks of
  the active de-correlating stimulus (p = 0.012); sham did essentially nothing
  (p = 0.916). The reduction persisted through a three-week washout and was
  still trending downward at the end of it.
- AM and PM performed near-identically and were pooled.
- Distress scores (THI, TFI) fell in *both* active and sham — a placebo/
  participation effect, not evidence for the modulation.
- **Noise replacement inverted**: the sham helped, the active didn't. The
  authors offer speculative explanations and no confident one. Treat this
  condition as unresolved rather than as a working therapy.
- n = 53 completers for the pooled AM/PM analysis; fully online, unsupervised
  frequency matching, uncontrolled daily listening duration.

So: a real but modest effect, one parameter set, one trial. The interesting
thing here is the *stimulus design*, and the fact that the tested corner of its
parameter space was chosen more or less arbitrarily.

## Architecture options

Three genuinely different builds. They are not variants of each other and
should not be blended before one is chosen.

### A — `gen~` additive synthesis (faithful generator)

Rebuild the paper's synthesis directly. Every partial computed per sample.

**Structural property that makes this tractable:** there is no per-partial
state to carry. Phase is `2π n f0 t` — an explicit function of elapsed time,
not an accumulator — and the modulation depends only on `t` and `Fₙ`. So the
whole stimulus is a stateless function of `(t, n)`, and a `gen~` codebox `for`
loop over harmonics needs one time ramp and nothing else. (`t` resets each
4 s stimulus, which also keeps the phase argument small enough that precision
never becomes a question.)

**Cost.** f0 = 96 Hz gives harmonics n ≈ 11–166 in the 1–16 kHz range: ~156
partials, two `sin` each in the modulated band. Worst-case modulated band is
8–16 kHz (n ≈ 83–166, ~84 partials). Needs measuring, not guessing.

**The optimization that probably makes it cheap:** the *unmodulated* partials
have `Aₙ = 1`, `ψₙ = 0`, so their sum is strictly periodic at f0. One
wavetable, one `phasor~`/`wave~`, regardless of how many partials it contains.
Only the modulated octave — 11 to 84 partials depending on band — needs
per-partial per-sample work. The table is re-rendered once per 4 s stimulus
when f0 and the random phases change, which is cheap and off the audio path.

`φₙ` is **zero in the trial configuration** (sine phase — see the code
findings), which removes a whole problem: no per-partial phase state, no hash,
and the unmodulated wavetable is just a bandpassed impulse train. If the
random-phase option is exposed as a parameter, `φₙ` should come from a hash of
`(n, stimulus_index)` rather than sampled noise, so it's reproducible and held
for exactly the stimulus duration.

### B — `pfft~` spectral processor (arbitrary carrier)

Apply `Mₙ(t)` as per-bin gain (AM) or per-bin phase advance (PM) inside a
`pfft~`, on any input. This is the version the paper gestures at and never
built, and the one that behaves like an `f_` module rather than a renderer:
audio in, de-correlated audio out.

Trade-offs: bin resolution vs. ripple density at low frequencies (4.5 cyc/oct
across 1–2 kHz is a fine ripple in linear bin spacing); phase modification in
an overlap-add FFT is not equivalent to true phase advancement of a partial
and needs verification against the additive version; ramps/windowing artifacts.

### C — Offline render to `buffer~` / file

Reproduce the Matlab pipeline: render 4 s stimuli, concatenate, write a file.
Least interesting — it reproduces something already freely available, gives up
live parameter exploration, and teaches nothing. Worth doing only as a
*verification harness*: render one stimulus with known parameters, compare its
spectrogram against the paper's Fig. 3–4 and against the checkhearing output.

### Recommendation

**A first, B as the real destination.** A is faithful, verifiable against
published figures, and its correctness is checkable by eye in a spectrogram.
B is the module worth having, but it needs A as ground truth — otherwise
there's no way to tell a bin-resolution artifact from a working de-correlation.

## Cross-domain note (`f_`'s actual interest here)

`Mₙ(t)` **is a texture**. The modulation matrix is literally a 2D time–frequency
image of a drifting ripple whose spatial frequency varies sinusoidally — the
paper's own Fig. 3C is that image. Computing it in Jitter (`jit.expr` or a
`jit.gl.pix` codebox, 1×N per frame or N×T scrolling) and feeding it to `gen~`
as per-partial modulation depth would:

- put the ripple generator in the domain the rest of this library already
  works in,
- make the control surface for the audio and a visual companion the same
  object, and
- give a display of exactly what's being applied, which the web version does
  not have.

Precedent: `f_chladni` already ships with an audio companion patch, so the
audio↔visual pairing has a shape in this repo. **Unverified** whether a
per-frame Jitter→`gen~` handoff has acceptable latency/granularity for a 1 Hz
temporal modulation rate — it almost certainly does, since nothing in the
modulation moves faster than a few Hz, but it hasn't been tested.

This is also the one honest argument for the module living in `f_` at all
rather than as a standalone patch. See "Does this belong here" below.

## Proposed parameter contract (draft)

Grouped by whether the paper fixed the value or left it free.

**Targeting**
| Param | Range | Default | Note |
|---|---|---|---|
| `tin_freq` | 100–16000 Hz | 8000 | matched tinnitus frequency |
| `band_mode` | auto / manual / free | auto | auto picks the best of the 7 octaves |
| `band` | 1 of 7 | — | manual override |
| `bandwidth` | 0.5–3 oct | 1.0 | **free parameter, untested in the trial** |
| `condition` | active / sham | active | sham = nearest non-tinnitus octave |
| `hearing_profile` | normal / mild / mod / severe | normal | 0/15/30/45 dB tilt |

**Modulation**
| Param | Range | Default | Note |
|---|---|---|---|
| `mod_type` | AM / PM / both / noise-replace | AM | AM and PM share one matrix |
| `depth` (d) | 0–1 | 1.0 | |
| `tmr` (ω) | 0.1–256 Hz | 1.0 | paper: periodotopy extends to ≥256 Hz, untested |
| `smr_mean` (μ) | 0–12 cyc/oct | 4.5 | |
| `smr_range` (r) | 0–12 | 3.0 | r > μ lets SMR go negative → up-sloping ripples |
| `smr_rate` (ν) | 0.01–2 Hz | 0.125 | |
| `pm_turns` | 1–64 | 1 | PM ceiling beyond 2π — explicitly flagged in the paper |

**Carrier** (mode A only)
| Param | Range | Default | Note |
|---|---|---|---|
| `f0_lo` / `f0_hi` | 50–400 Hz | 96 / 256 | |
| `stim_dur` | 1–30 s | 4.0 | |
| `ramp` | 0–50 % | 25 % | 1 s of 4 s in the trial |
| `spec_lo` / `spec_hi` | — | 1 / 16 kHz | harmonic inclusion range |

`gain` and `mix` are the library's canonical names and should be used as such
if this ever becomes a real module — `mix` only makes sense in build B.

## Open questions

**Q1 — Which build.** A, B, or A-then-B. Blocks everything. (See
Recommendation above; not yet Matt's decision.)

**Q2 — Are the 4 s stimulus and 1 s ramps therapeutic, or an artifact of
offline rendering?** Half of every stimulus is ramp, producing a strong ~0.25
Hz pulsing. The paper *speculates* this slow beat percept may itself have
contributed to the relaxation effect — so it may not be incidental. But
non-overlapping 4 s blocks with hard f0 resets are exactly what you'd do if
you were concatenating pre-rendered files, and a real-time synth has no such
constraint (it could crossfade, overlap, or drift f0 continuously). Deviating
means no longer running the studied stimulus. Decide deliberately.

**Partially answered 2026-08-04 by the code.** The driver exposes `dur_range`
as a *range* with per-stimulus randomisation and rounding, then pins it to
`[4,4]`; and `files_per_category` carries the author's own note that raising it
*"will reduce repetitiveness and predictability."* So the fixed 4 s block is a
knob the author built and chose not to turn, and he was already uneasy about
predictability. That is permission to treat it as free — but it doesn't resolve
whether the resulting ~0.25 Hz pulsing is load-bearing.

**Q3 — Does the PM implementation actually match?** `ψₙ` is described as phase
*advancement* equivalent to frequency modulation. In build A this is a direct
phase offset per partial and is unambiguous. In build B it isn't. Verify A
against B, and A against the checkhearing output, before trusting either.

**Q4 — Partial count / CPU.** Unmeasured. The wavetable split above should
make it a non-issue, but "should" isn't a measurement. Also unmeasured:
whether the modulator itself can run at a lower rate and interpolate, given
nothing in it exceeds a few Hz at default settings (though `tmr` up to 256 Hz
would break that assumption — see Q5).

**Q5 — High `tmr` changes the character entirely.** At ω = 1 Hz this is a slow
shimmer. At 100+ Hz the modulation is in the audio range and becomes
sidebands/roughness rather than a ripple drift. The paper argues periodotopic
organization means this region might be *more* effective, and equally it might
just sound bad. Genuinely unknown; the patch is how you'd find out.

**Q6 — Does the hearing-correction tilt belong in the module or upstream?** It
is a fixed EQ curve. Arguably `f_a_tilt` or just a `filtergraph~`. Folding it
in makes the module self-contained; splitting it keeps the module about one
thing.

**Q7 — Where does the modulation matrix get computed?** `gen~` codebox
arithmetic, or Jitter (see Cross-domain note). Gated on Q1 and on whether a
visual companion is actually wanted or is retrofitted justification.

## Scratch tests (all untested)

Cheap, ordered, each one settles something.

- **T1 — Read the authors' MATLAB code.** ✅ **DONE 2026-08-04.** All eight `.m`
  files read. Findings in "MATLAB code — what it actually does" above. Two
  discrepancies would have produced a wrong build from the paper alone
  (sine-phase carrier, half-depth PM). Read as reference only, not transcribed —
  see Licensing.
- **T2 — Static harmonic complex.** ✅ **PASSED 2026-08-04.** One `gen~` codebox loop, random f0,
  harmonics 1–16 kHz, **sine phase** (per the code, not the paper), no
  modulation. Confirms the loop-over-harmonics-with-one-time-ramp structure
  works. Compiles and sounds right in Max. (Q4)
- **T3 — Wavetable equivalence.** ⏳ **Partially run 2026-08-05, verdict
  pending.** Full trace, in order:
  1. **poke/peek argument order & units confirmed correct.** Manual round-trip
     test (write 0.5 at index 10, read index 10) returned exactly 0.5.
  2. **Static-index table reads confirmed correct.** A for-loop-populated
     ramp table (`table[i] = i/64`) read back exactly right at `idx_test` =
     0, 32, 63.
  3. **`peek` floors fractional indices rather than interpolating** —
     `idx_test = 31.5` read back exactly `table[31]` (0.484375), not an
     interpolated ~0.492. Plausibly correct, unbuggy default behavior for a
     table-lookup opcode, not itself a bug.
  4. **Initial hypothesis (render loop re-firing every sample) ruled out** —
     added a `render_count` debug outlet (`History`, incremented only inside
     the one-shot gate) read via `snapshot~`; it sat at 1 through repeated
     checks, including after restoring the full nested loop.
  5. **Phase accumulator (`ph_prev`/`idx`) confirmed correct** — but only
     after a real methodology mistake got caught: every scope reading up to
     this point was taken at f0≈150 Hz, where ~20 cycles compress into one
     scope window and a correct sawtooth and a broken signal are hard to
     tell apart from a description of the pixels. Dropping to f0=5 Hz (1–3
     cycles visible) showed an unambiguous clean sawtooth — the "narrow
     dips" seen in earlier screenshots were very likely this same correct
     signal, misread. **Lesson for future scope-based scratch tests: pick a
     test frequency low enough that the shape is legible in one glance,
     don't infer waveform correctness from a compressed multi-cycle image.**
  6. **Nested loop (64 table positions × 200 harmonics, ~12,800 iterations,
     one-shot on render) compiles and runs** — no hang, no console error,
     `render_count` still held at 1 with the heavier loop in place. The
     compile-time risk flagged before this test started did not materialize.
  7. **Residual against A, run at f0=5 Hz, was non-flat and structured** —
     not simply "B contributes nothing" (the original symptom) but not a
     clean null either. **This result is suspect, not a verdict**: at
     f0=5 Hz, both codeboxes' fixed 200-harmonic loop bound (`n<=200`) can
     only just barely reach the 1–16kHz band at all (200×5=1000 Hz, right at
     the lower edge) — A's output should be near-silent at this frequency if
     working as designed, and its scope visibly wasn't, which undermines
     trusting this particular comparison. **T3 needs a rerun at a realistic
     f0 (96–256 Hz, the module's actual design range) before treating either
     a null or a non-null result as meaningful.**

  Scratch files: `/Users/matt/Vsynth/patterns/f_a_ripple_scratch.maxpat`
  (clean T2-passed reference, untouched) and
  `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t3.maxpat` (left in its
  "test 7" state — nested-loop render restored, `render_count` debug outlet
  still wired, manual `idx_test` inspector still present alongside the live
  `f0`-driven path — good starting point for the rerun, not cleaned up).
- **T4 — Modulation matrix as a signal.** ✅ **PASSED 2026-08-05.** Built
  `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t4.maxpat`: `Mₙ(t)` and
  `S(t)` computed in isolation from a fixed, directly-testable `Fn` (standing
  in for a real partial's `log2(fn/geomean)`), no audio wiring yet. Two real
  problems surfaced and got fixed along the way, both worth remembering:
  1. **Reading a slow-drift scope by eye isn't a real verification method.**
     First pass tried "eyeball the wiggle rate changing" — correctly flagged
     by Matt as unusable ("I'm not an oscilloscope"). Replaced with an actual
     numeric spot-check: `q`/`p` exposed as read values (`q_actual`,
     `p_actual`), plus a by-hand computation (`S_expected = smr_mean +
     smr_range·sin(p_actual)`, `M_expected = sin(2π·(q_actual +
     Fn·S_expected))`) checked against live readouts.
  2. **That spot-check still failed until `t` was frozen.** Point-in-time
     reads taken by clicking then screenshotting were landing at
     unpredictably different elapsed times (human reaction time vs. an 8s
     `smr_cycle` — not negligible), producing readings that looked like
     random noise but were actually just `t` drifting during the click→read
     gap. Fixed by adding a `run` toggle (off by default) gating whether `t`
     advances at all — `t` now stays locked at exactly 0 after a reset until
     `run` is explicitly enabled, removing the timing race entirely.
  3. **`reset` collides with a `gen~` built-in system message — new finding,
     different dialect than the `jit-gen-codebox` skill's existing `mix()`
     collision.** Naming a `Param` `reset` and sending it `reset <n>`
     produced `gen~ • extra arguments for message "reset"` followed by
     `: bad number` in the Max console, every single time, until the Param
     was renamed to `trig` (only the internal codebox identifier — same
     fix-shape as the earlier `mix`→`mix_pct` collision). Confirmed
     empirically 2026-08-05: error present with `Param reset(0)`, gone after
     rename, no other change. **This is the audio/`gen~` dialect's version of
     the same collision class documented for `jit.gl.pix` in
     `jit-gen-codebox/SKILL.md`** — worth a documented home (see Open
     questions below on where).
  4. Once fixed, verified via a live console table (`t`, `S`, `M` triples
     logged every 200ms while `run` is on, ordered deterministically via a
     `trigger` object so each row is coherent rather than a mix of
     stale/fresh reads): `S` correctly swept from its analytic max
     (`smr_mean+smr_range` = 7.5, observed 7.499275 at `t=33.972`) down
     toward its min (1.5, observed still falling at `t=37.364`, ~3.4s later
     against a half-cycle of 4s at `smr_cycle=8` — right on schedule), while
     `M` stayed bounded in [-1,1] throughout. This confirms the actual T4
     criterion (drift + breathing on the configured `smr_cycle`) with real
     numbers, not a visual impression.

  Scratch file: `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t4.maxpat`.

- **T5 — AM on one octave.** ⏳ **Partially passed 2026-08-05, spectrogram
  comparison still open.** Built
  `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t5.maxpat`, combining T3's
  wavetable (unmodulated partials — now correctly excluding the modulated
  band from the render loop) with T4's proven modulator, applied as real AM
  to the modulated band's own per-sample partials. Two design questions
  resolved before building, both by extending already-proven patterns
  rather than inventing new ones:
  1. **Carrier-phase precision** — considered testing raw-elapsed-`t` phase
     for the modulated partials' own carrier separately, then realized this
     was solving a strawman: the obviously-correct build reuses T2/T3's
     already-validated wrapped `n·ph_prev` carrier phase (bounded, safe)
     for every partial regardless of modulation, and only feeds raw `t`
     into the *modulation* terms (`ω·t`, `Fₙ·S(t)`), which T4 already
     confirmed stay small. No dedicated precision smoke-test needed.
  2. **Real `Fₙ` per harmonic** — T4 used a hand-set test `Fn` to isolate
     the modulator; T5 needed the actual `log2(fₙ/geomean(f_modulated))`.
     Solved with a one-shot `geomean_mod` computation (log-domain mean over
     just the modulated-band harmonics), gated by the same `trig`-changed
     pattern as T3's wavetable render — same primitive, reused, not a new
     mechanism.

  At defaults (band 6 = 5657–11314 Hz, f0=96) — **sounds close to
  indistinguishable from the checkhearing.org reference by ear.** Real
  signal, correct general character, not obviously broken. **The actual
  spectrogram-vs-paper's-Fig.-4 comparison has not been run** (no
  spectrogram tool available this session) — this is a listening-only
  result, a real step below T3/T4's numeric-verification bar, and shouldn't
  be treated as equivalent to a passed spectrogram check. Also confirmed:
  **DSP held up clean with no glitching** at low `output_level`, despite
  the modulated-band `for (n=1..200)` loop now running per-sample at audio
  rate — the first actual evidence (not just a prediction) toward the
  Primary Risk section's unmeasured CPU-cost question, though not a full
  measurement (no profiling, band 6 only, not the worst-case band 7 at
  ~84 partials).

  Scratch file: `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t5.maxpat`.

- **T6 — PM on one octave**, then A/B against T5 by ear and by spectrogram.
  ⏳ **Partially passed 2026-08-06, spectrogram comparison still open.**
  Built `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t6.maxpat` as a
  clone of T5 with one addition: a `mod_type` toggle (0=AM, 1=PM) switching
  only the final per-partial mapping — everything upstream (wavetable
  render, `geomean_mod`, `q`/`p` draw, `Mₙ(t)`/`S(t)`) is shared, identical
  code, so flipping `mod_type` mid-stimulus without re-triggering "new
  stimulus" is a genuine like-for-like comparison rather than two
  independently-randomized patches. Uses the code-accurate PM formula —
  `sin(2π fₙ t + (π/2)(1 + d·Mₙ(t)))`, depth `π/2` not the paper's stated
  `π` (MATLAB discrepancy #2 above) — computed alongside the AM formula
  every sample, selected by a single ternary.

  **A/B by ear passed**: PM "sounds a little different, a plausible
  variant" of T5's AM at the same modulator state — exactly the expected
  outcome, since AM and PM are genuinely different perceptual mappings of
  the same shared `Mₙ(t)`, not two routes to identical output. **The
  spectrogram comparison has not been run** — same gap, same cause as T5
  (no spectrogram tool available this session).

  Scratch file: `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t6.maxpat`.

- **T7 — `pfft~` version**, null/compare against T5. (Q1, Q3) ✅ **PASSED
  2026-08-07** (AM confirmed working; PM/T7b not yet attempted). Built
  `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t7a.maxpat` (AM-only,
  reduced scope agreed up front: no shared random draw with T5,
  typed-matching params instead — see file header) plus the required
  external subpatch `/Users/matt/Vsynth/patterns/t7a_inner.maxpat` (`pfft~`
  loads subpatches by name from disk; unlike `gen~`, it does **not** support
  inline-embedded patcher JSON — confirmed by a `no patcher t7a_inner`
  console error until the content was extracted to its own file).

  **Long path to the answer, worth recording in full.** Signal path was
  confirmed working end-to-end early, after finding and fixing two real
  structural bugs (`pfft~`'s external-subpatch requirement, above; and a
  `gen~` codebox's true multi-signal inlets needing the built-in
  `in1`...`inN` keyword syntax, not `Param` declarations — both written up
  in `gen-tilde-codebox/SKILL.md`). But the actual per-bin AM effect
  stayed stubbornly absent through **four separate `gen~`-inside-`pfft~`
  control-routing architectures** — 10 dedicated inlets, 4 inlets with one
  shared for `Param` dispatch, `Param` messages into the same inlet
  carrying the real signal (matching T2-T6's proven convention), and a
  hand-typed message bypassing the whole outer chain. Every one produced
  zero audible effect from `depth`, confirmed by direct `depth=0` vs.
  `depth=100` (later `100`) A/B listening each time. Also ruled out along
  the way: compile caching, a silent reserved-word collision
  (`depth`→`dpth`, no change), spectral leakage diluting the effect.

  **This was a real process failure, not just a hard bug** — debugging
  proceeded by guessing plausible fixes from `.maxref.xml` reference prose
  one architecture at a time, rather than first reading Cycling '74's own
  worked examples. Matt's direct intervention broke it open: asking
  whether the help files had actually been read, then suggesting the
  external-subpatch mechanism itself was the more suspect thing to
  question rather than the routing details within it. Reading
  `Examples/gen/pfft.pfftgen.maxpat` and `Examples/fft-fun/lib/
  fp_fft.maxpat` revealed the real idiom: **a per-bin gain curve
  precomputed into a named `buffer~`, read inside `pfft~` via plain
  `index~` — no `gen~`, no `Param`, no message inlet into `pfft~` at all.**
  Rebuilt on that basis (`uzi`-driven message-rate sweep through `expr`,
  writing via `peek~`, since `gen~`+`snapshot~` can't keep pace with
  `uzi`'s bang-burst speed) — **confirmed working immediately: "I can
  clearly hear the ripple now and depth has a pronounced effect."**

  Two new skills came out of this: `max-advanced-object-methodology/
  SKILL.md` (read help/example patches before architecting with an
  unfamiliar object; build the smallest verified increment; don't present
  a documentation-based guess with confirmed-pattern confidence) and a
  full rewrite of `pfft-spectral-processing/SKILL.md` documenting the
  working `buffer~`/`index~` pattern as the canonical approach, with the
  four failed `gen~` architectures kept as a "what didn't work" record
  rather than deleted.

  **T7b (PM in `pfft~`) is next** — no longer blocked on a control-routing
  problem (the `buffer~`/`index~` pattern generalizes), but still has its
  own open question: phase modulation in overlap-add STFT needs
  `cartopol~`/`poltocar~` and isn't obviously equivalent to true
  per-partial phase advancement (see skill file). Not yet started. The
  spectrogram-vs-Fig.-4 comparison also remains unrun (same tooling gap
  as T5/T6).

  Scratch files: `/Users/matt/Vsynth/patterns/f_a_ripple_scratch_t7a.maxpat`,
  `/Users/matt/Vsynth/patterns/t7a_inner.maxpat`.

- **T8 — Cross-frequency correlation check.** Compute the off-diagonal
  correlation matrix of band envelopes (Fig. 3Ai vs 3Aii) for a fixed-SMR
  ripple vs. the varying-SMR one. This is the *actual claim* of the paper and
  the only test that verifies the stimulus does what it says rather than merely
  sounding like it should. Offline analysis, not real-time.

T8 is the one that would be easy to skip and shouldn't be — everything else
confirms it sounds right, and "sounds right" is exactly what the sham condition
also achieved.

## Does this belong here

Open, and worth answering before speccing rather than after. The `f_focus`
precedent applies: a module can be feasible and still not warrant existing.

**For:** `f_a_` exists and is exactly this class. The modulation matrix is a
texture-shaped object and the visual pairing is real, not decorative. The
parameter space is genuinely unexplored and a live patch is the right
instrument for it. `f_a_purr` established that audio-domain modules in this
repo are about *mechanism*, not about deliverables — same here.

**Against:** it is a therapeutic tool, not a performance instrument. Nothing in
it feeds a visual chain, nothing in it composes with the vecfield ecosystem,
and it will never appear in `f_modules`. A free, faithful, better-validated
web version already exists for actual daily use. It could equally live as a
standalone patch in `~/Vsynth/patterns/` or its own small repo.

Middle path, probably right: **build it as a scratch patch first without
deciding.** T1–T5 answer whether it works; the "does it belong" question only
becomes real if there's something worth shipping.

## Naming

`f_a_spectral_ripple` is descriptive but long, and "spectral ripple" already
means the *fixed*-rate stimulus in the psychoacoustics literature — the whole
novelty here is that the rate varies. Alternatives: `f_a_decorrelate` (names
the mechanism and the claim), `f_a_ripple` (short, but collides conceptually
with visual ripple), `f_a_smr` (opaque). If the processor version (build B)
happens, generator and processor likely want separate names.

## Safety

Not medical advice, no claims, personal experimentation only. The trial's
listening instructions, worth carrying into any patch that gets used rather
than just tested: no more than 60 % of device volume, no more than 60 minutes
at a time, 60 minutes between sessions. Participants were excluded if loud
sound had previously worsened their tinnitus. Any patch built here should be
level-limited by construction — an additive synth with ~150 partials and a
depth-1 AM has an easy path to a much louder output than intended if `depth`
or partial count changes and nothing normalizes.
