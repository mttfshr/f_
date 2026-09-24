---
name: jit-gen-codebox
description: Canonical reference for writing jit.gl.pix codebox code in f_ Vsynth bpatchers. Use when writing, reviewing, or debugging any codebox in a jit.gl.pix gen subpatcher. Covers valid operators, silent failure patterns, known-good idioms, and a health check checklist. All findings are empirically verified in Max 9 jit.gl.pix GPU path — not just from docs.
---

# jit.gl.pix Codebox Reference

**Canonical docs:** https://docs.cycling74.com/userguide/gen/gen_genexpr/

Empirically verified operator reference for GenExpr code inside `jit.gl.pix` gen subpatchers. All findings verified in Max 9 against the Vsynth `vsynth` GL context. The GPU path (jit.gl.pix) has important differences from the CPU path (jit.gen, jit.pix) — operators listed in Cycling '74 docs may still fail silently on GPU.

**Source of truth:** `/Users/matt/Github/f_/.specify/codebox.skill/tasks.md` — full test results.


**Evidence levels (since 2026-09-22).** Entries here were mostly verified by
eye in a scratch patch. The `f_` test bench (`tests/bench.sh`) can now verify
GenExpr behavior *numerically* on the GPU — see "Bench-Verified Facts" below.
When adding or revising an entry, say which kind of evidence backs it
(bench / scratch patch / docs-only), and prefer the bench for anything that
can be stated as numbers. A codebox under development should be checked with
`benchclient.run_pass()` before being declared working.

---

## Language Model

GenExpr is a typeless expression language compiled to GLSL for `jit.gl.pix`. It resembles C but has important restrictions:

- **No type declarations** — do not write `float x`, `float4 col`, `int n`, etc. Variables are untyped; just assign: `x = 1.0;`. Type keywords are not valid syntax and will cause errors.
- No array notation (`[index]`)
- No pointer types
- Semicolons required for multi-line code
- Variables are local-to-scope by default — no `var` keyword needed
- Functions must be declared before all statements (before `Param` declarations and main body)
- User-defined functions are supported in jit.gl.pix GPU path — **confirmed working 2026-06-18**
- Function syntax: `funcname(arg1, arg2, ...) { ... return val; }` — no `def` keyword
- `Param` values are NOT accessible inside function bodies — must be passed as explicit arguments
- `in` and `out` are reserved keywords (inlet/outlet references) — do not use as variable names
- The compiler is silent about many GPU-incompatible constructs — they compile but produce black output

---

## Multiple Return Values

Functions that return multiple values use comma assignment. The compiler strips unused return values automatically — no performance penalty:

```
// cartopol returns r and theta
r, theta = cartopol(x, y);

// ignore theta — compiler optimizes it out
r = cartopol(x, y);

// ignore r
notused, theta = cartopol(x, y);
out1 = theta;

// multiple right-hand side expressions
sum, diff = in1 + in2, in1 - in2;
out1, out2 = diff, sum;
```

---

## Abstractions as Functions

Gen abstraction files (`.genjit` for jit.gl.pix) on the Max search path can be called by name from a codebox as if they were functions:

```
// Calls myHelper.genjit from the search path
out1 = myHelper(in1, in2);
```

Function names must be valid identifiers — letters, numbers, underscores only. Names with `~` or `.` are invalid.

---

## Requiring GenExpr Files

Shared function definitions can live in `.genexpr` files and be included with `require`:

```
require("myHelpers");  // loads myHelpers.genexpr from search path
out1 = myHelperFunc(in1);
```

---

## `boundmode` Attribute — GPU Status Unknown

The docs show `sample(in, norm, boundmode="mirror")` as valid GenExpr syntax. Our skill previously documented this as silently ignored on GPU. **This needs empirical verification on jit.gl.pix** — may work for some values and not others, or may be a CPU-only feature. Until verified, use manual coordinate wrapping:

```
// Safe wrap — verified GPU-working
uv_wrapped = vec(fract(uv.x + offset), fract(uv.y));
out1 = sample(in1, uv_wrapped);
```

---

## Valid Operators (confirmed in jit.gl.pix GPU path)

### Math
`+` `-` `*` `/` `%` `abs` `neg` `sign` `floor` `ceil` `fract` `sqrt` `pow` `log` `exp` `mod`

