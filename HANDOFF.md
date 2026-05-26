# f_ — Handoff

_Session: 2026-05-26_

## What was done this session

**f_chladni Phase 0 + Phase 1 complete:**
- Renamed `f_cymascope.maxpat` → `f_chladni.maxpat` (T001–T005)
- Codebox patched: ph0 repurposed as global phase offset, added to all 8 modal angular terms (T006–T008)
- `docs/f_chladni.md` updated: source file, ph0 description, parameter table split (ph0 vs ph1–ph7)

**f_chladni_audio.maxpat built (Phase 2, T009–T017):**
- Filter bank: `inlet~` → `biquad~ ×8` → `abs~` → `slide~` → `*~` → `snapshot~` → `prepend mXamp` → `outlet`
- Two frequency sets computed and stored as message boxes: Log (80Hz–8kHz, ~0.95 oct/band) and Bessel (f0=A3=220Hz, Bessel-zero ratios, 220–1014Hz)
- Coefficients normalized to unity gain at center frequency (b0=1, b2=-1, a1/a2 per band)
- Umenu toggles Log/Bessel by banging the appropriate coefficient message boxes into unpack → biquad~ inlets 2–6
- Master gain via `number~` into all 8 `*~` right inlets
- `meter~` per band for visual monitoring
- Outlet contract: `inlet~` mono audio in; `outlet` message out → `m0amp`–`m7amp` floats at ~20ms

**f_chladni control inlet added:**
- Second inlet added to `f_chladni.maxpat` (obj-76), wired to route object (obj-8)
- Parent patch: `ezadc~` → `f_chladni_audio` in~ → outlet → `f_chladni` control inlet 2

**Spec updated:**
- Outlet contract documented in `.specify/f_chladni/spec.md`
- Signal chain corrected: peakamp~ → abs~ (peakamp~ outputs float, not signal)
- Frequency set tables added to spec
- T009–T017 marked complete in tasks.md

## First thing next session

Open `.specify/f_chladni/tasks.md` → T018 (formal mic test: verify all 8 bands differentiate with music/speech) and T019 (tuning toggle test: Log vs Bessel swap verified live). Then pivot to next patcher.

## Loose threads

- **loadbang init**: coefficients don't load automatically on patch open — loadbang → select → log message boxes path not firing reliably; workaround is clicking umenu. Needs investigation.
- **T020+**: EEG companion patch still pending; Muse calibration pass needed first
- **f_droste**: needs autopattr added (`.specify/f_droste/tasks.md`, 3 tasks)
- **Scope review**: optics family vs circular screen prioritization still pending
- **Help patches**: none exist for any bpatcher; f_texrouter first
