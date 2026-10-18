# REGISTRATION_NOTES — f_tf_smooth

Shared-file edits belong to the parent (owner constraint 2026-10-17). This
module owns only:

- `src/f_tf_smooth/codebox_state.gen` — the state pix (2 gen inlets:
  in1 = frame tensor, in2 = previous blended tensor via the feedback loop;
  Params `release` (provisional 0.5, gate OQ1 open) and `bypass_gate`;
  ADR-3: no clamp anywhere in the feedback path).
- `src/f_tf_smooth/codebox_render.gen` — the render passthrough node.
- `tests/modules/tf_smooth/test_tf_smooth.py` — tier-1 mirror, 12/12 green, incl. the
  decay-theorem and opposite-axis-reinforcement tests.
- `tests/modules/tf_smooth/bench_tf_smooth.py` — tier-2 bench, WRITTEN, NOT RUN (needs the
  bench open; run pending Matt).
- `docs/f-reference/f_tf_smooth.md` — draft reference doc.

## tests/lib/benchdeps.py — DATA registration (tasks T014)

Enforced by `tests/toolchain/test_benchdeps.py::test_every_real_bench_file_is_registered_and_its_globs_match`.
Exact line to add (mirror of the tensormap/axisflow entries; verified no dead
glob — `benchdeps.input_files("bench_tf_smooth")` resolves):

```diff
     "bench_tf_tensormap": _MACHINERY + ["src/f_tf_tensormap/codebox_*.gen"],
     "bench_tf_axisflow": _MACHINERY + ["src/f_tf_axisflow/codebox_*.gen"],
+    "bench_tf_smooth": _MACHINERY + ["src/f_tf_smooth/codebox_*.gen"],
 }
```

NOT added to `tests/bench.sh` DEFAULT (T014: not a regression gate until Matt
says so). NOTE: an earlier draft of this session edited benchdeps.py directly;
that edit has been reverted — the file at `.specify/f_tf_glyph/`'s sibling
bench entries must not silently absorb this module's line; the parent applies
it. (`tests/modules/tf_glyph/bench_tf_glyph.py` and `tests/modules/tf_sharpen/bench_tf_sharpen.py` were transient
strays from sibling sessions and were removed; they must be re-created by
their own owners if wanted, alongside their own DATA lines.)

## tests/contracts/bench_modules.py — BYPASS_EXPECT (tasks T023)

Once the module patcher is registered for the module bench, add:

```python
    "f_tf_smooth": {1: IN1},    # bypass = exact passthrough of the inlet tensor (ADR-4), not a freeze
```

(with `IN1` as used for f_vf_advect's composite outlet). Bypass here is
passthrough semantics, not the neutral-frame semantics tensormap uses.

## Module menu (src/f_modules/menu.py) / README.md / module-inventory / HANDOFF

**PENDING — not performed** (shared files, parent-owned). Suggested placement,
per the tensormap T033 finding that `tools/` scripts no longer exist (path is
`src/f_modules/menu.py` → `build/generate_menu.py`, category Utilities,
`vecfield False`, next to Tensor Map):

```python
        ("Tensor Smooth", "tf_smooth", False),
```

README status-table row (⚠ Unverified pending tier-3, matching this module's
build state):

```
| `f_tf_smooth` | One-pole temporal tensor smoother (inertia) — stabilizes structure-tensor fields across frames |
```

## definition.py (Phase 3 — BUILT 2026-10-17)

Written and built (per parent instruction). Artifact paths:

- definition.py: `src/f_tf_smooth/definition.py`
- built patcher: `package/patchers/f_tf_smooth.maxpat` (JSON-valid)
- build invocation used: `python3 build/build_patcher.py src/f_tf_smooth/definition.py`
  (from repo root); JSON-validated with
  `python3 -c "import json; json.load(open('package/patchers/f_tf_smooth.maxpat'))"`.

As-built summary (plan ADR-2, f_vf_advect wiring precedent): two-node
`pix_chain` — `state` (primary, `codebox_state.gen`, 2 gen inlets / 1 gen
outlet) and `render` (support, `codebox_render.gen`, 1 inlet / 1 outlet,
obj-50) — with `pix_wires` `["state",0,"render",0]` and
`["render",0,"state",1]` (the feedback loop: the render node's passthrough
outlet is both the module outlet and next frame's `T_prev`), plus the standard
automatic routepass → state(in0) source wire. Outlet 0 sourced from the render
node (`outlet_source_override` {0: "render"} + raw_lines obj-50→obj-2).
Params `release` (0–1, default 0.5, PROVISIONAL; gate OQ1 open) and `bypass`
(type bypass, bypass_mode "param", bypass_target the primary = state pix,
ADR-4 passthrough). Single outlet, signal_type "tensor out" with the amber
tensor colour (tensormap T030 precedent). Contract analysis on the built
patcher is CLEAN (both params driven, none unused, bypass reaches the
primary); drift check: zero problems for f_tf_smooth.

## Build-path finding (contradicts triad docs; recorded for the parent)

Triad docs (.specify/f_tf_smooth/plan.md "Files", tasks.md Expected Output
Layout) put the codeboxes and definition.py in `.specify/f_tf_smooth/`. The
built-module layout (tensormap and axisflow shipped codeboxes) is `src/<name>/`
— both read each other's `codebox_*.gen` from `src/f_tf_tensormap/`. This
module's codeboxes were written to `src/f_tf_smooth/` accordingly, which also
keeps the `src/f_tf_smooth/codebox_*.gen` DATA glob above consistent with
tensormap's glob style. If Matt prefers `.specify/`, move the two .gen files
and fix the glob (definition.py references gen files relative to its own
directory, per tensormap's `CODEBOX_DIR = ""`).