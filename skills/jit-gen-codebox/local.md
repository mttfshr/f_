# jit-gen-codebox: f_ notes

Project-specific additions to `SKILL.md` and `references/`. Not part of the
shared skill.

## Context

Codeboxes here live in f_ Vsynth bpatchers, verified against the Vsynth
`vsynth` GL context. Full early test results (the operator sweep):
`.specify/codebox.skill/tasks.md`. In a Vsynth chain `dim` works for aspect
because the first inlet carries a render-sized texture (upstream, or
`vs_black`). Codebox `in 1` carrying both bang and first texture contradicts
what some Vsynth source comments imply (verified by observation, 2026-06-06).

## The test bench (what "bench" means in the shared files)

- Codebox bench: `tests/bench.sh -q <file>`, `benchclient.run_pass()`; check
  a codebox under development with it before declaring it working. Module
  bench: `tests/contracts/bench_modules.py` (instantiates the shipped patcher
  as Max does; the only one that sees a compile-error passthrough). Authoring
  rules: `skills/bench-test-authoring/`. Bench docs: `.specify/test_bench/`.
- **Don't write `outN` in a codebox comment** (hard error, 2026-10-07): the
  codebox bench sizes the codebox from the `outN` tokens in its text,
  comments included. A one-output codebox whose comment said "(the second
  outlet of caustic_pix is out2)" was built with two outputs and failed with
  `codebox: patchcord outlet out of range: deleting patchcord`. Same for `inN`
  if a stage's input count is read from the text. (Found verifying
  `f_caustic`'s select stages.)
- **The bench keeps a `Param`'s last value between jobs** (2026-09-28): a job
  that omits a Param inherits the previous job's value, not the codebox
  default. Pin every Param a measurement depends on (a cost test silently
  measured taps=16 after a loop that ended on 16).
- **Wedge after a compile failure:** every later job returns a STALE image
  with no error until `benchclient.reopen()`; probe with
  `tests/lib/benchclient.ensure_healthy` before trusting results (2026-10-06;
  2026-10-25 it also failed 7 unrelated legs until the next run).
- **Codebox bench cost floor:** an empty `out1 = in1` pass measures about
  2.1-2.5 ms per frame (CPU overhead), so `measure` readings below that are
  upper bounds, not costs.
- **Module bench `period_ms`** (`caustic_runner.py`/`cr.period_ms`, real
  `vs_render` context; 2026-10-08, `tests/records/spike_caustic_res_cost.py`,
  `.specify/f_caustic_scatter/tasks.md` T046): vsync-locked at `cr.CAP_MS`
  (~16.7 ms). A module cheaper than that reads ~16.7 ms regardless; readings
  that all cluster there mean "all cheaper than the floor", not "no effect":
  push inputs until they clear it. A single sample is noisy (up to ~2x run to
  run), and the first job after `cr.ensure_bench()` reopens is unreliable: take
  3+ samples and use the median.

## Conventions

- Bypass on multi-outlet modules: `param bypass_gate 1`, native attribute off.
- Module-bound pix names are prefixed `#0_`; the shipped multi-stage modules
  did this all along, and single-pix definitions must too. The module bench
  exercises it by keeping a live instance while instantiating fresh ones.
- Prefilter taps that need to stay reachable: keep a route token and no panel
  slot (`"ui": False` in `f_vf_fluid`'s `definition.py`).
- Check a definition's control tokens against jit.gl.pix's attributes before
  the first build.
- Tensor consumers: bias at the source (`atan2(y, x + 1e-7)`); see
  `docs/f-reference/f_tensor_type.md` rules 5-6 and `.specify/f_tf_glyph/plan.md`
  ADR-2 amendment. `f_tensormap`'s stage C survives flat content with
  `mix(NaN, 0.5, iso_dir)` and stays as-is (verified and live-checked);
  `f_tf_glyph`'s `mix(NaN, 0.0, flag)` did not clear. Every new consumer uses
  the bias idiom.

## Provenance

- `mod()` banding: `mod_test.maxpat` scratch patch, 2026-07-09.
- `atan2` accuracy: `tests/records/spike_atan2_safety.py` (vecfield decode),
  2026-10-12.
- `boundmode` and the seam: `tests/records/bench_boundmode_probes.py` B1/B2,
  `tests/logs/20261114-141112-bench.log`; earlier probes P2/P6/P7/P9 in
  `bench_mirror_findings_probes.py` (2026-10-20); the `atan2(0, 0)` counter
  observation is probe P5 of the same set.
- Ring-offset `uv.x` failure and the edge-band artifact: `f_vf_repulse`,
  2026-06-21.
- Unconnected inlet: `f_caustic`'s sheets composite (treats a vecfield exactly
  0 in R and G at four fixed points as absent; real vecfields encode 0 as 0.5).
- `inN` and `active` collisions, for-loop scope: `f_apollonian` generalized
  ring work, 2026-07-08 (`any_inside`, `active`).
- `Param mix`: `f_vf_advect`, 2026-07-12.
- `Param t`: `f_formconstants` T046, 2026-10-24 (frame counter renamed
  `frameno`). Attribute collisions: `f_formconstants` (`depth`) and `f_wc`
  (`texture`), 2026-10-24.
- `Param shape`: `f_halftone`, 2026-11-14 (renamed `dot_shape`; the Shape rows
  pass per `tests/logs/20261114-081815-bench.log`, per the docs).
- `exp(-(a + b))`: `f_vf_erode`, 2026-11-10, `tests/logs/20261110-105232-bench.log`.
- `PI = ...`: `f_stereo`, 2026-10-04 (20 contract-test issues; fixed as
  `pi_val`; caught by the per-module contract test).
- Component assignment and the Möbius building blocks: `f_apollonian` /
  `f_poincare` (derivation in their `plan.md`), 2026-07-08/09.
- Gate vs silhouette: `f_vf_seeds` hue/color Evolution 3, 2026-07-22.
- `vec4` accumulation: `f_lens` ghost images, 2026-07-15
  (`effect_out * warm_shift * vignette` was the multiplication precedent).
- Per-row modulation: masonry-style patterns (`f_masonry`).
- Bench facts 2026-09-22: `tests/**/bench_*.py`; E1-E4 the same day. Native
  `@bypass`: module bench 2026-09-23, seen on 11 shipped modules. Unary-minus:
  bench control probe 2026-09-23.
- Minify and fixed-`dim` resampling, nested Param loops: `f_vf_fluid` force
  taps, 2026-09-28/29.
- Jumpy-coordinate sampling, statement budget, functions, `require`, `step`
  literals: caustic gather/scatter spike, 2026-10-06 (`ideas/optics_map.md`,
  "Findings: multi-guess gather").
- `atan2` NaN, `nearest()` units, compile-error passthrough, ob3d names:
  glyph/aniso tensor consumers, 2026-10-17
  (`tests/modules/tf_glyph/bench_tf_glyph.py`,
  `tests/modules/tf_aniso_blur/bench_tf_aniso_blur.py`); the passthrough was a
  live session the same day; the ob3d example was `sharpen_pix`.
- Corner taps and the 256-tap overflow: `f_formconstants` block-mean attempt,
  2026-10-25 (`tests/logs/fc_t075_mean1.npz`, `.specify/f_formconstants/tasks.md`
  T075).
- `dim` follows the first input, large-argument trig, shader cost, uniform
  branch: `f_quasi` codebox bench, 2026-10-26.
- Call-site overflow and the sin-hash mismatch: `f_halftone`, 2026-11-14
  (codebox bench 19/19 after the fix).
