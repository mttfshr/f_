# f_wc

**Type:** Generator (pulse inlet, RGB out) — **temporal / has memory**
**Status:** Built, benched and live-checked through Phase D (Matt confirmed the live defaults 2026-10-25). Phase 0 (constants measured), Phase R (the parity rebuild) and Phase D (performance controls) are closed (control set approved 2026-10-25; T064 dropped, solver fixed at 1024). The Phase 2 soak (T024) was done by Matt live on 2026-10-25, so the README row carries no ⚠.

_Renamed from `f_formconstants` on 2026-10-25. Reference written 2026-10-25 from `src/f_wc/` (definition + codeboxes), `.specify/stable/f_wc/{spec,tasks}.md` and the module's tests. Where the spec and the shipped module differ, this doc and `tasks.md` follow the shipped module (spec Revision 2 and its "Shipped controls" section are the current spec)._

---

## What it does

A faithful port of Michael Rule's `WC_Example_10_fullscreen.html` webgpgpu page: a **Wilson-Cowan
excitatory/inhibitory solver** on a **fixed 1024 × 1024** float32 grid, shown through the bare
complex-log retinal map, so the pattern reads as the fine, silky "form constant" web of a visual
hallucination (honeycombs, tunnels, spirals, cobwebs). It looks like the page and keeps itself alive the
way the page does: a slow square-wave drive `s` on the excitatory population, no noise.

It is an **"outstanding simulation, not a performable module"** (Matt, 2026-10-24) with a small set of
performance surfaces: the **pulse** (Depth, Period, or a texture on the pulse inlet), **Rate** (slow
motion), **Freeze**, and the **Output / Input / Space** menus. Kill-and-revive is a feature: pushing the
pulse too hard kills the field, and easing off brings a pattern back from the next seed or the next pulse.

It outputs an RGB texture (see Output). It does not output a vecfield.

Typical use: patch it alone as a living background; feed a camera or a Vsynth WFG into the pulse inlet
to make the web follow the image; set Space to Unwrapped and patch the output into `f_droste` (or any
downstream wrap) for the flat cortical grid.

Replaces the old FFT-chain `f_wc_fft` (a 256² solver with a noise-sustained labyrinth and many more dials;
archived in `docs/f-reference/superseded/f_wc_fft.md`): this module trades that one's resolution-independent grid and
tuning surface for the page's fine-grained look.

---

## Signal Flow

One control inlet (messages and the draw bang), one **pulse** inlet (texture, optional), one outlet.

```
hold -> pass (in 1)         seed -> pass (in 2)
pass -> blur_x -> blur_y -> nl (in 1) ;  pass -> nl (in 2) ;  pulse -> nl (in 3)
nl -> hold (the feedback edge)
nl -> enc (in 2) -> outlet
```

| Stage | Job |
|---|---|
| `hold` | Identity. One-frame delay, the loop break |
| `seed` | Hash noise (arithmetic, no `sin()`): uniform uint8-like values in all four channels, `salt` advanced per RESET only |
| `pass` | Holds the last state (R = E, G = I, B = contour, A = 1 flag), or reseeds from `seed` when `reseed` = 1. A texel whose alpha is 0 is lost and reseeds too. NaN guard |
| `blur_x` `blur_y` | Separable Gaussian coupling, σ (1, 2) with a shared 13-tap radius, per-channel weights, wrapped, quantized to 255 levels; Grain spaces the taps |
| `nl` | The page's `wc` shader (Example-10 constants, dt 1): relaxation toward the sigmoid of the coupled fields, the `s` pulse on E only, Freeze and Rate gating, 255-level quantization |
| `enc` | The retinal map on the **output** size: square crop on the long axis, `(atan2, ln r) / 2π`, bilinear + wrap; Output menu; bypass gate |

The solver stages are `@adapt 0 @dim 1024 1024` and **no `r dim` message reaches them**: the page's
solver never follows the window, so a resize does not reseed and the pattern scale is fixed relative to
the solver grid. Only `enc` follows the render size (and, as plain Params, `nl` for the Retinal Input
space). Every codebox takes the grid size from a Param `n` (default 1024), never the gen `dim` global.

