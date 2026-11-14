# Numerics and compiler limits in a jit.gl.pix codebox

Part of the jit-gen-codebox skill. Max 9, `jit.gl.pix`, float32, measured on
one machine's GPU unless marked otherwise.

Contents: `cell` and `norm` · unary minus · `step` with literals · NaN and
`atan2` · trig precision · the sin hash vs a reference · the statement budget
· loops and branches · cost

---

## `cell` is NOT an integer pixel index — bench 2026-09-22

`cell = norm * (dim - 1)`: at texel centres `cell.x` = 0.492, 1.477, … for
dim 64 (exact to float32 across the frame). For an integer index (bin, grid
id, parity) compute `i = floor(norm.x * dim.x)`. `norm` itself is exactly
`(i + 0.5) / dim` (texel centres), and matrix row 0 is where `norm.y` is
smallest (no flip on readback).

---

## Unary minus before a parenthesis mis-compiles

- bench 2026-09-23: `exp(-(v * k2 + drag) * dt)` evaluated as
  `-v*k2 + drag*dt`.
- bench 2026-11-10: `exp(-(a + b))` compiled as `exp(-a + b)`; the sign did
  not distribute over the sum.

Write `0 - (...)` in front of any parenthesis or product, distribute the sign
(`exp(-a - b)`), or name the sum first (`s = a + b; exp(0 - s)`). A bare
negative literal (`-1`) is fine. A habit that compiled first time on a ~48-line
unrolled codebox: write negative constants as `(0 - c)`.

---

## `step()` with two literal constants folds the wrong way — bench 2026-10-06

`step(0.3, 0.5)` gives 0, not 1. With variables, `norm` or Params it follows
GLSL, `step(edge, x)` = `x >= edge`. Never test `step` with two literals; for
`a < b` write `1.0 - step(b, a)`.

---

## NaN

- **`NaN == NaN` is TRUE here** (bench 2026-09-22; seen again 2026-10-17): an
  `x == x` NaN test does nothing. `switch(abs(x) < 1e30, x, 0)` clears NaN and
  Inf. GenExpr has no `isnan()`.
- **A `mix()` guard cannot clear NaN:** `mix(NaN, safe, 1)` = NaN·0 + safe·1,
  and NaN·0 is still NaN (bench 2026-10-17).
