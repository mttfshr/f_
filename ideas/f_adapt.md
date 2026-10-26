# f_adapt — temporal adaptation, novelty and band-pass for plain textures (working name)

_Status: ⚪ concept only. Drafted 2026-10-23 from the webgpgpu mining run
(`webgpgpu-ideas-1`). Not specced, not tried in Max._

## Concept

Per-pixel temporal memory on any texture, with the *difference from memory* as the
usable output: static structure fades, change pops. The webgpgpu `vision/` pages
(2024 WebGL2 tests plus the `Vision_00x` series) build a small family of these.
They share one core (an exponential memory) and differ in how it is used:

| Mode | Source | What it does |
|---|---|---|
| Habituation | `Vision_004/005` | memory weight 0.9 (or 0.7) on memory, rest on input; static scenes fade |
| Novelty | `Vision_005`, `..adaptation_webgl2_test` | output `0.5 + current - memory`: stillness is mid gray, change is bright or dark |
| Change-gated | `..gating_webgl2_test` | per-pixel gate `clamp(distance(x,u)+0.5,0,1)` scales how much memory updates, so moving regions stay live and settled regions freeze |
| Cascade | `..delay_webgl2_test` | three one-pole stages in series: a softer, longer lag than one long-weight pole |
| Temporal band-pass | `Vision_012/013` | difference of a fast and a slow lag (alpha 0.5 / 0.1 in 013, 0.20 / 0.05 in 012); isolates mid-timescale change |
| Resonator pair | `Vision_006/008` | two memories rotated by a 2x2 rotation (cos 1.2 * 0.97, sin 1.2 * 0.97): a phase-delayed, precessing afterimage |

An older webgpgpu example also blends a fraction of the previous frame back in as plain
motion blur (`perceptron_v2`); that overlaps `glow_profile_and_afterimage.md`.

## What f_ has today

- `f_tf_smooth`: one-pole smoother, **tensor space only**.
- `f_vf_advect`: accumulation along a vecfield, not difference from memory.
- `f_vf_temporal_smooth.md` (parked) is the vecfield sibling of a plain-texture one-pole.
- `f_vf_optical_flow` ruled out frame differencing as a *motion-field* estimator; a
  display or drive signal is a different use.
- No plain-texture temporal adaptation, high-pass or band-pass.

## Proposed shape

- Signature: texture -> adapted texture + novelty texture, temporal.
- One module, mode menu (Habituate, Novelty, Gated, Cascade, Band-pass, Resonator). The
  library's taste for general tools says one module with a `kind` menu rather than six.
- Dials: memory weight or lag time, novelty gain, gate radius and threshold, cascade
  stage count, fast and slow lag, rotation rate and decay.
- Float32 state removes the web version's 8-bit dead zones (slow decay stalls when
  the step falls below one 8-bit level), so no sub-LSB workaround is needed.
- The band-pass mode is the natural drive for the Resonator mode here and for
  `f_wave_field.md` (it is exactly `Vision_013`'s forcing signal).

## Tier-1 checks (all closed form)

- Memory after N frames: (1-w)^N * init + w * sum_k (1-w)^k * input_k.
- Static input drives the novelty output to exactly 0.5; a step of amplitude a gives
  0.5 + a * (1-w)^k at frame k.
- Two-lag difference of a step has a known bi-exponential response; peak time follows
  from the two alphas.
- Resonator: single-impulse response is a damped spiral, pole magnitude = decay,
  angle per frame known.

## Caveats the verifiers noticed (they are not in the omp drafts)

- `Vision_007/008` define the adapt shader but never call it in the active loop; the
  live uses are `Vision_005` and `Vision_006`.
- In the resonator pair, memory 1 injects the full input and memory 2 injects
  `(1 - DECAY) * input`; the clean damped-spiral story rests on the second form.
- The gate's smooth pass samples three textures, not four.

## Risks and open questions

- **Overlap with core Vsynth.** The run could not see
  `docs/vsynth-reference/module-inventory.md`; Vsynth's own frame delays and luma
  processors may cover most of Habituate, Novelty and Afterimage. Check before
  speccing, and keep the modes that Vsynth cannot do (Gated, Band-pass, Resonator).
- Lag dials are in frames, so they depend on frame rate; consider seconds.
- Noisy sources make the band-pass and the gate noisy unless prefiltered.
- Shared-operator question (parked `shared_tensor_vecfield_operators.md`): one
  module over texture, vecfield and tensor, or a plain-texture module now. The
  closed-form checks above would carry over either way.
- The change-gated mode's reference (raw versus delayed input) is an open tuning
  choice and may flicker on camera noise.

## Related

`f_tf_smooth`, `f_vf_temporal_smooth.md`, `f_vf_advect`, `glow_profile_and_afterimage.md`,
`f_wave_field.md`, `f_wc_from_webgpgpu.md` (habituation channels inside `f_wc_fft`).

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 22, 23, 55, 24, 29, 30, 60, 61, and 21
(afterimage). Verified by subagents against the vision files and the f_ inventory;
the caveats above come from the verifier replies and were not in the drafts.