The frame counter (`frameno`, from `r draw`) drives the square wave; it wraps at 1,000,000 frames
(~4.6 h at 60 fps), with one phase jump then.

---

## Parameters

Panel 272 × 150, two rows. Control tokens are prefixed where a bare word collides with a `jit.gl.pix`
attribute (`depth`, `texture`, `output`, `mode`); the labels are what the panel shows.

| Label | Token | Type | Range | Default | Description |
|---|---|---|---|---|---|
| Depth | `pulse_depth` | float | 0.0–1.5 | 0.6 | Pulse depth, i.e. the excitability level added to E. 0.6 is the source; 0 fades the field out over ~1000 frames; ~1.5 (or a steady 0.6) kills it |
| Period | `pulse_period` | float | 30–600 frames | 147.0588 | Internal square-wave period, used when the pulse inlet is unplugged. 147 is the source (500/3.4). Under ~100 the field dies |
| Rate | `sim_rate` | float | 0.05–1.0 | 1.0 | Slow motion by **step skipping**: the solver advances on a fraction of the frames and the pulse clock counts solver steps, so the look is unchanged (a smaller `dt` would freeze under quantization) |
| P.Mix | `pulse_mix` | float | 0.0–1.0 | 1.0 | Pulse texture vs the internal wave: 1 = the texture is the pulse, 0 = ignored, between = blend. No effect unplugged |
| P.Gain | `pulse_gain` | float | 0.0–2.0 | 1.0 | Scales the pulse texture's luma before it becomes the pulse: raise a dim image, tame a bright one |
| Reset | `reset` | button / message | — | — | Reseeds the state from fresh noise. Fires once on load (after 200 ms). Also accepted as a `reset` message |
| Grain | `grain_scale` | float | 0.5–2.0 | 1.0 | Blur tap spacing (same 13 taps): below 1 finer and wormier, above 1 bigger softer spots; above ~1.5 the spaced taps alias into a moire (kept on purpose). 1 = the source lattice exactly |
| Output | `out_mode` | menu | RGB / E / Contour / Luma | E | RGB = the source look (E, I, contour). E = the activity (spots). Contour = the boundary web. Luma = all three as gray |
| Input | `pulse_space` | menu | Retinal / Unwrapped | Retinal | Where the pulse texture is read. Retinal = through the inverse of the display map, so the image lands where you see it and the pattern grows out of it. Unwrapped = on the flat solver grid (WFG bands become rings or spokes) |
| Space | `out_view` | menu | Retinal / Unwrapped | Retinal | Retinal = the log-polar form-constant view. Unwrapped = the solver grid itself (angle across, log-radius up, periodic in both axes), to feed `f_droste` |
| Freeze | `freeze_on` | header toggle | 0/1 | 0 | Holds the field exactly where it is (the display keeps rendering); off resumes from that state |
| Bypass | `bypass` | toggle | 0/1 | 0 | Black, alpha 1, on the outlet. The solver keeps running underneath, so releasing bypass resumes a warm field |

The pulse inlet: a texture, optional. **Unconnected**, a vs_inState flag (`pulse_conn` = 0) selects the
internal square wave. **Connected**, `s = depth × mix(square, P.Gain × luma, P.Mix)`, with Rec. 709 luma,
read with normalized coordinates (any input size).

Internal, never set by hand: `reseed`, `salt` (reset logic), `frameno` (the draw counter), `pulse_conn`
(pulse connection flag), `bypass_gate` (bypass jsui), `ow` / `oh` (output size, from `r dim`).

**Fixed, not controls:** solver size 1024², the 255-level quantization at the page's three points, the
blur kernels, the Example-10 couplings (Aee 10.5, Aie 8.5, Aei 12, Aii 3, He 2, Hi 3.5, Te 10, Ti 20),
the retinal map's constants.

---

## Settings groups (Depth / Period / Grain)

