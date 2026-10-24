# f_wc

**Type:** Generator (drive inlet, luma out) — **temporal / has memory**
**Status:** Built, benched and tuned. Phase 0 (settled model + gates), Phase 1 (GPU chain + mirror diff), Phase 2 (Ranges/G4/landmarks/retinotopy) all closed 2026-10-23. Phase 4 (2026-10-23, gate G5): the `habituation` dial shipped — slow Ve/Vi fatigue riding the spare state channels. README lists it by name.

_Reference written 2026-10-23 from `src/f_wc/` (definition + codeboxes), `.specify/f_wc/{spec,tasks}.md` and the module's tests. Where the spec and the shipped module differ, this doc and `tasks.md` follow the shipped module._

---

## What it does

A **Wilson-Cowan hallucination** generator: a 2D excitatory/inhibitory solver on the GPU whose
per-frame random drive keeps the pattern ALIVE — stripes, labyrinth and spiral-ish forms that
keep reorganizing forever. Nothing needs to feed it. It is a hallucination with a **drive inlet**:
weak drive = hallucinate (free labyrinth), strong drive = the scene imprints (normal vision). One
knob, both ends of the trip.

It outputs a grayscale luma texture. It does not output a vecfield.

Typical use: patch it alone for a living pattern; feed a camera or a bright structured texture
into the **drive** inlet to make it see; use the output as a mask, displacement source or
`f_vf_fieldmap` input.

The solver is a fixed **256 × 256** float32 grid on a periodic domain. Only the last stage
follows the render size (a log-polar inverse-retinotopic map, see below), so the outlet is a
normal render-size texture whatever the solver size.

---

## Signal Flow

One control inlet (messages and the draw bang, no texture), one drive inlet (texture,
optional), one outlet.

```
hold -> pass (in 1)          seed -> pass (in 2)   seed -> nl (in 3)   drive -> nl (in 4)
pass -> fx -> fy -> spec -> iy -> ix -> nl  ;  pass -> nl (in 2)
                                           (nl -> hold: the feedback edge)
                                            nl -> enc (render resolution) -> outlet
```

| Stage | Job |
|---|---|
| `hold` | Identity. One-frame delay, the loop break |
| `seed` | Deterministic arithmetic hash noise (no `sin()`), the frame counter as `salt`; R/G are the reseed channels, B/A feed the per-frame noise (`nl`) |
| `pass` | Holds last frame's state (R = E, B = I, G = Ve, A = Vi — the habituation memory), or reseeds each field from the R/G channels when `reseed` = 1 (adaptation restarts at 0). Also reseeds any texel that is exactly 0 in BOTH E/I channels (self-heal, see Notes) |
| `fx` `fy` | Forward DFT, separable, one axis per pass — ONE chain carries BOTH fields (R,G = Re,Im of E-hat; B,A = Re,Im of I-hat) |
| `spec` | Per-bin Gaussian kernel gains `exp(-sigma^2 k^2 / 2)` per field (`sig_i` on the I pair, `sig_i/1.45` on the E pair). No decay term, no DC zeroing |
| `iy` `ix` | Inverse DFT, separable, real parts kept, residue zapped |
| `nl` | The heart: relaxation toward the sigmoid of the coupled drive, per-frame Box-Muller noise into both sigmoid inputs, drive term E-only, Ve/Vi habituation subtracting at depth `habit`, NaN/Inf zap |
| `enc` | Log-polar inverse-retinotopic resample to render size, plain-E display with the `sharp` S-curve blend (default 0.5), bypass gate |

