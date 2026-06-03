# f_util_profile

CPU-side dual-axis luminance profiler. Reads an incoming GL texture and outputs
two independent 1D luminance profiles as GL textures — one per horizontal band
(rows), one per vertical band (columns).

Infrastructure, not an image operator. No visual output. Outputs are control
signals in texture form for downstream modulation.

---

## Inputs

**Inlet 0** — texture in (`routepass jit_gl_texture jit_matrix` pattern)

---

## Outputs

**Outlet 0** — row profile (`128 × 1` GL texture)
One mean luminance value per horizontal band. Consumers sample at normalized X.

**Outlet 1** — column profile (`1 × 128` GL texture)
One mean luminance value per vertical band. Consumers sample at normalized Y.

Output dimensions are fixed architectural constants — never change regardless
of params.

---

## Parameters

| Param | Type | Range | Default | Description |
|---|---|---|---|---|
| `res_rows` | int | 1–128 | 64 | Horizontal analysis slabs — controls row profile sharpness |
| `res_cols` | int | 1–128 | 64 | Vertical analysis slabs — controls column profile sharpness |
| `freq` | int | 1–64 | 8 | Upstream generator band count — sync target only, not used internally |
| `bypass` | toggle | — | off | Freeze: holds last computed profile on both outputs |

---

## Signal flow

```
inlet 0
  → routepass jit_gl_texture jit_matrix
      out0 → jit.gl.pix vsynth (passthrough, triggers asyncread)
           → jit.gl.asyncread vsynth
               ├→ jit.dimop @op avg @step 640 1  [row averaging → 1×height]
               │   → gate_row (bypass-controlled)
               │   → js profile_rows.js
               │   → jit.gl.texture @dim 128 1 @name profile_rows_tex
               │   → outlet 0
               └→ jit.dimop @op avg @step 1 640  [col averaging → width×1]
                   → gate_col (bypass-controlled)
                   → js profile_cols.js
                   → jit.gl.texture @dim 1 128 @name profile_cols_tex
                   → outlet 1
      out2 (unmatched) → route res_rows res_cols freq
```

---

## Files

| File | Description |
|---|---|
| `patchers/f_util_profile.maxpat` | Production bpatcher |
| `code/profile_rows.js` | Row aggregation — 1×height matrix → 128×1 float32 |
| `code/profile_cols.js` | Column aggregation — width×1 matrix → 1×128 float32 |
| `code/profile_compute.js` | Original single-axis JS (Phase 2 reference, superseded) |

---

## Usage

### Basic

Wire any Vsynth texture source into inlet 0. Both outlets immediately produce
live-updating profile textures. Wire into a `jit.pwindow @size 512 4` (outlet 0)
and `jit.pwindow @size 4 512` (outlet 1) to monitor.

### With f_masonry

`f_masonry` has independent course (row) and column structure. Wire:
- outlet 0 → `f_masonry` courses modulation inlet — drives per-row brightness
- outlet 1 → `f_masonry` columns modulation inlet — drives per-column brightness

Set `freq` on `f_util_profile` to match `f_masonry`'s `courses` / `columns`
param so consumers sample the profile at the right coordinates.

### Sampling in a consumer shader

For a generator with `freq` bands, band `i` samples at:
```
coord = (i + 0.5) / freq
```
on the appropriate axis. The GPU sampler interpolates between profile values.

---

## Design notes

**Why two separate dimop passes?** The row and column profiles contain genuinely
independent data — a transposition of the row profile would not represent column
luminance. Each `jit.dimop` pass averages along one axis only, producing
independent spatial information per axis.

**Why CPU-side?** Shaders execute per-pixel with no cross-pixel communication.
Aggregating luminance across a row or column requires communication — impossible
in a single shader pass. `jit.gl.asyncread` reads the texture to CPU each frame;
`jit.dimop` averages efficiently on CPU before JS interpolation.

**Bypass freezes, not zeros.** On bypass, both gates close and JS stops receiving
new matrices. The last computed texture continues to output unchanged — the
consumer keeps operating at its last-known state rather than being driven to zero.

**`freq` is UI-only.** `f_util_profile` has no knowledge of its consumer's band
structure. `freq` exists in the UI as a reminder of what to sync to, and is
saved/restored via autopattr. It is not wired to any processing object.

---

## Archetype

`f_util_` — infrastructure/analysis tool. No codebox, no visual output.
Bypass freezes rather than passing through or zeroing.
