# Known-good patterns for jit.gl.pix codeboxes

Part of the jit-gen-codebox skill. Max 9, `jit.gl.pix`. Each pattern was
confirmed working on the GPU path on the date given.

Contents: user-defined functions · sin hash · texture sampling basics ·
bypass · branchless selection · polar coordinates · per-row modulation ·
gate box vs shape silhouette · accumulating vectors · complex/Möbius math ·
debugging numeric mismatches

---

## User-defined functions — 2026-06-18

```
// Declare BEFORE Param statements and the main body
// No 'def' keyword: bare funcname(args) { ... return val; }
// Params are NOT visible inside: pass them as arguments

eval_field(ux, uy, radius, reflect, phase) {
    ddx = ux - 0.5;
    ddy = uy - 0.5;
    rs  = max(sqrt(ddx*ddx + ddy*ddy) * 2.0 * radius, 0.001);
    th  = atan2(ddy, ddx);
    ev  = sqrt(2.0 / (pi * rs));
    return ev * cos(rs - 2.4048) * cos(0.0*th + phase);
}

Param dishradius(1.0);
Param ph0(0.0);

result = eval_field(norm.x, norm.y, dishradius, 0.0, ph0);

// Central-difference gradient sampling:
eps = 0.004;
t_xp = eval_field(norm.x + eps, norm.y, dishradius, 0.0, ph0);
t_xn = eval_field(norm.x - eps, norm.y, dishradius, 0.0, ph0);
gx = (t_xp - t_xn) / (2.0 * eps);
```

Calling a big function many times can overflow the compiler; see
`numerics-and-limits.md`.

---

## Sin hash (noise substitute)

```
// 1D hash: stable, GPU-safe
hash1d = fract(sin(x * 43758.5453) * 43758.5453);

// 2D hash
hash2d = fract(sin(x * 127.1 + y * 311.7) * 43758.5453);

// Seeded hash (smoothly interpolated across seed values)
s0 = floor(seed); s1 = s0 + 1.0; sf = fract(seed);
ha = fract(sin((x + s0) * 213.7 + (y + s0) * 157.3) * 43758.5453);
hb = fract(sin((x + s1) * 213.7 + (y + s1) * 157.3) * 43758.5453);
h = mix(ha, hb, sf);
```

It won't match a CPU reference pixel for pixel (`numerics-and-limits.md`):
compare statistics.

---

## Texture sampling basics

```
uv = norm;

// Access channels inline on the call, never on a stored result
luma = sample(in1, uv).x;

// Explicit edge behavior rather than the default (wrap)
col = sample(in1, vec(uv.x + offset, uv.y), boundmode="clamp");

// Aspect-correct UV for generators
aspect = dim.x / dim.y;
px = uv.x * aspect;
py = uv.y;
```

---

## Bypass

```
// Processor
out1 = mix(effect_out, sample(in1, norm), bypass);

// Dual-mode generator
out1 = mix(result, mix(vec(0,0,0,1), sample(in1, norm), step(0.5, src_mode)), bypass);
```

`bypass` here is a Param; the pix's native `@bypass` attribute skips the
shader instead and flips secondary outlets (`pix-object.md`), so give the
Param a different name (`bypass_gate`) if both could be in play.

---

## Branchless selection

```
// step() for a hard threshold
result = mix(val_false, val_true, step(threshold, x));

// switch(condition, true_val, false_val)
result = switch(uv.x > 0.5, 1.0, 0.0);  // 1.0 on the right, 0.0 on the left

// smoothstep() for a soft threshold
result = smoothstep(edge0, edge1, x);
```

---

## Polar coordinates

```
r, theta = cartopol(snorm.x, snorm.y);
// or by hand:
r = sqrt(snorm.x * snorm.x + snorm.y * snorm.y);
theta = atan2(snorm.y, snorm.x);
```

---

## Per-row modulation sampling

For patterns (e.g. courses of bricks) where modulation must be identical
across every pixel of a row, sample the modulation texture at the row's
centre; this also breaks circularity with per-pixel geometry:

```
course_uv = vec(0.5, (course_idx + 0.5) / course_scale);
mod_val = sample(in2, course_uv).x;
```

---

## A discrete item's gate is a bounding box, not the shape's silhouette — 2026-07-22

In a "seed/mark" codebox, a position-based `gate` (a rectangle test of
`along`/`across` against a `size`-derived half-extent) is combined with a
separately sampled shape texture that draws the visible silhouette inside the
box. The box is almost always larger than the shape: most of it reads black
only because the shape texture is black there. Easy to miss, because box and
shape look identical while everything inside is shape-colored or black.

