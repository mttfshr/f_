# f_vf_lbm

**Type:** Processor (obstacle mask in → f_vecfield out) — **temporal / has memory**
**Status:** Verified by use (Matt, 2026-10-21; README ⚠ removed). Three Max benches are still unrun and the `tilt` dial has not been run in Max (see Known issues). Menu entry: `Lattice Boltzmann`, in ∇ Fields (the menu was regrouped 2026-10-22).

_Reference written 2026-10-22 from `src/f_vf_lbm/` (definition + codeboxes), `.specify/stable/f_vf_lbm/{spec,tasks}.md`, `HANDOFF.md` and the module's tests. Where the spec and the shipped module differ, this doc follows the shipped module._

---

## What it does

A 2D **Lattice Boltzmann** channel-flow solver (D2Q9, BGK collision) around an obstacle. A mask texture goes in (white = obstacle), a steady wind blows left to right, and the **velocity vecfield** of the wake comes out. Feed the outlet to the vecfield inlet of `f_vf_advect`, `f_vf_warp`, `f_vf_streak`, `f_vf_glow` or any other consumer.

It does not move any texture, like `f_vf_fluid`. Unlike `f_vf_fluid`, it is a *channel*: flow enters through the left edge, leaves through the right, wraps top to bottom, and separates around whatever the mask paints. At the default settings the wake sheds vortices (a Kármán street) after a long warm-up.

With the mask inlet unconnected (or black) there is no obstacle: the output is a uniform wind with a tiny sideways ripple to break symmetry.

Compared with `f_vf_fluid`: use `f_vf_fluid` for a field that keeps swirling after you stir it with any force; use `f_vf_lbm` when you want flow that goes *around a shape*.

The solver is a fixed **192 × 108** lattice (literal `W = 192; H = 108` in each codebox). Only the encode stage follows the render size.

---

## Signal Flow

One inlet (the mask texture, plus control messages on the same physical inlet), one outlet.

```
hold -> collide -> stream -> mac -> enc          (stream -> hold: the feedback edge)
                             mac -> mprev -> enc (previous velocity, for the Speed blend)
mask inlet -> collide (second inlet)
```

The solver state is **one 192 × 324 float32 texture**: the three RGBA state planes (nine populations) stacked vertically (the "state atlas"). One texture means every solver stage has a single hot inlet. A first version with three state textures out of three outlets of one `jit.gl.pix` depended on the undocumented order jit.gl.pix fires its outlets, and live it stepped with planes from different frames and made noise in an empty channel.

| Stage | Job |
|---|---|
| `hold` | The loop break: a one-frame delay of the state atlas (identity), triggered by the frame gate |
| `collide` | Fused macro quantities + equilibrium + BGK collision + bounce-back + Zou/He inflow + zero-gradient outflow, y periodic. Box-averages the render-size mask itself. Seeds a valid equilibrium when the state is empty or non-finite |
| `stream` | Gather: `new[x] = old[x − e_i]`, explicit periodic indices |
| `mac` | `ux`, `uy`, `rho` from the streamed state, one texel per cell (192 × 108) |
| `mprev` | One-step delay of the `mac` texture |
| `enc` | Render-size bilinear upsample, gain, clamp, f_vecfield encode, Speed blend, bypass gate |

