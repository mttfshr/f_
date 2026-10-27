# f_quasi

**Type:** Generator (dual-mode: optional texture inlet, three outlets) — stateless; the clock lives in the patcher
**Status:** Built, benched and live-checked (Matt, 2026-10-26: the built module, "ship it"). The defaults are first-look values, not a tuned set; the open items are under Known issues.

_Working name kept (gate G1, 2026-10-26). Reference written 2026-10-26 from `src/f_quasi/` (definition + codebox), `.specify/stable/f_quasi/{spec,tasks}.md` and the module's tests. Where the spec and the shipped module differ, this doc follows the module._

---

## What it does

A **Shepard-zoom quasicrystal generator**: a sum of cosine plane waves at five directions (36° apart) over seven octaves, with the octave weights a Gaussian in log2 scale. Because the weight envelope is fixed in absolute scale, advancing `Zoom` by one octave only swaps which octave is loudest, so the pattern keeps its character as it scales: an endless zoom, the visual analogue of a Shepard tone. The pattern is five-fold and never repeats.

It is **stateless**: no feedback, no memory. Everything animates from parameters; a small patcher-side clock (the **Z.rate** and **D.rate** dials) advances `Zoom` and `Drift` for you, and `Zoom` and `Drift` stay plain dials so a mod source or LFO can drive them too.

Three outlets come from one pass: a **banded look** of the potential, the potential's **exact analytic gradient as an `f_vecfield`**, and the **potential itself** as a 0–1 texture.

Typical use: patch it alone as a living contour texture; patch the vecfield outlet into `f_caustic` or `f_vf_warp` for a field that is not tied to an image; raise `Gain` to use more of the vecfield's range.

Related, not replaced: `f_chladni` (a fixed modal figure, audio-driven, no zoom) and `f_ks` (chaotic, no zoom coherence).

---

## Outlets

| # | Type | Content |
|---|---|---|
| 1 | tex (float32, A = 1) | Banded look: `abs(fract((P/2 + 1) * bands) * 2 - 1)^1.1`, a triangle-folded contour map of the potential |
| 2 | f_vecfield (float32) | `grad P` divided by the weighted total frequency, so `|v| <= 1`; encoded `v * gain * 0.5 + 0.5`, B = 0.5, A = 1 |
| 3 | tex (float32, A = 1) | The potential `P` in [-1, 1] mapped to `P/2 + 0.5`, as gray |

Bypass (`bypass_gate`, never the native `@bypass`): outlets 1 and 3 black with A = 1, outlet 2 the neutral vecfield (0.5 / 0.5 / 0.5 / 1). The pass still runs underneath.

---

## Signal Flow

