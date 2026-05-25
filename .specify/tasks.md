# f_ — Task Tracker

_Last updated: 2026-05-25_

Cross-session task list. One item per line. Reorder freely — top = highest priority.
Spec for all planned work lives in `.specify/spec.md`.

---

## Active: f_chladni Signal Chain

- [ ] **Scope review** — conversational, no files needed; decide taxonomy, prioritize optics family vs f_cymascope vs f_chladni loose threads; informs plate morphing decision
- [ ] **f_chladni: patcher file rename** — open `patchers/f_cymascope.maxpat` in Max, File → Save As `f_chladni.maxpat`; update `docs/f_chladni.md`, `package-info.json`, `README.md`
- [ ] **f_chladni: ph0 decision** — repurpose as global phase offset (preferred) or hide from UI; update codebox and docs
- [ ] **f_chladni: audio signal chain** — build bandpass bank (8 filters at modal freq ratios) → peakamp~ → slide~ → m0–m7 in a companion patch
- [ ] **f_chladni: EEG signal chain** — udpreceive → band routing → scale → line/slide~ → m0–m7; calibrate Muse raw value range first
- [ ] **f_chladni: view_mode blend** — test circular↔strip blend with live signal chain once audio path is working

## Up Next

- [ ] **f_cymascope: feasibility check** — can jit.gl.pix read/write feedback texture at Vsynth render tempo without frame-order issues? Answer before committing to build
- [ ] **Help patches** — start with f_texrouter (bypass=freeze must be documented), then f_droste, then f_chladni
- [ ] **f_chladni: near-center singularity** — decide epsilon floor vs accept; low priority, do after signal chain is working
- [ ] **f_chladni: plate shape morphing** — hold until scope review; significant GLSL change, may not be worth it

## Backlog

- [ ] **Optics family** — scope review first; then f_lens/f_aberration (review prior session work), f_caustic, f_flare, f_diffraction; see spec.md
- [ ] **Apollonian fractal** — GLSL approach TBD; see ideas/scratchpad.md
- [ ] **Non-Euclidean geometry** — hyperbolic tiling / Möbius transforms; see ideas/scratchpad.md
- [ ] **f_hue_processor: hue_lower / hue_upper remote control** — on hold; revisit if remote control needed in performance
- [ ] **README: update patch table** — add f_chladni (rename from f_cymascope listing)

---

## Done (recent)

- [x] Repo migration — docs/, ideas/ directories created; bpatcher specs moved from .specify/bpatchers/
- [x] spec.md written — all planned work consolidated from docs/, ideas/, tasks.md, HANDOFF.md
- [x] f_chladni vs f_cymascope clarification — separate specs, distinct physics
- [x] vsynth-bpatcher skill updated — package structure and bpatcher lifecycle
- [x] .specify/ scaffold — constitution, all 8 bpatcher stubs
- [x] f_chladni initial build (as f_cymascope) — Bessel mode visualizer, 8 modal amps, confirmed working visually
