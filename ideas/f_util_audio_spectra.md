# f_util_audio_spectra

_Extracted from scratchpad 2026-06-06_
_Status: Idea — not yet specced_

## Concept

Audio spectral character extractor — takes audio in and outputs several derived control signals simultaneously, each capturing a different perceptual quality of the spectral moment. Wraps the filtercoeff~/cascade~ → per-band avg~ → derived signal math pipeline behind a clean interface with meaningful output names. Parallel to f_util_profile: infrastructure that doesn't produce visual output but feeds control signals into visual parameters.

## The gap it fills

Amplitude following and sigmund~ give you energy envelope and pitch/onset. What's missing is spectral *character* — qualities that change slowly and meaningfully with the mood and texture of a complex mix, stable enough to drive visual parameters without jitter. Designed for post-mix, complex soundscape input (laptop mic) rather than isolated instrument channels.

## Band split approach

4 bands via filtercoeff~/cascade~, fixed crossovers at musically meaningful points (200Hz, 2kHz, 8kHz). Fixed rather than user-configurable so that output semantics are stable and nameable — bass energy, presence energy, air energy always mean the same thing.

## Outlets and semantics

- **energy** (float) — overall amplitude, all bands summed. Brightness, contrast, effect intensity.
- **tilt** (float) — high/low band ratio. Is energy concentrated in bass or treble right now? Color temperature, spatial frequency, harshness parameters. Simple division of top and bottom band amplitudes.
- **flatness** (float) — band variance. Are all bands active equally or is energy concentrated in one region? Proxy for tonal vs noise-like character without FFT. Order/chaos axis, stipple coarseness, grain density.
- **flux** (float) — summed band differential. How much is the spectral content changing frame to frame? Instability/transient indicator more stable than sigmund~ onset detection on a full mix.
- **bang** — fires on significant flux threshold crossing. The "event" output — a discrete trigger derived from spectral instability rather than naive amplitude threshold. Less representational than onset detection.

## Params

`smoothing` — attack/release time for amplitude followers. Single param controlling all bands for simplicity; can revisit if bands want independent smoothing.

## Naming rationale

`f_util_` = infrastructure, not image operator. `audio_` = explicitly crosses the audio/video boundary (no other f_ patch does this; worth flagging but not a problem). `spectra` = multiple derived spectral qualities, not a raw spectrum display.

## Relationship to f_util_profile

Both are analysis utilities that output control signals rather than textures. f_util_profile is GPU→CPU (texture → luminance vector). f_util_audio_spectra is audio→control (audio signal → scalar floats). Natural companions for driving visual parameters from different signal sources.

## Open questions

- Should tilt be a ratio (top/bottom band) or a difference, or normalized somehow? Ratio has the problem of blowing up when bass is near zero.
- Is 4 bands enough or does presence want to be split further (upper-mid vs lower-mid)?
- Does flux want its own smoothing param, or should it be faster than energy/tilt/flatness by default?
- Bang threshold — fixed or user-configurable?
