# Entrainment — Research Territory & Design Brief

Mapping the space of light/frequency-based altered state induction: historical lineages, mechanisms, measured neural correlates, and design implications for f_ patchers and presentation contexts.

---

## Why this territory

Two converging interests: (1) building visual synthesis tools that operate on the viewer's perceptual and neural state, not just their aesthetic experience; (2) having an EEG (Muse Athena) to actually measure what's happening. The ganzflicker test patch is the entry point, but the broader question is what kinds of experiences are worth building, for what ends, and what the measurable correlates are.

The EEG angle matters because it forces honesty — it becomes possible to distinguish between effects that are claimed and effects that are measurable. Most of this territory has more claims than evidence.

---

## Lineages

### Perceptual deprivation — Ganzfeld

**Origin:** Wolfgang Metzger, 1930s. Uniform visual field (ganzfeld = "whole field") causes the visual system to lose its reference signal and begin generating internally. Original research was perceptual psychology, not altered states.

**Later use:** Parapsychology researchers (Charles Honorton, 1970s–90s) adopted ganzfeld as a noise-reduction protocol for ESP experiments. The parapsychology framing is not the point — the perceptual effect itself is solid and independent of it.

**Mechanism:** Sensory homogenization. The visual system is a difference engine — it responds to edges, motion, contrast. Remove all of those and it starts hallucinating. Eigengrau, phosphenes, geometric patterns, and eventually more complex imagery emerge during extended exposure.

**Flicker variant (ganzflicker):** Adding temporal structure (rhythmic luminance oscillation) on top of the uniform field combines deprivation with entrainment. The two mechanisms are separable but interact. Flicker rate determines which brainwave band is being driven; deprivation determines the hallucinatory substrate.

**Measured correlates:** Alpha suppression during photic driving is well-documented. Theta increase during ganzfeld hallucination is less settled — the research is thinner than the phenomenology. SSVEP at stimulus frequency is reliable for any photic driving.

**Design implication:** Needs to fill the visual field to work fully. Screen approximation is degraded — peripheral vision still receives ambient room light, edges are visible, bezel is present. Full effect requires large projection in a dark room with viewer positioned close enough for the field to cover peripheral vision. See presentation section.

---

### Rhythmic entrainment — Photic driving & SSVEP

**Neuroscience basis:** Steady-state visual evoked potentials (SSVEPs) are well-documented — drive the visual cortex at a frequency, measure that frequency in occipital EEG. Used clinically for BCI and neurological diagnostics. This is solid, replicable neuroscience.

**The open question:** Whether entrainment *causes* state change or merely *correlates* with it. Seeing a peak at your stimulus frequency in the EEG confirms entrainment; it does not confirm altered experience. The relationship between the two is not well established.

**Commercial tradition:** Binaural beats and photic driving were heavily commercialized in the 1980s–90s (Hemi-Sync, various "mind machines" combining light glasses with audio). Strong claims, weak evidence. Worth knowing the difference between the neuroscience and the commercial layer built on top of it.

**Frequency bands and their associations:**
- Delta (0–4 Hz) — deep sleep, not typically targeted for waking induction
- Theta (4–8 Hz) — hypnagogia, creative states, edge of sleep; the target for deep trance/dreamlike experience
- Alpha (8–13 Hz) — relaxed wakefulness; visual cortex idles here; resonance effects strongest; Dreamachine range
- Beta (13–30 Hz) — active cognition; driving this tends toward alertness not relaxation
- Gamma (30+ Hz) — not typically targeted for this work; associated with perceptual binding

**Square wave vs sine wave:** Square wave produces hard transients — strongest SSVEP signal, strongest harmonic content (fundamental + odd harmonics). A 8 Hz square wave also drives at 24 Hz, 40 Hz, 56 Hz. Sine wave is spectrally clean — fundamental only. Triangle sits between. For measurement, sine is cleaner; for effect, square is stronger but the harmonic stimulation is an uncontrolled variable.

**Design implication:** For EEG measurement, need temporal precision — know exactly when stimulus is running and at what frequency. Projector refresh rate matters; some projectors introduce timing jitter that appears as noise in stimulus-locked analysis. Screen is actually more reliable for precise timing even though the perceptual field is smaller. For SSVEP detection specifically, want a high-Q narrow bandpass at the exact stimulus frequency, not the broad band-power filters used for general EEG monitoring.

---

### Art & device — Dreamachine

**Origin:** Brion Gysin, Ian Sommerville, William Burroughs, 1959–1962. Rotating slotted cylinder over a bare bulb, viewed with eyes closed. Flicker rate determined by cylinder rotation speed and slot geometry; typically 8–13 Hz.

