# f_tone_curve — tasks

_Created by the 2026-10-12 maintenance pass: module has no .specify
folder (graduated straight to docs/). The audit found one stale
cross-reference and one idea Matt flagged "wants this pursued for
real". Ids start at T001._

- [x] T001 (2026-11-06, Claude: both pointers now name `docs/f-reference/f_tone_curve.md`; the LUT work stays in the ideas file): Fix the stale pointer in
  ideas/lut_curve_and_color_controls.md: it twice cites a revisit note
  "added at `.specify/f_tone_curve/definition.py`" (lines 47, 124) —
  no such folder/file exists anywhere. Either create the folder and
  move the note there or correct the pointer to wherever the note
  actually lives (likely src/f_tone_curve/definition.py). While in
  that ideas file: the dependent-texture 1×256 LUT experiment it
  specs (Matt: "wants this pursued for real") is the actionable
  follow-up; this task is the doc-pointer fix, the LUT work stays
  tracked in the ideas file until picked up.

- [x] T002 (decided 2026-10-19, Matt): tier 1 skipped. A few dozen lines of smoothstep band-weighted lift; only identity at neutral and uniform-lift symmetry exist to check. (Constitution rule for pre-convention modules, "Verification Tiers".)

- [x] T003 Stable preflight (2026-11-06, offline by Claude), record below.
- [ ] T004 Matt's helpfile look: the digest, the note, and Falloff 0 against a raised Falloff. Do not move to `.specify/stable/` until it passes.
- [x] T005 Matt's call, 2026-11-06: keep native bypass ("Keep native"), no migration to `bypass_gate`, so no bench run (`G-bypass-native`).

## Stable preflight (2026-11-06)

Part 1 offline by Claude: drift ok, no baseline entry; menu and launcher `--check` up to date; README row 100 chars, no ⚠; menu entry under Color / Tone, no recipe; helpfile box 160x130 against a footprint of 150x120. Bypass FAILS the preflight rule as written: jsui -> `attrui bypass`, native, and the module is listed in `G-bypass-native`. For a texture processor the result is source passthrough either way (contract bench's implicit out1 = in1 check; no `BYPASS_EXPECT` entry), so the doc says native. Matt decided to keep it (T005). The route has a `bypass` selector, so `bypass [0 / 1]` stays in the helpfile. Tests: no mirror (T002, skip decided by Matt) and no `bench_*` file of its own, only the contract bench, plus the route string in `tests/build/test_build_conventions.py`. No `spec.md` or `plan.md`; `definition.py` has no `Spec:` line.

Patcher against docs: one inlet, one outlet. No `vs_inState`, no `vs_black`, no `r draw`, so only the incoming texture triggers the pix, and nothing connected means no output (wiring read; behavior inferred, not run). `@type char`, so float input is quantized here. The inventory's Required is right.

Fixed: the reference doc had no ranges or defaults (read from `definition.py` and the patcher), no inlet or trigger facts, no bypass truth, an old date and source path. It now says the lift is additive on R, G and B by Rec. 601 luma, and neutral at defaults. README's "Tone curve adjustment" and the digest both reinforced the curve-editor impression the audit flagged (`ideas/f_helpfile_content_audit_2026-10-13.md`), now fixed, and References now carries the naming caveat and the LUT pointer. `ideas/INDEX.md` and `ideas/gpu_gems_research.md` had the same dead `.specify/f_tone_curve/definition.py` pointer T001 fixed elsewhere.

Inferred, not run: at the default Falloff 0, `smoothstep` gets equal edges, undefined in GLSL. Expected: a hard step at each crossover, so different lifts leave a contour. T004 checks it.

Chains in `library-characteristics.md`: all feed Tone Curve a texture, and its texture goes on to texture inlets (`f_wc` pulse is inlet 1). By meaning: the Luma-band field said only highlights advect, but crushing shadows leaves mids too, and at Falloff 0 the jump at `low_mid` is itself a hard edge, likely the strongest gradient in the frame (worked from the codebox); chain now raises Falloff and says so. Grain palette lock credited Tone Curve with palette selectivity, but it acts on the whole frame; reworded. "Squash contrast" needs shadows up and highlights down, not a default; now stated. The `f_vf_chroma` chain was not assessed (paused).

Helpfile: source already wired (`vs_sources_main`, opens on the Movie tab). At defaults the output equals the source (from the codebox, not seen), so a new note says that and what the dials do. It does not overlap the preview (rects: preview 338-574 x 340-589; note 518-758 x 190-312). No consumers named. `test_generate_menu.py` result as in Flow's record. Live by Matt: T004.

Left alone: `ideas/f_vf_seeds.md` says Tone Curve can color-map seeds (it cannot; an old idea note).
