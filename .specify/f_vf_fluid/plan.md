# Implementation Plan: f_vf_fluid

_Created: 2026-09-23_
_Spec: `.specify/f_vf_fluid/spec.md` (user stories, FRs, success criteria live
there — this file is HOW only)_
_Research background: `ideas/ceyron_simulation_scripts_notes.md`_

---

## Summary

A spectral (FFT) incompressible-flow **velocity solver** as a vecfield
producer: a force vecfield goes in, an evolving velocity vecfield comes out.
The solver runs as a chain of `jit.gl.pix` stages at a fixed internal
256×256 `float32`: self-advect + add force → forward separable DFT (2 passes)
→ one elementwise spectral pass (projection blend, exact viscosity, drag) →
inverse DFT (2 passes) → velocity state (Pattern 1 feedback). A final encode
stage at **render resolution** upsamples and encodes the velocity into the
`f_vecfield` contract, so consumers see an ordinary render-size vecfield.
Everything numeric is verified in NumPy and on the GPU bench before any
patcher is built; the patcher comes from a dedicated build script (the
`build_advect.py` / `build_seeds_multistage.py` precedent).

---

## Technical Context

**Stack**: Max 9, Vsynth, `jit.gl.pix` + GenExpr codeboxes (`float32`);
Python 3 (NumPy) for the math mirror; the Max test bench (`tests/bench*`) for
GPU verification.

**Reused, already verified**: separable-DFT codeboxes
(`tests/bench/codeboxes/dft_x.gen`, `dft_y.gen`, GPU-matched to `np.fft` at
~1e-7); `pass_dft`/`pass_spectral` NumPy mirrors
(`tests/test_fft_separable.py`); `gpu_sim.py`; the `f_vf_advect`
`state`/`pass` feedback pattern (Pattern 1); `vs_inState` +
`src_vecfield` unconnected-inlet suppression.

**Constraints from bench-verified facts** (`jit-gen-codebox` skill):
- `cell = norm * (dim - 1)`, not an integer index → integer bin =
  `floor(norm * N)`.
- `nearest()` at texel centers for transforms; twiddle index `mod(k*n, N)`
  before scaling to an angle.
- Components accessed inline on `sample()`/`nearest()` results, never on a
  stored vector.
- A `Param` must not share a name with a GenExpr built-in (`mix` bit us);
  never name a Param `bypass` on a pix that also uses native bypass.
- Fixed `@name`s break a second instance → **all names `#0_`-scoped**.
- A new gen compiles at its first render; params sent earlier fail.
- Hardware `sample()`: clamps neighbor taps, 8-bit weights, and is nearest-like
  when minifying (Phase 0) — all interpolation here is manual (ADR-3).
- `NaN == NaN` is true on this GPU; guard with `abs(x) < 1e30` (ADR-6).
- **A unary minus before a parenthesis mis-parses** (`-(a + b) * c` ≠ −(a+b)·c);
  write `0 - (a + b) * c` (Phase 1). A codebox cannot read an input texture's size.
- Native `@bypass` skips the shader and flips outlets 2+ (this module uses a
  Param-based bypass gate instead — ADR-8).

**Cost budget** (from the bench): one N=256 DFT pass ≈ 0.4 ms (extrapolated
from 2.96 ms at 512²). Four DFT passes ≈ 1.5 ms; everything else is one or
two samples per pixel. Target total ≤ 3 ms/frame (spec NF-001), measured, not
assumed.

---

## Constitution Check

✅ **Codebox before patcher** — every stage is a `src/f_vf_fluid/codebox_*.gen`
file, verified (tiers 1–2) before any JSON is built.
✅ **Numbers before eyes** — math mirror and bench tests precede any scratch
patch; tier 3 is only for ranges, look and Vsynth integration.
✅ **One bpatcher, one concern** — solver only; dye stays in existing
consumers.
✅ **Specs before building** — `spec.md` exists.
✅ **`#0_` scoping** — required by FR-012.
⚠️ **Multi-stage + hand-edited patcher** — like `f_vf_advect`/`f_vf_seeds`,
this will land on the never-regenerate list once hand-edited; mitigated by
keeping the build script authoritative until then and recording drift.
⚠️ **Bench limits** — the bench drives one codebox at a time
(`run_temporal` feedbacks a single codebox), so multi-stage frame-exactness
is host-sequenced from Python (ADR-10), not a GPU-resident chain.

