# Spec: f_tf_tensormap

_Created: 2026-10-16_
_Status: Draft_

_Promoted from `ideas/f_tensorfield.md` (the family hub; read it for the full
survey, consumer audit, and rejected alternatives). That file moved this
concept OUT of `.specify/` on 2026-10-10 because it was mostly open
questions. The producer's open questions are now resolved or reduced to
three small, non-architectural ones (see Open Questions), which is the bar
for a spec. Consumer-side work (f_vf_glow, f_stipple, f_grain, etc.) is NOT
in this spec; it lives in the hub doc._

---

## What it does

A structure-tensor producer. Takes any scalar-dominant texture and derives a 2x2 symmetric structure tensor from its local gradient: the classic computer-vision measure of local orientation AND how strongly that orientation is expressed. A vector answers "which way"; this answers "which way, and how much does that mean here."

**Producer in the tensor-field family**, the analog of `f_vf_fieldmap` in the vecfield family. Same input shape (any scalar-dominant texture: `jit.gl.bfg`, f_grain, f_stipple, luma of a video source), different output.

**Processor archetype, `driving_inlet`.** Requires input; no self-generating mode. Inlet 0 carries the driving texture and all control messages combined (see `ideas/module_taxonomy_standardization.md`).

**Two outlets, one computed pass.** Not a producer plus a separate bridge module: the eigendecomposition of a 2x2 symmetric matrix is closed-form and cheap.