One inlet (control messages and an optional texture), one `jit.gl.pix`, three outlets. The inlet follows the library's dual-mode generator pattern: `vs_inState` feeds the pix a texture, or `vs_black` when nothing is connected, so the module draws on its own. The codebox does not read that texture; its **size sets the aspect** (`dim.x / dim.y`, as `f_grain` and `f_masonry` do), and the patcher's own `src_mode` flag (`vs_inState`'s connected / not connected) is declared and unused.

The clock, in raw boxes, one per dial:

```
[r draw] -> [f] -> [+ rate] -> [expr $f1 - floor($f1)] -> [f] right inlet   (store the new phase)
                                                        -> [prepend param zoom_clk] -> pix
```

`Z.rate` (octaves per frame) and `D.rate` (turns per frame) go to the right inlet of each `[+ ]` and have no cord to the pix (`pix_wire: False`). The wrap is `x - floor(x)`: **Max has no control-rate `[wrap]`**, and the expression is exact for a value already in [0, 1), so a rate of 0 freezes the phase exactly. The codebox adds `zoom_clk` to the `Zoom` dial and `drift_clk` to the `Drift` dial and wraps each sum.

The clock is **frame-based** like the other `rate` dials: the speed depends on the frame rate.

---

## Parameters

Panel 227 × 164, nine dials. Control tokens are the route names and the codebox Param names.

| Label | Token | Type | Range | Default | Description |
|---|---|---|---|---|---|
| Zoom | `zoom` | float | 0.0–1.0 (cyclic) | 0.0 | Pattern scale: one full turn is one octave and wraps with no seam. The clock adds to it |
| Z.rate | `zoom_rate` | float | -0.02–0.02 | 0.002 | Zoom clock, octaves per frame, either direction (0.002 = one octave in about 8 s at 60 fps). 0 freezes the zoom exactly |
| Drift | `drift` | float | 0.0–1.0 (cyclic) | 0.0 | Phase of the waves, in turns: one full turn is the identical frame. The clock adds to it |
| D.rate | `drift_rate` | float | -0.02–0.02 | 0.001 | Drift clock, turns per frame, either direction (0.001 = one turn in about 17 s at 60 fps). 0 freezes the phase exactly |
| Dens | `density` | float | 1.0–12.0 | 4.0 | Cycles per frame height at the base scale: finer or coarser texture |
| Env | `envelope` | float | 0.25–0.7 | 0.5 | Sigma of the octave envelope: low = one scale dominates, high = a wider mix. The top of the range keeps the zoom loop seamless (Notes) |
| Bands | `bands` | float | 1.0–12.0 | 5.0 | Contour count in outlet 1 |
| Angle | `angle` | float | 0.0–180.0 | 0.0 | Rotates the five wave directions together, degrees |
| Gain | `gain` | float | 0.0–8.0 | 1.0 | Strength of the vecfield outlet. At 1 the bounded field fills only part of the range (Notes); 0 is the neutral field |
| Bypass | — | toggle | 0 / 1 | 0 | `bypass_gate`: neutral values on every outlet |

Driven by the module, never by a control: `zoom_clk`, `drift_clk` (the clock's wrapped phases), `src_mode` (declared, unread), `bypass_gate`.

The `bypass 1` control **message** is not routed (as in most generated modules); use the toggle.

---

## Algorithm

With N = 5 orientations, M = 7 octaves, frame-height units, `x = (norm.x - 0.5) * aspect`, `y = norm.y - 0.5`:

```
zw     = frac(zoom + zoom_clk)            dw = frac(drift + drift_clk)
e_i    = zw + i                           i = 0 .. 6
s_i    = exp(e_i * ln 2)                  w_i = exp(-0.5 * ((e_i - 3) / envelope)^2)
phi_k  = k * pi / 5 + angle               beta_k = frac(exp(pi * k))      (float64 literals in the codebox)
psi_ik = beta_k * s_i + 2 pi dw 2^i + (cos phi_k * x + sin phi_k * y) * 2 pi B s_i      B = density
P      = sum_i w_i sum_k cos(psi_ik) / (5 * sum_i w_i)                     in [-1, 1]
grad P = -2 pi B sum_i w_i s_i sum_k sin(psi_ik) dir_k / (5 * sum_i w_i)
v      = -sum_i w_i s_i sum_k sin(psi_ik) dir_k / (5 * sum_i w_i s_i)      |v| <= 1
```

Exact and bounded: `v` is the gradient divided by `2 pi B` times the weighted mean frequency, so it needs no per-setting scale.

---

## Notes

- **Units.** `Dens` is cycles per frame **height** (only `x` is scaled by the aspect), so rings stay round and the pattern is the same at any aspect. The first spec said frame width; the mirror's convention is height.
- **The zoom loop is seamless only if the envelope is narrow.** The octave that leaves (scale 128) has weight `exp(-8/sigma^2)` and the one that enters (scale 1) `exp(-4.5/sigma^2)`. The residual between `Zoom` just below 1 and 0 measured 1.7e-8 at `Env` 0.5, 7.6e-5 at 0.7, 5.2e-3 at 1.0 (about 17 levels of the banded texture at 12 bands). The dial stops at 0.7, where the residual is under half an 8-bit level of the banded texture at 12 bands.
- **Drift is a phase in turns, applied as `2 pi dw 2^i`**, exactly periodic because `2^i` is an integer. A plain unbounded phase scaled by each octave's scale lost half an output level of precision by a value of 1e4. Side effect: drift speed does not scale with `Zoom`.
- **Precision.** The GPU potential matches a float64 evaluation to 3.7e-5 (twelve parameter sets), the same size as float32 NumPy (2.6e-5), with no argument reduction. The five `beta_k` are float64 literals: float32 `exp(4 pi)` is 286751.4 with an ulp of 0.031, which would corrupt `beta_4`.
- **The vecfield is bounded but loose.** Over a parameter sweep the largest `|v|` was 0.62 (median 0.22 and 99th percentile 0.47 at the defaults), so at `Gain` 1 the encoded R and G occupy about 0.19–0.80 of their range. `Gain` above 1 uses more. A fixed scale would not serve every setting: the true gradient's peak spans 24 to 337 across the sweep. A fixed-scale alternative was not shipped.
- **No Nyquist fade.** At 1080p, inside the ranges, the highest octave that carries weight (at least 1e-3 of the peak) reaches only 0.50 cycles per pixel (density 12, `Env` 0.7), so nothing aliases. Aliasing appears at small render sizes (a 270-pixel-tall frame at high density). The tested candidate is a per-octave smooth fade on cycles per pixel, not renormalised (a renormalised or global fade performed worse); it is not shipped.
- **Cost.** One pass at 1920×1080 is under 0.21 ms (under 0.82 ms at 3840×2160) on the M3 Max, an upper bound set by the bench's resolution; the M1 is unmeasured. Skipping low-weight octaves was not worth a branch.
- **Aspect comes from the texture on the first inlet** (`dim`), which in a chain is render-sized. In the codebox bench `dim` follows the first input's size, not the render's, so the bench gives it a render-sized input.

---

## Known issues / open

- **Tuning is first-look.** Ranges and defaults are as built; the `Gain` default (1), the zoom and drift speeds, and the bounded versus fixed-scale vecfield have not had a tuning pass beyond Matt's first live look.
- **No Nyquist fade** for small render sizes (above).
- **The clock is frame-based**: its speed follows the frame rate, and drift speed is independent of zoom.
- **`bypass` message not routed**; the toggle works.
- **M1 cost unmeasured.**
- **No helpfile preset table or menu recipe yet**; this module sits in the `f_modules` menu under Patterns.

---

## Verification

- `tests/modules/quasi/test_quasi.py` — NumPy mirror (`quasi_mirror.py`), 12/12, against an independent scalar float64 reference: potential bounded, octave shift, wrap weights, drift period, rotation covariance, analytic gradient against a finite difference (1.8e-6), vecfield bound, banded look closed form, four mutations caught.
- `tests/modules/quasi/bench_quasi.py` — the real codebox on the GPU, 7/7: all three outlets against the mirror (look within 2.2e-4, vecfield within 2.5e-5, scalar within 2.0e-5), exact bypass neutrals, gain 0, zoom and drift wraps, clock phases add, `src_mode` inert, and the `dim` probe.
- Records: `tests/records/spike_quasi_{float32,gradient,wrap,nyquist,cost}.py`.
- Module contract bench (`tests/contracts/bench_modules.py`), 2/2 over all 47 modules with no unexpected issue; offline contracts 9/9 (`src_mode` is a documented unread Param); drift 0 (reproduces exactly from the definition).

---

## References

- Shepard (1964). "Circularity in Judgments of Relative Pitch." Journal of the Acoustical Society of America 36(12):2346–2353. The octave-weighted envelope here is the same idea, in space.
- Mermin & Troian (1985). "Mean-field theory of quasicrystalline order." Physical Review Letters 54(14):1524–1527. Background reading on quasicrystalline order; this module is a visual construction, not a physical model.
- Michael Rule's webgpgpu (`github.com/michaelerule/webgpgpu`), `Example_27`, `Example_28`, `Example_31`, `Example_33`: the structure (five plane waves, seven octaves, a log-Gaussian octave envelope centred on octave 3, a triangle-folded banded look raised to 1.1) is adapted from these examples. The source's gradient omits the `2 pi B s` factor and its aspect handling is not isometric; this module's exact gradient, the weighted-total-frequency normalisation, the wrapped drift phase and the frame-height coordinates are original to this repo.
- Related: `f_chladni.md`, `f_ks.md`, `f_caustic.md`, `f_vf_warp.md`, `ideas/f_quasi.md`.

---

## Source Files

`src/f_quasi/definition.py`, `src/f_quasi/codebox_quasi.gen`, `package/patchers/f_quasi.maxpat`, `package/help/f_quasi.maxhelp`, `.specify/stable/f_quasi/{spec,tasks}.md`, `tests/modules/quasi/`.