The `r draw` bang goes to `seed`, `pass` and `enc`, and it increments `salt` EVERY frame —
WC's per-frame noise is the mechanism, not a seeding detail (unlike `f_ks`, whose `salt` moves
only on reset). The feedback, state tap, noise and drive textures arrive on cold inlets, so the
loop advances exactly once per rendered frame. The output size follows the render size (`r dim`
into `enc`, `@adapt 0`).

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `rate` | float | 0.0–1.0 | 1.0 | Time step per frame (`dt = rate`; 1 = the validated labyrinth tempo). No stability ceiling exists (relaxation toward a bounded sigmoid); the top of the range is aesthetic, not structural |
| `grain` | float | 1.0–4.0 | 1.4 | The inhibition kernel width in pixels (`σ_I`; the E kernel is slaved at `σ_I/sig_ratio`). **Landmarks: 1.1 broken stripes / 1.4 labyrinth / 1.9 coarse.** Free sweep approved (Matt, 2026-10-23) |
| `aspect` | float | 1.2–2.2 | 1.45 | Inhibition-to-excitation kernel ratio `sig_ratio` (`σ_E = σ_I/sig_ratio`; G6). Character ladder from the night-12 sweep: 1.3 + fine grain = hexagons; 1.45 = the labyrinth corner; 1.7–2.0 = hot rolls; past ~2.5 = saturation |
| `drive_gain` | float | 0.0–2.0 | 0.0 | Scene strength on the drive inlet. 0 = pure free hallucination; ~1.5 = the scene imprints (normal vision). Below ~0.2 the pattern ignores the scene entirely |
| `energy` | float | 0.0–2.0 | 1.0 | Per-frame noise amplitude `Ne` — the drive-band axis. Below ~0.7 the labyrinth thins out and freezes; 1.0 is the T005/G3-verified corner; above ~1.2 it shimmers saturated. It also compensates deep habituation: depth ≥ 2 only stays live at higher energy (T052 deep sweep) |
| `habituation` | float | 0.0–1.5 | 0.0 | Fatigue depth: slow negative feedback on the activity (Ve/Vi relax toward the firing rates over 50/100 frames and subtract from the sigmoid inputs; G5/T052). 0 = free run with exactly the pre-G5 dynamics; higher steadies the field mean against long-soak drift and lifts contrast, at the cost of a narrower low-drive band |
| `sharp` | float | 0.0–1.0 | 0.5 | Edge sharpness in `enc`: 0 = soft gradients, 1 = hard-edged cells. The 0.5 default keeps the free labyrinth readable as its mean wanders (G4 decision) |
| `excite` | float | −0.3–0.8 | 0.0 | Excitability: a shared positive offset inside both sigmoid inputs — the firing thresholds HE/HI lowered together (G7). + = hotter (clean rolls near 0.5); − = toward blackout. The viable band is asymmetric — don't range it wider by message |
| `zoom` | float | 2.0–16.0 | 8.0 | Eccentricity gain of the retinotopic map (`k_ecc`) — log-radius zoom; 8 = the settled T033 corner |
| `twist` | int | 2–8 | 5 | Angular gain of the map (`k_ang`) — the spoke fold. **Integer only**: a fractional gain seams the visual field at θ = ±π (T006). 5 = settled corner |
| `fovea` | float | 0.1–5.0 | 0.5 | Foveal radius of the map (`r0`): smaller = more center magnification; 0.5 = the settled corner |
| `reset` | button / message | — | — | Reseeds both fields from fresh noise. Fires once on load (after 200 ms). Also accepted as a `reset` message on the control inlet |
| `bypass` | toggle | 0/1 | 0 | Black, alpha 1, on the outlet. The solver keeps running underneath, so releasing bypass resumes a warm field |

The drive inlet: a texture, optional. Unconnected it reads the **neutral mid-gray 0.5** (a
vs_inState connection flag supplies it), so `drive_gain × (scene − 0.5)` drops out and the
labyrinth runs free — no special-casing needed to unplug it. Any texture works as a scene;
structured bright regions imprint strongest.

Internal, never set by hand: `reseed`, `salt` (reset/draw logic), `drv_conn` (drive connection
flag), `bypass_gate` (bypass jsui). `amp` (the seed amplitude, 1.0) is a codebox `Param` with
no control, kept so the bench can vary it (tasks.md T021/T025, registered known-undriven in
`test_module_contracts.py`); `ne` was that same kind of constant until 2026-10-23, when the
`energy` dial exposed it.

---

## Algorithm

