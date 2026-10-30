# f_tf_hatch

**Type:** Processor (f_tensor consumer, renderer)
**Status:** v2 built 2026-10-29; tier 1 (NumPy mirror, 20/20) and tier 2 (GPU bench vs the
mirror, 12/12, 2026-10-30) green; tier 3 live looks passed (the blob strokes, the stroke-texture
inlet, Coh Floor). The dial defaults are still provisional.
(v1, a lattice of oriented marks, was replaced on 2026-10-28: it drew origin-anchored concentric
rings in every source. v1 is archived as `.specify/f_tf_hatch/spec_v1.md`, `plan_v1.md`,
`tasks_v1.md`, and in git at `a24b8cd`.)

---

## What it does

A per-pixel **streamline renderer** (line integral convolution) built to make a tensor field's
**coherence and topology visible**. For every pixel it walks a bounded number of steps in both
directions along the local structure axis decoded from an incoming structure tensor, adding up a
sparse noise value at each step. The result:

- **Coherent, smooth structure -> strokes.** Neighboring pixels on one streamline share most of
  their samples, so each impulse is smeared into a stroke along the contour.
- **Incoherent structure -> grain.** The march random-walks, neighbors share nothing, and an
  impulse stays a small smudge.
- **Degenerate points** (where the direction vanishes inside a coherent region) -> knots, wedges
  and swirls where the strokes converge. That is the topology, and it comes from the field, not
  from mark design.

The noise is **sparse**: only a small fraction of the frame is lit, so the output is separate
strokes with gaps, not a contour-streaked texture. The impulses are round blobs by default, or the
marks can come from a texture (see Inlets): then the module streaks that texture along the
contours.

Coherence enters in exactly two places. It sets **how faithfully each step follows the axis**
(persistence: a step goes along the axis weighted by `coherence^0.5` and in a random direction
otherwise), and, only when **Coh Floor** is raised, it ends strokes and blacks out regions where
direction is lost. There is no coherence-to-stroke-shape mapping (v1's `commit`/aspect is gone).

The decode is per-consumer (no `f_tf_decode` module): the canonical idiom from
`.specify/f_tf_glyph/plan.md` ADR-2, without dividing the tensormap's gain back out (axis and
coherence are ratios; see Notes). Stateless: no feedback pass. Flicker mitigation lives upstream
(see Upstream contract). Output is luma on black; color is downstream's job.

Requires a tensor input (processor archetype, `driving_inlet`); no self-generating mode.

---

## Signal Chain

```
in0 (tensor)  -> stage E1  decode + presence            -> aux (ca, sa, coherence, presence)
in1 (texture, optional) ---------+
                                 v
                 stage E2  streamline march (16 steps per direction, one pass) -> (raw, presence)
                 stage E3  style + encode (the only stage that clamps)          -> outlets 0 and 1
E1/E2 intermediates stay unbounded float32 and are never outlets.
```

- **Stage E1** samples tensormap **outlet 0** (the raw tensor, lossless; the packed outlet 1 is
  angle-doubled and clamped, the wrong feed for a geometry consumer). It decodes the axis and
  coherence = (l1-l2)/(l1+l2) in closed form, applies `angle_offset`, and computes presence
  (below). Below the zero-tensor guard (`eps_trace`, 1e-4 on the encoded trace) the axis is unset
  and presence is 0: no strokes, never an arbitrary angle. The aux stores the axis as unsigned
  `(cos, sin)` and is read with `nearest` only.
- **Stage E2** is the march. Per pixel and per direction: up to 16 steps of length
  `half-length / 16`; the direction at each step is `normalize(w*axis + (1-w)*random)` with
  `w = coherence^0.5` read at the current position, the axis sign-flipped to stay continuous with
  the previous step; a path that leaves the frame stops contributing. The impulse is added at the
  pixel itself and at every step. Blob impulses are described under Density and Grain below;
  with a texture connected they are the texture's luma (Inlets).
- **Stage E3** scales by Contrast, applies the Line style, multiplies by presence, and encodes
  both outlets. Bypass lives here (`bypass_mode "param"`: black on both outlets; E1/E2 keep
  running).

---

## Inlets

| Inlet | Content | Notes |
|---|---|---|
| 0 | Tensor (`f_tf_tensormap` outlet 0 encoding, `f_tensor_type.md`) | Required. Packed (outlet 1) feeds are a wiring error: strokes at a doubled angle |
| 1 | **Stroke texture** (optional) | The marks Hatch streaks along the contours. Unconnected (`vs_inState`) = the built-in blobs; the output is exactly the plain look |

**With a stroke texture** the impulse at each step is the texture's Rec.709 luma, soft-thresholded,
sampled by `nearest` at the frame-normalized march position:

- **Grain = zoom.** The texture is tiled `2^((1-Grain)*6)` times across the frame in each axis:
  Grain 1 shows it once (the identity map), Grain 0 tiles it 64 times (features 64x smaller). As
  with the blobs, a bigger Grain makes bigger marks.
- **Density = a soft threshold on the luma:** `smoothstep(thr-0.1, thr+0.1, luma)` with
  `thr = 1.1 - 1.2*Density`. Density 0 lights nothing, Density 1 lights every texel, 0.5 sits
  mid-ramp.
