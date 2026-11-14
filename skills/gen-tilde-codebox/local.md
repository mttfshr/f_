# gen-tilde-codebox: f_ notes

Project-specific additions to `SKILL.md`. Not part of the shared skill.

## Context

gen~ codeboxes in this repo belong to the `f_a_` audio-domain modules
(`f_a_purr`, `f_a_ripple`). Most of the project's codebox experience is on
the GPU side (`jit.gl.pix`, see `skills/jit-gen-codebox/`), which is why the
"don't import GPU rules wholesale" warning matters here.

## Conventions

- One-shot triggers and controls reach the codebox the house way: a
  `prepend <paramname>` into the single gen~ control inlet, matched to a
  `Param` by name (used throughout `f_a_ripple` T2-T6). One-shot trigger
  Params are named `trig` (established in `f_a_ripple`'s T4 scratch patch).
- Related project skills not yet shared: `pfft-spectral-processing` (the
  working pfft~ control-value pattern, buffer~/index~/peek~; supersedes
  gen~-inside-pfft~) and `max-patch-notation` (describing patches in chat).

## Provenance

- `noise()` valid in gen~, the `in`-object requirement for Params, the
  `latch` deadlock, the read-History-into-a-local rule, and the `code`-key
  finding: `f_a_purr` (first `f_a_` audio module), 2026-07-27; context in
  `.specify/f_a_purr/plan.md`. Originally filed in jit-gen-codebox and moved
  here 2026-09-29 when the two copies of that skill were reconciled.
  The `code`-key case: `_build_purr_scratch.py` wrote `text` and was flagged
  stale/unsafe to run rather than re-fixed (the full entry now lives in
  maxpat-json-authoring).
- `Param reset` collision: 2026-08-05, found in `f_a_ripple` scratch work.
- `Data` / `poke` / `peek` and the one-shot gate (2048 x 200 render):
  `f_a_ripple` T3, 2026-08-05.
- Freezing time (the 8 s `smr_cycle`) and the `trigger` logging pattern:
  `f_a_ripple` T4 (between T3 on 2026-08-05 and T7a on 2026-08-07; exact
  date not recorded).
- Multi-inlet `in1`...`inN` and `pfft~` needing a file on disk: `f_a_ripple`
  T7a, 2026-08-07 (`t7a_inner.maxpat`).
- Testing lessons: low frequencies (T3 phase-accumulator debugging), rate by
  eye (T4), flonum readout vs console log (T4 and T7a).
- Metering objects (`scope~` blank above ~200 Hz, `peakamp~` linear):
  `f_a_ripple` wavetable-size check, 2026-09-16.
- `noise()` + time-gate randomization: `f_a_ripple` v1 production build,
  2026-09-16; replaced T5/T6's external `random` draws for `q`/`p`.
