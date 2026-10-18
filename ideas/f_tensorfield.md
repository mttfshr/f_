# f_tensorfield — tensor field family hub

_Created 2026-10-10; rewritten 2026-10-17 as the active working doc. Sibling to `f_vecfield.md`
and plays the same role: the family's hub, not a build plan for any one module._

**Companions:** unbuilt candidates and their entry conditions: `ideas/f_tf_backlog.md`. Evidence,
prior art and the platform audit: `ideas/f_tf_research.md`. Encoding contract:
`docs/f-reference/f_tensor_type.md`. Per-module specs: `.specify/f_tf_<module>/`, as-built
references: `docs/f-reference/f_tf_<module>.md`.

**Outlet numbering in this doc is 0-based and matches the built modules:** tensormap outlet 0 =
raw tensor, outlet 1 = packed. Older notes (and some `.specify/` history) count from 1 and call
the packed outlet "outlet 2"; read those with that offset.

---

## Origin

Prompted by `vector_field_math_concepts.md` #9: a vector answers "which way"; a tensor answers
"which way, and how much does that mean here". Some phenomena, unoriented line fields chief
among them, are not vector-field problems at all. A structure tensor is an **unoriented line
field** with confidence, so forcing it into a vecfield either invents a sign (a hard seam) or
hides tensor data in unused vecfield channels, which was rejected: it would create two
ordinary-looking vecfields that are not interchangeable (the bug shape
`module_taxonomy_standardization.md` already caught once).

## Module status (as of 2026-10-17; the README rows and HANDOFF are the source of truth)

Verification tiers: 1 = NumPy mirror, 2 = Max test bench (+ module contract bench), 3 = live
judgment in a scratch patch. All seven are registered (menu, README, launcher, inventory).

| Module | Role | Tier 1 | Tier 2 | Tier 3 / open gates |
|---|---|---|---|---|
| `f_tf_tensormap` | Producer: raw (0) + packed (1) | done | 8/8 | Done, live-checked 10-16 |
| `f_tf_axisflow` | Bridge: packed tensor to seam-free vecfield | done | 5/5 | Done; drove `f_vf_advect` live. v2 ideas in backlog |
| `f_tf_smooth` | Operator: one-pole temporal smoother | green | 6/6 | `release` default and range (T016) |
| `f_tf_glyph` | Consumer: glyph field, family debug tap, **canonical decode idiom** | 14/14 | 6/6 | Variant menu and debug tints (look); defaults provisional |
| `f_tf_sharpen` | Operator: eigengap exaggerate / relax, trace fixed | 15/15 | 6/6 | Dial mapping (0-4 one-sided vs bipolar vs log) and possible rename (T016/T017) |
| `f_tf_aniso_blur` | Consumer: structure-aligned smoother, straight-axis v1 | 19/19 | 6/6 | Kernel family (b) only if the cost experiment says (a) is not enough; defaults; curved-corner artifact look; strength pairing (Q16) |
| `f_tf_hatch` | Consumer: orientation-committed hatching, branch T | 20/20 | 6/6 | Commit-curve shape; hairpin hazard probe (needs bench); defaults; NaN masking question (Q17) |

Cross-cutting open items: the helpfile judgment gate for the five new helpfiles (yours), and
whether the five benches join `bench.sh DEFAULT`. Cost: hatch measures about 0.2 ms/pass per
stage at 1080p (M3 Max upper bounds, M1 unmeasured). Some `tasks.md` checkboxes and the
reference docs' Status lines still say "bench pending" after the 10-17 sweep; the benches did
pass.

## Decisions

Resolved; each is recorded where it is implemented. Change one only by an explicit review.

- **Not a vecfield; two outlets, one computed pass** (2026-10-13, Matt). Outlet 0 = raw
  `Jxx*s, Jxy*s*0.5+0.5, Jyy*s, 1` (lossless, unclamped float32); outlet 1 = packed
  `cos2t, sin2t, trace, coherence`. The decoded-convenience packing came from consumers wanting
  direction+anisotropy (stipple) or trace+anisotropy (glow) together. Name `f_tf_tensormap`,
  prefix `f_tf_` (2026-10-16).
- **Sign-sensitive consumers go through `f_tf_axisflow`; never feed outlet 1 R/G straight in**
  (`f_tensor_type.md` rules 1-2). Angle-doubling fixes storage continuity only: decoding
  `0.5*atan2` confines theta to (-pi/2, pi/2], so a near-vertical axis flips sign.