**`mod()` confirmed GPU-safe for discrete banding (2026-07-09):** tested via a
minimal isolated scratch patch (`mod_test.maxpat`) comparing `mod(x, 1.0)`
directly against a manual `x - floor(x/m)*m` fallback, split across the
frame via `snorm.y` sign so both render simultaneously. Both produced
identical vertical stripe banding — no silent divergence, no NaN, no
sign-related quirk. Safe to use directly for discrete region/id coloring
(e.g. `mod(circle_id, 2.0)` for flat lineage-based coloring), not just for
continuous wrapping.

### Trigonometry
`sin` `cos` `tan` `asin` `acos` `atan` `atan2` `sinh` `cosh` `tanh`

### Range / Interpolation
`clamp` `wrap` `fold` `mix` `smoothstep` `step`

### Comparison / Logic
`>` `<` `>=` `<=` `==` `!=` `&&` `||` `!` `min` `max`

### Control Flow
`if / else if / else` — valid and GPU-safe
`switch(condition, true_val, false_val)` — valid; argument order is condition first, then true value, then false value
`for` / `while` — valid but use with caution on GPU (fixed iteration counts only)

### Vector
`vec(x, y)` `vec(x, y, z)` `vec(x, y, z, w)` — pack scalars into vector
`concat(a, b)` — concatenate two vectors into larger vector

### Coordinate (Jitter-specific globals)
`norm` — normalized UV [0,1] as vec2, current pixel position
`snorm` — signed normalized UV [-1,1] as vec2
`cell` — **NOT an integer index on jit.gl.pix: `cell = norm * (dim - 1)`** (bench-verified 2026-09-22; see Bench-Verified Facts). Integer index: `floor(norm * dim)`
`dim` — pixel dimensions of render context as vec2 (e.g. vec(640, 480) — NOT normalized)

### Sampling
`sample(inN, coord)` — bilinear sample inN at normalized coord vec2; **default boundmode is CLAMP** (empirically verified 2026-06-21 with literal OOB coordinate — sampling at u=1.3 produces solid stripe of u=1.0 edge color)
`nearest(inN, coord)` — nearest-neighbor sample

**`uv.x` / `uv.y` silent failure in ring offset code (empirically verified 2026-06-21):**
When computing per-sample ring positions, do NOT store `norm` in a variable and then access `.x`/`.y` — that's the stored-variable component access silent failure. Use `norm.x` and `norm.y` directly:
```
// WRONG — su0 becomes dx0*reach (centered on origin, not current pixel)
uv = norm;
su0 = uv.x + dx0 * reach;  // uv.x silently returns 0

// CORRECT
su0 = norm.x + dx0 * reach;
```

**Clamp artifact in ring-accumulation modules (empirically verified 2026-06-21):**
When a module samples a ring of positions around each pixel (e.g. `f_vf_repulse`), pixels
within `reach` distance of any frame edge have some ring positions going OOB. Because
`sample()` default boundmode is CLAMP, those OOB positions read the nearest edge pixel,
introducing that edge value into the field accumulation asymmetrically. Result: visible
bands along all four edges, with band width proportional to `reach`. Fix: zero-gate any
OOB sample using:
```
in_bounds = step(0., su) * step(su, 1.) * step(0., sv) * step(sv, 1.);
w = max(luma - threshold, 0.0) * in_bounds;
```
This gives Clear semantics: OOB positions contribute zero weight, field weakens naturally
near edges rather than reading false edge-pixel values.

**Also note:** the earlier squished-texture result (before using a literal OOB value) was
caused by the stored-variable silent failure on `oob_u` — `sample(in1, vec(oob_u, norm.y))`
was silently sampling at `norm.x` instead of `oob_u`. Always use literals or verify with
literals when testing boundmode behavior.

### Color (Jitter-specific)
`hsl2rgb(vec)` — convert HSL to RGB, preserving alpha
`rgb2hsl(vec)` — convert RGB to HSL, preserving alpha

### Coordinate Math
`cartopol(x, y)` — returns r, theta (radians)
`poltocar(r, theta)` — returns x, y

### Constants
`pi` `twopi` `halfpi` `e` `phi` `sqrt2` `DEGTORAD` `RADTODEG`

### Parameters
`Param name(default)` — declares a named parameter controllable from outside gen patcher

---

## Silent Failures — Most Dangerous

These compile without error but produce black output or wrong results. No console warning.

