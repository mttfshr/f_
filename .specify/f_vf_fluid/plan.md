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
| 1 | `adv` | `pass` (state), force | backward self-advection (periodic bilinear) + `force · F` | 256² |
| 2–3 | `fx`,`fy` | prev | forward DFT x then y | 256² |
| 4 | `spec` | `fy` | projection blend → viscosity·drag decay | 256² |
| 5–6 | `iy`,`ix` | prev | inverse DFT y then x; `ix` outputs real part, zero Im, NaN-guarded | 256² |
| 7 | `enc` | force (passthrough), `ix` | bilinear upsample, gain, clamp, encode, bypass gate | render |

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
outlet; a 256² outlet would break the bench's `bypass_out1` shape check and
risk consumers seeing a small texture.

**Decision**: solver nodes `@adapt 0 @dim 256 256`; `enc` `@adapt 1` with its
inlet 0 = the render-res force so it adapts to render size, inlet 1 = the
256² velocity, sampled with bilinear.

**Rationale**: upsampling happens once, inside the module, and outputs are
ordinary render-size textures. **Alternatives**: expose the 256² texture
directly (rejected: FR-014 wants consumers unchanged, and bypass equality
needs the same size as the input).

**Consequences**: −: `enc`'s size when the force inlet is *unconnected*
depends on what `vs_inState` delivers (`vs_black`'s dimensions) — an open
experiment (E1b). +: removes the "small texture downstream" risk from
spec Open Experiment 1; what remains is whether a 256² pix works inside
Vsynth's render context at all.

### ADR-3: Periodic self-advection with a manual 4-tap bilinear

**Context**: the FFT domain is periodic; GL `sample()` clamps at edges, so
`fract()` on the coordinate alone may leave a clamped seam at the wrap.

**Decision**: `adv` samples the velocity with four `nearest()` reads whose
integer indices wrap with `mod`, blended manually. Mirror:
`gpu_sim.sample(..., wrap=True)`.

**Rationale**: exact periodicity, bench-verifiable. **Alternatives**:
`sample()` + `fract()` — kept as an experiment (E-seam: compare both at the
seam against the periodic reference; use the cheaper if it matches).

**Consequences**: +: no edge artifacts in the flow; −: 4 reads instead of 1
in a cheap 256² stage (negligible).

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
imaginary residue every frame so it cannot accumulate), replaces non-finite
values with 0 (test via `x == x`, verified on the bench that GenExpr
compares `NaN` as expected), and `enc` clamps the encoded result to [0, 1].
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

### Phase 0: Experiments and math [A, C]
- E1: does a `@adapt 0 @dim 256 256` `jit.gl.pix` run inside Vsynth, and does
  a render-res pix downstream sample its output correctly? (Highest risk.)
- E1b: what size is `enc`'s output when the force inlet is unconnected
  (`vs_inState` → `vs_black`)? If small, fall back to a Vsynth-render-size
  source for the `enc` adapt.
- E-seam: `sample()`+`fract()` vs manual 4-tap at the periodic seam.
- E4: force downsample filter — bilinear vs 2×2 box, on a noisy source.
- E5 (optional): can the DFT loop bound be a `Param`?
- Write `fluid_mirror.py` + `test_fluid_mirror.py`; pin down the Nyquist
  rule, units and decay form.
- **Checkpoint**: Block A green; C answers recorded. *Blocks Phase 1.*

### Phase 1: Solver stages on the bench [B]
- Codeboxes: `adv`, `spec`, `enc`, baked DFTs (`gen_dft.py`), `ix` guards.
- `bench_fluid.py`: per-stage GPU-vs-mirror, seam test, host-sequenced
  multi-frame, NaN-guard behavior, cost.
- **Checkpoint**: spec success criteria 1–6 pass on the GPU path.

### Phase 2: Build the module [D] — stories US1, US2, US3, US5
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
- **The unresolved dependencies** that could reshape the plan are exactly
  E1/E1b (internal size inside Vsynth, unconnected-force size) — both in
  Block C, run first.
- **Known limits carried from the spec**: periodic domain (no walls);
  semi-Lagrangian advection is dissipative (Taylor–Green bound is the
  measurement); no vorticity confinement; nothing here changes existing
  consumers.

## Next Steps

- Generate `tasks.md` (with the constitution's Phase 0 verification-tier
  template).
- Optional clarify pass on the spec if the plan's findings (notably the
  `enc`-at-render-res change to Open Experiment 1) should be reflected there.
