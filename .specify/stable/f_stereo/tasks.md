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

---

## Maintenance (2026-10-12 audit)

- [ ] T024: Run the existing Tissot-indicatrix diagnostic
  (tests/records/spike_mobius_vecfield_transform.py /
  tests/records/spike_droste_conformality.py are the precedents) against
  f_stereo — the only warper of the three with a non-conformal end of
  its blend, so the only one where the indicatrix is actually
  interesting (expect the ellipse→circle sweep as proj blends
  ortho↔stereo). ideas/f_tensorfield.md:320 flags this as never run.
  Filed in place per the stable/ rule above (single investigation
  task; move the folder if it grows).

- [x] T025 **Tier-1 NumPy mirror (omp run mirror-build-2, landed 2026-10-20).** `tests/modules/stereo/{stereo_mirror,test_stereo}.py`, 14/14 offline. Checks: projection closed forms (Tissot), the asin domain exits, bypass. Tier-2 (probe P1, run 2026-10-20, `tests/records/bench_mirror_findings_probes.py`): on an odd texture the exact-centre texel is finite on the GPU, RGBA (0.985, 0.985, 0, 1), where the mirror gives (0.5, 0.985, 0, 1): not black, but an edge-column value (probe P5 then showed a bare atan2(0,0) from arithmetic zeros is +pi, finite, not NaN; probe P6 showed exactly u = 1.0 and u = 0 both read the first texel; together these do not yet explain the centre value, which is unresolved). The mirror folds atan2(0,0) to 0, so it disagrees at that one texel (odd sizes only). Away from it the worst GPU-vs-mirror difference is 0.0151. See `HANDOFF.md` 2026-10-20.
