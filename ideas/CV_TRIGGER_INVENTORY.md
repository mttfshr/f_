# CV → Trigger Module Inventory
_Session: 2026-05-19 — pre-design research for texture routing matrix_

## Purpose

Catalogue what exists on-system for converting continuous audio signals (CV) into
discrete routing commands. Goal: design the matrix message protocol around what
these modules naturally output, not the other way around.

---

## Output format taxonomy

Before listing modules, it helps to name the output types that appear:

| Type | Description | Example consumers |
|------|-------------|-------------------|
| **bang** | momentary pulse, no value | `counter`, `select`, `gate` |
| **0/1 int** | sustained gate state | `gate`, `==`, `if` |
| **float 0–1** | continuous level | `scale`, `line`, map to index |
| **float dB** | level in decibels | comparison, display |

The matrix protocol needs to handle bang (the most common), and optionally float→int mapping for signal-indexed strategies.

---

## Tier 1: Attack / Onset Detection
_Input: audio signal. Output: bang on transient._

### `upshot_attackdetection` (Upshot package)
**Architecture (read from source):**
- `abs~` → `slide~ 5 4410` (fast attack, slow release ~100ms) → `atodb~`
- Parallel: `slide~ 1000 1` (slow attack, instant release) → `atodb~`
- Differential: subtract slow from fast → volume differential in dB
- `thresh~ 0.5 5.` (Schmitt trigger with separate hi/lo thresholds, tuned by sensitivity)
- `change~` → `>~ 0.` → `edge~` → `onebang 1` + `delay N` (min time between attacks)

**Inlets:** audio~, activate toggle, sensitivity (0–127), threshold-hi (dB), threshold-lo (dB), min-time (ms)  
**Outlet:** bang (attack detected)  
**Key insight:** Uses `thresh~` not just `>~` — built-in hysteresis prevents chatter without extra smoothing.  
**Sensitivity mapping:** `scale 0 127 40 1` → controls the slow-slide window (40ms to 1ms). More sensitive = faster comparison window = fires on subtler transients.  
**Minimum time:** `onebang`/`delay` pair enforces inter-attack interval — effectively a hold-off filter.

### `bonk~` (bonk_64bit-version package)
Classic percussion onset detector by Miller Puckette. Well-tested, widely used.  
**Output:** bang + velocity float, one per detected attack.  
**Controls:** threshold, mask (inter-attack hold-off), learn mode.  
**Character:** Tuned for percussive transients, can false-trigger on sustained tones.

### `fluid.onsetslice~` / `fluid.onsetfeature~` (FluCoMa)
FluCoMa's onset detectors. More configurable algorithm selection.  
**`fluid.onsetslice~`:** Outputs sample-accurate onset positions — best for offline slicing.  
**`fluid.onsetfeature~`:** Real-time onset feature curve (continuous 0–1), not a bang generator. Needs `thresh~`/`edge~` downstream.  
**Algorithms:** energy, HFC, complex, phase, Wphase, MKL, KL, Kullback, Foote, novelty  
**Character:** Slower and heavier than bonk~/upshot, but more algorithm choice. Worth having when bonk~ false-triggers.

### `fluid.ampslice~` / `fluid.ampgate~` (FluCoMa)
Amplitude-based slicer/gate pair.  
**`fluid.ampslice~`:** bang on upward amplitude crossing.  
**`fluid.ampgate~`:** 0/1 gate based on amplitude threshold — sustained, not momentary.  
**Good for:** sustained tones (synths, sustained voice) where transient detectors fail.

### `zsa.flux~` (zsa.descriptors)
Spectral flux — measures frame-to-frame spectral change. Not an onset detector per se, but a continuous descriptor that peaks at onsets.  
**Output:** float (0+). Needs `thresh~`/`edge~` to convert to bang.  
**Character:** Catches timbral onsets (filter sweeps, new note entries) that amplitude-only detectors miss.

---

## Tier 2: Amplitude Following / Level Sensing
_Input: audio signal. Output: continuous float representing level._

### `vs_envelope_follower` (Vsynth)
Native Vsynth module. Has a `function` object for custom attack/release curve mapping.  
**Output:** float in Vsynth timing domain (driven by `r draw`).  
**Character:** Already synced to Vsynth frame rate — no rate mismatch when feeding Vsynth params.  
**Note:** Uses a drawable function curve for the attack/release shape — more expressive than dial-based A/R.

