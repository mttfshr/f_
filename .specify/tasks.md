# f_ — Task Tracker

_Last updated: 2026-05-25_

Cross-session task list. One item per line. Reorder freely — top = highest priority.

## Next Session: Repo Reorganization (do first)

- [ ] **Migrate .specify/bpatchers/ → docs/** — working bpatchers only (f_droste, f_grain, f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve, f_texrouter); strip planning content, keep as-built reference
- [ ] **Migrate .specify/bpatchers/f_chladni.md → docs/** — it's working (signal chain pending but the bpatcher itself is working)
- [ ] **Migrate .specify/bpatchers/f_cymascope.md → ideas/f_cymascope.md** — not yet built
- [ ] **Migrate .specify/ideas.md → ideas/scratchpad.md** — rename and move
- [ ] **Delete .specify/bpatchers/** — once migration is confirmed
- [ ] **Write spec.md** — planned work only: f_chladni signal chain first
- [ ] **Derive plan.md and rewrite tasks.md** from spec.md

## In Progress

- [ ] **f_chladni: rename patcher file** — rename `patchers/f_cymascope.maxpat` → `f_chladni.maxpat` in Max and update any references
- [ ] **f_chladni: audio signal chain** — bandpass bank (8 filters at modal freq ratios) → peakamp~ → smooth → m0–m7 amp inputs
- [ ] **f_chladni: Muse OSC routing** — udpreceive → band routing → scale → line/slide~ smooth → m0–m7

## Up Next

- [ ] **Scope review** — step back and review overall package direction: generative bpatchers (f_chladni, f_cymascope) vs image processors (grader, hue, luma, tone); what's the arc? Feeds into f_chladni plate morphing decision and f_cymascope feasibility assessment
- [ ] **f_cymascope: feasibility check** — confirm ping-pong texture / FDTD wave propagation is viable in jit.gl.pix within Vsynth context before committing to build
- [ ] **f_chladni: ph0 dead param** — cos(0·θ + ph0) = constant; repurpose as global phase offset or hide
- [ ] **f_chladni: near-center singularity** — sqrt(2/πr) diverges at origin; decide whether to address or leave as characteristic artifact
- [ ] **f_chladni: plate shape morphing** — pending scope review; circular (Bessel) → rectangular (sine products) morph param
- [ ] **Help patches** — none of the bpatchers have .maxhelp files yet; start with most-used
- [ ] **f_texrouter: bypass semantics** — document bypass = freeze (not pass-through) in help patch

## Backlog

- [ ] **f_cymascope: build** — FDTD wave propagation in GLSL, fluid medium, pitch-driven source; see spec
- [ ] **f_hue_processor: hue_lower / hue_upper remote control** — rslider params excluded from route; revisit if needed
- [ ] **README: add f_chladni** — update patch table (was listed as f_cymascope)
- [ ] **f_chladni: view_mode blend** — 0=circular, 1=unwrapped strip; blendable but not tested with live signal chain

## Done (recent)

- [x] `f_chladni` initial build (as f_cymascope) — Bessel mode visualizer, 8 modal amps, confirmed working visually
- [x] vsynth-bpatcher skill updated — patterns/patchers distinction, codebox-first workflow, template from f_droste
- [x] `.specify/` scaffold — constitution, tasks, all 8 bpatcher stubs
- [x] Clarified f_chladni vs f_cymascope distinction — renamed accordingly, separate specs