---

## Project Structure

```
src/f_vf_fluid/
  definition.py            # metadata only (params, docs/helpfile pipeline, archetype) —
                           #   NOT the patcher source; the build script is
  build_fluid.py           # dedicated build script → package/patchers/f_vf_fluid.maxpat
  gen_dft.py               # writes the four DFT codeboxes from one template (N baked)
  codebox_adv.gen          # stage 1: self-advect + force (256², periodic)
  codebox_dft_fx.gen       # stage 2: forward DFT along x
  codebox_dft_fy.gen       # stage 3: forward DFT along y
  codebox_spec.gen         # stage 4: projection blend + viscosity + drag
  codebox_dft_iy.gen       # stage 5: inverse DFT along y
  codebox_dft_ix.gen       # stage 6: inverse DFT along x + real part + NaN guard
  codebox_enc.gen          # stage 7: upsample + encode + gain + bypass gate (render res)
tests/
  fluid_mirror.py          # NumPy mirror of every stage + full step (imports gpu_sim,
                           #   pass_dft/pass_spectral from test_fft_separable)
  test_fluid_mirror.py     # tier 1: Taylor–Green, projection, energy, Nyquist, stability
  bench_fluid.py           # tier 2: each stage on the GPU vs the mirror; multi-frame; cost
docs/f-reference/f_vf_fluid.md        # reference doc (Phase 4)
package/patchers/f_vf_fluid.maxpat    # built (Phase 2)
package/help/f_vf_fluid.maxhelp       # helpfile pipeline (Phase 4)
```

**Structure decision**: stage-per-file codeboxes because each stage is
verified independently and the DFT stages differ only by baked constants
(axis, direction). `definition.py` exists only to feed the docs/helpfile and
param-extraction tooling (as for `f_vf_advect`), so the patcher's real
source of truth is the build script.

---

## Data Model — texture packing

All solver textures are `float32` RGBA at 256×256.

| Texture | R | G | B | A | Notes |
|---|---|---|---|---|---|
| Velocity state / advect output | u | 0 | v | 0 | u, v in ±1 "field units" (same scale as decoded `f_vecfield`) |
| Spectral (after `fx`,`fy`) | Re û | Im û | Re v̂ | Im v̂ | the packing `pass_dft` already uses |
| Force input (render res) | Fx | Fy | 0.5 | 1 | standard `f_vecfield`; decoded `(p−0.5)·2` |
| Outlet (render res) | 0.5+0.5·clamp(gain·u) | 0.5+0.5·clamp(gain·v) | 0.5 | 1 | FR-001 |

Domain: periodic unit square; wavevector `k = 2π · signed_index`.

---

## Architecture Decisions

### ADR-1: Stage chain (8 `jit.gl.pix`, 7 doing work)

**Context**: spectral incompressible flow needs advection in real space and
diffusion/projection in Fourier space; each `jit.gl.pix` pass is one
full-screen render.

**Decision**: `pass → adv → fx → fy → spec → iy → ix → enc`, with `ix → pass`
as the feedback edge. Solver stages (`pass`…`ix`) are 256²; `enc` is render
res.

| # | Node | In | Does | Size |
|---|---|---|---|---|
| 0 | `pass` | `ix` | identity; holds last frame's velocity | 256² |
| 1 | `adv` | `r draw` bang (in0), force, `pass` (state) | backward self-advection (periodic 4-tap bilinear) + `force · F`; runs every frame even with no force | 256² |
| 2–3 | `fx`,`fy` | prev | forward DFT x then y | 256² |
| 4 | `spec` | `fy` | projection blend → viscosity·drag decay | 256² |
| 5–6 | `iy`,`ix` | prev | inverse DFT y then x; `ix` outputs real part, zero Im, NaN-guarded | 256² |
| 7 | `enc` | `r draw` bang (in0), force (passthrough), `ix` | periodic 4-tap upsample, gain, clamp, encode, bypass gate | render (from `r draw`) |

**Rationale**: the minimal chain that matches the verified math; every stage
is one codebox file and one test. **Alternatives**: merging `enc` into `ix`
as a second outlet (rejected — the encode stage needs the render-res force
for bypass passthrough and must not be 256²); pass-count reduction via
radix-2 FFT (rejected — the separable DFT is already cheap enough at 256²,
and simpler to verify).

**Consequences**: +: each stage independently testable; −: 8 pix ties
`f_vf_optical_flow` for the largest chain in the library.

