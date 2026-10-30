# Tasks: f_tf_hatch (v2 — streamline renderer)

**Spec**: `.specify/f_tf_hatch/spec.md`   **Plan**: `.specify/f_tf_hatch/plan.md`
**Reference doc**: `docs/f-reference/f_tf_hatch.md`   **Findings**: `findings_2026-10-29.md`
**Archived v1**: `spec_v1.md`, `plan_v1.md`, `tasks_v1.md` (the 2026-10-28 reset, commit `35ca14a`, renamed
`tasks.md` to `tasks_v1.md`; there was no v2 `tasks.md` until this file, written 2026-10-30 from the HANDOFF
entries and the git log, so the commit hashes below are the record).
**Test discipline**: as CLAUDE.md. The one affected test, `-q`; ask before any bench run (Max +
`tests/bench/bench.maxpat`; Vsynth paused for a cost reading).
**Verification now**: tier 1 `tests/run.sh -q tests/modules/tf_hatch/test_tf_hatch.py` 24/24; tier 2
`tests/bench.sh tests/modules/tf_hatch/bench_tf_hatch.py` 13/13 (2026-10-30); drift, contracts and `test_render_dim` green.

---

## Phase 0 — Mirror + synthetic tests (DONE 2026-10-28)

- [x] T001 LIC mirror and synthetic coherence tests, gate passed 10/10 (`eacc7bb`). OQ1 provisionally decided.
- [x] T002 Sparse impulse input noise reads as hatching; test 9 (`231e652`).

## Phase 1 — GPU cost spike (DONE 2026-10-28)

- [x] T010 N = 16 nearest taps, one pass: E2 1.7 ms at 1080p (`77f61ea`). Decided OQ2 (`unsigned_nearest`) and OQ3's N.

## Phase 2 — Production codeboxes + bench (DONE 2026-10-28/29)

- [x] T020 Codeboxes E1 / E2 / E3 and the rewritten bench (`02a9374`); bench 6/6, E2 1.78 ms, module 3.24 ms (`bb53748`).
- [x] T021 `definition.py` rewritten, patcher rebuilt (`5a46afb`).
- [x] T022 Sin-free lattice hash, GPU `sin` loses precision at 1080p cell indices (`b262008`); bench tests for GPU `hash13` and the partial-coherence march (`c141cbb`).

## Phase 3 — Live judgment and the fixes it forced (2026-10-29 onward)

- [x] T030 First live look: axis-aligned rectangles, not strokes (`1085698`, `findings_2026-10-29.md`). The mirror at the same settings drew strokes, so the defect was GPU / pipeline / real tensor.
- [x] T031 E2 noise rebuilt as band-limited BLOBS; the Strength dial removed; tier 1 13/13, bench 10/10, cost 4.61 ms (`7548844`).
- [x] T032 ROOT CAUSE: live `dim` reads about 1 in `jit.gl.pix`, so E2's position clamp pinned every step to the frame centre. Fixed with the new builder key `render_dim` and a static guard test (`89359a9`, `37f8886`). Hatch now renders at the render size.
- [x] T033 Optional stroke-texture inlet (E2 in2, `src_stroke` gate): Grain = zoom, Density = a soft luma threshold (`af7d4ce` mirror, `34ea65c` codebox, `9907a70` bench). Cost probes: the cost is texture footprint x tiling stride (`9e26273`, `d9c914f`).
- [x] T034 Low-coherence look. Spike of Clouds / Dark / Terminate (`e1dcabe`), then the Coh Floor dial: strokes end where coherence drops and the pixel fades (`e687707` mirror, `ad2f086` codebox + definition). Matt chose BLACK over the pixel's own dot (`4f96789`); GPU parity bench (`21102dd`). Default 0 is bit-for-bit the old look. **Matt's live look passed 2026-10-30.**
- [x] T035 Texture PRE-STAGE (2026-10-30): a separable box downsample to render size / 4 on each axis ahead of E2, fixed factor 4, aspect follows the render (Matt switches between 16:9 and 1:1).
  - Spike: accurate to 1e-7, E2 13.0 to 5.3 ms (`81d58d4`; mipmap route skipped, see Decisions).
  - Mirror and tier-1 tests 19-22 (`f410365`).
  - Codeboxes `pre_h` / `pre_v`, the opt-in builder group `render_dim.downsample`, definition, patcher; builder tests +3 (`2d0d0fa`).
  - Bench 13/13: GPU = mirror with 0.0 error (16:9, 1:1, 250x150); E2 12.18 to 5.01 ms; module in texture mode about 7.4 ms (conservative), gate 8 ms (proposed; Matt has not confirmed it); docs updated (`742e9db`).

