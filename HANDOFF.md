# HANDOFF — f_ session 2026-06-09 (end of session)

## What was done this session

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

1. **build_patcher.py multi-pix extension** — design schema for multi-pix bpatchers so
   f_vf_advect can get a definition.py and build_advect.py can be retired. f_cymascope
   (3 pix) will stress-test the design.
2. **f_cymascope spec** — now unblocked; Pattern 1 extended (3 pix, 2 historical frames).
3. **f_poincare spec** — fully independent; good alternative if geometry feels more
   appealing than implementation work.

---

## Loose threads

- f_mobius performance gap — needs use before deciding if params need extending
- Color theming via Max styles — worth establishing before module count grows further
- Reaction-diffusion → f_vf_fieldmap → f_caustic — signal chain experiment
- f_poincare presentation region — f_vf_scalar masking is the natural mechanism
- f_chladni audio companion loadbang-in-bpatcher init reliability
- Stipple displaced UV reconstruction with angle≠0 — worth a scratch patch verify
- f_vf_vortex/vortex_multi: in0 label is 'texture / control' but it's control-only — minor cosmetic inaccuracy, low priority
