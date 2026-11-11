# f_vf_erode

**Type:** Processor with a state: a water-and-pigment solver. Inlets: picture (0), terrain (1), vecfield (2), background (3). Outlets: ink (composite over the background) and thickness.
**Status:** Built, benched and looked at live 2026-11-10. Benches green: codebox 17/17, module 5/5, tier 1 11/11. Live look (Matt, chat, 2026-11-10, at all defaults, with Feed raised on an animated input): "looks amazing". Helpfile, panel layout and menu category are still to do (see Known issues).

_Reference written 2026-11-10 from `src/f_vf_erode/` (definition and six codeboxes), `.specify/f_vf_erode/{spec,plan,tasks}.md` (gates T060-T095, ADR-1 to ADR-6) and the module's tests. Numbers marked inferred were worked out, not observed._

---

## What it does

A **solver, not a filter**. A picture goes in; on a **wetting** it becomes pigment lying on the paper and the frame is flooded. Water then runs over a terrain (inlet 1) pushed by a vecfield (inlet 2). Fast water lifts pigment off the paper and carries it. Slow and shallow water puts it back down, and water that has gone puts all of it down. Ink pools in the low places and leaves the high ones, with clean edges where the water stopped. The water dries away and the wash stands still.

- **Inlet 0**: the picture, plus control messages. Read at a wetting (and every frame while Feed is above 0).
- **Inlet 1**: the terrain. Luma is height. Optional: unconnected, the water is flat.
- **Inlet 2**: a vecfield that pushes the water. Optional: unconnected, no push.
- **Inlet 3**: the background the pigment sits on. Optional: white under Darker, black under Lighter.
- **Polarity.** **Darker**: the pigment filters the background (the picture is stored as absorbance). **Lighter**: it adds to the background (stored as light). A change takes effect at the next wetting.
- **Wet.** The Wet button (or a `wet` message) wets once. A held press wets once, not repeatedly. Wetting again before the wash has dried keeps the water, adds `flood`, replaces the paper pigment with the new picture and drops the old suspension.
- **Feed.** With Feed above 0 the module follows an animated or live input continuously, with no press: each step it deposits a fraction of what the picture holds beyond the paper's pigment, and relaxes the water toward `flood`. **Fade** returns ink above what the picture holds toward the picture, so a picture that gets lighter is followed and the frame cannot saturate to black. Feed 0 is wet-once exactly, and Fade does nothing then. Feed is not a frame delay: the memory is the water and pigment, moved by the terrain and the field.

Until the first wetting (and with Feed 0) the module returns its input, so an unwetted module is transparent. The solver steps once per rendered frame; releasing the button does nothing. At the defaults a wash from `flood` 1 dries in about 625 steps (inferred, arithmetic from `dry`; about 10 seconds at 60 fps).

---

## Signal Flow

Inlet 0: picture plus control messages. Inlets 1-3: terrain, vecfield, background. Outlet 1: ink. Outlet 2: thickness.

```
hold -> load -> transport -> react -> hold        (react -> hold is the feedback, cold)
prep -> transport, react                          (static face velocities and drive, cold)
react -> enc                                      outlets 1, 2
r draw -> hold, prep, enc        r dim -> enc, and `dim W 2H` -> hold, prep, load, transport, react
inlet 0 -> load (picture), enc    inlet 1 -> prep    inlet 2 -> prep    inlet 3 -> enc
```

The state is **one float32 texture at the render size, W x 2H**: two RGBA planes stacked vertically.

- Plane A: R water depth, GBA pigment in suspension.
- Plane B: RGB pigment on the paper, A the load flag (2 x loaded + the Wet gate as last seen; 0 = never loaded).

