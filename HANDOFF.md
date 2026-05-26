# f_ — Handoff

_Last updated: 2026-05-25_

---

## Active Build

**f_chladni — Signal Chain**
`.specify/f_chladni/` — spec, plan, tasks all present.
Start with `tasks.md` → T001 (patcher rename in Max).

---

## Bpatcher Status

| Bpatcher | Stage | Location |
|----------|-------|----------|
| f_chladni | 🔨 Active build | `.specify/f_chladni/` |
| f_mobius | 📋 Specced | `.specify/f_mobius/spec.md` |
| f_droste | ✅ Working | `docs/f_droste.md` |
| f_grain | ✅ Working | `docs/f_grain.md` |
| f_hue_processor | ✅ Working | `docs/f_hue_processor.md` |
| f_luma_processor | ✅ Working | `docs/f_luma_processor.md` |
| f_tone_curve | ✅ Working | `docs/f_tone_curve.md` |
| f_channel_grader | ✅ Working | `docs/f_channel_grader.md` |
| f_texrouter | ✅ Working | `docs/f_texrouter.md` |
| f_cymascope | 💡 Idea | `ideas/f_cymascope.md` |
| f_stereo | 💡 Idea | `ideas/circular_screen.md` |
| f_sharmonics | 💡 Idea | `ideas/circular_screen.md` |
| f_poincare | 💡 Idea | `ideas/circular_screen.md` |

---

## Build Queue

1. **f_chladni signal chain** — active
2. **f_mobius** — next; plan + tasks when f_chladni is done
3. **f_stereo** — after f_mobius (shared math)
4. **f_poincare** — after f_mobius (shared math)
5. **f_sharmonics** — after f_stereo
6. **f_cymascope** — feasibility check first (ping-pong texture in jit.gl.pix)

Scope review needed before committing to optics family (f_lens, f_caustic, f_flare, f_diffraction) or Apollonian fractal.

---

## Package-Wide Loose Threads

- **Help patches** — none exist for any bpatcher; start with f_texrouter (bypass = freeze, not pass-through — must be documented)
- **f_chladni rename** — `f_cymascope.maxpat` → `f_chladni.maxpat` still pending in Max (T001)
- **f_hue_processor** — hue_lower/hue_upper not remotely controllable; on hold
- **README patch table** — needs update after f_chladni rename

---

## .specify/ Structure

```
.specify/
  constitution.md          — package-wide constraints and values
  f_chladni/
    spec.md                — what it does, signal chain, acceptance criteria
    plan.md                — ADRs, dependency blocks, phases
    tasks.md               — T001–T034, session anchor
  f_mobius/
    spec.md                — what it does, params, codebox structure
                           — plan + tasks added when build begins
```

**Lifecycle**: `ideas/scratchpad.md` → `ideas/f_name.md` → `.specify/f_name/` → `docs/f_name.md`