- **Focus on full-tensor consumers and operators; views are support** (2026-10-16). Triage
  (2026-10-17): build smooth, glyph, sharpen, aniso_blur, hatch (done); mix waits for chain B;
  glow merges into Q12; glint, jacobian, motion, hessian, authored deferred (backlog).
- **Per-consumer in-pixel decode; no `f_tf_decode` module** (2026-10-17). The canonical idiom is
  `.specify/f_tf_glyph/plan.md` ADR-2. The lambda/coherence block is copied verbatim; axis
  recovery varies: glyph and hatch use `atan2`, while sharpen and aniso_blur use half-angle
  identities and need none. Consumers read outlet 0 exactly; feeding outlet 1 is a wiring error.
- **`atan2` is GPU-safe on decoded sampled input** (2026-10-12): max error 5.6e-7 rad, wraps
  correctly at the branch cut, with one benign +pi vs -pi difference at `Fy == 0, Fx < 0`.
  Runtime `atan2(0,0)` is NaN though (`f_tf_research.md` section 6).
- **`f_vf_seeds` and `f_vf_potential` are sign-sensitive** (confirmed from their codeboxes,
  2026-10-16). Seeds builds its frame from a full-angle basis, so outlet 1 R/G needs
  decode-and-redouble regardless of phase or shape; potential's increment is magnitude-only but
  its backward-advect lookup depends on direction, so an axis field corrupts the temporal trail.
  Both are on the exclusion list below.
- **Survey phase (Phase 1) closed 2026-10-16.** Phase 2 (per-module finesse) is deliberately
  narrow; see Scope.
- **Modules in `.specify/paused/` are excluded from analysis** (README session rule, 2026-10-11).
  A check of every paused module found no unblock from tensor fields: their stalls are algebra
  bugs (`f_apollonian`/`f_poincare`, ADR-8), a Vsynth render-to-texture limit (`f_stereogram`), a
  loop architecture question (`f_vf_chroma` draft), a codebox-split question (`f_vf_vorticity`),
  or not blocked at all (`f_focus`). None is a representation problem.
- **Producer design history lives in the tensormap spec** (`.specify/f_tf_tensormap/spec.md`) and
  reference (`docs/f-reference/f_tf_tensormap.md`, including "Calibration by input type").
  The 2026-10-10 spike (`tests/records/spike_structure_tensor_range.py`) fixed the `strength` regime;
  the shipped default is 100. Gradient operator: Sobel (the verified `f_vf_sobel` kernel);
  Scharr comparison deferred until a consumer proves Sobel too soft for fine structure.

## Scope: what Phase 2 is

Raised by Matt 2026-10-11: the opportunity may be library-wide, with more intuitive, performative,
per-pixel-responsive control surfaces across most modules, not just "consumers that happen to take
a vecfield". That splits into two tracks, both live now:

1. **The `f_tf_` consumer family** (built; the table above).
2. **Per-module finesse of existing modules** (`f_vf_glow` Q12, `f_stipple` Q13, `f_grain` Q14).
   Some of it is a deeper rethink of a control surface, not an inlet. Do one module at a time and
   do not start piecemeal because a candidate looks good in survey.

Two existing workstreams constrain track 2 (confirmed by Matt 2026-10-11): the **drift-cleanup**
project (`plan.md` item 6: `definition.py` as source of truth, 32 of 39 patchers reproducing at
last count), because several candidates (`f_vf_seeds`, `f_vf_warp`) are on the never-regenerate
list and would inherit surgical-edit constraints; and the paused **UI-density / control-surface**
workstream (`ideas/mod_depth_ui_density.md`), which may be the same direction as track 2 and
should be decided together with it, not independently.

---

## Open questions

Numbering is kept from earlier notes because specs and tasks cite it. Resolved questions moved to
Decisions: Q1 (strength range, now calibrated in the tensormap reference), Q2 (packing), Q4
(naming), Q5 (first consumer; superseded by the builds), Q6 (`atan2`), Q9 (seeds), Q11 (potential).

**Q3. Gradient operator.** Sobel today; Scharr deferred (see Decisions). Not blocking.

**Q7. Mod-texture unipolar vs bipolar convention (inherited).** `named_mod_textures.md` already
flags the divergence between `f_masonry` (unipolar) and Kevin's `vs_displacement` (bipolar). The
final range of the trace/anisotropy channels cannot be locked until each consumer's inlet
expectation is read.

