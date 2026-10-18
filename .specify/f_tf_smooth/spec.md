# Spec: f_tf_smooth

_Created: 2026-10-17_
_Status: Draft_

_Promoted from `ideas/f_tf_build_brief.md` §4 ("f_tf_smooth — current single best next
module") and `ideas/f_tf_triage.md` (verdict: build first, review confirmed 2026-10-17).
Build order position: first of the confirmed Phase 2 modules; every chained renderer is
silently blocked on it. Its contribution is semantics/integration, not algorithm — see
 jitfx-audit note below._

---

## What it does

A temporal tensor smoother ("inertia"). Feeds back the raw tensor onto itself across
frames: `T' = T_new + release · (T_prev − T_new)`, per component, in tensor space. Each
pixel's tensor is the released average of the tensor it has been seeing, so per-frame
gradient jitter settles into a stable field while real motion still tracks through.

**Why tensor space and not "temporal filter on a texture":** opposite axes that trade
places frame-to-frame (flicker between two edge camps) average into a stable tensor
rather than cancelling into mush; and the field carries its confidence with it. This is
the same argument the hub doc makes for tensor-space spatial smoothing
(`ideas/f_tensorfield.md`, "What a tensor can do that a vecfield cannot" — "Averages
correctly"), applied over time.

**Why a module at all:** the math is stock — `jit.fx.tp.filter` is the same two-pole
recurrence over an MRT feedback chain, and its channels are storage-agnostic
(`jitfx_audit.md` source-read: `out2 = in0·a0 + in1·a1 + in2·a2 − in3·b1 − in4·b2`,
`out3 = in3`). What is *not* stock, and what this module is: a **one-knob performable
smoother for the tensor family** with the family's float32 guarantees, the exact f_tensor
inlet contract, and attack/release semantics chosen for the release gesture rather than for
audio-adjacent filter character. The family's own precedent is identical:
`f_vf_temporal_smooth` (parked idea, `ideas/f_vf_temporal_smooth.md`) exists for exactly
this reason on the vecfield side rather than adopting a generic filter for vecfields.

**Where it sits:** between `f_tf_tensormap` and every consumer (glyph/hatch/aniso_blur/
sharpen's source). Chain A of the brief is `tensormap → smooth → sharpen → aniso_blur`;
no chain works on live video without it (brief: "prerequisite... not a nicety").

## Tensor-native test (explicit)

Collapse it to a vecfield one-pole and the module's purpose disappears: per-frame axis
sign flips cancel the field to zero where tensors reinforce (hub argument), and coherence
must arrive as a second texture the vecfield pipeline doesn't carry. Collapse it to a
scalar (trace-only smoothing) and the axis is lost — mush returns exactly where the
opposite-axis flicker lives. Both eigenvalues, the axis, and coherence must ride the same
feedback to earn the type.

## jitfx-audit note (carried into every read of this spec)

`ideas/f_tf_jitfx_audit.md` §3: `jit.fx.tp.filter` is "approximately yes" shipped
coverage of the *math*. This module's honest framing (quoted from the audit): "the case is
integration + semantics, which is how the library treats all its f_ re-shapes." Do not
describe this spec as introducing an algorithm the platform lacks; describe it as giving
the library's tensor type the temporal semantics its consumers require.

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | tensor (required) + control | — | Raw tensor from `f_tf_tensormap` outlet 0 (`f_tensor_type.md` encoding). |
| 1 | tensor | tensor mix | OPTIONAL second tensor source blended in before the feedback (see Tensor mix inlet). |

## Outlets

| Outlet | Content | Channels |
|---|---|---|
| 0 | Smoothed raw tensor, float32 | Same f_tensor out0 encoding as the input (R = Jxx·strength... per contract). |

Single outlet: consumers need the raw form only; packed conveniences are tensormap's job
and this module must not re-encode them (single-source-of-truth on encoding).

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `release` | live.dial | 0–1 (0.999 max?) | 0.5 provisional | Feedback coefficient. 0 = passthrough (neutral). Higher = longer memory. The family's one-knob gesture: ride it from 0 (reactive) to 0.9+ (heavy inertia). Default and top-of-range are tier-3 judgements (T0xx). |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Standard bypass: passthrough of inlet to outlet, no feedback mixing. |

**Tensor mix inlet** (design consideration, to resolve in Phase 0): a second tensor inlet
mixed pre-feedback (`T_mix = (1−m)·T_a + m·T_b`, m param) would let an `f_tf_authored`/
LFO source morph live with tensormap output under one smoother. **Deferred**: it widens
this module's job (mixing is `f_tf_mix`'s, per triage) and its UI cost is a live question
in the paused `mod_depth_ui_density.md` territory. Revisit if chain B assembles with no
`f_tf_mix`.

---

## Signal Flow

```
in0 (source tensor + control) -> routepass jit_gl_texture jit_matrix
  jit_gl_texture branch -> vs_inState -> smooth pix in0 (feedback via pass/state pair)
  unmatched -> route <params> -> live.dials -> prepend param <name> -> smooth pix in0

smooth pix out0 -> outlet 0 (smoothed raw tensor, @type float32)
```

**Architecture: two-domain, the `f_vf_advect` precedent.** Two pix nodes in a `pix_chain`:

- **State pix** (the "field" node): reads `Param srcSmoothTensor` (previous frame's raw
  tensor, via `vs_inState`) and inlet tensor; outputs the blended tensor back into the
  state texture AND forwards it to the render pix.
- **Render pix**: passthrough, renders to the module outlet and the visible output.

This matches `f_vf_advect`'s architecture (`src` state texture + render pass reading it),
and mirrors `jit.fx.tp.filter`'s MRT feedback (`out3 = in3`) minus its 4-tap depth. One
feedback tap per channel; two-pole filtering (deeper delay lines) is out of scope v1.

## Acceptance Criteria

Numbers first per the constitution's Verification Tiers. Tier 1 applies (recurrence has
closed-form ground truth); tier 2 applies (feedback wiring on real GPU); tier 3 applies
(default and range of `release`).

- **Passthrough at release 0:** out = in, exactly, at frame N and at frame N+1 (no
  feedback residue) on content that changed between frames.
- **Exact decay:** a one-frame step from tensor A to tensor B (synthetic: two constant
  regions) gives out(N+k) = B + (A−B)·release^k per channel, to mirror tolerance.
- **Line-field invariance:** smoothing does not invent orientation: an input sequence
  alternating axis θ and θ+180° (identical tensors, angle-doubled) stays constant, and the
  output axis matches the input axis, not a cancelled average.
- **Opposite-axis reinforcement:** synthetic: two constant regions per frame alternating
  90° axis (crossed gradients) — output coherence stays high (tensors reinforce) where a
  vecfield version would collapse to zero magnitude between frames. This is the tensor-
  native test rendered as a number.
- **Neutral on unconnected inlet:** `vs_black` in (0, 0.5, 0, 1) feeds back the zero
  tensor; smoothed output stays at the zero-tensor neutral while unconnected.
- **Bypass:** passthrough exactly.
- **Loads in Vsynth** and renders in `vs_render` (shipped-bpatcher contract tests).

## Out of Scope (v1)

- **Any tensor mixing semantics** (crossfade knob, pre-feedback blend) — `f_tf_mix`, chain B.
- **Attack/release split** — the smoother is release-only: the tensor arriving each frame is
  trusted at face value and only history is softened. An attack curve would smooth the input
  itself, dulling real structure; if tier 3 shows the release curve insufficient for live
  video, this opens as a v2 question (one knob first).
- **Packed outlet 1 re-encoding** — consumers needing (cos2θ, sin2θ, trace, coherence) take
  tensormap outlet 1 directly, or a future unpack view; not this module's jobs.
- **Two-pole (multi-tap) filtering** — tp.filter's b1/b2 ringing taps. If release-only
  one-pole proves too laggy for live response, this is the v2 door, decided by feel.
- **Any spatial smoothing.** Spatial box smoothing of tensors belongs to tensormap's
  `radius`; this module is temporal only.

## Open Questions

1. **`release` default and range ceiling.** Provisional 0.5, dial 0–1. What the top of the
   range should actually be (0.99 flickers with float32; 0.999 near-freezes) is a tier-3
   judgement on live noise — same shape as tensormap's `strength` calibration (T023 there).
2. **Warp/UV: does feedback survive stage rendering at differing sizes?** [INFERENCE] The
   module is fixed-size internally; tensormap emits whatever it renders. If the tensormap
   and smoother sizes disagree, the feedback texture resamples — acceptable (float32
   resampling of a smooth field is harmless), but confirm no clamping artifacts at the
   edges in tier 2.
3. **`release` mod inlet?** If the family later wants per-pixel release (mask-region
   inertia), it follows the `f_vf_glow` anisotropy-inlet pattern — deferred, not v1.

## Clarifications

- Q: Two-pole like tp.filter? -> A: No, one-pole (release-only) v1; v2 door if needed.
- Q: Packed outlet passthrough? -> A: No; raw tensor only. The packed encoding is
  tensormap's to emit.
- Q: Why not adopt `jit.fx.tp.filter` in a chain rather than build this? -> A: Its knobs
  are b0-b2 filter coefficients (audio-adjacent, five dials), it does not carry the family
  @type guarantee, and its neutral-on-unconnected is silent garbage-in-garbage-out on
  tensor data (no vs_black gate). The audit records the honest finding; the family builds
  the performable version, `f_vf_temporal_smooth` precedent.

---

## Sources (prior art + precedents cited)

- `ideas/f_tf_jitfx_audit.md` §2.2 (tp.filter source-read) — the "don't claim novelty"
  note above.
- `ideas/f_vf_temporal_smooth.md` — the vecfield-family precedent for re-shaping a stock
  recurrence into a semantic module.
- `docs/f-reference/f_tensor_type.md` — inlet encoding contract.
- `ideas/f_tf_build_brief.md` §4/§5 — promotion and chain context.
- `ideas/f_tf_expressive_consumers.md` §2.3 — concept origin (the "temporal tensor
  smoother (row 14)" candidate).
- One-pole release-only temporal smoothing: standard recursion; no external source taken.