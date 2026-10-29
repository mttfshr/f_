# f_tf_hatch

**Type:** Processor (f_tensor consumer, renderer)
**Status:** Draft — codebox tier-2 bench and tier-3 live judgment pending
(built 2026-10-17 as the fifth module of the tensor-family build order:
smooth → glyph → sharpen → aniso_blur → **hatch**; the mirror and cost
spike are green, and the tier-2 bench ran green (re-run 2026-10-28; each
stage under ~0.8 ms/pass at 1080p, upper bounds); the module's provisional defaults remain
provisional — the tensormap cycle applies, with the tier-3 live
judgment pending).

---

## What it does

An orientation-committed hatching / engraving renderer. Discrete marks (short
dashes) are laid out across the frame, each oriented along the local structure
axis decoded from an incoming structure tensor — and, critically, each mark's
*shape is committed per-pixel from the eigenvalues*: where the eigengap is wide
(a direction genuinely exists) the mark commits to a line-like stroke along
that direction; where the gap closes the same mark rounds off toward a dot; at
or below the coherence gate there is nothing. One mechanism, continuous across
the field: lines where structure is line-like, dots where it is not, nothing
where the gate says there is no structure at all.

The per-pixel decode is per-consumer (no `f_tf_decode` module exists; hatch
copies the canonical decode idiom from `.specify/f_tf_glyph/plan.md` ADR-2
verbatim). Hatching is the *tensor-native* consumer of the family: direction
alone would be a view (a vecfield carries neither λ2 nor confidence); the
per-pixel commit IS the point. Performer dials set response magnitude and
thresholds only (`elongation`, `coherence_gate`) — never the shape data (the
glint lesson, applied deliberately).

Discrete-item family member (the fifth, after `f_grain`, `f_masonry`,
`f_weave`, `f_vf_seeds`): hash-grid-cell marks with the family's `density` /
`weight` / `softness` / `phase` / `regularity` vocabulary; but hatching's mark
character is INTERNAL (smoothstep profile, as in `f_weave`), not the
shape-tex-inlet architecture — the mark footprint cannot live upstream without
un-doing the tensor-native part.

Requires a tensor input (processor archetype, `driving_inlet`); no
self-generating mode.

---

## Signal Chain

```
in0 (tensor + control) -> stage E1  eigen decode + commit (closed-form)
                       -> stage E2  mark layout (the branch-T frame pass)
                       -> stage E3  mark render + compose + encode (the only
                                    stage that clamps/encodes)
E1/E2 intermediates stay unbounded float32 and are never outlets.
```

- **Stage E1** samples tensormap **outlet 0** (raw tensor, lossless; the
  packed outlet 1 is angle-doubled and clamped — the wrong feed for a
  geometry-laying-out consumer). Decodes λ1/λ2 closed-form (the glyph ADR-2
  idiom), normalizes coherence = (λ1−λ2)/(λ1+λ2) (tensormap's form), computes
  the commit curve (below), and applies `angle_offset` (±1 ⇒ ±90°, wrapping
  cleanly because the decoded axis is an unoriented line). Below `eps_trace`
  (1e-6, tensormap ADR-6/T019) the axis is unset and commit 0 — no marks,
  never an arbitrary angle.
- **Stage E2** rotates each pixel into its local (across, along) frame from
  E1's axis (branch T: the tileable distance-field pattern; chosen over
  stroke-marching by the T001 cost-shape gate — 3 passes / ~6 taps / no loops
  vs ≥5 passes / 75-90 taps / loop-carried march state — plan ADR-1).
- **Stage E3** renders the mark (the f_weave smoothstep profile and edge
  form, cited), squeezes aspect by commit, multiplies mark intensity BY
  commit (no seam at the gate), and encodes both outlets. Bypass lives here
  (bypass_mode "param", both outlets black).

Stateless (no feedback pass); flicker mitigation lives upstream — see
Upstream contract.

---

## Parameters

All defaults below are **provisional** — the tensormap precedent applies:
they lock at the tier-3 judgment (tasks T020, pending) with live
replacements recorded in the spec's Open Questions.