**Q8. Could named-mod-texture tags double as a type declaration?** Tagging by *type*
(`vecfield_flow`, `vecfield_axis`, `tensor_raw`) as well as by role would let a consumer's `route`
demux branch its own decode and close the flow-vs-axis detection gap: nothing today lets a
consumer tell a flow field from an axis field, both being ordinary f_vecfield-contract textures.
Today this is convention, not enforcement. It raises the bar on `named_mod_textures.md`'s open
items (pix-hop failure, untested T4/T6), which would then gate correctness, not convenience. Core
Vsynth modules have no shared inlet to carry a tag, so type-safety there stays documentation-only.

**Q10. Does any real use need the decoded angle, or do `(cos2t, sin2t)` suffice?** For a consumer
whose target is just two independent scalar depths (as with `f_vf_split` fed outlet 1 in bipolar
mode), the raw doubled components avoid `atan2` entirely. Unassessed per module.

**Q12. `f_vf_glow` anisotropy inlet: continuous, per-pixel `direction` blend (design done,
build parked).** The first Phase 2 module, chosen because it needs no new panel dial and so is
not behind the UI-density question. Triage merged the proposed `f_tf_glow` into it. Tasks T039-T043
in `.specify/f_vf_glow/tasks.md` are all unticked. Design, grounded in `codebox_v1.gen`:

- `fwd_mode`/`bwd_mode` are already branchless from `direction`. The change continuizes the
  weight reaching the loop; `direction` keeps its meaning and default.
- Touches only outlet 1's coherence (A) channel: a confidence gate on the existing vecfield
  inlet, not a rewiring of the direction source (the R/G decode problem stays out of scope).
- New `mod_inlets` entry, no new dial, following `radius mod`'s precedent:
  `{"label": "anisotropy", "state_param": "src_anisotropy"}` (a fourth texture inlet, `in4`).
- **Connection detection must use `state_param`, not a content heuristic.** An unconnected
  texture inlet samples 0, but this gate's neutral is 1.0 (full confidence, reproducing today's
  behavior). Glow's vecfield inlet gets away with a content heuristic only because 0 is also the
  right neutral for a flow field.
- Codebox, with the coherence read corrected to `.w` (tensormap outlet 1 carries coherence in A and
  trace in B):

  ```c
  Param src_anisotropy(0.0);
  aniso = mix(1.0, sample(in4, uv).w, src_anisotropy);   // 1.0 = full confidence, unconnected default
  fwd_weight = mix(1.0, fwd_mode, aniso);                 // 1.0 = safe bidirectional floor
  bwd_weight = mix(1.0, bwd_mode, aniso);
  ```

- At `direction=0` it is a no-op. At 1/2, low anisotropy pulls the pixel toward the bidirectional
  floor. Linear mix, no curve param (a curve would be a new dial).
- **Deferred:** a performer gain dial on top (waits for UI density); wiring outlet 1 R/G into
  `in2` (needs the seeds-style decode-and-redouble).
- The 2026-10-16 strategy note proposed one live test first (tensormap -> axisflow -> glow in2),
  since axisflow's `gate` already scales flow to zero at low coherence. A dedicated inlet only adds
  a different low-confidence behavior (fall back to symmetric glow instead of none), which is a
  taste call. That test is not recorded as done.

**Q13. `f_stipple`'s `anisotropy` / `angle` as tensor-driven per-pixel params.** Tightest semantic
match in the library (they already mean what the tensor's anisotropy and axis mean, just as global
dials), but it has no mod-inlet machinery for them, so wiring means new base+depth dials: it
inherits the UI-density blocker. Needs two inlets or one packed one, and its own design pass.

**Q14. `f_grain`'s `jitter` / `size_var` as tensor-driven sites.** `f_grain.md` says grains are
already driven by input luminance, but that is unconfirmed against the actual codebox. Read it
before concluding anything; do not assume an easy fit.

