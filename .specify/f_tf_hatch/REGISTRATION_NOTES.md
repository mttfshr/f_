# REGISTRATION_NOTES.md -- f_tf_hatch parallel build (2026-10-17)

Shared-file lines this module's build would need, prepared instead of editing
the shared files directly (parent-side hard constraint: hatch touches only
`.specify/f_tf_hatch/`, its own tests/bench files, and its docs page). One
section per shared file, exact diff-style content; the parent applies or
declines each.

## tests/benchdeps.py (DATA table)

```python
    "bench_tf_hatch": _MACHINERY + ["src/f_tf_hatch/codebox_*.gen"],
```
(one row after `"bench_tf_axisflow"`. Without it, `tests/bench.sh --changed`
always runs and never records bench_tf_hatch; a test in test_benchdeps.py
enforces the entry.)

## tests/bench_modules.py (BYPASS_EXPECT table)

```python
    "f_tf_hatch": {"outlets": {"out0": "black", "out1": "black"},
                   "note": "bypass_mode param (bypass_gate on stage e3): both outlets black"},
```
(follows the tensormap entry's shape; both hatch outlets are black under
bypass. Not added anywhere — the bench run that exercises it is pending.)

## tests/bench.sh (DEFAULT regression list)

NOT requested. Per the tensormap T021 discipline, bench_tf_hatch stays out of
DEFAULT until Matt makes it a regression gate.

## src/f_modules/menu.py (CATEGORIES)

```python
        ("Tensor Map", "tf_tensormap", False),
        ("Axis Flow", "tf_axisflow", False),
        ("Hatch", "tf_hatch", False),
```
(one row after Axis Flow, in Utilities). After applying:
`python3 build/generate_menu.py` and `python3 build/generate_launch.py` (the
tensormap T033 finding — the tools/ scripts referenced by older tasks are
gone). README row for `generate_launch`'s Patches table, with the ⚠ flag:

```
| `f_tf_hatch` | ⚠ Unverified. Orientation-committed hatch/engraving renderer: marks laid out and committed from the structure tensor (strokes → dots as coherence falls) |
```
placed after the `f_tf_axisflow` row in README.md's Utilities table.

## docs/f-reference/module-inventory.md

```markdown
| `f_tf_hatch` | raw tensor → tex (marks) | Orientation-committed hatching: decodes the tensor in-pixel (glyph ADR-2 idiom), lays dashed marks along the axis (f_weave distance-field mechanics in the per-pixel frame), commits mark shape per-pixel from coherence (strokes → dots → nothing). 3 stages, no loops, ~6 taps/pixel. Chain-terminal renderer; wants `f_tf_smooth` upstream |
```
(inserted after the `f_tf_axisflow` row, in the tensor/field section where
tensormap/axisflow live.)

## docs/f-reference/f_tensor_type.md (Family members table)

```markdown
| `f_tf_hatch` | Consumer (renderer) | Decodes outlet 0 in-pixel via the glyph ADR-2 idiom; commits mark shape from coherence. Outlet rendering only (marks), never a tensor/vecfield producer |
```
(appended to the table.)

## .specify/f_tf_hatch spec.md — exact lines the build would change in-place

1. **Inlet table, inlet 1 row** (OQ2 resolved OUT of v1 — plan ADR-6 T002
   record):
   - DELETE the row `| 1 | texture (optional) | tone (PROVISIONAL — OQ2) | ...`
   - REPLACE the "vs_black fallback" paragraph's third sentence "The tables
     below list inlet 1 as **provisional pending OQ2**." with:
     "The tone inlet was DECLINED at T002 (plan ADR-6 record): inlets stay
     single in v1; tone gating is deferred with the cross-hatch layer to a v2
     (the v2 pointer there is inlet-1-luma, not density layering)."

2. **Open Question 2** — add after the paragraph:
   "> **DECIDED (T002, 2026-10-17): OUT of v1.** Recorded in plan ADR-6 with
   > the spike's evidence; the live confirmation task (T021) becomes the v2
   > trigger, pending Matt."

3. **Open Question 1** — add after the paragraph (it stays open for the
   bench until T013/T016, so the gate is marked PROVISIONAL):
   "> **PROVISIONALLY DECIDED (T001, 2026-10-17): branch T.** Spike evidence
   > and the cost model are in plan ADR-1's amendment; the tier-2 bench
   > (T013/T016) is the declared resolver."

4. **Open Question 5** (aux commit/axis outlet): not decided by this build;
   stays open, unchanged.

## Constitution (Current Bpatchers table)

Row to add once the module is live-verified (NOT before, per the README ⚠
discipline):
```
| `f_tf_hatch` | Orientation-committed hatching renderer (tensor consumer, chain-terminal) |
```

---

## Build artifact report (for the parent's drift/contract checks)

- **definition.py path:** `src/f_tf_hatch/definition.py`
- **built .maxpat path:** `package/patchers/f_tf_hatch.maxpat`
- **build invocation (run from repo root):**
  `python3 build/build_patcher.py src/f_tf_hatch/definition.py`
  → "Written: package/patchers/f_tf_hatch.maxpat"; validated
  `python3 -c "import json; json.load(open('package/patchers/f_tf_hatch.maxpat'))"`
  → "VALID JSON".
- **codebox files:** `src/f_tf_hatch/codebox_stage_e1.gen` (decode+commit),
  `src/f_tf_hatch/codebox_stage_e2_T.gen` (layout, branch T),
  `src/f_tf_hatch/codebox_stage_e3.gen` (profile+compose+encode). Branch S
  files (e2_S_p1/p2) deleted at the T001 gate, never stubbed.
- **tests:** `tests/test_tf_hatch.py` (tier-1 mirror, 20/20 pass),
  `tests/spike_tf_hatch_costshape.py` (T001 gate),
  `tests/bench_tf_hatch.py` (tier 2 — WRITTEN-NOT-RUN).
- **drift note:** the built patcher is new (not in `tests/drift_baseline.json`);
  `tests/test_drift.py` must reproduce it cleanly from the definition before
  the baseline is touched (the parent owns baseline edits).