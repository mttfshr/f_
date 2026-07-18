# Feature Specification: f_vf_vorticity

**Created**: 2026-07-06
**Status**: Draft

---

## Concept

A standalone vecfield-to-vecfield processor implementing vorticity confinement
(GPU Gems 1, Ch. 38, S:38.5.1 — Harris/Stam). Consumes an f_vecfield, computes
its vorticity (curl), and adds a small corrective force — perpendicular to the
gradient of vorticity magnitude — back into the field. This restores fine-scale
swirling motion that gets washed out by numerical/grid dissipation, without
requiring a full diffusion/projection solve (which `f_vf_advect` deliberately
omits as too expensive — 20-80 Jacobi iterations per timestep, non-goal per
`ideas/vorticity_confinement.md`).

Fits the vf_ family's producer/consumer composability: takes any f_vecfield in
(vortex, repulse, flow, fieldmap, or another vf_ processor's output), outputs
an enhanced f_vecfield. Works upstream of `f_vf_advect` or any other vecfield
consumer — not advection-specific.

`confinement` reads as a turbulence-amount knob (Matt's call, 2026-07-06) —
a prominent expressive control, not a subtle detail-restoration afterthought.

---

## User Stories

### User Story 1 — Restore swirl detail on any vecfield source (Priority: P1)

A performer connects any f_vecfield source (vortex, repulse, flow) and gets
back an enhanced field with visible small-scale swirling character that the
source alone doesn't produce.

**Why this priority**: Core value proposition — without this the module has
no reason to exist.

**Independent Test**: Connect `f_vf_vortex` (single fixed-point field, smooth
by construction) to in1. At `confinement = 0`, output should be visually
identical to input. Raising `confinement` should introduce visible fine-scale
swirl distortion not present in the source.

**Acceptance Scenarios**:
1. **Given** `confinement = 0`, **When** viewed against any source, **Then**
   output field is (near-)identical to input field
2. **Given** `confinement` raised, **When** viewed, **Then** fine-scale swirl
   detail appears, increasing with the parameter
3. **Given** `bypass` engaged, **When** viewed, **Then** output field is
   identical to input field

### User Story 2 — Turbulence-amount as a prominent expressive control (Priority: P1)

A performer treats `confinement` as a primary character dial during a live
set — not a corrective/cosmetic knob — and its range is calibrated to feel
meaningfully different across its full sweep.

**Why this priority**: Confirmed 2026-07-06 — `confinement` is meant to read
as "how much turbulence," a headline control for this module, which affects
UI prominence and how its range should be tuned once in scratch testing.

**Acceptance Scenarios**:
1. **Given** low `confinement`, **When** viewed, **Then** output reads as a
   gentle roughening of the source field
2. **Given** high `confinement`, **When** viewed, **Then** output reads as
   strong, chaotic-feeling turbulent character, clearly distinct from low end
3. **Given** the same `confinement` value across different source fields
   (vortex vs. repulse vs. flow), **When** compared, **Then** perceived
   strength may differ (baseline vorticity differs by source — this is
   expected, not a bug; per-source range tuning happens in scratch testing,
   not in this spec)

### User Story 3 — Composability upstream of any vecfield consumer (Priority: P2)

A performer chains `f_vf_vorticity` between a vecfield producer and any
consumer (`f_vf_advect`, `f_caustic`, `f_vf_warp`, `f_lens` field inlet, etc.)
with no special-casing required.

**Why this priority**: Validates the standalone-processor architecture
decision (2026-07-06) — the module must behave as a transparent, drop-in
`f_vecfield`-typed link in a chain, not something coupled to a specific
downstream consumer.

**Acceptance Scenarios**:
1. **Given** `f_vf_vortex` → `f_vf_vorticity` → `f_vf_advect`, **When**
   viewed, **Then** the chain produces plausible advected, turbulence-
   enhanced flow with no type errors or visual artifacts at the seam
2. **Given** `f_vf_vorticity` output patched directly into `f_caustic`'s
   field inlet, **When** viewed, **Then** caustic structure responds to the
   enhanced field exactly as it would to any other f_vecfield source

---

## Requirements

### Functional Requirements

- **FR-001**: Module MUST consume a float32 RG f_vecfield texture on in1
  (0.5 = zero vector, per `docs/f_vecfield_type.md` contract)
- **FR-002**: Module MUST compute vorticity (scalar curl) from the input
  field via finite differences
- **FR-003**: Module MUST compute the normalized gradient of vorticity
  magnitude
- **FR-004**: Module MUST construct a corrective force perpendicular to that
  gradient, scaled by `confinement`
- **FR-005**: Module MUST add the corrective force to the input field and
  output the result as a valid f_vecfield (RG, 0.5 = zero vector convention
  preserved)
- **FR-006**: `confinement = 0` MUST produce output identical (within finite-
  difference floating point tolerance) to the unmodified input field
- **FR-007**: Module MUST provide exactly one texture inlet (vecfield in) and
  one texture outlet (enhanced vecfield out) — no source/light texture, no
  composite/isolated-layer split (unlike `f_vf_glow`/`f_caustic`, this module
  transforms the field itself, it does not composite over an image)
- **FR-008**: `bypass` MUST restore the input field unmodified on the outlet

### Non-Functional Requirements

- **NF-001**: Module MUST draw to `@drawto vsynth` GL context
- **NF-002**: Inlet/outlet type: float32 RG, per f_vecfield contract (not
  `@type char` — this is a vecfield producer/processor, not an image processor)
- **NF-003**: Finite-difference neighbor sampling MUST use `dim`-derived texel
  offsets, consistent with `f_caustic`'s divergence calc and the Sobel idiom
  already used in `f_vf_repulse`
- **NF-004**: Performance target: 60fps at standard Vsynth live-performance
  resolutions, alongside other simultaneously-running `f_` modules
- **NF-005**: All params registered in `parameters` block; autopattr present
  for state save
- **NF-006**: Follows vsynth-bpatcher skill conventions throughout

---

## Parameter Contract

| Param | Type | Range | Default | Description |
|---|---|---|---|---|
| `confinement` | float | TBD — calibrate in scratch testing | TBD | Turbulence amount. 0 = no effect (pass-through field). Headline expressive control, not a subtle correction. |
| `bypass` | float | 0.0 – 1.0 | 0.0 | Standard bypass — output = unmodified input field |

Range and default for `confinement` are explicitly deferred to scratch
testing (per User Story 2, Acceptance Scenario 3) — baseline vorticity
varies ~significantly by source field, so a single fixed range risks being
wrong for at least one source. Test against vortex, repulse, and flow before
committing to numbers here.

---

## Success Criteria

1. `confinement = 0` is visually and structurally indistinguishable from
   passthrough, on at least two different source fields
2. Raising `confinement` produces a visible, legible increase in fine-scale
   swirl/turbulence character, distinct from the source field's own topology
3. The full `confinement` sweep (low → high) reads as a meaningfully
   different range of turbulence character, not a narrow band where most of
   the range looks the same
4. Module composes cleanly upstream of `f_vf_advect`, `f_caustic`, and
   `f_vf_warp` with no special-casing at any seam
5. 60fps maintained at standard live-performance resolution alongside at
   least one other simultaneously-running `f_` module

---

## Edge Cases

- **Uniform/constant field input** (including `vs_black` fallback, which
  remaps to a constant (-1,-1) per f_vecfield convention): spatial
  derivatives of a spatially-uniform field are zero everywhere, so vorticity
  = 0 and the corrective force = 0 — output equals input with no special-
  case handling required. This is a structural consequence of the math, not
  something that needs an explicit fallback branch (contrast with
  `f_vf_glow`, which does need explicit suppression logic for the same
  `vs_black` case).
- **Field singularities** (e.g. a vortex's fixed point): vorticity is
  expected to spike near a singularity. Behavior there is UNVERIFIED —
  needs a scratch-test check that the corrective force doesn't blow up or
  produce NaNs at/near the singularity before this is considered settled.
- **Very high `confinement`**: expected to eventually produce visually
  chaotic/unstable-looking output. Whether there's a practical ceiling
  before the field becomes unusable (vs. NaN/instability) is UNVERIFIED,
  to be found empirically during scratch testing.
- **Chained with `f_vf_advect`'s `decay > 1.0` "excitable/amplifying" mode**:
  both mechanisms independently add energy/swirl to a field. Whether they
  compound in a controllable way or fight each other is UNVERIFIED —
  worth a specific scratch test once both modules can be chained.

---

## Open Questions (carried from `ideas/vorticity_confinement.md`)

- Whether the curl computation and the vorticity-gradient computation can
  live in one `jit.gl.pix` codebox, or need to split into a multi-stage
  chain (curl → scalar texture → second pass samples curl's neighbors for
  the gradient) — likely the latter, since the gradient step needs curl
  already computed at neighboring texels, not just the current pixel. This
  is a plan.md / architecture question, not resolved here.
- Exact `confinement` param range and default — deferred to scratch testing
  per above.
