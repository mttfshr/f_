# Plan: maintenance (prioritizing the remaining library)

**Date:** 2026-10-09
**Spec:** this workstream has no separate spec.md — see `SKILL.md`'s
"Why this exists" for the goal, `tasks.md` for the live queue.

This is a point-in-time prioritization of every shipped module not yet
audited, derived from README's Patches table (39 shipped modules total).
Unlike `SKILL.md`'s selection algorithm — which is meant to be re-run live
and never hardcodes names — this document is a snapshot: a reasoned
ordering across the *whole* remaining set, done once, so each future
session isn't re-deriving the big picture from scratch. If the shipped
module list changes materially (new module ships, `f_caustic` settles),
re-derive rather than patch this file piecemeal.

## Accounting

- **Audited (9):** `f_grain`, `f_vf_advect`, `f_masonry`, `f_sirds`,
  `f_vf_vorticity`, `f_vf_warp`, `f_vf_seeds`, `f_vf_fieldmap`,
  `f_vf_repulse`.
- **Excluded (5):** `f_caustic` (active development — see HANDOFF, don't
  audit a moving target); `f_modules`, `f_texrouter` (confirmed dead,
  Matt 2026-10-09), `f_util_matrix_2`, `f_util_profile` (all `out_of_scope`
  in `drift_baseline.json` — not expressible in the schema or deliberately
  unfinished-draft).
- **Remaining (25):** grouped below, Tier A highest priority.

## Tier A — heavy bypass-cost modules (4)

The six modules HANDOFF names as having lost "bypass skips the shader"
GPU savings in the 2026-09/10 rollout, minus `f_grain` (done) and
`f_caustic` (excluded, active). Direct hit on the stated #1 priority.

- `f_vf_glow` — field-aligned directional blur, accumulates along
  streamlines; same shape of cost concern as `f_vf_streak`.
- `f_vf_prism` — vecfield-driven prism separation, composite/isolated
  outlets.
- `f_vf_streak` — directional blur via vecfield, composite/isolated
  outlets.
- `f_vf_chroma` — chromatic aberration along field direction,
  composite/isolated outlets. (Currently in `paused/` — check why before
  assuming it's simply next in line; may belong with paused modules
  instead of this tier if there's an unresolved reason it's there.)

## Tier B — other Param-bypass modules, same oversight risk (3)

`f_masonry`'s audit found it was `bypass_mode: "param"` but never named
among HANDOFF's heavy six — an apparent oversight, not a deliberate
exclusion. These three are in the same rollout but also never
individually assessed for the cost question; worth checking whether
they're actually lightweight (likely, for at least two of these) or just
as overlooked as `f_masonry` was.

- `f_chladni` — Chladni plate modal synthesis visualizer; has an audio
  companion patch (`f_chladni_audio`, Tier G).
- `f_stipple` — 2D hash field stipple texture; architecturally simple,
  probably low cost, but unconfirmed.
- `f_vf_split` — splits a vecfield's X/Y channels to two outlets; trivial
  math, almost certainly a non-issue, include mainly for completeness.

**Flag before starting Tier A:** `f_vf_chroma` has a `.specify/paused/`
folder but no ⚠ in README and no visible reason recorded in HANDOFF/plan.md
for why it's paused while shipping normally — same shape of doc/reality
gap this whole pass keeps finding elsewhere. Worth 5 minutes figuring out
why before auditing it normally, in case "paused" means something a
plain perf/bench/convention pass would miss.

## Tier C — README ⚠, visual (1)

- `f_ngon` — "Unfinished... not yet confirmed or documented." The one
  remaining non-audio ⚠ module.

## Tier D — foundational or architecturally complex (5)

Not flagged by any mechanical criterion, but worth prioritizing over
Tier F: either many other modules depend on them (so a bug here
propagates widely) or they're complex/stateful enough that drift or
quiet breakage is more likely.

- `f_vf_vortex`, `f_vf_vortex_multi` — the two vecfield generators
  nearly everything else in the ∇ family is typically demonstrated or
  tested against; foundational.
- `f_vf_fluid` — "incompressible-flow solver... evolving velocity field
  out" per README; stateful, same risk category as `f_vf_advect`.
- `f_vf_optical_flow` — Lucas-Kanade from source motion, confidence-gated
  with aperture-problem fill; per project memory, "Phase 6
  (registration/docs) complete, stage E shipped and verified" — complex
  enough that a maintenance pass checking it against *current* tooling
  (not just its own completion state) seems worthwhile.
- `f_weave` — grouped with the already-audited discrete-item family
  (`f_grain`/`f_vf_seeds`/`f_masonry`) in `technical-notes.md`; same risk
  profile, never audited.

## Tier E — known issue, not yet formalized (1)

- `f_hue_processor` — project memory already records a `hue_lower`/
  `hue_upper` UI bug. Auditing this one is partly just making sure that
  known bug actually lands as a real task in its own `tasks.md` rather
  than staying folklore.

## Tier F — remaining, lower architectural risk (9)

Generic 2D processors/generators with no specific flag. Lowest priority
among visual modules, roughly interchangeable order within the tier.

`f_droste`, `f_mobius`, `f_stereo`, `f_lens`, `f_channel_grader`,
`f_luma_processor`, `f_tone_curve`, `f_vf_potential`, `f_vf_flow`.

## Tier G — audio / `gen~`, different domain (2)

No GPU-cost angle at all (no `jit.gl.pix`), so the perf axis barely
applies; still worth a bench/convention pass eventually for completeness.

- `f_a_ripple` — ⚠ Unfinished. "DSP done, UI and docs pending."
- `f_chladni_audio` — ⚠ Unverified. "No reference doc."
