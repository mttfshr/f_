# f_texrouter — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

4×4 texture routing matrix with a preset system. Routes up to 4 input textures to up to 4 output slots via a 16-cell matrix (cells 0–15). Presets allow named configurations to be stored and recalled. Bypass semantics differ from processor bpatchers: bypass = freeze (hold last routed frame), not pass-through.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bang` | bang | Trigger preset recall or matrix update |
| `0`–`15` | int/float | Matrix cell values — 16 cells of the 4×4 routing grid |

## Signal Chain

```
textures in (up to 4) → routing matrix (16-cell, 4×4)
                      → textures out (up to 4)
```

Routing driven by matrix cell messages `0`–`15`. Preset system stores/recalls full matrix states.

## Bypass Semantics

**bypass = freeze**, not pass-through. When bypassed, the last routed frame is held. This differs from all other f_ bpatchers where bypass passes the input through unmodified. Document this clearly in the help patch.

## Loose Threads

- **Bypass semantics undocumented** — needs a note in the help patch clarifying freeze vs pass-through behavior.
- No help patch exists yet.

## Source File

`patchers/f_texrouter.maxpat`

## Reference

`vs_texrouter_SPEC.md` in repo root — original spec document.
