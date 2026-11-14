# The jit.gl.pix object around the codebox

Part of the jit-gen-codebox skill. Behavior of the `jit.gl.pix` object itself
(not the GenExpr inside it) that shows up as codebox bugs. Max 9.

Contents: `dim` · inlet and outlet counts · unconnected inlets · texture
messages and renders · Params after loading a gen · native `@bypass` · names
that collide · compile errors · feedback and output quantization · reading
results back exactly

---

## `dim`: pixel size, and whose size

`dim` is pixel dimensions (e.g. 640 x 480), not normalized: use it for aspect
(`aspect = dim.x / dim.y;`), and `norm` for normalized positions.

**It is the pix's size, which followed its FIRST INPUT** (bench 2026-10-26):
a 256x144 first input read `dim = (256, 144)` and matched a 16:9 reference
to 5e-6; a 4x4 stand-in first input read square and matched the square
reference instead, 0.73 off the other way, while the output was 256x144 both
times. In a render chain this works because the first inlet usually carries a
render-sized texture. So when testing a codebox that uses `dim`, give the
first input the render's size or take the aspect from a Param. A pattern that
matches its reference only at aspect 1, or a cutoff on `dim.y` that flattens
everything, is this.

---

## Inlet and outlet counts

- **The pix's inlet count follows the gen patcher's `in` objects,** not only
  what the codebox references (bench 2026-09-22): a `.genjit` with `in 1..3`
  (only `in 1` wired to the codebox) gives a 3-inlet pix, and cords into
  inlets 1-2 survive and deliver. Useful for keeping inlet counts stable when
  swapping gen patchers (`inputs` is read-only).
- **An unwired `out N` compiles, keeps its outlet, and emits an all-zero
  texture** (bench 2026-09-22). Handy for keeping outlet counts constant.

## An unconnected inlet reads a constant (0, 0, 0, 1) — 2026-10-07

An inlet nothing is cabled to does not read stale data or garbage:
`sample(in2, norm)` returns black **with alpha 1** (one distinct value across
the whole image). A guard that asks "is this input absent?" must test the
color channels, not alpha. Example: a decoder whose real data encodes zero as
0.5 can treat an input that reads exactly 0 in R and G at a few fixed points
as absent.

---

## Texture messages and renders — bench 2026-09-22

- **A texture message sent to the pix (e.g. from js `message()`) lands on
  input 0** regardless of `activeinput`; `sendinput N jit_gl_texture name`
  did *not* set input N. Use physical cords for inputs 2+.
- **Every texture message a pix receives triggers a render.** Sending it a
  second texture per frame doubles the work downstream.
- **A newly loaded gen compiles at its first render.** Params sent right after
  `gen <name>`, and even on the next draw bang (which fires before the
  render), hit "jit.gl.pix: invalid message <param>". Send Params a couple of
  frames later.

---

## Native `@bypass` skips the shader and flips secondary outlets — 2026-09-23

With the native `bypass` attribute on, outlet 1 equals input 0 exactly, but
outlets 2+ output input 0 **vertically flipped** (exact `flipud`), and codebox
logic like `mix(x, y, bypass)` never executes. Seen on 11 multi-outlet
abstractions (two more multi-stage ones differed). To give secondary outlets a real bypass state, drive a Param with
a *different* name (`bypass_gate 1`) and leave the native attribute off.

---

## Names that collide

### A control named like a `jit.gl.pix` attribute binds to the attribute — 2026-10-24
A builder/UI-side trap that looks like "a codebox Param that does nothing". A
control's `param_connect` addresses `<pix object>::<control name>`; if
`jit.gl.pix` has a native attribute of that name, the control binds to the
**attribute** and takes its type and range. A dial named `depth` became Type
Int, Range 0 1 (the pix has an int 0/1 `depth` attribute); a dial named
`texture` snapped back to its minimum (native `@texture` takes a texture-name
list). Give the control a token that can't be a pix attribute (`pulse_depth`,
`grain`, `out_mode`, not `depth`, `texture`, `output`, `mode`), keep the plain
word in the label, and scan control names against the pix's attribute list
before first use. (The `.maxpat` side is in maxpat-json-authoring.)

### Two instances with the same bare `@name` collide — 2026-10-17
Ob3D `@name` bindings are global to the GL context. Two copies of an
abstraction whose pix is bare-named (`sharpen_pix`) in one context error
"name already in use. ob3d does not allow multiple bindings", and the loser's
Params go unset ("no attribute ... on target pix"): it renders its inlet
passthrough. Prefix names bound inside an abstraction with `#0_`
(`#0_sharpen_pix`); Max substitutes the instance id, making each binding
unique.

---

## Compile errors

### A compile error in a saved patch falls back to passthrough — live 2026-10-17
A broken gen graph ("patchcord source not found: deleting patchcord" on load;
an untapped input typed dead: "type is not a sampler") made the pix render its
first inlet texture UNCHANGED, whatever the dials. A test harness that wraps
the code in its own gen patcher never sees this; only loading the real saved
patcher does. A pix "acting like a passthrough": suspect the gen graph or the
compile first, the math second.

### Compile errors are catchable, but never wire `[error]` straight into `js` — bench 2026-09-22
A gen compile failure posts `codebox: <message>` to the Max window (e.g.
`codebox: addition op missing argument`), and `[error 1]` does output it.
Wiring `[error]` directly into a `js` object recursed (js re-reported the
error, `[error]` caught that) until Max hit a stack overflow, which disables
*all outlets in Max* until the yellow bar is cleared. Safe shape:
`[error 1] → [deferlow] → [prepend some_name] → js`, with a handler that never
posts or throws.

---

## Feedback and output quantization — bench 2026-09-22

- **char pix output quantizes round-to-nearest, clamped to [0, 1]** (not
  floor). In a char feedback loop every step re-quantizes: increments below
  0.5/255 per step never accumulate.
- **Feedback into a non-left pix inlet is a clean one-frame delay**
  (a state/pass loop): stepping is frame-exact, verified with an exact counter
  over 20 steps and a closed-form decay accumulator.

---

## Reading results back exactly — bench 2026-09-22

**Float32 readback is exact:** texture → `jit.matrix @type float32` via the
matrix's `jit_gl_texture` method, then `write` to `.jxf`, round-trips values
outside [0, 1] bitwise. Matrix planes are ARGB. This is how a codebox can be
checked numerically against a NumPy reference.