**Q15. Anisotropy as a multiplicative confidence gate on mod amount, generalized.** A mod-depth
dial answers performer intent; anisotropy answers local data confidence. Do not collapse them:
`effective_depth(pixel) = depth_dial * anisotropy(pixel)`, so the dial keeps its meaning and the
data side gains branch-cut suppression as a side effect. Q12 is one instance. Where a param has no
depth dial (`f_vf_glow`'s `radius mod`: `radius_eff = clamp(radius + mod_val*radius, 0, 0.3)`), a
performer-facing gain defaulting to 1.0 still beats zero live control. Consequence for
`f_util_mod_texture.md`: does the base/depth/texture triple need an optional fourth element,
the confidence-gate source?

**Q16. Strength is not on the wire (new, 2026-10-17).** Outlet 0's G decode needs the `strength`
tensormap was set to, and the texture does not carry it. Gain-free consumers do not care: glyph is
ratio-only (ADR-5), sharpen commutes with uniform scaling except at its fixed trace floor, hatch is
strength-invariant (all tested). `f_tf_aniso_blur`'s absolute-energy gate does: its own `strength`
param must equal tensormap's, and a x3 mismatch moves the kernel-length weight W from 1.0 to 0.167
on the default kernel (matching gains are bit-identical). This is the one real cost of the
per-consumer-decode decision, and the triage's named fallback, a gain channel from tensormap v2,
is exactly what it would reopen. Options: keep the documented pairing (current, aniso_blur spec
OQ3 option a); carry a gain channel on the wire; or gate on ratios instead of energy. Tier 3
decides (aniso_blur T018); do not fix silently.

**Q17. Hatch E1's NaN masking (new, 2026-10-17, unresolved).** `src/f_tf_hatch/codebox_stage_e1.gen`
computes `theta = 0.5*atan2(2.0*jxy, diff)` without the `+1e-7` denominator bias that glyph's
ADR-2 amendment made the family idiom, then masks with `ca = cos(eff) * (1.0 - iso)`. A `*0`
cannot clear a NaN, which is the pattern the glyph finding says fails. Hatch's zero-tensor bench
row passed (`iso=1`, axis unset, exact), but tensormap's own `mix(NaN, 0.5, iso)` also survives
for unresolved compiler-fold reasons, so a pass does not prove safety. Sharpen and aniso_blur are
`atan2`-free and unaffected; glyph carries the bias. Cheapest resolution: adopt the bias idiom in
hatch, or run one constant-isotropic-tensor probe. Not changed in this docs pass.

---

## Consumer territory: every built module that takes a vecfield input

Audited against `docs/f-reference/module-inventory.md` and each module's
`src/<name>/definition.py` `mod_inlets` (the ground truth `build_patcher.py` builds from), excluding
`.specify/paused/`. "B/A" = outlet 1's trace and coherence channels; "R/G" = its doubled-angle
direction channels.

| Module | Free mod inlet for B/A | Is R/G direction sign-safe? | Confidence |
|---|---|---|---|
| `f_vf_glow` | Yes: `radius mod`, unused | Axis-blind in `direction=bidirectional` (default); sign-sensitive in fwd/back | Confirmed |
| `f_vf_chroma` | Yes, two: `hue mod`, `dispersion mod` | Likely sign-sensitive: R/B offset in opposite directions along the vector | Inferred |
| `f_vf_prism` | Yes, two: `reach mod`, `spread mod` | Likely sign-sensitive: same luma-gated RGB split | Inferred |
| `f_vf_seeds` | Yes: `mod tex` (feeds `size_mod`/`stretch_mod`) | Sign-sensitive; needs decode-and-redouble (Decisions) | Confirmed 2026-10-16 |
| `f_vf_streak` | No | Sign-sensitive (one-directional) | Confirmed |
| `f_vf_warp` | No | Sign-sensitive (single-sample displacement) | Inferred |
| `f_caustic` | No (the vecfield inlet has no connected-state tracking) | Sign-sensitive (backward streamline accumulation) | Inferred |
| `f_vf_advect` | No | Sign-sensitive (temporal accumulation along a direction) | Inferred |
| `f_vf_potential` | No (2nd inlet is `color`) | Sign-sensitive (backward-advect lookup, temporal) | Confirmed 2026-10-16 |
| `f_weave` | No (`in1` already carries the vecfield, `in2` scalar/color) | Sign-sensitive (the known vector-add-renormalize blend bug) | Inferred |
| `f_vf_fluid` | No (the vecfield is the force input, `in1`) | Sign-sensitive; temporal, so a bad sample corrupts persistent state | Inferred |
| `f_vf_split` | No | **Decode-adjacent utility, not an effect**: outlet 1 into bipolar mode yields cos2t and sin2t as scalar textures with no `atan2` | Mechanically obvious once named |

- **Best-positioned B/A targets in the library:** `f_vf_chroma` and `f_vf_prism` (two free scalar
  inlets each, zero new plumbing).
- **Exclusion list.** Outlet 1 R/G must not reach sign-sensitive consumers directly:
  `f_vf_warp`, `f_caustic`, `f_vf_advect`, `f_vf_fluid`, `f_vf_potential`, `f_vf_seeds`,
  `f_vf_streak`, `f_weave`, and (pending confirmation) `f_vf_chroma` / `f_vf_prism`. Drive them
  through `f_tf_axisflow`, whose output is an ordinary vecfield; the decode-and-redouble steps
  mentioned for individual consumers are then not needed.
- `f_vf_vorticity` is paused and unverified project-wide: excluded, not assessed.

### Beyond the vecfield consumers: a three-part heuristic (2026-10-11)

Run against the full module inventory: does a built module (1) fight a vector that secretly has no
sign, (2) want a diagnostic ellipse (Tissot, `vector_field_math_concepts.md` #10), or (3) flatten a
curvature quantity to a scalar? Five hits:

- **`f_caustic`: strongest, with numbers.** It weights by divergence (the trace of the local
  Jacobian), but a fold needs the full Jacobian's eigenvalues. Measured 2026-10-12
  (`tests/records/spike_caustic_trace_vs_jacobian.py`): the trace weight and the local full-Jacobian gain
  have identical top-8% sets at the fold distance d*, so optics_map's "saddle on a fold" scenario
  does **not** occur on this glass. The real gap is in the 53-55% of interior pixels that are
  saddles at d*: trace correlates with photon-count truth at r 0.52-0.69 against the full
  Jacobian's 0.60-0.80. In the focus and defocus partitions they are equivalent. Past the first
  fold (3.5 d*) the one-branch local det gain collapses (r 0.15-0.20, worse than the trace's
  0.46-0.56), so multi-branch handling, not tensor representation, is the binding constraint there.
  Net: a saddle-partition-only fidelity gap, not a blanket one.
- **`f_stipple`:** confirms Q13, the tightest semantic match.
- **`f_stereo`:** same conformal-blend shape as `f_mobius`/`f_droste`; the Tissot diagnostic was
  never run against it (see backlog, `f_tf_metric`).
- **`f_lens`:** prediction only: locally isotropic distortion, so always a circular indicatrix;
  also why optics_map's astigmatism row is stuck at "Research".
- **`f_masonry`:** marginal, by proxy, via adaptive AA (`line_edge_antialiasing.md`).

Everything else in the inventory (tonal grading, routing and utility modules, and the vecfield
producers, which carry a legitimate sign) fits none of the three criteria. Logged so it is not
re-checked.

---

## Cross-references

- `vector_field_math_concepts.md` #9: origin of the thread; #10 Tissot; #11 Jacobian-determinant AA.
- `f_vecfield.md`: the sibling hub and type-contract precedent (float32, RG = XY, 0.5 = zero).
- `module_taxonomy_standardization.md`: the `driving_inlet` distinction and the "two things sharing
  a label" bug shape.
- `named_mod_textures.md`, `f_util_mod_texture.md`, `mod_depth_ui_density.md`: plumbing and UI
  questions behind Q7, Q8, Q13, Q15.
- `f_weave_orientation_blend.md`: the 2-theta encoding is the correct fix for weave's blend bug;
  its `atan2` blocker is closed. `f_anamorph_unnamed.md`: same line-not-direction problem.
- `optics_map.md`: caustic fidelity measurements; photoelastic and astigmatism rows.
- Spikes: `tests/records/spike_structure_tensor_range.py`, `tests/records/spike_atan2_safety.py`,
  `tests/records/spike_caustic_trace_vs_jacobian.py`.

---

## Retired docs (2026-10-17)

Consolidated into this hub, `f_tf_backlog.md` and `f_tf_research.md`. All eight were last present at
commit `693417b`; read one with `git show 693417b:ideas/<name>`.

| Retired | Now lives in |
|---|---|
| `f_tf_triage.md` | Decisions here; per-item entry conditions in the backlog |
| `f_tf_build_brief.md` | Module status here; catalog and chains in the backlog |
| `f_tf_jitfx_audit.md` | `f_tf_research.md` section 4 |
| `f_tf_tensor_strategy.md` | `f_tf_research.md` sections 2, 3, 5; Decisions here |
| `f_tf_expressive_consumers.md`, its `research.md` copy, and the `_omp` draft | `f_tf_research.md` section 7; backlog |
| `f_tf_omp_prompt.md` | Nothing (a spent process artifact) |

Specs, plans and tasks under `.specify/f_tf_*` still cite the retired docs by path as provenance
(for example "promoted from `ideas/f_tf_triage.md`"). Their section references (section 2.1, 4.4 and
so on) point into the old documents; use `git show` for those.
