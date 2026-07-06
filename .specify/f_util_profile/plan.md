# f_util_profile — plan

_Status: ready to build_

---

## ADRs

**ADR-1: CPU row-averaging via jit.dimop, interpolation in JS**
Rather than iterating every pixel in JS (expensive at 640×640), `jit.dimop
@op avg @step 640 1` averages each row to a single value on the CPU,
producing a 1×height matrix before JS. JS receives one averaged RGBA pixel
per row — only `height` getcell() calls, not `width × height`. JS then
computes luma per slab and interpolates to 128.

Previous approaches tried and retired:
- `jit.gl.slab` pre-averaging (ADR-1 v1): failed — slab requires being part
  of the render chain, not triggered by texture message.
- `jit.resamp` downsampling: samples not averages — confirmed by test.
- `jit.3m`: global reduction only, not per-row.
- Single-pixel column sampling (getcell([0, row])): wrong — samples one
  pixel at column 0, not a row mean. Also had variable name conflict
  (resolution var vs resolution function) that silently produced 0.5 output.
- `jit.dimop @step 640 1` with vertical bands: correctly produces uniform
  output (expected — vertical bands have equal row averages). Confirmed
  working with horizontal bands (Angle=90°): per-row values vary. ✅

**ADR-2: Output via jit.gl.texture object, not jit.matrix message**
The output needs to be a named GL texture that downstream bpatchers can wire
into a texture inlet. `jit.gl.texture` with a fixed name (`profile_tex`) and
`@adapt 0 @dim 1 128` holds the output. The JS writes to a CPU matrix, sends
it to `jit.gl.texture`, which makes it available as a GL texture on the
outlet. This mirrors the Vizzie `vz.texture2matrix` pattern (inverted
direction).

**ADR-3: asyncread triggered by jit.gl.pix draw cycle, not texture message**
`jit.gl.asyncread vsynth` reads asynchronously on the vsynth render clock.
It does NOT fire from receiving a texture name message on its inlet directly.
A `jit.gl.pix vsynth @adapt 0 @type char` must sit between routepass and
asyncread — the pix draws to the vsynth GL context on each render frame,
which is what triggers asyncread to read. Without the pix, asyncread is
silent regardless of what is sent to its inlet.

Enable/disable is via `prepend enable` → asyncread inlet 2 (not inlet 0).
Confirmed working in scratch patch: profile updates in sync with WFG output.

**ADR-4: Bypass via gate on asyncread output**
When bypassed, the gate on asyncread output is closed — the JS object stops
receiving new matrices. The JS holds its last computed output matrix and
continues passing it to `jit.gl.texture`. This implements freeze-on-bypass
without any special JS logic; the JS just never receives a new bang to
recompute.

**ADR-5: f_util_profile uses a passthrough jit.gl.pix to trigger asyncread**
A `jit.gl.pix vsynth @adapt 0 @type char` is required as a passthrough
between routepass and asyncread. It has no codebox logic — it just draws the
incoming texture to the vsynth GL context, which is what asyncread hooks into.
This is the same pattern used by vs_capture. The pix outlet goes to asyncread
inlet 0; the pix codebox (if any) is a simple passthrough.

**ADR-7: Dual independent dimop passes for row and column profiles**
The asyncread output fans out to two independent processing chains. The row
chain uses `jit.dimop @op avg @step 640 1` (averages each row to one pixel,
producing a 1×height matrix). The column chain uses `jit.dimop @op avg @step
1 640` (averages each column to one pixel, producing a width×1 matrix). Each
chain has its own gate, JS file, and output texture. This gives genuinely
independent data on each axis — the column profile is not a transposition of
the row profile. Motivated by f_masonry, which has independent course and
column structure that benefits from independent modulation.

Two JS files (`profile_rows.js`, `profile_cols.js`) rather than one with two
outlets — each is simpler, independently testable, and takes a different-shaped
input matrix. `res_rows` and `res_cols` are separate params, each controlling
analysis sharpness on its axis independently.

**ADR-6: freq param is UI-only metadata**

---

## Signal flow (detailed)

```
inlet 0
  → routepass jit_gl_texture jit_matrix
      out0 (texture) → jit.gl.pix vsynth @adapt 0 @type char
                     → jit.gl.asyncread vsynth @enable 1
                         ├→ jit.dimop @op avg @step 640 1   [row averaging]
                         │   → gate_row (bypass-controlled)
                         │       → js profile_rows.js
                         │           → jit.gl.texture @dim 128 1 @name profile_rows_tex
                         │               → outlet 0
                         └→ jit.dimop @op avg @step 1 640   [col averaging]
                             → gate_col (bypass-controlled)
                                 → js profile_cols.js
                                     → jit.gl.texture @dim 1 128 @name profile_cols_tex
                                         → outlet 1
      out2 (unmatched) → route res_rows res_cols bypass
```

bypass jsui → attrui bypass → [closes both gates simultaneously]

---

## Phases

### Phase 1 — asyncread + JS skeleton in scratch patch

Goal: prove the GPU→CPU→GPU round trip works in a Vsynth context.

1. Build scratch patch at `~/Vsynth/patterns/util-profile-scratch.maxpat`
2. Wire: texture source → `jit.gl.asyncread @enable 1` → `js profile_compute.js`
3. Write `profile_compute.js` skeleton:
   - `outlets = 1`
   - `function jit_matrix(...)` — receives matrix, prints dimensions and
     first cell value to Max console. No aggregation yet.