**Intent:** Explicitly positioned as an art object and inner experience device, not therapy. Gysin's context was the cut-up method and the "third mind" — bypassing conscious editorial control to access something else. Related to but distinct from therapeutic or neuroscientific framing.

**Mechanism:** Closed-eye photic driving. The eyelid is not a complete light block; rhythmic luminance change drives visual cortex through the eyelid. Peripheral vision also engaged because the device was sized to fill the viewer's visual field when seated. This is the key design constraint — the physical object was scaled to its perceptual effect.

**Experience:** Colors, geometric forms, motion, kaleidoscopic imagery — all with eyes closed. Passive and surrendered — the viewer has no control, no interaction. Duration matters; effects typically deepen over several minutes.

**Closed-eye vs open-eye distinction:** This is fundamental. Dreamachine is a closed-eye device. Ganzfeld is an open-eye device. The neural pathway is different, the phenomenology is different, the design requirements are different. A patcher designed for closed-eye use doesn't need to look like anything specific — just luminance. A patcher for open-eye use has spatial content that matters.

**Design implication:** A Dreamachine-equivalent patcher is primarily a luminance oscillator at a controlled Hz with color as a secondary parameter. Its visual appearance doesn't matter much — only its temporal and photometric properties. Projection preferred; screen can approximate if the viewer is close and the room is dark. The viewer's posture and behavior (eyes closed, facing the source, sitting still) are part of the experience design.

---

### Compositional / synesthetic — Color organs

**Lineage:** Thomas Wilfred's Clavilux (1920s), Scriabin's Prometheus light keyboard (1910), later Stan VanDerBeek's Movie-Drome and expanded cinema practitioners.

**Intent:** Synesthesia and visual music — mapping musical or compositional structure to color and light. The goal is aesthetic and performative, not inductive. The operator is an agent; the viewer has a compositional experience.

**Distinction from entrainment:** Color organs are not trying to alter viewer state through neural mechanism. They're creating a visual-musical correspondence. The relationship is semantic/compositional, not frequency-driven. This lineage matters as context but is not the same project.

**Where they overlap:** Both involve sustained exposure to color fields, which produces chromatic adaptation and afterimage effects that can be perceptually interesting. Long exposure to a saturated color field followed by a neutral field produces a strong afterimage in the complementary color — this is a measurable, predictable perceptual effect that color organ practitioners exploited.

---

### Clinical — EMDR, Neurofeedback, Photosensitivity

**EMDR:** Eye Movement Desensitization and Reprocessing uses rhythmic bilateral stimulation (originally eye movement tracking, now also bilateral audio or tapping) for trauma processing. The rhythmic component is important — hypothesis is that bilateral stimulation during recall reduces the emotional valence of traumatic memory. Not entrainment in the frequency sense but rhythmic bilateral visual stimulus. Worth knowing because it's a clinical validation that rhythmic visual stimulus has measurable psychological effect.

**Neurofeedback:** EEG-driven audio or visual feedback used to train specific brainwave states. The feedback loop is the mechanism — the subject learns to modulate their own EEG through real-time signal. This is the clinical version of what a closed-loop EEG + visual system would be doing. Decades of clinical research, mixed but real evidence for efficacy in ADHD, anxiety, some other conditions.

**Photosensitive epilepsy:** Maps the danger zone. Peak sensitivity is 15–25 Hz for most people; some have lower thresholds. Full-field luminance oscillation at 4–10 Hz is below peak risk but non-zero for susceptible individuals. The ITC (International Telecommunication Union) guidelines and Harding test define broadcast safe limits. Working in 4–10 Hz with full-field square wave is the riskiest point in the parameter space that is also interesting for trance induction — these overlap for a reason. Need to be conscious of this, especially when showing to other people.

---

## EEG Measurement Strategy

**Current setup:** Muse Athena receiving via OSC in Max. Existing patch averages 4 channels and extracts band powers via parallel SVF filters. Issues: channel averaging loses spatial information (TP9/TP10 vs AF7/AF8 are different sites); SVF Q=0.5 is too broad for SSVEP detection; scale calibration needs verification.

**What can be measured reliably:**
- SSVEP at stimulus frequency — most reliable, requires narrow high-Q filter at exact Hz
- Alpha band power changes — reasonably reliable at TP9/TP10
- Theta/alpha boundary shifts over extended sessions — possible but noisy

**What is harder:**
- Distinguishing driven theta from spontaneous theta without precise stimulus timestamping
- Occipital signals — Muse electrode positions are frontal and temporal, not occipital; SSVEP signal will be present but attenuated

**Closed-loop possibility:** Use EEG band power to modulate stimulus parameters in real time — rising theta → slow the flicker; dropping alpha → increase saturation. This is neurofeedback architecture. Interesting as both a research tool and a performance instrument.