- **Brightness** is the mean impulse along the path (classic LIC), not blob coverage crossed, so
  Contrast needs retuning when you switch modes.
- An animated texture animates the strokes. Any Vsynth noise or pattern source works.

**The stroke texture is pre-filtered** (2026-10-30): before E2 it is box-filtered down to 1/4 of the
render size on each axis (two stages, `pre_h` and `pre_v`; 480x270 at 1080p, 270x270 at 1:1, so the
aspect follows the render). The streaking averages fine detail away anyway, and E2's cost with a
texture is its memory footprint times the tiling stride, so this cuts E2 from about 12 ms to 5. Smooth
textures look the same (luma contrast x0.87-0.98); per-pixel noise loses contrast (x0.25), so
Density's useful range is narrower for it. See Cost.

---

## Parameters

All defaults are **provisional**.

| Param | Label | Range | Default | Description |
|---|---|---|---|---|
| `reach` | Length | 0-1 | 0.5 | Stroke length: the march's half-length, 0 to a quarter of the frame height on each side. Strokes reach it only where coherence is high; 0 draws nothing. With very fine Grain at full Length the march can skip noise cells and strokes get gaps |
| `grain` | Grain | 0-1 | 0.5 | Feature scale of the noise the strokes are drawn from, log-mapped: low = fine, thin strokes; high = coarse, thick strokes, fewer of them. Blobs: the noise lattice has `2^((1-Grain)*6+3)` cells (8 to 512) per frame height. Texture: the zoom above |
| `density` | Density | 0-1 | 0.7 | How many strokes. Blobs: how much of the frame the blobs cover, `0.25% * 2^(5*Density)` (0.25% at 0 to 8% at 1). Texture: the soft threshold above |
| `contrast` | Contrast | 0-1 | 0.5 | Stroke brightness gain, 0.6x at 0 to 2x at 1 |
| `line_hard` | Line | 0-1 | 0 | Stroke style: 0 = soft, 1 = hard engraved lines (thresholded with a soft edge). Outlet 1 stays soft |
| `structure_floor` | Floor | 0-1 | 0.1 | Draw nothing where there is too little structure **strength**. Reads the tensormap's trace scale (trace x its Strength; strong structure is ~1), squared for finer control at the low end; 0 = strokes wherever any structure exists. Not Strength-invariant: calibrate with the feeding tensormap's Strength. Gates brightness only, never the geometry |
| `angle_offset` | Offset | -1 to 1 | 0 | Rotates the strokes relative to the structure axis: +-1 = +-90 degrees (the axis is an unoriented line, so +-90 spans the distinct layouts). 0 keeps strokes along structure |
| `coh_floor` | Coh Floor | 0-1 | 0 | Where the tensor loses its **direction** (low coherence) the output goes black and strokes end, instead of smearing into clouds: below this coherence a path stops contributing, and the pixel fades to black by its own coherence (both ramped over the 0.2 below the dial). 0 = off, exactly: the plain look, bit for bit |
| `bypass` | (toggle) | 0/1 | 0 | Black on both outlets |

Internal (no control): `src_stroke` (1 when the stroke-texture inlet is connected), `width` /
`height` (the render size, below) and `ow` / `oh` (the stroke-texture pre-stage's output size,
floor(render / 4), at least 1; the same render-size plumbing sizes the two pre-stages).

**Floor vs Coh Floor.** Floor asks "is there enough structure here?" (trace); Coh Floor asks "does
the structure have a direction?" (coherence). Measured on a synthetic noisy scene, the trace gate
separates flat sensor noise from real structure better than the coherence gate (keeping 5% of a
noisy wall kept 82% of the structure with Floor, 56% with Coh Floor), so use Floor for plain noise
on flat areas. Coh Floor is for strong but directionless energy: foliage, corners, crossing edges.

**Prefix:** `hatch` - **Object name:** `hatch_pix` - **Type:** `@type float32` throughout.

---

## Render size

Hatch renders at **Vsynth's render resolution**, whatever size the tensor is. It takes the size
from Vsynth the way Vsynth's own modules do (`r dim` receives `dim W H` from `vs_render`;
`loadbang -> s trig_res` asks for it at load). All three stages run `@adapt 0` and follow the
size, and E2's `width` / `height` params are driven the same way (the build key `render_dim`,
documented in `build/spec.md`). Nobody sets them by hand.

Why: `dim` reads 1 inside a live Vsynth `jit.gl.pix`, regardless of `@adapt` and `@type` (found
2026-10-16 in the tensormap work, re-found 2026-10-29), so a codebox cannot read the frame size.
E2 used to, and every march step was pinned to the frame center: the output was the same noise
for any input. Hatch needs a running Vsynth render for its size; the tensor can be any
resolution (it is read at `norm`).

---

## Outlets

| Outlet | Content | Notes |
|---|---|---|
| 0 | Streaks | Hatch strokes, luma on black, `@type float32`: strokes follow the structure axis and lengthen where coherence is high, grain where it is low, nothing below the structure floor. Color is downstream's job |
| 1 | Streak field | The same field without the Line style (soft strokes), for downstream styling or gating |

