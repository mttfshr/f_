# Plan — f_ Helpfiles

## Approach

Helpfiles are generated as JSON using Python (same toolchain as patchers), using `f_droste.maxhelp` as the structural template. Each helpfile session follows this order:

1. Read the patcher to extract inlet structure, param names, and ranges from codebox + attrui
2. Read `docs/f_name.md` to check for existing references — add `## References` section if absent
3. Generate the `.maxhelp` JSON using canonical rects from the `f-helpfile` skill
4. Open in Max and verify: demo produces output, ranges correct, layout clean
5. Commit

## Patcher Archetypes → Helpfile Variants

**Processor** (f_droste template — fully established):
- `vs_sources_main` → bpatcher → `vs_preview`
- LFO wired to time/scalar inlet if present

**Generator** (no upstream source):
- bpatcher at top of right column → `vs_preview`
- No `vs_sources_main`
- LFO still available if generator has time/animation param

**Utility** (f_texrouter — no codebox, different signal flow):
- Assess case by case

## Dependencies

- `f-helpfile` skill must be loaded before generating any helpfile
- `docs/f_name.md` `## References` section must exist (create if absent) before helpfile is written
- Param ranges must be verified from the actual patcher — not assumed from docs

## Priority Order

Based on stability and simplicity:
1. f_droste ✅ done
2. f_stereo — simple processor, no time inlet, few params
3. f_mobius — simple processor
4. f_chladni — generator, needs audio companion consideration
5. f_stipple — dual-mode generator
6. f_grain — dual-mode generator
7. f_lens — complex processor, many params
8. f_masonry — complex generator, unresolved issues (do after masonry stabilizes)
9. Color processors (f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve) — simple, batch these
10. f_texrouter — utility, assess separately
