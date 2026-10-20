# f_ngon — tasks

_Created by the 2026-10-12 maintenance pass: README's ⚠ "Unfinished,
not yet confirmed or documented" is accurate — the module ships in
package/patchers/ and regenerated identically 2026-09-24 (build_layout
T012, the one module of 33 that did), but has no spec, no
verification, and five open design questions in ideas/f_ngon.md.
Ids start at T001._

- [ ] T001: Decide f_ngon's fate: write a spec answering the five open
  pre-spec questions in ideas/f_ngon.md (mask-vs-kaleidoscope output,
  iteration-count scaling with n_mirrors, radius/rotation UX, plus the
  fold convergence criterion) and either clear the README ⚠ (confirm +
  document) or demote the module. The 32-iteration fold loop is
  unmeasured and untested on GPU; a NumPy mirror can verify the
  2·n_mirrors-gon output and convergence at n_mirrors=18 (closed-form
  fold math, directly mirrorable) — fold into this task or T002.
- [x] T002: Tier-1 NumPy mirror test for the fold (see T001): verify
  output polygon vertex count and convergence behavior against the
  codebox math.
  **Done: tier-1 NumPy mirror (omp run mirror-build-3, landed 2026-10-20).** `tests/modules/ngon/{ngon_mirror,test_ngon}.py`, 10/10 offline. Checks: reflection isometry (radius preserved), the folded angle against the closed form (phi mod 2*theta), the full-turn identity, output range. The neutral setting is not a passthrough (the fold symmetrizes the frame). Grounded in `ideas/f_ngon.md` (the module has no reference doc). See `HANDOFF.md` 2026-10-20.