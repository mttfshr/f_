---
name: max-patch-notation
description: Consistent notation system for describing Max/MSP patches to build by hand. Use whenever Claude is helping design, describe, or document a Max or Vsynth patch — including new patches, debugging sessions, and handoff notes. Prevents referential drift (switching between object names, concept labels, and class names) that makes patch descriptions ambiguous. Load at the start of any Max patching session.
---

# Max Patch Notation

A minimal, unambiguous notation for describing Max/MSP patches built by hand.

## The Core Rule

Every object gets **one canonical label**, established at definition, used exclusively
for the rest of the description. Never switch to the class name, a concept label,
or any synonym mid-description.

---

## Object Definition Format

```
[class arg arg @attr val] // label
[class @name label]
```

- Square brackets wrap the object exactly as typed in Max's object box
- Label after `//` is canonical name when the object doesn't support `@name`
- If the object supports `@name`, use it — doubles as the Max scripting name
- Arguments precede attributes; attributes use `@key val` syntax

**Examples:**
```
[jit.noise 1 64 64] // sirds_noise
[jit.gl.pix @name sirds_pix]
[jit.gl.node @name sirds_depth @adapt 1]
[jit.gl.gridshape @drawto sirds_depth @shape sphere] // sirds_shape
[metro 30] // sirds_metro
[loadbang] // sirds_boot
```


---

## Connection Format

```
label outN → label inN
```

- Always 0-indexed integers
- Always explicit — never "left outlet", "first inlet", "outlet 1"
- One connection per line

**Examples:**
```
sirds_noise out0 → sirds_pix in0
sirds_depth out0 → sirds_pix in1
sirds_metro out0 → sirds_depth in0
sirds_pix out0 → cornerpins in0
```

For a message or number box sending to an object:
```
[0.15] // period_msg  →  sirds_pix in0
```

---

## Embedded Code (codebox, js, gen~)

Use a fenced block immediately after the object definition:

```
[jit.gl.pix @name sirds_pix]
codebox:
  Param period(0.15);
  Param depth_scale(0.05);
  uv = norm;
  depth = sample(in2, uv).r;
  shift = depth * depth_scale;
  tiled_x = mod(uv.x - shift, period) / period;
  out1 = sample(in1, vec(tiled_x, uv.y));
```

---

## Patch Description Structure

A complete patch description has three sections in this order:

### 1. Objects
List every object with its definition. Group loosely by function with a blank line
between groups, but don't rely on order to imply connection — connections are explicit.

### 2. Connections
List every connection. One per line. Complete — don't omit "obvious" ones.

### 3. Notes (optional)
Parameter ranges, debugging observations, known issues, next steps.
No object references by class name or concept — label only.


---

## Worked Example

A minimal SIRDS patch using this notation:

### Objects

```
; timing
[loadbang] // sirds_boot
[metro 30] // sirds_metro

; texture source
[jit.noise 1 64 64] // sirds_noise

; depth map (offscreen GL context)
[jit.gl.node @name sirds_depth @adapt 1]
[jit.gl.gridshape @drawto sirds_depth @shape sphere @scale 0.7 0.7 0.7] // sirds_shape

; SIRDS shader
[jit.gl.pix @name sirds_pix]
codebox:
  Param period(0.15);
  Param depth_scale(0.05);
  uv = norm;
  depth = sample(in2, uv).r;
  shift = depth * depth_scale;
  tiled_x = mod(uv.x - shift, period) / period;
  out1 = sample(in1, vec(tiled_x, uv.y));
```

### Connections

```
sirds_boot out0  →  sirds_metro in0
sirds_metro out0 →  sirds_noise in0
sirds_metro out0 →  sirds_depth in0
sirds_noise out0 →  sirds_pix in0
sirds_depth out0 →  sirds_pix in1
sirds_pix out0   →  cornerpins in0
```

### Notes

- `sirds_shape` draws into `sirds_depth` context via `@drawto` — no patch cord needed
- `period` range: 0.01–0.5 (sweet spot 0.1–0.2)
- `depth_scale` range: 0.01–0.2 (too high distorts tiling)
- `cornerpins` connects into existing Vsynth `vs_output`

---

## bpatcher and Multi-File Patches

When a patch spans multiple files (e.g. a bpatcher with its own source file), declare the file boundary explicitly:

```
[bpatcher @patcher f_hue_processor.maxpat @name hp] // hp
; file: /Users/matt/Github/f_/patchers/f_hue_processor.maxpat
; in0: texture input
; in1: named control messages (sat_amt, bypass, hue_shift, ...)
; out0: texture output
```

- The `; file:` comment gives the absolute path to the source
- `; inN:` / `; outN:` document the bpatcher's public interface
- Internal objects inside the bpatcher are described in a separate patch description for that file — not inline here
- When referencing a bpatcher in connections, use its label only: `hp out0 → next_module in0`

For `[p subpatcher]` (inline, no separate file), no `; file:` line is needed — just label it and describe its internals inline if relevant.

---

## Discipline Reminders (for Claude)

- Once a label is assigned, use it and only it — forever
- Never say "the noise object", "the pix", "the depth map node" — use the label
- Never say "outlet 1" or "left outlet" — always `out0`, `out1`, etc.
- Inlet/outlet indices are always 0-based integers
- If uncertain which inlet/outlet: say so explicitly rather than guessing
- For bpatchers: document the public interface (ins/outs), not the internals, at the call site
