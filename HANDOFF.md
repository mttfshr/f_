# HANDOFF — f_ session 2026-06-03 (evening)

## Status
f_masonry modulation sampling architecture fixed and working. Commit pending.

---

## What was done this session

### f_masonry: brick-space modulation sampling

**Problem identified:** A and B were sampling in screen space (`norm.x`, `norm.y`), not masonry structure space. This caused:
- Offset modulation having no effect on course 0 (band_idx=0 → band_idx * offset_eff = 0)
- Other params modulating in screen-space gradients rather than brick-space patterns
- The original per-course/per-brick articulation was designed for 1×N profile textures — with full 2D textures the distinction belongs in what texture you connect, not how you sample

**Architecture settled:**
- A and B both sample at the same brick-UV: `vec(wrap(slot/bond_scale, 0,1), wrap(band_idx/course_scale, 0,1))`
- Two independent mod lanes, distinction is in the texture patched to each inlet
- Geometry block moved before sampling so brick-UV coords are available

**Offset special case:**
- `offset_shift` computed from per-course UV `vec(0.5, band_idx/course_scale)` — no along component
- Avoids circularity: offset shifts the slot used for sampling, so sampling can't depend on the shifted slot
- `along_shifted = along + offset_shift / bond_scale` applied before all slot/along_cont computation
- Whole course slides as a unit — gaps and bricks together, no stripe artifacts

**Stripe artifact root cause and fix:**
- Artifact appeared at slot boundaries when offset_shift was in along_cont but not in slot
- Or when preliminary slot (for UV) and rendering slot were out of sync
- Fix: per-course offset sampling breaks the circularity entirely — preliminary slot stays unshifted, along_shifted carries the shift into both slot and along_cont together

---

## Known issues / loose threads

- **Other mod params not audited** for structural issues — likely fine since none multiply by band_idx the way offset does, but worth a pass
- **Offset samples at x=0.5** — horizontal texture variation ignored for offset modulation. Per-column offset variation not possible with current approach. Acceptable for now.
- **`f_masonry` pix still named `weave_pix`** — pre-existing, low priority
- **`autopattr varname` error on load** — pre-existing, not introduced this session

---

## Next session

- Audit remaining mod params for structural issues
- f_util_profile Phase 1 (T001–T008) — scratch patch, GPU→CPU→GPU round trip
- f_chladni signal chain

---

## Files changed this session
- `patchers/f_masonry.maxpat` — brick-space modulation sampling, offset special case, geometry reorder