## Phase 4 — Definition, build, drift, contracts (DONE, kept green through every change above)

- [x] T040 `drift -v f_tf_hatch` ok, drift 16/16, `test_module_contracts` 9/9 (`ow` / `oh` count as driven), `test_render_dim` 8/8, `test_benchdeps` 23/23.

## Phase 5 — Docs and registration

- [x] T050 Reference doc rewritten for v2 (`0a9daa7`); README row describes v2, launcher regenerated, `test_launch` 8/8 (`b4ce9b1`); pre-stage cost and design in the doc (`742e9db`).
- [ ] T051 README ⚠ Unverified marker: kept (Matt did not say to drop it). Decide after the pre-stage live look.
- [ ] T052 Helpfile `package/help/f_tf_hatch.maxhelp` is the v1 one (last committed 2026-10-17). It needs the v2 controls (Strength is gone; Coh Floor, Density as blobs, the optional texture inlet and its pre-stage). Written in a Claude session per CLAUDE.md, with the `f-helpfile` skill; Matt checks it in Max.

---

## Open

- [x] T060 **Matt's live look at the pre-stage PASSED 2026-10-30 (09:40)**: a texture connected to a fresh Hatch instance works through the two-stage path. (Not reported either way: Density with per-pixel-noise textures, which lose contrast x0.25 in the reduction; smooth textures do not, x0.87-0.98.)
- [ ] T061 Confirm or change the 8 ms texture-mode cost gate (bench floor and 8-bit Vsynth textures are not modelled: untestable on the bench).
- [ ] T062 (2 of 4 done offline 2026-10-30: `f_tf_tensormap` (live look passed) and `f_tf_glyph`; then `f_tf_aniso_blur`, `f_tf_axisflow`, which Matt added) **Migrate `f_tf_tensormap`, `f_tf_glyph`, `f_tf_aniso_blur` to `render_dim`** (their Width / Height dials become `render_dim`; the tensor then renders at the render size, so cost and what Radius means change: bench each). Needed because Hatch now follows the render size while the tensor modules do not. **Decided (Matt, 2026-10-30): the Width and Height dials are REMOVED** (they become internal params driven by `render_dim`); the affected files are listed in the HANDOFF entry of 2026-10-30 09:45. **Also decided: each module's output follows the render size** (`render_dim` `size_stages`, every stage `@adapt 0`, as Hatch's does).
- [ ] T063 The six exempt modules read `dim` (latent live bug; list in `tests/build/test_render_dim.py`): `f_cmap` (paused), `f_grain`, `f_masonry`, `f_quasi`, `f_vf_seeds`, `f_vf_vorticity`. Not Hatch's work; tracked here because Hatch found it.
- [ ] T064 Housekeeping: the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail (Strength was removed in T031); `package/examples/f_demo_hatch.maxpat` is untracked and has `strength[1]` bindings: check it loads.
- [ ] T065 Tier-3 questions not recorded as decided (spec Open Questions): OQ1 real coherence (mostly 0.1-0.7) at exponent 0.5; OQ3 kernel shape (box vs cosine); OQ4 is outlet 1 used; OQ6 dense LIC as a mode; OQ7 fanning strokes at mid coherence (Coh Floor changes the low end; the cone is not addressed).

## Decisions (Matt unless noted)

- 2026-10-28: reset to a streamline (LIC) renderer; v1 archived. `unsigned_nearest` aux; N = 16, one pass; coherence mixes into the march direction, exponent 0.5 (provisional).
- 2026-10-29: Strength dial removed; sparse impulses are band-limited blobs; Hatch takes the render size from Vsynth (`render_dim`), so the whole chain renders at the render size, not the tensor's.
- 2026-10-29: the stroke texture was accepted as a heavy optional mode (option C), then SUPERSEDED by the pre-stage on 2026-10-30.
- 2026-10-29/30: Coh Floor (E2, dial, default 0 = off) fades undirected regions to BLACK; it gates by DIRECTION where Floor gates by structure STRENGTH (Floor separates flat sensor noise from structure better; Coh Floor is for strong but directionless clutter such as foliage and corners).
- 2026-10-30: pre-stage inside Hatch, not a standalone downsample / mipmap module (the box filter is accurate and nearly free; a mipmap route would need a new `job.setup` hook in `tests/bench/bench.js`); the factor is fixed at 4; the size follows the render so the aspect is never fixed.
