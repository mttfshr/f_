---
name: jit-gen-codebox
description: Use this skill whenever writing, reviewing, porting or debugging code in a jit.gl.pix gen patcher, or a .genjit file, even if the user only says "pix", "codebox", "GenExpr" or "shader in Max". Load it especially on these symptoms: a pix that compiles clean but renders black or passes its input through unchanged; a Param that ignores its messages ("invalid message" or no effect); "operator not defined", "invalid left-hand expression" or "stack overflow (too many captures)"; edges that wrap, smear or band; sample() results that are blocky, noisy or don't match a reference; NaN or all-black frames from atan2; a dial with the wrong type or range. Covers valid and silently broken operators, reserved names, inlets and outlets, sampling and out-of-range behavior, numeric precision, compiler limits, known-good idioms, and a review checklist. For gen~ (audio, CPU) use gen-tilde-codebox instead: the dialects share syntax but not rules (noise() fails here and works in gen~).
---

# jit.gl.pix Codebox Reference

**Canonical docs:** https://docs.cycling74.com/userguide/gen/gen_genexpr/

Empirically verified rules for GenExpr inside `jit.gl.pix` gen patchers, on
Max 9. The GPU path (`jit.gl.pix`) differs from the CPU path (`jit.gen`,
`jit.pix`): operators listed in the Cycling '74 docs can still fail silently
on the GPU, and the compiler is silent about many GPU-incompatible constructs
(they compile and render black). Measurements were made on one machine's GPU;
other GPUs may differ in the precision details.

**Evidence levels.** Entries are marked by what backs them: *bench* (measured
numerically: a codebox rendered by a test harness, read back as float32 and
compared with a NumPy mirror), *scratch patch* (seen by eye in Max), or
*docs-only*. Prefer a numeric check for anything that can be stated as
numbers, and check a codebox under development numerically before calling it
working. Items marked unverified, inferred or suspected are exactly that.

**Where things are:**

| File | Read it when |
|---|---|
| this file | always: quick rules, language, operators, silent failures, hard errors, inlets, review checklist |
| `references/sampling.md` | sampling textures: `sample()`/`nearest()` accuracy, out-of-range coordinates and `boundmode`, edges, minifying, hand interpolation |
| `references/numerics-and-limits.md` | precision, NaN, `atan2`, `step`, trig, the compiler's statement budget, loops, cost |
| `references/pix-object.md` | the `jit.gl.pix` object around the codebox: `dim`, inlet counts, unconnected inlets, bypass, renders, naming, compile errors, readback |
| `references/patterns.md` | known-good idioms: functions, sin hash, bypass, branchless selection, polar, masks, vector accumulation, complex/Möbius math, debugging mismatches |

---

## Quick rules

1. **Never write type declarations** (`float x`, `vec4 c`): assign bare,
   `x = 1.0;`. Build vectors with `vec(...)`, not `vec4(...)`/`vec2(...)`.
2. **Never read `.x`/`.y`/`.r` from a stored variable;** read it inline on
   the call: `sample(in1, uv).x`. A stored read renders black. Writing
   `z.x = ...` is a compile error: use separate scalars (`zx`, `zy`).
3. **Don't use `noise()`, `snoise()`, `cycle()`, `swiz`, `select()`:** use a
   sin hash, `sin(x * twopi)`, manual `vec()`, `switch()` or `mix/step`.
4. **Don't name variables or Params after built-ins** (`cell`, `in`, `norm`,
   `snorm`, `dim`, `inN`, `active`, `mix`, `step`, `t`, `shape`, constants
   like `PI`). The failure is silent: black output or a Param that never
   takes its value.
5. **Declare functions before everything, and pass Params in as arguments;**
   Params are invisible inside function bodies.
6. **Declare loop-carried variables before the loop;** a variable first
   assigned inside a `for` does not exist after it.
7. **Make an inlet or outlet exist by referencing `inN`/`outN` in the code
   first,** then add and wire the `in N`/`out N` object. Codebox `in 1` is
   the pix's inlet 0.
8. **Out-of-range coordinates wrap by default** (pix-to-pix), and exactly
   0.0/1.0 is a seam. Pass `boundmode="clamp"` when you want an edge.
   (`references/sampling.md`)
