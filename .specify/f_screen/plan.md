# Implementation Plan: f_screen

**Date**: 2026-11-08
**Spec**: .specify/f_screen/spec.md

All gate decisions below are **preliminary**: Claude's recommendations, accepted in place on Matt's instruction (2026-11-08). Matt has not confirmed them. Derivations marked inferred are worked out, not run.

---

## Summary

A stateless, analytic processor in one `jit.gl.pix` stage. For each of the three channels it rotates the pixel into that plate's lattice, finds the cell, reads the tone once at the cell centre, and compares it with an area-preserving spot function to decide ink or no ink, with a soft edge. Dot and Line are P1; jitter, shape, Threshold and Bayer are P2. The lattice is a function of position alone, so the module samples the input only to read tone. It is the threshold-field half of the print-styles family; ink behaviour is `f_ink`'s job.

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix` GPU path (GenExpr). `@type float32`.
- **Archetype**: processor, in0 the `driving_inlet`; one stage; no optional inputs in v1 (spec P8, G12). With in0 unconnected the output is black.
- **Limits** (`skills/jit-gen-codebox/SKILL.md`, `ideas/f_deflicker.md`; read, not re-run): about 250 statements per function and about 450 per program; about 16 reads per stage; `noise()` is black on this path (use the sin hash); a bilinear tap on a texel corner once returned ONE texel, so every tone read here is a `nearest` read at a texel centre.
- **Build**: `src/f_screen/definition.py` → `build/build_patcher.py` → `package/patchers/f_screen.maxpat`.
- **Naming**: `softness`, `jitter`, `shape`, `angle` are the library's vocabulary (`docs/f-reference/discrete_item_conventions.md`, not opened; G13 checks).

---

## Constitution Check

✅ Codebox-first; one concern (tone to marks); the patcher is a thin wrapper.
✅ Numbers before eyes: the area law, extremes, monotonicity, lattice period and orientation, and plate independence are all closed forms or invariants (spec SC-001 to SC-007), so tiers 1 and 2 precede the live look.
⚠️ Statement budget: three channels × (rotation, cell, spot function) must live in functions; a function call is one statement.
⚠️ `sample()` inside a user function or a loop is unverified (inferred risk): the first bench checks it; the fallback is to sample in the main body and pass tone into the functions.

---

## Project Structure

```
src/f_screen/
  definition.py              # source of truth
  codebox_screen.gen         # the single stage
tests/modules/screen/
  screen_mirror.py           # float32 NumPy mirror
  test_screen.py             # tier 1
  bench_screen.py            # tier 2: real codebox vs mirror
  bench_screen_module.py     # shipped patcher: bypass, flags
