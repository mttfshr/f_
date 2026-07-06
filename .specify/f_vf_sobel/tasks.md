# f_vf_sobel — Tasks

## Phase 1: Codebox verification

- [ ] T01 — Write Sobel codebox (Gx+Gy, luma, dim-derived step, vecfield encoding)
- [ ] T02 — Open scratch patch: masonry → jit.gl.pix (sobel codebox) → preview
- [ ] T03 — Verify full ring field around blobs (not half-ring)
- [ ] T04 — Verify flat regions output neutral (R≈0.5, G≈0.5)
- [ ] T05 — Verify strength sign convention: positive = repulsion direction
- [ ] T06 — Wire vs_filter_lp4x downstream, confirm smooth field spread, no encoding artifacts
- [ ] T07 — Wire f_vf_advect downstream, confirm fluid motion away from shape boundaries

## Phase 2: definition.py + build

- [ ] T08 — Write .specify/f_vf_sobel/definition.py from confirmed codebox
- [ ] T09 — Run build_patcher.py → patchers/f_vf_sobel.maxpat
- [ ] T10 — Validate JSON: python3 -c "import json; json.load(open('patchers/f_vf_sobel.maxpat'))"
- [ ] T11 — Open in Max, confirm patcher loads and renders correctly
- [ ] T12 — Run audit_interface.py, resolve any warnings

## Phase 3: Integration + registration

- [ ] T13 — Wire full recipe in scratch patch: masonry → f_vf_sobel → vs_filter_lp4x → f_vf_advect
- [ ] T14 — Confirm performative character: fluid motion from shape boundaries, fields interact across multiple masonry blobs
- [ ] T15 — Add to f_modules.maxpat (Vecfield category) via build_modules.py
- [ ] T16 — Add to f_addmod.js SIZES dict
- [ ] T17 — Update README.md patch table
- [ ] T18 — Commit
