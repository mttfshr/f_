# src/f_a_purr

`codebox.gen` is the gen~ codebox of `f_a_purr`, extracted verbatim on 2026-11-03
from `/Users/matt/Vsynth/patterns/f_a_purr_scratch.maxpat` (box `obj-100`, key `code`,
file last modified 2026-07-29). 2706 chars, sha256 prefix `4a5121062755f6a7`.

2026-11-03, later: T025 (`breath_src`, `breath_src_ms`, external phase on `in1`) was
applied here and to a copy of the patch, `/Users/matt/Vsynth/patterns/f_a_purr_scratch_t025.maxpat`,
so this file is currently AHEAD of the master scratch patch until that copy is
heard in Max and promoted.

Status: a source of record, not yet a build input. There is no `definition.py`, and
`build/build_patcher.py` cannot generate `f_a_` modules (`G-audio`, tasks.md T026).
The scratch patch is still hand-built. Until a build path exists, the scratch patch is
the master (Matt, 2026-11-03): a codebox change is made and heard in Max, then copied
here, and the commit message says so. Nothing checks that the two agree.

The only `.gen` file here; no test reads it except `tests/build/test_render_dim.py`,
which scans `src/*/*.gen` for the word `dim` (this codebox has none).

Spec and tasks: `.specify/f_a_purr/`. Idea file: `ideas/f_a_purr.md`.
