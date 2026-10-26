# f_wc — render-resolution Wilson-Cowan labyrinth (formerly f_formconstants; replaces f_wc_fft)

_Built 2026-10-24/25 (`.specify/f_wc/`). On 2026-10-25 it was renamed from `f_formconstants` to `f_wc` and REPLACED the FFT-chain `f_wc_fft` (archived at `.specify/superseded/f_wc_fft/`); the history below describes it as a sibling and is kept as written. Specced 2026-10-24. Origin: the f_wc_fft pixelation
discussion the same day — reading the actual `WC_Example_10_fullscreen.html`
source (michaelerule/webgpgpu) showed its fine, silky look is STRUCTURAL, not an
AA technique: solver grid = display grid, separable-Gaussian-blur coupling
(σ_E = 1 px, σ_I = 2 px — no FFT), continuous non-thresholded display. f_wc_fft's
256² FFT architecture decoupled solver res from render res and then magnifies a
near-binary coarse field ~7.5×, which is why its contours stair-step no matter
how good the reconstruction filter is. Matt: "their look is the actual target —
fine and silky; color isn't essential." Decided: NEW SIBLING MODULE (f_wc_fft and
its tuned labyrinth/spots corners ship unchanged), Example-10 coupling constants
as defaults, `formconstants` name picked over `f_v1` / `f_wc_hd`._

## Concept

The Ermentrout-Cowan / Rule noise-and-blur Wilson-Cowan model run AT RENDER
RESOLUTION, following the webgpgpu Example-10 pipeline:

```
hold ← state (R = E, G = I; B/A spare: habituation Ve/Vi)
blur_x → blur_y    separable Gaussian, per-channel σ (R at σ_E, G at σ_I),
                   weights computed inline from the σ Params
nl                 logistic relax + optional per-frame hash noise + drive inlet
hold               feedback close
enc                f_wc_fft's retinotopic bare-log map stage, adapted (r_soft
                   foveal softening retained — better than the source's aliased
                   center vortex)
```

- **Example-10 constants**: Aee 10.5, Aie 8.5, Aei 12, Aii 3, He 2.0, Hi 3.5,
  Te 10, Ti 20, dt = 1. Its `s` term is a slow square-wave excitability bias —
  parked (the performer's `excite` dial covers it; Phase 0 measures whether the
  deterministic post-seed dynamics sustains or whether a small per-frame `Ne`
  is load-bearing at float32 — theirs runs 8-bit, where quantization decorrelates).
- **Pattern scale in visual units, not pixels** (fixes the source's
  resize-couples-physics defect): the `grain` dial sets pattern wavelength as a
  fraction of frame height; σ_px derives from `min(dim)`.
- **float32 state end to end** — their `EncodeFloat` 8-bit quantization is a
  liability for a model on a saturation boundary; we keep f_wc_fft's precision.

## Relationship to the library

- `f_wc_fft` stays: coarse grid, FFT chain, its mapped spots/labyrinth regimes
  (aii 3–6 corner) are distinct content. This module is the same model class at
  ~50× cortical resolution with the fine-grained regime f_wc_fft cannot reach
  (σ_I = 2 px at 256² is below the grid's pattern scale).
- Shares with `f_wc_fft`: nl math shape, drive-inlet semantics (G3), the enc map
  stage math, mirror/bench infrastructure patterns.
- Color deliberately out of scope — the library's colormap/tone modules do that
  downstream (their `vec4(Ue, Ui, |Ue−Ui|·3)` display is a debug view, not a look).

## Evidence so far

- `WC_Example_10_fullscreen.html` + `lib/gpgpu.js` + `lib/gpugaussian.js` read
  2026-10-24 (framebuffer = canvas client size, LINEAR/REPEAT, UNSIGNED_BYTE,
  `GPUGaussianMultiBlur(gl,1,2,1,1)` two-pass separable, radius ceil(3σ)).
- f_wc_fft 2026-10-23: the same model class reproduced in NumPy at 512² (std
  95/255, clean labyrinth) against the live page readback; per-frame noise is
  load-bearing for the PSYCHEDELIC constants (Example 10's own page injects
  none — Phase 0 measures this for Example-10 constants at float32).
- f_wc_fft pixelation arc (HANDOFF 2026-10-24): C0-bilinear facets → fixed (CR);
  contour-position quantization at 256² → the failed SSAA attempts; the failed
  offsets were quarter-SCREEN-pixels against a ~7-screen-px/texel artifact —
  structurally unable to help.
