# f_mosh — datamosh look without a codec (working name)

_Captured 2026-11-14 in chat with Matt. Concept only: nothing built, nothing tried in Max.
The look is the 2009 Motionographer post on Ray Tintori's Chairlift "Evident Utensil" and
Nabil's Kanye West "Welcome to Heartbreak" (Takeshi Murata named as the influence). The
technique account below is from that post, read this session; everything about how `f_`
would do it is inferred._
_Status: ⚪ Idea. Not a gate._

## The look

A compression mistake that keeps the *motion* of one shot and the *pixels* of another. At a
cut, the new shot's movement drags the old shot's image around: faces melt into the next
scene, a band member "breaks through the frame" and tears the pixels along. Hold the same
motion and it blooms: pixels keep sliding the same way, smearing into color explosions.
Blocky, not fluid: it moves in square chunks, with seams and stair steps.

## How the videos did it (per the post)

- Re-encode to an AVI codec at a high data rate, so each cut becomes a key frame (I-frame).
- Delete the key frames in a separate tool. The delta frames (P-frames) that follow now apply
  their changes to the previous shot's content.
- Plan cuts on beats with spare frames, because the result is hard to predict. Six-hour
  renders, 45-50 versions, cleanup in After Effects.

The two moves that matter: **drop a key frame** (the cut smear) and **repeat a delta frame**
(the bloom; the post doesn't name this one, it is the other standard datamosh trick).

## The f_ version: a fake codec on the GPU

No codec, no file. Keep one held image (the "reference") and push it around with motion from
the live input, every frame:

1. **Motion vectors.** One vector per block (8, 16 or 32 px), estimated from the live input's
   previous and current frame. Constant inside a block: that is where the blockiness comes from.
2. **Predict.** `held = held sampled at (uv - block_vector)`, nearest sample, no blur, no decay.
   Errors accumulate, as in a real codec with no refresh.
3. **Residual (optional).** Add `residual * (current - previous)` of the live input. At 0 it is
   pure smear; higher, ghost color and edges of the real shot bleed through, as real P-frames do.
4. **Refresh (the key frame).** `key` trigger copies the live frame into `held`. Not triggering
   at a cut is the mosh.

Controls that follow from that:

| Control | What it does |
|---|---|
| `key` (trigger) | re-key: copy live into held. Patch to a beat or a cut detector |
| `auto key` / `drop` | re-key automatically when the frame difference spikes (a cut), with a `drop` chance that skips it: the codec's I-frame, deleted on purpose |
| `hold` (toggle) | freeze the motion vectors: repeat the last P-frame, the bloom |
| `gain` | scales the vectors; >1 accelerates the bloom |
| `block` | block size menu (8 / 16 / 32) |
| `residual` | 0-1, see step 3 |
| `intra` | per-block chance of a refresh where the prediction error is large: real codecs fall back to an intra block there, giving the patchy half-clean look |
| `chroma` (maybe) | move color at half block resolution from luma: the codec color fringe |
| `mix_pct` | per the dry/wet convention |

Inputs: tex (live, the motion source) and an optional second tex as the image to be moshed,
so shot B's motion can drag shot A's pixels without a cut at all. That second inlet is the
part a real codec cannot do and the most performable.

## Overlap with what f_ has (read from `module-inventory.md`, not opened)

- `f_vf_lk` gives a per-pixel Lucas-Kanade field. Quantized to blocks, it might
  supply step 1. Unchecked: whether a 5×5 single-scale LK sees motion large enough for a cut
  (its own note flags fast motion as its limit), and whether block matching (SAD search over
  ±N px) is cheaper and more codec-like. Block matching is likely to look more "wrong" in the
  right way: it picks bad matches, codecs do too.
- `f_vf_advect` is frame-to-frame advection with feedback. A first sketch might be
  `f_vf_lk → block quantize → f_vf_advect` with decay at 1 and no injection after
  the key. Differences: advect is smooth and semi-Lagrangian, mosh wants nearest-sample block
  translation; advect has no key or residual. Try the chain before writing a module.
- `ideas/f_adapt.md` (concept): its frame-difference memory is the cut detector for `auto key`.
- `f_texrouter` freezes on bypass, so it can't be the held-frame store.

## Open questions

- Chain of existing modules first, or its own module? (Lean: try the chain as a scratch
  patch; build only if the block and key behavior can't be had.)
- Block matching vs quantized LK: which looks right? Cost of a ±16 px search at 1080p is
  unmeasured.
- Held buffer as ping-pong feedback: same pattern as the other **temporal** modules; bypass
  should pass through and keep the held image, or reset it?
- Does `hold` with large `gain` blow up to noise too fast to be useful, and does it need a clamp?
- Audio tie-in: `key` and `hold` from onsets, which is what the videos did by hand.
