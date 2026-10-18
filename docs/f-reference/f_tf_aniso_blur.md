# f_tf_aniso_blur

**Type:** Processor (tensor consumer)
**Status:** Draft — codebox tier-2 bench and tier-3 live judgement pending

---

## What it does

**Structure-aligned smoothing, the coherence-enhancing smoother.** Blurs the
source texture along the local structure axis, with the kernel's shape — its
elongation *and* orientation — taken per-pixel from the structure tensor,
falling back to plain isotropic blur where the field has no direction. It
smooths *along* the grain and not *across* it: the real-time closed-form
simplification of Weickert's coherence-enhancing diffusion (his CED is
iterative and expensive; this module does the same tensor steering in one
pass with an elliptical kernel).

Two texture inlets: the **tensor** drives the kernel, the **source** is the
content to smooth. Feed both the same texture (the default hand connection)
for edge-preserving denoise; feed different textures for the expressive
chain (a kernel field decoupled from the smoothed content).

The tensor inlet requires an `f_tf_tensormap` **outlet 0** (raw tensor, per
`docs/f-reference/f_tensor_type.md`); the module decodes eigenvalues and axis
per-pixel, in-shader. Outlet 1 (the packed, angle-doubled outlet) is a
wiring error here: the kernel needs the eigenstructure the raw form carries
losslessly.

