# Spec: f_wc

_Created: 2026-10-24_
_Status: **REVISION 2 (2026-10-24 night) — read "Revision 2" first; it
supersedes the premises listed there.** Scope originally settled 2026-10-24._
_Origin: `ideas/f_wc.md` — spun out of the f_wc_fft pixelation
discussion (HANDOFF 2026-10-24). Reading the `WC_Example_10_fullscreen.html`
source showed its fine, silky look is structural (solver grid = display grid,
separable-Gaussian coupling, continuous display), and Matt confirmed that look
is the actual target. Written as a sibling of the FFT-chain `f_wc_fft`; on 2026-10-25 it REPLACED that
module (archive: `.specify/superseded/f_wc_fft/`): same model class, different architecture and regime.
Working name was `f_formconstants` (Ermentrout-Cowan's term for the hallucination taxonomy; Matt,
2026-10-24), renamed `f_wc` (Wilson-Cowan) on 2026-10-25. Task and section ids are unchanged._

## Revision 2 (2026-10-24 night, Claude + Matt): parity first, then deviate

### Why this revision exists

A re-read of the reference source (`WC_Example_10_fullscreen.html`,
`lib/gpgpu.js`, `lib/gpugaussian.js`, `lib/gpurand.js`) found that the two
premises the original spec was built on are wrong. Every later decision
(adaptive render-res solver, resize reseed, `sw`/`sh` plumbing, σ clamp in
screen px, switching to the Psychedelic + noise + habituation corner) was
made on top of them. After those decisions the module was being tuned
against a target it no longer resembled, and the live build fails (HANDOFF
2026-10-24 night). Matt concurred with this revision 2026-10-24.

### What the reference actually does (source-traced; each item is the spec)

| # | Fact | Source |
|---|---|---|
| S1 | **Solver is a FIXED 1024 × 1024**, not render resolution. `getRasterGL()` sets `canvas.width = canvas.clientWidth` *before* `make_fullscreen()` runs, while the canvas still has its inline `style="width:1024px;height:1024px"`; every `newBasicFramebuffer` inherits `gl.width`/`gl.height`. Fullscreen/resize only change the CSS size: the browser stretches the 1024² canvas to `max(w,h)` square and crops the overflow. | `gpgpu.js getRasterGL`, `newTexture`; html `main()` call order, `make_fullscreen()` |
| S2 | **8-bit quantization at three points per step**: `floor(255·c + 0.5)/255` on the blur-x output, the blur-y output, and the WC update's E and I (`EncodeFloat`). **CORRECTED 2026-10-24 (T041/T042 measurement): quantization is NOT the sustain mechanism.** At the source's kernel widths the float32 + `s` run sustains exactly like the quantized one; only removing `s` kills the field (`tests/records/spike_fc_parity_sustain.py`). Quantization stays in Phase R for parity (it changes texture character, not liveness); whether it earns a dial is T062. | `gpugaussian.js GPUGaussianMultiBlur` shader; html `wc` shader |
| S3 | **Blur**: `GPUGaussianMultiBlur(gl,1,2,1,1)` → σ_R = 1, σ_G = 2, σ_B = σ_A = 1 texel; ONE shared radius `ceil(3·max σ)` = 6 (so the σ = 1 kernel also spans 13 taps); each channel's weights `exp(−0.5·(i/σ)²)` normalized over [−6, 6]; texel-exact taps (`gl_FragCoord` ± i), REPEAT wrap. | `gpugaussian.js createGaussianConvolution`, `GPUGaussianMultiBlur` |
| S4 | **WC update** (dt 1, Te 10, Ti 20, Aee 10.5, Aie 8.5, Aei 12, Aii 3, He 2, Hi 3.5): `Ve = F(Aee·Uec − Aie·Uic − He + s)`, `Vi = F(Aei·Uec − Aii·Uic − Hi)`, `Ue += (Ve−Ue)·dt/Te`, `Ui += (Vi−Ui)·dt/Ti`; output `(Q(Ue), Q(Ui), |Ue−Ui|·3, 1)` (B stored through an 8-bit target, so clamped to [0,1] and quantized). `s` enters E only. | html `parameters`, `wc` shader |
| S5 | **Drive `s`**: `s = 0.3·(sign(sin(t·π·6.8/500)) + 1)` → a square wave, 0.6 for the first half-period, 0 for the second, period 500/3.4 ≈ 147.06 frames; `t` = frame count from page load. One WC step per frame. | html `animate()` |
| S6 | **Seeding**: one-time uniform uint8 random in all four channels (values k/255). **No per-frame noise. No habituation.** | `gpurand.js GPUNoise.randomize`, html `noise.randomize(U)` |
| S7 | **Map**: z = canvas coordinates mapped to [−1, 1]² of the square canvas; u = (atan2(z.y, z.x), log‖z‖) / 2π; sample the NEW state at u with LINEAR filtering and REPEAT wrap. Bare complex log, conformal: one texture width per revolution. Over most of the visible screen this MAGNIFIES the field (≈1–3× in canvas px, × the CSS stretch ≈1.9 at 1080p), which is where the silky read comes from. The centre minifies and aliases (accepted in the source). | html `retinalmap` shader |
| S8 | **Display is RGB** `(E, I, 3·|E−I|)` straight from the state, no curve, no threshold. The blue channel lights where E and I disagree and draws the contour web. | html `retinalmap` samples all four channels of `temp` |

