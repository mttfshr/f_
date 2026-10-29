# f_vf_immiscible — blend two flows by an immiscible phase field

**Status:** 🟢 built 2026-10-27/28 and live-checked by Matt (2026-10-28: two `f_vf_fluid` at
different viscosity "in good shape", defaults kept). Name confirmed by Matt (it began as
`f_vf_phase`; `f_vf_emulsion` was the other candidate). Module: `src/f_vf_immiscible/`,
reference `docs/f-reference/f_vf_immiscible.md`, helpfile `package/help/f_vf_immiscible.maxhelp`,
design record `.specify/stable/f_vf_immiscible/{spec,plan,tasks}.md`. **A separate module** (not the fork of
`f_vf_fluid` that `f_vf_emulsion.md` first proposed), and it **requires two upstream velocity
vecfields**, one per phase. Below: the original idea record; the sections after "The phenomena" are
history and some figures (cost, "unverified" notes) were superseded by the build. Stage 2
(momentum across the interface, Phase 4) is not built. Everything marked [inference] was from
general knowledge of the method or my own derivation when written.

## The phenomena this is for

Matt framed the family of looks 2026-10-27. How each is served:

- **Oil and water light show** — two fluids that do not mix, with different
  viscosities and characters. **This module.** It is the one Matt "would really
  like to build".
- **Watercolor ink dispersing in water** — mostly available today as the
  emulsion doc's Tier 0 (`f_vf_fluid` plus `f_vf_advect` with a coloured source),
  where smearing is the point. The missing piece is the drop of ink itself:
  see `f_splat.md`.
- **Drops forming and sliding on glass** — the drops come from modules that
  already exist upstream (`f_grain`). The trail and rivulet-network half is the
  River rule parked in `f_ca.md`. Nothing is planned here.
- **Water flowing, pooling at obstacles, overflowing** — `f_vf_lbm` gives flow
  around an obstacle but has no free surface, so nothing pools or spills. A
  height-field rule (water depth over a terrain luma) would be new. Not planned.

## Concept

Two velocity vecfields come in, one per phase, each produced by its own
`f_vf_fluid` with its own `viscosity`, `project`, `drag` and `dt`. Inside the
module a scalar phase field **φ** says where each phase is. The module

1. evolves φ by a **Cahn–Hilliard** equation, advected by the blended velocity;
2. **blends the two velocities by φ** into one vecfield for downstream
   consumers (`f_vf_advect`, `f_vf_warp`, ...);
3. (stage 2) returns **nudge and force vecfields** so each Fluid feels the
   other phase across the interface.

Different viscosities are therefore not a feature of the module: they are two
Fluids with different dials. That is what makes the unmixed look possible
without changing `f_vf_fluid`.

Cahn–Hilliard fits "immiscible": a double-well energy keeps φ near its two
values, gives the interface a fixed width, makes droplets bead up and coalesce,
and conserves the amount of each phase. It is the opposite problem to the one
`f_vf_emulsion.md` was written for (there, smearing of φ was half-welcome); here
smearing is the enemy and the model has a physical term that fights it, instead
of the fiddly anti-diffusion patch the emulsion doc had to propose. [inference]

## Why a separate module, and why two upstream Fluids (decided 2026-10-27)

- `f_vf_fluid` uses all four channels of its DFT chain, so φ needs its own
  chain whether it lives inside Fluid or beside it. A fork would cost the same.
