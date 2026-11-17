# src/f_a_purr

`codebox.gen` is the gen~ codebox of `f_a_purr` and a build input of `definition.py`
(`archetype: "audio_gen"`, audio archetype Phase B, 2026-11-16). **`src/` is now the master:**
edit here, rebuild with `build/py.sh build/build_patcher.py src/f_a_purr/definition.py`. Before 2026-11-16 the
scratch patch `/Users/matt/Vsynth/patterns/f_a_purr_scratch.maxpat` was the master; it and the copies in
`scratch/experiments/f_a_purr_*` are now older than this file.

History: extracted verbatim 2026-11-03 from the scratch patch (box `obj-100`, 2706 chars, sha256 prefix
`4a5121062755f6a7`), then extended here with T025 (`breath_src`, `breath_src_ms`, external phase on `in1`),
the realism pass (T035-T038) and T039 / T040 (`ph_*`, `run_*`). Before the Phase B edits: 6419 chars, 176 lines,
sha256 prefix `c8d11f24bc19135d` (git `HEAD` before the Phase B commit). None of the 2026-11-03/04 code had been
compiled or heard in Max when the module was built from it.

Phase B edits (2026-11-16, `.specify/f_a_purr/tasks.md` T041), and only these:
1. Defaults set to the T011 by-ear preset: `rate_jit` 0.05, `amp_jit` 0.05, `decay_ms` 3.7, `decay_jit` 0.6,
   `res_hz` 215.5, `res_q` 0.9919, `breath_hz` 0.32, `breath_skew` 0.79, `breath_rate_mod` 0.464, `breath_noise` 0.15.
2. `Param gain(0.3)` and a `tanh` ceiling on `out1`; `Param bypass_gate(0.0)` as a ~5 ms slewed mute of `out1`.
   `out2` (breath phase) is not gained or muted. `gain` is a guess, not measured; not heard.
The DSP is untouched. The dial ranges are in `definition.py` (spec table, except `decay_jit` 0-0.9 and `res_hz` 20-400).

Spec and tasks: `.specify/f_a_purr/`. Idea file: `ideas/f_a_purr.md`.
