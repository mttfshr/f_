# f_ngon

**Type:** Processor (texture in → texture out) — stateless
**Status:** Shipped but not confirmed: no spec, README marks it "not yet confirmed or documented". Tier-1 mirror landed 2026-10-20 (`T002`); the module's fate (`T001`) is still open. Has a helpfile (`package/help/f_ngon.maxhelp`).

_Reference written 2026-10-22 from `src/f_ngon/definition.py` (the inline codebox), `ideas/f_ngon.md`, `.specify/f_ngon/tasks.md` and `tests/modules/ngon/`. The module has no spec; `ideas/f_ngon.md` is its only design note and is partly out of date (see Known issues)._

---

## What it does

A **kaleidoscope fold** of the input texture with a live-modulatable mirror count. Each pixel's coordinate is folded by repeated reflection across two mirror lines (at angle 0 and at `π / n_mirrors`) until it lies in the fundamental wedge, and the source texture is sampled there. The result has `2·n_mirrors`-fold symmetry and a regular `2·n_mirrors`-gon outline (a 12-gon at the default `n_mirrors = 6`).

It exists because Vsynth has no simple way to get a clean regular polygon with a live-modulatable vertex count. The mechanism came out of the `f_poincare` Phase 0 kaleidoscope diagnostics (the same reflection fold, shared math with `f_apollonian`) and was confirmed visually at `n_mirrors` 6, 11 and 18 in a scratch patch (`~/Vsynth/patterns/ngon-scratch.maxpat`).

It is a *sampler*, not a shape generator: it needs a source texture, and there is no filled-polygon mask outlet (see Known issues).

Related: `f_mobius` and `f_droste` (other stateless analytic UV transforms), `f_stereo` (also folds onto a disk).

---

## Signal Flow

One inlet (texture plus control messages), one outlet.

```
in0 (texture + ctrl) -> routepass -> ngon_pix (one jit.gl.pix, inline codebox) -> out1
```

Single-stage `jit.gl.pix`, built by the generic builder (`archetype: processor`). Panel is 154 × 91 px.

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `n_mirrors` | float | 2.0–18.0 | 6.0 | Mirror count. The output has `2·n_mirrors`-fold symmetry. The 32-iteration fold is confirmed stable through 18. Non-integer values are accepted and fold anyway, but the angle closed form only holds for integers |
| `rotation` | float | 0.0–6.2831853 | 0.0 | Mirror axis rotation, radians. Mirror 0 sits on the x-axis at 0. A full turn (2π) is the identity |
| `scale` | float | 0.0–2.0 | 1.0 | Zoom: the pixel coordinate is divided by `scale`. 1.0 is the neutral scale. The dial minimum 0 **divides by zero** and is untested |
| `bypass` | toggle | 0/1 | 0 | Mixes toward the plain unwarped source (`sample(in1, norm)`); a half value is a mix |

---

## Algorithm

```
theta = pi / n_mirrors
z0    = snorm * (1 / scale)                      // snorm = norm mapped to [-1, 1]
z     = rotate(z0, -rotation)
repeat 32 times:
    reflect across the x-axis       when zy <= 0           (step(zy, 0))
    reflect across the theta-line   when crossTheta <= 0   (step(crossTheta, 0)), crossTheta = zx*sin(theta) - zy*cos(theta)
uv  = clamp(z * 0.5 + 0.5, 0.001, 0.999)
out = mix(sample(in1, uv), sample(in1, norm), bypass)
```

Each iteration is branchless: both reflections are blended in with `step()` / `mix()`.

- **Fold result.** For integer `n_mirrors` the folded angle equals the start angle reduced into `[0, θ]`: `phi mod 2θ`, mirrored down to `2θ − phi_f` when it lands above `θ`. The fold is a composition of reflections, so it preserves radius.
- **Convergence needs roughly `n_mirrors` iterations** in the worst case (a point far from a narrow wedge needs more alternating folds). A fixed count tuned for one value silently under-converges at higher ones: 10 iterations broke down around `n_mirrors = 18`; 32 held up cleanly at least that far. The count is a literal 32, not scaled with `n_mirrors`.
- **Read clamp is texel-centre bounds** (0.001 / 0.999), not [0, 1]. Clamping to exactly 1.0 reads the *first* column on the GPU (seam rule), so a fold that lands past the right edge showed the wrong edge. Fixed 2026-10-20 (HANDOFF: clamp triage).

---

## Notes

- **The neutral setting is not a passthrough.** At the defaults (n 6, rotation 0, scale 1) the fold symmetrizes the frame: the output differs from the source. Only `bypass` gives the source back. This is why the bypass is a mix against an unwarped read rather than the fold being skippable.
- **A historical bug is worth remembering.** The second mirror's containment test once had an inverted sign (`step(0.0, crossTheta)` instead of `step(crossTheta, 0.0)`), verified with a concrete numeric example before fixing. The mirror test keeps the wrong form as the mutation `step_swap`.
- **Points exactly on a mirror line sit on a `step` tie** and are excluded from the tests.
- **Alpha** comes from the sampled source texel (the neutral-setting test asserts it stays 1 for an opaque source).

## Known issues / open

- **No spec and no decision on the module's fate (T001).** Five open questions from `ideas/f_ngon.md` remain: filled-polygon mask versus kaleidoscope-of-a-texture output (possibly two outlets or a mode switch; today only the kaleidoscope exists), iteration count scaling with `n_mirrors`, radius/rotation UX, a convergence criterion, and its relationship to the existing Vsynth shape generator (replacement, companion or merged). Either confirm and document it, or demote it.
- **`ideas/f_ngon.md` is partly stale.** It lists rotation and scale as open ("currently fixed at mirror-0 = x-axis", "unclear if a zoom param is needed"); both are now dials.
- **`scale = 0` divides by zero.**
- **Not verified on the GPU.** The 32-iteration loop has only the NumPy mirror (10 tests at landing: reflection isometry, folded angle against the closed form, full-turn identity, output range, bypass, mutants) and visual scratch confirmation; there is no Max bench for it.
- **Bypass wiring:** the bypass control and the codebox `bypass` Param are the same name; it follows the `f_mobius` convention (`mix(effect, sample(in1, norm), bypass)`).

## Verification

- `tests/modules/ngon/{ngon_mirror,test_ngon}.py` — tier-1 mirror, mutations caught: `exact_clamp`, `rot_sign`, `no_scale`, `theta_2pi`, `step_swap`. Run: `tests/run.sh tests/modules/ngon/test_ngon.py`. Grounded in `ideas/f_ngon.md`, since the module has no reference doc until this one.

## References

- Reflection folding into a fundamental wedge of a dihedral group; shared with `f_poincare` / `f_apollonian` (`f_apollonian`'s plan, ADR-8).
- Design note: `ideas/f_ngon.md`. Scratch: `~/Vsynth/patterns/ngon-scratch.maxpat`.

## Source Files

`src/f_ngon/definition.py` (codebox inline), `package/patchers/f_ngon.maxpat`, `package/help/f_ngon.maxhelp`, `.specify/f_ngon/tasks.md`.
