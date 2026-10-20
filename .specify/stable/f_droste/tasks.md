# Tasks: f_droste

**Status**: Working bpatcher — minor fix only, no spec or plan needed.

---

- [x] T001 Open `patchers/f_droste.maxpat` in Max; add `autopattr @varname droste_autopattr` to the patcher (matches convention in all other f_ bpatchers)
- [x] T002 Save and verify bpatcher still loads correctly in Vsynth; confirm no regression
- [x] T003 Update `docs/f_droste.md` — remove "None known" from Loose Threads; note autopattr added

- [x] T004 **Tier-1 NumPy mirror (omp run mirror-build-1, landed 2026-10-19).** `tests/modules/droste/{droste_mirror,test_droste}.py`, 11/11 offline. Checks: the zoom-step self-map, arm folding, fract() no-ops, palette containment, bypass. The full-frame coordinate check re-derives the shear algebra in float64 (codebox-dependent, labeled in its docstring). See `HANDOFF.md` 2026-10-19.
