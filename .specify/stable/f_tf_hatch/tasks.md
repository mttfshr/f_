# Tasks: f_tf_hatch (v2 — streamline renderer)

**Spec**: `.specify/stable/f_tf_hatch/spec.md`   **Plan**: `.specify/stable/f_tf_hatch/plan.md`
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
- [x] T051 README ⚠ Unverified marker DROPPED (Matt, 2026-10-31, after the passed pre-stage live look); launcher regenerated.
- [x] T052 v2 helpfile `package/help/f_tf_hatch.maxhelp` WRITTEN 2026-10-31 (title Hatch, nine controls, comment-only wiring like v1, new References; `docs/f-reference/f_tf_hatch.md` References line added). Matt checked it in Max 2026-10-31: looks good.

---

## Open

- [x] T060 **Matt's live look at the pre-stage PASSED 2026-10-30 (09:40)**: a texture connected to a fresh Hatch instance works through the two-stage path. (Not reported either way: Density with per-pixel-noise textures, which lose contrast x0.25 in the reduction; smooth textures do not, x0.87-0.98.)
- [x] T061 8 ms texture-mode cost gate KEPT as is (Matt, 2026-10-31; bench floor and 8-bit Vsynth textures are not modelled: untestable on the bench).
- [x] T062 (DONE offline 2026-10-30, 4 of 4: `f_tf_tensormap` and `f_tf_glyph` (live looks passed), `f_tf_aniso_blur`, and `f_tf_axisflow`, which Matt added; live look at aniso_blur and axisflow still owed) **Migrate `f_tf_tensormap`, `f_tf_glyph`, `f_tf_aniso_blur` to `render_dim`** (their Width / Height dials become `render_dim`; the tensor then renders at the render size, so cost and what Radius means change: bench each). Needed because Hatch now follows the render size while the tensor modules do not. **Decided (Matt, 2026-10-30): the Width and Height dials are REMOVED** (they become internal params driven by `render_dim`); the affected files are listed in the HANDOFF entry of 2026-10-30 09:45. **Also decided: each module's output follows the render size** (`render_dim` `size_stages`, every stage `@adapt 0`, as Hatch's does).
- [x] T063 (closed 2026-10-30/31: grain, quasi, seeds, vorticity migrated; `f_masonry` and `f_cmap` stay exempt) The six exempt modules read `dim` (latent live bug; list in `tests/build/test_render_dim.py`): `f_cmap` (paused), `f_grain`, `f_masonry`, `f_quasi`, `f_vf_seeds`, `f_vf_vorticity`. Not Hatch's work; tracked here because Hatch found it.
- [x] T064 (closed 2026-11-06, Matt: archive; the three scripts below and `dial_effects.py`, which imports them, are in `spike/retired/` with a README) Housekeeping. DONE 2026-10-31: `package/examples/f_demo_hatch.maxpat` is tracked and consistent: its Hatch bpatcher has exactly the eight v2 bindings (reach to coh_floor); the `strength[1]` bindings belong to its `f_tf_tensormap` (obj-7), whose Strength dial is valid, so nothing was removed (the earlier note was a false alarm). Not tested: that it loads cleanly in Max. OPEN: the spike scripts `camera_like.py` and `lic_stills*.py` still pass `strength=` and fail (Strength was removed in T031).
- [x] T065 Tier-3 questions DECIDED 2026-10-31 (Matt, as leaned): OQ1 keep exponent 0.5, no `persist` dial, Coh Floor is the lever; OQ3 box kernel, cosine deferred until a look asks; OQ4 keep outlet 1, documented in the helpfile; OQ6 dense LIC dropped as a mode (the stroke-texture inlet at Density 1 covers it); OQ7 fanning cone deferred (reads as direction uncertain). OQ5 moot.
- [x] T066 Hub Q17 (NaN masking in E1 on isotropic tensors) PROBED 2026-11-01: `.specify/stable/f_tf_hatch/spike/bench_e1_nan_probe.py`, 5/5, zero NaN/inf in every case (exact zero, isotropic nonzero at 16/64/256, mixed texture, one ulp from isotropic); log `tests/logs/20261101-082451-bench.log`. The `+1e-7` bias was NOT adopted. Not tested: a live Vsynth render. Matt decided 2026-11-01: no permanent bench rows and no live check; the spike is the record.