### `vs_audio2video` (Vsynth)
More complete A→V pipeline — includes envelope following, scaling, and output routing in one module.  
**Output:** Vsynth parameter messages (sends to named receives).  
**Character:** Designed for end-to-end "audio drives video param" use case. Less flexible for mid-chain routing.

### `upshot_amplitudefollower` (Upshot)
General amplitude follower. Float output, controllable attack/release.  
**Output:** float 0–1 (presumably), at audio rate or downsampled.  
**Character:** More general-purpose than vs_envelope_follower, not Vsynth-specific.

### `fluid.loudness~` (FluCoMa)
Perceptual loudness (ITU BS.1770 LUFS + true peak).  
**Output:** float (LUFS), per analysis window.  
**Character:** Perceptually weighted — reacts more like human hearing than RMS. Good when the visual response should match perceived dynamics.

### `zsa.energy~` / `zsa.ampstats~` (zsa.descriptors)
Frame-by-frame RMS energy and amplitude statistics.  
**Output:** float.  
**Character:** Raw energy, not perceptually weighted. Fast.

---

## Tier 3: Native Max signal-domain primitives
_These are the building blocks everything else uses. Worth knowing directly._

### `thresh~`
Schmitt trigger. Separate hi and lo thresholds (hysteresis built in). Outputs 0/1 signal.  
**This is the anti-chatter primitive.** All the smarter modules use it internally.

### `edge~`
Bang on 0→nonzero (out0) and nonzero→0 (out1) signal transitions.  
**The standard converter from signal-domain gate to message-domain bang.**

### `change~`
Outputs signal only when value changes. Useful pre-`edge~` to catch any value change, not just threshold crossings.

### `slide~`
Asymmetric low-pass: separate rise/fall time constants. Fundamental for attack/release shaping before thresholding.  
`slide~ fast_rise slow_fall` = envelope follower. `slide~ slow_rise fast_fall` = peak detector. Upshot_attackdetection uses both in parallel.

### `atodb~`
Amplitude to dB conversion. Linearizes perception before differential comparison.

### `onebang N`
Outputs one bang, then blocks until reset after N ms. Enforces minimum inter-event time.  
**The hold-off primitive.** Used in upshot_attackdetection for min-time-between-attacks.

### `>~`, `<~`, `>=~`, `<=~`
Signal comparison operators → 0/1 signal output. Compose with `edge~` for threshold crossing bangs.

---

## Tier 4: Smoothing / De-chattering
_Used to stabilize signals before thresholding._

### `upshot_smooth` (Upshot)
Dedicated smoothing module. Float in, smoothed float out.  
**Character:** Good for stabilizing noisy CV before feeding a threshold gate.

### `vs_filter_lp2x` / `vs_filter_lp4x` (Vsynth)
Vsynth LP filters — but these operate in the video domain (on jitter matrices). **Not useful for audio CV smoothing.**

---

## Tier 5: Probability / Stochastic
_For "cut to what" strategies that involve randomness._

### `upshot_1bitprobability` (Upshot)
50/50 coin flip on each bang received. Outputs bang or nothing.  
**Good for:** Stochastic pool selection — receive a trigger, randomly decide to act on it.

### `upshot_7bitprobability` (Upshot)
Weighted probability with 128-step resolution.  
**Good for:** Biased routing — "70% chance of going to state 1".

### Rhythm and Time Toolkit — `rtt.rprob`, `rtt.rlogic`, `rtt.euclidean`, `rtt.divs`, etc.
RTT is a modular step-sequencer ecosystem built on RNBO. Modules include per-step probability (`rprob`), logical gate operations on two signals (`rlogic`), Euclidean rhythm generation (`euclidean`), clock dividers (`divs`), pattern sequencers, swing, feel, and more.

**Inlets/outlets are trigger-domain, not audio-domain.** The modules consume clock triggers and produce trigger outputs — they don't process audio signals. They live *after* any CV→trigger conversion, not before it.

