# Plan: f_chladni Refactor

_Last updated: 2026-06-17_
**Spec**: `.specify/f_chladni/spec.md`

---

## Summary

Reframe f_chladni from an 8-mode manual amplitude generator to a single-resonance audio-to-vecfield transducer. The bpatcher receives `note` (MIDI) and `amp` (envelope) and selects/scales one dominant Bessel mode. A second outlet produces a float32 f_vecfield encoding the gradient of the modal field. Architecture decisions depend on scratch patch results before any build work.

---

## Technical Context

**Platform**: Max 9 + Vsynth
**Build**: `tools/build_patcher.py` from `definition.py`
**Artifacts**: definition.py (rebuilt); f_chladni.maxpat (rebuilt); companion patches (hand-built in Max)
**Testing**: Visual verification in Max; vecfield outlet verified via f_caustic routing

---

## Architecture Decisions

### Decision 1: Single resonance, not 8-band superposition
One dominant mode selected by MIDI pitch input. Physically faithful to real Chladni plates. Produces sculptural behavior — pattern has identity, reorganizes between modes — rather than a complex superposition that reads as a visualizer.

Rejected: 8 independent amplitude params driven by filterbank (previous architecture). Reasons: too direct a spectral mapping, requires calibrated companion patch, produces visualizer character rather than sculptural object.

### Decision 2: MIDI as canonical input unit
`note` param (0–127) is the interface. Upstream companion patches or routing objects convert from any source (sigmund, OSC, CV, manual) to MIDI. Decouples bpatcher from audio analysis strategy.

### Decision 3: Mode selection behavior — determined by scratch patch
Two candidates:
- **Linear interpolation** — smooth blend between adjacent modes as note moves
- **Resonance snap** — falloff curve centered on each Bessel zero; pattern has strong mode identity

Both implemented in scratch patch; decision made empirically. A `spread` or `snap` param may emerge as useful.

### Decision 4: Dual outlet — luma + vecfield
Out 1: luma (nodal line pattern, existing behavior).
Out 2: float32 f_vecfield — gradient of `total` pointing toward nodal lines.

Vecfield outlet moves from "deferred" (previous spec) to "core" in this revision. The gradient is computed via numerical differencing of `total` at UV offsets — simpler than symbolic differentiation, equivalent at shader resolution.

### Decision 5: Circular geometry only
Rectangular/sine-mode boundary is a separate module. Strip view mode retained for f_stereo routing. No mode switch for plate shape.

### Decision 6: Companion patches supply note + amp only
Previous companion patches supplied 8 amplitude messages. New interface is two values: `note` and `amp`. Companion patch design is deferred until bpatcher architecture is verified.

---

## Dependency Blocks

```
Block 0: Scratch patch → determines mode selection behavior and MIDI range
Block 1: definition.py rewrite → depends on Block 0 decisions
Block 2: Build + verify bpatcher → depends on Block 1
Block 3: Vecfield outlet verification → depends on Block 2 (needs f_caustic routing)
Block 4: Companion patches → depends on Block 2 interface being stable
Block 5: Docs + registration → wraps up all blocks
```

---

## Implementation Phases

### Phase 0: Scratch Patch
Build a minimal `jit.gl.pix` scratch patch (not using build system) with:
- `note` param (0–127)
- `amp` param (0–1)
- `dishradius`, `reflectamt`, `linesharpness` carried over
- Mode A: linear interpolation between Bessel zeros
- Mode B: resonance snap with falloff width param
- Luma output only (vecfield deferred to Phase 2)

Evaluate: which behavior is more sculptural, what MIDI range is expressive, whether `spread` param adds value.

**Deliverable**: written notes in `.specify/f_chladni/scratch_notes.md`; decisions recorded as ADRs in this plan.

### Phase 1: Definition Rewrite
Rewrite `.specify/f_chladni/definition.py` with:
- New param set: `note`, `amp`, `dishradius`, `reflectamt`, `linesharpness`, `view_mode`, `ph0`, `bypass`
- Optional: `spread` (if scratch patch warrants it)
- Two outlets: luma (out1), vecfield float32 (out2)
- Codebox implementing chosen mode selection behavior + vecfield gradient

### Phase 2: Build + Verify
- Run `tools/build_patcher.py`
- Verify in Max: note input selects mode, amp scales output, ph0 shifts pattern, view_mode blends
- Run audit_interface.py; resolve any issues

### Phase 3: Vecfield Outlet Verification
- Route out2 → f_caustic; verify convergence accumulates at nodal lines
- Route out2 → f_vf_warp; verify source texture warps toward nodal lines
- Document signal chain recipes

### Phase 4: Companion Patches
- `f_chladni_audio.maxpat`: sigmund~ or pitch follower → note; peakamp~ → amp
- `f_chladni_eeg.maxpat`: dominant band → note; total power → amp
- Design EEG note mapping (weighted centroid vs. highest-amplitude band — decide empirically)

### Phase 5: Docs + Registration
- Update `docs/f_chladni.md`
- Register in f_modules, f_addmod.js if signal_type changes
- Update README if needed
- Update HANDOFF.md