The Phase 0 Record's statement "solver textures = canvas client size (up to
1920² on a 1080p display)" is WRONG per S1 (verification step in T040).

### Superseded by this revision

FR-001 (render-res state), FR-002's σ-in-screen-px band clamp, FR-003's
Psychedelic + noise + habituation defaults, FR-007's map and sampling,
NF-002 (float32 end to end), NF-005, the Edge Cases resize item, the
Parameters table, Success Criterion 3, Out of Scope items 1 and 2 (color, the
`s` wave), and the "Resolved by design discussion" architecture bullets. They
stay below as history. Where they conflict with Revision 2, Revision 2 wins.

What still holds: US-2 drive semantics (G3, f_wc_fft), US-5 module conventions,
FR-004 (seed from noise, never zero), FR-008 (no NaN at the outlet), FR-009
(reset), FR-011, FR-012, NF-003 (stability soak), NF-004 (tier order).

### Revised architecture (Phase R target: the parity build)

    hold → pass → blur_x → blur_y → wc → hold          (all fixed @dim N N)
    seed → pass (reseed only)        wc → enc (render res)

- **Solver stages are fixed size**, `@adapt 0 @dim N N @type float32`,
  N = 1024 (S1). NO `r dim` reaches any solver stage. NO resize reseed. Every
  codebox that needs the texel grid uses a literal or a Param whose default is
  N, never the gen `dim` global (jit-gen-codebox rule; the 2026-10-24 debug).
  A test asserts the codebox Param defaults equal the definition's @dim.
- **Quantization is in the codeboxes** exactly where S2 puts it. State
  textures stay float32; the quantize makes the values 8-bit-exact.
- **pass**: reseed from seed (uint8-like: `floor(h·256)/255` capped at 1, all
  four channels, S6), otherwise hold. The **"lost" test is the alpha channel**
  (wc writes A = 1; a fresh or reallocated texture reads A = 0), NOT
  "E == 0 and I == 0": in the quantized dynamics both can legitimately be
  exactly 0, and the old self-heal would inject noise into a live field.
  NaN guard stays.
- **wc** (the old `nl`): S4 verbatim, with `s` computed in the codebox from a
  frame-count Param `frameno` (the existing draw counter; NOT named `t`, see tasks T046): `s = s_depth · (fract(frameno ·
  s_rate) < 0.5)`, defaults `s_depth` 0.6, `s_rate` 3.4/500 = 0.0068. (`fract`
  instead of `sin` keeps it exact at large t; the source's t = 0 value 0.3 is a
  single frame and is not reproduced.)
- **enc**: S7 on the module's output size. Square crop on the long axis:
  `L = max(ow, oh)`, `zx = (norm.x·2−1)·ow/L`, `zy = (norm.y·2−1)·oh/L` (`ow`,
  `oh` = output size Params fed by the existing `r dim → route → unpack`).
  Sample the state with the existing manual bilinear + wrap, grid size N
  (literal/Param). Output `(E, I, B, 1)` sampled (S8), `bypass_gate` → black
  A = 1. No `r_soft`, no contrast/sharp in Phase R.
- **Parity build has no performance dials** — only reset and bypass. The
  drive inlet's plumbing may stay in the patcher, but nothing in the wc
  equation reads it in Phase R. Every dial comes back in Phase D, one at a
  time.

The y-axis orientation of jit textures vs. `gl_FragCoord` may mirror the
picture vertically relative to the HTML. That is not a parity failure; note it
and move on.

### Phase D (deviations from the source, after parity passes)

Each deviation is its own task, A/B'd against the parity build and the HTML,
and reversible. Candidates, roughly in value order: output mode (RGB / luma of
E / luma of the B contour channel); breathe dials (`s_depth`, `s_rate`); a
quantization-levels dial (255 default; float = off) as a character control;
conformal zoom (one complex gain, so spiral twist stays conformal) and optional
centre softening; solver size as a load-time choice (512 / 1024 / 2048 —
features are texel-scale, so N sets the look scale); `rate`; the drive inlet
(G3 semantics); coupling dials; and, only if it earns its place in A/B, the
old Psychedelic + noise + habituation "steady web" as a second mode (reference
build: commit `63b6129`).

## Shipped controls (Phase D, 2026-10-25) — supersedes the Parameters table below

