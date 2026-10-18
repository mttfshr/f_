# REGISTRATION_NOTES — f_tf_sharpen

Owner-constraint compliance file (2026-10-17): shared-file edits belong to the parent.
Each section below is the exact change this module needs, diff-style, for the parent to
apply. Nothing in a shared file was edited by this module.

---

## `tests/benchdeps.py` — DATA registration (T014)

Enforced by `tests/test_benchdeps.py::test_every_real_bench_file_is_registered_and_its_globs_match`
(`on_disk <= set(bd.DATA)`); `tests/benchdeps.input_files` also *errors on a dead glob*
(MissingInputs), so the glob below is verified to exist.

```diff
--- a/tests/benchdeps.py
+++ b/tests/benchdeps.py
@@
     "bench_tf_tensormap": _MACHINERY + ["src/f_tf_tensormap/codebox_*.gen"],
     "bench_tf_axisflow": _MACHINERY + ["src/f_tf_axisflow/codebox_*.gen"],
    "bench_tf_sharpen": _MACHINERY + ["src/f_tf_sharpen/codebox_sharpen.gen"],
}
```

**Path update (parent, 2026-10-17):** the codebox and definition were moved from
`.specify/f_tf_sharpen/` to `src/f_tf_sharpen/` per the shipped-layout
normalization (tensormap/axisflow precedent); the DATA glob and build command
now point there (already applied in `tests/benchdeps.py`).

Note: the original `.specify/`-pointing rationale is obsolete after the parent's
`src/` normalization — the glob now follows the shipped-module convention
(`src/f_tf_sharpen/`), same glob style as tensormap's `codebox_*.gen`.
NOT added to `tests/bench.sh` DEFAULT (T014: not a regression gate until Matt says so).

---

## Modulesmenu / README / HANDOFF / module-inventory (T021, T028)

Parent-owned; needs at build/integration time:

- `src/f_modules/menu.py` (→ `build/generate_menu.py`): row for `f_tf_sharpen`
  (category: Utilities, vecfield False, tensormap-style; name `f_tf_sharpen`,
  title "Tensor Sharpen").
- `README.md` + `docs/f-reference/module-inventory.md`: one row each —
  `f_tf_sharpen | tensor out | Eigengap exaggerator/relaxer (contrast dial on
  anisotropy; axis untouched, trace fixed) | Draft`.
- `HANDOFF.md`: built-module entry once parent registers.
- `tests/test_module_contracts.py` BYPASS_EXPECT: `f_tf_sharpen` → passthrough
  (output == input at bypass; the module has one outlet).

No exact diff supplied for these: menu/inventory formats are the parent's live
state; the strings above are the content this module expects to appear.

---

## Spec correction (owner-confirmed exception: own triad file)

`spec.md` "What it does" math block line `λ2' = trace/2 − gap·(λ2 − trace/2)` was a
sign slip (collapses λ1'==λ2' at γ≠1; breaks trace invariance — caught by mirror T003).
Corrected text, already applied to `.specify/f_tf_sharpen/spec.md` by this module
(own-triad file, in scope):

```
λ2' = trace/2 + gap·(λ2 − trace/2)
```

with a one-line note added under the block: *(Correction 2026-10-17: original prose
wrote a MINUS here; the trace-preserving relax form is the same PLUS sign for both
eigenvalues — caught by the tier-1 mirror's trace-invariance test, T003.)*

---

## Provisional flags carried in this module's files (no parent action needed)

- **Name gate (spec OQ4) PROVISIONAL:** `f_tf_sharpen` stays; a future rename is one
  find-replace over `.specify/f_tf_sharpen/{codebox_sharpen.gen,definition.py}`,
  `tests/{test,bench}_tf_sharpen.py`, `docs/f-reference/f_tf_sharpen.md`, plus the menu/
  inventory rows above. No directory rename is needed if done before live shipping.
- **Dial mapping gate (spec OQ1) PROVISIONAL-OPEN:** one-sided linear 0–4, default 1.0
  shipped in definition.py + codebox comment.
- **Tier-2 cost gate PROVISIONAL-OPEN:** per-pass cost unmeasured (bench never run).
  Cost model vs tensormap's published floors (~0.9 ms per pass at 1080p, R_MAX 16):
  sharpen has no loop and one texture read — expected at or under the tensormap
  single-pass floor, i.e. ~0.9 ms upper bound at 1080p. Resolving experiment:
  `bc.measure(code(), [rand(1080,1920)], chain=8)` in `tests/bench_tf_sharpen.py`
  (add a `test_cost` when the gate is exercised).

---

## Generated artifact paths (for the parent's drift/contract checks)

- definition.py: `.specify/f_tf_sharpen/definition.py`
- built (this module ran it, from `/Users/matt/Github/f_/`):
  `python3 build/build_patcher.py .specify/f_tf_sharpen/definition.py`
  → `package/patchers/f_tf_sharpen.maxpat` (written; `json.load` VALID)
- codebox: `.specify/f_tf_sharpen/codebox_sharpen.gen`
- tests: `tests/test_tf_sharpen.py` (tier 1, green 15/15), `tests/bench_tf_sharpen.py`
  (tier 2, written, never executed)
- reference doc: `docs/f-reference/f_tf_sharpen.md` (Status: Draft)