# HANDOFF — f_ session 2026-06-06

## Status

Repo cleanup + helpfile work. `f_droste.maxhelp` completed as the template for all future helpfiles.

---

## Helpfile conventions established (f_droste.maxhelp as template)

**Layout**: Single flat pane. No tabs unless a module has genuinely distinct usage modes or long documentation.

**Structure top to bottom:**
- Title bar: Ableton Sans Medium, 36pt, full width, themed bgcolor (`themecolor.live_control_text_bg`), varname `autohelp_top_digest[4]`. Text is short name without prefix — "Droste" not "f_droste".
- Digest bar: Ableton Sans Light, 14pt, full width, same themed bgcolor, varname `autohelp_top_digest[3]`.
- Signal flow column left: `vs_sources_main` → bpatcher → `vs_preview`. Dashed wires.
- LFO (`vs_wfg_s`) to the right of bpatcher, wired to scalar/time inlet via outlet 1 (data out, not texture out).
- Bubble label ("time_s") pointing left toward the wire, Ableton Sans Light.

**External Control Messages block** (top-right, Ableton Sans Light, right-justified):
Lists only externally-addressable params with ranges. Not UI dials.

**References block** below External Control Messages, same column, Ableton Sans Light 12pt.
Plain ASCII only (no unicode math symbols or curly quotes — font renders them but safer to avoid).

**Canonical rects (processor with time inlet, patcher rect ~771x681):**
- Panel (left column bg): `[0, -2, 303, 765]`
- Title (h-1): `[15, 15, 270, 50]`
- Digest (h-2): `[15, 75, 270, 40]`
- External Control Messages (d-8): `[15, 150, 270, 122]` — grows with param count
- References (r-1): `[15, 315, 270, 208]` — starts ~165px below ext ctrl bottom
- vs_sources_main (d-3): `[338, 24, 296, 126]`
- LFO/vs_wfg_s (d-6): `[417, 196, 75, 74]`
- time_s bubble (d-7): `[500, 221, 64, 26]`
- bpatcher (d-4): `[338, 294, 154, 91]`
- vs_preview (d-5): `[338, 405, 236, 249]`

**Tab architecture**: Investigated. Works via `showontab: 1` inside embedded patcher + `showrootpatcherontab: 0` on root. Root tab cannot be fully suppressed via JSON alone. Not worth the complexity for modules with short reference lists. Revisit only if a module genuinely needs multiple distinct views.

**docs/ references**: Each module's `docs/f_name.md` gets a `## References` section with full citations. Helpfile references block is the summary; docs file is the canonical source.

---

## What was done this session

### Repo organization
- `code/` renamed to `javascript/` — aligns with Max package convention (Vsynth uses `javascript/` for JS, `code/` for gen files)
- `tools/build_texrouter.py` moved from `code/` to `tools/` (it's a build script, not a runtime file)
- `tools/` reorganized: masonry-specific scripts into `tools/masonry/`, util_profile scripts into `tools/util_profile/`

### .specify/ updates
- `f_chladni/tasks.md`: T029/T030 (view_mode verification) marked complete — confirmed passing last session per HANDOFF
- `e2e-testing/tasks.md`: A (load/crash safety) marked done for all patchers touched last session (droste, lens, mobius, stereo, channel_grader, hue_processor, luma_processor, tone_curve); notes added; @type and bypass_toggle cross-cutting checks marked complete
- `.specify/f_weave/` deleted — pre-rename masonry artifacts, superseded, preserved in git history

### ideas/ reorganization
Scratchpad pruned from 506 → ~160 lines. Extracted to dedicated files:
- `ideas/f_util_audio_spectra.md` — audio spectral character extractor concept
- `ideas/f_vecfield.md` — vector field displacement generator; multi-fixed-point architecture; face/figure generator as motivating use case
- `ideas/vsynth_gaps.md` — strategic analysis of Vsynth capability gaps and f_ positioning
- `ideas/f_weave.md` — collision events appended; **distance field as hard design requirement** added with rationale

Deleted: `ideas/f_mobius.md`, `ideas/f_stipple.md` (superseded by built patchers)

Updated:
- `ideas/f_cymascope.md` — history note clarifying chladni split; multi-pix alternative to ping-pong noted
- `ideas/entrainment.md` — f_spiral noted as superseded by droste (arms=1, twist≈0, slow rotation)
- `ideas/vsynth_gaps.md` — displacement gap clarified: field generators and idioms are interesting, replacement processors are not

### New ideas captured
- **Masonry→droste aliasing root cause**: mortar edges are high-frequency boundary transitions; distance field approach is the architectural fix; f_weave written distance-field-native serves as proof of concept for future masonry refactor
- **f_vecfield multi-fixed-point**: motivating use case is generative face/figure generator (tribal/fauvist/outsider aesthetic); face emerges from attractor topology rather than being drawn
- **Droste raster reframe**: 360 video works through droste because natural images have no sub-pixel features; masonry's problem is feature frequency vs droste compression ratio, not AA per se
- **f_cymascope**: multi-pix chaining may avoid explicit ping-pong texture management; investigate vs_chemical_osc architecture

### Helpfiles
- `help/f_droste.maxhelp` created — working demo + external control block + references
- `docs/f_droste.md` updated — correct param ranges, loose threads, references section added
- Helpfile conventions documented above

### README
Rewritten for public/package framing:
- Installation updated to Packages directory with OS paths
- Type column added to patch table (Generator / Processor / Utility)
- Patches reordered: generators, processors, utilities
- f_chladni updated to with audio companion note
- Build Queue removed
- Help files note folded into Notes

---

## Next session options

- **f_chladni Phase 3 (EEG)** — requires Muse headset; T020 measurement pass first
- **f_chladni Phase 5 (docs)** — update docs/f_chladni.md, mark tasks complete
- **f_mobius** — performance gap; what params would open up the useful range?
- **f_chladni_audio spectral normalization** — per-frame normalization after slide~ envelopes
- **Continue e2e audit** — B–G remaining for most patchers
- **More helpfiles** — f_stereo is next simplest candidate

## Loose threads

- f_masonry C inlet (in4) wiring — hover in Max to confirm index assignments
- f_masonry `quantize` param — needs performance use to judge whether it earns its place
- f_grain dual-mode — partially implemented, not working; deferred
- f_vecfield scratch patch — validate single-center displacement field in Vsynth before speccing
- f_droste `time_s` inlet on in[1] — convention violation (should be in[0]); deferred refactor
