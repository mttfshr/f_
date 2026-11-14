# Sampling textures in a jit.gl.pix codebox

Part of the jit-gen-codebox skill. Max 9, `jit.gl.pix`, float32, measured on
one machine's GPU unless marked otherwise.

Contents: out-of-range coordinates and `boundmode` · hardware `sample()`
accuracy (minifying, jumpy coordinates, texel corners) · interpolating by hand
with `nearest()` · fixed-resolution stages and prefiltering · edge artifacts in
ring gathers · texture size is not readable

---

## Out-of-range coordinates and the `boundmode` keyword — bench 2026-11-14

Measured with the input fed pix-to-pix (how a chain of pix stages runs), plus
earlier probes of 2026-10-20. **A matrix-fed input (`jit.matrix` or
`jit.movie` into the pix) is untested**; a 2026-06-21 scratch observation that
the default is clamp was probably that case.

- **Default (no keyword): both `sample()` and `nearest()` WRAP,** on both
  axes: -0.2 reads 0.8, 1.3 reads 0.3.
- **Exactly 0.0 or 1.0 is a seam, not an edge:** on x both read the FIRST
  texel; on y both read the LAST row (`1 - fract(1 - v)`). Same for `sample()`
  and `nearest()`. So `clamp(coord, 0, 1)` before a bare `sample()` protects
  only two of the four edges (x = 1.0 reads the first column, y = 0.0 the last
  row). To clamp by hand, clamp to texel-centre bounds (e.g. 0.999 on x, 0.001
  on y), not exactly 0.0 / 1.0.
- **The `boundmode` keyword works** (`sample(in1, c, boundmode="clamp")`,
  also on `nearest()`). (An earlier belief that it is silently ignored was
  wrong.)
  - `"clamp"`: clamps on x and y. The simplest way to get clamp-to-edge. Its
    behavior at exactly 0.0 / 1.0 was not probed; inferred, not verified, that
    it fixes the seam above.
  - `"wrap"`: wraps on x and y (same as the default).
  - `"mirror"`: mirrors on **x only**. On y it read as WRAP (coordinates below
    0; above 1 not probed). Cause unknown. Mirror y by hand:
    `v_m = 1.0 - abs(1.0 - mod(abs(v), 2.0))`.
  - An unknown value (`"bogus"`) compiles silently and behaves as the
    default. A typo gives no error.
- **`nearest()` at a literal coordinate returned an interpolated value**
  (`nearest(in1, vec(-0.2, ...))` read 0.79999, not the texel centre 0.8047);
  at run-time coordinates it returned texel centres. Observed once; cause not
  investigated.

Say what you want rather than rely on the default:

```
col = sample(in1, vec(uv.x + offset, uv.y), boundmode="clamp");   // or "wrap"
```

**When testing out-of-range behavior, use literal coordinates.** An earlier
"squished texture" result came from the stored-variable component failure:
`sample(in1, vec(oob_u, norm.y))` with a broken `oob_u` was silently sampling
at `norm.x`.

---

## Hardware `sample()` accuracy

**At 1:1 and when magnifying,** `sample()` is exact bilinear, with 8-bit
interpolation weights (error about 1e-3 for general fractions; median 2e-5,
max 1.2e-4 on smooth data). Its neighbor taps clamp: a `fract()`ed coordinate
does not wrap them, giving a 0.5 error at a periodic seam. A manual 4-tap with
`wrap(x, 0, N)` on integer indices is exact and periodic (1e-6). (bench
2026-09-22)

### Nearest-like when minifying (source larger than the pix) — bench 2026-09-22, 2026-09-28
When the output is smaller than the source, `sample()` behaves like nearest
(half a source texel off). Measured with white noise: one tap into 1920x1080
or 3840x2160 gave 5.97x / 11.6x the noise of an exact area average; the
bilinear model predicts 3.8x / 9.3x, the nearest model 5.9x / 11.5x. So any
codebox reading a much larger texture needs its own averaging.

### Nearest when the coordinate is data-dependent and jumpy — bench 2026-10-06
Texture filtering chooses magnify or minify from the coordinate's screen-space
derivative. When a dependent read's coordinate jumps by more than about one
texel between neighboring pixels (Newton iterations starting in different
cells, ray marching, fractal iteration, a gather over jumpy candidates), the
read falls back to the NEAREST minification filter and the texture reads
piecewise-constant: error up to half a texel of variation (median 6e-3 against
2e-5 at pixel-aligned coordinates, on a field changing 0.06 per texel). Smooth
warps (coordinate = uv + smooth offset) stay bilinear. Same mechanism as
minifying. It is silent: no error, plausible output, and iterations that never
converge. If a GPU result disagrees with a reference only where coordinates
are jumpy, suspect this before float32 arithmetic (a step-for-step float32
mirror was identical to the float64 one).