- Fluid's viscosity is spectral and constant; a spatially varying one cannot be
  expressed in the Fourier domain (`f_vf_emulsion.md`, "Why one fluid is
  structural"). Two Fluids sidestep that: each is homogeneous, the blend does
  the spatial variation.
- This is the emulsion doc's Tier 1 ("two Fluid instances, blended by a mask")
  made less naive. That doc rejected it because a mask-weighted blend of two
  divergence-free fields is not divergence-free and no momentum crosses the
  interface. Stage 2 addresses the missing momentum; the divergence can only
  be spread by the blend, not removed (see "The blend").
- It leaves the verified, documented `f_vf_fluid` untouched.
- **The second vecfield is required** (Matt, 2026-10-27). No single-fluid mode
  is designed. An unconnected or non-vecfield inlet must still be safe: read it
  through the usual content gate (`f_vecfield_type.md` producer note 4) as a
  zero field, so nothing blows up, but that is a quiet failure, not a feature.

Alternatives considered and set aside, kept for the record:

1. *A look only:* advect φ by a blurred copy of the velocity where φ says
   "thick". Cheap, but the flow never feels it.
2. *A drag map in one Fluid* (~0.1 ms, emulsion doc Tier 2): slows the flow but
   damps all scales alike, so it reads sticky, not thick.
3. *A viscosity map in one Fluid* (~0.3–0.6 ms): solve at the base viscosity,
   blend toward a blurred copy where "thick". Per-frame spectral decay is a
   Gaussian blur of variance 2·ν·dt in domain units, so this is the exact extra
   viscosity away from the interface, and inexact at it. [inference]

Options 2 and 3 remain the fallback if two Fluids prove too expensive; they
need one optional map inlet on `f_vf_fluid`, a structural change that touches
the unresolved mod-inlet convention (`named_mod_textures.md` T4–T6).

## Proposed shape

```
in0  φ source / control   (texture + messages: ink or oil injected, e.g. from f_splat)
in1  velocity vecfield A  (f_vf_fluid out, phase A)       — required
in2  velocity vecfield B  (f_vf_fluid out, phase B)       — required

out0 φ                     (scalar texture, float32)
out1 blended velocity      (vecfield, f_vecfield contract, B = 0.5, A = 1)
     stage 2 only:
out2 nudge / force for A   (vecfield)
out3 nudge / force for B   (vecfield)
```

- The φ source is a dedicated inlet, not derived from the force, for the reason
  argued in `f_vf_emulsion.md` ("φ's source"): contrast in the image needs
  independent causes.
- Convention to settle: φ in [-1, 1] for the solver, blend weight
  `w = (φ + 1) / 2`; phase A at w = 0.
- The inputs are Fluid's **encoded** outlets (render size, gain applied,
  clamped to ±1 field units), not the raw solver state. That caps the
  velocity φ can feel.

## The blend

A plain `w·u_B + (1−w)·u_A` has divergence `∇w · (u_B − u_A)` when both inputs
are divergence-free. Only the component of the velocity difference *normal* to
the interface contributes, because ∇w points along the normal `n`. So:

- **Correction (2026-10-27, found while writing the spec).** An earlier version
  of this section claimed that blending the normal component from one agreed
  value "adds no divergence". That is only true where the two normal components
  already agree, and there the plain blend is already divergence-free. Where
  they disagree, the jump `n·(u_B − u_A)` is a real mass-flux mismatch, and the
  divergence integrated across the interface equals that jump **for any blend
  rule**. An output-side rule can only spread it over a wider band; only changing
  the flows themselves (stage 2) removes it. If both Fluids get the same stirring
  force the mismatch is mostly in magnitude and may be small; Phase 0 measures it.
- The interface-aware rule that remains a candidate: split into normal and
  tangential parts, blend the tangential by `w`, and replace the normal part in a
  band by an average. It lowers the peak divergence by spreading it. Whether that
  is worth building is G2 in the spec. [inference]
- **The tensor concept, if the rule is kept:** the raw structure tensor of φ is,
  up to scale, `n nᵀ`, a sign-free normal/tangential projector (none of the
  angle-doubling traps in `f_tensor_type.md` apply). The plan computes it
  directly from φ's gradient; `f_tf_tensormap` is not needed.
- **Viscosity in the weights** (candidate): weight by `μ_A·(1−w)` against
  `μ_B·w`, so the thicker fluid dominates a mixed cell. A heuristic, not
  derived or tested. [inference]

