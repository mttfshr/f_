# f_vf_dilate — Tasks

## Phase 1: Codebox + feedback architecture

- [ ] T01 — Study f_vf_advect patcher: understand how textureset feedback is wired (texture naming, pass count, bang routing)
- [ ] T02 — Write dilation codebox: sample current pixel + 4 neighbors, adopt highest-magnitude non-neutral neighbor
- [ ] T03 — Scratch patch: single pass dilation — verify edge vectors spread by 1 pixel
- [ ] T04 — Add feedback loop (textureset): verify N passes = N pixel spread
- [ ] T05 — Wire reach param to pass count — verify reach=0 is pass-through, reach=16 spreads 16px
- [ ] T06 — Verify neutral regions stay neutral where no neighbor has signal
- [ ] T07 — Verify direction preservation: spread vectors maintain original edge direction, not distorted
- [ ] T08 — Test on non-sobel input: vortex field → dilate → confirm spread works
- [ ] T09 — Wire f_vf_advect downstream: confirm fluid motion extends beyond edge boundary

## Phase 2: definition.py + build

- [ ] T10 — Write .specify/f_vf_dilate/definition.py from confirmed codebox + architecture
- [ ] T11 — Run build_patcher.py → patchers/f_vf_dilate.maxpat
- [ ] T12 — Validate JSON
- [ ] T13 — Open in Max, confirm loads and renders correctly
- [ ] T14 — Run audit_interface.py, resolve warnings

## Phase 3: Integration + registration

- [ ] T15 — Full recipe test: masonry → f_vf_sobel (scratch) → f_vf_dilate → f_vf_advect
- [ ] T16 — Add to f_modules.maxpat (Vecfield category)
- [ ] T17 — Add to f_addmod.js SIZES dict
- [ ] T18 — Update README.md
- [ ] T19 — Commit

## Blocked

- f_vf_repulse — blocked until f_vf_dilate complete