Neither outlet is a tensor or a vecfield (do not feed them to tensor consumers). The header
`signal_type` reads "T_ in" (the tensor family's color) as the inlet tag only.

---

## Cost

Bench numbers, 1080p, per pass (2026-10-30, clean machine): **E1 0.80 + E2 3.00 + E3 0.82 =
4.62 ms** (E1 and E3 are upper bounds at the bench floor); the module gate is 5 ms. Coh Floor is
free (E2 with it at 0.5 reads 2.96 ms).

**Stroke-texture mode** (bench 2026-10-30, 1080p, float32): E2 with the pre-staged 480x270 texture
**5.0 ms** (12.2 with a full-size float32 texture, which is what the module did before the
pre-stage; blobs 3.0), `pre_h` 0.37 and `pre_v` 0.25 (both upper bounds at the bench floor), so the
module in texture mode is about **7.4 ms** (conservative: E1 and E3 are floors too); its gate is
8 ms, the blob gate stays 5. The pre-stage's GPU passes match the mirror exactly (0.0 error, 16:9,
1:1 and a size 4 does not divide). Why a pre-stage: probes
(`.specify/f_tf_hatch/spike/bench_cost_probe*.py`, `bench_downsample_probe.py`) showed the cost is
the texture's memory footprint times the tiling stride, not the fetch count or the branch: a 4x4
texture 2.7 ms, 256x256 4.8, 512x512 5.1, 1024x1024 6.9, 1920x1080 13.2; a box downsample is
accurate to 1e-7 against NumPy. Vsynth's own textures may be 8-bit; that is not testable on the
bench.

---

## Typical use

```
camera -> f_tf_tensormap -> f_tf_smooth -> f_tf_hatch (outlet 0 / 1)
                                              ^ in1: a Vsynth noise or pattern module (optional)
```
Chain-terminal renderer. Start with Density around 0.5-0.7 and Line 0-0.5, raise Floor until flat
walls go black, raise Coh Floor only if directionless clutter remains. The full chains (B:
`tensormap <-> f_tf_authored -> f_tf_mix -> f_tf_smooth -> hatch`; D: `f_vf_optical_flow ->
f_tf_motion -> f_tf_smooth -> hatch`) assemble as those modules land.

---

## Upstream contract

`f_tf_smooth` upstream is the practical requirement: a stroke present one frame and gone the next
reads as noise, and Hatch is stateless and holds no smoother. Its inlet expects EXACTLY tensormap
outlet 0's encoding (`f_tensor_type.md`). Floor reads the encoded trace, so it depends on the
tensormap's Strength (the Strength dial that used to live on Hatch is gone: it only fed the
zero-tensor guard, since axis and coherence are ratios).

---

## Notes

- **Tests.** NumPy mirror `tests/modules/tf_hatch/tf_hatch_mirror.py` and tier 1
  `test_tf_hatch.py` (20 tests: decode vs `eigh`, headline behaviors on coherent / isotropic /
  ring fields, blob coverage and axis bias, the texture mode, Coh Floor); tier 2 GPU bench
  `bench_tf_hatch.py` (12 tests: parity vs the mirror including the texture mode and Coh Floor,
  edge cases, cost). The build key and its static guard: `tests/build/test_render_dim.py`.
- **The blobs.** Quintic value noise on a lattice rotated 22.5 degrees (so strokes along the axes
  and the diagonals see the same noise), thresholded with a soft ramp; the threshold is a
  closed-form cubic in Density (`BLOB_THR`, fit by `.specify/f_tf_hatch/spike/blob_fit.py`). They
  replaced the first lit-lattice-cell noise, whose squares painted cell-shaped patches.
- **Spec OQ1 ("coherence only as persistence") is superseded** for `coh_floor > 0` (2026-10-29,
  Matt): the first form kept each undirected pixel's own mark, which read as bright dots; the
  chosen form fades them to black.
- **Latent `dim` readers.** Six modules still read `dim` in code (`f_cmap`, `f_grain`,
  `f_masonry`, `f_quasi`, `f_vf_seeds`, `f_vf_vorticity`); `tests/build/test_render_dim.py` keeps
  them on an explicit exemption list until each gets `render_dim`.
- Spec, plan, tasks, findings, spikes: `.specify/f_tf_hatch/`; session record in `HANDOFF.md`.

---

## References

- `docs/f-reference/f_tensor_type.md` - the tensor encoding contract.
- `.specify/f_tf_glyph/plan.md` ADR-2 - the canonical decode idiom (the basis of stage E1).
- `.specify/f_tf_hatch/spec.md`, `plan.md` - the v2 design (line integral convolution of sparse
  impulses along the axis field; coherence as persistence).
- `build/spec.md` ("render_dim") and `docs/f-reference/f_wc.md` - the Vsynth `r dim` pattern.
- `docs/f-reference/f_tf_tensormap.md`, `f_tf_smooth.md` - the upstream modules.
- Cabral and Leedom 1993, "Imaging vector fields using line integral convolution" - the technique.
