# f_a_purr — Implementation Plan

_Created: 2026-07-27_

## Architecture Decisions

### ADR-1 — `f_a_` prefix for audio modules
`f_a_` denotes audio-domain synthesis or conditioning: no texture inlet, no
texture outlet, no vsynth GL context. Bare `f_` would misrepresent the module,
since it currently means "visual module with texture in and texture out."

Most `f_` structural conventions do not apply — no `jit.gl.pix`, no
`routepass jit_gl_texture`, no `moduleSize.js`, and `build_patcher.py` cannot
generate it. What carries over: the three-stage lifecycle, UI styling, named
control-message dispatch, session-end update discipline.

`f_breath_phase` renamed to `f_a_breath_phase` under this decision, resolving
its open `f_bio_` question. The defining characteristic is the audio domain,
not the biological source.

### ADR-2 — Everything in one gen~; scheduler in the patcher
Layers 0–4 live in a single `gen~` codebox. Layer 5 (behavioural) is a Max
patcher-level scheduler.

Breath lives inside `gen~` rather than being passed in: per-cycle jitter needs
sample-accurate access to breath phase, and phase is emitted on `out1` anyway,
so there is no cost to keeping it internal.

### ADR-3 — Jitter is latched per cycle, never continuous
Continuous modulation of the ramp frequency is vibrato. Per-cycle resampling
is biological irregularity. These are different sounds and only the second is
wanted.

Breath's influence on rate is folded into the latched value rather than
applied continuously, so rate is constant within a cycle. Correct on physical
grounds too — a real purr's rate changes between cycles, not within one.

### ADR-4 — Click decay is an absolute one-pole, not ramp-driven
An earlier design derived the decay envelope from the accumulator's phase.
Rejected: it couples decay time to pulse rate, so changing rate silently
changes every click's length and `rate_jit` and `decay_ms` can never be tested
independently.

```
coeff = exp(-1 / (decay_ms * 0.001 * samplerate));
env   = trig ? amp_target : env_prev * coeff;
```

Also permits `decay_ms` to exceed the cycle period, giving overlapping clicks.
Probably ugly, but a real region of the space that should not be structurally
excluded.

### ADR-5 — Hand-rolled two-pole resonator, not `biquad`/`svf`
Uses only operators empirically verified working in this codebox: `History`,
`cos`, `twopi`, `samplerate`, arithmetic. Chosen after several assumed
operator behaviours turned out to be wrong; the cost of a stdlib filter object
misbehaving mid-debug outweighs the convenience.

Input scaled by `(1 - q)` so output level stays roughly constant as `res_q`
sweeps — the ear hears resonance change rather than volume.

### ADR-6 — All params clamped inside the codebox
Dial ranges protect the UI path but not the message path. In a feedback
topology an out-of-range value does not merely sound wrong: it drives the
resonator unstable, `History` state goes to NaN, and the NaN persists after
the bad value is removed. Silence that survives correcting the input.

Every `Param` is clamped at the top of the codebox and only clamped names are
used downstream.

## gen~ Codebox Constraints (empirical, 2026-07-27)

These cost real debugging time and are not documented anywhere else.

**A gen~ codebox needs at least one `in` object for `Param` messages to
reach it, even when the code uses no signal input.** Without it, `Param`
values never arrive and the module is silent with an empty console. Found
empirically after two incorrect assertions to the contrary.

**`latch` initialises to 0 regardless of any `History` initialiser feeding
it.** In a self-dependent feedback loop this deadlocks permanently: `latch`
outputs 0 before the first trigger, the accumulator never advances, so the
trigger never fires, so `latch` never updates. Use the self-referential
conditional instead:

```
rate_h = trig ? rate_target : r_held;
```

**Read every `History` into a local before writing it.** Reading and writing
the same `History` in one expression is the pattern that caused the `latch`
failure. `p1 = y1; p2 = y2;` then compute, then assign.

**`noise` is a hard failure on the `jit.gl.pix` GPU path but valid in gen~.**
Different compiler, different domain. Do not import GPU-path constraints
wholesale from `skills/jit-gen-codebox/SKILL.md`.

**Codebox contents live under the `code` key in `.maxpat` JSON, not `text`.**
Writing to `text` produces a codebox that silently falls back to the default
template. Cost several exchanges of misdirected debugging.

## Phases

- **Phase 1 — concept and interface.** Complete. `ideas/f_a_purr.md`.
- **Phase 2 — scratch verification.** Partial. Layers 0/1 + resonator
  confirmed audible. Layers 2 and 4 not yet built. Jitter bands unresolved.
- **Phase 3 — parameter characterisation.** Not started. Blocked on resolving
  the primary risk in spec.md.
- **Phase 4 — production build.** Not started. No `definition.py` equivalent
  exists for `f_a_` modules; build path must be decided. Scoped (not solved)
  2026-09-16 in `ideas/f_a_build_process.md` — a follow-up project, not
  something to resolve while finishing this module's earlier phases.
- **Phase 5 — docs and helpfile.** Not started.
