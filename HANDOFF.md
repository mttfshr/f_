# f_ — Handoff

_Session: 2026-05-27_

## What was done this session

**f_stereo complete (all phases):**
- T009–T020 verified in Max (confirmed by Matt at session start)
- docs/f_stereo.md written — params, signal chain, rotation model, known behaviors
- README updated: f_stereo added to patches table as ✅ Working; build queue updated
- Key verified behaviors:
  - lon sweep: smooth continuous rotation, no 0/1 discontinuity
  - lat sweep: pole tilts correctly toward/away from viewer
  - spin: fully independent roll
  - proj: 0 = orthographic, 1 = stereographic; outside 0–1 expressive but uncontrolled
  - Circular mask: works correctly in Vsynth context (square output assumed)
  - xy encoder routing on in1: working
  - Composition with f_grain, f_chladni, f_mobius: no context errors

**Display chain discoveries (documented in docs/f_stereo.md):**
- Full display chain: `source → [vs_flipy → vs_poltocar →] f_stereo → vs_fisheye → output`
- Fisheye post-processing significantly improves spherical illusion — narrows FOV so both poles aren't visible simultaneously
- Prep chain for radially symmetric sources: `source → vs_flipy → vs_poltocar → f_stereo` — aligns source center with viewing pole. Verified with f_chladni.

**`circ` toggle added post-completion:**
- `live.text` mode selector showing "circle" / "full" — matches Vsynth UI convention (Displacement module pattern)
- circle = mask on (circular output), full = unmasked rectangle (back hemisphere visible in corners)
- Distinct from bypass which removes the projection entirely
- Key lesson: jsui objects with `param_connect` must appear before the gen object in the boxes array — if created after, Max crashes on open (mutex not initialized at setvalueof time)

## First thing next session

Two options:
1. Return to **f_chladni** — T018/T019 (mic test, tuning toggle) still pending
2. Begin **f_poincare** spec — now next in build queue after f_stereo

## Loose threads

- **f_stereo**: Ghost image artifact — faint blob behind sphere when sweeping lat/lon. Likely alpha bleed at mask edge or singularity contribution. Not yet diagnosed.
- **f_stereo**: proj outside 0–1 range — expressive but uncontrolled; may scale back in future revision
- **f_mobius T010**: autopattr state save/restore not verified
- **f_mobius T011**: moduleSize.js chain not verified
- **f_mobius T013**: cx/cy via xy encoder not tested
- **f_mobius T016**: composition with f_droste not tested
- **f_mobius docs**: `docs/f_mobius.md` not written yet
- **f_chladni T018/T019**: mic test and tuning toggle test still pending
- **f_chladni loadbang**: coefficients don't load automatically on patch open — workaround is clicking umenu
