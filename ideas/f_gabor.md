# f_gabor — oriented band-pass and quadrature energy (working name)

_Status: ⚪ concept only. Drafted 2026-10-23 from the webgpgpu mining run
(`webgpgpu-ideas-1`). Not specced, not tried in Max._

## Concept

A tunable orientation-and-scale channel for live video: convolve the frame with a Gabor
kernel (Gaussian-windowed sinusoid) and show the result. The `vision/` pages build it up
in stages, and each stage is a mode:

1. **Signed response** (`Vision_001`, `Vision_002`): a tap loop accumulates
   `kernel * input`; output is a signed band-pass image, an edge or ridge detector that
   sweeps continuously in orientation and frequency.
2. **Amplitude-normalised** (`Vision_002_v2`): divide by the square root of the summed
   squared kernel weights, so output no longer scales with input contrast.
3. **Quadrature energy** (`Vision_003`): accumulate a cosine-phase and a sine-phase
   response together and output `sqrt(sumCos^2 + sumSin^2)`: phase-invariant, ridges
   light up wherever they fall in the stripe cycle (the "complex cell").
4. **Tile bank** (`Vision_002`): one pass tiles the image so each block shows the filter at
   an orientation and phase derived from its block index: a live mosaic of every
   orientation at once, and a tuner for the settings to run.
5. **Log-scale sweep** (`Vision_003`): block row sets an octave-spaced frequency
   (`exp2(row/(N-1) - 1)`), so the mosaic is an octave pyramid.

## What f_ has today

`f_tf_tensormap` (structure tensor: where edges are and their orientation),
`f_tf_aniso_blur` (oriented smoothing), `f_tf_glyph` (per-cell ellipses). No oriented
band-pass, no phase-invariant band-limited energy, no filter bank over an image.

## Proposed shape

- Signature: texture -> texture (signed response or energy). Tile mode is a display
  option on the same module.
- Dials: orientation, frequency, sigma (kernel size), output (signed / normalised /
  quadrature energy); tile mode: grid size, orientation range, scale range.
- Tap loop is the cost. Use the disc-limited 13x13 loop from `Vision_002/003` (about
  169 taps), not the full 24x24 square of `Vision_001` (576 taps, and that file's name
  ends in `brken`, so treat it as a broken test).
- The tile modes need a downsample prefilter (the examples use a 128x128 buffer);
  without it the tiles alias on noisy video and the display misrepresents selectivity.
- GenExpr has `exp` but no `exp2`.
- Speculative (my addition): a bank of Gabor energies at several orientations is also a
  way to build an orientation field with scale selectivity, which would connect this to the
  tensor family. Not in the source; flag only.

## Tier-1 checks

- Grating test: response peaks with the right amplitude and phase; kernel weights sum to the
  accumulated normaliser.
- Normalised response is unchanged when the input is scaled by k.
- Quadrature energy is constant while a test grating's phase slides.
- Tile at scale s responds maximally to a grating of frequency s (peak tracking across
  octaves).

## Risks and open questions

- Per-pixel tap cost at render resolution; may need a small internal buffer or fewer taps.
- Quadrature mode doubles per-tap arithmetic and accumulators.
- Dividing by a near-zero normaliser on flat input amplifies noise; needs a floor
  (and `sqrt` of a negative must be guarded).
- At coarse scales the tap radius must grow with scale or the tiles silently stop
  filtering.
- The drafts' risk line for quadrature mode says "576 taps"; the verifier noted this
  conflicts with the 13x13 disc loop (about 169). Use the smaller figure.

## Related

`f_tf_tensormap`, `f_tf_aniso_blur`, `f_tf_glyph`, `f_tensorfield.md`.

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 56, 25, 26, 27, 28. Verified by subagents
against the vision files and the f_ inventory; the tap-count correction comes from a
verifier reply.