Matt confirmed the live defaults as good on 2026-10-25 (T069). Panel 272 × 150, two rows. One texture
inlet (the pulse), one outlet (RGB pattern). Control tokens are prefixed where a bare word collides
with a `jit.gl.pix` attribute (`depth`, `texture`, `output`, `mode`; tasks T061).

| Row | Label | Token | Type / range | Default | What it does |
|---|---|---|---|---|---|
| 1 | Depth | `pulse_depth` | float 0–1.5 | 0.6 | Pulse depth (excitability). 0.6 = the source; 0 fades the field out slowly; ~1.5 kills it fast |
| 1 | Period | `pulse_period` | float 30–600 frames | 147.0588 | Internal square-wave period, used when the pulse inlet is unplugged; under ~100 the field dies |
| 1 | Rate | `sim_rate` | float 0.05–1 | 1 | Slow motion by step skipping; the pulse clock counts solver steps, so the look is unchanged |
| 1 | P.Mix | `pulse_mix` | float 0–1 | 1 | Pulse texture vs the internal wave: 1 = the texture is the pulse, 0 = ignored |
| 1 | P.Gain | `pulse_gain` | float 0–2 | 1 | Pulse texture brightness before it becomes the pulse |
| 1 | Reset | (raw button) | bang | — | Reseed the fields from fresh noise (also on load) |
| 2 | Grain | `grain_scale` | float 0.5–2 | 1 | Blur tap spacing: below 1 finer and wormier, above 1 bigger softer spots, moire near 2 (kept on purpose) |
| 2 | Output | `out_mode` | menu RGB / E / Contour / Luma | E | RGB = the source look; E = activity (spots); Contour = the boundary web; Luma = all three as gray |
| 2 | Input | `pulse_space` | menu Retinal / Unwrapped | Retinal | Where the pulse texture is read: Retinal = it lands where it is seen; Unwrapped = on the flat solver grid |
| 2 | Space | `out_view` | menu Retinal / Unwrapped | Retinal | Retinal = the log-polar form-constant view; Unwrapped = the flat solver grid, to feed `f_droste` |
| header | Freeze | `freeze_on` | toggle | off | Hold the field exactly where it is; off resumes from that state |
| header | Bypass | `bypass` | toggle | off | Black output (A = 1) |

**Fixed, not controls:** solver size N = 1024 (S1), 255-level quantization at the source's three points
(S2), the blur kernels and Example-10 couplings (S3, S4), the retinal map's constants (S7).

**Decided against / moved out in Phase D (do not rebuild):** Quant menu (no visible difference); Inhibit
dial (one narrow band, washes out or dies outside it); Flash "swing" dial and an inhibition-rate damping
dial (the flash is the E–I loop's own bulk oscillation); De-flicker (a downstream utility,
`ideas/f_deflicker.md`); Strike / impulse and Contrast / Sharp (downstream modules); map dials
(zoom / rotate / arms / spiral, T063, overlap `f_droste`; the Unwrapped Space view covers that route);
drive inlet (T066, superseded by the pulse inlet with the Retinal Input space); steady-web mode (T068,
reference build at `63b6129`). T064 (solver size as a load-time choice) is open pending a look
(`tests/records/spike_fc_solver_size.py`).

## Scope settled (2026-10-24, Claude + Matt) — history; see Revision 2

- **New sibling module, not a re-architecture of f_wc_fft.** f_wc_fft's 256² FFT
  chain, its tuned labyrinth corner, and its spots corner (aii 3–6) ship
  unchanged. This module trades f_wc_fft's resolution-independent 256² grid for a
  render-resolution solver with spatial blur coupling — the webgpgpu
  Example-10 pipeline — to reach the fine-grained silky regime f_wc_fft's grid
  structurally cannot (σ_I = 2 display px at fullscreen; f_wc_fft's grain floor is
  ~1 cortical texel ≈ 7 screen px at 1080p).
- ~~**Example-10 coupling constants as defaults**~~ → **AMENDED BY MEASUREMENT
  (Phase 0 T002, 2026-10-24).** The Example-10 fullscreen page is Rule's
  *flicker* preset (Ne = 0 + a slow square-wave bias): its own constants
  measure DEAD at float32 in every configuration we tried (no noise, small
  noise, their own `s` wave) and only survive in a faithful 8-bit-quantized
  port — its live look breathes on quantization decorrelation plus the s
  kick. The float32-native sustaining corner is the **Psychedelic coupling
  set + habituation**: Aee 16.1, Aie 14.5, Aei 13.7, Aii 13.0, He 3.1,
  Hi 3.5, Te 4, Ti 12.5, Ne = 0.75,
  `habituation` ≈ 0.9–1.2 and σ_I in the steady band ≈ 0.75–1.1 screen px
  (measured: flat traces past 4000–6000 frames, dark-field fine webs).