**Frame gate (raw boxes).** `r draw` goes through `[t b b]`: first to a counter that passes every Nth bang to `hold` (N from the Speed menu), last to `enc`. A skipped frame leaves the whole solver idle and `enc` re-renders, so Speed 1/N slows the flow to 1/N. `mprev` copies the current velocity just *before* each step, and `enc` shows `mix(previous, current, phase / N)` with `phase` = 1..N, so the output moves continuously, about N frames behind.

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `omega` | float | 1.0–1.98 | 1.97 | BGK relaxation rate. Low = thick and smooth, high = thin and turbulent. The top of the range is the stability limit; the codebox clamps to [0.5, 1.98] |
| `inflow` (label **Wind**) | float | 0.0–0.1 | 0.08 | Inflow speed in lattice units; the codebox clamps to [0, 0.1] |
| `tilt` | float | −30–30 | 0.0 | Wind direction in degrees: 0 = straight left to right, positive = toward the top. The speed stays Wind (split into x and y parts). The flow still enters through the left edge and wraps top to bottom. Large angles are less accurate. The codebox clamps to ±30 too |
| `gain` | float | 0.0–10.0 | 3.0 | Scale applied to velocity before encoding (clamped to the vecfield range) |
| `speed` | menu | Full, 1/2, 1/3, 1/4 | Full | The solver advances every 1st, 2nd, 3rd or 4th rendered frame. Slower = the same wake in slow motion. No pix attribute: the menu feeds the frame gate's counter |
| `bypass` | toggle | 0/1 | 0 | Outputs an exactly neutral vecfield (0.5, 0.5, 0.5, 1). The solver keeps running underneath |

Internal, never set by hand: `bypass_gate` (bypass jsui), `phase` and `nsteps` (the frame gate, for the Speed blend).

The `Wind` label is the user-facing name of the `inflow` param; the routed message is `inflow`.

---

## Algorithm

