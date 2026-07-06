# tasks.md — codebox.skill

Verification tests for jit.gl.pix codebox operators. Run each in scratch.maxpat with vs_render running. Note pass/fail and any console errors.

## Setup
- Scratch patch: `/Users/matt/Vsynth/patterns/scratch.maxpat`
- Requires: vs_render running, jit.gl.pix with `@drawto vsynth`, r draw or vs_render trigger wired

---

## Operator Verification Tests

### Numeric / Range

**T01: `fract()`** — VALID. (Original test degenerate; UV variant confirms working.)

**T02: `sqrt()`**
```
uv = norm;
r = sqrt(uv.x * uv.x + uv.y * uv.y);
out1 = vec(r, r, r, 1.0);
```
Expected: radial gradient. Result: PASS

**T03: `noise()`**
```
uv = norm;
n = noise(uv.x * 10.0);
out1 = vec(n, n, n, 1.0);
```
Expected: fail. Result: FAIL — black screen (compiles but outputs black; noise() unavailable in GPU path)

---

### Type Constructors

**T04: `vec4()`**
```
uv = norm;
out1 = vec4(uv.x, uv.y, 0.0, 1.0);
```
Expected: fail. Result: FAIL — "operator vec4 not defined"

**T05: `vec2` / `float2`**
```
uv = norm;
v = vec2(uv.x, uv.y);
out1 = vec(v.x, v.y, 0.0, 1.0);
```
Expected: fail. Result: FAIL — "operator vec2 not defined"

---

### Conditional / Selection

**T06: `select()`**
```
uv = norm;
out1 = vec(select(uv.x > 0.5, 1.0, 0.0), 0.0, 0.0, 1.0);
```
Expected: fail. Result: FAIL — "operator select not defined"

**T07: `if/else` branching**
```
uv = norm;
if (uv.x > 0.5) {
    out1 = vec(1.0, 0.0, 0.0, 1.0);
} else {
    out1 = vec(0.0, 0.0, 1.0, 1.0);
}
```
Expected: red right / blue left. Result: PASS

**T08: `switch()` operator**
```
uv = norm;
out1 = vec(switch(uv.x > 0.5, 1.0, 0.0), 0.0, 0.0, 1.0);
```
Expected: pass. Result: PASS — note: argument order is switch(condition, true, false) → black left, red right

---

### Reserved Words as Variable Names

**T09: `cell` as variable**
```
uv = norm;
cell = floor(uv.x * 10.0);
out1 = vec(cell * 0.1, 0.0, 0.0, 1.0);
```
Expected: compile error. Result: NOT a reserved word — compiles, but black screen (cell shadows the coordinate operator; output undefined/zero)

**T10: `band` as variable**
```
uv = norm;
band = floor(uv.y * 8.0);
out1 = vec(0.0, band * 0.125, 0.0, 1.0);
```
Expected: compile error. Result: NOT a reserved word — compiles and produces green/black gradient bands (works correctly as a variable name)

**T11: `in` as variable**
```
uv = norm;
in = uv.x;
out1 = vec(in, 0.0, 0.0, 1.0);
```
Expected: compile error. Result: NOT a compile error — black screen (in shadows the inlet keyword; output undefined/zero)

---

### Sampling

**T12: `sample` with `boundmode` attribute**
```
uv = norm;
uv_shifted = vec(uv.x + 0.3, uv.y);
out1 = sample(in1, uv_shifted, boundmode="wrap");
```
Expected: pass with wrap behavior. Result: FAIL — black screen (boundmode attribute syntax does not work in jit.gl.pix GPU path)

**T13: `swiz` operator**
```
uv = norm;
col = sample(in1, uv);
swapped = swiz(col, 2, 1, 0, 3);
out1 = swapped;
```
Expected: R/B channels swapped. Result: FAIL — black screen (swiz does not work in jit.gl.pix GPU path)

**T14: `.r/.g/.b` component access**
```
uv = norm;
col = sample(in1, uv);
out1 = vec(col.b, col.g, col.r, 1.0);
```
Expected: pass. Result: FAIL — black screen (note: T12/T13/T14 all require a connected texture on in1; may need to retest with texture wired)