The settled model is the noise-sustained Ermentrout–Cowan / Michael Rule form (the model that
produces the working "Psychedelic" webgpgpu demo). Each frame, for both fields E and I:

1. **Convolve.** `cE = K_E ⊗ E`, `cI = K_I ⊗ I` with Gaussians in pixel units
   (`K_hat = exp(-sigma^2 k^2 / 2)` per Fourier bin, sigma_E = sigma_I/sig_ratio — the
   `aspect` dial, 1.45 at the settled corner). That IS the linear
   part; there is no separate decay term and no DC zeroing — the relaxation below carries both.
2. **Relax.** `E += (S(16.1·cE − 14.5·cI − 3.1 + excite − habit·Ve + Ne·N + drive_gain·(drive − 0.5)) − E)·dt/4`,
   and same for I with 13.7/13.0/3.5 and `dt/12.5`, where `S` is the logistic sigmoid, `N` a
   FRESH Gaussian field every frame (`Box-Muller × sqrt(dt)`, shared by both sigmoid inputs),
   and the drive term is E-only. `Ve, Vi` are the habituation memory (the `habituation` dial):
   they ride the spare state channels G/A (the DFT chain's imaginary parts; the real kernel
   gains leave the convolved E, I unaffected), relax `Ve += (E − Ve)·dt/50`,
   `Vi += (I − Vi)·dt/100`, and subtract at depth `habit`. At `habit` = 0 (default) G/A stay
   pinned at 0 and the dynamics are exactly the pre-G5 dynamics; reseed restarts them at 0.
   Constants are the settled "Psychedelic" corner and are baked into `codebox_nl.gen`;
   `dt = rate`.
3. **Contain.** A non-finite result becomes 0 in `nl`; any texel that hits exact 0 in both
   fields is reseeded from the noise channels by `pass` next frame.
4. **Encode.** The display resamples E through an **inverse retinotopic map** (the cortical
   sheet rendered as a visual field: `(u, v) = (k_ecc·log1p(r/r0), k_ang·theta)` — the zoom/twist/fovea dials, periodic in both
   axes), then shows E directly — `soft = clamp(E, 0, 1)`,
   `crisp = smoothstep(0.46, 0.54, soft)`, `lum = mix(soft, crisp, sharp)`, R = G = B = lum,
   A = 1. Map constants (fovea 0.5, eccentricity gain 8, angular gain 5, radius 4) are settled
   and baked in `codebox_enc.gen`.

The per-frame noise is the **load-bearing mechanism**: the labyrinth is a noise-sustained
transient, not a stable Turing attractor. Without fresh noise every frame the pattern collapses
to uniform (the Phase-0 ablation). With it, stripes/labyrinth/spiral-ish forms reorganize
forever.

---

## Notes

- **The taxonomy is one continuum, not four separable attractors.** The Phase-0 region map
  found clean stripe-glass at fine kernel widths and disorderly labyrinth at coarse ones, with
  spiral/cobweb-like forms appearing transiently between; there was no four-form selector to
  build (G1, 2026-10-23 — Matt chose the labyrinth generator over the taxonomy). The "Wilson-
  Cowan form constants" name survives in the `ideas/` lineage; the shipped module is the
  hallucination generator by that name.
- **Reset is fast at rate 1.** Pattern contrast reaches ~0.06 within 4 s of a reset and is
  fully formed in seconds (the 2026-10-23 soak: 0.059 at 4 s, 0.091 at 12 s, 0.122 at 30 s).
- **The free run drifts.** With no drive the field's E-mean wanders over tens of seconds
  (dark field with bright knots → bright field with dark knots). Contrast stays healthy (no
  saturation; NF-003), but the plain soft display washes toward an extreme — hence the shipped
  `sharp` default of 0.5 (G4).
- **Drive is E-only, raw additive.** `drive_gain·(scene − 0.5)` rides into the E sigmoid input;
  adding it to I measured identical but unnecessary (T007). Unconnected reads the supplied
  neutral 0.5 exactly (vs_inState flag → `drv_conn`), so an unplugged inlet never biases the
  trip.
