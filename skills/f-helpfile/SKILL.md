---
name: f-helpfile
description: Conventions for writing .maxhelp files for the f_ Vsynth bpatcher library. Use when creating or editing any file in /Users/matt/Github/f_/package/help/. Covers layout, fonts, object structure, tab mechanics, signal flow conventions, and the reference block pattern. f_droste.maxhelp is the canonical template.
---

# f_ Helpfile Skill

Conventions for `package/help/f_<name>.maxhelp` files in the f_ library. The canonical template is `package/help/f_droste.maxhelp` — read it before generating a new helpfile.

**Helpfiles live at:** `/Users/matt/Github/f_/package/help/`
**Template:** `/Users/matt/Github/f_/package/help/f_droste.maxhelp`

---

## Prerequisite: docs/f-reference must exist first

`docs/f-reference/f_name.md` is not optional supporting material — it is the
required upstream synthesis this skill's output is generated from. Before
writing or generating any `.maxhelp` file:

1. Confirm `docs/f-reference/f_name.md` exists and reflects the module's
   current stable state. If it doesn't exist yet, **that's the actual task**
   — write it first, synthesizing:
   - Mechanical params from `.specify/f_name/definition.py` (or the built
     `.maxpat` if no definition file exists)
   - Real signal flow from the built patcher
   - A Notes section distilled from that module's `spec.md`/`plan.md`/
     `tasks.md` — resolved decisions, empirical findings, known honest
     limitations. See `f_vf_optical_flow.md` for a worked example of this
     synthesis.
2. Only once that doc exists does `build/extract_params.py` +
   `build/generate_helpfiles.py` have real material to draw prose from —
   both refuse to queue/generate a module without it (see `build/spec.md`'s
   "Helpfile Generation Pipeline" section for the full rule and why).

Skipping straight to helpfile generation without this doc produces a
mechanically-correct but narratively-empty helpfile — accurate param ranges,
no real "why" or known-limitations content, because there's nothing to draw
that from.

---

## Core Layout: Two-Column Flat Pane

Single flat pane — no tabs. Left column: identity and reference text. Right column: signal flow.

```
[panel — left column bg]   [vs_sources_main        ]
[Title                 ]       ↓
[Digest                ]   [LFO] → time_s bubble
[                      ]       ↓
[External Control Msgs ]   [f_name bpatcher        ]
[param list...         ]       ↓
[                      ]   [vs_preview              ]
[References            ]
[citation text...      ]
```

Generators (no upstream source needed) omit `vs_sources_main` — the bpatcher sits at the top of the right column.

---

## Canonical Rects (Processor with time inlet)

Patcher window rect: `[100, 99, 871, 780]` (771×681 usable)

| Object | ID | Rect `[x, y, w, h]` |
|---|---|---|
| Left column panel | obj-1 | `[0, -2, 303, 765]` |
| Title | h-1 | `[15, 15, 270, 50]` |
| Digest | h-2 | `[15, 75, 270, 40]` |
| External Control Messages | d-8 | `[15, 150, 270, 122]` — grows with param count |
| References | r-1 | `[15, 315, 270, 208]` — ~165px below ext ctrl bottom |
| vs_sources_main | d-3 | `[338, 24, 296, 126]` |
| LFO (vs_wfg_s) | d-6 | `[417, 196, 75, 74]` |
| time_s bubble | d-7 | `[500, 221, 64, 26]` |
| bpatcher | d-4 | `[338, 294, 154, 91]` |
| vs_preview | d-5 | `[338, 405, 236, 249]` |

Adjust References rect y based on actual External Control Messages height. Keep ~40px gap between sections in the left column.

---

## Fonts

| Element | Font | Size |
|---|---|---|
| Title | Ableton Sans Medium | 36pt |
| Digest | Ableton Sans Light | 14pt |
| External Control Messages | Ableton Sans Light | 13pt |
| References | Ableton Sans Light | 12pt |
| Bubble labels | Ableton Sans Light | 13pt |

All comments use `"fontface": 0`. No bold, no italic.

---

## Title Bar

```json
{
  "maxclass": "comment",
  "text": "Droste",
  "fontname": "Ableton Sans Medium",
  "fontsize": 36.0,
  "fontface": 0,
  "patching_rect": [15.0, 15.0, 270.0, 50.0],
  "varname": "autohelp_top_digest[4]",
  "saved_attribute_attributes": {
    "bgcolor": {"expression": "themecolor.live_control_text_bg"},
    "textcolor": {"expression": "themecolor.live_control_fg"}
  },
  "bgcolor": [0.11, 0.135, 0.16, 1.0],
  "textcolor": [0.9, 0.9, 0.9, 1.0]
}
```

- Text is **short name without prefix** — "Droste" not "f_droste"
- `varname` must be `autohelp_top_digest[4]`

---

## Digest Bar

```json
{
  "maxclass": "comment",
  "text": "Log-polar spiral transform — Droste / Escher-style recursive zoom",
  "fontname": "Ableton Sans Light",
  "fontsize": 14.0,
  "fontface": 0,
  "patching_rect": [15.0, 75.0, 270.0, 40.0],
  "varname": "autohelp_top_digest[3]",
  "saved_attribute_attributes": {
    "bgcolor": {"expression": "themecolor.live_control_text_bg"},
    "textcolor": {"expression": "themecolor.live_control_fg"}
  },
  "bgcolor": [0.11, 0.135, 0.16, 1.0],
  "textcolor": [0.9, 0.9, 0.9, 1.0]
}
```

