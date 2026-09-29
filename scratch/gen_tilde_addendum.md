
---

## Carried over from `jit-gen-codebox` (2026-09-29)

The findings below were originally filed in the `jit.gl.pix` skill during
`f_a_purr` development and moved here when the two copies of that skill were
reconciled. They are gen~ rules, not GPU rules.

**Everything above this section is `jit.gl.pix` GPU-path only.** `gen~`
(audio-rate, CPU) is a different compiler with different rules. Source:
`f_a_purr` (first `f_a_` audio module), 2026-07-27 — see
`.specify/f_a_purr/plan.md` for full context. This section exists because
importing GPU-path constraints wholesale into a `gen~` codebox is an easy
mistake given how much codebox experience on this project is GPU-side, and
at least one of the rules below is a direct **reversal** of a GPU-path rule.

### `noise()` is valid in gen~ — reversal of the GPU rule
On the `jit.gl.pix` GPU path, `noise()` compiles silently but always
outputs black (see "Silent Failures" above) — the fix there is a sin hash.
**In gen~, `noise()` is a real, working operator.** Do not reflexively
swap it for a sin hash in audio-domain code; that GPU-path fix does not
apply here and there is no reason to avoid the built-in.

### A gen~ codebox needs at least one `in` object for `Param` messages to arrive
Without an `in N` object present in the gen~ subpatcher — even when the
codebox uses no signal input at all and every parameter arrives as a
`Param` message — `Param` values never reach the codebox. The module
compiles clean and runs, but is silent, with an empty console and no
error pointing at the cause. Confirmed empirically after two incorrect
assertions to the contrary during `f_a_purr` development.

### `latch` zero-initializes regardless of any `History` initializer — deadlocks self-dependent feedback
`latch` outputs 0 before its first trigger, ignoring whatever initial
value a feeding `History` was declared with. In a self-dependent feedback
loop (a per-cycle accumulator whose own held rate depends on a trigger
that in turn depends on the accumulator advancing), this is a permanent
deadlock: `latch` outputs 0, the accumulator never advances, so the
trigger never fires, so `latch` never updates. **Use a self-referential
conditional instead of `latch`:**
```
// WRONG — deadlocks permanently in a self-dependent feedback loop
rate_h = latch(rate_target, trig);

// CORRECT
rate_h = trig ? rate_target : r_held;   // r_held read from History before this line
```

### Read every `History` into a local before writing it, when both happen in one block
Reading and writing the same `History` variable within one expression
block is the pattern that caused the `latch` failure above and is worth
treating as a general precaution in gen~: read the held value into a
local name first, use the local for computation, then write the
`History` once, near the end of the block.
```
r_held = rate_h;                       // read first
rate_target = ...;                     // compute using r_held
rate_h = trig ? rate_target : r_held;  // write once, using the local for the untriggered case
```
Simple single-read-then-single-write History updates (e.g. a plain
accumulator: `ph_acc = ph_prev + step; ...; ph_prev = ph_acc - trig;`)
are fine without a separate local — this precaution matters most when the
same History's old value is needed again *after* something else has
already been computed from it, which is exactly the shape that broke with
`latch`.

### Codebox contents live under the `code` key in `.maxpat` JSON — not `text`
If hand-writing or scripting a `.maxpat` file's codebox object, the
key holding the GenExpr source is `code`. Writing to `text` instead
produces a codebox that silently falls back to the default template —
no error, just a codebox that isn't running the code you wrote. Cost
real debugging time on `f_a_purr` before being traced to this. If a
script writes `.maxpat` codeboxes programmatically, verify the key name
directly rather than assuming; see `_build_purr_scratch.py` for a
concrete case where this was wrong and is now flagged as stale/unsafe to
run rather than blindly re-fixed and re-trusted.