### A tap on a texel corner returns ONE texel — bench 2026-10-25
A reduction chain assumed each `sample()` at a block corner averages the four
surrounding texels (16 taps per stage, 4 x 4 blocks). The GPU block values had
twice the std of the true 8 x 8 block means (0.072 against 0.036) and
correlated only 0.5 with them: what averaging 16 single texels (not 64) looks
like. Which texel comes back varies with rounding. Don't rely on `sample()` to
interpolate at texel corners or at 1:1 in a pix-to-pix chain; this bites even
with smooth coordinates.

---

## Interpolating by hand with `nearest()`

**`nearest()` takes NORMALIZED coordinates, same as `sample()`** (bench
2026-10-17). Passing raw texel indices (`ix + 0.5`) sent every interior tap to
coordinates around 89, which read the frame border: a result that looks like
an edge-smeared version of the truth. If taps disagree with a reference by a
large coordinate-scale shift, check units before math.

Exact bilinear from four `nearest()` taps at texel centres (about 3.7x the
reads of one `sample()`; with it the GPU matched a float32 NumPy mirror to
r = 1.0000):

```
fxy(u, v) {                       // texture side W (here 256); returns the decoded field (x, y)
  tx = u * 256.0 - 0.5;  ty = v * 256.0 - 0.5;
  ix = floor(tx);  iy = floor(ty);  ax = tx - ix;  ay = ty - iy;
  x0c = (ix + 0.5) / 256.0;  x1c = (ix + 1.5) / 256.0;  y0c = (iy + 0.5) / 256.0;  y1c = (iy + 1.5) / 256.0;
  px = (nearest(in2, vec(x0c, y0c)).x * (1.0 - ax) + nearest(in2, vec(x1c, y0c)).x * ax) * (1.0 - ay)
     + (nearest(in2, vec(x0c, y1c)).x * (1.0 - ax) + nearest(in2, vec(x1c, y1c)).x * ax) * ay;
  py = (same with .y);
  return (px - 0.5) * 2.0, (py - 0.5) * 2.0;
}
fx, fy = fxy(wu, wv);
```

For exact reductions, use `nearest()` at texel centres
(`(ix + 0.5) / width`) and do the arithmetic yourself: a 1024 → 1 mean is
five stages of 4 x 4 blocks, 16 taps each (1024 → 256 → 64 → 16 → 4 → 1).
One 256-tap unrolled stage overflows the compiler (see
`numerics-and-limits.md`).

---

## Fixed-resolution stages are resamplers — 2026-09-28/29

**Any internal stage with a fixed `@dim` minifies every input it reads from
the render,** by render_size / internal_dim: 4-15x at HD/4K for a 256² grid.
With nearest-like minification, one `sample()` per texel then reads well under
1% of the source and aliases hard on noisy input. The codebox can't read an
input's size, so nothing warns you. Treat it as a design consequence of
choosing an internal resolution.

**Fix, which needs no source size:** average a `taps x taps` grid of
`sample()` calls at offsets in NORMALIZED coordinates. A nested `for` bounded
by an expression of a Param compiles and runs
(`tn = max(1, floor(taps)); for (a = 0; a < tn; a += 1) { for (b = 0; ...`).
Cost ~ taps²: 8 taps about 0.4-0.7 ms, 16 about 1.2-1.7 ms for a 256² pix
reading an HD/4K input. Keep components inline on each `sample()`.

**Prefiltering is a correctness setting, not a performance control.** It does
nothing on smooth inputs and only removes noise on noisy ones; there is no
expressive range to perform. Fix it at a measured value in the shader
(`Param taps(8)`) rather than spending a user-facing control on it.

---

## Edge artifacts when gathering a ring of samples — scratch patch 2026-06-21

A codebox that samples a ring of positions around each pixel reads
out-of-range positions for pixels within `reach` of any edge. Those read a
value from elsewhere in the frame (the opposite side, since the default
wraps; the edge pixel under clamp), entering the accumulation asymmetrically:
visible bands along all four edges, width proportional to `reach`. Fix (valid
under either mode): zero-gate out-of-range samples, so the field weakens
naturally near edges:

```
in_bounds = step(0., su) * step(su, 1.) * step(0., sv) * step(sv, 1.);
w = max(luma - threshold, 0.0) * in_bounds;
```

Compute ring positions from `norm.x`/`norm.y` directly, not from a stored
`uv = norm` (`uv.x` silently reads 0, centring the ring on the origin).

---

## A codebox can't read a texture's size

`texdim()` is not defined and `in1.dim` returns 0 (bench 2026-09-22). `dim`
is the pix's own size (see `pix-object.md`). Manual bilinear taps therefore
need the size as a literal or a Param, or work in normalized offsets.
