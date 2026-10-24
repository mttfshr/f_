# f_wc support items from webgpgpu (noise drive, reference, habituation, retinotopic stage)

_Status: 🟡 partially promoted. Drafted 2026-10-23 from the webgpgpu mining run
(`webgpgpu-ideas-1`). Companion to `f_vf_wilson_cowan.md` and `.specify/f_wc/`.
Discussed with Matt after f_wc shipped (2026-10-23): habituation (item 3) promoted to
`.specify/f_wc/tasks.md` Phase 4 (T052 + gate G5); the noise-stream and retinotopy
round-trip checks promoted as tier-1 hygiene (T050/T051). The known-answer fixture
(item 1) and the shared noise / retinotopy pieces (items 2, 4) are parked, reasons
recorded in the Phase 4 section._

Michael Rule's Wilson-Cowan pages (`wilson_cowan/wilson_cowan_gpu.html` and
`examples/wilson_cowan_examples/`) are what unblocked `f_wc` on 2026-10-23. The mining
run read them as ordinary examples, and four reusable pieces came out.

## 1. Known-answer reference

The page is a working, parameter-documented implementation of the system the Phase 0
spike ablated against. The headless reproduction already done (cortical texture std
95/255 at 512 px, Psychedelic preset, 1600 frames, per `HANDOFF.md`) is the natural
fixture. The tier-1 mirror can assert field statistics (mean, std, spatial
autocorrelation scale) averaged over several seeds, since the labyrinth is a
long-lived transient on a saturation boundary and single seeds may differ.

## 2. Gaussian noise drive

The per-frame stochastic drive is the load-bearing ingredient. Rule's page:
- a uniform noise texture regenerated every step by a GPU RNG helper (the games lessons
  use a small chaotic neighbour-product map for the same job, reseeded from random bytes
  only at init);
- turned into Gaussian pairs per pixel by Box-Muller (radius `sqrt(-2 ln u)`, angle
  `2 pi u'`), scaled by `sqrt(dt)`, injected as `Ne * noise` into the E and I inputs.

For GenExpr the uniform source should be the sin-hash seeded by a per-frame value
(`noise()` is a silent failure). Check before relying on it: sin-hash uniforms can
show lattice correlations on large grids, so histogram-check the result on the real
sample grid, and check temporal decorrelation between frames. One example
(`WC_Example_11_acid_trip`) already builds Box-Muller from a hash. A small shared
noise helper (or a tiny `f_rng` module) would also serve `f_ca.md`; eight separate
drafts proposed a Gaussian noise utility, all the same idea.

## 3. Habituation dials

The model already carries slow adaptation variables (`Ve`, `Vi` in the spare blue and
alpha channels, relaxing toward the firing rates and subtracting from the inputs;
Example 11 uses `ae = 50`, `ai = 100`). The Psychedelic working set sets `be = bi = 0`,
so adaptation exists but is not performable. Exposing depth and rate gives a slow
fatigue-and-recovery layer under the labyrinth transient. Costs: four ALU ops, no extra
texture. Risk (both the worker and the verifier agree): subtractive feedback pulls the
populations toward the saturation boundary the labyrinth lives on, so the Phase 0 region
map must be redone with adaptation on, and it may shrink the usable drive band
(Ne about 0.7 to 0.85) instead of adding a regime. Tier-1: with both weights zero the
mirror is bit-identical to the unadapted run.

## 4. Retinotopic stage as a shared piece

`f_wc` does the inverse log-polar map inside its own render stage. `WC_Example_5`
shows the same map as a display pass: angle `atan(z.y, z.x)` and `log(length(z))` as
sample coordinates, scaled by 1/2 pi with wrap, plus a drift as a plain offset in angle
and log radius. The same resample would show any texture or generator in visual-field
coordinates with logarithmic centre magnification. `f_droste` is a spiral-zoom display
transform, not an honest cortex-to-retina map with a foveal policy, so there is a real
distinction, but the overlap and the foveal singularity (the seam family in
`droste_singularity.md`) make the standalone value uncertain. Design question: factor
the stage out as a shared module now, or keep it inside `f_wc` until a second consumer
exists. Tier-1: map then inverse is the identity up to interpolation error inside the
eccentricity range.

## Not taken from the examples

- 8-bit rounding to keep state stable (`floor(255 x + .5) / 255`) and the 16-bit packed
  variant: unnecessary with float32 state. One example's note on platform-independent
  rounding is relevant only to a web export.

## Related

`f_vf_wilson_cowan.md`, `.specify/f_wc/`, `f_ca.md`, `f_adapt.md`,
`droste_singularity.md`, `f_droste`.

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 32, 33, 34, 35, plus the known-answer
reference and noise utilities in `SUGGESTIONS.md`. Verified by subagents against the
page sources and the f_wc spec. The omp run did not flag the noise drive as the
load-bearing ingredient (it filed it as a generic utility); that framing is from
`HANDOFF.md`.