### `noise()`
Listed in Cycling '74 docs as a common operator. Compiles with any argument signature. **Always outputs black in jit.gl.pix GPU path.** Use sin-based hash instead:
```
// canonical sin hash — verified working
hash = fract(sin(x * 43758.5453) * 43758.5453);
// or for 2D input:
hash = fract(sin(x * 127.1 + y * 311.7) * 43758.5453);
```

### Component access on stored variables
`.x/.y/.z/.w` and `.r/.g/.b` on a **stored variable** silently fail — output goes black with no error.

```
// WRONG — silent failure
col = sample(in1, uv);
r = col.x;  // black

// CORRECT — inline access on sample() return value
r = sample(in1, uv).x;
```

This is the single most common silent failure pattern. Always access components inline on the `sample()` call, never on a stored intermediate variable.

### `boundmode` attribute in GenExpr syntax
The docs show `sample(in1, coord, boundmode="wrap")`. This compiles but is **silently ignored** in jit.gl.pix — defaults to clamp regardless. To get wrap behavior, use `fract()` or `wrap()` on the coordinate before sampling:
```
// wrap manually
uv_wrapped = vec(fract(uv.x + 0.3), uv.y);
out1 = sample(in1, uv_wrapped);
```

### `swiz`
Documented operator for component remapping. Silently fails in jit.gl.pix GPU path regardless of argument syntax. Use manual `vec()` construction instead:
```
// WRONG — silent failure
swapped = swiz(col, 2, 1, 0, 3);

// CORRECT — manual channel remap via inline access
out1 = vec(sample(in1, uv).z, sample(in1, uv).y, sample(in1, uv).x, 1.0);
```

### Variable name shadowing
`cell`, `in`, `norm`, `snorm`, `dim` are coordinate operators. Using them as variable names compiles silently but produces undefined/zero output:
```
// WRONG — shadows coordinate operator
cell = floor(uv.x * 10.0);  // compiles, black output

// CORRECT
cell_idx = floor(uv.x * 10.0);
```