- **Not characterized (don't build on it):** one shader survived flat content
  with `mix(NaN, 0.5, flag)` while another's identically shaped
  `mix(NaN, 0.0, flag)` did not clear the NaN. The compiler's select/fold
  behavior on `mix` with a computed-NaN operand is unknown. Fix NaN at its
  source instead.

### `atan2`
- **Accurate,** including on decoded sampled-texture input (bench 2026-10-12):
  all four quadrants match `np.arctan2` to 5.6e-7 rad; the ±π branch cut is
  wrapped correctly (adjacent-texel 2π jumps, no smearing across the cut); the
  half-angle and doubled-angle round trips pass. **Quirk:** at the cut
  (`y == 0, x < 0`) the GPU returns +π where IEEE `atan2(-0, -x)` gives −π.
  Benign for angles (the same line), but a reference comparison must
  wrap-compare there.
- **Runtime `atan2(0, 0)` returned NaN** (bench 2026-10-17) for zeros sampled
  from a texture: a flat, edge-free region of a structure-tensor field
  rendered all black with a clean console, NaN propagating through `cos`/`sin`.
  Compile-time literals fold to 0. *Counter-observation (2026-10-20):* zeros
  made by arithmetic on `norm` read +π, finite (π for x < 0, y = 0; 0 for
  x > 0). GLSL leaves `atan2(0, 0)` undefined: treat it as undefined, never as
  a specific value.
- **Fix at the source; never let (0, 0) reach it:** bias an argument,
  `atan2(y, x + 1e-7)`. Where the bias matters the input is near-degenerate
  (for a tensor, near-isotropic), so the resulting angle renders the same in
  anything rotation-symmetric.

---

## Trig precision

- **Reduce trig arguments before `sin`/`cos` in long accumulations**
  (bench 2026-09-22): a DFT twiddle computed as `twopi * mod(k * n, N) / N`
  instead of `twopi * k * n / N` was about 12x more accurate at N = 256
  (6.8e-7 vs 8.0e-6 relative). Large float32 angles lose precision before the
  function runs.
- **But one `cos`/`sin` at a large argument is fine** (bench 2026-10-26): a
  7-octave x 5-wave plane-wave sum (phases up to ~1.6e3 rad, ~1e4 on a
  negligible octave) matched float64 to 3.7e-5 over 12 parameter sets, with or
  without argument reduction (3.7e-5 vs 3.2e-5). The 12x gain above is an
  accumulation effect over 256 taps.
- **An unbounded phase accumulator multiplied by a growing scale does lose
  precision** (a level of precision lost by 1e4): wrap it; a phase in turns
  times an integer 2^i stays exactly periodic.

## The sin hash does not match a reference per pixel — bench 2026-11-14

One float32 ulp of `sin(...)`, times 43758, moves the hash by about 2.6e-3, and
the GPU's `sin` differs from NumPy's by about an ulp, so hashed cells flip.
Compare hash-driven output by means, lit fractions or distributions, with
tolerances taken from the reference's own spread over seeds, not pixel by
pixel.

---

## The compiler's statement budget — bench 2026-10-06

Too much code fails with `lua: [string DSL.Parser]: stack overflow (too many
captures)`. Bisected:

- About **250 statements** in one function body or at the top level (260
  fails), about **450 for the whole program** (450 compiled, 458 failed); a
  `for` body tolerates more (680).
- It is not bytes or lines: 600 one-statement lines and 120 lines packed five
  to a line behave the same, and a complicated 11 KB program compiled where a
  7.7 KB file of 600 simple statements failed.
- A loop's iteration count does not matter (iterations are not statements).
- A function body is counted once however often it is called, and a call is
  one statement, so repeated code belongs in functions; but see the next
  point.
- `require("file")` **adds no budget**: it is a textual include (two required
  files of 150 statements compile, four fail, like the same code inline).
- A 256-tap unrolled shader overflows it (2026-10-25); a chain of four
  16-tap stages compiled.

**Call sites of big functions cost too** (2026-11-14; mechanism inferred): a
codebox of about 228 statements (counted by semicolons), far under 450, failed
with the same error in Max's GL3 shader transformer
(`lua: [string DSL.Parser]:393: stack overflow (too many captures)`). Bisected
offline: no single line caused it, and the 209-statement version before it
also failed once ~12 lines or one small function were added. The fix cut the
statement count only to 218 but cut the copies of a big function (about 50
lines, multi-value return, nested calls) from 7 (3 hand-inlined blocks + 4
calls) to 3, and it compiled. So "a body is counted once" did not hold here;
inferred, the transformer sees the generated GLSL with bodies expanded per
call. Rule: call a big function a few times, not many; pick per-call inputs
(source, channel, settings row) in the main body and run one call per output
slot.

**After such a failure, verify the next results:** in a test harness, every
later render returned the same stale image with no error until the harness
was reopened (2026-10-06, 2026-10-25). Whether that is the pix or the harness
was not isolated. Before trusting results after a compile failure, render a
known-good codebox.

---

## Loops and branches

- **Long fixed-count loops compile fine** (bench 2026-09-22): 128-, 256- and
  512-iteration `for` loops with four `nearest()` reads per iteration gave
  correct results (separable DFT vs `np.fft`, ~1e-7 relative).
- **A `Param`-bounded loop compiles and runs** (row DFT matched `np.fft` at
  N = 128 and 64), so a bound need not be a literal; nested loops bounded by
  an expression of a Param work too (`sampling.md`).
- **A uniform branch** (`if (weight > 0.001)` on a Param-only value) and a
  per-iteration `smoothstep` fade both compile and run (2026-10-26); neither
  changed the cost at the size tested.
- Use `for`/`while` with care on the GPU; declare loop-carried variables
  before the loop (SKILL.md).

---

## Cost reference

- A 7-octave x 5-wave shader (35 `cos` + 35 `sin` + 14 `exp` per pixel,
  three outlets) cost under 0.21 ms per pass at 1920x1080 on an M3 Max (an
  upper bound, below what the harness resolves). Other machines not measured.
- A taps x taps averaging grid: see `sampling.md`.
- Hand bilinear from four `nearest()` taps: about 3.7x the reads of one
  `sample()`.
