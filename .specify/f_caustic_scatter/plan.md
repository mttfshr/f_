# Implementation Plan: f_caustic sheets mode

_Created: 2026-10-07_
_Spec: `.specify/f_caustic_scatter/spec.md` (what and why, the measured numbers, the seven resolved decisions;
this file is HOW only)_
_Research background: `ideas/optics_map.md`, `ideas/f_lumia.md`; spike records `tests/spike_scatter.py`
(stages `s0`-`s11`), `tests/bench/spike_scatter*.maxpat`, `spike_scatter.jxs`_

---

## Summary

Add a second mode to `f_caustic`: **sheets**, a GPU forward scatter (a lattice of points displaced through the
vecfield and splatted additively into a float32 capture), beside the existing 8-tap gather, which stays
byte-for-byte untouched. The module keeps its two inlets (texture + control, vecfield) and two outlets. New parameters: `mode` (soft | sheets,
default soft) and `detail` (1-5, the capture-size / density ladder, default 5). `scale`, `gain`, `mix_pct` and
`bypass` are shared.

Technically: the existing `caustic_pix` (primary pix, soft) is joined by a raw GL scene (a `jit.gl.node` capture
holding a points `jit.gl.mesh` drawn with a `.jxs` shader), a **sheets composite pix** (tone map, bilinear upscale
to the source's size, additive composite, unconnected-vecfield guard) and a **select pix** (a `Param` picks soft or
sheets per outlet and applies bypass). The inactive branch is disabled; the lattice exists only in sheets mode.
Everything numeric is verified in NumPy (tier 1) and on the module bench (tier 2) before the look is judged
(tier 3).

---

## Technical Context

**Stack**: Max 9.2, Vsynth, `jit.gl.pix` + GenExpr codeboxes (`float32`) for composite and select; GLSL 1.20
`.jxs` vertex + fragment shader for the scatter (the one constitution deviation, spec "What the sheets mode does");
Python 3 (NumPy) for the mirror and truth; the module bench (`tests/bench*`, `tests/spike_scatter.py` is the
runner precedent) for GPU verification; the declarative builder (`src/f_caustic/definition.py` ->
`build/build_patcher.py` -> `package/patchers/f_caustic.maxpat`).

**Reused, already verified in the spike** (`ideas/optics_map.md`): the scene (gridshape matrix -> points mesh -> node
capture), the shader (tent splat, corner snap, `point_size 2`), the `detail` message network (`s11`), the tone-map
and upscale stage (`s10`), the NumPy emulation `ref_scatter` and photon-counting truth (`scratch/caustic_fidelity.py`).

**Builder support** (`build/spec.md`, verified by reading `build/build_patcher.py`): `pix_chain` nodes with
`pix_wires` cross-wiring, `pix_attrs`, `gen_code`; per-param `pix_target` (a node id or a list), `pix_wire: False`,
`ui: False`; `inlet_fanout` and per-`mod_inlets` `fanout` / `state_nodes`; `outlet_source_override`;
`raw_boxes` / `raw_lines` / `raw_parameters` (best derived, not typed: `build/capture_raw.py`, `raw_ui.json`).
Precedents: `f_grain` and `f_lens` (raw boxes), `f_vf_fluid` / `f_vf_advect` / `f_vf_seeds` (pix_chain).

**Constraints from bench-verified facts** (`skills/jit-gen-codebox/SKILL.md`; every codebox here follows them):
- **Read the skill's Language Model and Silent Failures sections before writing each codebox** (the look-patch tone
  stage broke on two documented rules): functions precede every statement including `Param`; components read inline
  on `sample()`; `Param` names never shadow GenExpr built-ins (`mix`); never name a variable `in1`-shaped.
