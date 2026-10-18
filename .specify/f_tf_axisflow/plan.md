# Implementation Plan: f_tf_axisflow

_Date: 2026-10-16_
_Spec: `.specify/f_tf_axisflow/spec.md`_

## Summary

A single-stage, stateless processor: one `jit.gl.pix` (`@type float32`) with one codebox.
No `pix_chain`. Pure per-pixel arithmetic on the packed tensormap outlet 1.

```
in0 (tensormap outlet 1) -> axisflow codebox -> out1 (vecfield)
```

## Codebox sketch (not final; verified against the mirror first)

```
Param angle(0.0);  Param mode(0.0);  Param gain(1.0);  Param gate(1.0);
Param width(640.0); Param height(480.0); Param bypass_gate(0.0);

t   = sample(in1, norm);
c2  = (t.x - 0.5) * 2.0;   s2 = (t.y - 0.5) * 2.0;
len = sqrt(c2*c2 + s2*s2);
ok  = step(0.000001, len) * (1.0 - step(1.05, len));     // iso and unconnected -> 0
phi = angle * pi / 180.0;  rx = cos(phi);  ry = sin(phi);
ax  = 0.5 * ((1.0+c2)*rx + s2*ry);  ay = 0.5 * (s2*rx + (1.0-c2)*ry);   // across: (g.r) g, g = gradient axis
vx  = mix(rx - ax, ax, mode);       vy = mix(ry - ay, ay, mode);       // along = r - across (mode 0)
mag = ok * gain * mix(1.0, t.w, gate);
sh  = min(width, height);
out1 = vec(clamp(vx*mag*sh/width*0.5 + 0.5, 0, 1), clamp(vy*mag*sh/height*0.5 + 0.5, 0, 1), 0.5, 1.0);
out1 = mix(out1, vec(0.5,0.5,0.5,1.0), bypass_gate);
```

(`mode` as a 0/1 menu index; check how `f_vf_advect` declares its menu.) The iso test uses
the *unit-length* property of valid input. Open: the guard at `len > 1.05` vs the Vsynth
`src_*` in-state flag; the content guard needs no plumbing, so it is the default.

## Architecture decisions

- **ADR-1 projection, not atan2** (spec). Smooth, seam-free, cheaper.
- **ADR-2 aspect corrected in the module** rather than asking the user to scale. It needs
  `width`/`height` Params for the same reason as the tensormap (`dim` = 1 live).
- **ADR-3 bypass = `bypass_mode: "param"`** with `bypass_gate`, as tensormap/advect. Native
  `@bypass` would pass the tensor texture through as if it were a vecfield: wrong.
- **ADR-4 single pix, no state.** No `pass_pix`; nothing to feed back.

## Verification (same three tiers as the tensormap)

1. **Mirror** `tests/modules/tf_axisflow/test_tf_axisflow.py` (NumPy): sweep θ, φ against a brute-force
   `atan2`-and-sign reference for |v| and direction up to sign; invariance under θ → θ+π;
   along + across = r; iso → neutral; unconnected (`R=G=0`) → neutral; aspect 16:9 on a 45°
   axis preserves the pixel direction; chain test with the tensormap mirror on stripes/ramps.
2. **Bench** `tests/modules/tf_axisflow/bench_tf_axisflow.py`: codebox vs mirror, incl. clamp, iso, black input,
   aspect; bypass const in `BYPASS_EXPECT`.
3. **Live**: scratch patch tensormap → axisflow → `f_vf_advect`, noise source, sweep `angle`.

## Risks

- The fade at perpendicular edges may feel weak: addressed by `angle` and (if needed) a later
  `normalize`.
- Aspect units (short side) may surprise downstream gain: document in the reference page.
- Content guard (`len > 1.05`) assumes tensormap output stays unit-length; the tensormap tests
  already cover that invariant.

## Files

`src/f_tf_axisflow/{definition.py,codebox_axisflow.gen}`, `tests/modules/tf_axisflow/test_tf_axisflow.py`,
`tests/modules/tf_axisflow/bench_tf_axisflow.py`, `tests/lib/benchdeps.py` entry, `src/f_modules/menu.py` +
README row + generators, `tests/contracts/bench_modules.py` BYPASS_EXPECT + NEUTRAL_BYPASS_BY_DESIGN not
needed (full bypass), docs.