One texture keeps every stage to a single hot inlet (the `f_vf_lbm` finding). No stage has more than four inlets. The connected flags `src_terrain`, `src_field` and `src_bg` come from each inlet's `vs_inState`: an unconnected inlet is known from its flag, never from its value. The atlas stages are `@adapt 0` and take `dim W 2H` from the builder's `render_dim` key `atlas_stages`; they read W and H from the Params `width` and `height`.

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `polar_sw` | text button | Darker / Lighter | Darker | How the pigment is stored and composited. Takes effect at the next wetting |
| `flow` | float | 0–2 | 0.4 | How strongly the water runs downhill on the terrain |
| `push` | float | 0–4 | 1 | How strongly the vecfield moves the water. 0 equals no vecfield |
| `lift` | float | 0–1 | 0.7 | How readily running water takes pigment off the paper. A square curve: effective rate 0.9 * (d / 0.7)^2, so the default is the old 0.9 and the top of the dial is about twice that |
| `settle` | float | 0–1 | 0.19 | How readily slow water puts pigment back, so less is carried far. A cubic curve: effective rate 0.6 * d^3, 0.004 (the old default) at the default. Water that has gone puts all of it down regardless |
| `dry` | float | 0–0.02 | 0.0016 | Water lost per step. A dried wash is still |
| `speed` | float | 0–4 | 1 | Step size of each solver step, limited inside the solver for stability |
| `flood` | float | 0–4 | 1 | Water a wetting adds (and the depth Feed relaxes toward) |
| `feed` | float | 0–1 | 0 | Continuous source. 0 = wet once |
| `fade` | float | 0–1 | 0.02 | With Feed on: how fast ink above the picture's returns to it. Pooled ink lasts about 1 / `fade` steps |
| `wet` | button / message | — | — | The wetting. A held press wets once (the press edge, kept by the load flag) |
| `bypass` | toggle | 0/1 | 0 | Both outlets pass inlet 0. The solver keeps running underneath |

Internal, never set by hand: `wet_gate`, `src_terrain`, `src_field`, `src_bg`, `bypass_gate`, `width`, `height`. Ranges and defaults are provisional (tuning is Phase 2); the defaults gave the look Matt approved on 2026-11-10.

---

## Algorithm

Per frame, in order. Every length and rate is in **texels at one size**: scaling to the render size is not done yet (see Known issues).

1. **prep.** Terrain luma (0.2126, 0.7152, 0.0722) times 6 gives a height. The vecfield is decoded `(v - 0.5) * 2` and scaled by `push * 0.1`. For each cell's four faces it stores the static face velocity `speed * (-flow * (T_B - T_A) + 0.5 * (F_A + F_B))`, with A the left or up cell and B the right or down one; a face is stored by both of its cells from the same operands, so what leaves one arrives in the next, bit for bit. A second plane stores the lift and settle drive: the field minus `flow` times the terrain gradient.
2. **load.** On a Wet press edge: paper pigment = the picture in linear light (display ^ 2.2), as absorbance `-log(clamp(lin, 0.001, 1))` under Darker or as `lin` under Lighter; suspension emptied; `flood` added to the water. A state that was never loaded carries no pigment. Then Feed: `p += feed * max(pigment - p, 0) - fade * max(p - pigment, 0)` and `w += feed * max(flood - w, 0)`; feeding counts as loaded.
3. **transport.** For each face: `v = clamp(static - speed * flow * (w_B - w_A), -0.2, 0.2)`, the flux `q = v * min(w_up, 0.5) * clamp(w_up / 0.15, 0, 1)` from the upwind cell, and the suspended pigment `c_up * q + 0.04 * min(w_A, w_B, 1) * (c_A - c_B)` per channel (no channel ever mixes with another). Water and suspension then gain and lose through the four faces, and the water loses `dry * speed`. At the **frame edge** water and pigment leave (the cell beyond the frame has the terrain continued linearly and depth 0 as a donor), so nothing re-enters.
4. **react.** From the water's surface slope and the field, a speed measure `min(|drive| * speed, 0.2) * clamp(w / 0.15, 0, 1)`. Lift: paper to suspension by `clamp(lift * speed measure * min(w, 1), 0, 0.5)`, with `lift` the dial's curve and the speed measured in 1920-height texels. Settle: suspension to paper by `max(settle * speed * (1 - speed measure / 0.1), clamp(1 - w / 0.08, 0, 1))`, `settle` the dial's curve (the threshold was 0.03 before 2026-11-10; at that value the dial was nearly inert). It also clears non-finite and negative values from the state it writes back.
5. **enc.** Darker: `background * exp(-(p + s))`; Lighter: `background + p + s`; then display = linear ^ (1 / 2.2). Alpha from the picture. Outlet 2 is the luma of the pigment on the paper only (no water outlet). Before the first wetting, and with Feed 0, the picture is shown as if loaded. Bypass passes the picture on both outlets.

