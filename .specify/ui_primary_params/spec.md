# Spike: primary vs secondary params, and dial vs numbox as a role signal

_Started 2026-11-22 (Matt's idea; scaffolded offline by Claude). A small test, not a module. Nothing here is decided._
Gates touched: `G-ui-density` (this is one candidate direction for it), `G-m4l` (the Live-style panel work chose number boxes by readability; this idea would choose by role, see Tension).

## Hypothesis

**H1.** For most modules the controls split into a few **primary** params (they set the character of the effect: change what it *is*) and the rest **secondary** (they refine it: change how much, how fast, how clean).
**H2 (layout, only if H1 holds).** In a panel that mixes widgets, a **dial usually means primary and a number box usually means secondary**, so a module is more scannable and coherent: a user can read its character from the panel at a glance.

H2 is a default, not a law (Matt, 2026-11-22). Exceptions are fine when the layout, readout or control type calls for one (a primary that needs a readable value, a secondary that is performed live, a color triple as three boxes). The test is whether the default makes panels read better, not whether every param obeys it.

H2 is a design bet, not a measurable fact; the spike can only say whether H1 holds well enough to try it and what the panels look like.

**H3 (soft typing, added 2026-11-22 with Matt; applies before H2).** Some params get their default widget from what *kind* of quantity they are, not from their role. In order:
1. **Discrete choice, few values (about 8 or fewer) → a menu or stepper**, whether the param is an int or a float rounded to one (`n_inks` 1-3, `direction` 0-2, `band` 1-7, `ghost_count` 1-4). A large int (an index: `seed` 1-256, `levels` 2-16, `taps` 1-16) is a number box. The 8 is a guess.
2. **Companion amounts → number box:** `mix_pct`, `gain` (Matt: yes even when it is primary) and mod depths (`*_mod`, `*_m`). Today 9 of 10 mix params are number boxes and 26 of 29 gain params are dials (counted from `inventory.json`, 2026-11-22), so this flips about 26 gain dials across 23 modules if ever applied. A proposal only; no definition changes in this spike.
3. **Circular quantities → dial:** angle and rotation, and hue (0-360 wraps like an angle). Not phase in `f_weave` (a scroll, not circular).
4. **Everything else → H2** (primary dial, secondary number box).
5. **A group can override any of it** (an HSL triple, a per-plate column of the same kind reads best as one widget). Tension to expect: the per-plate angles in `f_halftone` are circular (rule 3, dial) but secondary by role (H2, number box); the group rule decides there, in Phase 2.

**H4 (spatial, added 2026-11-22, Matt; a soft default like H2).** Number boxes generally do not go on the first row. The top row is for dials (primaries, and circular dials from H3), so the panel's character reads first and the number boxes sit below as refinement. It is also how the hands-on test below reads the result: what you put in the top row.

## Definitions (proposed, for Matt to amend)

A param is **primary** if it passes at least two of:
1. **Kind, not degree.** Moving it across its range changes the *structure* of the output (what shapes, patterns or motion appear), not only its strength, speed or sharpness.
2. **Reached for live.** A performer would move it while watching the picture (a lever, not a setup value).
3. **Others depend on it.** Its setting changes what the other params do (a gate or driver, high interaction), or it names the effect (Scale for a halftone, Mode for a separation).

It is **secondary** if it mainly (a) scales an effect that already exists (gain, mix, depth), (b) tunes stability or quality (step size, drying, limits), or (c) is set once and left. Menus and buttons are out of scope: they are already their own widget.
Expected size: **2 to 5 primaries per module**. A module with no clear primary, or with more than 6, is a finding, not a failure.

## Pool rule (Matt, 2026-11-22): set aside what is already laid out

A module with substantive layout customization is set aside: it is not in the pilot and the layout test does not touch it. **When in doubt, set it aside.** Evidence is the `overrides` block, custom param rects, `panel_toggle` and `columns` in `definition.py` (a proxy: counts are exact, "substantive" is inferred).
- **Set aside, clear:** `f_weave`, `f_separate`, `f_vf_erode`, `f_halftone`, `f_lens`, `f_grain`, `f_channel_grader`, `f_poincare`, `f_mobius`, `f_stereo`, `f_droste`, `f_tf_axisflow`, `f_tone_curve`, `f_luma_processor`, `f_hue_processor`.
- **Set aside, light (in doubt):** `f_masonry`, `f_texrouter`, `f_tf_sharpen`, `f_tf_smooth`, `f_tf_tensormap`, `f_vf_fieldmap`, `f_vf_lbm`, `f_vf_vortex_multi`, `f_vf_warp`, `f_vf_stamp`, `f_wave_field`.
- **Set aside, audio shell:** `f_a_ripple`, `f_a_purr`, `f_a_decorrelate`.
- **The pool:** the 23 untouched modules with controls (`inventory.json` minus the above; `f_vf_split` has no controls).
- The six pilot modules chosen before this rule (the first six above) are set aside; their J1 roles stay in `roles.json` as an answer key against Matt's existing layouts, not as evidence for the thresholds. **The pilot is being re-chosen from the pool** (tasks T004).

## Method: three independent judges, compared

| Judge | Who | Input | Output | Cost |
|---|---|---|---|---|
| J1 Rubric | Claude, offline | `inventory.json`, each param's `hint`, `docs/f-reference/<m>.md` | role + one-line reason per param, in `roles.json` | no runs; reading |
| J2 Blind call | Matt | a sheet of param names, ranges and defaults per module, **without** J1's labels; only the 63 untyped params (28 are typed by H3). Hands-on alternative (rearrange a named scratch copy so the top row is primary) still to be chosen | role per param, or "unsure" | Matt, a few minutes per module |
| J3 Sensitivity | NumPy mirror, offline | modules that have a mirror in `tests/modules/<m>/`; sweep each param min to max with the rest at defaults | per param: output change (mean abs diff), structure change (change in spatial spectrum or edges after matching mean and contrast), and interaction (how much its effect varies with the others' settings) | NumPy only, no Max; needs a go (CLAUDE.md run rule) |

J3 is evidence for criteria 1 and 3, not for 2. It is skipped for a module with no mirror (a built-in control for the comparison).

**Pilot set (8 modules, re-chosen 2026-11-22 from the pool, Matt approved):** `f_vf_advect`, `f_vf_glow`, `f_stipple`, `f_quasi`, `f_vf_seeds`, `f_vf_vortex`, `f_tf_hatch`, `f_vf_ch`. Mirror directories exist for `f_vf_advect`, `f_vf_glow`, `f_stipple`, `f_quasi`, `f_vf_seeds`, `f_vf_vortex`, `f_tf_hatch`, `f_vf_ch` per the `tests/modules/` listing (whether each can run a param sweep is not checked; that is T012).

## Success and stop rules (proposed numbers, mine, not Matt's)

Proceed to a layout test if all hold on the pilot:
1. **J1 and J2 agree** on at least 75% of params (a threshold I chose; adjust it before looking at the result).
2. **Size:** at least 6 of 8 modules have 5 or fewer primaries under J2, among their *untyped* params (H3 settles typed ones by kind and they are not judged under H2), and at most 2 modules have none. Success rule 3 below counts the 8 modules above (7 if one has no usable mirror). _Amended 2026-11-22 after H3 and after seeing J1 (not J2): the original "2 to 5" made `f_separate` fail only because its character params (ink hues, `n_inks`) are typed by H3, so its untyped params are all secondary. J1 untyped primaries per module: halftone 3, separate 0, erode 3, weave 4, lens 3, advect 2, glow 1, grain 4._
3. **J3 supports J1:** where a mirror exists, J1's primaries are in the top half by structure change or interaction for at least 5 of 7 modules. If J3 ranks by magnitude only, that is a fail of the method, not of H1: say so.

**Stop and park the idea** (new row `P-ui-roles` in `gates.md`, tripwire "a module is redesigned and the split is obvious") if J1 and J2 disagree on more than 40% of params, or most modules have no stable primaries. Disagreement is itself the result: it would say importance is use-dependent, which is an argument for presets and macros rather than a fixed widget role.

## Layout test (Phase 2, scratch only, not built until Phase 1 passes)

Two scratch strips in the style of `ideas/m4l_ui_design.md` (`scratch/`, gitignored, no `definition.py` change): the **same module twice**, current panel versus dials-for-primaries / number-boxes-for-secondary. Candidates: `f_weave` (already mixes, 9 dials + 3 number boxes) and `f_vf_erode` (today all number boxes; would regain 2 or 3 dials). Judged by Matt in Max.

## Tension to settle first

`ideas/m4l_ui_design.md` (2026-11-18) concluded "number boxes beat dials where the value must be readable and placeable", and `f_vf_erode`'s all-number-box panel was chosen on that basis. This idea picks the widget for a different reason (role, not readout). With H2 a default, they conflict only where a primary needs a readable value, and an exception there is allowed; a dial with `valuepopup` or a number box styled as primary (a larger or brighter box) are fallbacks to try in Phase 2, not to decide now.

## Out of scope

Changing `definition.py` or the builder (a `role` key would be a schema change; roles live in `roles.json` until Matt wants it), the module menu, helpfiles, macros and randomizers (`ideas/f_util_scoped_presets.md` covers those), audio modules in the pilot, any Max bench run.