- **Imprint speed.** At drive_gain 1.5 a structured scene imprints within ~15 frames (scene
  correlation 0.83 at +0.25 s) and releases within ~1 s of gain 0 (the 2026-10-23 session).
- **One DFT chain, not two.** The four-channel packing carries both fields through a single
  f_vf_fluid-derived DFT chain, so GPU cost is the f_ks class, not 2x: **2.45 ms/frame at
  256² on the bench** (2026-10-23 measurement), comfortably inside NF-001.
- **256² solver is final.** The 128² fallback (spec's NF-001 branch-out) was measured
  unnecessary at 2.45 ms.
- **`grain` not `texture`.** The dial token is `grain`: `texture` is a native jit.gl.pix
  attribute and silently snaps a bound control back to min (live contract-bench find).
- **Self-heal is two-channel.** `pass` reseeds a texel when BOTH channels read exact 0 (context
  loss, a fresh module, an `nl` zap) — a live WC field never honestly holds that.

## Known issues / open

- None at the module level. Phase-3 leftovers: menu placement (T042) and README/`ideas` tidy-up
  (T043) land with this doc.
- The `grain` hint's landmark values (1.1 / 1.4 / 1.9) come from the 2026-10-23 sweep stills;
  coarse grains past ~2.6 wash out under the current display (recorded, Matt approved the
  provisional retinotopy as final).

## Verification

- `tests/modules/wc/test_wc.py` — NumPy mirror, 7/7: pass-chain vs np.fft at N = 32, single-bin
  kernel gains, scalar fixed point, the noise-sustainment ablation (collapse without, contrast
  with), the drive-coupling ordering, unbounded-time boundedness, retinotopic radial constancy.
- `tests/modules/wc/bench_wc.py` — GPU vs mirror, 10/10 with `--slow`: DFT chain 1e-5 of the
  spectrum peak (both field pairs), `spec` 1e-4, `nl` 1.2e-7, `enc` 5.2e-6 at 512², 30-frame
  chain 4.1e-6, 100-frame contrast 0.226 (GPU) vs 0.226 (mirror), cost 2.45 ms/frame.
- Module contract bench (`f_wc` entry): `param` readbacks exact (dt / sig_i / drive_gain /
  sharp), bypass → black A = 1, 10 pix objects, 2/2.
- The tuning instrument `tests/modules/wc/bench_wc_look.py` (soak + grain sweep + drive
  imprint) is retained for future range questions; its job record is
  `tests/jobs/20261023_203051_0cb119`.

## References

- Wilson & Cowan (1972). "Excitatory and inhibitory interactions in localized populations of
  model neurons." Biophysical Journal 12:1–24.
- Ermentrout & Cowan (1979). "A mathematical theory of visual hallucination patterns."
  Biological Cybernetics 34:137–150. The retinotopic log-polar map and the
  stripes/spirals/cobweb taxonomy the ideas file derives from.
- Michael Rule's working webgpgpu noise-sustained Wilson-Cowan demo (the "Psychedelic" corner:
  AEE 16.1, AIE 14.5, AEI 13.7, AII 13.0, HE 3.1, HI 3.5, TE 4, TI 12.5, sigma 2.0/2.9 at
  512²). `tests/records/spike_wc_noise_regions.py` ports it; the region-map finding that killed
  the four-form selector is there too.
- The DFT stages are generated by `src/f_wc/gen_dft.py` from `f_vf_fluid`'s shared template
  (code lines asserted identical to the source).
- Related: `f_ks.md` (same solver architecture, the precedent for the chain and the bench
  template), `f_chladni.md` (bypass convention), `ideas/f_vf_wilson_cowan.md` (the original
  four-form pitch the G1 decision pruned).

## Source Files

`src/f_wc/definition.py`, `src/f_wc/codebox_{seed,pass,dft_fx,dft_fy,dft_iy,dft_ix,spec,nl,enc}.gen`,
`src/f_wc/gen_dft.py`, `package/patchers/f_wc.maxpat`, `.specify/f_wc/{spec,tasks}.md`.
