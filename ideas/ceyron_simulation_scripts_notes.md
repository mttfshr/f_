> **Source:** github.com/Ceyron/machine-learning-and-simulation,
> `english/simulation_scripts/` (cloned locally to
> `/Users/matt/Github/machine-learning-and-simulation`). Reference CFD/
> spectral-method implementations (Python/JAX/Julia) from Felix Köhler's
> YouTube series — not GPU shader code, but the reference math/algorithm
> is directly relevant to the `f_vf_advect`/vecfield family.
> **Status:** first-pass notes, read but not yet discussed against
> production code in detail (no scratch patches, no architecture
> decisions made). Flagging what's worth a real session.

## Files actually read this pass

Fully read: `stable_fluids_python_simple.py`, `kolmogorov_turbulence.jl`,
`taylor_green_turbulence.jl`. Headers/docstrings only (confirmed domain,
not full algorithm): `lattice_boltzmann_method_python_jax.py`,
`smoothed_particle_hydrodynamics_simple_python.py`,
`kuramoto_sivashinsky_2d_and_3d_no_videos.ipynb`, `stable_fluids_fft.jl`.

**Not read this pass** (lower expected relevance, flagged for later if
wanted): `stable_fluids_fft_3d.jl` (almost certainly the 3D version of
the FFT technique already confirmed 2D via `kolmogorov_turbulence.jl` —
low priority, same "no fit" 3D pattern would likely apply), `flow_over_a_step.py`,
`lid_driven_cavity_python_simple.py`, `pipe_flow_with_inlet_and_outlet_python.py`,
`pressure_driven_pipe_flow_python.py` (internal channel/pipe-flow CFD
demos — walls, inlets, outlets; `f_` has no channel/duct concept, these
are likely a "no fit" architecturally but not confirmed), the six
`lorenz_*` files (chaotic ODE attractor, not a field — a stretch as a
scalar/vector modulation source, not vecfield-shaped, lowest priority).

---

## 1. FFT-based Stable Fluids — real, significant finding

**File:** `kolmogorov_turbulence.jl` (2D, forced turbulence variant),
confirmed general-purpose in `stable_fluids_fft.jl` (2D, arbitrary
forcing).

This directly reopens the "deliberate non-goal" framing in
`ideas/vorticity_confinement.md` and the HANDOFF summary of GPU Gems 1
Ch. 38 — the reasoning there was: diffusion and pressure projection each
need 20-80 Jacobi iterations per timestep, too expensive for real-time
multi-module live use, so `f_vf_advect` correctly implements only the
advection step and skips both.

**That cost assumption doesn't hold if FFT is available.** In the
spectral formulation, both steps become single elementwise operations
in Fourier space, no iteration at all:

- Diffusion: `w = exp(-k^2 v dt) * w_hat` — one multiply per frequency bin.
- Pressure projection: `q = w_hat . k / |k|`, then `w_hat - q*k/|k|` — a
  divergence and a subtract, both elementwise in Fourier space, no
  Poisson solve.

So the real question isn't "is projection too expensive" — it's
whether a 2D GPU FFT is available anywhere in this pipeline at all.

**Checked this session (2026-07-03): `jit.fft` exists, but it's not
GL-space.** Searched the full Max/Jitter reference doc set
(`/Applications/Max.app/Contents/Resources/C74/docs/refpages/`) for
fft/fourier/spectral. Findings:
- `jit.fft` is real and does exactly the right math — 2D matrix FFT/IFFT,
  2-plane complex input (plane 0 real, plane 1 imaginary), up to 32
  dimensions, `inverse` attribute for direction. But it's a CPU-side
  `jit.matrix` object (`category="Jitter Analysis"`), not a
  `jit.gl.texture` operation.
- Everything else with "fft" in the docs (`fft~`, `ifft~`, `pfft~`,
  `mc.fft~`, `fftin~`/`fftout~`, `windowed-fft~`) is MSP audio-rate, 1D —
  irrelevant.
- No `jit.gl.fft` or any GL-prefixed fft/fourier/spectral object exists
  anywhere in the reference docs.

**This reframes the question rather than closing it.** Using `jit.fft`
on vecfield data means: GPU→CPU readback (`jit.gl.asyncread` or similar)
of the texture into a `jit.matrix`, run `jit.fft` on CPU, re-upload the
result as a texture — a full round-trip every frame. That's exactly the
"no CPU-GPU round trip anywhere in the pipeline" constraint that ruled
out several GPU Gems techniques already (persistent-particle-state
methods, etc.) — this would be the first place in `f_` breaking that
invariant.

**Not a closed door, but now a cost question, not an availability
question.** Whether a per-frame readback→FFT→upload round trip for a
640×640 (or whatever the working resolution is) 2-plane matrix is fast
enough to be worth it at live-performance framerates is unmeasured.
**Next step if pursued: a scratch-patch fps test of the round-trip alone**
(readback → `jit.fft` → upload, no actual field math yet) — measure
before deciding anything architectural, same "experiment before
building" discipline as everywhere else in this library.

