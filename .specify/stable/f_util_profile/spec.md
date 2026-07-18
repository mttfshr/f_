# f_util_profile — spec

_Status: specced, not yet built_

---

## What it does

`f_util_profile` reads an incoming GL texture on the CPU and outputs two
independent 1D luminance profiles as GL textures — one profiling horizontal
bands (rows), one profiling vertical bands (columns). Each output is one mean
luminance value per band, across a fixed output resolution.

It is infrastructure, not an image operator. It has no visual output. Its
outputs are control signals in texture form, consumed by downstream bpatchers
as modulation sources. The two outputs are independent: row and column
profiles are computed from separate `jit.dimop` averaging passes and have
separate resolution controls.

---

## Why it exists

Shaders can't aggregate information across pixels — every pixel knows only
its own position and value. `f_util_profile` does that aggregation upstream
on the CPU, then hands the result back to the GPU as a 1D texture. This
gives downstream shaders band-level awareness of the texture's own content,
which a shader alone cannot achieve in a single pass.

The intended behavioral loop: a generator produces content → `f_util_profile`
reads that content and extracts its luminance distribution → the profile
feeds back into the generator as a modulation texture → the generator's
behavior varies spatially according to its own output. The rule in the
generator is simple and fixed; the behavior is complex because the signal
driving it is itself dynamic.

---

## Signal flow

```
upstream texture → jit.gl.asyncread → CPU jit.matrix
                ├→ jit.dimop (avg rows) → slice into `res_rows` horizontal bands
                │                       → mean luminance per band (float 0–1)
                │                       → interpolate to 128×1 jit.matrix
                │                       → jit.gl.texture → outlet 0 (row profile)
                └→ jit.dimop (avg cols) → slice into `res_cols` vertical bands
                                        → mean luminance per band (float 0–1)
                                        → interpolate to 1×128 jit.matrix
                                        → jit.gl.texture → outlet 1 (col profile)
```

---

## Interface

**Inlet 0:** texture in (`routepass jit_gl_texture jit_matrix` pattern)

**Param — `freq`** (int, 1–64, default 8)
The band count of the upstream generator this profile is intended to serve.
Used by the consumer to sample the output texture at the right coordinates —
not used internally by `f_util_profile` itself. Named `freq` to match
upstream generator vocabulary; sync by routing the same control message to
both `f_util_profile` and the upstream generator. Exposed as a param so the
consumer can read it via autopattr if needed, and so it appears in the UI as
a reminder of the intended sync target. Applies to both axes.

**Param — `res_rows`** (int, 1–128, default 64)
Number of horizontal bands computed CPU-side for the row profile. Controls
row-axis analysis sharpness. Real-time modulatable.

**Param — `res_cols`** (int, 1–128, default 64)
Number of vertical bands computed CPU-side for the column profile. Controls
column-axis analysis sharpness. Real-time modulatable.

**Outlet 0:** row profile — GL texture, always `128 × 1`
One mean luminance value per horizontal band. Consumers sample at normalized
X coordinate.

**Outlet 1:** column profile — GL texture, always `1 × 128`
One mean luminance value per vertical band. Consumers sample at normalized
Y coordinate.

---

## Output format

Both outputs have fixed dimensions — `128 × 1` for the row profile, `1 × 128`
for the column profile. These are architectural constants; output texture
dimensions never change, preserving full modularity.

**`res_rows`** controls how many horizontal bands are computed CPU-side and
spread across the 128 row-profile cells. **`res_cols`** does the same for
vertical bands in the column profile. Low values produce smooth coarse
profiles; high values resolve finer spatial detail. Both are real-time
modulatable — sweeping during performance is a valid gesture.

`res_rows`, `res_cols`, and `freq` are related but distinct:
- `freq` — how many bands the upstream generator has (sync target, both axes)
- `res_rows` — how finely the row profile reads the texture (analysis quality)
- `res_cols` — how finely the column profile reads the texture (analysis quality)

Consumers sample the row profile at normalized X; the column profile at
normalized Y. For a generator with `freq` bands, band `i` samples at
`coord = (i + 0.5) / freq` on the appropriate axis.

---

## CPU-side implementation

`jit.gl.asyncread` reads the GL texture to a CPU `jit_matrix` asynchronously
(non-blocking — outputs on the next bang after the read completes, one frame
of latency). The matrix fans out to two independent processing chains:

