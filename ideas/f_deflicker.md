# f_deflicker — a downstream De-flicker utility

_Status: ⚪ concept only, not started. Captured 2026-10-25 (Matt: "deflicker seems like it could become a
generally useful downstream utility")._

## Gist

A utility module that holds an input's overall brightness near its **usual** level, frame by frame, so
whole-frame pumping and flashing flatten while the image's spatial structure is untouched. One main dial,
**De-flicker** (0 = pass-through, 1 = fully held). Useful after any source that breathes as a whole:
reaction-diffusion and neural-field generators, feedback loops, strobing footage, camera auto-exposure hunts.

## Where it came from

`f_wc` flashes: the whole field fires, recovers and fires again. Measured (2026-10-25,
`tests/records/spike_fc_flash.py`, `spike_fc_damping.py`) as the E–I loop's own bulk oscillation
(frame-mean E swinging ~0.07 ↔ 0.6), entrained by the pulse, and inseparable from the pattern inside the
dynamics: no knob removes one without killing the other. A display-side de-flicker was designed and
partly built in that module (T075), then moved out as a general utility. The work-in-progress is in git at
`8b33e27` (dial, tracker stage, gain law in the encoder, mirror + tests), removed in the following commit.

## Design (as approved for T075)

1. **Measure** the frame's mean per channel (a GPU reduction chain down to 1 × 1).
2. **Track the usual level**: a 1 × 1 feedback stage moving a small fraction toward the current mean each
   frame (0.005 ≈ 200 frames); a fresh texture (alpha 0) takes the current mean.
3. **Rescale**: out = in × mix(1, clamp(usual ÷ current, 0, cap), amount), per channel; cap ≈ 4× so a
   near-black frame is not blown up into noise. Scaling (not subtracting) keeps black black.
4. One frame of latency (the mean is last frame's) — imperceptible at flash periods of 75–150 frames.

Candidate extra dials for a general utility: Response (the tracker's speed), Cap, and a per-channel vs
luma-only switch (luma-only avoids colour shifts on footage).

## Hardware findings to build on (measured, 2026-10-25)

- **`sample()` does not interpolate here.** A bilinear tap exactly on a texel corner returned ONE texel,
  not a 2 × 2 average (GPU block results had 2× the expected spread, correlation 0.5 with true block
  means; evidence `tests/logs/fc_t075_mean1.npz` at the time). Build the reduction from `nearest` reads at
  texel centres.
- **Shader length limit.** A 256-tap `jit.gl.pix` codebox broke the GL shader translator ("lua: stack
  overflow (too many captures)"). Keep each reduction stage to ~16 reads (4 × 4 blocks).
- **A failed compile poisons the bench.** After that error, every later leg in the same run failed;
  the next run was clean. Put reduction legs where a failure is obvious.
- Exact 4 × 4 reduction for a 1024² input: 1024 → 256 → 64 → 16 → 4 → 1 (five stages, 16 reads each).

## Open questions for a standalone module

- **Arbitrary input size.** A downstream utility sees 1920 × 1080, 4K, etc. Options: first resample the
  input to a fixed power-of-two working size (e.g. 256², nearest) and reduce from there (the mean barely
  changes), or size the chain from `r dim`.
- Per-channel vs luma: per-channel holds colour balance for generators; luma-only is safer for footage.
- Freeze-safety: a static input makes the gain settle to 1 (current = usual) — confirm.

## Related

- `f_wc` (`.specify/stable/f_wc/tasks.md` T075) — the origin and the measurements.
- Downstream-effect philosophy (Matt, 2026-10-25): Strike / impulse and Contrast / Sharp also belong in
  separate modules, not inside generators.