package/patchers/f_screen.maxpat   docs/f-reference/f_screen.md   package/help/f_screen.maxhelp
```

---

## Architecture Decisions

### ADR-1: One stage, analytic lattice (spec FR-002, G6)

**Decision**: the lattice is computed from the pixel's position, never from a texture. Position `p = ((uv.x - 0.5) * aspect, uv.y - 0.5)` in frame heights (preliminary G2, shared with `f_ink`); rotate by `-θ_c` about the frame centre (preliminary G6); lattice coordinates `q = R(-θ_c) p / pitch`; the cell is `round(q)` and the local position `f = q - round(q)` in `[-0.5, 0.5]²`.
**Rationale**: a pure function of position is the cheapest thing to mirror exactly and keeps the screen fixed to the frame (spec P4). Rotating about the centre keeps a rotation of 0, 45 or 90 degrees exact on a centred grid (to be checked, G6).
**Rejected**: a lattice built from a noise texture; a per-image-fixed lattice (spec P4).

### ADR-2: Area-preserving spot functions (G3, spec P3)

A pixel is inked where `T(f) < tone`, where `T` is a threshold field with the property that the fraction of a cell with `T < t` equals `t`.
- **Line**: `T = 2|f_v|` (exact: the fraction with `|f_v| < t/2` is `t`).
- **Round dot** (inferred derivation, verify in the mirror): with `r = |f|`, the area of a circle of radius `r` inside the unit cell is `A(r) = π r²` for `r ≤ ½`, and `A(r) = π r² - 4 (r² acos(1 / (2r)) - ½ √(r² - ¼))` for `½ < r ≤ √½`; `A(√½) = 1`. `T(r) = A(r)` is monotone, and its derivative is `dA/dr = 2π r` for `r ≤ ½` and `dA/dr = r (2π - 8 acos(1 / (2r)))` above (the perimeter inside the cell). This avoids a numerical inverse.
- **Square** (P2 shape end): `T = (2 max(|f_u|, |f_v|))²`, exact.
- **Shape morph** (P2): `T = mix(T_round, T_square, shape)`; the area law is exact at the ends and holds within the mirror's tolerance in between (inferred).
**Rejected**: a power-of-radius approximation `T = (2r)^k` (not area-preserving, gives a visible tone-curve error).

### ADR-3: Soft edge and exact extremes (G5, spec FR-004, FR-008)

**Decision**: `coverage = clamp(0.5 + (tone - T) / w_T, 0, 1)` with `w_T = max(softness * 0.5, aa) * |dT/dd|`, where `dd` is the distance in lattice units across the edge; `aa` is one texel expressed in lattice units (`1 / pitch_in_texels`), so the edge is never sharper than the antialiasing allows. `|dT/dd|` is analytic (`2π r` for the round dot, the formula above beyond ½, `2` for the line). After the compare, `tone <= 0` forces exactly 0 and `tone >= 1` exactly 1, because the soft edge alone would put 0.5 at the centre of a zero-tone dot.
**Smallest usable pitch**: measured (G5): the pitch in texels below which the area law fails by more than the mirror's tolerance; assumed about 3 texels until measured.

### ADR-4: Tone is read once per cell (G4, spec FR-006, FR-007)

**Decision (preliminary)**: for the Dot type, the tone is read at the cell centre, converted back to screen coordinates and then to a texel index (`nearest`, clamped to the frame). For the Line type, the read is at the point on the line's centreline nearest to the pixel (the same lattice row, the pixel's own position along the line).
**Consequence**: a smooth ramp becomes a staircase of dot sizes, as in a real halftone; on a hard edge the dot nearest the edge takes the edge's tone. A small average over the cell (up to 16 reads) is the alternative if the tier-3 look wants smoother tone; kept as a Phase 0 measurement.
**Rejected**: a per-pixel compare against the field (a distorted dot where tone varies inside a cell; this is the Bayer and Threshold types' behaviour by design, not the Dot's).

### ADR-5: Jitter by neighbourhood test (spec FR-009, G7)

**Decision**: with `jitter = 0` the module evaluates one cell exactly (no neighbourhood, so the lattice is exactly regular). With `jitter > 0`, each cell centre is displaced by `jitter * 0.25 * (hash2(cell, seed) - 0.5) * 2` cells (the limit keeps a dot inside its own neighbourhood), and the pixel evaluates the nine surrounding cells and takes the maximum coverage. The nine-cell loop lives in a function (one statement per call).
**Cost**: nine tone reads per channel only when `jitter > 0`; measured at Phase 0.

### ADR-6: Threshold and Bayer (P2 stories)

**Decision**: Threshold is `coverage = smoothstep(level - w, level + w, tone)` with `w` from `softness`. Bayer is an 8×8 ordered matrix evaluated from the texel coordinates by the bit-interleave formula in a three-iteration loop, compared with `(M + 0.5) / 64`; its cell is a texel, so it is the one type in texel units, not frame units (documented in the spec's G-notes).

### ADR-7: Bounds, alpha, bypass (spec FR-011, FR-013, FR-014)

**Decision**: output clamped to 0..1 by construction; non-finite tone zapped to 0; alpha copied from the source; `bypass` is the codebox `bypass_gate` Param (never native `@bypass`) passing the source through.

---

## Stage and wiring sketch

```
in0 (driving_inlet) -> screen -> out0
r dim -> screen (render size, aspect)
```

---

## Testing plan (constitution tiers)

- **G1 decided (preliminary)**: tiers 1, 2, 3 all apply.
- **Tier 1**: `screen_mirror.py` / `test_screen.py`: area law on flat patches (several tones, pitches, angles), tone extremes exact, monotone along a ramp, lattice period and orientation (autocorrelation), plate independence, jitter 0 exact and jitter 1 mean preserved, render-size scaling, non-finite zap. Run `tests/run.sh -q tests/modules/screen`.
- **Tier 2**: `bench_screen.py` runs the real codebox against the mirror (one input); first checks `sample()` inside a function and the smallest usable pitch. `bench_screen_module.py` covers bypass and the connected flag. Read `skills/bench-test-authoring` before writing either.
- **Contracts**: register in `tests/contracts/test_module_contracts.py` and `bench_modules.py`.
- **Tier 3 (Matt)**: a photo through three plates at 15, 75, 45; followed by `f_ink`; a bent use.

## Risks

- **The round-dot area function** is an inferred derivation; the mirror must confirm it before the codebox copies it.
- **Staircase of dot sizes** (per-cell sampling) may look too coarse at large pitch; the cell-average alternative is cheap to try.
- **Moiré between plates** (the offset angle convention is inferred) may need different defaults; tier 3.
- **Exactness at 0, 45, 90 degrees** depends on float32 rotation; checked in the mirror.
- **Statement budget** with three channels and nine-cell jitter; functions are the mitigation.

## Phasing (details in tasks.md)

- **Phase 0**: gates, the mirror, and the area-law and pitch measurements.
- **Phase 1**: codebox (Dot and Line first), `definition.py`, patcher, benches; then P2 types.
- **Phase 2**: tuning with Matt.
- **Phase 3**: reference doc, helpfile, menu, README.