4. Confirm: asyncread fires, JS receives matrix, dimensions are correct.
5. Add `jit.gl.texture @adapt 0 @dim 1 128` downstream of JS.
6. JS writes a flat test matrix (all 0.5) → texture → `jit.pwindow 1×128`.
7. Confirm: output texture visible, correct dimensions, flat grey.

Completion gate: JS receives real matrix data from asyncread, outputs a
visible 1×128 texture.

---

### Phase 2 — aggregation and interpolation in JS

Goal: `profile_compute.js` correctly computes the luminance profile.

1. Implement luma conversion in JS:
   `luma = 0.299*r + 0.587*g + 0.114*b`
2. Implement slab aggregation:
   - Accept `resolution` as a message, store as global
   - Divide matrix height into `resolution` equal slabs
   - Mean luma per slab → float array of length `resolution`
3. Implement interpolation to 128:
   - Linear interpolation from `resolution`-length array to 128-length array
   - Write to 1×128 `jit.matrix`, send to outlet
4. Wire `resolution` message (from a `live.numbox` for testing) into JS.
5. Verify with structured input:
   - Use `f_masonry` as upstream texture (strong horizontal bands)
   - Output should show clear band structure in `jit.pwindow`
   - Changing `resolution` should visibly coarsen/sharpen the profile
   - Changing `f_masonry` params should change the profile output

Completion gate: profile output visibly reflects upstream texture structure;
`resolution` param has visible effect.

---

### Phase 3 — bypass (freeze) behaviour

Goal: bypass holds last computed profile.

1. Add `gate 1 1` between asyncread output and JS inlet.
2. Wire bypass toggle → `sel 0 1` → gate open/close.
3. Verify:
   - Bypass off: profile updates every frame
   - Bypass on: profile freezes at last value, `jit.gl.texture` continues
     outputting that frozen texture
   - Toggle bypass on and off — profile resumes updating immediately

Completion gate: freeze-on-bypass confirmed.

---

### Phase 4 — bpatcher JSON build

Goal: production `f_util_profile.maxpat` rebuilt with dual-output architecture.

**Required objects:**
- `inlet` (texture in)
- `outlet` ×2 (outlet 0: row profile 128×1; outlet 1: col profile 1×128)
- `routepass jit_gl_texture jit_matrix`
- `route res_rows res_cols bypass` (control dispatch)
- `jit.gl.pix vsynth @adapt 0 @type char` (passthrough — triggers asyncread)
- `jit.gl.asyncread vsynth @enable 1`
- `jit.dimop @op avg @step 640 1` (row averaging)
- `jit.dimop @op avg @step 1 640` (col averaging)
- `gate 1 1` ×2 (gate_row, gate_col — bypass-controlled)
- `js profile_rows.js`
- `js profile_cols.js`
- `jit.gl.texture @adapt 0 @dim 128 1 @name profile_rows_tex`
- `jit.gl.texture @adapt 0 @dim 1 128 @name profile_cols_tex`
- `live.numbox` for `res_rows` (int, 1–128, default 64)
- `live.numbox` for `res_cols` (int, 1–128, default 64)
- `live.numbox` for `freq` (int, 1–64, default 8) — UI only
- `bypass_toggle.js` jsui → `== 0` → both gates
- `autopattr @varname profile_autopattr`
- `moduleSize.js` chain
- Title comment + panel
- `parameters` block registering `res_rows`, `res_cols`, `freq`, `bypass`

**UI layout:**
- Three numboxes: `res_rows` (left), `res_cols` (center), `freq` (right)
- Labels below each
- Bypass toggle top-right (standard position)
- Panel wider than original single-param version

**Note:** Phase 4 is a rebuild of the existing `f_util_profile.maxpat`.
The build_patcher.py `util` archetype generates the shell; the dual internal
chain must be hand-wired in Max.

Completion gate: bpatcher opens in Max, both outlets active, all params
save/restore via autopattr.

---

### Phase 5 — integration test with f_masonry

Goal: both profile outputs independently drive modulation inlets on f_masonry,
producing visible axis-independent spatial modulation.

1. Wire `f_masonry` → `f_util_profile`. Confirm both outlets produce textures.
2. Wire outlet 0 (row profile) → courses modulation inlet on a second
   `f_masonry`. Confirm visible per-row modulation.
3. Wire outlet 1 (col profile) → columns modulation inlet. Confirm visible
   per-column modulation independent of the row modulation.
4. Sync `freq` on `f_util_profile` to `f_masonry`'s `courses` and `columns`
   params. Confirm band alignment on both axes.
5. Sweep `res_rows` and `res_cols` independently — confirm each affects only
   its axis without disturbing the other.

Completion gate: visible independent spatial modulation on both axes confirmed
in a real signal chain.

---

## Open questions going into build

- **`jit.gl.asyncread` name/context:** ✅ RESOLVED — `jit.gl.asyncread vsynth`
  Context name is the first positional argument. No `@drawto` needed. Confirmed
  from 9 instances across Vsynth source (vs_envelope, vs_capture, vs_scope, etc.)
- **`jit.gl.texture` name collision:** if multiple instances of
  `f_util_profile` are open, `@name profile_rows_tex` / `profile_cols_tex`
  will collide. Deferred — known Vsynth pattern.
- **asyncread output format:** ✅ RESOLVED — output is `char` (0–255).
  JS must divide by 255 to normalize to 0–1.
- **JS file location:** `profile_rows.js` and `profile_cols.js` go in
  `f_/code/` (on Max search path). Confirmed working pattern from Phase 1.
