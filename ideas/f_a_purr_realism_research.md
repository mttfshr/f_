# f_a_purr — realism research

_2026-11-03. Web research on techniques for making the synth sound more like a
cat. Findings 1-5 come from acoustics and voice-science sources only. A later section
studies the architecture of one public generator, after Matt relaxed the rule on
2026-11-04 (see `ideas/f_a_purr.md` Notes). Written from search results and
one fetched primary paper; confidence is marked per item. Nothing here is
verified against the codebox by ear._

## What was and wasn't new

Agrees with `tasks.md` T032 (inhale/exhale deltas: literature disagrees),
T033 (no chest/tract resonance numbers published) and T034 (no purr-specific
synthesis model exists). New: actual measured magnitudes for breath timing, a
flow-reversal amplitude account, and the voice-synthesis literature on
non-white jitter.

## Findings

### 1. Breath timing: slower than measured, and the asymmetry is smaller (high confidence on the numbers, n = 4 cats)
Schötz & Eklund 2011 (fetched, Table 1; ~70 s of calm purring per cat, four
cats: three 6-month-olds and one 16-year-old, 3.0-5.2 kg, so mostly young cats):

| cat | inhale ms | exhale ms | breath s | breath Hz | inhale share |
|---|---|---|---|---|---|
| Donna | 673 | 587 | 1.26 | 0.79 | 53% |
| Rocky | 819 | 756 | 1.58 | 0.63 | 52% |
| Turbo | 604 | 511 | 1.12 | 0.90 | 54% |
| Vincent | 511 | 484 | 1.00 | 1.01 | 51% |

(Breath period, Hz and share are my arithmetic from their means.) Inhale was
significantly longer than exhale in all four. Remmers & Gautier 1972 reported
the opposite direction (exhale 730 ms, inhale 690 ms, inhale share about
49%). Both are small asymmetries.

Against the engine: the T011 preset has `breath_hz` 0.32 (3.1 s breath, 2-3x
slower than all four cats) and `breath_skew` 0.79, which the warp
`fi = 0.5 - 0.4 * skew` turns into an inhale share of about 18%. The warp can
only ever make inhale 10-50% of the period, never longer than exhale. The idea
file's principle "exhale longer than inhale" is stronger than any measured
value and is contradicted in direction by the one fully quantified study.

Variability: the standard deviation of phase durations was 9-21% of the mean
(inhale: 0.18, 0.21, 0.10, 0.17; exhale: 0.14, 0.17, 0.09, 0.14; Donna,
Rocky, Turbo, Vincent). The breath is not periodic.

### 2. Amplitude should dip at both flow reversals (medium confidence; one source seen only secondhand)
Remmers & Gautier's account, as quoted on a secondary site (the paper itself
was not readable): sound and vibration amplitude diminish when respiratory
flow reverses, and are inaudible or only articulation noise at exactly zero
flow. Herbst et al. 2023 critique R&G's muscle/EMG mechanism, not this
observation; under the myoelastic-aerodynamic account (which Herbst supports)
vibration needs airflow, so a dip at zero flow is expected (my inference). A
low-reliability student site says the interruptions are very short, so the dip
probably should not reach silence.

Against the engine: `b_curve = 0.5 - 0.5 cos(2 pi phase)` is zero at the
exhale-to-inhale boundary and peaks at 0.5, the inhale-to-exhale boundary. One
hump per breath, peaking at a reversal. The data suggest two humps (mid-inhale
and mid-exhale) with dips at both boundaries. This is `tasks.md` T015.

SPL by phase in the four-cat study: exhale louder in two cats, no difference
in the other two. So no fixed loudness asymmetry is justified.

### 3. Jitter and shimmer in natural voices are not white (medium confidence, human speech not cats)
Aoki & Ifukube 1996: jitter and shimmer in non-pathological sustained
phonation follow a power law; in paired comparisons by 25 listeners, 1/f
jitter and shimmer sounded more human-like than Gaussian white noise. The
exponent is not consistent in Aoki's own work (1/f in the 1996 abstract, 1/f^2
favoured in the 2000 thesis). Mattioli et al. 2015: jitter plus shimmer
together were judged most natural, shimmer alone the least. The 1966 Bell
patent already restores random period-to-period glottal variation for
naturalness. The engine draws independent noise every click cycle.

