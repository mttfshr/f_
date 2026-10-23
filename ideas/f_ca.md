# f_ca — discrete cellular automata generator (working name)

_Status: ⚪ concept only. Drafted 2026-10-23 from the webgpgpu mining run
(`webgpgpu-ideas-1`). Not specced, not tried in Max._

## Concept

`f_` has continuous pattern generators (`f_ks`, and `f_wc` once built) but no
discrete-state automaton. One generator with a rule menu, rather than one module
per rule (the library's general-tool taste):

- **Life** (`games/lesson_11_game_of_life`): 8-neighbour count, birth/survival.
  The web version also writes cell change (mature, newborn, died) into a tile id
  so the same texture drives a palette, and keeps a diffusing trail channel
  (0.95-decayed five-cell average maxed with the live bit) that leaves a fading
  wake around dead regions (`lesson_17b`). A rare spontaneous birth keeps it
  from dying out.
- **Ising / Metropolis** (`lesson_23_ising`): spins in {-1,1}, von Neumann
  neighbour sum, acceptance `r = 1/(1+exp(q))` compared against a per-texel
  random. One temperature dial sweeps from large aligned domains, through
  flickering fractal boundaries at the critical point, to salt noise.
- **Forest fire** (`lesson_13_forest_fire`): trees grow on a rare random event,
  fire is a countdown, spread probability proportional to burning neighbours;
  gives a slow self-organising front rather than chaos.
- Dendrite-growth variants exist in `lesson_12_*` (four files); not examined by the
  run, so treat as unknown.

## What f_ has today

No cellular-automaton, Ising or percolation module anywhere in the inventory or the
ideas index. Closest: `f_ks` (continuous chaos), `f_vf_lbm` (a grid solver with a
fixed internal resolution, a useful architectural precedent).

## Proposed shape

- Signature: optional seed texture -> texture (cell render) + scalar (trail or age),
  temporal.
- Rule menu: Life, Ising, Forest fire (later: dendrite). Dials common to all:
  steps per frame, seed density, reset; per rule: birth/survive preset, temperature
  and field bias, growth/ignition/spread probabilities, trail diffusion.
- Internal low-resolution grid with nearest upsampling (the `f_vf_lbm` 192x108
  pattern); one-bit state at render resolution is brittle.
- State as float32 on the usual feedback pattern; the web's 8-bit packing
  (tile id in red, state in green, trail in blue) is not needed.
- **Per-frame randomness** is what the stochastic rules need. The web library keeps
  a persistent noise texture that a small chaotic map advances every frame. In
  GenExpr the safe route is the sin-hash seeded by a per-frame time uniform;
  `noise()` is a known silent failure. A shared noise helper also serves `f_wc`
  (see `f_wc_from_webgpgpu.md`).

## Tier-1 checks (exact)

- Life: a glider translates (1,1) every 4 steps; a block and a beehive are fixed
  points; NumPy mirror matches state bit for bit from a fixed seed.
- Ising: the sweep should show the Onsager transition at T_c = 2/ln(1+sqrt 2)
  ~ 2.269 (J = k_B = 1). **The omp draft wrote this as `1/ln(2+sqrt 2)`, which is
  0.81, not 2.269; the verifier missed it.** Use the corrected form.
- Forest fire: front speed and the critical ignition probability against the known
  percolation regime.
- Trail channel equals the 0.95 recurrence exactly.

## Risks and open questions

- Life is a known quantity and may read as retro; the distinctive part of the web
  source is the companion channels (age, diffusing trail), which turn a binary CA
  into a graded temporal image.
- A fresh random stream every frame is an architecture risk shared by all stochastic
  rules; acceptance randomness needs a well-behaved hash or the dynamics freeze
  wrongly. Histogram-check the hash on the actual sample grid.
- Multi-state rules multiply the testing surface per rule variant.
- Compare with `f_vf_lbm` before deciding the internal grid and the steps-per-frame
  budget.

## Related

`f_ks`, `f_vf_lbm`, `f_wc` (noise source), `f_vf_seeds` (placement, not cells).

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 45, 46, 49, 13 (Life, Ising,
Life with age trail, stochastic multi-state family) and the persistent-noise
utility in `SUGGESTIONS.md`. Verified by subagents against the lesson files and
the f_ inventory; the Ising critical-temperature expression was wrong in the
draft and is corrected above.