### ADR-2: Solver at a fixed 256²; only the encode stage follows render res

**Context**: spec decisions — internal resolution independent of render
size. Downstream consumers and the module bench both assume a render-size
outlet.

**Decision**: solver nodes `@adapt 0 @dim 256 256`; `enc` `@adapt 1` and
**triggered by an `r draw` bang on its inlet 0**, with the force (from
`vs_inState`) on inlet 1 and the 256² velocity on inlet 2. Likewise `adv`'s
inlet 0 is an `r draw` bang, force on inlet 1, previous state on inlet 2.
In the codeboxes the bang inlet is `in1` (unused), so force = `in2` and
velocity/state = `in3`.

**Evidence (Phase 0, `tests/fluid_feasibility.py`, inside Vsynth's real
`vs_render` via the module bench)**:
- A `@adapt 0 @dim 256 256 @type float32` pix runs inside `vs_render`, reports
  `dim = [256, 256]`, and produces the exact pattern (error 6e-8) — **E1 passes**.
- A render-res stage that adapts to a *texture* on inlet 0 takes that
  texture's size. With the force inlet unconnected `vs_inState` delivers
  `vs_black`, which is **1×1**, so such an `enc` would output 1×1 and a
  decaying flow would vanish on disconnect — **E1b fails for the original
  wiring**.
- Triggering by `r draw` gives the render-context size (512×512 in the bench)
  whether or not the inlet is connected — **E1c** — and the same trigger keeps
  the solver running every frame instead of depending on `vs_inState`'s
  unconnected timer (~180 ms).

**Force validity (Phase 2)**: the `src_vecfield` flag from `vs_inState` lags
~180 ms at load/disconnect and `vs_black` is all zeros (decoded −1), so `adv`
and `enc` also gate the force by content — a real `f_vecfield` has B = 0.5,
`vs_black` has B = 0 (`abs(sample(in2, norm).z - 0.5) < 0.25`). Without it the
solver injected a −1 force for the first ~10 frames and kept the phantom
velocity (module bench, T033).

**Alternatives**: expose the 256² texture directly (rejected: FR-014 wants
consumers unchanged); adapt `enc` to the force texture (rejected: E1b).

**Consequences**: +: the outlet is always a normal render-size vecfield and
`vs_black`'s size never matters; −: (a) hot/cold inlet behavior must be
confirmed in Block D — only inlet 0 should trigger a render, so the solver
advances exactly once per frame (add a bench test); (b) the module bench
feeds 64² inputs but its render context is 512², so `bypass_out1` needs an
input at the context size for this module (Phase 2); (c) `enc` reads the
velocity from `ix` in the same frame only if draw order allows — worst case a
one-frame display latency, harmless.

### ADR-3: All interpolation is a manual 4-tap read (periodic where the domain is)

**Context**: the FFT domain is periodic; GL `sample()` clamps its neighbor
taps, and Phase 0 measured two more limits of hardware `sample()` on this
GPU (`tests/bench_fluid_probes.py`, `tests/fluid_feasibility.py`):
- `fract()` on the coordinate does **not** wrap the neighbor tap: error ≈ 0.52
  on the wrap rows/column (E-seam).
- Hardware bilinear weights are 8-bit: ≈ 1e-3 error for general fractions
  (exact only at 0, 0.5, 0.25…).
- **Minification is not bilinear**: whenever the output is smaller than the
  source, `sample()` is off by half a source texel (behaves like nearest;
  256→128/64/32 all show 1.84e-2 vs bilinear). It is exact bilinear at 1:1
  and when magnifying.

**Decision**: `adv` reads the velocity state, and `enc` reads the velocity for
upsampling, with four `nearest()` taps whose integer indices wrap with
`wrap(x, 0, N)` and a manual bilinear blend (`tests/bench/codeboxes/seam_tap4.gen`:
1.3e-6 vs the periodic reference, seam included; Phase 1: `adv` and `enc`
match the mirror to 6.5e-7 and 9.4e-6). The force is the one exception (below).

**The force** is read with hardware `sample()`: a codebox cannot read an input
texture's size (`texdim` is not defined; `in1.dim` returns 0), so manual taps
are impossible there. Phase 1 measured it: exact at 1:1 and when magnifying
(6.6e-7 vs the mirror), nearest-like when minifying — the common case, since
render res is usually > 256² (0.44 max error vs a bilinear mirror on white
noise). That is harmless for a smooth force; prefiltering it (a `Param`-supplied
size or an extra stage) is E4, tier 3.