**If it turns out to be available:** this would mean actual
incompressible fluid flow (not just advection-only) becomes cheap enough
for live use, which is a materially different `f_vf_advect` than what
exists today — currently explicitly non-incompressible/non-diffusing by
design. Worth a real "is this true incompressibility even a thing we
want" architecture discussion before chasing it, independent of the
feasibility question — advection-only already has a specific
"excitable/amplifying" character (per HANDOFF, `decay > 1.0`) that true
incompressible flow might remove.

**Smaller, always-available idea regardless of FFT availability:** the
Kolmogorov-forcing scenario itself (sinusoidal forcing along one axis,
periodic domain, self-sustaining turbulence) is a clean, well-understood
forcing pattern worth trying against the existing advection-only
`f_vf_advect` even without projection — periodic sinusoidal forcing plus
pure advection (no projection) won't be incompressible or physically
"correct," but might still produce an interesting self-sustaining flow
character worth a quick empirical test, since it needs zero new code —
just a specific forcing-field input to what already exists.

## 2. 2D Lattice Boltzmann (D2Q9) with obstacle bounce-back — reopens a
previously closed question

**File:** `lattice_boltzmann_method_python_jax.py` (header/docstring
only, not the full step-by-step code).

GPU Gems 2 Ch. 47 was already read and ruled "no fit" — but that chapter
was specifically 3D D3Q19 (19 channels/node, 3D voxel domain, depth-peel
obstacle voxelization). This script is 2D D2Q9 (9 channels/node, flat 2D
domain, flow around a cylinder producing a von Karman vortex street) — a
categorically lighter, 2D-native version of the same method family that
was never actually evaluated on its own terms.

**Why this might actually fit `f_`'s architecture, unlike the 3D case:**
- 9 distribution values per cell could plausibly pack into ~3 RGBA
  textures (or fewer with a reduced lattice, e.g. D2Q5).
- BGK collision is a per-cell local computation — same shape as
  everything else in a `jit.gl.pix` codebox.
- The streaming step (each cell reads its neighbor's pre-collision value
  offset by `-e_i`) is a gather, not a scatter — directly expressible as
  a directional texture sample, the same idiom already used throughout
  the vecfield family (`f_vf_streak`, `f_vf_glow`, etc.).
- Obstacle bounce-back (no-slip on a 2D shape) could plausibly be driven
  by a mask texture — same idiom as the mod-texture inlets already used
  elsewhere in the library.