The constants (6, 0.1, 0.2, 0.5, 0.15, 0.04, 0.1, 0.08, 2.2, 0.001) are the NumPy mirror's, marked INFERRED there: starting values from the mocks, not tuned.

---

## Notes

- **Wet once, then it runs.** Changes at inlet 0 between wettings do not reach the wash (T074). Terrain and vecfield, however, are read live every frame, so a moving terrain or field steers the water.
- **Darker log floor.** Under Darker the stored log is bounded at 0.001 of linear light, so display values below about 0.043 come back lifted to it. Identity holds from there up (`G-linear-light`, widened from 0.004 on 2026-11-10).
- **Order of the three layers.** The whole solver works on the stored pigment, so Polarity changes only what is stored and how it is composited; one solver serves both.
- **Time is frames.** Drying and everything else step once per rendered frame, so the wash lasts twice as long on the clock at 30 fps.
- **Parser trap found by the bench.** In `codebox_enc.gen`, `exp(-(a + b))` compiled as `exp(-a + b)`: the sum is written `exp(-a - b)`. Worth a line in `skills/jit-gen-codebox/SKILL.md` (needs Matt's re-upload).
- **Uninitialised texture.** A texture nothing has written reads (0, 0, 0, 1), so its alpha would seed suspension; `load` ignores the pigment of a state that was never loaded.

## Known issues / open

- **Render-size scaling** (T083): constants are in texels, so at other sizes the physics scales differently (looser or tighter pools). The mirror and benches are at one size each (64 x 48 and 640 x 640). The look Matt approved was at his render size, not recorded.
- **Cost.** The probe codeboxes at 1080p were 6.3 ms upper bound for one step (`tests/logs/20261110-101838-bench.log`); the real stages are not measured (NF-102 asks only that it be recorded). Render size was kept (T065).
- **Animated input** is not in a bench (the harness feeds one static texture); Matt's live look covers it.
- **Panel layout** (`G-ui-density`): Polarity is in the title bar and Wet in the first slot of the dial grid (Matt, 2026-11-10); panel 190 x 150. Looked at in Max (Matt, 2026-11-10): fine; the helpfile text fits. **Menu category** (`G-menu`): placed under Color / Tone by Claude, provisional, Matt's to move. **Helpfile:** not written.
- **Frame-edge model and the lift/settle forms** are inferred; only the bowl and field tests (direction) and Matt's look check them.
- `tests/contracts/bench_modules.py` fails as a whole on `f_vf_fluid`'s frame size (640 against 512), not on this module; the `f_vf_erode` row is clean.

## Verification

- `tests/modules/vf_erode/test_vf_erode.py`: the float32 NumPy mirror, 11 tests (conservation open and closed edge, bowl, field push, stillness and identity, stability at the extremes, Polarity, input hygiene, Feed, Fade, mutations).
- `bench_vf_erode.py`: each stage's codebox on the GPU against the mirror, 17/17, worst error about 1e-6 (log `tests/logs/20261110-173333-bench.log`), plus host-sequenced chains (load then 10 steps, a fed still picture, a dark-then-light picture).
- `bench_vf_erode_module.py`: the shipped patcher, 5/5 (same log).
- `tests/build/test_render_dim.py` 13/13 for the new `atlas_stages` key; drift 16/16; contract test 9/9.
- Live (Matt, 2026-11-10): the look at all defaults with Feed on an animated input.

## References

Original to this library: the model was designed in development from four offline mocks (`scratch/experiments/f_ink_look/`, local) and takes no code or formula from an outside source.

- Conservative face fluxes, upwind donors and a flux limit are standard finite-volume practice; the state-atlas and hold pattern follow `f_vf_lbm.md` and `f_vf_ch.md`.
- `.specify/f_vf_erode/{spec,plan,tasks}.md`; `ideas/f_print_styles.md`. Related: `f_separate.md`, `f_vf_fluid.md`, `f_vf_stamp.md`, `f_vecfield_type.md`.

## Source Files

`src/f_vf_erode/definition.py`, `src/f_vf_erode/codebox_{hold,prep,load,transport,react,enc}.gen`, `package/patchers/f_vf_erode.maxpat`, `tests/modules/vf_erode/`, and `render_dim` `atlas_stages` in `build/build_patcher.py`.
