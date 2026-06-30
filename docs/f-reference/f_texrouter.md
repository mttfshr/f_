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

---

## Implementation Notes

Non-obvious behaviors worth knowing if modifying the patch:

**Fan-out**: Multiple open gates on the same row (e.g. in0 → out1 and in0 → out2 both open) sends the same texture to two outlets. Intentional and correct — `jit_gl_texture` is a message, the same texture name fans out cleanly.

**Fan-in**: Multiple open gates on the same column (e.g. in0 → out1 and in1 → out1 both open) means two sources both send to out1. Last message in scheduler order wins on the GL side. The matrix doesn't enforce single-source per outlet — that's the patch designer's responsibility.

**pattrstorage + autopattr coexistence**: `router_autopattr` handles save/restore of full bpatcher state (including dirty toggle edits). `router_pattrstorage` handles the named preset bank. Both coexist cleanly — autopattr saves raw toggle values, pattrstorage saves named snapshots.

**Preset recall timing**: pattrstorage recall sets live.toggle parameter values which immediately output to their gates. Glitch-free because `jit_gl_texture` is message-domain, not audio-domain.

**cell_val ordering is safe by construction**: `unpack` fires right-to-left — V always reaches `cell_val` before R triggers the index calculation. Ordering is deterministic in Max's single-threaded scheduler.

**Preset slot 0**: Ships pre-stored as identity (diagonal). After any rebuild, recall identity state then send `store 0` to `router_pattrstorage` to restore this.
