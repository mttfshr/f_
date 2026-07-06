# Tasks: f_chladni Refactor

_Last updated: 2026-06-17_
**Spec**: `.specify/f_chladni/spec.md`
**Plan**: `.specify/f_chladni/plan.md`

> Previous tasks (T001–T034) are superseded by the 2026-06-17 reframe.
> Completed work retained: rename (T001–T005), ph0 fix (T006–T008), view_mode verification (T029–T030).
> Audio companion patch (T009–T019) and EEG companion patch (T020–T028) are superseded — companion patch interface changes from 8 amplitudes to note + amp.

---

## Phase 0: Scratch Patch

- [ ] T100 Create scratch patch `~/Vsynth/patterns/chladni_scratch.maxpat` with `jit.gl.pix`, `note` and `amp` float params, `dishradius`/`reflectamt`/`linesharpness` params, luma out
- [ ] T101 Implement Mode A codebox: map `note` linearly across Bessel zero span (z0=2.4048–z7=11.0864); blend between two adjacent modes
- [ ] T102 Implement Mode B codebox: resonance snap — compute distance from `note` to each Bessel zero; weight modes by falloff curve (Gaussian or 1/d²); `spread` param controls falloff width
- [ ] T103 Evaluate Mode A in Max: does pattern transition feel smooth and useful, or visualizer-like?
- [ ] T104 Evaluate Mode B in Max: does pattern snap feel sculptural? What `spread` value feels right?
- [ ] T105 Determine preferred MIDI range: which octave span gives expressive mode navigation?
- [ ] T106 Write `.specify/f_chladni/scratch_notes.md`: record observations, preferred behavior, MIDI range, whether `spread` param is worth keeping

**Checkpoint**: Written notes exist. Mode selection behavior decided. MIDI range decided. Proceed to Phase 1.

---

## Phase 1: Definition Rewrite

- [ ] T107 Rewrite `.specify/f_chladni/definition.py`:
  - Params: `note` (float, 0–127), `amp` (float, 0–1), `dishradius`, `reflectamt`, `linesharpness`, `view_mode`, `ph0`, optional `spread`, `bypass`
  - Two outlets: `{"comment": "luma"}`, `{"comment": "vecfield", "signal_type": "float32"}`
  - `pix_type: "float32"` (required for vecfield outlet)
- [ ] T108 Write codebox implementing chosen mode selection behavior from scratch patch
- [ ] T109 Add vecfield gradient computation: evaluate `total` at `norm + epsilon` offsets; central difference → gx, gy; encode as f_vecfield (RG, 0.5=zero)
- [ ] T110 Calibrate `epsilon` for gradient: should resolve mode-scale features without aliasing (start ~0.004, same as fieldmap default)

**Checkpoint**: definition.py complete; codebox reviewed; ready to build.

---

## Phase 2: Build + Verify

- [ ] T111 Run `tools/py.sh tools/build_patcher.py .specify/f_chladni/definition.py`
- [ ] T112 Open `patchers/f_chladni.maxpat` in Max; verify loads without errors
- [ ] T113 Test `note` param: sweep 0–127; confirm pattern reorganizes across modes
- [ ] T114 Test `amp` param: sweep 0–1; confirm output scales correctly
- [ ] T115 Test `ph0`: confirm global phase shift visible across all modes
- [ ] T116 Test `view_mode`: confirm circular ↔ strip blend smooth
- [ ] T117 Run `tools/py.sh tools/audit_interface.py patchers/f_chladni.maxpat`; resolve any issues

**Checkpoint**: Bpatcher verified in Max. Audit passing. Both outlets present.

---

## Phase 3: Vecfield Outlet Verification

- [ ] T118 Route f_chladni out2 → f_caustic; confirm caustic accumulation at nodal lines
- [ ] T119 Route f_chladni out2 → f_vf_warp with source texture; confirm warp toward nodal lines
- [ ] T120 Route f_chladni out2 → f_vf_glow; confirm glow organized along nodal geometry
- [ ] T121 Document signal chain recipes in `docs/f_chladni.md`

**Checkpoint**: Vecfield outlet verified with at least two consumers. Recipes documented.

---

## Phase 4: Companion Patches

- [ ] T122 Design audio→note mapping: sigmund~ pitch output → MIDI note scaling; document approach
- [ ] T123 Create `patchers/f_chladni_audio.maxpat`: sigmund~ or pitch follower → `note`; peakamp~ → slide~ → `amp`; master gain; outlet contract `note <int>` / `amp <float>`
- [ ] T124 Test audio companion with mic: note input tracks pitch; amp responds to dynamics; figure animates sculpturally
- [ ] T125 Design EEG→note mapping: decide between weighted centroid and highest-amplitude band; document reasoning
- [ ] T126 Create `patchers/f_chladni_eeg.maxpat`: Muse OSC → note + amp; line smoothing ~150ms; outlet contract matches audio companion
- [ ] T127 Test EEG companion with Muse: smooth animation; no 10Hz stepping visible

**Checkpoint**: Both companion patches working. Outlet contracts consistent.

---

## Phase 5: Docs + Registration

- [ ] T128 Update `docs/f_chladni.md`: new architecture, params, signal chain, outlet contract, recipes
- [ ] T129 Verify f_modules registration is correct (signal_type may have changed)
- [ ] T130 Update README.md description if needed
- [ ] T131 Commit all changes in logical units
- [ ] T132 Update `HANDOFF.md`

**Checkpoint**: Docs consistent with as-built state. Build complete.
