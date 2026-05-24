# f_ Package Handoff
_Last updated: 2026-05-24 — f_cymascope initial build + vsynth-bpatcher skill update_

## What was done this session

### f_cymascope: new Bessel mode cymatics bpatcher

Built `patchers/f_cymascope.maxpat` from scratch — a circular plate modal synthesis visualizer.

**Concept:** Superimposes 8 circular membrane modes using large-x asymptotic Bessel function approximations. Each mode `m` contributes `sqrt(2/πr) * cos(r - z_m) * cos(m*θ + ph_m) * amplitude`. Nodal lines rendered via `1 - clip(sqrt(abs(total)) * linesharpness, 0, 1)`.

**Parameters:**
- `m0amp`–`m7amp` — modal amplitudes (signal-driven inputs)
- `z0`–`z7` — Bessel zeros, correct J_m first zeros by default, tweakable
- `ph0`–`ph7` — phase per mode (note: ph0 has no effect for m0, no angular term)
- `dishradius` — plate radius scale
- `reflectamt` — boundary reflection standing wave mix
- `linesharpness` — nodal line width
- `globalscale` — output brightness
- `view_mode` — 0=circular (default), 1=unwrapped strip, blendable

**Intended signal chain (not yet built):**
- Audio path: mic → bandpass bank (8 filters at modal freq ratios) → peakamp → smooth → mNamp
- EEG path: Muse OSC → udpreceive → band routing → scale → smooth → mNamp
- Muse updates at ~10Hz — needs `line`/`slide~` smoothing before params

**EEG band → mode mapping:**
Delta→m0, Theta→m1, Alpha→m2, Beta-lo→m3, Beta-hi→m4, Gamma-lo→m5, Gamma-hi→m6, Spare→m7

### vsynth-bpatcher skill updated

Updated `/Users/matt/Github/claude-scaffold/skills/vsynth-bpatcher/SKILL.md` with:
- `patterns/` vs `patchers/` distinction (version control boundary)
- One-sentence mental model: Vsynth owns render tempo and cornerpins
- Codebox-first workflow: write text, paste manually, verify before building JSON
- Template derived from f_droste (no autopattr, routepass pattern, moduleSize chain)
- Two codebox gotchas added: `vec4()` invalid (use `vec()`), single Vsynth inlet

## Current state

All patchers working. f_cymascope confirmed producing correct Bessel patterns visually.

## Loose threads

- **f_cymascope signal chain** — modal amps are static dials; audio/EEG analysis chain not yet built
- **f_cymascope near-center singularity** — `sqrt(2/πr)` diverges at origin, visible as bright spike. Low priority, somewhat characteristic of cymatics images
- **ph0 dead param** — phase has no effect for m0 (cos(0*θ + ph0) = cos(ph0) = constant). Consider repurposing as global phase or hiding
- **hue_lower / hue_upper not remotely controllable** — rslider params intentionally left out of route in `f_hue_processor`. Revisit if needed
- **f_texrouter bypass semantics** — bypass = freeze, different from processor bypass. Document in help patch

## Next steps

- Build audio signal analysis chain for f_cymascope (bandpass bank → peakamp → smooth)
- Build Muse OSC → cymascope routing patch
- Help patchers — none of the bpatchers have help files yet
- Test control messaging in a real Vsynth patch

## Package structure

```
f_/
  code/           — JS files (bypass_toggle.js, hue_rslider.js, etc.)
  patchers/       — 8 bpatchers (+ f_cymascope new this session)
  help/           — (empty)
  package-info.json
```

## Resources
- Max package conventions: https://docs.cycling74.com/max8/vignettes/packages
- Vsynth: /Users/matt/Documents/Max 9/Packages/Vsynth
- Cymascope Obsidian note: f_cymascope_bpatcher.md
