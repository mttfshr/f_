# HANDOFF — f_ session 2026-05-31 (ideation)

## Status
Pure ideation session — no patches built, no files changed except documentation. Thinking about the texture analysis utility family substantially developed and captured.

---

## What was completed this session

### f_util_analysis family — ideation developed and graduated
Extended the `f_util_profile` scratchpad entry into a full design document at `ideas/f_util_analysis.md`. Key developments:

**Design principle established: proprioception**
The analysis utility family is framed not as "useful control signals" but as giving a patch awareness of its own visual content. The animating idea: a patch that responds to what it's doing rather than what it's told is a qualitatively different instrument.

**Concrete case articulated (f_weave + f_util_profile):**
A weave patch that knows its own luminance distribution per band can develop internal coherence — bright regions behaving differently from dark regions according to rules that emerge from the content itself. The rule is simple and fixed; the behavior is complex because the signal driving it is itself dynamic. That's the loop.

**f_util_envelope identified as companion utility:**
ADSR-style conditioning for raw analysis signals. Without shaping, per-band parameters driven by raw luminance would jitter every frame. The shaped signal gives the patch's response to its own content a feeling of intention rather than noise. Sits downstream of any analysis utility — not tied to profile specifically.

**Broader utility family named:**
Centroid, variance, dominant frequency, motion energy, regional contrast — all captured with initial evocations and design notes. Common thread: most interesting outputs preserve some spatial structure rather than collapsing to a scalar.

**Design gaps identified to hold:**
- Temporal structure (rate of change, periodicity) — easy to miss when thinking in pictures
- Signal relationships (ratios/differences between analysis outputs)
- Signal conditioning — gap between raw GPU output and useful control signal

**Scratchpad updated:**
- `f_util_profile` entry replaced with pointer to `ideas/f_util_analysis.md`
- Gap 1 (texture analysis) in capability gaps section replaced with pointer

---

## Recommended next session

### First: tech debt assessment
Now that conventions are solidifying and ideation for new patchers is accelerating, begin by auditing existing patchers against current thinking. Known axes of debt:

- **`prepend param` → `attrui`** — convention changed forward-only; existing patchers still use old wiring
- **Dual-mode (`vs_inState`)** — identified candidates (f_grain, f_masonry) not yet evaluated against current pattern
- **Texture inlet opportunities** — structural modulation targets identified per-patch in scratchpad; none implemented yet
- **Bypass pattern** — verify all patchers use current bypass JSON convention
- **UI/parameter surface** — older patchers may predate current parameter naming and range conventions

Goal: produce a prioritized debt inventory before starting any new patch work. Decide which debt is worth paying now vs. accepting as legacy.

### Then:
1. **f_lens Phase 5** — Vsynth integration testing (longest-standing deferred item)
2. **f_util_profile** — begin speccing concretely; first decision is consumption pattern downstream (how does f_weave actually read the 1×N matrix?)
3. **f_util_envelope** — spec alongside profile; needed immediately once profile produces raw signal
4. **f_chladni signal chain** — EEG/spectral driving via muse.maxpat

---

## Files changed this session
- `ideas/f_util_analysis.md` — created (new file)
- `ideas/scratchpad.md` — f_util_profile and Gap 1 entries replaced with pointers
- `HANDOFF.md` — this file