- **Pattern scale in screen pixels, held in the measured band** *(amended
  2026-10-24, Phase 0 T003/T005 — the original "fraction of frame height"
  plan measured DEAD)*. The fine silky regime exists only at σ_I ≈ 0.75–1.1
  SCREEN px (with habituation 0.9–1.2); λ there is set by the nonlinear
  dynamics (16–43 px features), not by the kernel, so a frame-fraction σ
  breaks the regime as windows resize. `grain` maps to σ_frac but is CLAMPED
  per frame into the sustaining σ_px band — a resize reflows the pattern, it
  never leaves the regime (see Edge Cases for state-resize behavior).
- **Luminance display; color out of scope.** The source's
  `vec4(Ue, Ui, |Ue−Ui|·3)` display is a debug view. This module renders E
  through the shared enc map with contrast/sharp, per f_wc_fft's G4; color is a
  downstream module's job.
- **float32 end to end.** The source quantizes state to 1/255 every write
  (`EncodeFloat`) and quantizes the blur output too; this model lives on a
  saturation boundary, so we keep f_wc_fft's precision. (Their quantization also
  acts as stochastic decorrelation — Phase 0 measures whether Example-10's
  noiseless update sustains structure at float32 or needs a small per-frame
  `Ne` default.)

## Why this module, in this library

- The fine/silky web look is confirmed target content (Matt, 2026-10-24) and
  is unreachable from f_wc_fft's grid — this is the cheapest faithful route, and
  it is also likely CHEAPER per frame than the DFT chain it replaces (two
  ~15-tap separable blur passes vs. eight generated stage codeboxes at these
  σ; cost to be measured, NF-001).
- Everything load-bearing is already proven in-repo: the nl equations and
  noise/habituation/drive mechanics (f_wc_fft Phase 0–4), the enc retinotopic
  map stage with foveal softening (f_wc_fft FR-007), the blur-as-convolution
  correctness (f_wc_fft's spec stage is the same Gaussian, evaluated spectrally —
  the mirror cross-checks the spatial form against np.fft trivially).

## Clarifications

### Resolved by design discussion (2026-10-24, Claude + Matt)

- **Architecture: render-res adaptive stages, one feedback loop.** State
  (R = E, G = I; B/A spare for habituation) lives at render resolution,
  `@adapt 1`, through `hold → blur_x → blur_y → nl → hold`, with the enc
  stage sampling it retinotopically at the same resolution. No FFT, no
  fixed-size solver texture, no reconstruction filter — the artifact class
  those existed to manage (contour quantization on a coarse grid) does not
  arise.
- **Blur: separable Gaussian, weights computed inline.** One codebox pair
  (x then y), per-channel widths (R blurred at σ_E, G at σ_I), radius
  `ceil(3σ)`, weights `exp(−i²/2σ²)` evaluated in GenExpr from the σ Params
  (no kernel tables, no array uniforms — jit.gl.pix Params are scalars).
  The source's `GPUGaussianMultiBlur(gl,1,2,1,1)` is exactly this shape.
- **enc stage reuses f_wc_fft's map math** — the bare-log retinotopic resample,
  `r_soft` foveal softening, contrast + sharp output map, `bypass_gate`.
  Copied with header changes; whether a shared enc source gets factored
  (the `gen_dft.py` shared-generator precedent) is a Phase 3 hygiene
  question, not a v1 requirement.
- **Their slow square-wave bias `s` is parked.** Example 10 oscillates
  excitability (period ~500/6.8 frames) to keep the deterministic field
  from settling; the performer's `excite` dial covers the gesture, and
  Phase 0 (T002) measures whether a default per-frame `Ne` covers the rest.
- **Noise at float32: measured, not assumed.** Example 10 injects no
  per-frame noise (its 8-bit quantization decorrelates deterministically);
  f_wc_fft's Psychedelic corner needs noise as the load-bearing mechanism.
  Phase 0 T002 determines the default `energy` for the Example-10
  constants at float32; the dial exists either way.

### Open, not yet decided

- **State behavior on render resize** (see Edge Cases) — reseed vs.
  resample; decided at build time (T013) from what the adaptive feedback
  chain actually does.
- **`energy` default** — T002's measurement (0.0 if the deterministic
  update sustains indefinitely at float32; the measured sustain floor
  otherwise).
- **`habituation` dial in v1** — the math is proven (f_wc_fft G5) and the B/A
  channels are free; staged as gate G1 (Matt) to keep the v1 dial surface
  curated.

## User Stories

### User Story 1 — Fine-grained living hallucination web (Priority: P1)

A performer drops `f_wc` into a patch with no inlets connected and
gets a continuously evolving, fine-grained, silky cortical labyrinth rendered
in visual-field coordinates — the WC_Example_10 look — never settling, never
blocky, at any render resolution.