Five starting points, measured at the module's real solver size (N 1024, from a reset, mirror
`tests/records/spike_fc_presets.py`) and confirmed distinctive live (Matt, 2026-10-25). They are a
table, **not a preset menu** (Matt's call): set the three dials by hand. Press Reset after changing
Grain: a formed field reshapes slowly.

| Group | Depth | Period | Grain | What it looks like |
|---|---|---|---|---|
| A source | 0.6 | 147 | 1.0 | The page's own look. Alive, forms in ~620 frames |
| B fine rolls | 0.9 | 147 | 0.6 | Finer, rolling stripes; the fastest to form (~330 frames) |
| C big cells | 0.6 | 294 | 1.6 | Big soft cells; slow to emerge (~1200 frames, ~20 s at 60 fps) |
| D slow breath | 0.4 | 450 | 1.0 | Forms, then fades between breaths: an in/out breathing pattern |
| E moire | 0.8 | 147 | 2.0 | The moire end of Grain, kept on purpose |

A fast, hard pulse (Depth 1.25 with Period 110) dies at once; that is the kill gesture, not a bug.

---

## Algorithm

Each frame (one solver step per frame at Rate 1), with E, I the two fields and `cE`, `cI` their blurs:

1. **Blur.** Separable Gaussian, σ = 1 on E and σ = 2 on I (the contour channel uses σ = 1), 13 taps, wrapped,
   each tap output quantized to 255 levels. Grain multiplies the tap spacing.
2. **Relax.** `Ve = F(10.5·cE − 8.5·cI − 2.0 + s)`, `Vi = F(12·cE − 3·cI − 3.5)`;
   `E += (Ve − E)·dt/10`, `I += (Vi − I)·dt/20`, dt = 1, `F` the logistic. `s` enters E only.
3. **Contour.** `B = clamp(3·|E − I|, 0, 1)` from the unquantized updated fields.
4. **Quantize.** The state `(E, I, B, 1)` is stored at 255 levels, as the page does through an 8-bit target.
5. **Drive.** `s = depth × (fract(simt / period) < 0.5)`, with `simt = floor(frameno × Rate)` the solver
   clock. At the defaults: 0.6 for the first half-period, 0 for the second, period ≈ 147 frames.
6. **Rate / Freeze.** A frame steps only when `floor((frameno + 1)·Rate) > simt` and Freeze is off;
   otherwise `nl` writes its incoming state back unchanged.
7. **Display.** `enc` maps the screen to the solver grid: `z` on the square crop of the frame,
   `u = (atan2(z.y, z.x), ln |z|) / 2π`, bilinear sampling with wrap. Output E / Contour / Luma / RGB.
   Over most of the frame this **magnifies** the field (about 1–3×, plus the display stretch), which is
   where the silky read comes from; the centre minifies and aliases, as in the source.

No noise, no habituation: the square-wave drive is the liveness mechanism. Removing `s` kills the field
in float32 and in the quantized run alike (`tests/records/spike_fc_parity_sustain.py`); quantization
changes texture character, not liveness.

---

## Notes

- **Reset is slow, on purpose.** The reference dynamics start with a ~600-frame near-uniform transient
  and the pattern then emerges; slow reset is a feature, with no dead-zone guard and no fix intended.
- **The flashing is the simulation.** The E–I loop's own bulk oscillation (frame-mean E swinging about
  0.07 to 0.6, ~80 frames free-running, locked to the pulse period) is inseparable from the pattern.
  Measured and rejected as a control (`tests/records/spike_fc_flash.py`, `spike_fc_damping.py`): a
  "swing" dial does not reduce it, and damping through the inhibition rate leaves only the page's value
  alive. A de-flicker belongs downstream (`ideas/f_deflicker.md`).
- **Pulse = excitability.** Depth acts as an excitability level (`tests/records/spike_fc_pulse_shapes.py`);
  every kill and revive is reachable on purpose.
- **Retinal Input vs Unwrapped.** A camera in Unwrapped space arrives distorted into log-polar; Retinal
  (the default) reads the texture through the inverse of the display map, so what you see is where it lands.
  Mismatch at the frame edge between the GPU's wrap and the mirror's clamp is the only measured residue.
- **Unwrapped Space for `f_droste`.** The cortical grid is periodic in both axes, so it tiles seamlessly;
  this is the route for wrapping the web (zoom / rotate / arms / spiral were NOT built here for that reason).