---

### Coordinate Operators

**T15: `snorm`**
```
sn = snorm;
out1 = vec(sn.x * 0.5 + 0.5, sn.y * 0.5 + 0.5, 0.0, 1.0);
```
Expected: UV gradient. Result: PASS — red/green gradient (snorm [-1,1] remapped to [0,1])

---

### Interpolation

**T16: `smoothstep()`**
```
edge = smoothstep(0.4, 0.6, norm.x);
out1 = vec(edge, edge, edge, 1.0);
```
Expected: smooth vertical band. Result: PASS — black left, smooth transition, white right

---

## Results Summary

### Valid operators (confirmed working in jit.gl.pix GPU path)
`fract`, `sqrt`, `wrap`, `fold`, `mod`, `%`, `floor`, `ceil`, `abs`, `sign`, `pow`, `log`, `exp`, `sin`, `cos`, `atan2`, `pi` (and other math constants), `smoothstep`, `step`, `clamp`, `mix`, `switch`, `if/else`, `snorm`, `cell`, `dim`, `norm`, `vec()`, `concat()`

### Silent failures (compile but produce black/no output — most dangerous)
- `noise()` — compiles with any argument signature, always outputs black
- `boundmode` attribute on `sample()` in GenExpr syntax — silently ignored, defaults to clamp
- `swiz` — silently rejected, last valid frame held
- Component access (`.x/.y/.z/.w` or `.r/.g/.b`) on a **stored variable** — silently fails; use inline access directly on `sample()` return value instead
- `cell`, `in` used as variable names — shadow coordinate operators, compile but produce undefined/zero output

### Hard errors ("operator X not defined")
- `vec4()` — use `vec(r, g, b, a)`
- `vec2()` — use `vec(x, y)` or scalar vars
- `select()` — use `mix(a, b, step(threshold, val))` or `switch()`
- `cycle()` — no equivalent; use sin-based arithmetic
- `snoise()` — no equivalent; use sin hash

### Key findings vs prior assumptions
- `fract()` IS valid — our workaround `wrap(x, 0.0, 1.0)` also works but is not required
- `sqrt()` IS valid — prior "unreliable" note was wrong; use freely
- `noise()` is the most dangerous: listed in docs, compiles cleanly, always black — must use sin hash
- `dim` returns pixel dimensions of render context, not normalized values
- `cell` and `band` are NOT reserved words — they shadow coordinate operators silently if used as variable names
- `boundmode` and `swiz` fail silently in GPU path — no console error
- Component access: `sample(in1, uv).x` works (inline on return value); `col = sample(...); col.x` does not (stored variable). Our existing pattern `sample(in1, uv).r` is correct — inline access works, stored variable access does not
- `switch(condition, true_val, false_val)` argument order confirmed

---

## Additional Tests

### Retests with texture wired to in1
Wire a texture source (e.g. vs_noise or vs_wfg) to jit.gl.pix in1 before running these.

**T12b: `sample` with `boundmode` attribute**
```
uv = norm;
uv_shifted = vec(uv.x + 0.3, uv.y);
out1 = sample(in1, uv_shifted, boundmode="wrap");
```
Expected: texture shifted right with wrap. Result: FAIL — silently rejected by GPU; no draw refresh, last valid frame held

**T13b: `swiz` operator**
```
uv = norm;
col = sample(in1, uv);
swapped = swiz(col, 2, 1, 0, 3);
out1 = swapped;
```
Expected: texture with R/B swapped. Result: FAIL — silently rejected by GPU; no draw refresh, last valid frame held

**T14b: `.r/.g/.b` component access**
```
uv = norm;
col = sample(in1, uv);
out1 = vec(col.b, col.g, col.r, 1.0);
```
Expected: texture with R/B swapped. Result: FAIL — silently rejected by GPU; no draw refresh, last valid frame held

---

### switch() argument order

