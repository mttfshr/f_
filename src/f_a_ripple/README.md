# src/f_a_ripple

`codebox.gen` is the gen~ codebox of `f_a_ripple`, a build input of `definition.py`
(`archetype: "audio_gen"`). Extracted 2026-11-16 from the shipped v1 prototype
`package/patchers/f_a_ripple.maxpat` (gen~ `obj-300`, codebox `obj-2` inside it): 4652 chars,
143 lines, sha256 prefix `378a098711116646`, extracted verbatim before any edit.

Edits made the same day (audio archetype Phase A, `.specify/f_a_ripple/tasks.md` T004), and only these:
1. `Param output_level(0.0)` renamed `gain`, default 0.1 (a module silent on load reads as broken; Matt, 2026-11-16).
2. `Param bypass_gate(0.0)` added; `out1` is multiplied by `1 - byp_s`, where `byp_s` is `bypass_gate`
   through a one-pole slew of about 5 ms. Not heard: click behavior is Matt's check.
3. `out2` (`render_count`) and `out3` (`f0_h`) removed: diagnostics of the prototype's retrigger check.
   The Histories stay, the DSP is untouched (T001's loop bounds included).

Master copy: edit here, rebuild with `build/py.sh build/build_patcher.py src/f_a_ripple/definition.py`.
The original prototype is in git history (`git show db7cc1b:package/patchers/f_a_ripple.maxpat`).
