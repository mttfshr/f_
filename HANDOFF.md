# HANDOFF — f_ session 2026-06-05

## Status
f_grain fixed (processor mode working). Codebox skill written from empirical test data. E2E testing plan written. Cache clear script added. Ready for e2e testing phase.

---

## What was done this session

### f_grain: fixed
- vs_inState wiring was broken (obj-44 / prepend param src_mode was wired to wrong inlet)
- Added `r draw` receiver to drive pix when no texture connected
- Removed `param_connect` / `parameter_enable` from bypass_toggle.js jsui (latent crash risk)
- Dual-mode (no-input) behavior attempted but not resolved — deferred, noted in scratchpad
- **Grain now works correctly as a processor** (requires incoming texture)

### jit-gen-codebox skill
- Ran 45 operator verification tests in scratch.maxpat against jit.gl.pix GPU path
- Key findings that correct prior assumptions:
  - `fract()` and `sqrt()` ARE valid — prior workaround notes were wrong
  - `noise()` silently outputs black (most dangerous — compiles, no error, no output)
  - Component access on stored variables (`col.x` after `col = sample(...)`) silently fails — inline access on sample() return value works (`sample(in1, uv).x`)
  - `boundmode` in GenExpr syntax silently ignored — use `fract()` on coord instead
  - `swiz` silently fails on GPU path
  - `cell` and `band` are NOT reserved words — they shadow operators silently
  - `dim` returns pixel dimensions (e.g. 640×480), not normalized values
- Skill written to `/Users/matt/Github/claude-scaffold/skills/jit-gen-codebox/SKILL.md`
- vsynth-bpatcher skill updated to reference jit-gen-codebox and correct outdated info

### E2E testing plan
- Written to `.specify/e2e-testing/tasks.md`
- Covers 11 working patchers + cross-cutting checks + build script backfill
- 7 test dimensions per patcher: load/crash, code health, functional output, Vsynth chain integration, presentation layout, edit mode layout, build script cross-check

### Cache clear script
- `tools/clear_max_cache.sh` — clears Max 9 Database/ cache
- Checks Max is closed, skips Ableton/lock files, asks confirmation
- Run with `./tools/clear_max_cache.sh` from repo root

---

## Known issues / loose threads

### f_grain dual-mode (no-input)
- `r draw` + `vs_inState` + `src_mode` gray fallback all in place but dim uniform flickering, no grain visible
- Needs dedicated debugging session
- Grain works fine as processor — not a blocker

### f_masonry unresolved
- `aspect` uses `dim` which returns context pixel dimensions (640×480) — works by coincidence in square context but wrong
- C inlet (in4) wiring still unverified
- AA hardcoded to `px_norm = 1.0/640.0`
- All captured in e2e tasks

### @type char missing
- f_mobius, f_grain, f_lens, f_stipple, f_masonry, f_chladni all missing `@type char`
- Tracked in e2e cross-cutting checks

### scratch.maxpat
- Needed `@drawto vsynth` on jit.gl.pix and render trigger — now correctly set up
- Located at `/Users/matt/Vsynth/patterns/scratch.maxpat`

---

## Next session
Start e2e testing. Begin with f_grain (fresh in mind, known issues to document). Run A/B/C checks, layout audit, create definition.py.