**Alternatives**: `sample()` + `fract()` for the velocity (rejected, above).

**Consequences**: +: exact, periodic, mirror-verifiable everywhere; −: 4–16
`nearest()` reads per pixel in the cheap stages (negligible at 256²; `enc`
runs at render res with 2 channels × 4 taps, still cheap).

### ADR-4: Four baked DFT codeboxes from one template

**Context**: each DFT stage needs an axis and a direction; params set at load
race with the first compile.

**Decision**: `gen_dft.py` writes `codebox_dft_{fx,fy,iy,ix}.gen` with axis
and direction baked as constants and `N = 256` as a literal (appears exactly
twice, as in the verified codeboxes). The checked-in files are what the bench
tests.

**Alternatives**: one file + `Param inverse`/`axis` set by message
(rejected: compile-timing fragility, and it hides that the four stages are
different programs).

### ADR-5: Spectral pass definition

`spec` computes, per bin with signed indices and `k = 2π·idx`:

1. **Operator wavenumbers** `kx, ky` with the **Nyquist bin zeroed**
   (`|idx| = N/2 → 0`) — odd-symmetric derivative operators must vanish
   there, otherwise the real-field (Hermitian) symmetry breaks and the
   output picks up an imaginary part. (Closes spec edge case "Nyquist bins";
   the existing `pass_spectral` mirror does not do this — the new mirror
   does, and gets its own test.)
2. **Projection**: `û_p = û − k (k·û)/|k|²` (`k = 0` bin left alone);
   `û ← mix(û, û_p, project)`.
3. **Decay**: multiply by `exp(−(ν·|k|² + μ)·dt)` — exact viscosity and
   drag in one factor; the k = 0 (mean-flow) bin only gets the drag term.

**Parameter mapping**: physical `ν·dt·|k|²` is dimensionless; at N = 256 the
top octave is `|k| ≈ 2π·64…128`, so "honey" (top octave dead in ~1 frame)
needs `ν·dt ≈ 1e-5…1e-4`. The user-facing `viscosity` will be a curve onto
that range, chosen in tier-3 tuning; the codebox takes the physical `ν`.

### ADR-6: Containment — real part, NaN guard, clamp

**Decision**: `ix` writes `vec(Re u, 0, Re v, 0)` (discarding numerical
imaginary residue every frame so it cannot accumulate) and replaces
non-finite values with 0 using **`switch(abs(x) < 1e30, x, 0)`**. Bench-verified
(E-nan, 2026-09-23): this clears both NaN and Inf and passes finite values
unchanged, whereas the originally planned `x == x` test **does not work** —
on this GPU `NaN == NaN` evaluates true. `enc` also clamps the encoded result
to [0, 1].
**Rationale**: a NaN entering the feedback loop persists forever
(NF-003). **Consequence**: one extra compare per channel — negligible.

### ADR-7: Feedback, forcing units, shared `dt`

- Feedback is the established Pattern 1: `ix → pass → adv` with the usual
  one-frame latency; within a frame the chain evaluates in draw order as the
  8-stage `f_vf_optical_flow` chain already does.
- **Units**: velocity is in decoded `f_vecfield` field units; displacement
  per frame = `velocity · dt` (same meaning as `f_vf_advect`'s `dt`);
  force adds `force · F` per frame (no `dt`), so `force` reads as "velocity
  gained per frame at full-scale force".
- `dt` is one user parameter that reaches both `adv` (displacement) and
  `spec` (decay exponent).

### ADR-8: Bypass is a Param gate on `enc`, not native `@bypass`

**Context**: (a) bypass must output the incoming force unmodified, and a
neutral field — not `vs_black`'s all-zero (decoded −1) — when the inlet is
unconnected; (b) the solver must keep running; (c) native bypass skips the
whole shader (`f_vf_warp` finding, 2026-09-23).

**Decision**: `enc` gets a `bypass_gate` Param (never named `bypass`), driven
`jsui → prepend param bypass_gate → enc`. Output when gated:
`mix(neutral, force, src_vecfield)`.

**Consequences**: +: solver state warm, exact passthrough for connected
inlets, neutral otherwise; −: the module bench's native-bypass readback
reports `bypass-leaves-active` for it — add to `PARTIAL_BYPASS_BY_DESIGN`
(as for `f_vf_advect`), and the bench's `bypass_out1` check (output equals
input) remains the real test.