- `sample()` is bilinear and clamps; the composite relies on it for the upscale.
- Native `@bypass` skips the shader and flips secondary outlets: bypass is a `Param` (`bypass_mode: "param"`).
- **All object names `#0`-scoped** (the scene's node and shader names already are), so several instances coexist.
- A new gen compiles at its first render; params sent earlier fail (send order matters in the mode / detail network).
- `.jxs` shaders must be on Max's search path; Vsynth keeps its own in its package `code/` (`Vsynth/code/vtfk.jxs`).

**Cost** (spec "Measured facts"): step 5 about 5-9 ms on an M3 Max (never measured directly: only observed to fit the
cap), density-driven; timings vary up to 2x between runs. Soft mode must cost what it costs today plus one select
pass. The `detail` ladder is the escape hatch for weaker machines.

---

## Constitution Check

- ✅ **1. Vsynth compatibility**: two inlets and two outlets unchanged; `vs_inState` on the source texture, none on the
  vecfield; the scene draws in the `vsynth` context like `vs_xyz_disp`.
- ✅ **2. Codebox before patcher**: composite and select codeboxes are written and bench-verified as files before any
  structure is built (Phases 2 and 4); the shader is verified in the module bench (a `.jxs` is not a pix codebox).
- ⚠️ **Codebox-first (principle)**: the shader is a deliberate, narrow deviation. The amendment wording is decided
  (spec, Decisions item 7) and is applied when the mode ships (task T040).
- ✅ **3. One bpatcher, one concern**: both modes redistribute light through a vecfield; Matt chose a second mode over
  a separate module.
- ✅ **4. Specs before building**: the spec is written and its decisions resolved.
- ✅ **5. Tasks.md is the session anchor**: `.specify/f_caustic_scatter/tasks.md`; README and HANDOFF updated at each
  checkpoint.
- ✅ **6. Numbers before eyes**: tier 1 and tier 2 targets (spec, Acceptance criteria) pass before tier 3.

---

## Project Structure

```
src/f_caustic/
  definition.py            # EXTENDED: pix_chain (3 nodes), mode / detail params, raw scene     — Phase 4
  codebox_v2.gen           # soft path: UNCHANGED
  codebox_sheets.gen       # sheets composite: tone, upscale, additive composite, guard         — Phase 2
  codebox_select.gen       # select: mode gate, bypass                                          — Phase 4
  scatter_scene.py         # generates raw_ui.json: scene, detail network, mode network         — Phase 2
  raw_ui.json              # generated (raw_boxes / raw_lines / raw_parameters)                 — Phase 2
package/code/f_caustic_sheets.jxs                        # the shader (new folder)            — Phase 2
package/patchers/f_caustic.maxpat                        # rebuilt                            — Phase 4
tests/
  scatter_mirror.py        # promoted NumPy mirror (ref_scatter) + photon-counting truth        — Phase 1
  test_scatter_mirror.py   # tier 1                                                              — Phase 1
  bench_caustic_sheets.py  # tier 2: the module bench, sheets mode                               — Phases 2-4
  baselines/f_caustic_soft.npz   # the soft path's output BEFORE any change                      — Phase 0
  bench/spike_scatter*.{maxpat,jxs}, spike_scatter.py      # stay as the records
docs/f-reference/f_caustic.md                            # updated                              — Phase 6
package/help/f_caustic.maxhelp                           # regenerated through the pipeline    — Phase 6
.specify/constitution.md                                 # amended at ship                      — Phase 6
```

**Structure decision.** Declarative `definition.py` + generated raw scene, not a dedicated build script
(`f_vf_fluid`'s route). Reason: the pix chain is three nodes, not seven; the scene is raw boxes, which `f_grain` and
`f_lens` already ship; and staying on the generic builder keeps drift detection, the contract tests, the helpfile
pipeline and the launcher working unchanged. If Phase 1's builder checks show a limit, the fallback is a dedicated
script (ADR-1).

---

## Architecture Decisions

### ADR-1: Declarative builder, with a dedicated script only as the fallback
**Context**: how to produce a module with a GL scene, three pix stages and a mode network.
**Decision**: extend `src/f_caustic/definition.py` (`pix_chain`, `pix_wires`, `mod_inlets` fanout,
`outlet_source_override`, raw scene).
**Alternatives**: a dedicated `build_caustic.py` (the `f_vf_fluid` precedent): rejected unless a verification task
(T009, T010) shows the builder cannot target multiple stages for one param or override outlet sources with a pix node.
**Settled 2026-10-07 (T011): declarative `definition.py`; no dedicated build script.**
**Verified 2026-10-07 (T009, T010)** by building a throwaway definition in-process (`scratch/probe_builder_targets.py`):
`pix_target` lists feed one param's attrui to several stages; `bypass_target` reaches several stages; `outlet_source`
(not `outlet_source_override`, which is for raw boxes) feeds both outlets from a `pix_chain` node; a `mod_inlets`
`fanout` reaches pix nodes and a raw box without `vs_inState`; `inlet_fanout` carries the texture through
`vs_inState` into pix nodes and a raw box. Every `pix_chain` node needs an explicit `primary` flag.
**Consequences**: + drift, contracts, helpfile pipeline keep working; - the builder's multi-stage keys are newer
(2026-10-05) and `f_caustic` becomes one of their heaviest users.

### ADR-2: The scene is derived by a script into `raw_ui.json`, not typed or captured by hand
**Context**: `build/spec.md` says raw boxes are "best derived, not typed"; `capture_raw.py` derives them from a
shipped patcher, which does not exist yet for this scene.
**Decision**: `src/f_caustic/scatter_scene.py` emits the scene (node, mesh, gridshape, slabs, shader, the `detail`
select and message boxes, the mode network) with `#0`-scoped names, writing `raw_ui.json` in the shape `f_grain`'s
definition reads. It reuses the box construction of `tests/bench/make_spike_scatter.py`, which stays as the record.
**Alternatives**: hand-build in Max then `capture_raw.py` (the `f_grain` route): rejected, the scene is already
generated and verified in the spike; typing the boxes in `definition.py`: rejected by the builder's own guidance.
**Consequences**: + one source of truth, regenerable; - the first build must be checked against drift carefully
(raw boxes that the builder does not know are matched as "extra").

### ADR-3: Mode selection happens in a select pix, driven by a `Param`
**Decision**: `select_pix` takes soft composite, soft layer, sheets composite, sheets layer (and the source for
bypass) and outputs the two outlets by `Param sheets_gate`. No routing object touches a texture message.
**Alternatives**: `gate` objects as in `f_texrouter`, `gswitch` UI objects (used in the look patch), `switch`:
rejected, a Param needs no routing and works with the builder's bypass convention.
**Consequences**: + soft mode adds one cheap pass; soft output is `mix(a, b, 0)`, exact in float32; - the soft
branch's outputs now feed a stage instead of the outlets, so the contract and bench tables need updating (T029).

### ADR-4: Bypass is applied once, in the select stage
**Context**: the builder drives `bypass_gate` on the primary pix; the sheets stages would each need it.
**Decision**: the select stage applies `bypass_gate` as the last step (`mix(selected, src, bypass_gate)` on the
composite; the layer goes to black), so a bypassed module is a passthrough in either mode. `caustic_pix` keeps its
own `bypass_gate` (untouched, driven by the builder as today).
**Mechanism (verified, T009)**: `bypass_target: ["caustic", "select"]` wires the bypass toggle's
`prepend param bypass_gate` to both stages (each codebox must declare `Param bypass_gate(...)`); no raw fallback is
needed.
**Consequences**: + the sheets composite stays free of bypass; - two stages carry the Param.

### ADR-5: The inactive branch is disabled; the lattice exists only in sheets mode
**Decision**: switching mode sends `enable` to the node, the mesh and the sheets stages (1 in sheets mode) and the
inverse to `caustic_pix`; entering sheets mode sends the current `detail`, which builds the lattice; entering soft
mode does not free it (a rebuild costs a hitch) but nothing draws. A fresh module loads in soft mode with no lattice.
**Alternatives**: always build the lattice: rejected, 200 MB at step 5 for nothing in soft mode.
**Consequences**: + soft mode costs nothing extra in memory; - the first switch to sheets hitches (documented,
same as `detail`).

### ADR-6: Capture size is fixed and square; the composite adapts to the source
**Decision**: the scene always captures a square of the `detail` step's size; `sheets_pix` is `@adapt 1` (follows its
first input, the source) and reads the capture with `sample(inN, norm)`. No fixed `@dim`. A non-square output
stretches the UV square, as in the look patch (the soft path is also UV-space).

### ADR-7: One shader, simplified, in `package/code/`
**Decision**: `f_caustic_sheets.jxs` is the spike shader with the experiment uniforms removed (`h`, `jit`, `latn`,
`taps`, `snap`): corner snap, size 2, regular lattice, one source read and the orientation flip are fixed. `scale`
(distance), `weight` and `res` remain uniforms. Names `#0`-scoped.
**Verified 2026-10-07 (T007):** after Max is relaunched, a file in `package/code/` is found on the search path (a JS
`File()` lookup, with Vsynth's `vtfk.jxs` as the positive control and a bogus name as the negative one). Two facts for
developers: Max does not add a NEW folder to the search path until it is relaunched (`max.refresh()` only rescans
folders already on the path), and the bench does not report `jit.gl.shader` load failures (a nonexistent shader file
raised no error), so the shader's loading is verified by **non-black output** in the module bench, not by an empty
error list. The final check from a patch outside the repo is part of the live check (T037).

### ADR-8: Testing split
**Tier 1**: `tests/scatter_mirror.py` (promoted `ref_scatter` and truth), offline. **Tier 2**: `tests/bench_caustic_sheets.py`
on the module bench, one function per acceptance bullet; the `s10` and `s11` checks are promoted into it; the existing
`tests/bench_modules.py` `BYPASS_EXPECT` entry and the contract tests keep passing. **Tier 3**: Matt on real video.
The cost check uses an interleaved A/B method, not the K-meshes multiplier (it failed).

---

## Dependency Blocks

### Block A: Baselines and feasibility (no module change)
**Dependencies**: none.
**Builds**: the soft-path baseline (recorded before anything changes), four verification spikes (shader location,
unconnected pix input, builder multi-stage targets, builder routing), and the promoted tier-1 mirror.
**Why this block**: ADR-1's builder choice and the unconnected-vecfield guard both rest on facts we do not have yet,
and "soft mode unchanged" is only checkable against a baseline recorded first.
**Verification checkpoint**: baseline file committed; the three spikes each answered in writing (HANDOFF) with their
fallback chosen; `tests/test_scatter_mirror.py` green.

### Block B: Scene, shader and sheets composite (module-bench only)
**Dependencies**: Block A.
**Builds**: `scatter_scene.py` + `raw_ui.json`, `package/code/f_caustic_sheets.jxs`, `codebox_sheets.gen`, and a
bench-only wrapper that runs them without the real `f_caustic` (the spike bpatcher precedent).
**Why this block**: the sheets path is the new, risky code; prove it standalone before it touches the module.
**Verification checkpoint**: the sheets tier-2 checks that do not need the select stage pass (identity, energy,
orientation, quality per step, tone/upscale, unconnected-field guard).

### Block C: `detail` ladder and mode network
**Dependencies**: Block B.
**Builds**: the `detail` select-and-message network and the mode / enable network in the scene generator;
`codebox_select.gen`; the `mode` and `detail` params.
**Why this block**: the controls only make sense around a working path; they are the part that reshapes the module.
**Verification checkpoint**: `detail N` identical to the explicit messages for all five steps; mode switch toggles
enables and the select gate as intended (bench).

### Block D: Build into `f_caustic`
**Dependencies**: Blocks B and C.
**Builds**: the extended `definition.py`, the rebuilt `package/patchers/f_caustic.maxpat`, updated contract / bench /
drift expectations.
**Why this block**: structure comes last (constitution 2).
**Verification checkpoint**: soft mode bit-identical to the Phase 0 baseline; all existing tests pass; `build/drift.py`
clean; the sheets tier-2 suite passes against the real module.

### Block E: Live and release
**Dependencies**: Block D.
**Builds**: Matt's live check, the reference doc, the helpfile, the constitution amendment, README / HANDOFF /
plan updates.
**Verification checkpoint**: Matt confirms tier 3; docs and tests current; committed.

**Please confirm this sequence before tasks are cut in detail** (the skill's checkpoint); `tasks.md` is drafted
from it.

---

## Implementation Phases

Phases map to the blocks and to `tasks.md` (Phase 0 Setup, 1 Foundational, 2 US1, 3 US2, 4 US3, 5 US4, 6 Polish).

- **Phase 0 Setup**: record the soft baseline; create the folders; read the skill sections that govern the new codeboxes.
- **Phase 1 Foundational (Block A)**: the three verification spikes; the promoted tier-1 mirror. *Blocks all story work.*
- **Phase 2 US1 (Block B)**: sheets mode renders correctly (the MVP).
- **Phase 3 US2 (Block C, part)**: the `detail` ladder.
- **Phase 4 US3 (Block C part, Block D)**: the mode switch, the extended definition, soft mode unchanged.
- **Phase 5 US4 (Block D)**: shared behaviours: bypass in both modes, unconnected vecfield, instances.
- **Phase 6 Polish (Block E)**: live check, docs, constitution, release notes.

---

## Complexity Notes

- This is the module with the most moving parts in the library: a GL scene, three pix stages, a mode network and a
  generated raw-box layer. The mitigation is the order: everything risky is proven standalone (Blocks A and B) before
  the module changes, and soft mode is protected by a baseline recorded first.
- The builder's multi-stage keys are recent. Two verification tasks (T009, T010) exist to find a limit early; the
  fallback (a dedicated build script) is already named.
- Timing evidence is weak (2x run-to-run). Nothing in this plan treats a single timing as a gate; cost checks compare
  within a run, interleaved.
