# Vsynth Pattern Library

**Status:** Skeleton — not yet populated. Reading pass planned; see HANDOFF.md.

**Purpose:** Recurring architectural patterns Kevin uses in Vsynth internals — patterns f_ can adopt, extend, or knowingly diverge from. Answers "how does Kevin solve X?"

**Questions this document answers:**
- How does Kevin handle dual-mode (source vs. processor)?
- How does he handle texture inlet routing?
- How does he handle parameter animation/modulation internally?
- What does a Tier 3 (ping-pong, frame-memory) patch actually look like structurally?
- What recurring codebox patterns exist — hash functions, SDF approaches, UV conventions?

---

## Dual-Mode: vs_inState

*To be documented from reading `patchers/abstractions/vs_inState.maxpat`.*

Known so far (from f_ session notes): monitors inlet state via draw-callback timing. Outlet 0 = texture or `vs_black` fallback. Outlet 1 = 0/1 int, fires on state change only.

---

## Tier 3 Architecture (Ping-Pong / Frame Memory)

*To be documented from reading `patchers/vs_feedback.maxpat`.*

Known so far: feedback loop exists as a module. Internal mechanism unknown — how does Kevin route frame N output back as frame N+1 input within the Vsynth render context?

---

## WFG Internal Architecture

*To be documented from reading `code/vs_wfg_sine.genjit` and `code/vs_wfg3.genjit`.*

Known so far: gen-based, waveform selected by swapping `.genjit` file. Parameter surface: freq, phase, angle, FM amount. Texture output carries both the waveform value and displacement information.

---

## Abstractions Inventory

*To be documented from reading all files in `patchers/abstractions/`.*

Known abstractions (from directory listing):
- `vs_inState` — inlet connection state detection
- `vs_thru` — unknown; likely passthrough utility
- `vs_canvas` — unknown
- `vs_canvasLFO` — unknown; canvas variant with LFO?
- `vs_2xblur` — 2× blur utility
- `vs_b2b` — unknown
- `vs_bline` — unknown
- `vs_getactivetab` — unknown
- `vs_newTime` / `vs_oldTime` — unknown; time-related
- `vs_populate` — unknown; likely module layout
- `vs_range` — unknown; likely value scaling/mapping
- `vs_rotary` — unknown
- `vs_scrub` — unknown
- `mm_rgb2hsl` — RGB→HSL conversion (non-vs prefix, likely third-party)
- `vs.ohelp` — likely help file abstraction

---

## Send/Receive Namespace

*To be documented from reading `patchers/vs_public_variables.txt`.*

Known sends/receives from f_ session notes:
- `r dim` — current render dimensions (vec2)
- `r time` — global time/tempo signal
- `s delta`, `s theta`, `s alpha`, `s beta`, `s gamma` — EEG band sends (from muse.maxpat)

---

*Populated: 2026-05-31 (skeleton only — no files read yet)*
*Last updated: 2026-05-31*
