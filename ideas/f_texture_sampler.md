# Texture sampler (working name) — an MPC-style sampler for video, textures and fields

**Status:** idea only, not specced, not scheduled. Captured 2026-10-18 from a chat
question ("does Max have the video equivalent of an audio sampler, like a software
MPC?"). The mechanisms below come from general Max/Jitter knowledge plus the repo's own
temporal-synthesis notes. **Nothing here has been tried in Max.**

## Core idea

Max has no single "video sampler" object, but the pieces exist: something to capture and
hold frames, something to trigger playback at a chosen position, rate and direction, and a
control layer (pads, choke groups, envelopes) on top. This note asks what that looks like
as `f_` modules, and, the angle specific to this library, whether the stored "samples"
can be **fields** (vecfields, tensors) as well as images.

## Two different things hiding in "sampler"

| | A. Live capture / freeze / loop | B. Pad-triggered clip bank |
|---|---|---|
| Samples come from | frames captured from the chain at runtime | clips already on disk |
| Storage | GPU texture ring buffer | movie players (in RAM, or streamed from disk) |
| Domain | texture / GPU, fits the `f_` chain naturally | mostly control and playback logic, CPU / disk side |
| Closest existing | Vsynth `vs_frame_delay` (`jit.gl.textureset`) | Vsynth `sources_movie` |
| Hard part | memory, indexed reads, capture timing | per-pad voices, choke, envelopes, many simultaneous decodes |

## What already exists, and what it says

- **`vs_frame_delay`** (Vsynth, Tier 3) uses `jit.gl.textureset.js` as an explicit,
  JS-managed ring buffer of named textures, supports longer delays than the two-pix
  feedback pattern, and has an xfade. `docs/max-reference/temporal_synthesis_architecture.md`
  records it as Pattern 2 ("pix objects read from it by texture name").
  `docs/max-reference/intraframe_multipass_architecture.md` already files textureset as
  the right tool for multi-frame history and as the documented workaround for
  manually-timed single-frame capture, which is exactly "record one frame on a trigger".
  This is the repo's own precedent and should be the default route for A, ahead of a
  CPU matrix bank (`jit.matrixset`) that would mean a CPU-to-GPU upload every frame.
- **Pattern 1 feedback** (`pass_pix` + a state pix) holds one frame of history: enough
  for freeze/hold, not for looping.
- **`sources_movie`** covers single-clip playback in Vsynth. For B, plain Max
  (`jit.movie`: start/end, loop, signed rate, `loadram`; HAP for GPU-decoded playback)
  is what a pad bank would wrap. That is general Max knowledge, not checked in this repo.
- Nothing in the `f_` library records or replays anything today. `f_vf_advect`
  accumulates; it does not store.

## Memory budget (arithmetic, not measured)

| Frame format | Per frame | 120 frames (4 s at 30 fps) |
|---|---|---|
| 1920x1080 RGBA 8-bit | ~8.3 MB | ~1.0 GB |
| 1280x720 RGBA 8-bit | ~3.7 MB | ~0.44 GB |
| 512x512 RGBA float32 | ~4.2 MB | ~0.50 GB |
| 256x256 RGBA float32 | ~1.0 MB | ~0.13 GB |

Video is the expensive case, so any real sampler uses short loops, low resolution, or
disk streaming. Fields are float32 by contract (`f_vecfield`, `f_tensor`), so storing
them at 8 bits would quantize them; the field case is 4x per pixel but naturally lives
at the 128-256 px sizes `f_vf_fluid` already runs at.

## The angle only this library has: field samples

Record `f_vf_fluid`, `f_vf_vortex` or `f_vf_optical_flow` output into slots and replay it
as a force field into `f_vf_advect`, `f_vf_warp` or `f_caustic`: a performable library of
flows. Trigger a flow "pad", loop it, scrub it, play it backwards. Replay costs texture
reads rather than a solve. Reversed playback is playback of a recording, not the solver
run backwards. Speculative; nothing has been checked.

## Relationship to `f_loop_to_cycle`

Same open question: GPU-resident, indexable frames. Option A below is effectively the
feasibility test for `f_loop_to_cycle.md`: if one pix can read an arbitrary slot plus a
fraction (two reads and a lerp), per-pixel phase reads work; if only a fixed set of
named slots can be bound as inlets at once, they do not. The sampler adds the capture
side and the trigger layer; `f_loop_to_cycle` adds per-pixel phase modulation. Possibly
one mechanism with two front ends.

## Control layer (the MPC part)

Mostly Max control logic, little GPU work:

- pad trigger from MIDI note-on or a named message (the library's existing scalar
  message convention); one-shot / loop / gate modes; choke groups
- start and end points; rate including reverse (the "pitch" of a sample)
- level envelope (attack / release into gain or alpha); a step sequencer on top
- several pads sounding at once needs a voice mixer; output shape is undecided (one
  composited texture, N outlets, or one per pad group)

## Architecture options (for discussion, none chosen)

1. **Probe: live freeze / loop on textureset (A, small).** Record N frames into one
   buffer; play with rate, reverse, loop, start/end and sub-frame lerp. Low resolution
   first. Answers the open questions below and unblocks `f_loop_to_cycle`; the same role
   `f_vf_advect` played for the temporal modules.
2. **Pad bank (B).** Control-heavy, mostly wraps movie playback. Value added is the
   pads, choke and envelopes, which may be better as a utility that sends named messages
   to existing sources than as a texture module.
3. **Unified sampler.** Slots hold either captured frames or loaded clips, with one
   voice/mixer layer. Largest; only worth it if 1 and 2 show repeated cost.

Lean: 1, then decide on 2.

## Build-system fit (unchecked)

`build_patcher.py` handles multi-pix `pix_chain` modules. textureset is a JS object, not a
pix, so this is probably a schema gap (the temporal doc anticipated "adds JS dependency").
Not checked: how `vs_frame_delay` wires it, and how an `f_` module would ship or reference
the JS.

## Open questions

- Can one `jit.gl.pix` read an arbitrary slot, or several at once, from a textureset, or
  only named slots bound as inlets? Decides per-pixel use and the `f_loop_to_cycle` link.
- Does textureset hold float32 textures? Needed for the field case. `vs_frame_delay`'s
  type is unchecked.
- Capture timing: record-on-trigger against draw order and the one-frame feedback delay.
- Practical memory and resolution ceiling next to the rest of a Vsynth chain (chains
  already compound cost; `f_caustic` alone is ~21-23 ms/frame).
- Overdub (record while playing), as an MPC does: possible?
- A vs B vs both: does Matt perform with live-captured material, pre-rendered clips, or
  both? Unanswered.
- Name: "sampler" carries audio connotations; descriptive working names are the
  precedent (`f_loop_to_cycle`).
- Whether sample slots could be named textures (`named_mod_textures.md`). Not reconciled.

## Cheapest first step

Read `vs_frame_delay` in the Vsynth package (how it writes and reads slots, what texture
type, how many slots a pix reads at once). No new objects needed. Then a scratch patch:
capture ~30 frames at 256x256 and read at slot i plus a fraction with a lerp. A NumPy
mirror would only be index math; every real unknown here is a Max/GPU fact, so it is
bench or scratch-patch work.

## Explicitly not decided / not in scope yet

No spec, plan, build or scratch testing. No module names chosen. Not yet checked against
Vsynth's package source. The memory figures are arithmetic, not measurements.