**Where it's useful for the matrix:** If you want the matrix to switch on a rhythmic pattern rather than reactively on audio events, RTT is the right tool upstream of the matrix inlet. E.g.: `rtt.euclidean` (trigger generator) → matrix → routing state changes on a Euclidean beat grid. This is the "cycle/clock" strategy from the handoff.

**Not useful for:** converting continuous audio CV to routing commands.

---

## Tier 6: More exotic descriptors (available but likely overkill)
_Available if nuanced audio features drive routing decisions._

### FluCoMa real-time descriptors
- `fluid.pitch~` — pitch + confidence. Route differently when pitched vs. unpitched.
- `fluid.spectralshape~` — 7 descriptors (centroid, spread, skewness, kurtosis, rolloff, flatness, crest). Timbre-based routing.
- `fluid.mfcc~` — 13 MFCCs. Full timbral fingerprint. Probably needs ML layer to be useful.
- `fluid.noveltyfeature~` — novelty curve. Good for structural section change detection over longer time scales.
- `fluid.hpss~` — harmonic/percussive separation. Could drive "percussive hits trigger routing, harmonic content doesn't".

### zsa.descriptors
- `zsa.centroid~`, `zsa.rolloff~`, `zsa.flatness~`, `zsa.spread~` — spectral shape.
- `zsa.fund` — fundamental frequency.
- `zsa.flux~` — (listed above in Tier 1).

---

## Output format summary (for matrix protocol design)

| Module | Output | Notes |
|--------|--------|-------|
| upshot_attackdetection | bang | Has built-in Schmitt + hold-off |
| bonk~ | bang + float (velocity) | Two outlets |
| fluid.onsetslice~ | bang | Sample-accurate |
| fluid.onsetfeature~ | float 0–1 | Needs thresh~+edge~ downstream |
| fluid.ampgate~ | 0/1 int | Sustained, not momentary |
| vs_envelope_follower | float 0–1 | Vsynth frame rate |
| upshot_amplitudefollower | float 0–1 | Audio rate |
| thresh~ | 0/1 signal | Primitive, compose with edge~ |
| edge~ | bang (two outlets: rise, fall) | Standard signal→bang |
| upshot_1bitprobability | bang or nothing | Probabilistic pass-through |

---

## Key design conclusions

**1. Bang is the universal primitive.** All the most useful CV modules (onset detectors, edge detectors, threshold crossings) output bangs. The matrix "go to state N" message protocol should accept bangs as its primary input — the matrix decides what "bang" means (next, toggle, random, etc.) based on its own configuration.

**2. Continuous float needs a translation layer.** Signal-indexed strategies (float → state index) require `scale` + `int` + bounds checking between the CV source and the matrix. This translation is thin enough to live in the connecting patch, not in the matrix itself.

**3. Hysteresis and hold-off are always needed.** Raw amplitude or flux fed directly to a threshold gate will chatter. Every real use of threshold-based gating needs either `thresh~` (not just `>~`) or a minimum inter-event time (`onebang` + `delay`). The matrix doesn't need to solve this — the CV modules handle it — but the matrix documentation should note it.

**4. The most immediately useful setup is:** `upshot_attackdetection` or `bonk~` → bang → matrix inlet. Both exist, both are installed, both have been tested in practice. Start here.

**5. `fluid.ampgate~` is the right choice for sustained tones.** When source material is sustained (pads, strings, held notes), transient detectors are wrong. `fluid.ampgate~` gives a stable 0/1 gate that transitions cleanly. Output needs `edge~` if the matrix wants bangs, or the matrix can accept 0/1 directly.

**6. Probability modules (upshot_1bitprobability, upshot_7bitprobability) slot naturally between a trigger source and the matrix.** They're already bang→bang pass-throughs with configurable probability. Perfect for "stochastic pool" and "controlled surprise" strategies from the handoff.

---

## BEAP (`/Applications/Max.app/.../packages/BEAP`)

BEAP is a complete modular synth ecosystem for Max. Everything operates **at audio signal rate** — CV is always a signal~, not a message. This is the key architectural difference from all the other modules above.

**Relevant CV→trigger modules confirmed present:**