**Why this priority**: the module's entire reason to exist; the look f_wc_fft
structurally cannot reach.

**Independent Test**: patch `f_wc` alone into `vs_preview` at
default dials. At 1920×1080 the pattern reads as the Example-10 fine web
(tier-3, Matt, side-by-side with the HTML page); at 320×180 it reads as the
same picture at lower detail; no texel-scale staircase on contours at any
`sharp` setting.

**Acceptance Scenarios**:
1. **Given** a freshly loaded module, **When** frames run with no inlets
   connected, **Then** the output sustains a high-contrast living labyrinth
   at the default constants indefinitely (10,000+ frames, no freeze, no
   decay, no blow-up — mirror-verified at test resolution first, NF-003).
2. **Given** the module running at 1080p, **When** the render resolution
   changes (half, then double), **Then** the pattern's visual scale and
   character are unchanged (pattern wavelength in frame-height units
   constant within Phase-0-measured tolerance), with only the state-reseed
   seam visible at the moment of resize (see Edge Cases).
3. **Given** the module running in any regime, **When** more frames run,
   **Then** no NaN/Inf ever reaches the outlet.

### User Story 2 — Driven mode: scene vs. spontaneous web (Priority: P1)

Same contract as f_wc_fft US-2: a texture on the drive inlet modulates the E
sigmoid input; weak drive = hallucinate, strong drive = see; unconnected =
neutral (the pure US-1 web).

**Why this priority**: the performative core, shared with f_wc_fft (gate G3's
semantics carry verbatim).

**Independent Test**: high-contrast moving texture on the drive inlet; sweep
`drive_gain`; output tracks the scene at high gain and ignores it at zero;
disconnect mid-run without a NaN or pop.

**Acceptance Scenarios**:
1. **Given** a structured texture on the drive inlet at `drive_gain` ≥ 1,
   **When** frames run, **Then** the web's structure follows the input
   (bench-measurable imprint correlation, f_wc_fft T032-pattern).
2. **Given** the drive inlet disconnected, **When** frames run, **Then** the
   behavior is exactly US-1 (0.5-neutral substitution via `drv_conn`).

### User Story 3 — Grain and character navigation (Priority: P1)

A continuous `grain` dial moves the web from hair-fine to coarse-mesh,
resolution-independently; `aspect` (σ_E/σ_I ratio) steers ordering
(stripes ↔ labyrinth), carrying f_wc_fft's G6 semantics.

**Why this priority**: the navigation promise; without a steerable grain the
module is one fixed demo preset.

**Independent Test**: sweep `grain` and `aspect` live from a running state;
the mesh size and ordering shift continuously; no reset, no divergence.

**Acceptance Scenarios**:
1. **Given** a running pattern, **When** `grain` sweeps its range,
   **Then** the characteristic wavelength tracks the dial in frame-height
   units (mirror-measured structure-factor peak) at every render size.
2. **Given** the documented spots landmark, **When** frames run from noise,
   **Then** the texture reads as the Example-10 web (tier-3) in at least 4
   of 5 seeds (the seed-variance bound the f_wc_fft sweeps used).

### User Story 4 — Rate, energy, and reset (Priority: P2)