- [x] T067 Stable preflight (2026-11-06, offline by Claude), record below.
- [x] T068 Matt's helpfile look PASSED 2026-11-06: the new demo chain at defaults, the digest, and the bypass toggle (black on the preview). Moved to `.specify/stable/`.

## Stable preflight (2026-11-06)

Part 1 offline by Claude: drift ok, no baseline entry; menu and launcher `--check` up to date; README row 110 chars or under, no ⚠; bypass is `bypass_gate` on stage e3, and the contract bench asserts black, A = 1 on both outlets (`tests/contracts/bench_modules.py`; `bench_modules.py` 2/2 in `tests/logs/20261106-081412-bench.log`, from before these edits, which touch only a comment there); helpfile box 191x152 against a footprint of 190.5x150; `test_generate_menu.py` 17/17 after the helpfile edit (`tests/logs/20261106-083730-offline.log`). No gate row holds Hatch. No code changed, so `bench_tf_hatch.py` was not re-run: 13/13 rests on commit `742e9db`; no log of that run is in `tests/logs/` (the latest there, `tf_hatch_bench_2026-10-30b.out`, is 12/12, before the pre-stage bench).

Fixed: v1 wording survived in `module-inventory.md` (both rows: distance-field dashes, mark mask, one inlet), `f_tensor_type.md`, `f_tf_sharpen.md` and `library-characteristics.md` (~6 taps, strokes vs dots, the outlet names). The reference doc had old test counts, a chain diagram without the pre-stage, "three stages" for render size, and a `dim` note listing six modules where two remain. The spec still said no v2 code exists, listed `strength`, and had neither the stroke inlet nor `coh_floor`. Comments only in `definition.py` (said width/height are not needed; a misplaced render-size note; 1.8 ms) and `bench_modules.py`; drift still ok.

Helpfile: no source was wired, so the demo drew nothing. Added `vs_sources_main` -> `f_tf_tensormap` outlet 0 -> Hatch -> preview. The digest now says what the module is for (spec: making coherence visible), and the inlet comment says `f_tf_smooth` belongs between them on moving sources (not in the demo). Live by Matt: T068.

## Moved to stable/ (2026-11-06)

Matt's helpfile look passed ("Look passes, move it"), so the module moved. Live path references were updated, and the spike scripts' root paths went one level deeper; the v1 records, `findings_2026-10-29.md` and `REGISTRATION_NOTES.md` keep the old path. Optional cost and the provisional dial defaults carry over per the stable bar. `tests/build/test_gates.py` 5/5 after the move (Matt's go; log `tests/logs/20261106-084140-offline.log`).

## Decisions (Matt unless noted)

- 2026-10-28: reset to a streamline (LIC) renderer; v1 archived. `unsigned_nearest` aux; N = 16, one pass; coherence mixes into the march direction, exponent 0.5 (provisional).
- 2026-10-29: Strength dial removed; sparse impulses are band-limited blobs; Hatch takes the render size from Vsynth (`render_dim`), so the whole chain renders at the render size, not the tensor's.
- 2026-10-29: the stroke texture was accepted as a heavy optional mode (option C), then SUPERSEDED by the pre-stage on 2026-10-30.
- 2026-10-29/30: Coh Floor (E2, dial, default 0 = off) fades undirected regions to BLACK; it gates by DIRECTION where Floor gates by structure STRENGTH (Floor separates flat sensor noise from structure better; Coh Floor is for strong but directionless clutter such as foliage and corners).
- 2026-10-30: pre-stage inside Hatch, not a standalone downsample / mipmap module (the box filter is accurate and nearly free; a mipmap route would need a new `job.setup` hook in `tests/bench/bench.js`); the factor is fixed at 4; the size follows the render so the aspect is never fixed.
