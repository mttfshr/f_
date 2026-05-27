# f_ — Handoff

_Session: 2026-05-26_

## What was done this session

**f_mobius complete (all phases):**
- Planned `.specify/f_mobius/plan.md` and `tasks.md` from existing spec
- Codebox written and verified: passthrough, inversion, rotation, singularity guard all pass
- Production bpatcher `patchers/f_mobius.maxpat` built via one-shot generator script (deleted after use)
- Zoom exponent tuned to `pow(10, (zoom-0.5) * 5.0)` empirically
- Behavior clarified through exploration:
  - `invert` is a wet/dry between passthrough UV and `1/z` inversion — the distinctive control
  - `rotate` and `zoom` affect the passthrough (identity) path; at `invert=1` they have no effect
  - The `mix()` blend between paths is not group-pure Möbius at intermediate values, but produces coherent and interesting UV warps
  - Output is visually strong — lobe structures, circle-preserving distortions, striking with waveform generator source
- Architectural insight: f_mobius is not a mathematical foundation for f_stereo/f_poincare — those modules will implement their own Möbius math internally, parameterized correctly for their purpose (sphere rotations for f_stereo, disk automorphisms for f_poincare)
- README updated: f_mobius → ✅ Working; build queue updated; f_stereo is next

## First thing next session

`.specify/f_stereo/spec.md` is written. Start with `plan.md` — the key task is expanding the rotation matrix R = Rz(lon) * Rx(lat) * Rz(spin) into explicit scalar expressions for rx, ry, rz, then verify in a scratch patch before building the wrapper.

## Loose threads

- **f_mobius T010**: autopattr state save/restore not verified
- **f_mobius T011**: moduleSize.js chain not verified
- **f_mobius T013**: cx/cy via xy encoder not tested
- **f_mobius T016**: composition with f_droste not tested
- **f_mobius docs**: `docs/f_mobius.md` not written yet
- **f_chladni T018/T019**: mic test and tuning toggle test still pending
- **f_chladni loadbang**: coefficients don't load automatically on patch open — workaround is clicking umenu
