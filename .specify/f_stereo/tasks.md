# Tasks: f_stereo

_Last updated: 2026-05-26_

## Phase 0 — Codebox

- [x] T001: Write codebox — UV → inverse projection → sphere → rotate (inlined R matrix) → equirectangular sample → mask → bypass
- [x] T002: Verify passthrough — `lon=0.5, lat=0.5, spin=0` → stable centered projection; radially symmetric texture appears symmetric
- [x] T003: Verify lon sweep — content rotates like globe on stand, no discontinuity
- [x] T004: Verify lat tilt — content tilts; pole moves toward/away from viewer
- [x] T005: Verify LFO on lon — smooth continuous rotation, no jump at 0/1 boundary
- [x] T006: Verify singularity guard — pole-facing values stable, no NaN, no crash

**Architecture changes discovered during Phase 0:**
- Rotation order changed to R = Rz(spin) × Ry(lon) × Rx(lat) — globe model
- Angle mappings: lon_a = (lon-0.5)*TWO_PI, lat_a = (lat-0.5)*PI, spin_a = spin*TWO_PI
- Forward stereographic replaced with equirectangular sampling (atan2/asin)
- `proj` parameter added: blends orthographic (0) ↔ stereographic (1), range −2 to 2
  - Orthographic = natural globe feel, edges foreshortened
  - Stereographic = conformal, edges expanded
  - Outside 0–1 = extended distortion effects, discovered to be a rich performance parameter

## Phase 1 — Bpatcher Wrapper

- [x] T007: Write Python build script for patchers/f_stereo.maxpat (5 params: lon, lat, spin, proj, bypass)
- [x] T008: Run script; patch written without errors
- [ ] T009: Open patch in Max; verify no load errors
- [ ] T010: Confirm signal flow — texture in → pix → texture out
- [ ] T011: Confirm all 5 params respond (lon, lat, spin, proj, bypass)
- [ ] T012: Confirm autopattr present; state saves and restores with parent patch
- [ ] T013: Confirm moduleSize.js chain fires on load
- [ ] T014: Load in Vsynth signal chain; verify no context errors

## Phase 2 — Performance Validation

- [ ] T015: Drive lon/lat via xy encoder (named float messages on in1) — confirm routing works
- [ ] T016: LFO on lon at 0.05 Hz — confirm smooth continuous rotation (primary use case)
- [ ] T017: Explore proj range — document landmark values (−2, −1, 0, 1, 2)
- [ ] T018: Compose with f_grain upstream — no context errors, projection visible
- [ ] T019: Compose with f_chladni upstream — Bessel modes on sphere
- [ ] T020: Verify aspect ratio — check if circular mask is elliptical in actual Vsynth context

## Phase 3 — Documentation

- [ ] T021: Write docs/f_stereo.md (as-built: params, signal chain, usage, known behaviors)
- [ ] T022: Update README.md — status to ✅ Working
- [ ] T023: Update HANDOFF.md