- `bp.Envelope Follower` — audio~ → signal 0–1. Adjustable attack/release.
- `bp.Threshold` — signal → 0/1 gate signal. The BEAP equivalent of `thresh~`.
- `bp.Signal Pulse` — signal level crossing → momentary pulse signal.
- `bp.Trigger to Gate` — converts a momentary pulse into a sustained gate signal.
- `bp.Trigger Gate` — gates a signal using a trigger control.
- `bp.Sample and Hold` — classic S&H at signal rate.
- `bp.Track and Hold` — like S&H but tracks while gate is open.
- `bp.Lag Processor` — slew limiter / signal smoother. The BEAP equivalent of `slide~`.
- `bp.Logic` — AND/OR/NOT/XOR on gate signals.
- `bp.Percent Switch` — probabilistic gate: 0–100% chance of passing a trigger. The BEAP equivalent of `upshot_1bitprobability` but continuously variable.
- `bp.Poisson Process` / `bp.Poisson Pulse` — random trigger generators with Poisson timing distribution. Useful for "stochastic pool" strategy without needing an audio input at all.
- `bp.Rotating Clock Divider` — clock division into multiple rhythmic trigger streams.

**Protocol:** All BEAP CV is audio-rate signal. To reach Max's message domain (bangs/floats), you must bridge out via `edge~` (signal → bang) or `snapshot~` (signal → float at message rate). BEAP does not output bangs natively.

**Bridge to Vizzie:** `vz.beapconvertr` converts BEAP signal CV to Vizzie float messages. Input range selectable: 0/1V, −1/1V, 0/5V, −5/5V.

**Verdict for the matrix:** BEAP adds no capability beyond what `thresh~` + `edge~` + `upshot` already provide — unless you're building a full BEAP patch and want to stay in that ecosystem. Not the natural fit here.

---

## Vizzie (`/Applications/Max.app/.../packages/Vizzie`)

Vizzie is a visual/AV performance toolkit. Its data protocol uses **float messages (0–1) clocked by `r vzdraw`** — analogous to Vsynth's `r draw`. Not audio-rate, not generic Max scheduler messages — its own clocked float world.

**Relevant modules confirmed present:**

- `vz.followr` — audio → 3-band envelope follower → Vizzie floats. Splits into low/mid/high bands, each produces independent 0–1 float output clocked by vzdraw. Most complete audio→data module on the system.
- `vz.audio2vizzie` — general audio → Vizzie data converter.
- `vz.analyzr` — audio analysis → Vizzie data.
- `vz.beapconvertr` — BEAP signal CV → Vizzie float (range selectable). Interop bridge between BEAP and Vizzie worlds.
- `vz.4dataroutr` — 4-in, 4-out Vizzie data router. Uses `change` internally. **Closest existing thing to the texture router we're building** — but operates on Vizzie float messages, not jit_gl_texture messages.
- `vz.dataswitchr` — Vizzie data switch.
- `vz.randomizr` — randomize Vizzie data values.
- `vz.2routr`, `vz.2switchr` — 2-channel routing and switching.

**Protocol:** Vizzie floats are 0–1, driven by vzdraw clock. To get a bang from a Vizzie float, you'd need `change` + threshold comparison downstream. `vz.vizzieconvertr` bridges out.

**Verdict for the matrix:** `vz.followr` is the most polished audio→data module on the system — 3 band followers in one UI, worth using if you want the CV layer to feel integrated. The `vz.4dataroutr` is architecturally similar to what we're building but in the wrong domain. Worth reading its source as a design reference.

---

## Protocol worlds summary

Four distinct signal worlds exist on this system. The texture router lives in world 4; CV sources live in worlds 1–3 and require bridging:

| World | Format | Clock | Bridge to bang |
|-------|--------|-------|----------------|
| 1. BEAP | audio~ signal (0–1 or ±1) | audio rate | `edge~` |
| 2. Vizzie | float message (0–1) | `r vzdraw` | `change` + threshold |
| 3. Max message | bang / int / float | scheduler | already there |
| 4. Vsynth/matrix | jit_gl_texture message | `r draw` / GL | — |

**The texture router lives in world 4. All CV sources must arrive as world 3 bangs or ints before entering the matrix.**

---

## What's confirmed NOT present

- No dedicated Schmitt trigger module at the Max-object level — `thresh~` is the built-in, nothing else needed.
- No ready-made "CV to routing preset" module — this is what we're building.