1. **Outlet 0, raw tensor**: Jxx, Jxy, Jyy, lossless. No consumer today; this is what a future glyph-field renderer or photoelastic module would need.
2. **Outlet 1, decoded convenience, packed RGBA**: R = cos 2theta, G = sin 2theta, B = trace, A = anisotropy. Direction is angle-doubled so theta and theta+pi map to the same stored value (fixes the storage ambiguity only; decoding is the consumer's job, see hub doc "The sign/branch-cut problem").

**Packed-convenience shape DECIDED 2026-10-13 (Matt)**, replacing the earlier three-outlet split. Reason: every real candidate consumer wants a packed pair from this set (f_vf_glow: trace + anisotropy; f_stipple: direction + anisotropy), so one consumer takes one inlet and reads whichever channels it needs.

**Explicitly rejected:** smuggling tensor data into unused vecfield channels of existing producers (e.g. the B channel `f_mobius` ignores). It would create two ordinary-looking vecfield textures meaning different things depending on which module made them: the same bug shape `module_taxonomy_standardization.md` already caught once.

---

## Field Architecture

```
// gradient: the project's own verified 3x3 Sobel (.specify/stable/f_vf_sobel/spec.md)
// luma = 0.299r + 0.587g + 0.114b (Rec. 601), same as f_vf_fieldmap / f_vf_sobel
gx, gy = sobel(luma(in0))

// structure tensor: smooth the per-pixel outer product over a neighborhood
Jxx = box_smooth(gx*gx, radius)
Jxy = box_smooth(gx*gy, radius)
Jyy = box_smooth(gy*gy, radius)

// closed-form 2x2 symmetric eigendecomposition
trace = Jxx + Jyy
diff  = Jxx - Jyy
root  = sqrt(diff*diff + 4*Jxy*Jxy)
lambda1 = 0.5 * (trace + root)        // larger eigenvalue
lambda2 = 0.5 * (trace - root)
coherence = root / trace              // = (lambda1-lambda2)/(lambda1+lambda2), in [0,1]; 0 where trace ~ 0
                                      // (normalized, as in tests/spike_structure_tensor_range.py; contrast-independent)
theta   = 0.5 * atan2(2*Jxy, diff)    // principal (across-edge) axis
```

**Outlet 0 encoding (raw tensor):**

```
R = clamp(Jxx * strength, 0, 1)             // diagonal terms >= 0: unipolar
G = clamp(Jxy * strength * 0.5 + 0.5, 0, 1) // cross term is signed: 0.5 = zero
B = clamp(Jyy * strength, 0, 1)
A = 1.0
```

**Outlet 1 encoding (decoded convenience):**

```
R = clamp(cos(2*theta) * 0.5 + 0.5, 0, 1)
G = clamp(sin(2*theta) * 0.5 + 0.5, 0, 1)
B = clamp(trace * strength, 0, 1)
A = coherence                               // already in [0,1]; no gain
```

**Undefined-direction case.** Where the tensor is isotropic (trace below a small epsilon), theta is mathematically undefined (atan2(0,0)). R and G MUST output the neutral 0.5/0.5 there rather than whatever angle the GPU's atan2(0,0) happens to return, so a consumer can never read an arbitrary direction out of a flat region. This matches the neutral-is-0.5 convention used across the library.

**Why Sobel:** reuses a kernel already verified on the bench (`f_vf_sobel`, 2026-06-18) and already matched in the NumPy spike. Scharr comparison deferred; see Open Questions.

**Why angle-doubling:** the structure tensor describes an unoriented LINE field, where theta and theta+pi are the same structure. Storing (cos 2theta, sin 2theta) removes the arbitrary sign choice that would otherwise flip discontinuously in storage.

**What this spec does NOT promise consumers:** that outlet 1's R/G can be fed to an ordinary vecfield inlet. It cannot. A consumer must decode theta = 0.5 * atan2(G', R') and re-emit a vector, and sign-sensitive consumers must not receive it at all (hub doc: "Explicit exclusion list"). GenExpr atan2 on decoded sampled-texture input is VERIFIED SAFE on the GPU (2026-10-12, `tests/spike_atan2_safety.py`); the one measured caveat is a +pi/-pi convention difference exactly at the branch cut, which is benign (same line direction).

**No auto-normalization:** gradient energy scales with input contrast squared. `strength` is the user-facing calibration, same tradeoff `f_vf_fieldmap` accepted, avoiding the multi-pass reduce a frame-level normalization would need.

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | texture (required) + control | — | Source scalar texture. Control messages route to params. |

Single driving inlet. No mod inlets in v1 (a converter, not a modulated generator; same call as `f_vf_fieldmap`).

vs_black fallback when inlet 0 is unconnected: zero tensor. Outlet 0 = (0, 0.5, 0, 1). Outlet 1 = (0.5, 0.5, 0, 0).

---

## Outlets

| Outlet | Content | Channels |
|---|---|---|
| 0 | Raw tensor, float32 | R = Jxx, G = Jxy (0.5 = zero), B = Jyy, A = 1 |
| 1 | Decoded convenience, float32 | R = cos 2theta, G = sin 2theta (both 0.5 = zero), B = trace, A = anisotropy (normalized coherence, 0-1) |

Both outlets `@type float32`. The source texture is not re-output.

Neither outlet is an `f_vecfield` and neither should be labeled as one. Whether `build_patcher.py` needs a new signal-type tag for these outlets is an open question (below).

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `strength` | live.dial, log scale | 1-1000 | 100 | Gain on trace and the raw tensor terms before clamping (not on anisotropy, which is already normalized). **Locked 2026-10-16 (Matt, live on noise):** trace is gradient squared, so needed gain scales with feature size squared; 95th-percentile trace to 1.0 needs ~35 (fine, 16 cells), ~150 (medium, 8), ~900 (coarse, 4) at radius 3, 640x480. The old provisional 0-30 only reached fine content. Matt approved 100 and 300 as good on his smooth source and the log-scale 1-1000 range. |
| `radius` | live.dial | 0-16 (R_MAX = 16, decided 2026-10-16) | 3 (Matt, live, 2026-10-16) | Smoothing neighborhood for the tensor. Spike: radius mostly dilutes outlier energy rather than the ambient median, so radius and `strength` are fairly decoupled. Range, default and units set by the Phase 0 spike, not guessed here. |
| `width` | live.numbox | 64-8192 | 640 | Render width in pixels. Stages A, B_h use it for tap spacing (1/width UV per pixel) because live `dim` reads 1. Set to the real frame width so `radius` means pixels. **Exposed for now (Matt, 2026-10-16: texel/aspect exposed; reshaped to width/height the same day since it is friendlier);** deriving from render size (`r dim`) is deferred. |
| `height` | live.numbox | 64-8192 | 480 | Render height in pixels. Stages A, B_v use it for the vertical step. Exposed for now. |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Outputs the zero-tensor neutral on both outlets. |

**Name:** `f_tf_tensormap` (decided 2026-10-16, Matt; working name until then was `f_tf_structure`). `tf` is the tensor-field family prefix, parallel to `vf`.
**Prefix:** `tensormap`
**Object name:** `tensormap_pix` (same convention as `f_vf_fieldmap` -> `fieldmap` -> `fieldmap_pix`)
**Type:** `@type float32`

---

## Signal Flow

```
in0 (source texture + control) -> routepass jit_gl_texture jit_matrix
  jit_gl_texture branch -> vs_inState -> structure pix in0
  unmatched -> route <params> -> live.dials -> prepend param <name> -> structure pix in0

structure pix out0 -> outlet 0 (raw tensor, @type float32)
structure pix out1 -> outlet 1 (decoded convenience, @type float32)
```

Same routing skeleton as `f_vf_fieldmap`. Whether the smoothing is one pass or two is a plan.md decision (Open Questions).

---

## Acceptance Criteria

Numbers first, per the constitution's Verification Tiers. Tiers 1-2 apply (this is nontrivial math with a known reference); the tier gate is still recorded as the first task of Phase 0 in tasks.md.

- **Flat input:** solid-color texture gives zero tensor on both outlets: outlet 0 = (0, 0.5, 0, 1), outlet 1 = (0.5, 0.5, 0, 0). Trace is exactly 0 at every radius (spike sanity floor).
- **Edge input:** trace scales as contrast squared. Contrast 1.0 at radius 0 gives raw trace 16.0 (the Sobel kernel's known gain), confirming the kernel matches the spike.
- **Direction correctness:** a synthetic linear ramp at a known angle phi gives theta = phi (mod pi) on a straight edge, and (cos 2theta, sin 2theta) matches NumPy `arctan2` to within the atan2-safety tolerance (~1e-6 rad).
- **Line-field invariance:** rotating the input by pi leaves outlet 1 unchanged.
- **Isotropic point:** a pixel with trace below epsilon outputs R = G = 0.5 and A = 0, never an arbitrary angle.
- **Anisotropy / singularity:** the anisotropy map's dark (near-isotropic) points coincide with where the direction field becomes undefined (matches the spike's visual check and the index-type singularities in `vector_field_math_concepts.md` #1).
- **Noise input:** coarse bilinear noise gives trace median ~0.015-0.019 and p95 ~0.05-0.07 before gain, stable across radius.
- **`strength` = 0:** outlet 1's B is 0 and outlet 0's diagonal terms are 0; outlet 1's R/G/A are unchanged (they don't depend on gain).
- **Coherence is contrast-independent:** the same edge at contrast 0.1 and 1.0 gives the same A (~1.0) while B differs by the contrast-squared ratio.
- **Bypass:** both outlets output the zero-tensor neutral.
- **Unconnected inlet:** zero-tensor neutral, no crash, no black frame.
- **Loads in Vsynth** and both outlets render in `vs_render` (the shipped-bpatcher contract tests).
- **Judgement tier (scratch patch):** with `jit.gl.bfg` in, outlet 1's B/A channels visibly separate structured ridges from flat regions, and `strength` default reads sensibly. This is the live confirmation the provisional `strength` default is waiting on.

---

## Out of Scope (v1)

- **Any consumer.** `f_vf_glow` anisotropy inlet (hub doc Q12, designed 2026-10-16), `f_stipple`, `f_grain`, `f_vf_chroma`/`f_vf_prism` wiring. None can build until this exists, but none belong in this spec.
- **Decode helper module** (atan2 half-angle and re-emit as a vector). Consumers decode inline for now; whether a shared `f_tf_decode` is worth it is a Phase 2 question.
- **Scharr or other gradient operators.** Sobel only; revisit if it proves too soft for grain/weave-scale structure once a real consumer exists.
- **Mod inlets on `strength` or `radius`**, per the `f_vf_fieldmap` precedent, and because new mod depth controls run into the paused `mod_depth_ui_density.md` question.
- **Type-tagging outlets via named mod textures** (hub doc Q8). Belongs to `named_mod_textures.md` once its verification work is done.
- **Glyph-field renderer, photoelastic optics, confidence-scaled marks** (hub doc "Future, not pursued").
- **Temporal smoothing.** Stateless per-frame.
- **Auto-normalization.** Needs multi-pass reduce; deferred indefinitely.

---

## Open Questions

1. **Module name and prefix. RESOLVED 2026-10-16 (Matt): `f_tf_tensormap`.** Remaining bookkeeping: the constitution's naming-convention section needs an `f_tf_` entry (tasks.md T042).
2. ~~Provisional `strength` default and range.~~ **Resolved 2026-10-16:** log dial 1-1000, default 100 (see Parameters).
3. **`radius` range, default and units.** The spike swept radius only as an experiment variable (in pixels: 0, 1, 3, 6; lean pixels). Needs a Phase 0 spike to pick a useful performance range, and a decision on pixels vs normalized UV (`f_vf_fieldmap` uses normalized UV for its `scale`).
4. **Smoothing implementation (plan.md, not spec). Partly resolved 2026-10-16 (Matt): separable stages with a bounded loop (plan ADR-1, ADR-3). Still open: `R_MAX`, which the cost spike sets.** Brute-force in one codebox means (2r+1)^2 Sobel evaluations per pixel; the alternative is a gradient-products pass plus a separable box-blur pass. This is a Phase 0 cost question to answer on the M1, the project's stated GPU budget floor, and an ADR decision, not something this spec should prescribe.
5. **Signal-type tag for the outlets.** `build_patcher.py` has `signal_type` values like `vecfield`. Whether `tensor` / `tensor_packed` get their own so outlets color and document themselves distinctly, or stay untyped for now, is a build-pipeline decision. Not blocking, but worth deciding before the first consumer is wired, given the whole point of the rejected-alternative above is not letting two different encodings look identical.
6. **Outlet order. RESOLVED 2026-10-16 (Matt): raw tensor on outlet 0, packed convenience on outlet 1**, as this spec already had it (library primary-output-first convention).

---

## Clarifications

### Carried from `ideas/f_tensorfield.md` (decided before this spec)

- Q: Three outlets (raw / direction / eigenvalues) or a packed convenience outlet? -> A: **Two outlets: raw tensor + packed convenience RGBA** (R=cos2theta, G=sin2theta, B=trace, A=anisotropy). Decided 2026-10-13 (Matt).
- Q: Raw lambda1/lambda2 or trace + anisotropy for the scalar pair? -> A: Trace + anisotropy. NumPy spike showed it cleanly separates structured ridges from flat regions, and both real candidate consumers want exactly that pair.
- Q: Does GenExpr `atan2` behave correctly on decoded sampled-texture input? -> A: **Verified safe on the GPU bench, 2026-10-12.** Max wrap-aware error 5.6e-7 rad; one benign +pi/-pi convention difference at the branch cut itself.
- Q: Hide tensor data in unused vecfield channels on existing producers? -> A: No, rejected; creates two same-looking textures with different meanings.
- Q: Self-generating mode? -> A: No. Processor, `driving_inlet`, requires input.
- Q: Which gradient operator? -> A: Sobel, reusing the verified `f_vf_sobel` kernel. Scharr deferred.

### Session 2026-10-16

- Q: Is this promotion from ideas/ to spec premature, given the 2026-10-10 note that it was "overwhelmingly open questions"? -> A: No. Phase 1 of the hub doc closed this session (consumer audit complete, `f_vf_seeds` and `f_vf_potential` codebox reads done, terminology pass done), and the packing decision closed the one architectural fork. The remaining open questions here are about naming, calibration and cost, not about what the module is.
- Q: Is the A channel raw (lambda1-lambda2) or normalized coherence? -> A: **Normalized coherence (lambda1-lambda2)/trace**, as the spike computed it. The first draft of this spec wrote raw lambda1-lambda2 times `strength`, copied from the hub doc's shorthand; that contradicts the spike evidence the hub doc cites and would make "confidence" depend on contrast. Corrected 2026-10-16, same session. Consequence: A is contrast-independent and noisy where trace is tiny, so a consumer that wants "is there real structure here" should combine A with B. Also what the `f_vf_glow` anisotropy gate (hub doc Q12) assumes: a 0-1 value.
- Q: Module name? -> A: **`f_tf_tensormap`** (Matt, 2026-10-16). Replaces the working name `f_tf_structure`; the directory, spec, plan, tasks, hub doc and the other docs that referenced the old name were updated the same session. `HANDOFF.md`'s 2026-10 entries still say `f_tf_structure` because they describe the past.
- Q: Outlet order? -> A: **Raw tensor first (outlet 0), packed convenience second (outlet 1)** (Matt, 2026-10-16).
- Q: What is `strength`'s range and default? -> A: **Log dial 1-1000, default 100** (Matt, 2026-10-16, live on noise; see Parameters for the measured scaling).
- Q: Why do stages take `width` and `height` Params? -> A: Live Vsynth `jit.gl.pix` reports `dim` = 1 (probe patch, 2026-10-16), so 1/dim gave a zero offset. Stages A, B_h, B_v take `width` and `height` (frame size in pixels; texel = 1/width). Radius is in pixels when they match the real frame size. How the module supplies them is open (T030/T031).
- Q: How is `radius` implemented? -> A: **Bounded loop** to a compile-time `R_MAX`, tap weight gated by the live `radius` (Matt, 2026-10-16). If cost is too high the response is a smaller `R_MAX`, not a different algorithm.
- Q: Why spec the producer before any Phase 2 consumer work? -> A: Every consumer design, starting with `f_vf_glow`'s anisotropy gate, is blocked on this module existing.
