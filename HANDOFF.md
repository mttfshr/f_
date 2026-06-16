# HANDOFF — f_ session 2026-06-16 (end of session)

## What was done this session

### API key setup via macOS Keychain
- ANTHROPIC_API_KEY stored in Keychain via `security add-generic-password`
- Retrieved at runtime: `export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s "ANTHROPIC_API_KEY" -w)`
- Added to both `~/.zshrc` and `~/.bashrc` (DC spawns bash)
- No plaintext secrets in dotfiles

### Helpfiles generated (committed) — 5 modules
f_lens, f_masonry, f_mobius, f_caustic, f_stipple

All generated via `generate_helpfiles.py` using their definition.py files.
Total spend: ~51,750 tokens across two runs.

### build_patcher.py — pix_chain multi-pix extension (bce22a2)

`build_patcher.py` now supports multi-pix bpatchers via `pix_chain` + `pix_wires` keys
in the definition. Single-pix path is completely unchanged.

**New schema keys:**
- `pix_chain` — list of pix node dicts, each with `id`, `name`, `gen`, `n_inlets`,
  `n_outlets`, `pix_type`, `adapt`, `primary`. Exactly one node has `primary: True`.
- `pix_wires` — cross-pix patchlines as `[src_id, src_outlet, dst_id, dst_inlet]`
  tuples using symbolic `id` refs.
- `gen: "pass"` sentinel — generates a trivial identity gen (in 1 → out 1) without
  needing a codebox file.

**Object IDs:** primary pix → `obj-5`; support pix → `obj-50`, `obj-51`, ... in chain order.

**Wiring convention:** standard wiring (routepass→primary, mod_inlets→primary,
bypass→primary, params→primary, primary→outlets) is automatic. `pix_wires` adds
only the explicit cross-pix connections.

**`@name` on pix nodes:** fully explicit in the definition — no automatic prefixing.
The `#0_` scoping in `f_vf_advect` was a deliberate choice, not a general convention.
Whether it's actually required for multi-instance collision avoidance is unverified.

### f_vf_advect definition.py written
- `.specify/f_vf_advect/definition.py` written and building correctly
- `build_advect.py` in `.specify/f_vf_advect/` is now superseded (not deleted, just unused)
- Two pix nodes: `#0_advect_pass` (identity, support) + `#0_advect_pix` (primary)
- Feedback loop: `state out0 → pass in0`, `pass out0 → state in2`
- Vecfield inlet: direct, no vs_inState (`vs_instate: False`)
- 4 UI params: dt, decay, injection, mix_amt

### spec.md updated
- pix_chain/pix_wires schema documented under Optional keys

---

## What was done last session

### Helpfile generation loop (loop engineering POC)
Explored loop engineering concepts and built a session-based helpfile generation
pipeline as a proof of concept.

**Tooling added (committed):**
- `tools/extract_params.py` — extracts param metadata from definition.py (primary)
  or patcher JSON (fallback); outputs `tools/helpfile_queue.json`
- `tools/generate_helpfiles.py` — reads queue, calls Anthropic API, writes helpfiles;
  has budget ceiling and per-entry token tracking. Needs ANTHROPIC_API_KEY to run.

**Helpfiles generated — 13 modules:**
grain, stereo, vf_vortex, vf_streak, vf_warp, vf_fieldmap, util_profile,
droste, channel_grader, chladni, hue_processor, luma_processor, tone_curve

**definition.py files written (in .specify/, gitignored):**
f_droste, f_hue_processor, f_luma_processor, f_tone_curve, f_channel_grader,
f_chladni, f_lens, f_masonry, f_mobius, f_texrouter

---

## Priorities for next session

Reading order: plan.md → HANDOFF.md

1. **Integration test f_vf_advect in Max** — open the rebuilt patcher, verify feedback
   loop runs correctly, params addressable, bypass works. Compare against hand-built
   version if the old one is available.
2. **f_vf_glow** — identified as next natural vecfield build (flow-aligned luminance
   accumulation). Start with specify workflow.
3. **f_cymascope** — next multi-pix candidate (2 pass nodes + fdtd primary). Will
   exercise pix_chain with 3 nodes naturally.

---

## Loose threads

- `#0_` scoping on multi-pix @name — unverified whether required for collision avoidance
  across bpatcher instances. Test in Max before assuming either way.
- `build_advect.py` in `.specify/f_vf_advect/` — superseded but not deleted. Delete
  once f_vf_advect integration test passes.
- f_grain: built patcher missing sv_seed numbox, field numbox, edge_mode umenu —
  definition.py has them, patcher doesn't; needs reconciliation
- f_chladni audio companion loadbang-in-bpatcher init reliability
- f_mobius performance — needs real use before deciding if params need extending
- f_vf_vortex/vortex_multi: in0 label is 'texture / control' but it's control-only —
  minor cosmetic inaccuracy, low priority
- Stipple displaced UV reconstruction with angle≠0 — scratch patch verify
- Color theming via Max styles — worth establishing before module count grows further
- f_poincare presentation region — f_vf_scalar masking is the natural mechanism
- Reaction-diffusion → f_vf_fieldmap → f_caustic — signal chain experiment