### ADR-9: Dedicated build script; do not extend `build_patcher.py`

**Context**: the module needs (a) the module inlet fanned to two stages via
`vs_inState`, (b) per-node `@adapt 0 @dim`, (c) params targeting three
different stages, (d) a Param-based bypass. `pix_chain` cannot express these;
extending the schema for one module is unjustified.

**Decision**: `src/f_vf_fluid/build_fluid.py`, structured like
`build_advect.py` (435 lines) and `build_seeds_multistage.py`, reusing
`build_patcher.py`'s box/wire helpers. Log the four gaps in
`ideas/build_patcher_schema_gaps.md` (item 10's per-module Param-bypass work
may make (d) worth a real schema feature later).

**Consequences**: the script stays the source of truth until the first
hand-edit; after that record drift and add `f_vf_fluid` to the
never-regenerate list.

### ADR-10: Verification strategy

1. **Tier 1 (no Max)** — `tests/fluid_mirror.py` mirrors each stage and a
   `step()` composing them. `tests/test_fluid_mirror.py` checks against
   *independent* truth: single-mode decay `exp(−νk²·dt)`; **Taylor–Green**
   decay `exp(−2νk²t)` over 100 frames (≤ 5%); divergence-free after
   projection; gradient field deleted / curl field preserved; energy
   non-increasing with no force; zero-in/zero-out exactness; Nyquist and
   Hermitian-symmetry preservation; no NaN over 10⁴ frames at extremes.