**Row profile** (`jit.dimop @op avg @step 640 1` → `js profile_rows.js`):
1. dimop averages each row to a single RGBA pixel → 1×height matrix
2. JS computes luma per slab, interpolates to 128 values
3. Writes 128×1 `jit.matrix` → `jit.gl.texture @dim 128 1 @name profile_rows_tex`

**Column profile** (`jit.dimop @op avg @step 1 640` → `js profile_cols.js`):
1. dimop averages each column to a single RGBA pixel → width×1 matrix
2. JS computes luma per slab, interpolates to 128 values
3. Writes 1×128 `jit.matrix` → `jit.gl.texture @dim 1 128 @name profile_cols_tex`

Two separate JS files keeps each simple and independently testable. Both
receive their respective `res_` param as a message. The asyncread output is
the only shared point — one fan-out, two independent chains.

---

**What `f_util_profile` does NOT know**

- What the downstream consumer does with the profile
- The downstream consumer's `freq` or band count
- Any parameter of the upstream generator
- Temporal history (no smoothing — that is `f_util_envelope`'s job)

---

## Bypass behavior

When bypassed, output freezes at the last computed profile. This is
preferable to a flat value because it allows the consumer to continue
operating at its last-known state without being driven to an arbitrary
position. On first load before any frame has been read, outputs a flat 0.5
texture until real data is available.

This is the no-knowledge-of-downstream principle from the ideas doc. The
utility is signal-source agnostic.

---

## Archetype

`f_util_` — infrastructure/analysis tool, not an image operator.

This is distinct from the processor and dual-mode generator archetypes in the
vsynth-bpatcher skill. Key differences:
- No codebox / jit.gl.pix — processing is CPU-side
- No visual output — outlet is a control texture, not a render texture
- Minimal UI — `freq` and `resolution` controls, title, bypass
- Bypass freezes output (not black, not neutral flat)

---

## How you know it's working

1. Open `f_util_profile` in a scratch patch. Wire any Vsynth texture source
   into inlet 0. Both outlets should produce textures.
2. Wire outlet 0 into a `jit.pwindow @size 512 4`. Wire outlet 1 into a
   `jit.pwindow @size 4 512`. Both should show luminance gradients that
   visibly respond to the upstream texture.
3. Use `f_masonry` as upstream source with strong horizontal and vertical
   band structure. Outlet 0 should reflect row (course) luminance; outlet 1
   should reflect column luminance independently.
4. Wire both outlets into `f_masonry` modulation inlets — one driving courses,
   one driving columns. Confirm visible independent spatial modulation on each
   axis.
5. Sweep `res_rows` and `res_cols` independently. Confirm each affects only
   its corresponding output without disturbing the other.

---

## Open questions (resolved)

**Output format — fixed or variable resolution?**
Fixed output dimensions (`128×1` rows, `1×128` cols). `res_rows` and
`res_cols` control CPU-side analysis sharpness independently. Output texture
dimensions never change. Consumers fully decoupled from all params. Resolved.

**Single output or dual output?**
Dual independent outputs — one per axis. Row profile (`128×1`) and column
profile (`1×128`) computed from separate `jit.dimop` passes with independent
resolution controls. Motivated by f_masonry use case: courses and columns are
independent structural axes that benefit from independent modulation. Resolved.

**`PROFILE_RES` as a constant or param?**
Exposed as two params (`res_rows`, `res_cols`), each int 1–128 default 64,
real-time modulatable. Output dimensions always fixed regardless. Resolved.

**Syncability of `freq`?**
`freq` is a single UI param naming the upstream generator's band count —
used by the consumer for sampling on both axes, not by the profile internally.
Sync by routing the same value to both. Misalignment produces interpolated
correspondence, not an error. Resolved.

**Bpatcher vs abstraction?**
Bpatcher. Participates in GL context (reads and outputs GL textures). Minimal
UI but present. Resolved.

**Bypass behavior?**
Freeze: hold last computed profile on both outputs. Single bypass toggle
freezes both chains simultaneously. Neutral on first load (0.5 flat) until
real data arrives. Resolved.

---

## Open questions (deferred)

**Orientation:** Both horizontal (row) and vertical (column) axes now
implemented. Angular slicing deferred — add as a mode param if a use case
emerges.

**Output statistic:** Mean luminance first. Variance or peak useful for
different behaviors — deferred until a specific downstream use case motivates
them.

**f_util_envelope integration:** Raw output from `f_util_profile` will be
noisy frame-to-frame. Smoothing is `f_util_envelope`'s job. The two are
designed to chain: `f_util_profile` → `f_util_envelope` → consumer. Spec
`f_util_envelope` in parallel with or immediately after this build.