9. **Don't trust `sample()` to interpolate** at jumpy data-dependent
   coordinates, at texel corners, or when minifying; use four `nearest()`
   taps at normalized texel centres and blend by hand.
   (`references/sampling.md`)
10. **Write `0 - (...)`, not `-(...)`,** in front of a parenthesis; unary
    minus before a parenthesised expression mis-compiles.
    (`references/numerics-and-limits.md`)
11. **Never let `(0, 0)` reach a runtime `atan2`** (NaN on the GPU; a `mix`
    guard can't clear it): bias the argument, `atan2(y, x + 1e-7)`.
    (`references/numerics-and-limits.md`)
12. **Stay under about 250 statements per function or top level, 450 per
    program,** and call a big function a few times, not many; past that the
    compiler fails with "too many captures". (`references/numerics-and-limits.md`)

---

## Language model

GenExpr is a typeless expression language compiled to GLSL for `jit.gl.pix`.
It resembles C with restrictions:

- **No type declarations**: `float x`, `float4 col`, `int n` are invalid
  syntax. Variables are untyped; just assign: `x = 1.0;`.
- No array notation (`[index]`), no pointer types.
- Semicolons required for multi-line code.
- Variables are local to their scope by default; no `var` keyword.
- Functions must be declared before all statements (before `Param`
  declarations and the main body). User-defined functions work on the GPU
  path (confirmed 2026-06-18; bench 2026-10-06: bit-identical to the unrolled
  code). Syntax: `funcname(arg1, arg2, ...) { ... return val; }`, no `def`.
- **`Param` values are NOT visible inside function bodies:** pass them as
  explicit arguments.
- A function body can call `sample(in2, ...)` and `nearest(in2, ...)`,
  contain `for` loops with local variables (declare them before the loop),
  and return several values (bench 2026-10-06).
- `in` and `out` are reserved keywords (inlet/outlet references).

### Multiple return values

Functions return several values by comma assignment. Unused return values are
stripped by the compiler, at no cost:

```
r, theta = cartopol(x, y);       // both
r = cartopol(x, y);              // ignore theta
notused, theta = cartopol(x, y); // ignore r
sum, diff = in1 + in2, in1 - in2;
out1, out2 = diff, sum;
```

### Abstractions as functions, and `require`

Gen abstraction files (`.genjit`) on the Max search path can be called by
name like functions: `out1 = myHelper(in1, in2);`. Names must be valid
identifiers (letters, numbers, underscores; no `~` or `.`).

`require("name")` includes `name.genexpr` from the search path (bench
2026-10-06: it resolved from the patch's own folder, and a required function
can sample `in2`). It is a textual include: it **adds no statement budget**
(see `references/numerics-and-limits.md`).

---

## Valid operators (jit.gl.pix GPU path)

- **Math:** `+ - * / %` `abs neg sign floor ceil fract sqrt pow log exp mod`.
  `sqrt` of a negative returns NaN: guard with `max(x, 0.0)`.
  `mod()` is GPU-safe for discrete banding as well as wrapping (scratch patch
  2026-07-09: `mod(x, 1.0)` matched `x - floor(x/m)*m` exactly, no sign
  quirk), e.g. `mod(circle_id, 2.0)` for alternating colors.
- **Trigonometry:** `sin cos tan asin acos atan atan2 sinh cosh tanh`.
  `atan2` is accurate on all four quadrants, including on decoded texture
  input; see `references/numerics-and-limits.md` for its ±π and `(0, 0)`
  behavior.
- **Range / interpolation:** `clamp wrap fold mix smoothstep step`.
  `step(a, b)` with two *literal* constants folds the wrong way; see
  `references/numerics-and-limits.md`.
- **Comparison / logic:** `> < >= <= == != && || ! min max`.
- **Control flow:** `if / else if / else` (GPU-safe);
  `switch(condition, true_val, false_val)` (condition first);
  `for` / `while` (fixed counts or Param-bounded counts both work; see limits).
- **Vector:** `vec(x, y)`, `vec(x, y, z)`, `vec(x, y, z, w)`; `concat(a, b)`.
  Whole-vector arithmetic on stored vectors (`a + b`, `a * b`, `a * s`) is
  fine; only component access is broken.
- **Coordinate globals:** `norm` (UV in [0, 1], texel centres),
  `snorm` ([-1, 1]), `dim` (pixel size, NOT normalized; whose size it is:
  `references/pix-object.md`), `cell` (**not an integer index**:
  `cell = norm * (dim - 1)`; use `floor(norm * dim)`).
- **Sampling:** `sample(inN, coord)` (bilinear, normalized coord) and
  `nearest(inN, coord)` (normalized coord too). Out-of-range and accuracy
  rules: `references/sampling.md`.
- **Color:** `hsl2rgb(vec)`, `rgb2hsl(vec)`, alpha preserved.
- **Coordinate math:** `cartopol(x, y)` → r, theta; `poltocar(r, theta)` → x, y.
- **Constants (read-only):** `pi twopi halfpi e phi sqrt2 DEGTORAD RADTODEG`.
- **Parameters:** `Param name(default)`.

---

## Silent failures (compile clean, wrong output, no console message)

### `noise()` always renders black
Listed in the docs, compiles with any arguments, always outputs black on the
GPU. `snoise()` and `cycle()` are hard errors. Use a sin hash, which is
deterministic, spatially stable and gives per-cell identities with no
per-frame flicker (idioms and its precision caveat in `references/patterns.md`):

```
hash = fract(sin(x * 43758.5453) * 43758.5453);
hash = fract(sin(x * 127.1 + y * 311.7) * 43758.5453);   // 2D
```

### Component access on stored variables (read)
`.x/.y/.z/.w` and `.r/.g/.b` on a **stored variable** render black. The most
common silent failure:

```
col = sample(in1, uv);  r = col.x;   // WRONG: black
r = sample(in1, uv).x;               // CORRECT: inline on the call
```

It applies to `norm` too: `uv = norm; su = uv.x + dx;` reads `uv.x` as 0
(2026-06-21); use `norm.x` directly. Whole-vector arithmetic on stored
variables is fine.

### `swiz`
Documented for component remapping; silently fails on the GPU whatever the
syntax. Remap by hand:
`out1 = vec(sample(in1, uv).z, sample(in1, uv).y, sample(in1, uv).x, 1.0);`

### Names that collide with built-ins
All of these compiled clean and broke output silently. The fix is always to
rename **only the internal codebox identifier**; UI labels, control names
and external message keywords live outside the codebox and can keep the
nice name (but see the attribute collision in `references/pix-object.md`).

- **Coordinate operators as variables** (`cell`, `in`, `norm`, `snorm`,
  `dim`): undefined/zero output. Use `cell_idx`, `band_idx`.
- **`inN`-shaped variables** (`in0`, `in1`...`in7`) — *root cause
  unverified*, but a real solid-black repro (2026-07-08) in a codebox with
  no texture inlets. Suspected: any `in`+digits token is parsed as an inlet
  reference. Renaming to `ins0`, `ins1` fixed it (correlation in a complex
  codebox, not a minimal isolation). Treat any `in`+digits name as suspect.
- **`active`** (2026-07-08): a sticky flag `active = active * escaped` gave
  solid black even when correctly pre-declared; renamed `alive`, it worked.
  Suspected (no minimal repro) to collide like `inN`; `@active` is a common
  Jitter attribute. Two such collisions in one session: when a new state
  variable gives solid black despite correct declaration, suspect its
  *name* next.
- **A `Param` named after an operator** (`mix`, 2026-07-12):
  `Param mix(100.0)` then `mix(a, b, mix / 100.0)` gave solid black. Rename
  (`mix_pct`). Check candidate Param names against the operator list (`mix`,
  `step`, `clamp`, `smoothstep`, `sample`, `wrap`, `mod`...).
- **A `Param` named `t`** (2026-10-24) accepts `t <value>` messages without
  complaint but **never takes the value**: it stays at its default (a
  square-wave drive stuck at one phase). Same family as `texture` and
  `bypass`, names `jit.gl.pix` itself owns. Rename (`frameno`).
- **A `Param` named `shape`** (2026-11-14, bench) stayed at its default the
  same way; renamed `dot_shape`, it works. Treat any one-letter or generic
  Param name (`t`, `n`, `s`, `shape`) as suspect until a test sets a
  non-default value and reads the effect back.

### Assigning to a predefined constant — compile failure on Max 9.2.0 (2026-10-04)
`PI = 3.14159265359;` ran under Max 9.1.4 and **fails to compile on 9.2.0**:
the whole pix renders nothing and every `Param` message reports "invalid
message". The symptom (dead output, Params that "don't exist") points away
from the cause. Use another name (`pi_val`) or the built-in `pi`/`twopi`.
Two cautions: a patch that "worked when it was saved" is not evidence its
codebox compiles on the installed Max; and only `PI` was observed — that
`e`, `phi`, `twopi`, `halfpi` and the rest are rejected the same way is
inferred, **not tested**. Treat all of them as read-only.

### Variables first assigned inside a `for` loop don't exist after it (2026-07-08)
This one is a compile error (`"varname" is not defined`), listed here because
the shape is easy to write. Declare with an initial value BEFORE the loop and
only reassign inside it. The same goes for loop-carried state read inside the
loop (an accumulator, a sticky flag):

```
any_inside = 0.0;                 // declare first
for (i = 0; i < 16; i += 1) {
    any_inside = max(a, b);
}
result = any_inside;              // works
```

### `boundmode` typos, and `"mirror"` on y
`boundmode=` works, but an unknown value (`"mirorr"`) compiles and falls back
to the default (wrap), and `"mirror"` mirrors x but wraps y (bench
2026-11-14). Details: `references/sampling.md`.

### Others, with details elsewhere
- Unary minus before a parenthesis mis-compiles (`references/numerics-and-limits.md`).
- `step()` with two literal arguments folds reversed (same file).
- Runtime `atan2(0, 0)` gives NaN; `x == x` can't detect it (same file).
- `sample()` reads nearest, not bilinear, at jumpy coordinates or when
  minifying; `nearest()` given raw texel indices reads the border
  (`references/sampling.md`).
- A control whose name matches a `jit.gl.pix` attribute binds to the
  attribute (`references/pix-object.md`).

---

## Hard errors (console error, no compile)

| Invalid | Use instead |
|---|---|
| `vec4(r, g, b, a)` | `vec(r, g, b, a)` |
| `vec2(x, y)` | `vec(x, y)` or scalar vars |
| `float2(x, y)` | scalar vars |
| `select(cond, a, b)` | `mix(a, b, step(threshold, val))` or `switch(cond, a, b)` |
| `cycle(x)` | `sin(x * twopi) * 0.5 + 0.5` |
| `snoise(x)` | sin hash |
| `texdim()`, `in1.dim` | not available (`texdim` undefined, `in1.dim` reads 0): pass a texture's size as a literal or Param |

Too many statements gives `lua: [string DSL.Parser]: stack overflow (too many
captures)`: see `references/numerics-and-limits.md`.

### Component assignment on a stored variable — "invalid left-hand expression" (2026-07-08)
Writing a component (`z.x = ...`) is a hard compile error, unlike the silent
*read* failure above. Don't model a 2D point as one variable with fields:
use two scalars (`zx`, `zy`) throughout, and write a 2-output transform as
two single-return functions (one for the new x, one for the new y).

**Sequencing hazard:** if the y function needs the *original* x, capture it
before overwriting: `zx_prev = zx; zx = invertX(...); zy = invertY(zx_prev, zy, ...);`.
Getting the order wrong gives a silently wrong result, not an error.

---

## Inlets and outlets

### Code first, object second
**`numinlets` and `numoutlets` on `jit.gl.pix` and on the codebox are
read-only,** derived, never settable. The causality is always
code → connection point → object:

- **Inlet:** (1) reference `inN` in the code (this makes the codebox inlet
  appear), (2) an `in N` object exists in the gen patcher, (3) it is wired
  to that codebox inlet.
- **Outlet:** (1) assign `outN` in the code (`out2 = period_vis;`), (2) an
  `out N` object exists, (3) the codebox outlet is wired to it.

So when adding one: edit the code, confirm the new nub appears, then place
and wire the object. Placing the object first and expecting the reference to
"connect" to it is a recurring source of confusion: the object alone does
nothing.

(The pix's own inlet count also follows the gen patcher's `in` objects, and
an unwired `out N` still keeps its outlet: `references/pix-object.md`.)

### Inlet indexing (2026-06-06)
Codebox `in N` is the outer pix inlet N-1: `in 1` → pix inlet 0 (which also
carries the bang: there is no separate bang-only inlet), `in 2` → inlet 1,
`in 3` → inlet 2.

```
// Two-texture pix: source on outer inlet 0, field on outer inlet 1
r  = sample(in1, norm).x;                  // in1 = outer inlet 0
fx = (sample(in2, norm).x - 0.5) * 2.0;    // in2 = outer inlet 1
```

---

## Code health checklist

When reviewing any codebox, scan for these in order:

- [ ] **No type declarations** (`float x`, `float4 col`, `int n`); bare assignments only
- [ ] **Inlet/outlet count**: each needed `inN`/`outN` is referenced in the code, has its `in N`/`out N` object, and is wired
- [ ] **`noise()`**: always black on GPU; sin hash
- [ ] **Component read on a stored variable** (`col.x`): black; read inline on `sample(...).x`
- [ ] **Component write** (`z.x = ...`): compile error; separate scalars
- [ ] **`vec4()`/`vec2()`**: use `vec()`
- [ ] **`select()`**: `mix(a, b, step(...))` or `switch(cond, a, b)`
- [ ] **`snoise()`/`cycle()`**: sin hash / `sin(x * twopi)`
- [ ] **`swiz`**: manual `vec(...)`
- [ ] **Names shadowing built-ins**: `cell`, `in`, `norm`, `snorm`, `dim`, `inN`, `active`, operator names; suffix them (`cell_idx`)
- [ ] **Generic `Param` names** (`t`, `shape`, one letter) or operator names: silently never applied; use descriptive names and prove a message reaches the Param
- [ ] **Assignments to constants** (`PI = ...`): compile failure on Max 9.2.0
- [ ] **Control names equal to a `jit.gl.pix` attribute** (`depth`, `texture`, `output`, `mode`): the dial binds to the attribute; prefix the name
- [ ] **Functions declared after the main body**: move them to the top
- [ ] **`Param` read inside a function body**: pass it as an argument
- [ ] **Loop-carried variables first assigned inside the loop**: declare before
- [ ] **Out-of-range `sample()`/`nearest()` coordinates**: wrap by default; exact 0.0/1.0 is a seam; want an edge, pass `boundmode="clamp"`; check its spelling; don't rely on `"mirror"` for y
- [ ] **`sample()` at jumpy, data-dependent coordinates** (iteration, ray marching, gathers): reads nearest; four `nearest()` taps blended by hand
- [ ] **`sample()` as an exact interpolator** at texel corners or 1:1: returns one texel; `nearest()` at texel centres
- [ ] **`sample()` of a much larger texture** (minifying, or a fixed-`dim` internal stage): nearest-like, aliases; average a taps x taps grid
- [ ] **`nearest()` coordinates normalized** (`(ix + 0.5) / width`), not raw texel indices
- [ ] **`cell` used as an integer index**: use `floor(norm.x * dim.x)`
- [ ] **`dim` used for normalized sizing**: it is pixels; use `norm`
- [ ] **Unary minus before a parenthesis** (`exp(-(a + b))`): write `0 - (...)` or distribute the sign
- [ ] **`step()` with two literal arguments**: folds reversed; keep one a variable
- [ ] **`atan2` fed possibly-(0, 0) runtime values**: bias an argument (+1e-7); no `mix` guard, no `x == x` test, no `isnan()`
- [ ] **`sqrt()` of possibly negative values**: `max(x, 0.0)` first
- [ ] **Large trig arguments in long accumulations**: reduce first (`mod(k * n, N)`)
- [ ] **Statement count**: about 250 per function or top level, 450 per program; repeated code into functions; `require` adds no budget; a big function called many times can still overflow
- [ ] **Bare pix `@name` in a module that may be instantiated twice**: prefix `#0_`

---

If a `local.md` sits next to this file, read it too: it holds project-specific
tooling and conventions that extend this skill.