### `inN`-shaped variable names (e.g. `in0`, `in1`...`in7`) — UNVERIFIED root cause, but a real solid-black repro (2026-07-08)
Naming ordinary scalar variables `in0`, `in1`, ... `in7` (e.g. per-candidate
containment flags in a multi-circle loop, `f_apollonian`'s generalized-ring
work) produced solid black output with a clean console — no compile error
— in a module with **no texture inlets at all**. Suspected cause, not yet
isolated with a minimal repro: `inN` (an `in` followed by digits) is
GenExpr's actual inlet-reference syntax (`in1`, `in2`, `in3`...), and the
parser may treat any `in`+digit token as an inlet reference regardless of
whether that inlet exists in this codebox, rather than as an ordinary
identifier — silently reading as zero/undefined instead of erroring. Same
*family* as the `cell`/`norm`/`snorm`/`dim` shadowing issue above, but not
previously documented for `inN` specifically, and not yet confirmed via a
dedicated minimal test (the fix below resolved the symptom in a complex
codebox — that's correlation, not a controlled isolation).
```
// SUSPECT — silent black output despite clean console, no texture inlets used
in0 = step(dist2, r2) * active0;
in1 = step(dist2b, r2) * active1;

// FIX — avoid the inN shape entirely
ins0 = step(dist2, r2) * active0;
ins1 = step(dist2b, r2) * active1;
```
If this resurfaces, treat any variable name matching `in` + digits as
suspect, not just the literal reserved words already documented above.

### Variables first assigned inside a `for` loop are out of scope after it — confirmed 2026-07-08
A variable whose *first* assignment happens inside a `for` block cannot
be read after the loop ends — the compiler reports `"varname" is not
defined`, even though the variable clearly has a value by the time the
loop exits in any C-like mental model. This bit `f_apollonian`'s
generalized-ring work twice: once for a loop-carried accumulator
(`any_inside`), once for a sticky flag (`active`) — both needed their
values to persist past (and across) loop iterations. **Fix: declare the
variable with an initial value BEFORE the loop, then only reassign
(never first-declare) it inside the loop body:**
```
// WRONG — "any_inside" not defined outside the loop
for (i = 0; i < 16; i += 1) {
    any_inside = max(a, b);
    ...
}
result = any_inside;  // ERROR: any_inside is not defined

// CORRECT — pre-declare before the loop
any_inside = 0.0;
for (i = 0; i < 16; i += 1) {
    any_inside = max(a, b);
    ...
}
result = any_inside;  // works
```
This also applies to any loop-carried state read *inside* the loop
across iterations (an accumulator, a sticky/latching flag like
`active = active * escaped_this_iter`) — pre-declare it above the loop
even though every read of it happens inside the loop body too.

### `active` as a variable name — silent collision, confirmed 2026-07-08
Naming a scalar variable `active` (e.g. a sticky "is this pixel still
iterating" flag, `active = active * escaped_this_iter`) produced solid
black output with a clean console — no compile error — even after
pre-declaring it correctly above its loop (see previous entry) and
pairing its update via comma-assignment (neither fix helped). Renaming
the identical variable to `alive` (no other change) immediately fixed
it and produced correct output. `active` is a common Jitter/Max object
attribute name (e.g. `@active`), and is suspected — not yet proven via
a fully minimal repro — to silently collide the same way `inN` does:
compiles clean, reads as zero/undefined rather than erroring. **Treat
`active` as a reserved-word-class name to avoid**, on top of the
already-documented `cell`/`in`/`norm`/`snorm`/`dim`/`inN` list. If a
self-referential scalar accumulator produces solid black despite correct
pre-declaration and comma-assignment pairing, suspect the variable's
*name* next, not just its update pattern — this was the second such
collision found in one session, so treat this as a real class of risk
whenever introducing a new named flag/state variable, not a one-off.

---

## Hard Errors ("operator X not defined")

These produce a console error and fail to compile:

| Invalid | Use instead |
|---|---|
| `vec4(r, g, b, a)` | `vec(r, g, b, a)` |
| `vec2(x, y)` | `vec(x, y)` or scalar vars |
| `float2(x, y)` | scalar vars |
| `select(cond, a, b)` | `mix(a, b, step(threshold, val))` or `switch(cond, a, b)` |
| `cycle(x)` | `sin(x * twopi) * 0.5 + 0.5` |
| `snoise(x)` | sin hash (see above) |

### Component assignment on a stored variable — hard error, distinct from component *read* (empirically verified 2026-07-08)
Writing to a component of a stored variable (`z.x = ...`) fails to compile
with **"invalid left-hand expression"** — a hard console error, not the
silent black-output failure documented above for component *reads*
(`col.x` on the right-hand side of `=`). Both are forms of "don't treat a
stored variable as having addressable components," but they fail
differently, and only the read case was previously documented:

```
// WRONG — hard compile error, "invalid left-hand expression"
z.x = invertX(z.x, z.y, cx, cy, r);

// CORRECT — use separate scalar variables instead of one vector-like
// variable with component fields
zx = invertX(zx, zy, cx, cy, r);
zy = invertY(zx_prev, zy, cx, cy, r);  // see sequencing note below
```

**Practical fallback**: don't model a 2D point as one variable with `.x`/
`.y` fields inside a codebox — use two independent scalars (`zx`, `zy`)
throughout, and write any transform as two single-return functions (one
returning the new x, one returning the new y) rather than one function
attempting to return or assign into a vector-like result. This sidesteps
both the read-side and write-side component-access failures at once, at
the cost of some duplicated argument-passing across the two functions.

**Sequencing hazard when splitting a 2-output transform into two calls**:
if the y-output function's math depends on the *original* x (before the
x-output function's result overwrites it), capture the old value in a
third scalar before reassigning `zx`: `zx_prev = zx; zx = invertX(...);
zy = invertY(zx_prev, zy, ...);`. Getting this ordering wrong produces a
silently different (wrong) result, not a compile error — worth
double-checking any translated two-output transform for this trap.

---

## Known-Good Patterns

### Inlet/outlet count on jit.gl.pix — code-first, object-second

**Both `numinlets` and `numoutlets` on jit.gl.pix are read-only.** Neither is
settable anywhere. Same applies to the codebox itself — it is not a jsui.

**The causality is always code → connection point → object**, for both
inlets and outlets. Referencing `inN` (or `outN`) in the codebox code is what
causes that inlet (or outlet) to exist on the codebox. You do not create the
`in N`/`out N` object first and then expect a reference to "connect" to it —
the reference in the code comes first, the connection point appears as a
consequence, and only then does placing and wiring the `in N`/`out N` object
make sense.

**Inlets — three things must all be true:**
1. `inN` is referenced in the codebox code (this is what makes the inlet
   *appear* on the codebox — do this first)
2. `in N` object exists inside the gen subpatcher
3. The `in N` object is wired to that codebox inlet

**Outlets — same pattern, symmetric:**
1. `outN` is assigned in the codebox code (e.g. `out2 = period_vis;` — this
   is what makes the outlet *appear* on the codebox — do this first)
2. `out N` object exists inside the gen subpatcher
3. The codebox outlet is wired to that `out N` object

**Practical sequence when adding a new inlet or outlet:**
1. Edit the codebox code first — add the `inN`/`outN` reference
2. Compile/confirm the codebox now shows the new inlet/outlet nub
3. Only now place the `in N`/`out N` object in the gen subpatcher
4. Wire it to the newly-appeared codebox inlet/outlet

Getting this backwards (placing the `in N`/`out N` object before the code
references it, then expecting the reference to "connect" to an
already-existing nub) is a recurring source of confusion — the object alone
does nothing; the code reference is what creates the connection point.

### Inlet indexing (empirically verified 2026-06-06)

Codebox `in N` maps to outer pix inlet N-1:

- `in 1` inside gen → outer pix inlet 0 (also carries control bang)
- `in 2` inside gen → outer pix inlet 1
- `in 3` inside gen → outer pix inlet 2

There is no separate bang-only inlet. Outer inlet 0 carries both the bang and the first texture. This is different from what some Vsynth source comments imply — verified by observation.

```
// Two-texture pix: source on outer inlet 0, field on outer inlet 1
// Requires: in 1 and in 2 objects in gen subpatcher, in2 referenced in codebox, both wired
r = sample(in1, norm).x;                  // in1 = outer inlet 0
fx = (sample(in2, norm).x - 0.5) * 2.0;  // in2 = outer inlet 1

// Three-texture pix: source, light source, field
// Requires: in 1, in 2, in 3 objects in gen subpatcher, in3 referenced in codebox, all wired
src   = sample(in1, norm);   // in1 = outer inlet 0
light = sample(in2, norm);   // in2 = outer inlet 1
field = sample(in3, norm);   // in3 = outer inlet 2
```

---

### User-defined functions (confirmed GPU-safe 2026-06-18)
```
// Declare BEFORE Param statements and main body
// No 'def' keyword — bare funcname(args) { ... return val; }
// Params are NOT accessible inside — pass as arguments

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

// Call with explicit param values
result = eval_field(norm.x, norm.y, dishradius, 0.0, ph0);

// Useful for central-difference gradient sampling:
eps = 0.004;
t_xp = eval_field(norm.x + eps, norm.y, dishradius, 0.0, ph0);
t_xn = eval_field(norm.x - eps, norm.y, dishradius, 0.0, ph0);
gx = (t_xp - t_xn) / (2.0 * eps);
```

### Sin hash (noise substitute)
```
// 1D hash — stable, GPU-safe
hash1d = fract(sin(x * 43758.5453) * 43758.5453);

// 2D hash
hash2d = fract(sin(x * 127.1 + y * 311.7) * 43758.5453);

// Seeded hash (smoothly interpolated across seed values)
s0 = floor(seed); s1 = s0 + 1.0; sf = fract(seed);
ha = fract(sin((x + s0) * 213.7 + (y + s0) * 157.3) * 43758.5453);
hb = fract(sin((x + s1) * 213.7 + (y + s1) * 157.3) * 43758.5453);
h = mix(ha, hb, sf);
```

### Texture sampling
```
uv = norm;

// Basic sample — store result as vec4, access channels inline only
luma = sample(in1, uv).x;

// Wrap behavior (manual, since boundmode GenExpr syntax is broken)
uv_wrapped = vec(fract(uv.x + offset), fract(uv.y));
col = sample(in1, uv_wrapped);

// Aspect-correct UV for generators
aspect = dim.x / dim.y;
px = uv.x * aspect;
py = uv.y;
```

### Bypass pattern
```
// Processor
out1 = mix(effect_out, sample(in1, norm), bypass);

// Dual-mode generator
out1 = mix(result, mix(vec(0,0,0,1), sample(in1, norm), step(0.5, src_mode)), bypass);
```

### Branchless selection (GPU-friendly)
```
// step() for hard threshold
result = mix(val_false, val_true, step(threshold, x));

// switch() for explicit branching — switch(condition, true_val, false_val)
result = switch(uv.x > 0.5, 1.0, 0.0);  // 1.0 on right, 0.0 on left

// smoothstep() for soft threshold
result = smoothstep(edge0, edge1, x);
```

### Polar coordinates
```
sn = snorm;
r, theta = cartopol(sn.x, sn.y);
// or manually:
r = sqrt(sn.x * sn.x + sn.y * sn.y);
theta = atan2(sn.y, sn.x);
```

### Per-course modulation sampling
For masonry-style patterns where modulation must be identical across all pixels in a row:
```
// Sample at course center — breaks circularity with per-pixel geometry
course_uv = vec(0.5, (course_idx + 0.5) / course_scale);
mod_val = sample(in2, course_uv).x;
```

### `vec4 + vec4` addition on stored variables (confirmed GPU-correct 2026-07-15)
Elementwise addition of two stored `vec4` variables (not component-sliced
— see the component-access failure class above) is safe, same as the
already-confirmed `vec4 * vec4`/`vec4 * scalar` multiplication pattern
(`effect_out * warm_shift * vignette` in `f_lens`). Confirmed on
`f_lens`'s ghost-images addition, where an addend vector's alpha channel
was deliberately zeroed (`vec(r, g, b, 0.0)`) before adding to a base
`vec4` whose alpha was already 1.0, specifically to avoid alpha drifting
above 1.0 from naive whole-vector accumulation:
```
ghost_vec = vec(ghost_r, ghost_g, ghost_b, 0.0);
effect_out = effect_out + ghost_vec * ghost;  // confirmed working in Max
```
General lesson: when accumulating color contributions onto a base `vec4`
via plain addition, explicitly zero the alpha channel of anything being
added (rather than letting it default to 1.0 from a `sample()` call) —
the addition itself is GPU-safe, but the *semantics* of adding two
alpha=1.0 vectors together will push the result past 1.0 if you don't
control for it.

### Complex/Möbius arithmetic (confirmed GPU-correct 2026-07-09)
GenExpr has no complex number type. Representing a complex value as two
scalars (`_re`, `_im`) and a 2x2 complex Möbius matrix as eight scalars
(`Are,Aim,Bre,Bim,Cre,Cim,Dre,Dim`) works correctly — confirmed both by
extensive hand-derivation *and* by an isolated GPU unit test (hardcoded
literals, no loop, checked against hand-computed expected output; see
`f_apollonian`/`f_poincare` `plan.md` for the full derivation this
supported). Safe, verified building blocks:
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

// Möbius point-map (a*z+b)/(c*z+d), split into two single-return
// functions per the component-assignment rule above
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
Composing a chain of anti-holomorphic maps (e.g. circle inversions, line
reflections) into a single accumulated matrix follows
`N_{k+1} = M_{k+1} * conj(N_k)` (matrix product, entries of `N_k`
conjugated elementwise) regardless of parity; the *result* is
`N_k(z)` if the step count is even, `N_k(conj(z))` if odd. Matrix
inverse for these projective (Möbius) matrices is the plain adjugate
swap-and-negate (`d,-b,-c,a`) — **no division by determinant needed**,
since scaling all four entries by a nonzero constant doesn't change the
transform represented.

---

## Debugging Numerical Mismatches — Threshold Sensitivity Near Möbius Poles (2026-07-09)

When comparing two mathematically-equivalent formulations of a Möbius/
circle-inversion computation (e.g. a real-vector inversion formula vs.
a complex-matrix reconstruction) via an error-magnitude debug view, a
**tight mismatch threshold (e.g. `0.01`) will produce false-positive
"bug" patterns** in regions where the map sends points to large
magnitudes (near the transform's pole) — this is expected float32
precision softness inherent to the math, not a logic error. Confirmed
by loosening a threshold from `0.01` to `0.3` and watching a persistent,
confusing four-lobed mismatch pattern shrink dramatically, after
extensive independent hand-verification had already shown the underlying
formulas were correct in every case checked.

**Practical lesson**: when a debug/verification check shows a mismatch
that survives multiple isolation attempts (fresh vs. loop-tracked state,
literals vs. `Param`s, in-loop vs. out-of-loop, different geometric
configurations) *and* the underlying math checks out by hand every time,
suspect the **threshold itself** before suspecting a deeper undiscovered
logic bug — loosen it by an order of magnitude or more and see if the
mismatched region shrinks proportionally (precision) or stays exactly
the same size (real bug). This is a cheap, fast, and often decisive test
to run early, not late.

### `dim` for aspect ratio
`dim` returns pixel dimensions of the render context (e.g. 640×480), not normalized values:
```
aspect = dim.x / dim.y;   // e.g. 1.333 for 640×480
```
Do not use `dim` to get normalized output size — use `norm` for that.

---

## What NOT to Use for Randomness/Noise

| Don't use | Reason |
|---|---|
| `noise()` | Compiles silently, always black on GPU |
| `snoise()` | "operator not defined" error |
| `cycle()` | "operator not defined" error |

**Always use sin hash.** It is deterministic, spatially consistent, GPU-safe, and produces stable per-cell identities with no per-frame variation.

---

## Bench-Verified Facts (Max test bench, 2026-09-22)

Measured numerically through the `f_` test bench (`tests/bench_*.py`,
`.specify/test_bench/`), not inferred from docs or screenshots. Max 9,
jit.gl.pix, float32.

### `cell` is NOT an integer pixel index — it is `norm * (dim - 1)`
At texel centers `cell.x` = 0.492, 1.477, … for dim 64 (exact to float32
across the whole frame). Any codebox that needs an integer index (bin
number, grid id, parity) must compute it: `i = floor(norm.x * dim.x)`.
`norm` itself is exactly `(i + 0.5) / dim` (texel centers), and matrix row
0 is where `norm.y` is smallest (no flip on readback).

### Compile errors ARE catchable — but never wire `[error]` straight into `js`
A gen compile failure posts `codebox: <message>` to the Max window (e.g.
`codebox: addition op missing argument`) and `[error 1]` does output it.
Wiring `[error]` directly into a `js` object recursed: js re-reported the
incoming error, `[error]` caught that, until Max hit a stack overflow —
which disables *all outlets in Max* until the yellow bar is cleared. Safe
shape: `[error 1] → [deferlow] → [prepend some_name] → js`, with a handler
that never posts or throws.

### Long fixed-count loops compile fine
128-, 256- and 512-iteration `for` loops with four `nearest()` reads per
iteration compile and produce correct results (separable DFT vs `np.fft`:
~1e-7 relative). Loop length is not a practical limit at these sizes.

### Reduce trig arguments before `sin`/`cos`
Computing a twiddle angle as `twopi * mod(k * n, N) / N` instead of
`twopi * k * n / N` was ~12x more accurate on real GPU `sin`/`cos` at N=256
(6.8e-7 vs 8.0e-6 relative). Large float32 angles lose precision before
the trig function even runs.

### jit.gl.pix object behavior (outside the codebox)
- **Inlet count follows the gen patcher's `in` objects**, not only what
  the codebox references: a `.genjit` with `in 1..3` (only `in 1` wired to
  the codebox) gives a 3-inlet pix, and cords into inlets 1–2 survive and
  deliver. Useful to keep inlet counts stable when swapping gen patchers
  (`inputs` is read-only).
- **A texture message sent to the pix (e.g. from js `message()`) lands on
  input 0** regardless of `activeinput`; `sendinput N jit_gl_texture name`
  did *not* set input N. Use physical cords for inputs 2+.
- **A newly loaded gen compiles at its first render.** Params sent right
  after `gen <name>` — and even on the next draw bang, which fires before
  the render — hit "jit.gl.pix: invalid message <param>". Send params a
  couple of frames later.
- **Every texture message a pix receives triggers a render.** Sending it a
  second texture per frame doubles the work downstream.
- **Float32 readback is exact:** texture → `jit.matrix @type float32` via
  the matrix's `jit_gl_texture` method, then `write` to `.jxf`, round-trips
  values outside [0,1] bitwise. Matrix planes are ARGB.
- **Native `@bypass` skips the shader and flips secondary outlets**
  (module bench, 2026-09-23). With the native `bypass` attribute on, outlet 1
  equals input 0 exactly, but outlets 2+ output input 0 **vertically
  flipped** (exact `flipud`), and codebox logic like `mix(x, y, bypass)` never
  executes. Seen on 11 shipped modules (two more multi-stage modules differ). To give secondary outlets a real bypass
  state, drive a Param with a *different* name (`param bypass_gate 1`) and leave
  the native attribute off.
- **A unary minus before a parenthesis mis-parses** (bench control probe,
  2026-09-23): `exp(-(v * k2 + drag) * dt)` evaluated as `-v*k2 + drag*dt`.
  `0 - (v * k2 + drag) * dt` is correct. Write `0 - ...` in front of any
  parenthesis or product (a bare `-1` literal is fine).
- **A codebox cannot read an input texture's size**: `texdim()` is not defined,
  `in1.dim` returns 0, and `dim` is the render context's. Manual bilinear taps
  therefore need the size as a literal or a Param.
- **Hardware `sample()` on this GPU**: exact bilinear at 1:1 and when
  magnifying, but with 8-bit interpolation weights (~1e-3 for general
  fractions), it clamps its neighbor taps (a `fract()`ed coordinate does not
  wrap them: 0.5 error at a periodic seam), and it is **nearest-like when the
  output is smaller than the source** (half a source texel off). A manual
  4-tap with `wrap(x, 0, N)` on integer indices is exact and periodic (1e-6).
- **`NaN == NaN` is TRUE on jit.gl.pix here**: an `x == x` NaN test does
  nothing. `switch(abs(x) < 1e30, x, 0)` clears NaN and Inf.
- **A `Param`-bounded `for` loop compiles and runs** on jit.gl.pix (row DFT
  matched `np.fft` at N = 128 and 64), so a loop bound need not be a literal.


### More bench-verified facts (E1–E4, 2026-09-22)
- **An unwired `out N` in a gen patcher compiles, keeps its outlet, and
  emits an all-zero texture.** Handy for keeping outlet counts constant.
- **char pix output quantizes round-to-nearest, clamped to [0, 1]** (not
  floor). In a char feedback loop every step re-quantizes: increments below
  0.5/255 per step never accumulate.
- **Feedback into a non-left pix inlet is a clean one-frame delay** (the
  Pattern 1 state/pass loop): stepping is frame-exact -- verified with an
  exact counter over 20 steps and a closed-form decay accumulator.

---

## Code Health Checklist

When reviewing any codebox, scan for these in order:

- [ ] **No type declarations** — `float x`, `float4 col`, `int n` are invalid syntax; write bare assignments: `x = 1.0;`
- [ ] **Inlet count correct** — for each texture inlet needed: (1) `inN` referenced in codebox code (this makes the codebox inlet appear), (2) `in N` object exists in gen subpatcher, (3) `in N` wired to that codebox inlet. Neither `numinlets` on pix nor on codebox is settable — both are derived.
- [ ] **`noise()` calls** — always wrong on GPU; replace with sin hash
- [ ] **Component access on stored variables (read)** — `col = sample(...); col.x` is always black; rewrite as inline `sample(...).x`
- [ ] **Component assignment on stored variables (write)** — `z.x = ...` is a hard "invalid left-hand expression" compile error; use separate scalar variables (`zx`, `zy`) instead of one vector-like variable with component fields
- [ ] **`vec4()` or `vec2()` constructors** — replace with `vec()`
- [ ] **`select()`** — replace with `mix(a, b, step(...))` or `switch(cond, a, b)`
- [ ] **`snoise()` or `cycle()`** — replace with sin hash or `sin(x * twopi)` respectively
- [ ] **`cell` used as an integer index** — it is `norm * (dim - 1)` on jit.gl.pix; use `floor(norm.x * dim.x)` for integer indices
- [ ] **Variable names shadowing operators** — `cell`, `in`, `norm`, `snorm`, `dim` as variable names produce silent wrong output; rename with suffix (e.g. `cell_idx`, `band_idx`)
- [ ] **`boundmode` in GenExpr syntax** — silently ignored; use `fract()` or `wrap()` on coordinate before sampling
- [ ] **`dim` used for normalized sizing** — `dim` returns pixel dimensions, not [0,1]; use `norm` for normalized coords
- [ ] **`sqrt()` on potentially negative values** — valid but returns NaN for negative input; guard with `max(x, 0.0)` before `sqrt()`
- [ ] **User-defined functions declared after main body** — functions must come before `Param` declarations and all statements; move them to the top
- [ ] **`Param` accessed inside function body** — Params not visible inside functions; pass as explicit arguments instead
- [ ] **`swiz` calls** — silently fails on GPU; use manual `vec(sample(...).z, sample(...).y, sample(...).x, 1.0)` instead

---

## gen~ / Audio-Domain Codebox — DIFFERENT COMPILER, DO NOT ASSUME GPU RULES TRANSFER

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