- **`sample()` returns the nearest texel on these inputs** (measured 2026-10-25, T075), so the pulse is read
  nearest, not bilinear. The mirror models bilinear, which may be part of the noise-texture residue in the
  bench (the Screen-pulse leg's random-noise case, 4 levels / 2.09%, is reported only, not gated).
- **A Param named `t` is never applied** in a `jit.gl.pix` codebox (found at T046): the frame counter is
  `frameno`. The dial-name trap likewise: `depth` bound to a pix attribute and became an Int 0–1, so the
  controls carry prefixed tokens. Both are in `skills/jit-gen-codebox/SKILL.md`.
- **Chain tolerance.** GPU vs mirror stage by stage: R, G within 1 level, B within 3 (B = 3|E − I| triples
  inherited flips), A exact, ≤ 0.1% of values differing; each frame is stage-exact given identical input.
- **Orientation.** The picture may be mirrored vertically relative to the HTML page; that is not a parity
  failure.
- **Cost.** About 1.07 ms/frame at 1080p and 1.54 ms at 4K (N 1024); N 2048 measured 2.04 / 2.47 ms (upper
  bounds). f_wc_fft is 2.45 ms. Cost is not a constraint.
- **Taken out, do not rebuild:** Quant menu (no visible difference), Inhibit dial (one narrow living band),
  Flash / damping dials (above), De-flicker (downstream), Strike / impulse and Contrast / Sharp (downstream
  modules), map dials (overlap `f_droste`), the drive inlet (superseded by the pulse inlet), and a
  steady-web mode (the old Psychedelic + noise + habituation build, git `63b6129`).

## Known issues / open

- **Solver size** is fixed at 1024 (T064 dropped 2026-10-25: at N 512 / 1024 / 2048 the dynamics are identical and only the scale
  changes, `tests/records/spike_fc_solver_size.py`; Grain already scales the pattern).
- `bench_wc_look.py` captures no outlet output in the module bench although the module renders live (a
  bench-side capture bug; first suspect the float32 output vs the capture matrix).
- Very slow Rate settings step visibly (the state holds between solver steps); an enc blend could smooth it.

## Verification

- `tests/modules/wc/test_wc_parity.py` — NumPy mirror (`wc_parity_mirror.py`), 19/19: blur,
  `wc` step, pulse shapes, Rate clock, Screen / Unwrapped coordinates (round trip lands on the same texel),
  Cortical view at N × N equals the state and tiles seamlessly.
- `test_wc_codebox_static.py` 7/7: codebox Param defaults equal the definition's `@dim`, no `r dim` reaches
  a solver stage, hash and weight guards.
- `tests/modules/wc/bench_wc.py` — GPU vs mirror, 14/14 incl. `--slow`: stage legs
  within 1 level, 150-frame E std / mean on the GPU equal the mirror to four digits, cost legs, plus legs for
  Rate, Grain, Output, the Retinal pulse and the Unwrapped view.
- Module contract bench, drift (16/16 reproduce exactly), launch and menu tests green.
- The look gate (T048): "almost exactly perfect" against the HTML page, ran 3 minutes live and stays alive.

## References

- Wilson & Cowan (1972). "Excitatory and inhibitory interactions in localized populations of model
  neurons." Biophysical Journal 12:1–24.
- Ermentrout & Cowan (1979). "A mathematical theory of visual hallucination patterns." Biological
  Cybernetics 34:137–150. The retinotopic log-polar map and the stripes / spirals / cobweb taxonomy.
- Michael Rule's webgpgpu `WC_Example_10_fullscreen.html` and `gpgpu.js` / `gpugaussian.js`: the
  pipeline, constants and display map this module ports (algorithm used directly; the float32 state, the
  pulse inlet and the Phase D controls are this repo's additions).
- Related: `superseded/f_wc_fft.md` (same model family, FFT chain, many dials), `f_droste.md` (the downstream wrap for the
  Unwrapped view), `ideas/f_deflicker.md`.

## Source Files

`src/f_wc/definition.py`, `src/f_wc/codebox_{seed,pass,blur_x,blur_y,nl,enc}.gen`,
`package/patchers/f_wc.maxpat`, `package/help/f_wc.maxhelp`,
`.specify/stable/f_wc/{spec,tasks}.md`, `tests/modules/wc/`.
