# Patcher anatomy

The objects inside a shipped f_ bpatcher and how they connect: signal flow, the pix, its gen subpatcher and codebox, the moduleSize chain, styling and the `parameters` block. Part of the vsynth-bpatcher skill; the builder writes all of this from `definition.py`, so read it to understand or check a patcher, not to hand-build one.

## Signal Flow (Full Detail)

```
bpatcher in0 (texture + ctrl)
  → routepass jit_gl_texture jit_matrix
      outlet 0 (jit_gl_texture match) → [texture path: vs_inState or pix in0]
      outlet 1 (jit_matrix match)     → (unused or matrix path)
      outlet 2 (unmatched)            → route param1 param2 ...
                                            outlet 0 → live.dial → attrui (param1) → pix in0
                                            outlet 1 → live.dial → attrui (param2) → pix in0
                                            ...

bypass_toggle.js → attrui (bypass) → pix in0   [wired directly, not through route]

pix out0 → bpatcher out0 (texture out)
```

Key points:
- **`routepass` only declares `jit_gl_texture jit_matrix`** — no param names on routepass
- **`route` dispatches named messages to the correct `live.dial`** — outlet indices start at 0 for first param
- **`attrui` replaces `prepend param <name>`** — it sits between the dial and pix in0, with the attribute name declared on the `attrui` object itself
- **bypass_toggle wires directly** — `jsui → attrui (bypass) → pix in0`, not through route
- **All `attrui` outputs go to pix in0** (the message inlet)

---

## jit.gl.pix Declaration

```
jit.gl.pix vsynth @name #0_<prefix>_pix
```

- First positional arg `vsynth` = drawto context
- `@name #0_<prefix>_pix` = scripting name, used by `param_connect`; the `#0_` prefix makes
  the Ob3D binding per-instance (bare `<prefix>_pix` collides when two instances are live in
  one context — see the checklist note, 2026-10-17)
- `numinlets: 1` — single message inlet; all params arrive as messages
- No `@dim` attribute — let Vsynth context set dimensions

**Output precision (`@type`):** Omitting `@type` defaults to float32, which is correct for most f_ patches. Two cases where it matters:

- **`@type float32`** — explicit full precision. Use when the patch output will be used as a modulation source by another patch (WFGs use this). Preserves sub-pixel values that would be lost at 8-bit.
- **`@type char`** — 8-bit integer output. Kevin uses this intentionally on feedback paths in `vs_feedback` and `vs_filter_temp` — the quantization artifacts are part of the aesthetic. Only use in f_ if that character is specifically wanted.

---

## Gen Subpatcher Structure

**Processor:**
```
in 1  →  codebox (inlet 0)   [upstream texture]
out 1  ←  codebox (outlet 0)
```

**Dual-mode generator:**
```
in 1   →  codebox (inlet 0)   [texture or vs_black fallback]
r dim  →  codebox (inlet 1)   [render dimensions — for aspect correction in generator mode]
out 1  ←  codebox (outlet 0)
```

`r dim` is only needed if the generator requires aspect correction (most do). Omit it if all computation is in normalized [0,1] UV space with no aspect dependency.

Codebox `numinlets` must match the number of wired inlets (1 for processor, 2 for dual-mode generator with `r dim`).

---

## Codebox Structure

```glsl
// Params declared at top
Param zoom(2.0);
Param bypass(0.0);

// ... computation ...

// Processor bypass — pass input through
out1 = mix(effect_out, sample(in1, norm), bypass);

// Dual-mode generator bypass — black in generator mode, pass-through in processor mode
Param src_mode(0.0);
out1 = mix(result, mix(vec(0,0,0,1), sample(in1, norm), step(0.5, src_mode)), bypass);
```

- `in1` = upstream texture (processor) or texture/vs_black (dual-mode generator)
- `norm` = normalized UV [0,1] as vec2
- `dim` = texture dimensions as vec2 — use `dim.x / dim.y` for aspect ratio
- `out1` = output — vec4 RGBA
- `bypass` always present, `mix()` always the last line. **Under native bypass this `mix` never runs** (the pix skips the shader); most modules now use `bypass_mode: "param"` with `Param bypass_gate`, mixed on every outlet. See `references/bypass-and-control.md`.

### jit.gl.pix Codebox Operators

**Load the `jit-gen-codebox` skill** for operators, silent failures, sampling and the review checklist; this skill no longer keeps a copy (an old copy here said `boundmode` is ignored, which jit-gen-codebox has since disproved: `boundmode="clamp"` works). The two facts most often needed here: read components inline (`sample(in1, uv).x`, never `col.x` on a stored variable), and `noise()` renders black on the GPU (use a sin hash).

### Sampling Syntax

```glsl
// Correct — inline component access only
luma = sample(in1, norm).x;

// Aspect-correct UV for generators
aspect = dim.x / dim.y;
px = norm.x * aspect;
py = norm.y;
```

---

---

## moduleSize.js Chain

Every bpatcher includes this chain to report its presentation size to Vsynth's module layout system:

```
loadbang → [getattr presentation_rect] → thispatcher → [zl slice 2] → [prepend tam] → js moduleSize.js
```

---

## UI Styling

- **Font:** `"fontname": "Ableton Sans Light"` on all text-bearing objects
- **Font sizes:** title 12pt, param labels 9.5pt
- **Background:** `panel` object, black bg `[0,0,0,1]`, blue border `[0, 0.035, 0.227, 1.0]`, presentation only
- **Dials:** `activedialcolor: [0.8, 0.8, 0.8, 1.0]`, `showname: 0`, `triangle: 1`, `valuepopup: 1`
- **Numboxes:** `44×15` patching, `34×15` presentation, Ableton Sans Light

---

## parameters Block (end of JSON)

Every param registered in `live.dial`, `live.numbox`, or `jsui` must appear here:

```json
"parameters": {
  "obj-2":  ["zoom", "zoom", 0],
  "obj-24": ["bypass", "bypass", 0],
  "obj-37": ["course_seed", "course_seed", 0],
  "parameterbanks": {
    "0": {
      "index": 0, "name": "",
      "parameters": ["-","-","-","-","-","-","-","-"],
      "buttons":    ["-","-","-","-","-","-","-","-"]
    }
  },
  "inherited_shortname": 1
}
```

Format per entry: `"<obj-id>": ["<longname>", "<shortname>", 0]`
