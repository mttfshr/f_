# f_ — Project Plan

_Last updated: 2026-06-17_

This document is orientation, not execution. It names active workstreams, states current thinking on sequencing and priority, and surfaces open questions that need a decision before work can proceed. Per-module task detail lives in `.specify/f_name/tasks.md`. Session-specific state lives in `HANDOFF.md`.

---

## Work queue — current thinking

1. **f_chladni scratch patch** — T100–T106; test linear vs. resonance snap mode selection; determine expressive MIDI range.
2. **UI density discovery** — design research phase; blocks f_util_matrix jsui and composite dials implementations
3. **Vecfield consumer: masking** — evaluate performance need before speccing; don't build infrastructure for its own sake

---

## Workstreams

### Helpfile pass
Tooling is operational — `tools/generate_helpfiles.py` with API-based generation. 18 helpfiles generated covering all current modules except f_vf_vortex_multi, f_vf_advect, and f_texrouter (postdate the generation run). f_droste.maxhelp remains the canonical hand-built template; conventions documented in the `f-helpfile` skill.

Refinement is an open creative thread, not a task queue item. Some helpfiles will want purpose demonstrations — showing not just what a module does but *why* to use it and what it sounds like in a signal chain. Tinkering and evaluation will surface which ones need this treatment. The three missing helpfiles can be generated when the time is right.

### Vecfield consumer ecosystem
Producers: `f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_fieldmap`. Consumers: `f_caustic` (convergence accumulation), `f_vf_warp` (UV displacement), `f_vf_streak` (directional blur), `f_vf_advect` (temporal fluid advection), `f_vf_glow` (field-aligned directional blur).

**f_vf_glow** is built — field-aligned directional blur, single-pass. Temporal feedback extension (anisotropic decay along field) is architecturally interesting but deferred; evaluate whether it's visually distinct from ordinary feedback before building.

Masking (`f_vf_scalar` — magnitude/divergence/curl/angle as scalar outputs) is further out; evaluate performance need before speccing. Don't build infrastructure for its own sake.

### f_chladni / f_cymascope — audio-to-vecfield family
Both patches are audio-to-vecfield transducers: f_chladni via modal superposition (Bessel basis, stateless/analytic), f_cymascope via FDTD wave propagation (temporal state, ping-pong texture). The shared signal chain is `audio → [f_chladni | f_cymascope] → f_vecfield → f_caustic → visual`. With this framing established, the refactor work is:

1. **f_chladni** — reframed (2026-06-17) as a single-resonance transducer. Interface is `note` (MIDI) + `amp` (envelope) rather than 8 independent band amplitudes. Dual outlet: luma (nodal lines) + float32 f_vecfield (gradient of modal field, pointing toward nodal lines). Scratch patch first to decide between linear interpolation and resonance snap mode selection. See `.specify/f_chladni/` for full spec, plan, tasks.
2. **Companion patches** — simplified to supply `note` + `amp` only. Audio: sigmund~ → note, peakamp~ → amp. EEG: dominant band or weighted centroid → note, total power → amp. Design deferred until bpatcher architecture verified.
3. **f_cymascope** — build after f_chladni proves the vecfield outlet pattern, and after f_vf_advect establishes the multi-pix bpatcher convention. Three chained pix (Pattern 1 extended). See `docs/max-reference/temporal_synthesis_architecture.md` and `ideas/f_cymascope.md`.

### Hyperbolic / non-Euclidean geometry
`f_mobius` is built and working. `f_poincare` (Poincaré disk model) and `f_sharmonics` (spherical harmonics) follow. Next step: promote `f_poincare` and `f_sharmonics` to their own `ideas/` files so the sequence is grounded and open questions are captured before we reach them.

### Build system generalisation
**Complete.** `build_patcher.py` now supports:
- `outlets` — multi-outlet with tricolor labels
- `vs_instate: False` — per-inlet vs_inState bypass
- `pix_chain` / `pix_wires` — multi-pix bpatchers with cross-pix feedback wiring
- `range_tiers` — dial range selector with compact live.menu toggle

Per-module scripts fully retired. All modules buildable from `definition.py` alone. `build_advect.py` in `.specify/f_vf_advect/` is superseded — delete when convenient.

### Temporal synthesis
**Discovery complete and first module done** — see `docs/max-reference/temporal_synthesis_architecture.md`.

The fundamental pattern (Pattern 1) is two chained jit.gl.pix inside one bpatcher: a `pass_pix` (identity, holds previous state) and a `state_pix` (reads current input + previous state from pass_pix). The GL pipeline's one-frame latency makes the loop stable without explicit buffer management.

Members and status:
- ~~**f_vf_advect**~~ — done. Pattern 1, one historical frame. Integration tested.
- **f_cymascope** — Pattern 1 extended (three pix, two historical frames). Build after f_vf_chladni refactor.
- **f_vf_smear** — try single-pass LIC first; Pattern 1 only if insufficient.
- ~~**f_vf_glow**~~ — done. Single-pass, field-aligned directional blur.
- **f_ganzflicker / f_dreamachine** — not a texture feedback problem; phase lives in audio/signal domain.
- **f_util_envelope** — not a texture feedback problem; scalar smoothing via Max bline/slide.

### UI density / control surface design
The general question: how do we achieve higher information and control density in the patcher UI — making parameter relationships clear while keeping things intelligible — within the constraints of the bpatcher context? This is a design discovery phase that blocks two downstream workstreams:

- **f_util_matrix jsui** — the modulation routing grid needs a clear visual language for routing relationships
- **Composite dials** — grouped/related parameters may warrant custom jsui widgets that express their relationships rather than independent live.dial instances

Discovery should explore what's possible and expressive in jsui within Max's bpatcher context, survey what Vsynth and other packages do, and produce a small set of design principles or prototypes before either implementation begins. This is deliberately pre-spec — the output is clarity about the design space, not a task list.

### Infrastructure: f_util_matrix
Modulation routing matrix — working implementation exists. Refinement is the goal, not initial build. The jsui routing grid and context strip UX could both benefit from higher UI density, but further work on this is **blocked on the UI density discovery phase**. Don't touch it until that discovery closes.

---

## Parked

- **Helpfile refinement** — ongoing tinkering; some modules will want purpose demonstrations; not a task queue item
- **f_util_profile dual-axis output** — works as-is; extension is a nice-to-have
- **f_raster** — resolution as expressive parameter; good idea, no urgency
- **Entrainment / perceptual work** (`f_ganzflicker`, `f_dreamachine`) — design research phase only; Muse Athena EEG integration available but don't build until design is grounded
- **f_vf_streak color_shift v2** — full 2D field vector shift noted as potential improvement; parked pending a clear expressive need
- **f_vf_scalar / masking** — evaluate performance need before speccing