- `varname` must be `autohelp_top_digest[3]`

---

## Left Column Panel

```json
{
  "maxclass": "panel",
  "patching_rect": [0.0, -2.0, 303.0, 765.0]
}
```

Extends slightly above (y=-2) and below the visible canvas. No border needed — background color comes from theme.

---

## External Control Messages Block

Right-justified text, Ableton Sans Light, lists only externally-addressable params (not UI dials the user clicks — params addressable via named messages on in0).

```
External Control Messages

bypass [0 / 1]
zoom [1.1 – 100.0]
n_arms [1 – 16]
twist [-8.0 – 8.0]
rotation [0.0 – 1.0]
time_s [continuous]
```

Format ranges with en-dash (–), not hyphen. Boolean params use `[0 / 1]`. Continuous float signals use `[continuous]`.

---

## References Block

Plain ASCII only — no unicode math symbols, no curly quotes, no em-dashes in the text content (use `--` and straight quotes). Ableton Sans Light renders unicode correctly but plain ASCII is safer and more portable.

```
References

Log-polar mapping: classical complex analysis
log(z) = log|z| + i * arg(z)

Lenstra & de Smit (2003)
"Solving Escher's Problem"
https://www.math.leidenuniv.nl/~smit/escher/

Symmetric shear formulation (twist parameter):
derived in development -- not from any external source.
At twist=1, one revolution = one zoom level (Escher coupling).
```

Each module's `docs/f_name.md` carries a `## References` section with full citations. The helpfile block is the summary — point users to docs for more.

---

## Signal Flow (Right Column)

### Processor

```
vs_sources_main  →  f_name (bpatcher)  →  vs_preview
vs_wfg_s (out1) →  f_name inlet 1
```

- `vs_sources_main`: flexible source with camera/movie/noise/oscillator tabs
- Wire from `vs_wfg_s` outlet **1** (data/scalar out) — not outlet 0 (texture)
- Bubble label on the wire: text "time_s", Ableton Sans Light, `"bubbleside": 1` (points left)

### Generator

```
f_name (bpatcher)  →  vs_preview
```

No source needed. Bpatcher at top of right column, preview below.

---

## LFO / Scalar Signal Convention

`time_s` and any other scalar signal inlets use `vs_wfg_s` as the demo driver. Wire from its **second outlet** (outlet index 1) — this is the data/float output. Outlet 0 is the texture output and will not drive a scalar param correctly.

---

## Tab Architecture (avoid for most modules)

Investigated. The mechanism:
- Set `"showontab": 1` inside each embedded subpatcher's patcher object
- Set `"showrootpatcherontab": 0` and `"showontab": 0` on the root patcher

The root tab ("f_droste.maxhelp (root)") cannot be fully suppressed via JSON — it requires interactive right-click or `helpstarter.js` machinery. Not worth the complexity for modules with short reference lists.

**Use tabs only if:** the module has genuinely distinct usage modes that don't fit on one canvas, or the reference content is long enough to warrant separation.

For everything else: single flat pane, references as a comment block below External Control Messages.

---

## Checklist: New Helpfile

- [ ] File at `help/f_<name>.maxhelp`
- [ ] Title text is short name without prefix ("Grain" not "f_grain")
- [ ] `varname: autohelp_top_digest[4]` on title, `[3]` on digest
- [ ] Ableton Sans Medium on title, Ableton Sans Light on everything else
- [ ] Left column panel object present
- [ ] External Control Messages lists only externally-addressable params with correct ranges
- [ ] References block uses plain ASCII text
- [ ] `docs/f_name.md` has `## References` section matching helpfile content
- [ ] Signal flow: processor uses `vs_sources_main`; generator does not
- [ ] LFO wired from outlet 1 (scalar), not outlet 0 (texture)
- [ ] Bubble label on time_s wire, bubbleside pointing toward wire

---

## docs/ References Convention

Every working module's `docs/f_name.md` should have:

```markdown
## References

Brief description of the mathematical foundation and provenance.

- Author (year). "Title." URL
- Any original derivations clearly labeled as such.
```

The key transparency goal: allow skeptical users to verify the math lineage and
confirm no code was lifted from other implementations. Original derivations
should be named as such — this is honest and actually reassuring.

**Attribution practice for externally-sourced techniques:**

Any technique drawn from published literature — GPU Gems, ShaderX/GPU Pro/GPU
Zen, iquilezles.org, SIGGRAPH papers, or any other source — should be cited
with enough specificity that someone could find the original:

```markdown
- Policarpo (2004). "Real-Time Stereograms." GPU Gems Ch. 41.
  https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-41-real-time-stereograms

- Quilez (2013). "Voronoi Edges."
  https://iquilezles.org/articles/voronoilines/
```

Be honest about the relationship: "algorithm used directly," "adapted from,"
or "inspired by" are all valid — the distinction matters and readers can tell
the difference.

The helpfile References block is a summary pointing to these sources. The
`docs/` entry carries the full citation. Both should be kept in sync.
