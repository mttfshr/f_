# f_tf_glyph

**Type:** Processor (f_tensor consumer — the family's first tensor renderer)
**Status:** Draft — tier-3 live judgment pending (helpfile judgment gate included). Tier-1 mirror green (14/14, 2026-10-17); tier-2 bench green 6/6 (2026-10-17); defaults provisional (tasks TG020); variant menu / debug tints unresolved for v2 (gates open).

---

## What it does

The tensor family's **universal debug view**: one closed-form glyph per grid
cell over the raw tensor, oriented along the local structure axis, with aspect
from the eigenvalue ratio and presence gated on trace. A field of oriented
marks that reads immediately as "this is where structure is, which way it runs,
and how anisotropic it is".

This is the family's canonical **per-consumer in-pixel decode** module: it
decodes `f_tf_tensormap` outlet 0 in-shader every frame (exactly the way C74's
own `jit.fx.cf.kuwahara` does), and its decode idiom is what `f_tf_sharpen`,
`f_tf_aniso_blur` and `f_tf_hatch` copy — see **The decode idiom** below.

Processor archetype, requires input. Not a generator.

## Why tensor-native

Glyph aspect is λ1/λ2 — collapse the tensor to a vecfield and you get a line
with no sense of "how anisotropic"; to a scalar and you get a dot with no
orientation. The second eigenvalue is load-bearing.

## Signal Flow

```
in0 (raw tensor) ─┐
in1 (source tint) ─┴→ stage_glyph (one jit.gl.pix):
                      cell lookup -> decode -> gate -> closed-form ellipse draw -> tint
                      → outlet 0 (glyph composite, @type float32)
```

Single stage, stateless, no loops anywhere (plan ADR-4: the uniform lattice
makes cell lookup exact arithmetic). Cell centers are sampled with in-shader
clamping to texel centers — the bench GPU wraps out-of-range reads (tensormap
ADR-5).

---

## Inlets

| Inlet | Content |
|---|---|
| 0 | **Raw tensor, `f_tf_tensormap` outlet 0 exactly** — `f_tensor_type.md` contract: R = Jxx·strength, G = Jxy·strength·0.5 + 0.5 (0.5 = zero), B = Jyy·strength, A = 1. The driving input; control messages ride the same inlet. |
| 1 | Source texture for tint (luma-modulated ink at the cell center). Optional; geometry never depends on it. Unconnected renders the neutral white ink. |

**Inlet contract (plan ADR-3):** inlet 0 accepts tensormap **outlet 0** only.
Feeding **outlet 1** (the angle-doubled packed encoding) decodes a visibly
wrong field — the doubled values spread the glyph angles apart. It self-
diagnoses on sight, but never wire it. Nothing mechanically sniffs the input.

## Outlets

| Outlet | Content |
|---|---|
| 0 | Glyph composite, float32. RGB = rendered glyphs (tinted per inlet 1), A = 1. Empty wherever the tensor is below the gate. |

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `grid` | 2-256 | 24 | Cells across; the lattice is grid × grid. The real control. |
| `glyph_scale` | 0-2 | 0.8 | Glyph radius relative to the cell: 1.0 = glyphs touch. |
| `thickness` | 0-1 | 0.15 | Stroke weight of the ellipse ring, as a fraction of radius. |
| `softness` | 0-1 | 0.1 | Edge falloff, independent of thickness (f_weave convention). |
| `gate` | 0-1 | 0.05 | Draw threshold on the delivered trace. |
| `max_aspect` | 1-32 | 8 | Clamp so near-degenerate λ2 can't draw infinitely thin spikes. |
| `bypass` | 0/1 | 0 | **Passthrough of the source texture** at the current pixel — not a neutral frame (glyph = passthrough per the family contract). |

**Every default above is provisional**, pending the live judgment tier
(tasks TG020). The shipped dial is named `glyph_scale` on the wire because the
codebox's internal identifier avoids the GenExpr `scale()` operator collision.

---

## The decode idiom (plan ADR-2 — the family's citation target)

`f_tf_sharpen`, `f_tf_aniso_blur` and `f_tf_hatch` copy this block verbatim
with a citation comment (`plan ADR-2, .specify/f_tf_glyph/plan.md`); do not
re-derive and do not extend the atan2 use beyond what this block contains.

```gen
// in: t = sample(tensor_tex, clamp(cell_uv_to_texel))   // tensormap ADR-5 clamp
// encoding: f_tensor_type.md outlet 0 — R>=0 G:0.5=zero B>=0 A=1 (all × strength)
Jxx = t.r / strength;  Jxy = (t.g - 0.5) * 2.0 / strength;  Jyy = t.b / strength;
trace = Jxx + Jyy;  diff = Jxx - Jyy;  root = sqrt(diff*diff + 4.0*Jxy*Jxy);
lambda1 = 0.5*(trace + root);  lambda2 = 0.5*(trace - root);
theta = 0.5 * atan2(2.0*Jxy, diff);      // GRADIENT axis (across the edge); along = theta + pi/2
// Gain-free identities (strength is a common factor on R, G-0.5, B):
//   tan(2*theta) = 2*(t.g-0.5)/(t.r - t.b);   aspect = (trace+root)/(trace-root)
// CAVEAT: 0.5*atan2 confines theta to (-pi/2, pi/2]; a near-vertical axis
// decodes sign-flipped. Safe ONLY for consumers symmetric to theta+180deg
// (glyphs, blur, hatch, sharpen, coherence). Sign-sensitive consumers must
// route through f_tf_axisflow (f_tensor_type.md consumer rule 2).
```

Note the θ+180° symmetry caveat in the idiom text: an unoriented line at θ and
θ+180° renders identically for glyphs, but a future consumer that is *not*
axis-symmetric must not copy it blindly.

## Key behaviors

- **Gain-free (ADR-5).** Glyph orientation, aspect and presence are computed
  from ratios of the decoded terms; the common `strength` factor cancels. The
  glyph *radius* comes from `glyph_scale` × cellsize, not from absolute
  eigenvalues — **sweeping tensormap's `strength` changes nothing here.**
  (Fallback if live judgment says size-meaning matters: λ1-driven radius with
  a `strength` echo param; recorded in plan ADR-5, not built.)
- **Gate (ADR-6).** A cell draws only where the decoded trace ≥ `gate`. Below
  it: nothing drawn. Isotropic-but-traceable cells (λ1 ≈ λ2 with real trace)
  draw aspect-1 circles. The all-zeros unconnected-wire texture (0,0,0,0)
  decodes a non-SPD phantom (λ1 = 1, λ2 = −1 in strength units) but its trace
  is exactly 0 — the gate keeps the frame empty; at `gate` 0 the inherited
  `eps_trace` (1e-6) floor still holds. Energy-gated consumers cannot rely on
  this trace trick and need an explicit SPD guard (`f_tensor_type.md` rule 5).
- **Ellipse-only v1** (spec OQ1 resolution, gate open for v2): no variant
  menu; cross/tick would be closed-form distance swaps kept as scratch-only
  experiments (plan ADR-8). No debug-tint modes (spec OQ2 gate also open).
- **Marks confined to their cells:** every drawn pixel lies within
  `glyph_scale·cellsize/2` (+ the softness falloff) of its own cell center.

## Typical use

```
jit.gl.bfg -> f_tf_tensormap (outlet 0) -> f_tf_glyph
```

Also as a debug sidecar behind any tensor consumer (the smooth/sharpen
scratch-check task, TG021 — pending siblings): tune while watching the glyph
view of the consumer's own output.

## Cost

Expected trivially cheap: one tensor tap + one source tap + closed-form math,
~84 codebox statements (the capture ceiling is ~450). Per-pass cost measured by `tests/modules/tf_glyph/bench_tf_glyph.py` (2026-10-17):
~2.39 ms per pass at 1080p and ~6.96 ms at 4K, both upper bounds (bench frame floor,
not GPU-bound; the tensormap T016 convention) — the default-resolution question
stays open for tier-3 live judgment.

## Notes

- Spec/plan/tasks: `.specify/f_tf_glyph/`. Tier-1 mirror:
  `tests/modules/tf_glyph/test_tf_glyph.py` (14 tests, green 2026-10-17: λ1/λ2/θ vs
  `np.linalg.eigh` ≤ 1.2e-7 / 2.4e-7 rad, gain-free identity exact, mutation
  caught). Tier-2 bench: `tests/modules/tf_glyph/bench_tf_glyph.py` — **run and green 6/6
  (2026-10-17)**; the live findings that shook out (family rules 5–6 of
  `f_tensor_type.md`; plan ADR-2 amendment): runtime `atan2(0,0)` = NaN
  (fixed at source with a +1e-7 denominator bias), `sample()` nearest-
  fallback on data-dependent jumping coords (fixed with the four-tap
  `nearest()` idiom on both texture reads), residual 2.3e-4 at the 97×64
  grid-7 extreme = the documented 8-bit-weight ceiling.
- The pix object binds as `#0_glyph_pix` (hash-zero-prefixed, like the
  shipped multi-stage modules' stage names): single-context-safe against Ob3D name collisions when
  two instances of the module are live at once (the bench found this class
  2026-10-17; `axisflow` carried it too and was renamed same day).
- Bench GPU wraps out-of-range texture reads; cell-tap coordinates are clamped
  in-shader to texel centers (tensormap ADR-5).
- `dim` reads 1 inside live jit.gl.pix, so `width`/`height` are Params (the
  tensormap precedent); they enter only through the texel-center clamp.
- The decode idiom's custodian is this module's plan ADR-2; guard its text.
- Unconnected `jit.gl.pix` inlets read (0,0,0,1) (bench-verified 2026-10-07);
  for inlet 1 that lands on luma 0 → neutral white ink, as intended.

## References

- Kindlmann et al. Superquadric glyphs for symmetric second-order tensors
  (IEEE TVCG 2009) — the glyph-rendering precedent family.
- Delmarcelle & Hesselink (1993). Hyperstreamlines / hyperLIC. Second-order
  tensor visualization lineage.
- G'MIC `-structuretensors` + `-eigen` + `-display_tensors`: an ellipse per
  tensor cell, the literal ancestor of this module's look.
- `jit.fx.cf.kuwahara` — C74's shipped per-consumer in-pixel decode precedent
  (`ideas/f_tf_research.md` §4).