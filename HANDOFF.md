# HANDOFF — f_ session 2026-06-15 (end of session)

## What was done this session

### Helpfile generation loop (loop engineering POC)

Explored loop engineering concepts (Addy Osmani's post) and built a session-based
helpfile generation pipeline as a proof of concept — no API key needed, ran inline.

**Tooling added (committed):**
- `tools/extract_params.py` — extracts param metadata from definition.py (primary)
  or patcher JSON (fallback); outputs `tools/helpfile_queue.json`
- `tools/generate_helpfiles.py` — reads queue, calls Anthropic API, writes helpfiles;
  has budget ceiling and per-entry token tracking. Needs ANTHROPIC_API_KEY to run.

**Helpfiles generated (committed) — 13 modules:**
grain, stereo, vf_vortex, vf_streak, vf_warp, vf_fieldmap, util_profile,
droste, channel_grader, chladni, hue_processor, luma_processor, tone_curve

**definition.py files written (in .specify/, gitignored) — new this session:**
f_droste, f_hue_processor, f_luma_processor, f_tone_curve, f_channel_grader,
f_chladni, f_lens, f_masonry, f_mobius, f_texrouter

**Key finding:** definition.py is the right primary source for helpfile generation —
better hints, correct ranges, explicit `internal` type for non-addressable params.
Patcher JSON fallback works but produces lower quality output.

## What was done last session

### UI density design exploration (no code changed)
Extended design discussion around legibility and param organization in bpatcher panels.

**Compound widget concept:** dial (primary param) + two live.numbox rows (primary + secondary value) arranged horizontally — dial left, label+numbox rows stacked right. Fixed labels always visible, color differentiation (white primary / blue secondary). No jsui required. Replaces compound dial idea.

**f_vortex_multi redesign concept:** Replace 17-dial layout with:
- `nodes` object: sites 1/2/3 as draggable colored points + C node for global cx/cy offset (cx_amt/cy_amt)
- Conv. + Curl dials: global mod amounts (conv_amt, curl_amt)
- 3×2 color-coded numbox grid: per-site conv/curl values
- Falloff dial: shared

**Open questions before implementing vortex_multi redesign:**
- Can `nodes` receive position messages programmatically? (needed for CV input and preset recall)
- Is C node output distinguishable from site nodes in the output stream?
- How do numeric/CV inputs for site positions work alongside spatial drag control?
- `nodes` message protocol may not map cleanly to setattr/param system

**Design principles surfaced:**
- When a param pair has a natural 2D spatial interpretation, a 2D control is more correct than two dials (vortex cx/cy is a one-off, not a general rule)
- Per-site color coding (matching node colors to numbox row colors) is a strong legibility pattern

## What was done last session

### Inlet/outlet label standardization (152755d, f98a189)
Established consistent vocabulary for inlet/outlet comments across all patchers:
- `texture / control` — primary inlet (texture or Max messages)
- `texture` — standard texture outlet (passthrough/transform)
- `vecfield` — float32 RG vecfield signal (in or out)
- `composite` — processed output blended over source
- `control` — dedicated Max message/param inlet (Mobius, Stereo legacy)
- Layer names (`caustic`, `streak`, `grain mask`, `displaced`, `brick mask`, `warped`, `advected`) — isolated effect outlets

### Multi-outlet additions (f98a189)
- `f_stipple` — 3 outlets: composite, stipple mask, displaced; `proc_mode` header toggle removed
- `f_masonry` — 2 outlets: composite, brick mask
- `f_vf_warp` — 2 outlets: composite, warped (raw displaced sample)
- `f_vf_advect` — 2 outlets: composite, advected (accumulated state pre-mix)
- `f_grain` — label→comment bug fixed; outlet vocabulary updated

### Vecfield signal_type label in header (66cd5f6)
- `build_patcher.py`: `signal_type_box()` renders small cyan-blue label in header right of title
- `SIGNAL_TYPE_COLORS`: `vecfield=[0.35, 0.75, 0.95, 1.0]`
- `"signal_type": "vecfield"` added to all vf_ definition.py files + build_advect.py
- Label is now rebuild-proof — no longer hand-added in Max

### f_caustic refactor — pure processor (c783325)
- Removed vestigial primary inlet (was doing nothing — texture was arriving on in1 not in0)
- Now 2 inlets: `texture / control` on in0, `vecfield` on in1 (direct, no vs_inState)
- Architecturally consistent with f_vf_warp and f_vf_streak
- Codebox: in2→in1, in3→in2 (mechanical renumber, no logic changed)

### Python tooling (df0611b)
- `tools/py.sh` wrapper ensures Homebrew Python 3.13
- Use `tools/py.sh tools/build_patcher.py ...` instead of `python3 ...`
- Restart Claude at start of next session to pick up updated ~/.bashrc PATH

---

## Priorities for next session

Reading order: plan.md → HANDOFF.md

1. **Remaining helpfiles** — generate for f_lens, f_masonry, f_mobius, f_stipple,
   f_caustic using their definition.py files (all written this session).
2. **API key setup** — get ANTHROPIC_API_KEY so generate_helpfiles.py can run
   unattended for any remaining modules.
3. **build_patcher.py multi-pix extension** — design schema for multi-pix bpatchers so
   f_vf_advect can get a definition.py and build_advect.py can be retired.

---

## Loose threads

- f_mobius performance gap — needs use before deciding if params need extending
- Color theming via Max styles — worth establishing before module count grows further
- Reaction-diffusion → f_vf_fieldmap → f_caustic — signal chain experiment
- f_poincare presentation region — f_vf_scalar masking is the natural mechanism
- f_chladni audio companion loadbang-in-bpatcher init reliability
- Stipple displaced UV reconstruction with angle≠0 — worth a scratch patch verify
- f_vf_vortex/vortex_multi: in0 label is 'texture / control' but it's control-only — minor cosmetic inaccuracy, low priority
- f_grain: built patcher missing sv_seed numbox, field numbox, edge_mode umenu — definition.py has them, patcher doesn't; needs reconciliation