2. **Tier 2 (bench)** — `tests/bench_fluid.py` runs each real codebox file on
   the GPU against the mirror: `spec`, `adv` (incl. the periodic seam), `enc`,
   the four baked DFTs at N = 256; then a **host-sequenced multi-frame run**
   (Python feeds each stage's output to the next, 100 frames) against the
   mirror within 1e-4. This is host-driven because `run_temporal` feeds back a
   single codebox only; GPU-resident feedback timing is already covered by
   the existing Pattern-1 tests and re-checked in the real module. Cost:
   `bc.measure` per stage at 256², summed against NF-001.
3. **Module contracts** — `tests/test_module_contracts.py` (static) and
   `tests/bench_modules.py` (live, inside `vs_render`) with **no** new
   `KNOWN` entries.
4. **Tier 3 (judgement)** — scratch patch in `~/Vsynth/patterns/`: ranges,
   defaults, look, `f_vf_optical_flow`-driven stirring, cost in a real patch.

---

## Dependency Blocks

### Block A: Math foundation (tier 1)
**Dependencies**: none. **Builds**: `fluid_mirror.py`, `test_fluid_mirror.py`.
**Why**: fixes the definition of every stage (Nyquist rule, units, decay
form) and gives the GPU tests something to be diffed against.
**Checkpoint**: Taylor–Green, projection, energy, zero-in/zero-out, Nyquist,
stability all pass; mutation-checked like the existing tests.

### Block B: Stage codeboxes on the bench (tier 2)
**Dependencies**: A. **Builds**: `codebox_*.gen`, `gen_dft.py`,
`bench_fluid.py`. **Why**: separates "is the math right" (A) from "does the
GPU run it" (B).
**Checkpoint**: every stage matches its mirror; host-sequenced 100-frame run
within tolerance; per-stage cost recorded.

### Block C: In-Vsynth feasibility (highest risk — start in parallel with A)
**Dependencies**: none. **Builds**: a throwaway scratch bpatcher —
`@adapt 0 @dim 256 256` pix feeding a render-res pix — plus the answers to
E1/E1b/E-seam below. **Why**: if a 256² pix behaves badly inside Vsynth's
render context, ADR-2 changes; better to know before Block D.
**Checkpoint**: E1 and E1b answered in writing (in `tasks.md`).

### Block D: The bpatcher
**Dependencies**: B, C. **Builds**: `build_fluid.py`, `definition.py`,
`package/patchers/f_vf_fluid.maxpat`, contract-bench pass.
**Checkpoint**: contract bench green with no new XFAILs; two instances
coexist; bypass check passes.

### Block E: Tuning and docs (tier 3)
**Dependencies**: D. **Builds**: ranges/defaults, `docs/f-reference/f_vf_fluid.md`,
helpfile, `f_modules` menu slot (∇ marked), README + module-inventory rows.
**Checkpoint**: spec success criteria 7–8 judged by Matt.

---

## Implementation Phases

Maps to the spec's proposed phasing; blocks in brackets.

### Phase 0: Experiments and math [A, C] — DONE 2026-09-23
- E1: **passes** — a `@adapt 0 @dim 256 256` pix runs inside Vsynth's render
  context, exact output.
- E1b: **failed for the original wiring** (`vs_black` is 1×1); fixed by `r draw`
  triggers (ADR-2), confirmed as E1c.
- E-seam: manual 4-tap is exact and periodic; `sample()`+`fract()` is not (ADR-3).
- E-nan: `abs(x) < 1e30` guard works, `x == x` does not (ADR-6).
- E5: a `Param` loop bound **compiles and matches** `np.fft` at N = 128 and 64
  (7e-8) — runtime-selectable resolution is possible; its cost is unmeasured.
- E4 (force downsample filter): still open for tier 3, but hardware `sample()`
  minification is nearest-like, so any filtering is done manually (ADR-3).
- `fluid_mirror.py` + `test_fluid_mirror.py`: 16/16, mutation-checked.
- **Checkpoint**: met. Findings table in `tasks.md`.

### Phase 1: Solver stages on the bench [B] — DONE 2026-09-23 (`tests/bench_fluid.py` 9/9)
_Outcome: all stages match the mirror at float precision; 100 chained GPU frames
within 3.1e-6 of the mirror; Taylor–Green 0.85% at frame 100; cost 2.4–2.8 ms/frame
(NF-001 budget 3 ms). See tasks.md Findings._
- Codeboxes: `adv`, `spec`, `enc`, baked DFTs (`gen_dft.py`), `ix` guards.
- `bench_fluid.py`: per-stage GPU-vs-mirror, seam test, host-sequenced
  multi-frame, NaN-guard behavior, cost.
- **Checkpoint**: spec success criteria 1–6 pass on the GPU path.

### Phase 2: Build the module [D] — DONE 2026-09-23 except the Vsynth smoke test (T034) — stories US1, US2, US3, US5
- `build_fluid.py` → patcher: 8 pix with `#0_` names, `vs_inState`, fan-out
  of the force, per-stage param targets (`dt`→`adv`,`spec`; `force`→`adv`;
  `viscosity`,`project`,`drag`→`spec`; `gain`,`bypass_gate`→`enc`;
  `src_vecfield`→`adv`,`enc`), `autopattr` with `varname`, `moduleSize`,
  bypass jsui → `prepend param bypass_gate`.
- `definition.py` (metadata), contract tests, module bench.
- **Checkpoint**: contracts green; two instances independent; bypass
  passes through / neutral.

### Phase 3: Tuning in Vsynth [E] — story US4
- Scratch patch with `f_vf_vortex`, `f_vf_flow`, `f_vf_repulse`,
  `f_vf_optical_flow` as force sources → `f_vf_fluid` → `f_vf_advect`/`warp`.
- Set ranges/defaults and the `viscosity` curve; decide 256² vs 128².
- **Checkpoint**: Matt judges success criteria 7–8; cost recorded (NF-001).

### Phase 4: Docs and integration [E]
- Reference doc, helpfile via the generation pipeline, `f_modules` menu (∇),
  README + module-inventory rows, `plan.md` status, HANDOFF.

---

## Complexity Notes

- **Largest-chain tie** (8 pix, same as `f_vf_optical_flow`); justified by
  one-stage-per-verified-step and by cost being dominated by the four DFT
  passes anyway.
- **Compile-time N**: the DFT loop bound is a literal (N = 256). 128² would
  be a regenerated set of codeboxes and a build-script constant; runtime
  selection is only possible if E5 succeeds.
- **The dependencies that could have reshaped the plan** (E1/E1b: internal
  size inside Vsynth, unconnected-force size) were resolved in Phase 0; E1b
  did change the wiring (ADR-2: `r draw` triggers).
- **Known limits carried from the spec**: periodic domain (no walls);
  semi-Lagrangian advection is dissipative (Taylor–Green bound is the
  measurement); no vorticity confinement; nothing here changes existing
  consumers.

## Next Steps

- Generate `tasks.md` (with the constitution's Phase 0 verification-tier
  template).
- Optional clarify pass on the spec if the plan's findings (notably the
  `enc`-at-render-res change to Open Experiment 1) should be reflected there.
