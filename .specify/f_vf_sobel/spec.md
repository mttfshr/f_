# f_vf_sobel — Internal Component Note

## Status: Not a standalone registered module

The Sobel codebox is used internally by f_vf_repulse. It is not registered in f_modules or f_addmod.js.

## Verified codebox (2026-06-18)

Confirmed working in scratch patch:
- Full ring field around masonry blobs (not half-ring)
- Flat regions → neutral (R≈0.5, G≈0.5)
- Positive strength → vectors point away from bright edges

```
Param strength(4.0);
Param bypass(0.0);

sx = 1.0 / dim.x;
sy = 1.0 / dim.y;

luma_tl = sample(in1, vec(norm.x - sx, norm.y - sy)).x * 0.299 + sample(in1, vec(norm.x - sx, norm.y - sy)).y * 0.587 + sample(in1, vec(norm.x - sx, norm.y - sy)).z * 0.114;
luma_tc = sample(in1, vec(norm.x,      norm.y - sy)).x * 0.299 + sample(in1, vec(norm.x,      norm.y - sy)).y * 0.587 + sample(in1, vec(norm.x,      norm.y - sy)).z * 0.114;
luma_tr = sample(in1, vec(norm.x + sx, norm.y - sy)).x * 0.299 + sample(in1, vec(norm.x + sx, norm.y - sy)).y * 0.587 + sample(in1, vec(norm.x + sx, norm.y - sy)).z * 0.114;
luma_ml = sample(in1, vec(norm.x - sx, norm.y     )).x * 0.299 + sample(in1, vec(norm.x - sx, norm.y     )).y * 0.587 + sample(in1, vec(norm.x - sx, norm.y     )).z * 0.114;
luma_mr = sample(in1, vec(norm.x + sx, norm.y     )).x * 0.299 + sample(in1, vec(norm.x + sx, norm.y     )).y * 0.587 + sample(in1, vec(norm.x + sx, norm.y     )).z * 0.114;
luma_bl = sample(in1, vec(norm.x - sx, norm.y + sy)).x * 0.299 + sample(in1, vec(norm.x - sx, norm.y + sy)).y * 0.587 + sample(in1, vec(norm.x - sx, norm.y + sy)).z * 0.114;
luma_bc = sample(in1, vec(norm.x,      norm.y + sy)).x * 0.299 + sample(in1, vec(norm.x,      norm.y + sy)).y * 0.587 + sample(in1, vec(norm.x,      norm.y + sy)).z * 0.114;
luma_br = sample(in1, vec(norm.x + sx, norm.y + sy)).x * 0.299 + sample(in1, vec(norm.x + sx, norm.y + sy)).y * 0.587 + sample(in1, vec(norm.x + sx, norm.y + sy)).z * 0.114;

gx = (-1.0 * luma_tl) + (1.0 * luma_tr) + (-2.0 * luma_ml) + (2.0 * luma_mr) + (-1.0 * luma_bl) + (1.0 * luma_br);
gy = (-1.0 * luma_tl) + (-2.0 * luma_tc) + (-1.0 * luma_tr) + (1.0 * luma_bl) + (2.0 * luma_bc) + (1.0 * luma_br);

field = vec(clamp(gx * strength * 0.5 + 0.5, 0.0, 1.0), clamp(gy * strength * 0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);
neutral = vec(0.5, 0.5, 0.5, 1.0);

out1 = mix(field, neutral, bypass);
```