- **Lattice and collision.** D2Q9 (order: 0 rest; 1 (1,0); 2 (0,1); 3 (−1,0); 4 (0,−1); 5 (1,1); 6 (−1,1); 7 (−1,−1); 8 (1,−1)). Equilibrium `wt · rho · (1 + 3·eu + 4.5·eu² − 1.5·|u|²)`, BGK relaxation with `omega`.
- **Write order per cell** (the experiment's): pre-collision copy, outflow copy, macro quantities, inflow, equilibrium, right-population overwrite, BGK collision, bounce-back.
- **Bounce-back** reads the cell's populations as held at the start of the frame, before the outflow copy and before collision (pre-collision values, FR-003).
- **Inflow (first column).** `ux = inflow·cos(tilt)`, `uy = inflow·sin(tilt)` on the interior rows, then the Zou/He density `rho = (rest + 2·leftward) / (1 − ux)`; the rightward populations take the equilibrium.
- **Outflow (last column).** The three leftward populations copy from the column to the left (zero gradient).
- **y is periodic** (decided 2026-10-21): the top and bottom rows are ordinary rows.
- **Mask.** Luma `0.299 R + 0.587 G + 0.114 B` averaged over a 4 × 4 grid of nearest taps across the cell's footprint (exact at 1:1, a box filter when the mask is larger). Obstacle where above 0.5; no soft weight (a fractional value is a full obstacle). The **first and last columns are never obstacle** (a covered outflow column drained mass and drove a jet ten times the inflow). An unconnected mask reads black = no obstacle.
- **Seed and self-heal.** A cell whose populations are non-finite, whose density is outside (0.2, 5) or whose rest population is not above 0.05 restarts at equilibrium with `rho = 1`, `u = inflow`, plus a tiny sideways ripple `0.02·inflow·sin(0.3x)`. Selection uses `switch()`, never `mix()` (`mix(NaN, x, 1)` is still NaN).
- **Encode.** `R = clamp(0.5 + gain·ux, 0, 1)`, `G` likewise with `uy`, `B = 0.5`, `A = 1`. The upsample is a manual 4-tap bilinear: y periodic, x clamped to the end columns. A non-finite sample encodes as zero velocity.

---

## Notes

- **Shedding is slow to start.** At omega 1.97 and Wind 0.08 the wake needs roughly 1100 to 1800 frames to begin shedding, and the period is about 16 s at 60 fps (29 s at Wind 0.06, 12 s at 0.1). Shedding is clean from Wind about 0.06 up, weak at 0.04 and absent at 0.02. This is a long-warm-up module, not an instant one (T012: Matt accepted it).
- **Wind 0 does not stop a developed flow** at omega 1.97 (peak |u| 0.136 at +3000 frames; it decays fast at omega 1.5). There is no reset control; lowering Omega is the damper.
- **The left-edge noise band is accepted, not a bug.** A ~20-column band of ragged, flickering colored noise along the inflow edge is inherent to an open inflow edge of a low-viscosity LBM (turbulence at the leading edge, upstream of everything else). Closed 2026-10-21; do not re-chase it. The edge feather and Wind slew that were tried against it were removed. No cap on the Wind / Omega dials, by Matt's choice.
- **Mach ceiling.** Wind 0.1 with omega near 1.98 reaches a local Mach number of about 0.36, above the usual 0.3 validity limit.
- **Tilt is slow to show.** The across-stream part travels downstream at about the flow speed (~0.075 cells/frame): the front reaches column ~60 by frame 1000 and the whole channel by about 2500 frames (about 40 s at Speed Full and 60 fps). A tilt change shows first at the left and sweeps right. A tilted inflow is rougher (peak speed about 0.088 at Wind 0.08; density 0.97 to 1.01).
- **Bypass** outputs a neutral vecfield with the solver running (decided 2026-10-21, T011), so releasing bypass resumes the developed wake. The module has no passthrough, because its one inlet is a mask, not a field.
- **Panel width is 197 px** (five controls: Omega, Wind, Tilt, Gain, Speed). The Speed menu's object id is wired by hand in the frame gate (`obj-32`); adding a param before it shifts that id and the contract test reports `unrouted speed`.
- **Output is a velocity field in lattice units.** Gain 3 puts the free stream near 0.74 encoded; gain 1 would sit within 0.05 of the centre.

## Known issues / open

- **Not run in Max: `tilt`.** Built in the mirror, codebox, definition and menu size on 2026-10-22 (mirror tests green). It has not been opened in Max and the change is uncommitted. `bench_vf_lbm_module.py` has no Tilt case.
- **Three benches unrun:** `bench_vf_lbm_module.py`, the `f_vf_lbm` row of `bench_modules.py`, and the slow 100-frame chain (`tests/bench.sh --slow`).
- **Reset control** (restart from rest) does not exist. Capping Wind/Omega at the top corner is open.
- **Spec drift.** `.specify/stable/f_vf_lbm/spec.md` says "Draft — not yet built" and describes three state textures, a separate `mrg` stage and two solver codeboxes; the shipped chain is the atlas above. T004's wording that Zou/He forces the whole inflow column differs from the mirror and codebox (interior rows only, FR-005).
- **Name** (`f_vf_lbm` versus `f_vf_karman` / `f_vf_obstacle`) was kept by default (T010); decide at Phase 3.
- **Cost not recorded.** NF-001 has no measurement in `tasks.md`.
- **Float32 vs float64:** the two paths diverge by 0.02 in 30 frames at omega 1.99; slow mass drift with bounce-back plus Zou/He.
- **Helpfile (T040)** does not exist yet.

## Verification

- `tests/modules/vf_lbm/` — NumPy mirror (`vf_lbm_mirror.py`), `test_vf_lbm.py` 17/17 (including the two tilt tests).
- `tests/modules/vf_lbm/bench_vf_lbm.py` — per-stage GPU against mirror, 16/16 green after the atlas rewrite: every stage within about 3e-7 (`enc` 5e-6, scales with gain), both bounce-back and pre-collision traps pass on the GPU.
- Live check: the module bench with a black 192-wide mask at default settings matches the mirror exactly (calm edges, uniform interior). This empty-channel check is what found the three-texture ordering bug.
- Mirror probes: `scratch/lbm_*.py` (Wind sweep, long runs, flicker, tilt).

## References

- D2Q9 BGK Lattice Boltzmann with bounce-back; Zou/He velocity inflow. Research notes: `ideas/ceyron_simulation_scripts_notes.md` section 2; architecture spike `tests/records/spike_lbm_d2q9_architecture.py`.
- Related: `f_vf_fluid.md` (same chained-pix pattern, `hold` idiom), `f_ks.md` (state-loop pattern), `f_vecfield_type.md` (output contract).

## Source Files

`src/f_vf_lbm/definition.py`, `src/f_vf_lbm/codebox_{hold,collide,stream,mac,mprev,enc}.gen`, `package/patchers/f_vf_lbm.maxpat`, `.specify/stable/f_vf_lbm/{spec,tasks}.md`.
