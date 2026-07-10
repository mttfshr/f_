# f_raster — Resolution as Parameter

## Concept

A processor that treats resolution as an expressive variable rather than a fixed technical constraint. Downsample an input texture to a target resolution, then upsample back — with independent control over the downsample ratio and the upsample interpolation mode. The result is deliberate pixelation, resolution mismatch, and chunky-vs-crisp compositing as aesthetic tools.

Aesthetic reference: risograph printing, screen printing, xerox degradation, DIY/punk printmaking. The look of independently-resolved layers composited together — one element chunky and pixelated, another crisp — is a specific visual language distinct from anything in the Vsynth library.

---

## Core Operation

```
input texture
  → downsample to (dim * scale) where scale ∈ (0, 1]
  → upsample back to output dim
  → output
```

The upsample interpolation mode is a key expressive parameter:
- **Nearest-neighbor** — hard pixel blocks, the classic lo-fi/pixelated look
- **Bilinear** — smooth blobs, painterly degradation

These are fundamentally different aesthetics from the same downsample ratio.

---

## Parameters (sketch)

- **scale** — downsample ratio (e.g. 0.125 = 1/8 resolution). Controls how chunky the output is.
- **interp** — upsample interpolation: 0=nearest-neighbor, 1=bilinear
- **bypass**

Possibly:
- **x_scale / y_scale** — independent horizontal and vertical resolution (anisotropic pixelation — horizontal scan lines vs vertical columns vs square blocks)

---

## Use Cases

### 1. Pipeline utility: procedural generators into UV transformers
Hard-edge procedural generators (masonry, stipple, chladni) alias badly when used as raster sources into UV-transforming processors (droste, mobius). Running them through f_raster at high scale (e.g. 2x or 4x internal resolution) produces a pre-filtered, bandlimited texture that UV transformers can sample cleanly.

```
masonry → f_raster (scale > 1.0, bilinear) → droste   ← clean
masonry → droste                                        ← aliased
```

Note: scale > 1.0 (supersampling) requires rendering at higher internal resolution — see implementation notes.

### 2. Expressive pixelation
Deliberate lo-fi degradation as an aesthetic. Scale down aggressively, upsample nearest-neighbor. Produces the chunky pixel block look of early digital video, game captures, xerox art.

```
any texture → f_raster (scale 0.1, nearest) → output
```

### 3. Mismatched resolution compositing
Run two textures through f_raster at different settings, composite downstream. One crisp, one chunky. The resolution mismatch itself becomes the texture — layers that feel like they came from different media or processes.

```
texture A → f_raster (scale 0.125, nearest) ─┐
                                               ├→ composite
texture B → f_raster (scale 1.0, bilinear)  ─┘
```

### 4. Anisotropic resolution
Independent x/y scale creates scan-line or column aesthetics — horizontal blur/chunking with vertical crispness or vice versa. Mimics interlacing, horizontal scan lines, vertical slat patterns.

---

## Implementation Notes

### Downsampling
In Max/Vsynth: render input into a `jit.gl.texture @dim W H` where W/H = input_dim * scale, then pass that texture downstream. The GL context handles bilinear filtering on the way down automatically.

### Upsampling
- Nearest-neighbor: `jit.gl.texture @interp 0` (nearest) on the low-res texture fed into a fullscreen quad
- Bilinear: `jit.gl.texture @interp 1` (default)

### Supersampling (scale > 1.0)
Render into a higher-res texture, output at standard resolution with bilinear downsample. Produces a bandlimited version of the input — useful for the droste pipeline case. One-frame latency from `jit.gl.asyncread` is acceptable in performance context.

### Resolution controllability
Ideally the scale parameter is continuous and performable. Snapping to integer ratios (1/2, 1/4, 1/8) avoids non-integer scaling artifacts but reduces expressivity. Continuous scaling with bilinear filtering is smooth; with nearest-neighbor it produces crawling artifacts at non-integer scales which may themselves be interesting.

---

## Open Questions

- Is this a single object with a mode toggle (subsample/supersample), or two separate utilities?
- Does anisotropic x/y scale earn its UI complexity?
- Should it expose the low-res texture as a second outlet (useful for downstream compositing without a second f_raster instance)?
- Relationship to `jit.gl.pix @adapt` — does adapt mode already do some of this?

---

## Status

**Shelved (2026-07-09) — waiting for a real reason to be built.**

Scratch-tested a downsample/upsample chain (`f_raster-scratch.maxpat`) against a
camera source to check the core mechanism (forced-low-res render via
`jit.gl.pix @adapt 0 @dim`, nearest/linear upsample via `filter`). The forced
low-res dim worked immediately and visibly. The live nearest/linear filter
switch did not, through three different wiring attempts (wrapper texture
object, filter on the consuming stage, filter on the producing stage as a
bare attribute message) — each fix was evidence-based, not a blind guess, but
none worked.

Reading Kevin's actual `vs_pixelator.maxpat` (Vsynth package) resolved the
mechanism: `filter` must be dispatched via `sendinput`/`sendoutput` (documented
`jit.gl.pix`/`jit.gl.slab` methods that forward a message to the object's
*internal* texture objects), not sent as a bare attribute message to the
box's own inlet. Applying that fix to the scratch patch still showed no
visible difference — unresolved, not re-diagnosed further, because a bigger
problem surfaced first (see below).

**The real finding: this module's core pitch is already shipped.**
`vs_pixelator.maxpat` (and `_2`/`_nonSquare` variants) already does forced
low-res dim + live nearest/linear interpolation toggle + bypass, natively in
Vsynth, battle-tested. Comparing against the use cases in this file:

- Expressive lo-fi pixelation (nearest/linear, scale down) — **already covered
  by `vs_pixelator`**, no gap
- Mismatched-resolution compositing (two instances, different settings) —
  trivially covered by two `vs_pixelator`s
- Anisotropic x/y scale — not covered (pixelator forces square blocks via
  `dim $1 $1`), but also not resolved as worth building here
- Supersampling as an anti-aliasing prefilter (scale > 1.0, feeding hard-edge
  generators into droste/mobius) — **not covered**, pixelator only goes down
- Second outlet exposing the low-res texture — not covered

**Decision: do not proceed with `f_raster` as originally scoped.** The
downsample/pixelation half of this concept duplicates `vs_pixelator`. If this
idea gets picked up again, the only remaining real justification is the
supersampling/pre-filter use case (masonry/stipple/chladni aliasing through
droste/mobius) or anisotropic x/y as a genuinely new aesthetic — not
pixelation, which already exists. Don't resume this by rebuilding the
nearest/linear pixelation mechanism; that question is answered and shelved.

Scratch file left at `~/Vsynth/patterns/f_raster-scratch.maxpat` (untracked,
per convention) if the filter-routing dead end is ever worth re-examining.

---

Concept only. Not specced, not planned. Emerged from f_masonry e2e testing (2026-06-05) — masonry aliasing through droste revealed the gap. The expressive use cases (risograph compositing, anisotropic resolution) may be more interesting than the original pipeline utility framing.
