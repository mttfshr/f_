# HANDOFF — f_ session 2026-06-18

## What was done this session

### Plan cleanup
- Marked regression audit fully complete (hue_processor, masonry fixed last session; stereo and droste confirmed fine by hand)
- Marked f_vf_glow as built (was still in queue)
- Removed stale regression audit section from plan.md
- Work queue updated: f_chladni scratch patch now #1

### f_chladni — full build cycle complete

All tasks T100–T120 complete. Summary of decisions and findings:

**Scratch patch** (`/Users/matt/Vsynth/patterns/chladni-scratch.maxpat`)
- Mode A (linear interp between adjacent Bessel modes) and Mode B (Gaussian resonance snap) both working
- Mixed-geometry approach confirmed: blending both radial envelope and angular order simultaneously works cleanly, no artifacts
- Mode distinction is subtle at default params; emerges with specific param combinations; both modes retained
- Full MIDI range 0–127 correct convention; scaling happens upstream
- Mode B: `spread` useful range 0.1–0.5; below 0.1 produces white artifacts between modes (accepted as floor, not fixed)
- `ph0` retained — useful even in single-mode operation
- Dual outlet confirmed: luma (out1) + float32 vecfield (out2)

**Key technical discoveries**
- User-defined functions work in jit.gl.pix GPU codebox path (no `def` keyword — bare `funcname(args) { ... }` syntax)
- Functions must be declared before all Param statements and main body
- Params are not accessible inside function bodies — must be passed as arguments
- Used this to implement correct central-difference gradient: `modal_A` and `modal_B` helper functions called 4× each for offset UV sampling

**Vecfield gradient**
- Central difference at `eps=0.004` (same as fieldmap, confirmed good resolution)
- Gradient is mode-aware: `modal_B` function used for gradient when `mode=1`, so vecfield tracks luma correctly including spread param
- Encoded as float32 RG: normalized gradient direction, 0.5=zero

**Build and audit**
- `tools/build_patcher.py` ran clean
- Audit: f_chladni passes with no warnings
- Consumer verification: chladni vecfield → f_lens + f_vf_glow + f_vf_advect chain confirmed working beautifully in Max

**Commits this session**
- `e98083c` f_chladni: reframe as single-resonance MIDI transducer with dual outlet
- `14dfe3b` f_chladni: vecfield gradient now mode-aware
- `a786dc3` f_vf_fieldmap: Max resave formatting only

---

## Priorities for next session

Reading order: .specify/plan.md → HANDOFF.md

1. **UI density discovery** — design research phase; blocks f_util_matrix jsui and composite dials
2. **f_vf_mix experiments** — try vs_mixer_3_avg and vs_op2 for vecfield blending; build only if encoding breaks down
3. **f_vf_diverge experiment** — try `f_vf_glow → f_vf_fieldmap` recipe with negated strength; build only if recipe has clear gap

---

## Loose threads

- f_chladni companion patches not yet built (sigmund → note/amp, analog CV → note/amp, OSC → note/amp)
- f_chladni helpfile not yet written (parked until pre-release pass)
- f_vf_normal: test `jit.gl.bfg` direct wiring before building
- f_vf_optical_flow: frame diff + fieldmap approximation worth a scratch patch test before committing
- Audit script: patcher-inlet → attrui path tracing still not recognized (f_droste time_s false positive)
- f_vf_advect audit flag: multi-pix architecture not traceable by audit script (known limitation)
- EEG companion patch note mapping: weighted centroid vs. highest-amplitude band — decide empirically