The bug: blending a **per-seed constant** (a color sampled once at the seed,
an id, anything constant across the box) using `gate` as the mask floods the
*whole box* with it. With seed spacing near the gate size this reads as a
full tessellation with hard box edges, easily mistaken for a Voronoi bug
elsewhere in the chain (seen: a per-seed sampled color produced a full-frame
flat-colored tessellation instead of a per-mark tint).

**Weight per-seed constants by the shape's own luma/alpha, not just `gate`:**
`gate` confines where marks can appear; `shape_luma` confines where this mark
is drawn.

```
// WRONG: floods the gate box with drive_color
blend = color_mode;
final_r = mix(shape_r, drive_r, blend);
mark_r = final_r * gate;

// CORRECT: confine the swap to the shape's footprint
blend = color_mode * shape_luma;
final_r = mix(shape_r, drive_r, blend);
mark_r = final_r * gate;
```

Any per-seed id, gradient sample or constant blended into a discrete-item
codebox needs the same weighting.

---

## Accumulating vectors: `vec4 + vec4` on stored variables — 2026-07-15

Elementwise addition of two stored `vec4`s (not component-sliced) is safe,
like `vec4 * vec4` and `vec4 * scalar`. When accumulating color onto a base
`vec4`, zero the alpha of what you add, or two alpha-1.0 vectors push alpha
past 1.0:

```
ghost_vec = vec(ghost_r, ghost_g, ghost_b, 0.0);
effect_out = effect_out + ghost_vec * ghost;
```

---

## Complex and Möbius arithmetic — 2026-07-09

GenExpr has no complex type. A complex value as two scalars (`_re`, `_im`)
and a 2x2 complex Möbius matrix as eight scalars work correctly (confirmed by
hand derivation and an isolated GPU test with hardcoded literals checked
against hand-computed output):

```
cmulre(are, aim, bre, bim) { return are*bre - aim*bim; }
cmulim(are, aim, bre, bim) { return are*bim + aim*bre; }

cdivre(are, aim, bre, bim) {
    dd = max(bre*bre + bim*bim, 0.0001);
    return (are*bre + aim*bim) / dd;
}
cdivim(are, aim, bre, bim) {
    dd = max(bre*bre + bim*bim, 0.0001);
    return (aim*bre - are*bim) / dd;
}

// Möbius point map (a*z+b)/(c*z+d), as two single-return functions
mobPtX(Are,Aim,Bre,Bim,Cre,Cim,Dre,Dim,Px,Py) {
    numre = cmulre(Px,Py,Are,Aim) + Bre;
    numim = cmulim(Px,Py,Are,Aim) + Bim;
    denre = cmulre(Px,Py,Cre,Cim) + Dre;
    denim = cmulim(Px,Py,Cre,Cim) + Dim;
    return cdivre(numre,numim,denre,denim);
}
mobPtY(Are,Aim,Bre,Bim,Cre,Cim,Dre,Dim,Px,Py) {
    numre = cmulre(Px,Py,Are,Aim) + Bre;
    numim = cmulim(Px,Py,Are,Aim) + Bim;
    denre = cmulre(Px,Py,Cre,Cim) + Dre;
    denim = cmulim(Px,Py,Cre,Cim) + Dim;
    return cdivim(numre,numim,denre,denim);
}
```

Composing a chain of anti-holomorphic maps (circle inversions, line
reflections) into one matrix follows `N_{k+1} = M_{k+1} * conj(N_k)` (matrix
product, entries of `N_k` conjugated) regardless of parity; the result is
`N_k(z)` for an even step count, `N_k(conj(z))` for odd. The inverse of a
Möbius matrix is the adjugate swap-and-negate (`d, -b, -c, a`), with **no
division by the determinant**, since scaling all four entries doesn't change
the transform.

---

## Debugging numeric mismatches: suspect the threshold near poles — 2026-07-09

Comparing two mathematically equivalent formulations (e.g. a real-vector
circle inversion vs a complex-matrix reconstruction) through an error-magnitude
debug view, a **tight threshold (0.01) produces false "bug" patterns** where
the map sends points to large magnitudes (near a pole): float32 softness, not
a logic error. Loosening it to 0.3 shrank a persistent four-lobed mismatch
dramatically, after hand checks had already shown the formulas correct.

When a mismatch survives several isolation attempts (fresh vs loop state,
literals vs Params, in vs out of a loop, different configurations) and the
math checks out by hand every time, loosen the threshold by an order of
magnitude: if the region shrinks proportionally it's precision; if it stays
the same size it's a real bug. Cheap and often decisive: try it early.