`rate` scales per-frame dt; `energy` (Ne) sets the per-frame noise floor
(default per T002's measurement); reset reseeds from fresh noise.

**Why this priority**: feel controls, f_ks/f_wc_fft precedent.

**Independent Test**: sweep `rate` across its range; hammer reset; no NaN,
no freeze, no cross-instance state.

**Acceptance Scenarios**:
1. **Given** `rate` at maximum, **When** 10,000 frames run, **Then** the
   output stays finite and bounded (relaxation toward a bounded sigmoid: no
   NaN ceiling exists, f_wc_fft T003 — the ceiling is pattern-preservation,
   set at Phase 2 tuning).
2. **Given** a reset mid-run, **When** frames continue, **Then** both fields
   reseed from fresh noise and resume with no seam after the settle time.

### User Story 5 — Standard f_ module behavior (Priority: P3)

Bypass (black A=1 generator neutral), autopattr, `moduleSize`, canonical
names, independent instances.

**Independent Test**: module contract bench; two instances in one patch.

**Acceptance Scenarios**:
1. **Given** bypass on, **When** frames run, **Then** the outlet is black
   A=1 while the solver keeps running (f_chladni generator convention).
2. **Given** a reloaded patch, **When** frames run, **Then** the state
   reseeds from noise on load (never from zero — Edge Cases).

## Requirements

### Functional Requirements

- **FR-001**: The module MUST hold persistent two-field state `(E, I)` in
  one texture (R = E, G = I; B/A reserved for habituation per G1) across
  frames in a one-frame feedback loop AT RENDER RESOLUTION (`@adapt 1`
  solver stages; the f_wc_fft FR-013 decoupling is deliberately reversed —
  solver res = render res is the point).
- **FR-002** *(amended 2026-10-24, Phase 0 T003/T005)*: The coupling
  convolution MUST be a real-space separable Gaussian: two stages
  (`blur_x`, `blur_y`), each applying `exp(−i²/2σ²)` weights over
  `i ∈ [−⌈3σ⌉, ⌈3σ⌉]`, normalized, with wrap (periodic) sampling, σ_E on
  the R channel and σ_I on the G channel simultaneously. σ in SCREEN PIXELS:
  nominally `σ_frac · min(dim.x, dim.y)` from the `grain` dial, CLAMPED per
  frame into the measured sustaining band σ_px ∈ [0.75, 1.4] (below = dead
  kernel taps / above = saturation at the shipped habituation; the band is
  the T003 map's diagonal corner). NO FFT/DFT chain in this module.
- **FR-003**: The `nl` stage MUST compute, per frame:

      E += (F(AEE·(σ_E blur E) − AIE·(σ_I blur I) − HE + Ne·N
              + drive_gain·(drive − 0.5) − habit·Ve + excite) − E)·dt/TE
      I += (F(AEI·(σ_E blur E) − AII·(σ_I blur I) − HI + Ne·N
              − habit·Vi + excite) − I)·dt/TI
      Ve += (E − Ve)·dt/50        Vi += (I − Vi)·dt/100

  *(amended 2026-10-24, Phase 0 T002)*: with F the logistic sigmoid and the
  measured PSYCHEDELIC defaults AEE = 16.1, AIE = 14.5, AEI = 13.7,
  AII = 13.0, HE = 3.1, HI = 3.5, TE = 4, TI = 12.5, dt0 = 1 — the
  originally specced Example-10 constant set (10.5/8.5/12/3, He 2.0) measured
  DEAD at float32 in every configuration (it is the webgpgpu *flicker*
  preset: 8-bit quantization + an `s` square wave are its sustain
  mechanisms, and the quantized+s port is the only variant that breathes;
  recorded in tasks.md T002). `N` is fresh Gaussian noise per frame
  (√dt-scaled, both sigmoid inputs); **Ne default = 0.75 and `habituation`
  default ≈ 0.9, both load-bearing at fine grain — without habituation the
  field saturates by ~3000 frames even at Ne = 0.75.** Ve/Vi ship in v1
  (G1 measured, not gated). The drive term is E-only with the f_wc_fft G3
  semantics (unconnected = 0.5-neutral via `drv_conn`). `excite` carries
  f_wc_fft G7's shared threshold offset; the source's `s` square wave stays
  parked (performed via `excite`; measured non-sustaining alone at float32).
- **FR-004**: State MUST seed from random noise on load and on reset —
  never zero, never uniform rest (f_wc_fft FR-004's guard; same model class,
  same fixed-point asymmetry).
- **FR-005**: `rate` MUST scale per-frame dt. No NaN clamp (bounded
  sigmoid); the ceiling is pattern-preservation, set at Phase 2.
- **FR-006**: The drive inlet MUST couple raw-additively into the E sigmoid
  input as `drive_gain·(scene − 0.5)`; an unconnected inlet reads BLACK in
  a pix chain (f_wc_fft build-time finding), so the inlet runs through a
  vs_inState whose connection flag sets `drv_conn`, and nl substitutes
  0.5 when unconnected. `drive_gain` is a `gain`-role dial.
- **FR-007**: The render stage MUST apply f_wc_fft's inverse retinotopic
  (log-polar → Cartesian) resample to the state at render resolution,
  including the `r_soft` foveal softening (the log-map singularity
  otherwise aliases the center into a vortex — the source demo has this
  defect; we do not) and the contrast + sharp display mapping (f_wc_fft G4/G8a).
  Sampling here is ordinary `sample()` — state and render grids coincide,
  so hardware LINEAR is exact and NO manual reconstruction (taps, weights,
  wrap arithmetic) carries over.
- **FR-008**: The output MUST be bounded grayscale with no NaN/Inf at the
  outlet; non-finite state zaps per the f_ks/f_wc_fft containment precedent.
- **FR-009**: A reset trigger MUST re-randomize both fields from fresh
  noise without reloading the module.
- **FR-010**: `grain` MUST set the pattern scale continuously via σ_frac
  (FR-002), with `σ_E = σ_I / sig_ratio` slaved to the `aspect` dial
  (f_wc_fft G6 semantics and landmarks carry, re-measured for FR-002's form
  in Phase 0). Documented landmarks MUST be reachable; there is no
  discrete form selector (f_wc_fft gate G1's finding applies to the model
  class).
- **FR-011**: All object names MUST be `#0_`-scoped.
- **FR-012**: Standard bpatcher conventions and canonical parameter naming.
  The σ Params MUST NOT be named `texture` (jit.gl.pix native-attribute
  collision, f_wc_fft FR-010's live-bench finding) — the dial token is `grain`.

### Non-Functional Requirements

- **NF-001** *(target, pending measurement)*: per-frame cost at 1920×1080
  measured on Matt's machine and reported against f_wc_fft's 2.45 ms (256²) as
  the reference point. Hypothesis (not a finding): two ~15-tap separable
  passes + nl + enc is sub-ms to few-ms class; 4K and tiny windows measured
  too, since σ_px and the tap count scale with resolution.
- **NF-002**: float32 end to end (deliberate departure from the source's
  8-bit `EncodeFloat` state).
- **NF-003**: No NaN/Inf after 10,000 frames at `rate` extremes, every
  mapped regime, with and without drive and resets.
- **NF-004**: Verification tiers: Phase 0 NumPy mirror first (tier 1 —
  closed forms exist: Gaussian-blur sums, single-mode decay, structure
  factor), then frame-exact bench vs. mirror (tier 2), then tier-3 look
  gates — headline gate: side-by-side against `WC_Example_10_fullscreen.html`
  itself (Matt).
- **NF-005** *(amended 2026-10-24, Phase 0 T005 — the frame-fraction version
  measured DEAD)*: Resolution independence of the REGIME, not of the
  wavelength: at every render size the field MUST stay inside the measured
  sustaining band (σ_px ∈ [0.75, 1.4] via the FR-002 clamp; habituation at
  its shipped corner), and pattern features are pixel-scale by design
  (measured λ 16–43 px). Features do NOT grow proportionally with window
  size — the look is fine silk at every size, and resize only reflows it.

## Parameters (proposed — final set fixed by Phase 0 / gate G1)

| Dial | Underlying | Notes |
|---|---|---|
| `grain` | σ_frac → σ_I,px, clamped to the sustaining band (FR-002) | regime selector (T003: λ is dynamics-set, not kernel-set, in the fine regime): fine silk → pulsing cells → (clamped) coarse ends; Phase 2 sets semantics + landmarks live |
| `aspect` | `sig_ratio` (σ_E = σ_I / sig_ratio) | f_wc_fft G6 semantics; stripes ↔ ordering; landmarks re-measured at render-res physics in Phase 2 |
| `energy` | per-frame noise amplitude `Ne` | **default 0.75 (measured T002 — load-bearing, not optional)**; the drive-band axis (f_wc_fft T005/T052) |
| `excite` | shared offset in both sigmoid inputs (HE/HI lowered together) | f_wc_fft G7 semantics; covers the source's parked `s` square wave as a performer gesture |
| `drive_gain` | gain on the drive inlet term | weak = hallucinate, strong = see (G3) |
| `habituation` | Ve/Vi subtractive adaptation depth | **default ≈ 0.9; load-bearing — without it the field saturates by ~3k frames (T002). Ships in v1 (G1 measured, pending Matt's confirm)**; steady band needs σ_I ≤ 1.1 px at high habit (T003) |
| `contrast` | display stretch about mid-gray in enc | f_wc_fft G8a; note the source gets its "pop" from 8-bit + no curve — ours comes from this + `sharp` |
| `sharp` | S-curve blend on the display | f_wc_fft G4 |
| `zoom` / `twist` / `fovea` | map constants `k_ecc` / `k_ang` (INT) / `r0`; `r_soft` bench-vary | f_wc_fft FR-007 carries verbatim (defaults from the T004 stills: the closer set 5/3/1.0 read best at the fine scale; r_soft 0.35) |
| `rate` | dt multiplier | FR-005 |
| `reset` | reseed | FR-009 |

## Success Criteria

1. **The look (tier 3, headline)**: side-by-side against
   `WC_Example_10_fullscreen.html` at the same window size, the module
   reproduces the fine-grained silky web to Matt's judgment — INCLUDING at
   high `sharp`, with no texel-scale staircase (the f_wc_fft failure mode).
2. **Sustained structure**: from noise seeding at the default constants the
   web persists indefinitely in the mirror (std and spectral peak stable
   over 10,000-frame soak; T002 fixes whether that needs `Ne` > 0).
3. **Resolution independence**: pattern wavelength in frame-height units
   constant across render sizes (320² to 4K) within Phase-0 tolerance
   (NF-005), mirror-verified and live-eyeballed.
4. **Frame-exact bench**: multi-frame runs of the real codeboxes match the
   NumPy mirror within the standard tolerance at fixed render size (blur
   exactness carries the f_wc_fft spec-stage tolerance class).
5. **Drive transition**: input/output imprint correlation high at strong
   drive, ~0 at zero drive (f_wc_fft T032-pattern leg).
6. **Stable**: NF-003's 10,000-frame statement, plus resize mid-run
   produces the specified reseed/resample seam and nothing else.
7. **Cost measured and within budget** at 1080p on Matt's machine (NF-001);
   4K and 320² reported with it.
8. **Distinct from f_wc_fft (tier 3)**: the two modules' default outputs are
   visibly different content families (fine web vs. chunky labyrinth), so
   the sibling relationship is justified in the menu/README.

## Edge Cases

- **Render resize mid-run**: adaptive-res feedback state is destroyed or
  resampled by the resize. v1 accepts a reseed seam (state restarted from
  noise with the same dials; the picture re-forms within the settle time) —
  but the chain MUST handle it deliberately (size-change detector → reseed
  path), not accidentally. Resizing MUST NOT corrupt the feedback loop,
  freeze, or NaN. Alternative if the reseed flash proves ugly live:
  resample the old state through the map into the new size (decided at
  T013 from what the adaptive hold actually does).
- **Very small render sizes**: σ_px = σ_frac·min(dim) shrinks below ~0.75 px
  where the discrete kernel radius collapses to ~1 tap; σ_px MUST clamp to a
  floor (≥ ~0.75) so the blur never degenerates to identity, accepting that
  pattern scale then exceeds the dial's nominal value.
- **Uniform rest / below-threshold quiet**: same fixed-point asymmetry as
  f_wc_fft — a too-clean state in a below-threshold regime decays quiet; FR-004
  noise seeding is the guard, and quiet-under-threshold is correct dynamics
  (US-2's below-threshold behavior is "shows the drive").
- **Drive inlet hot-plug**: connecting/disconnecting mid-run must not NaN
  (`drv_conn` guard, f_wc_fft precedent).
- **Habituation state on reset**: if G1 ships, Ve/Vi restart at 0 on
  reseed (f_wc_fft G5's rule).
- **`twist` integer-only**: fractional wrap gains seam the map at θ = ±π
  (f_wc_fft T006); the dial stays INT.

## Open Experiments (Phase 0 — none yet run)

1. **Mirror + blur exactness** (`tests/records/spike_wc_steadyweb_mirror.py` graduating
   to `tests/modules/wc/wc_steadyweb_mirror.py`): separable Gaussian vs.
   analytic Gaussian convolution; single-mode decay rates with couplings
   zeroed (f_wc_fft T002's pattern); boundedness.
2. **Sustain at the Example-10 constants, float32, NO explicit noise** —
   the load-bearing experiment. Example 10's page injects no per-frame
   noise and leans on 8-bit quantization + the `s` square wave; f_wc_fft's
   Psychedelic corner collapses without noise. Measure at the Example-10
   constants: does the structure persist indefinitely at float32 from
   noise seeding? Output: the `energy` default and whether an internal
   slow excite-LFO (the parked `s`) is actually needed.
3. **λ(σ) calibration table**: structure-factor wavelength vs. σ_frac at
   the shipped constants — fixes the `grain` dial mapping (FR-002) and the
   NF-005 tolerance band.
4. **Retinotopic look stills**: the mirror's field at the Example-10 fine
   scale through the shared map (reuse `tests/records/wc_retinotopy.py`);
   judge the look offline before any Max session (the parity defaults
   shipped for f_wc_fft were tuned on the chunky field; the fine web may want
   a different corner).
5. **Resize-invariance check**: mirror run at (say) 128² and 256² with
   σ_frac held constant; measure wavelength drift and regime drift —
   bounds the NF-005 claim and informs the reseed-seam decision.

## Proposed Phasing

- **Phase 0** — Experiments 1–5 + gate G0 (defaults: `energy`, grain range,
  parity-map corner) + G1 (habituation in v1: Matt).
- **Phase 1** — codeboxes (blur pair, nl, hold/seed, enc copy), definition,
  build (FIRST: confirm the build system's adaptive-res feedback pattern —
  f_ks/f_wc_fft run fixed-res stages; adaptive feedback is Vsynth-standard but
  new to the pix_chain builder: T011), bench vs. mirror, module contract
  bench, cost (NF-001 at 1080p/4K/320²), resize handling (T013).
- **Phase 2** — live tuning (tier 3): AB vs. the HTML page, grain/aspect
  ranges + landmarks, drive feel, map corner for the fine web, `rate`
  ceiling.
- **Phase 3** — reference doc, helpfile, menu (Patterns, after f_wc_fft),
  README row, INDEX flip.

## Out of Scope (This Version)

- Color display modes (the source's `vec4(Ue, Ui, |E−I|)` debug coloring) —
  grayscale out; color is downstream tooling.
- The `s` slow square-wave excitability bias as a built-in LFO (parked;
  measured for necessity at T002, performed via `excite` regardless).
- Vecfield / gradient outlets.
- Runtime-selectable solver resolution (solver res IS render res).
- Migrating f_wc_fft onto this architecture (f_wc_fft ships unchanged; if this
  module lands, that question can be revisited on its own merits).
- Shared-source factoring of the enc stage across the two modules (Phase 3
  hygiene question).
