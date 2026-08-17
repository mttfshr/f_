# f_vf_wilson_cowan (idea, not specced)

Vecfield producer based on the Wilson-Cowan neural mass model
(https://en.wikipedia.org/wiki/Wilson%E2%80%93Cowan_model): two coupled
scalar fields (excitatory E, inhibitory I) evolving under sigmoid
nonlinearity + local excitation / lateral inhibition coupling. Classic
reaction-diffusion-adjacent system — produces traveling waves, spatial
oscillation, limit cycles, Turing-like standing patterns depending on
params.

## Why it might fit f_
- Output E-I difference (or gradient of it) as an RG vecfield, same role
  as f_vf_advect / f_vf_potential.
- Inherently an ODE in time → needs jit.gl.node @capture 1 self-recursion
  (like optical_flow's temporal accumulation stage), not a stateless
  single-pass pix chain.
- Classic WC bifurcation params (E/I gain, threshold, coupling strength)
  are known for high pattern-selectivity from few knobs — fits the
  "disproportionately expressive levers" design goal.
- Possible resonance with parked f_breath_phase idea — WC (or WC-like)
  models are also used for CPG/respiratory rhythm generation, in case a
  biologically-motivated oscillator core is ever wanted instead of a
  simple envelope-driven phase ramp.

## Related paper: Butler et al. 2012, PNAS

Butler TC, Benayoun M, Wallace E, van Drongelen W, Goldenfeld N, Cowan J
(2012). "Evolutionary constraints on visual cortex architecture from the
dynamics of hallucinations." PNAS 109(2):606-609.
doi:10.1073/pnas.1118672109

This is the specific variant worth tracking: a diffusion term added to
the Wilson-Cowan equations to model long-range inhibitory connections in
V1. Core narrative — normal vision = excitation patterns driven by
external stimuli; hallucination = spontaneous self-organized excitation
patterns overwhelming that drive. The long-range inhibitory diffusion
term is what (evolutionarily) keeps the system out of the pathological
pattern-forming regime most of the time.

This is the direct mathematical lineage of the classic Ermentrout-Cowan
(1979) geometric hallucination forms: funnel, spiral, lattice/honeycomb,
cobweb — the recurring geometric categories reported in migraine aura,
psychedelic states, and hypnagogia. Loved reading about these shapes
specifically — potentially a strong visual/aesthetic target if this ever
gets built: the module's "look" could be explicitly aimed at reproducing
this specific taxonomy of forms rather than generic reaction-diffusion
texture.

Implementation implication: the long-range inhibitory term is a
diffusion/convolution across a wider spatial neighborhood than a typical
local Mexican-hat kernel — likely the main knob for actually landing on
funnel/spiral/lattice/cobweb forms specifically, vs. generic WC
patterning. Worth scratch-testing kernel radius and inhibitory diffusion
strength as the primary "pick a hallucination category" parameter.

### UI idea: WFG-style waveform-select dial, but for hallucination category

Nice parallel spotted: a WFG (waveform generator) typically has a select
dial with a little visual aid showing triangle/sine/square/etc. so you
can see what you're choosing before you hear/see it. This module could
do the same thing but for the funnel/spiral/lattice/cobweb taxonomy —
a discrete "form" selector with small glyph/icon previews of each
category, rather than (or in addition to) continuous kernel-radius /
diffusion-strength knobs. Continuous params would still drive the
underlying dynamics, but the categorical selector gives an immediate,
legible way to jump to "I want a spiral" the way a WFG dial gives you
"I want a triangle wave." Worth thinking about whether the four forms
map cleanly onto discrete parameter regions (i.e. is the mapping
actually clean enough for a dial) or if it's more of a fuzzy continuum —
this needs the underlying model implemented first before the UI
question can be answered for real.

## Open questions / risks
- Lateral-inhibition term is usually a difference-of-Gaussians convolution
  across neighbors — more expensive per-pixel than typical local-hash
  approach. Needs scratch-test for perf before committing.
- Not yet clear whether this should be its own family or a variant within
  f_vf_.
- No spec/plan/tasks yet — pure idea capture from a video lecture, no
  further research done.