**Not evaluated: whether this is actually cheaper or more useful than
what exists.** `f_vf_repulse` already produces obstacle-like behavior
via a much simpler mechanism (16-sample ring accumulation, luma
threshold) — HANDOFF explicitly notes GPU Gems 2 Ch. 47 confirmed
`f_vf_repulse`'s approach is "a completely different, much cheaper
mechanism" than LBM. The open question this file reopens isn't "should
we replace `f_vf_repulse`" — it's whether a genuine obstacle-aware
incompressible-ish 2D flow (which `f_vf_repulse` doesn't actually
produce — it's a repulsion pattern, not a flow solve) is worth the real
complexity of a multi-texture, multi-pass collision+stream architecture.
This would be a materially bigger build than anything currently in `f_`
— worth a real architecture discussion, not a quick add, if pursued.

## 3. Kuramoto-Sivashinsky (2D) — a candidate for a genuinely new
generator module

**File:** `kuramoto_sivashinsky_2d_and_3d_no_videos.ipynb` (intro cell
only).

A chaotic, spatio-temporally turbulent PDE — balances a destabilizing
2nd-order term, a convective nonlinearity, and 4th-order dissipation —
that self-organizes into organic, worm-like/fingerprint-like patterns
from noise, with no external forcing needed (unlike Kolmogorov flow,
which needs continuous forcing to sustain turbulence). The notebook uses
a JAX spectral solver (`exponax`), but the underlying PDE doesn't
strictly require FFT — a real-space finite-difference scheme (explicit
timestep, local stencil for the Laplacian and biharmonic terms) is a
legitimate alternative, just needs a wider stencil (biharmonic is
roughly a 13-point stencil in 2D) than anything currently in `f_`'s
codeboxes.

**Why this might be a genuinely new module, not an extension:** none of
`f_`'s existing generators are self-sustaining chaotic feedback systems
— `f_chladni` is a fixed modal/wave pattern (deterministic, not chaotic),
the noise-based generators are per-frame stochastic (no memory). A KS
generator would need the same feedback-loop mechanism already proven and
understood (per HANDOFF's resolved `jit.gl.pix` feedback-loop findings —
the one-frame delay from closing a loop is expected and usable here, not
a bug), continuously evolving via its own dynamics rather than being
driven by external time-varying input. Closer in spirit to
`f_vf_advect`'s temporal accumulation than to any purely reactive
module.

**Not evaluated:** whether an explicit finite-difference timestep for a
4th-order PDE is numerically stable enough at real-time framerates
without adaptive timestepping (KS is famously stiff) — this is the kind
of thing that would need an "experiment before building" scratch test,
not a reasoning-from-the-couch answer.

## 4. Confirmations / no-fits, briefly

- **`stable_fluids_python_simple.py`** (non-FFT, CG-based diffusion +
  pressure projection): confirms the exact Stam pipeline `f_vf_advect`
  already implements the advection-only part of, and confirms Conjugate
  Gradient as the standard alternative to Jacobi iteration for the
  implicit solves — doesn't change the "too expensive without FFT"
  verdict, CG still needs multiple full-Laplacian evaluations per solve,
  same cost category as Jacobi. No new information beyond what GPU Gems
  1 Ch. 38 already established, other than confirming CG-vs-Jacobi is a
  choice of iterative method, not a way around needing iteration.
- **`taylor_green_turbulence.jl`** (3D pseudo-spectral DNS): same 3D
  architectural mismatch as everything else 3D in this research line —
  real voxel domain, 3D FFT. No fit, no new information.
- **`smoothed_particle_hydrodynamics_simple_python.py`**: CPU-side
  Lagrangian particle simulation (free-surface "pouring beer" scenario,
  particle-particle neighbor search, not incompressible). Same
  architectural shape already ruled out via GPU Gems 3 Ch. 7 (persistent
  per-particle state, no GPU-native neighbor query in `f_`'s pipeline).
  No new information, confirms the earlier verdict from a second source.

## Where to resume

Three real threads opened, one answered:
1. Answered: Max/Jitter has no GL-space 2D FFT — `jit.fft` is
   CPU-matrix-only (see finding #1 above). Next step, if this thread is
   picked up, is a scratch-patch fps measurement of the
   readback→`jit.fft`→upload round-trip cost, before any decision about
   whether it's usable at all.
2. 2D LBM (D2Q9) as a possible new obstacle-aware flow module — real
   architecture discussion needed (multi-texture packing, collision +
   streaming pass structure) before any code. Bigger scope than a
   typical `f_` module addition.
3. Kuramoto-Sivashinsky as a new self-sustaining chaotic generator
   module — needs a scratch-patch stability test of the biharmonic
   finite-difference stencil before any real commitment; the numerical
   stiffness question is real and unresolved.

None of these are scheduled. Captured here per Matt's request, ready to
pick up whenever.

## Addendum (2026-07-03) — GL-domain FFT discussion, and a cheaper alternative to test first

Talked through what it would actually take to hand-build a 2D FFT inside
`jit.gl.pix`/GenExpr, as an alternative to the CPU-roundtrip `jit.fft`
path in finding #1. No code, discussion only.

**Correction to an assumption made during that discussion:** I'd said
the non-power-of-2 resolution problem (radix-2 Cooley-Tukey needs a
power of 2, and 640 isn't one) was a constraint imposed by Vsynth's
render module. **Matt corrected this — Vsynth's render resolution
defaults to 640×640 but is user-configurable, not fixed.** This actually
makes the FFT-module idea a bit more tractable than I'd framed it: an
FFT-based module could legitimately run its *own* internal working
resolution (e.g. 512 or 1024, whatever power of 2 fits the performance
budget) independent of the overall Vsynth render resolution, resampling
at its input/output boundary same as any other module that wants a
different internal working size — this is a normal, already-available
degree of freedom, not a new architectural accommodation. Doesn't remove
the resample-at-the-boundary seam entirely, but it's a much smaller deal
than "the whole render chain is stuck at 640×640, non-power-of-2,
forever."

**Doesn't change the overall recommendation.** The pass-count concern
(~40 sequential full-screen passes for a forward+inverse 2D FFT round
trip at N=1024, vs. 1-4 passes for everything else in `f_`) and the
"doesn't fit the live-tunable philosophy" concern (fixed pass structure,
not something you turn a knob on) both stand regardless of resolution
configurability. The real open question is still whether this problem
even needs FFT at all.

**Agreed next step, captured per Matt's request — not started:** before
building anything FFT-related, scratch-patch a plain Jacobi
diffusion/projection loop *directly* in `jit.gl.pix` (no FFT, no
CPU roundtrip) and measure fps at some iteration count. This tests the
actual, specific claim behind the original non-goal (`ideas/vorticity_confinement.md`,
GPU Gems 1 Ch. 38's "20-80 Jacobi iterations, too expensive") empirically
in this pipeline, rather than relying on general GPU-literature reasoning.
It's also structurally the simplest possible experiment here: no
power-of-2 constraint, no complex-number texel packing, no bit-reversal
permutation, no CPU-GPU roundtrip — just N repeated passes of the same
simple Jacobi-update codebox, exactly the "N-stage forward chain, DRY'd
codebox with a stage/iteration-index param" shape `f_stereogram` already
proved out.

**If the Jacobi test comes back fast enough:** the FFT thread (both the
CPU-roundtrip `jit.fft` version and the hand-built GL-domain version)
becomes moot — solved more simply, no need to revisit either.
**If it comes back too slow:** *then* the FFT discussion above becomes
the next real thing to weigh, now armed with an actual iteration-count-
vs-fps curve from the Jacobi test to compare against the FFT's fixed
~40-pass cost, rather than comparing a measured number to an unmeasured
one.

This — the Jacobi scratch-patch test — is the actual next step for this
whole thread, superseding the FFT round-trip fps test from finding #1's
"where to resume" item as the higher-priority experiment to run first.