**T17: `switch()` argument order — explicit**
```
uv = norm;
// if condition true → should output 1.0 red on RIGHT half
out1 = vec(switch(uv.x > 0.5, 1.0, 0.0), 0.0, 0.0, 1.0);
```
Expected: confirm which half is red — pinning down true/false argument order. Result: PASS

---

### Range / Wrapping

**T18: `wrap()`**
```
uv = norm;
out1 = vec(wrap(uv.x * 3.0, 0.0, 1.0), wrap(uv.y * 3.0, 0.0, 1.0), 0.0, 1.0);
```
Expected: tiled red/green gradient (same as fract). Result: PASS

**T19: `fold()`**
```
uv = norm;
out1 = vec(fold(uv.x * 3.0, 0.0, 1.0), fold(uv.y * 3.0, 0.0, 1.0), 0.0, 1.0);
```
Expected: tiled mirrored gradient. Result: PASS

**T20: `mod()`**
```
uv = norm;
out1 = vec(mod(uv.x * 3.0, 1.0), mod(uv.y * 3.0, 1.0), 0.0, 1.0);
```
Expected: tiled gradient (same as wrap/fract). Result: PASS

**T21: `%` operator**
```
uv = norm;
out1 = vec(uv.x * 3.0 % 1.0, uv.y * 3.0 % 1.0, 0.0, 1.0);
```
Expected: same as T20. Result: PASS

---

### Numeric

**T22: `floor()`**
```
uv = norm;
fx = floor(uv.x * 8.0) / 8.0;
fy = floor(uv.y * 8.0) / 8.0;
out1 = vec(fx, fy, 0.0, 1.0);
```
Expected: stepped/pixelated gradient. Result: PASS

**T23: `ceil()`**
```
uv = norm;
cx = ceil(uv.x * 8.0) / 8.0;
out1 = vec(cx, cx, cx, 1.0);
```
Expected: stepped gradient offset by one step vs floor. Result: PASS

**T24: `abs()`**
```
sn = snorm;
out1 = vec(abs(sn.x), abs(sn.y), 0.0, 1.0);
```
Expected: mirrored gradient — bright at edges, dark at center. Result: PASS

**T25: `sign()`**
```
sn = snorm;
out1 = vec(sign(sn.x) * 0.5 + 0.5, sign(sn.y) * 0.5 + 0.5, 0.0, 1.0);
```
Expected: hard split at center — four colored quadrants. Result: PASS

---

### Math

**T26: `pow()`**
```
uv = norm;
out1 = vec(pow(uv.x, 2.0), pow(uv.y, 0.5), 0.0, 1.0);
```
Expected: red channel curved down (square), green channel curved up (sqrt). Result: PASS

**T27: `pow(x, 0.5)` as sqrt substitute**
```
uv = norm;
r = pow(uv.x * uv.x + uv.y * uv.y, 0.5);
out1 = vec(r, r, r, 1.0);
```
Expected: radial gradient identical to T02 sqrt result. Result: PASS

**T28: `log()` / `ln()`**
```
uv = norm;
l = log(uv.x * 9.0 + 1.0);
out1 = vec(l, l, l, 1.0);
```
Expected: logarithmic ramp. Result: PASS

**T29: `exp()`**
```
uv = norm;
e = exp(uv.x * 2.0 - 2.0);
out1 = vec(e, e, e, 1.0);
```
Expected: exponential ramp. Result: PASS

---

### Trigonometry

**T30: `sin()` / `cos()`**
```
uv = norm;
s = sin(uv.x * pi * 4.0) * 0.5 + 0.5;
c = cos(uv.y * pi * 4.0) * 0.5 + 0.5;
out1 = vec(s, c, 0.0, 1.0);
```
Expected: sine/cosine wave pattern. Result: PASS

**T31: `atan2()`**
```
sn = snorm;
a = atan2(sn.y, sn.x) / (pi * 2.0) + 0.5;
out1 = vec(a, a, a, 1.0);
```
Expected: angular gradient rotating around center. Result: PASS

**T32: `pi` constant**
```
out1 = vec(pi / 4.0, pi / 4.0, pi / 4.0, 1.0);
```
Expected: uniform gray at ~0.785. Result: PASS

