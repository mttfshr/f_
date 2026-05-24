# f_ Package Handoff
_Last updated: 2026-05-23 — package cleanup and bypass toggle rollout_

## What was done this session

### Package restructure
- Renamed `javascript/` → `code/` (Max package convention — auto-adds to search path)
- Fixed hardcoded absolute JS paths in `f_luma_processor` and `f_tone_curve`
- Symlinked package into Max Packages folder — all JS files now resolve by name

### Control messaging (route-based)
Added named message control to all processor patchers. Pattern:

```
inlet → route <param1> <param2> ... → UI elements → prepend param → pix
                                    → last outlet → pix (texture passthrough)
```

Params per patcher:
- `f_tone_curve`: bypass, shadows, midtones, highlights, edge_falloff, low_mid, mid_high
- `f_luma_processor`: bypass, sat_amt, lum_shift, hue_shift, edge_falloff, low_mid, mid_high
- `f_hue_processor`: bypass, sat_amt, lum_shift, hue_shift, edge_falloff (rslider params excluded)
- `f_channel_grader`: bypass, r/g/b × lift/gamma/gain, m × lift/gamma/gain
- `f_droste`: bypass, zoom, n_arms, twist, rotation (on routepass unmatched outlet)
- `f_grain`: bypass, density, amount, persistence, fade, size, size_var, shape, softness, jitter, ch_diverge, luma_gate, displace, edge_mode_menu, field, sv_seed

Usage: send `sat_amt 0.5` or `bypass 1` into bpatcher inlet.

### bypass_toggle.js
New jsui component in `code/bypass_toggle.js`:
- Web-style pill toggle, 18×12px
- Gray = active (effect running), Red = bypassed
- Click to toggle, inlet accepts 0/1 messages
- autopattr compatible (`getvalueof`/`setvalueof`)
- Hover label shows "bypass"

Rolled out to all 7 patchers replacing the standard Max toggle.

## Current state

All patchers working and tested in Max. Package is clean, committed.

## Loose threads

- **hue_lower / hue_upper not remotely controllable** — rslider params were intentionally left out of the route object in `f_hue_processor` to avoid feedback loops. Revisit if needed.
- **f_texrouter bypass semantics** — bypass in texrouter = freeze (gate states unchanged, control messages blocked). Different from processor bypass which passes texture through. Worth documenting in help patch.
- **bypass_toggle hover label** — `onmouseenter`/`onmouseleave` confirmed working in Max 9. If it breaks in future versions, fallback is to remove hover and rely on the red/gray visual alone.
- **f_grain_displace** — removed, work deferred indefinitely.

## Next steps

- Help patchers — none of the bpatchers have help files yet
- Test control messaging in a real Vsynth patch (send named messages from another module)
- Consider adding `route`-based control to `f_texrouter` for cell, preset, clear, reset

## Package structure

```
f_/
  code/           — JS files (bypass_toggle.js, hue_rslider.js, hue_range.js, etc.)
  patchers/       — all 7 bpatchers
  help/           — (empty, to be filled)
  package-info.json
```

## Resources
- Max package conventions: https://docs.cycling74.com/max8/vignettes/packages
- Vsynth: /Users/matt/Documents/Max 9/Packages/Vsynth
