# HANDOFF — f_ session 2026-06-09 (end of session)

## What was done this session

### Build system generalization (6e44863, 11bec32)
- `outlets` key and `vs_instate: False` added to build_patcher.py
- f_caustic and f_vf_streak definition.py written; per-module build scripts retired

### Temporal synthesis discovery (3ca76e6)
- Pattern 1 (chained pix feedback) documented in `docs/temporal_synthesis_architecture.md`

### f_vf_advect — full build cycle complete (2cf67af, d26d943)
- Spec, plan, tasks written
- Codebox verified in scratch patch (`~/Vsynth/patterns/advect_scratch.maxpat`)
- build_advect.py written, patcher built and validated
- All Phase 3 acceptance criteria passed
- Param ranges tuned from integration testing:
  - dt: 0–0.05 (default 0.01)
  - decay: 0.8–1.5 (default 0.97) — >1.0 = excitable/amplifying mode
  - injection: 0–0.2 (default 0.02)
  - mix: 0–1.5 (default 1.0)
- README, f_modules menu, f_addmod.js updated

**Key expressive finding:** decay > 1.0 is a qualitatively different operating mode —
content amplifies rather than dissipates. Best sources: f_grain, f_caustic (isotropic texture).
Best fields: f_vf_fieldmap (organic), f_vf_vortex_multi (structured).

---

## Priorities for next session

Reading order: plan.md → HANDOFF.md

1. **build_patcher.py multi-pix extension** — design schema for multi-pix bpatchers so
   f_vf_advect can get a definition.py and build_advect.py can be retired. f_cymascope
   (3 pix) will stress-test the design.
2. **f_cymascope spec** — now unblocked; Pattern 1 extended (3 pix, 2 historical frames).
3. **f_poincare spec** — fully independent; good alternative if geometry feels more
   appealing than implementation work.

---

## Loose threads

- f_mobius performance gap — needs use before deciding if params need extending
- Color theming via Max styles — worth establishing before module count grows further  
- Reaction-diffusion → f_vf_fieldmap → f_caustic — signal chain experiment
- f_poincare presentation region — f_vf_scalar masking is the natural mechanism
- f_chladni audio companion loadbang-in-bpatcher init reliability