## Momentum across the interface (stage 2)

Without this the output is two flows composited: a picture of two fluids. For
momentum to cross, each Fluid has to be nudged toward the blend, weighted so
each is free in its own phase and pulled toward the other in the band across
the interface. That is two cross-module feedback cycles (each Fluid out → this
module → that Fluid's force inlet), **untested in Max**.

Two ways to deliver the nudge:

- **Through `f_vf_fluid`'s existing force inlet**, summed with the performer's
  own stirring force by `f_vf_mix` additive. No change to Fluid, but fragile:
  strength depends on Fluid's `force` and `gain` dials, which this module
  cannot see, and force tops out at 0.2 velocity per frame.
- **A native "pull toward this field" inlet on `f_vf_fluid`.** Exact, but a
  structural change (a second inlet).

Buoyancy (`∝ φ · g`, Boussinesq, no variable density) and surface tension
(`∝ −φ ∇μ`, μ the chemical potential) would travel the same way. [inference]

## Staging

1. **One-way, no cycle.** The same stirring force feeds both Fluids, set to
   different `viscosity` / `project` dials. φ is advected by the blend and the
   module outputs φ and the blend. Shows whether the look is worth the cost.
2. **Nudge and force outlets**, with the cycle and the delivery choice above.

## Solver sketch [inference, all of it]

- 256² float32, periodic, same architecture as `f_ks` / `f_vf_fluid`: a chain
  of `jit.gl.pix` stages, exact or semi-implicit linear step per Fourier bin,
  explicit nonlinearity in real space, encode stage at render size.
- Cahn–Hilliard is `dφ/dt = M ∇²(φ³ − φ − κ ∇²φ)`. Its linear part per bin has
  the same `k² − κk⁴` shape as `f_ks`'s step. The `∇²(φ³)` term needs φ³ in
  the Fourier domain, which fits the "two complex fields per chain" packing
  `f_wc` used: φ in one, φ³ in the other.
- Advection by the blended velocity is a semi-Lagrangian backward trace, as in
  `f_vf_fluid`'s `adv` stage (the periodic four-tap bilinear read exists).
- Cheaper packing is possible later: `f_vf_fluid`'s imaginary channels are
  zero, so two real fields could share one complex field with a Hermitian
  split. Not for a first build.

## Dials (provisional)

`kappa` (interface width / surface tension), `mobility` (how fast things
coarsen), `inject` (φ inlet amount), the blend options (normal-component
handling, viscosity weighting), and in stage 2 `buoyancy` (strength and
direction), `nudge` strength and `force gain`.

The emulsion doc's "φ persistence" question changes shape: φ is conserved and
Cahn–Hilliard *separates*, so the failure mode is not a uniform grey emulsion
but everything slowly resolving into two big blobs. Stirring keeps it
interesting; `mobility` sets how fast it resolves. The "what does equilibrium
mean" sub-question mostly goes away. [inference]

## Tier-1 checks (candidates)

- Mean of φ is conserved exactly (the k = 0 bin is untouched).
- Free energy is non-increasing with no flow.
- Spinodal growth: a single Fourier mode in the unstable band grows at the
  analytic rate; outside it, decays.
- A flat interface relaxes to the `tanh` profile with the width `κ` predicts.
- Blend: the plain blend's divergence equals `∇w · d` exactly; the divergence
  integrated across a straight interface equals the normal jump for every rule;
  with `w` constant the blend returns the matching input exactly; swapping A and
  B with `w → 1−w` gives the same output.
- Surface tension (later): a circular droplet reaches a pressure jump `σ / R`
  in 2D.

## Phase 0, cheap, offline, before any spec

NumPy only, in two parts:

1. **φ alone.** Stir with the velocity `tests/modules/fluid/fluid_mirror.py`
   already produces, advect a Cahn–Hilliard φ with it, and look: does the
   interface stay sharp, do droplets coalesce, how fast does it coarsen at
   256²? Compare against plain advected φ plus a sharpening term (the emulsion
   doc's fallback). Run a thin filament as well as a blob, since thin features
   are the worst case for the fallback.
2. **The blend.** Step two mirror Fluids with different `viscosity` and
   `project` under the same force, blend by φ, and measure the divergence of the
   plain blend relative to |u|, and how much an interface-aware rule lowers its
   peak. That is the number that says whether the extra rule is worth building.

## Risks and open questions

- **Cost.** Two Fluids are about 5 ms (2.5 ms each on the bench; in-patch margin
  unmeasured, see `f_vf_fluid.md`) plus the φ chain, roughly 2.4 ms going by
  `f_ks.md`: roughly 8 ms in all once input minification is counted,
  before any consumers, unmeasured together. Fluid's 128² fallback is the lever. A real risk for a live patch.
- **The blend rule is the design, and it is unproven.** Which normal component
  wins, how wide the interface band is, and whether viscosity weighting helps
  are all open. Phase 0 part 2 exists to answer them.
- **Coarsening speed at real time.** Cahn–Hilliard coarsens slowly (domain
  size grows roughly as t^(1/3)). A semi-implicit step is stable at large `dt`,
  but accuracy and the look at 60 fps are unknown. [inference]
- **Two-way coupling needs two one-frame feedback cycles across modules.**
  Never tried in Max with these modules; needs a scratch test with a
  `hold`-style delay (`f_vf_lbm`'s `hold` stage is the idiom). Stage 1 needs none.
- **Summing forces needs `f_vf_mix` additive**, which is idea-only
  (`f_vf_mix.md`). This module is its first concrete consumer.
- **Surface tension force stability.** An explicit capillary force carries a
  time-step limit; Fluid adds force as `force · F` per frame with no `dt`, so
  the force output will need a clamp and a conservative default. [inference]
- **Interface width versus the 256² grid.** The interface needs a few texels,
  so the smallest droplet is a few texels across (about 1% of the frame
  height). Probably fine, but it sets the finest look.
- **Periodic domain**, like Fluid. Consumers that clamp at their edges will not
  show wraparound, but the φ field itself wraps.
- **Unconnected inlets.** All three inlets need the content-gate pattern; φ
  source is a scalar, so "unconnected" must mean zero injection, not
  `vs_black`.
- **Render-size inputs minify into 256².** Fluid's outlets are render size, so
  this module reads them down to 256². A smooth field is fine; same
  "fixed-`@dim` stage is a resampler" finding as in `f_vf_fluid`.
- **Tensor inputs were considered and not chosen.** The module takes vecfields;
  the tensor appears only inside, for the interface projector.

## Related

`f_vf_emulsion.md` (the analysis this started from; its Tiers, φ-source and
timescale arguments still stand), `f_splat.md` (the way to drop ink or oil in),
`f_vf_fluid`, `f_vf_lbm`, `f_ks` (template for the spectral chain), `f_wc`
(two-fields-per-chain packing), `f_vf_mix.md` (additive force combiner),
`f_tf_tensormap` / `f_tensor_type.md` (the interface projector), `f_tf_aniso_blur`
(an alternative interface-sharpening route if plain advection is used),
`f_ca.md` (River rule, parked coupling).

## Provenance

Conversation with Matt, 2026-10-27; the two-upstream-vecfield blender and the
required second inlet are his. Reading: `f_vf_emulsion.md`,
`docs/f-reference/{f_vf_fluid,f_vf_lbm,f_vf_advect,f_ks,f_vecfield_type,f_tensor_type}.md`,
`.specify/f_vf_fluid/{spec,plan}.md`, `tests/modules/fluid/fluid_mirror.py`.
A repo search for Cahn–Hilliard, phase field, spinodal and shallow water found
no prior mention.
