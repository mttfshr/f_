# HANDOFF — f_ library

Last session: 2026-06-21

## What just happened

Built `f_vf_prism` from scratch — a new module forked from `f_vf_chroma` based on
an insight during chroma exploration. Instead of a streak/rainbow accumulation effect,
prism does physically-motivated spectral dispersion: R/G/B channels displaced along
the vecfield at slightly different angles, creating prismatic color separation that
follows field lines.

### f_vf_prism — WORKING, committed
Architecture: three-UV angular dispersion + 11-tap Gaussian blur of gate values
perpendicular to the field direction.

Key params:
- `reach` — how far channels are displaced along the field
- `spread` — angular separation between R/G/B (controls width of chromatic spread)
- `threshold` / `gate_width` — luma gate controls which emitters fire
- `feather` — inter-channel blend, normalized to separation distance (not independent)
- `strength` — additive composite amount

Two outlets: out1 = composite, out2 = isolated prism layer.

Best with: f_vf_vortex as field source, bright-on-dark source (jit.gl.bfg + colorize).

### f_vf_chroma — parked, not deleted
Still at v10 (accumulation loop, synthesized rainbow). Not broken, just unresolved.
The rainbow separation is washed out due to normalization averaging. Parked for now.

### Perspectival depth idea — parked in ideas
The vortex field + prism combination revealed a perspectival depth/light-from-a-point
effect (see screenshot from session). Not pursued further — filed as a future module idea.

## What's next

1. **Register f_vf_prism** in f_modules (add to build_modules.py + f_addmod.js SIZES dict)
2. **Write help file** for f_vf_prism (f-helpfile skill)
3. **Audit in1/in2 bug** — check other f_vf_ consumer modules (f_vf_warp, f_vf_streak,
   f_vf_glow, f_vf_advect) for the same in1/in2 mixup found in f_caustic
4. **f_vf_chroma** — decide whether to continue or leave parked

## Known issues / loose threads

- f_vf_prism not yet registered in f_modules menu
- f_masonry square output at non-square render dimensions still unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- text_button param type only reliably supports two options (three-option limitation)
- `rename strength → amount` across modules still parked

## Key learnings from this session (worth adding to jit-gen-codebox skill)

- **Blur gate values after threshold, not luma before** — blurring luma causes
  omnidirectional shape softening; blurring the gated output keeps blob edges sharp
- **step_size must scale to actual inter-channel separation** — `sin(spread) * reach * field_mag`
  gives the real distance between channels; feather as a fraction of that stays contained
- **Long accumulation lines silently fail** — split into two lines per channel
- `length` and `width` are reserved words in jit.gl.pix attribute system — use `reach`
  and `spread` instead