### 4. Phase-to-phase F0 variation and per-cat direction (low-medium confidence)
Per-phase mean F0 across phases varied by roughly 5-15% of F0 (my reading of
Table 1's standard deviations; the table does not label what they cover).
Which phase has the higher F0 differs by cat: higher on exhale in two cats,
higher on inhale in one, no difference in one. So no fixed inhale/exhale rate
offset is supported; `breath_rate_mod` as a free per-cat dial fits. F0 ranges
20.9-27.2 Hz across the four cats and phases.

### 5. Source model (high confidence)
Herbst et al. 2023 (Current Biology, CC BY): all eight excised cat larynges
sustained purr-range oscillation (25-30 Hz) with no neural input, by the same
myoelastic-aerodynamic mechanism as most vocalization, helped by connective
tissue pads in the vocal folds. The authors say active muscle contraction may
still play a role. This makes creaky-voice/vocal-fry models a fair guide.
Vocal-fry work (Devaraj et al. 2021) describes pulse trains with cyclic
amplitude modulation (two or more pulses per cycle). Nothing found shows this
in cats; parked.

## Not found
- No published cat purr click waveform or spectrum (the Herbst paper has
  6,000 fps glottal video from excised larynges; only its abstract and
  highlights were read, so the glottal opening shape is an untapped lead).
- No purr-specific synthesis or physical model. Granular and procedural-audio
  hits were generic and sample-based.
- A claimed 380-550 Hz "solicitation" component came from a low-reliability
  aggregator; not built on.

## What this led to (2026-11-03, see `tasks.md` T035-T038)
Four new params, all defaulting to the old behaviour: `breath_shape` (T015,
two humps), `breath_jit` (per-breath period jitter), `jit_tau` (correlated
click jitter), and `breath_skew` widened to -1..1. A/B message boxes in the
scratch test patch: the T011 preset against an evidence-based set (`breath_hz`
0.8, `breath_skew` -0.1, `breath_shape` 1, `breath_jit` 0.15, `jit_tau` 0.5).
These were chosen from the numbers above, not tuned by ear.

## Architecture of one public generator: Purrli (studied 2026-11-04)

Source: Matt pasted the page's JavaScript into chat. It is not stored in this repo, and
by the relaxed rule nothing below records its code, constants or sample files. Part of
the script is hex-obfuscated; decoded, the hidden strings were only standard Web Audio
API names and slider labels, so the structure below is readable.

- **Sample-based, not synthesized.** Two looping recorded sources (one inhale, one
  exhale) plus a sheet of meow clips, through a master gain, a low shelf and a broad
  high-frequency cut. Every pulse heard is a real cat's. The UI tempo is labelled
  "purrs per minute", i.e. a breath-cycle rate.
- **Breath scheduler.** It alternates inhale and exhale phases. Each phase has its own
  piecewise-linear gain envelope (ramp up, plateau, ramp down) that overlaps the phase
  edges, not a smooth sine hump. The end of a silent audio buffer is used as the timer
  that triggers the next phase.
- **Per-breath randomness.** The breath period, each phase's pitch (playback rate), the
  level at each envelope breakpoint, the envelope's time scale and the short pauses
  between phases are all randomized a little on every breath. The inhale share of the
  cycle is held near half with small random variation, which agrees with the measured
  51-54% in finding 1.
- **"Variability" control.** At breath boundaries, with a probability set by the slider,
  it starts a run of a few breaths at a different tempo (drawn from a wide range around
  the base tempo), then returns. So tempo excursions come in clusters, not independently
  per breath.
- **"Symmetry" control.** It attenuates one phase relative to the other: a user-set
  inhale/exhale loudness balance. Other controls: tone (playback-rate scale), a
  low-shelf/high-cut filter, and meow rate (the exhale is strongly attenuated during a
  meow).
- **The two phases are different recordings**, consistent with Schötz & Eklund noting
  that the phases are distinguishable by sound and waveform.

Inference (not measured): its realism likely comes mostly from the recorded click
texture; the engine adds breath structure and randomness. We have the structure and
randomness; the click texture is the gap. Levers it suggests for us, none built:
inhale/exhale timbre contrast (tasks.md T039), clustered tempo excursions (runs of a few
breaths, different from our independent per-breath `breath_jit`), and a user-set
inhale/exhale loudness balance (part of T039). Our own numbers (`breath_jit` 0.15 and so
on) come from the papers in findings 1-4, not from this generator.

Other generators found (not studied; links only): myNoise "Furry Friend" (the earlier
generation, a frequency-shaped noise generator) and the PurrCell instruments in Avid
Pro Tools Sonic Drops (resynthesized recordings, plus one FM-synthesized instrument).

## Sources
- Schötz & Eklund 2011, "A comparative acoustic analysis of purring in four cats": https://lup.lub.lu.se/search/files/3610898/2292764.pdf
- Herbst et al. 2023, "Domestic cat larynges can produce purring frequencies without neural input", Current Biology 33(21): https://phaidra.vetmeduni.ac.at/api/object/o:3419/download (press: https://sciencedaily.com/releases/2023/10/231004105157.htm)
- Herbst, Svec & Fitch, "About the voice production mechanism of cat purring: a critical appraisal of Remmers & Gautier, 1972": https://services.phaidra.univie.ac.at/api/object/o:1681638/download
- Remmers & Gautier 1972, Respiration Physiology 16:351-361 (read only as excerpted at https://whyevolutionistrue.com/2009/02/08/how-cats-purr/)
- Aoki & Ifukube 1996, "Two 1/f fluctuations in sustained phonation...": https://manuscript.isc.ac/inventory/49/309305.htm
- Aoki 2000 thesis, Hokkaido University: https://eprints.lib.hokudai.ac.jp/repo/huscap/all/28112/thesis2000.pdf
- Mattioli et al., "Perturbation Measurements on the Degree of Naturalness of Synthesized Vowels", J Voice 2015: https://observatorio.fm.usp.br/entities/publication/41448492-a962-4b0b-bc71-245c3d3173dd
- Devaraj et al. 2021, amplitude-modulated vocal fry glottal area waveforms: https://mdpi.com/2076-3417/11/5/1990
- Purrli (listened to and, from pasted source, architecture studied): https://purrli.com
- Reed College student site on purring mechanics (low reliability): https://reed.edu/biology/courses/BIO342/2011_syllabus/2011_websites/Purring%20CH&JP/mechanism.html