Processor archetype, requires both inlets. One outlet: the smoothed source,
`@type float32`, values unclamped (a weighted mean stays within the source's
convex hull — the smoother asserts no ceiling; encoding/clamping is the next
consumer's business).

---

## Signal Flow

```
in0 (tensor, f_tf_tensormap out0) ──┐
                                    ├─> aniso_blur_pix codebox (one pass)
in1 (source texture + control) ─────┘
                                    └─> outlet 0 (smoothed source, float32)
```

One `jit.gl.pix`, no internal chain. Per pixel: decode → closed-form 2×2
eigen → gates → 49-tap kernel accumulation → sum normalization.

## The gate model (ADR-3, in user terms)

Two tensor-derived quantities drive two kernel properties:

- **LENGTH from energy.** `W = min(1, λ1·strength_scale)`,
  `L = length·W`: the kernel extends up to `length` pixels along the
  structure axis, scaled by the absolute eigenvalue energy. Where the tensor
  carries no energy there is no length — "no blur where there is no
  structure" — a property no ratio can express, and the failure-mode guard
  for the strength-coupling problem below.
- **WIDTH from coherence.** The transverse extent is
  `D = L·max(floor, 1 − coherence·width_gate)`: at coherence 1 the kernel is
  a line along the edge (width ~ 0); at coherence 0 it is a circle. The
  `floor` keeps a minimum isotropic fraction everywhere (no "dead" flat
  region where the filter does nothing); `width_gate` shapes how fast the
  kernel elongates with coherence.
- **The isotropic fallback is a measurement, not a threshold.** Where the
  decoded tensor is non-SPD, has no trace, or has no defined axis, the
  kernel *by construction* drops the axis and equals the isotropic reference
  blur exactly (verified to 4e-7 in the mirror tests). There is no seam
  between the anisotropic and isotropic regimes: the fallback is *isotropic
  blur*, not "skip the filter".

## The strength pairing (one explanation, cited)

The raw tensor's G channel is `Jxy·strength·0.5 + 0.5`: the decode needs the
value tensormap's `strength` dial was set to, and that value is not carried
on the wire (`f_tensor_type.md`, outlet-0 contract). So **tensormap's
`strength` and this module's `T-Map Strength` must be dialed together** with
the same value; this module's `strength_scale` is then calibrated against
the *paired* delivered tensor (tier-3, same session as tensormap's own
calibration — see `docs/f-reference/f_tf_tensormap.md` "Calibration by input
type"). The eigenvalue *ratios* — coherence, axis shape — are
strength-invariant: a mismatch only rescales the decoded absolute λ1 and
thus W. Measured (tier 1, T010): a ×3 decode mismatch takes W from 1.0 to
0.167 on the default kernel; matching gains leave the output bit-identical.
This is spec OQ3 option (a): documented pairing, no code defense. If a
mismatch bites in practice, the alternatives recorded there (a tensormap v2
gain channel, or ratio gating) reopen — do not "fix" it silently.

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `strength_scale` | 0–2 | 0.5 | Energy→length gate gain: W = min(1, λ1·this). Calibrate together with tensormap's `strength`. |
| `length` | 0–8 | 4 | Kernel semi-length in pixels along the structure axis. 0 = no blur at all (identity). |
| `width_gate` | 0–1 | 0.5 | Coherence gate: 0 = always circular, 1 = full coherence response. |
| `floor_pct` | 0–1 | 0.25 | Width floor (labeled "Floor"): minimum isotropic fraction everywhere. 0 = no smoothing where there is no structure; 1 = fully isotropic. |
| `strength` | 1–1000 (log) | 100 | **The value tensormap's `strength` dial is set to** (the G-decode pairing above). Not an effect control. |
| `width` | 64–8192 | 640 | Render width in pixels — sets the one-pixel tap step. **Set to your real frame width** (`dim` reads 1 inside a live `jit.gl.pix`). |
| `height` | 64–8192 | 480 | Render height in pixels — same. |
| `bypass` | 0/1 | 0 | Exact passthrough of inlet 1. |

All four effect-knob defaults are **provisional** (tier-3 judgement pending);
`length`'s range top is set by the kernel's compile-time tap budget:
TAPS_MAX = 49 = 1 + 2·8 stations × 3 transverse taps.

**`length` cost does not scale with the dial.** The loop runs to the fixed
TAPS_MAX and weights unused taps to zero — same fact as tensormap's
`radius`; turning `length` down buys no frame time.

---

## The kernel

49 taps per pixel, oriented along the decoded structure axis:

- centre tap, weight 1;
- 8 stations per side at half-integer 1-pixel spacing (±0.5 … ±7.5 px),
  station weight `exp(−2u²/L²)` — L is the Gaussian semi-length;
- each station: 3 transverse taps at t = 0, ±D/2 px with the
  discrete-Gaussian rule (¼, ½, ¼) — the kernel's cross-section is a
  3-point Gaussian, continuous, not a dotted line;
- all weights positive, sum-normalized (the convex-hull property).

The axis is decoded with **no atan2 at all**: the doubled-angle vector
(Jxx−Jyy, 2·Jxy) carries the angle-doubled terms, and the half-angle axis
comes from the standard identities cos θ = √((1+diff/root)/2),
sin θ = sign(2·Jxy)·√((1−diff/root)/2) (sign of zero read as +; verified
against the atan2 decode to ~1e-7). The kernel is bilateral (up-and-down
both sides of the axis), so the line field's θ/θ+180° freedom is inert —
the glyph idiom's sign caveat (`f_tf_glyph/plan.md` ADR-2, which this
module's decode copies verbatim with a citation) cannot bite here.

**Straight-axis constraint (v1, plan ADR-4):** samples run along the local
axis *through the center pixel* only — no curvature following. On curved
contours the kernel cuts corners slightly instead of flowing around them.
This is the honest single-pass limit, not a bug; fixing it is a design
change (step-sign continuity), recorded as spec OQ6.

**Cost:** cost scales with TAPS_MAX (the compile-time loop), not any dial.
Cost model vs the tensormap bench floor (~0.9 ms/pass at 1080p, R_MAX 16):
the 49-tap pass is the same loop-cost class (PROVISIONAL — bench
measurement pending, `tests/bench_tf_aniso_blur.py` written; M1 unmeasured,
same caveat as tensormap).

---

## Unconnected inlets and wrong feeds

| Feed | Behavior |
|---|---|
| Tensor unconnected | `vs_black` (all zeros) decodes to Jxy·s = −1 → trace 0, λ1 = 1/s *phantom energy*, λ2 negative (non-SPD). **The SPD guard fires** (this is an energy-gated consumer: a trace gate alone would mistake the phantom for structure) and the pixel takes the isotropic fallback: a plain `length`-radius isotropic blur of the source. No crash, no invented direction. |
| Source unconnected | Black output, no crash. |
| Packed outlet 1 fed by mistake | Neutral (0.5, 0.5, 0, 0) decodes to a weak isotropic tensor (near-no-op); a strong packed feed reads as a plausible but wrong kernel field — visibly wrong, self-diagnosing; documented, not sniffed. |
| Bypass | Exact passthrough of inlet 1 (this module has no encoding of its own to neutralize). Rgb **and alpha** pass through — the bypass mix carries an alpha arm; on an unconnected tint inlet the outlet alpha follows the neutral's (0.5). |

The all-zeros phantom and the SPD-as-primary-defense distinction are the
joint glyph/aniso_blur finding of 2026-10-17; see `f_tensor_type.md`
consumer rule 5.

---

## Typical use

```
# denoise mode: same texture to both inlets
jit.gl.bfg -> f_tf_tensormap (outlet 0) -> f_tf_aniso_blur (tensor in0, source in1 <- bfg)

# expressive chain A: a kernel field decoupled from the smoothed content
jit.gl.bfg    (structure source) -> f_tf_tensormap outlet 0 -> aniso_blur in0
<video source>                                                  -> aniso_blur in1
```

A/B against plain isotropic blur: raise `floor` to 1 (or `width_gate` to 0)
for the exact circular reference at the same length budget.

---

## Notes

- Tier-1 mirror: `tests/test_tf_aniso_blur.py` (19/19; independent ground
  truths: `np.linalg.eigvalsh`, a densified brute quadrature, a dense area
  Gaussian, an independent isotropic reference). Tier-2:
  `tests/bench_tf_aniso_blur.py` (written; **not yet run** — bench-gated).
  Spec/plan/tasks: `.specify/f_tf_aniso_blur/`.
- Kernel-family decision (fixed-tap line integration vs ellipse grid) is
  plan ADR-2, RESOLVED PROVISIONAL-OPEN: family (a) ships; the exact bench
  experiment that closes the gate is recorded in the plan's ADR-2 addendum;
  the ellipse-grid family exists as a mirror function
  (`ellipse_grid_pass`) and its artifact datum is recorded (family (a) mean
  abs 0.0362 vs family (b) 0.0300 against the continuous area Gaussian at
  the default kernel).
- Bench GPU wraps out-of-range texture reads: every tap's sample coordinate
  is clamped to texel centres in-shader (`f_tf_tensormap.md` Notes,
  tensormap ADR-5).
- **All texture reads use the four-tap `nearest()` hand-bilinear idiom**
  (2026-10-17 post-bench refactor, plan ADR-6): the cell-coherent read
  coordinates make the hardware sampler's minification path fall back to
  nearest at cell-boundary pixels (silent, dim-dependent — f_tensor_type.md
  rule 6b). Cost: 4× reads per tap, ~196 reads/pixel at the 49-tap kernel;
  bench 6/6 green post-refactor and a 97×64 spot-check at 4.4e-6 vs mirror.
- Decode idiom: `.specify/f_tf_glyph/plan.md` ADR-2 (copied verbatim with a
  citation in the codebox; no re-derivation, no atan2 beyond what that
  block contains — this module uses none at all).
- The packed `B`/`A` channels of tensormap outlet 1 (trace, coherence) are
  NOT consumed here; the module works against outlet 0 only (the raw form
  avoids the packed outlet's trace clamping loss).
- Hub: `ideas/f_tensorfield.md`.

## References

- Weickert, J. (1998). "Coherence-enhancing diffusion filtering." IJCV 31.
  (CED; the isotropic fallback discipline and eigenvalue ordering.)
- Weickert, J. (1999). "Coherence-enhancing diffusion of colour images."
  Pattern Recognition and Image Analysis 9.
- `jit.fx.cf.directional` (Cycling '74): the 3-tap line-integral precedent
  this kernel family generalizes (`ideas/f_tf_research.md` §4).
- The 49-tap discretization, the discrete-Gaussian transverse rule, the
  half-angle axis identities and the gate model are this library's own; no
  code was taken from other implementations.