---

### Coordinate Operators

**T33: `dim` behavior in jit.gl.pix generator context**
```
d = dim;
out1 = vec(d.x / 1000.0, d.y / 1000.0, 0.0, 1.0);
```
Expected: uniform color reflecting actual context dimensions. Result: PASS — olive/ochre yellow (~0.64, 0.48, 0.0), confirming dim returns pixel dimensions of render context (640×480), not normalized values

**T34: `cell`**
```
c = cell;
d = dim;
out1 = vec(c.x / d.x, c.y / d.y, 0.0, 1.0);
```
Expected: same as norm (pixel coords / dim = normalized). Result: PASS — red/green gradient

---

### Vector construction

**T35: `vec()` with 2 components**
```
uv = norm;
v = vec(uv.x, uv.y);
out1 = vec(v.x, v.y, 0.0, 1.0);
```
Expected: pass — confirm vec() works with 2 args. Result: PASS — red/green gradient

**T36: `concat()`**
```
uv = norm;
xy = vec(uv.x, uv.y);
zw = vec(0.0, 1.0);
out1 = concat(xy, zw);
```
Expected: same as norm-based UV output. Result: PASS — red/green gradient

---

### Logic / Comparison

**T37: `step()`**
```
uv = norm;
s = step(0.5, uv.x);
out1 = vec(s, 0.0, 0.0, 1.0);
```
Expected: black left, red right — hard threshold at 0.5. Result: PASS

**T38: `clamp()`**
```
uv = norm;
c = clamp(uv.x * 2.0 - 0.5, 0.0, 1.0);
out1 = vec(c, c, c, 1.0);
```
Expected: ramp clipped at 0 and 1. Result: PASS

**T39: `mix()`**
```
uv = norm;
m = mix(0.0, 1.0, uv.x);
out1 = vec(m, m, m, 1.0);
```
Expected: linear gradient — same as norm.x. Result: PASS

---

### Silent failure patterns (no texture needed)

**T40: `noise()` with different input types**
```
n = noise();
out1 = vec(n, n, n, 1.0);
```
Expected: black or error — confirm noise() with no args. Result: FAIL — black screen (silent; noise() compiles but produces no output regardless of arguments)

**T41: `cycle()` — expected unavailable**
```
uv = norm;
c = cycle(uv.x);
out1 = vec(c, c, c, 1.0);
```
Expected: error or black. Result: FAIL — "operator cycle not defined"

**T42: `snoise()` — expected unavailable**
```
uv = norm;
n = snoise(uv.x);
out1 = vec(n, n, n, 1.0);
```
Expected: error or black. Result: FAIL — "operator snoise not defined"

---

### Additional tests from doc research

**T43: `.x/.y/.z/.w` component access on stored variable**
```
uv = norm;
col = sample(in1, uv);
out1 = vec(col.z, col.y, col.x, 1.0);
```
Expected: texture with R/B swapped. Result: FAIL — black screen (component access on stored variable fails silently in GPU path)

**T43b: `.x/.y/.z/.w` inline component access on sample() return value**
```
uv = norm;
out1 = vec(sample(in1, uv).z, sample(in1, uv).y, sample(in1, uv).x, 1.0);
```
Expected: texture with R/B swapped. Result: PASS — sine WFG with channels swapped (inline component access on sample() return value works)

**T44: `swiz` with correct constructor syntax**
```
uv = norm;
col = sample(in1, uv);
swapped = swiz(col, 2, 1, 0, 3);
out1 = swapped;
```
Note: swiz mask is set as constructor args at compile time, not runtime. Result: FAIL — black screen

**T45: `sample` boundmode as object attribute (not GenExpr attr syntax)**
```
uv = norm;
uv_shifted = vec(uv.x + 0.3, uv.y);
out1 = sample(in1, uv_shifted);
```
Note: place a `sample` object box in the gen patcher (not codebox) and set its boundmode attribute to wrap there. This tests whether boundmode works at all vs. the GenExpr syntax specifically. Result:
