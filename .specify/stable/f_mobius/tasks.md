# Tasks: f_mobius

_Last updated: 2026-05-26_

## Phase 0 — Codebox

- [x] T001: Write codebox code (params, identity path, inversion path, blend, fract wrap, bypass)
- [x] T002: Paste into scratch patch; verify passthrough — `invert=0, rotate=0, zoom=0.5` → pixel-perfect
- [x] T003: Verify inversion — `invert=1, cx=0.5, cy=0.5` → inside-out, center expands
- [x] T004: Verify rotation — `invert=0, rotate=0.25` → 90° rotation of sampling coordinates
- [x] T005: Verify singularity guard — `invert=1, cx=0.5, cy=0.5`, cursor near center — no NaN / no frozen band

## Phase 1 — Bpatcher Wrapper

- [x] T006: Write Python build script for f_mobius.maxpat
- [x] T007: Run script; open patch in Max; verify no load errors
- [x] T008: Confirm signal flow — texture in → pix → texture out
- [x] T009: Confirm all 6 params respond (cx, cy, rotate, zoom, invert, bypass)
- [ ] T010: Confirm autopattr present; state saves and restores with parent patch
- [ ] T011: Confirm moduleSize.js chain fires on load
- [x] T012: Load in Vsynth signal chain; verify no context errors

## Phase 2 — Performance Validation

- [ ] T013: Drive cx/cy via xy encoder (named messages on in1) — confirm routing works
- [x] T014: Tune zoom range empirically — settled on pow(10, (zoom-0.5) * 5.0)
- [x] T015: Explore loxodromic territory — invert 0.2–0.8 + rotate; behavior understood
- [ ] T016: Compose with f_droste — verify both orders work, no artifacts

## Phase 3 — Documentation

- [ ] T017: Write docs/f_mobius.md (as-built: params, signal chain, usage, known behaviors)
- [x] T018: Update README.md — status to ✅ Working
- [ ] T019: Update HANDOFF.md