| Param | Range | Default | Description |
|---|---|---|---|
| `density` | 0–1 | 0.5 | Line/dash spacing, log-mapped: `pow(2, density*5 − 1)` (the family formula, weave's published span) |
| `weight` | 0–0.5 | 0.1 | Mark thickness (across-axis half-extent). Squeeze-not-independent (the family's size+stretch finding): aspect is one dial |
| `softness` | 0–0.49 | 0.05 | Edge feather, both axes; expands the multiplicative outer edge (weave's cited form). Clamped 0.49 |
| `elongation` | 0–8 | 3 | Response-magnitude dial: max mark aspect at commit 1. Commit 0 ⇒ aspect 1 (dot) regardless. Caps where dashes merge: aspect_max = (0.5/(weight·density_scale))² — at the defaults that is ~elongation 2.1 (plan ADR-9); lighter `weight` uncaps |
| `coherence_gate` | 0–1 | 0.25 | Where strokes begin: coherence at/below this gives dots, above it marks lengthen toward strokes. Changes mark shape only, never brightness. Curve form (OQ3) still pending live confirmation |
| `structure_floor` | 0–1 | 0.1 | Draw nothing where there is too little structure. Threshold on the tensormap's trace scale (trace × its `strength`), squared for finer low-end control; 0 = dots wherever any structure exists. Not strength-invariant: calibrate with the tensormap's `strength`. Provisional default |
| `angle_offset` | −1–1 | 0 | Rotates the pattern relative to the decoded axis; ±1 ⇒ ±90° (spans the distinct layouts of an unoriented axis field) |
| `phase` | −1–1 | 0 | Scrolls marks along the stroke axis (phase 1.0 = one full dash pitch); the family-standard animation entry |
| `regularity` | 0–1 | 0.5 | Per-line dash stagger (weave's hash form): 1 = lines in phase (grid-like), 0 = fully staggered, hash-stable across frames |
| `strength` | 1-1000 | 100 | Gain the producing tensormap applied to the tensor; the decode divides it back out - match it to the feeding tensormap (log dial, like tensormap's) |
| `bypass` | 0/1 | 0 | Black on both outlets (bypass_mode "param", like the tensormap's) |

**Prefix:** `hatch` — **Object name:** `hatch_pix` — **Type:** `@type float32`
throughout. No width/height params: every texture read is at `norm` (no
measured tap step needed — the aspect `dim`-reads-1 caveat does not apply).

---

## Outlets

| Outlet | Content | Notes |
|---|---|---|
| 0 | Hatch output | Luma marks on black, `@type float32`; color is downstream's job (`f_channel_grader`/colorize, the weave convention) |
| 1 | Mark mask | The same luma without the encode mix (the discrete-family convention, `f_vf_seeds` out1): for downstream compositing/gating |

Neither outlet is a tensor or a vecfield — they are rendered marks, not field
data (don't feed them to tensor consumers). The header `signal_type` label
reads "T_ in" (the tensor-family color) as the tensormap precedent's header
tag; the outlets themselves are plain luma textures.

**Commit semantics (the one design constant):** mark intensity is multiplied
by per-pixel `commit`, so coherence at/below the gate renders nothing and the
line→dot rounding is continuous — this is the tensor-native core; pushing
`elongation` down does NOT create dots at low coherence (aspect does not take
shape instructions from a dial, plan ADR-3).

---

## Typical use

```
jit.gl.bfg -> f_tf_tensormap -> f_tf_hatch (outlet 0 / 1)
```
Chain-terminal renderer. The full chains (B: `tensormap ↔ f_tf_authored →
f_tf_mix → f_tf_smooth → hatch`; D: `f_vf_optical_flow → f_tf_motion →
f_tf_smooth → hatch`) assemble as those triads land.

---

## Upstream contract

`f_tf_smooth` upstream is the practical requirement: hatching is the family's
most flicker-sensitive consumer (a line present one frame and gone the next
reads as noise). Hatch itself is stateless and holds no smoother — the
mitigation lives upstream by design. Its inlet expects EXACTLY tensormap
outlet 0's encoding (`f_tensor_type.md`): the packing is a wiring error,
self-diagnosing (marks everywhere at a doubled angle), never blessed.

---

## Notes

- Built by the parallel T001 build (2026-10-17): NumPy mirror
  `tests/modules/tf_hatch/test_tf_hatch.py` (20/20 pass — eigh cross-check ≤4.8e-7 on λ,
  ≤3.6e-7 rad on axis; commit invariants; family mechanics; three mutation
  checks), cost spike `tests/records/spike_tf_hatch_costshape.py` (branch T chosen;
  model ≤2.7 ms/1080p vs the ~0.9 ms/pass bench floor), codeboxes
  `src/f_tf_hatch/codebox_stage_e{1,2_T,3}.gen`, definition.py
  (`src/f_tf_hatch/definition.py`) → `package/patchers/f_tf_hatch.maxpat`
  (JSON-valid).
- **Tier-2 bench (`tests/modules/tf_hatch/bench_tf_hatch.py`) and tier-3 scratch patch are
  pending** — the bench file is written and registered (in benchdeps.DATA via
  `.specify/f_tf_hatch/REGISTRATION_NOTES.md`) but not yet run; the cost
  model's PROVISIONAL-CLOSED gate and the provisional defaults resolve
  there.
- Bench GPU wraps out-of-range reads; hatch samples only at `norm` (always
  in-bounds), and E1 keeps the explicit clamp for the rule.
- GenExpr `0.5*atan2` confines the gradient angle to (−π/2, π/2]: hatch is
  safe under that (an unoriented line pattern is symmetric to θ+180°); the
  decode caveat is recorded in the codebox (glyph ADR-2 verbatim).
- Spec, plan, tasks: `.specify/f_tf_hatch/`; triage/build-order context in
  `ideas/f_tf_backlog.md`, `ideas/f_tensorfield.md`.

---

## References

- `docs/f-reference/f_weave.md` — the distance-field line/mark algorithm
  branch T adapts (cited, never re-derived).
- `docs/f-reference/discrete_item_conventions.md` — the family's param
  vocabulary (density/phase/regularity/softness, size+stretch squeeze).
- `.specify/f_tf_glyph/plan.md` ADR-2 — the canonical decode idiom (copied
  verbatim into stage E1).
- `docs/f-reference/f_tensor_type.md` — the tensor encoding contract.
- Gouraud/Haeberli-style line-hatching lineage: Praun et al. 2001
  ("Real-time hatching") for the tone-layer mechanism hatch's v2 pointer
  (inlet-1-luma) generalizes; nothing was taken from implementations.