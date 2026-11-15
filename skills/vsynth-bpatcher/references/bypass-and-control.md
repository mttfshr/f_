# Bypass and control messages

The bypass jsui, native vs param bypass, the passthrough-on-every-outlet convention, and how named control messages reach a module. Part of the vsynth-bpatcher skill.

## bypass_toggle.js

```json
{
  "maxclass": "jsui",
  "filename": "bypass_toggle.js",
  "hint": "Bypass",
  "numinlets": 1,
  "numoutlets": 1,
  "outlettype": [""],
  "presentation": 1,
  "presentation_rect": [<PW - 22>, 5.0, 18.0, 12.0],
  "parameter_enable": 1,
  "valuepopuplabel": 1,
  "varname": "bypass",
  "saved_attribute_attributes": {
    "valueof": {
      "parameter_invisible": 1,
      "parameter_longname": "bypass",
      "parameter_shortname": "bypass",
      "parameter_type": 1,
      "parameter_modmode": 4,
      "parameter_unitstyle": 0
    }
  }
}
```

- `filename: "bypass_toggle.js"` is **required** — omitting it crashes Max on load
- `numoutlets: 1`, `outlettype: [""]` — single outlet
- `parameter_type: 1` (int/toggle), `parameter_modmode: 4`
- `parameter_invisible: 1` — hidden from automation
- `varname: "bypass"` — no index suffix
- Position: top-right of presentation panel (`PW - 22`, y=5)
- Wired directly: `jsui → attrui (bypass) → pix in0` (not through route)
- **`param_connect` must NOT be set on jsui in generated JSON** — setting it causes Max to crash on load. The `build_patcher.py` script omits it; do not add it manually.


---

## Control Message Convention

External control arrives on in0 as named messages (after routepass peels the texture):

```
courses 16
angle 45
bypass 1
course_seed 7
```

The `route` object dispatches by name to the correct `live.dial` or `live.numbox`.
`bypass` is handled by the jsui directly — it does not go through `route`.

A control normally answers to its param's name, but a param can set `route_name`: `f_vf_advect`'s `mix_pct` numbox answers to `mix`, while most modules' `mix_pct` answers to `mix_pct`. That inconsistency is real and unresolved (a `mix 50` message works on one and not the other); check how the dry/wet modules differ before unifying them.

**Decision (2026-09-23):** the bypass *toggle* (jsui → `attrui @attr bypass` → pix)
is the supported bypass path and works in every module. The `bypass 1` control
message is routed only in the 9 oldest modules (`f_channel_grader`, `f_droste`,
`f_grain`, `f_hue_processor`, `f_luma_processor`, `f_masonry`, `f_mobius`,
`f_stereo`, `f_tone_curve`); generated modules do not route it and this is not a
defect — do not retrofit. (Core Vsynth's convention is `enable`; only
`vs_pixelator`/`vs_pixelator_2` route `bypass`.)

**Native bypass caveat (bench-verified 2026-09-23):** the toggle sets the pix's
*native* `bypass` attribute, which skips the shader entirely and passes the
input straight through. On outlet 1 that is exact; on outlets 2+ the input comes
out **vertically flipped**, and any `mix(..., bypass)` in the codebox never runs.
So a module with a secondary outlet cannot give it a meaningful bypass state
through the native attribute. `f_vf_warp` avoids this by driving a differently
named codebox Param instead (`jsui → prepend param bypass_gate → pix`). Since
2026-10-05 (T017) that is a builder key: top level `"bypass_mode": "param"`, with
`bypass_param` (default `bypass_gate`, never `bypass`) and `bypass_target` (default the
primary; a node id or a list for a multi-stage module; since 2026-10-06 also allowed in the default native mode, where it fans the `@bypass` attrui to each listed stage: `f_vf_seeds` bypasses its merge and composite stages that way). The builder refuses a target
whose codebox does not declare `Param <bypass_param>(`, because the toggle would then do
nothing; the codebox itself must implement the passthrough on EVERY outlet
(`out1 = mix(effect, in1, bypass_gate)`, likewise `out2`...).

**Convention (Matt, 2026-10-05): a bypassed module is a passthrough on every outlet.**
`f_vf_warp`, `f_vf_fluid` and, since 2026-10-06, all 11 modules of plan.md item 10 follow it, each through `bypass_mode: "param"`. The rule used: every outlet mixes to the input of the same signal kind if the module has one, else its neutral value (black for textures, 0.5/0.5 for a vecfield); isolated-layer outlets pass the source. `tests/contracts/bench_modules.py` `BYPASS_EXPECT` states what each outlet must show, and `tests/contracts/test_bench_expect.py` fails when a `bypass_mode: "param"` module has an outlet with no expectation, so a new Param-bypass module MUST extend that table.
`f_vf_warp`'s definition now reproduces the shipped patch, so it is no longer a special case. Multi-stage modules also need
the bypass attrui wired to *every* pix stage, including stage 0 (`f_sirds` and
`f_lens` were each missing one).