---

## Presentation Contexts

| Effect | Works on screen | Works on projection | Notes |
|---|---|---|---|
| Ganzflicker (SSVEP) | Partial | Full effect | Needs peripheral field coverage |
| Dreamachine (closed-eye) | Poor | Yes | Viewer posture is part of design |
| Hypnotic spiral | Yes | Stronger | Works at any size but scales with immersion |
| Color saturation field | Yes | More immersive | Afterimage effects scale with field size |
| Slow drift / optical flow | Moderate | Strong | Peripheral vision critical for vection |

**Screen:** Reliable timing (good for EEG correlation), small field of view, ambient light present. Best for measurement and development.

**Projection:** Larger field of view, timing less precise (projector-dependent), dark room removes ambient light. Best for full perceptual effect. Installation context allows control of viewer distance and posture.

**The field-of-view threshold:** True ganzfeld requires the uniform field to cover the entire visual field including periphery. Human visual field is roughly 200° horizontal × 130° vertical. At 2m viewing distance a 3m wide projection covers approximately 80° — not full ganzfeld but substantially more immersive than a screen.

---

## Design Implications — f_ Patchers

These are not the same category as generators (f_grain, f_chladni) or texture processors (f_droste, f_luma_processor). Those are indifferent to duration and viewer state. These are organized around a temporal arc and a perceptual goal.

**Possible category: environment patchers** — designed around sustained exposure, viewer state, and temporal structure. Parameters organized by perceptual effect rather than visual appearance.

**Candidates:**

**f_ganzflicker** — full-field luminance oscillator. Core parameters: Hz (stimulus frequency), waveform (square/sine/triangle), color temperature or hue, duty cycle. Secondary: spatial uniformity control (pure ganzfeld vs slight noise floor). Works on screen for development/measurement; needs projection for full effect.

**f_dreamachine** — closed-eye flicker environment. Similar parameter space to ganzflicker but optimized for closed-eye use — luminance range, color cycling. Possibly includes a "session" structure (ramp up, sustain, ramp down). Needs projection.

**f_spiral** — hypnotic rotating spiral or vortex. Open-eye, focused attention. Parameters: rotation speed, arm geometry, contrast, scale. Works on screen. Most tractable starting point — purely generative, well-understood visual form, measurable alpha suppression during focused visual attention. **Note (2026-06-06): f_droste with `arms=1`, `twist` near zero, and slow `rotation` speed already produces this effect. f_spiral is probably not worth building as a separate patch — droste covers the use case. The entrainment application is achievable by configuring droste appropriately.**

**f_entrain** — meta-layer: EEG feedback into any of the above. Not a visual generator itself but a modulation system. Takes EEG band powers and maps them to parameters in other patchers. The neurofeedback architecture.

**Build order suggestion:** f_ganzflicker first (already partially exists as test patch), then f_spiral (screen-compatible, measurable, self-contained), then f_entrain as the feedback layer once there's something to feed back into.

---

## VR

VR solves the field-of-view problem almost completely — the display covers the entire visual field including periphery, the outside world is occluded, and each eye can be driven independently. The things that make screen and projection approximations of ganzfeld become non-issues.

Specific advantages: binocular control (drive left and right eyes independently, enabling binocular rivalry or phase-offset flicker between eyes); well-controlled refresh rates (90–120Hz typical, good for precise stimulus timing); full peripheral coverage without requiring a large dark room.

Constraints worth noting: VR refresh rate sets a ceiling on stimulus frequencies — clean square wave flicker is only possible at integer divisors of the refresh rate. EEG compatibility is a real physical issue — wearing a Muse headband inside or alongside a VR headset is awkward and likely compromises contact quality on the temporal electrodes. Vestibular conflict (visual motion without body motion) adds another variable that could be interesting or confounding.

**Current status:** PS4VR is not Mac-compatible, so this direction requires new hardware acquisition before it's actionable. Worth revisiting if that changes — the field-of-view and binocular control advantages are significant enough that it's the most complete implementation path for ganzfeld specifically. EEG compatibility would need to be evaluated for any specific headset before committing.

---

## Open Questions

- What waveform shape produces the strongest phenomenological effect vs strongest measurable SSVEP? These may not be the same.
- At what field coverage does ganzflicker become qualitatively different from screen flicker? Is there a threshold?
- Can theta increase during ganzflicker be reliably detected with Muse electrode positions?
- What is the minimum session duration for effects to emerge at different Hz values?
- Closed-loop (EEG → stimulus) vs open-loop (fixed stimulus, EEG observed): which is more interesting as a research tool? As a performance instrument?
- How does color (hue, saturation) interact with entrainment? Most research uses white/grey fields; colored flicker is underexplored.
