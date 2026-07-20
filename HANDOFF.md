# HANDOFF

_Session: 2026-07-19 — stale-helpfile queue cleared + generate_helpfiles.py API removal_

## Start Here — Next Session

Read `README.md` → this file → `.specify/plan.md`.

The 15-item stale-helpfile queue from the prior session is now fully
cleared (0 stale, 19 current, 15 ready, 3 blocked_no_docs). No pickup
list remains from that workstream. See "Loose threads" below for what's
actually open now.

---

## This session, in order

### Cleared the full 15-item stale-helpfile review queue
For each of `f_channel_grader`, `f_chladni`, `f_droste`, `f_grain`,
`f_hue_processor`, `f_lens`, `f_luma_processor`, `f_masonry`, `f_mobius`,
`f_stereo`, `f_stipple`, `f_tone_curve`, `f_util_profile`, `f_vf_vortex`,
`f_vf_warp`: diffed `extract_params.py`'s dry-run param list against
`docs/f-reference/f_name.md`, fixed real drift where found, then
regenerated the helpfile directly in-session (one throwaway local Python
script, no API call -- pulled real object IDs from each built `.maxpat`
via a varname->id scan, matching the `f_droste`/`f_caustic` template
conventions). All 15 written, JSON-validated, script deleted after use.

**11 modules were prose-only staleness** (`f_channel_grader`, `f_chladni`,
`f_droste`, `f_hue_processor`, `f_luma_processor`, `f_mobius`, `f_stereo`,
`f_stipple`, `f_tone_curve`, `f_util_profile`, `f_vf_vortex`) -- params
already matched `definition.py`, just regenerated as-is.

**4 modules had real drift, fixed before regenerating:**

- **`f_grain`** -- `docs/f-reference/f_grain.md` listed a `softness` param
  that was missing from `src/f_grain/definition.py`'s `params` array
  entirely, plus a stale `edge_mode_menu` name (real name: `edge_mode`).
  Confirmed via the live `.maxpat` that `softness` is real and wired
  (`live.dial`, `param_connect: grain_pix::softness`) -- `definition.py`
  was simply incomplete, not the patch. Traced why: `f_grain.maxpat` was
  added 2026-05-23, `build_patcher.py` didn't exist until 2026-05-30 --
  this module predates the build system entirely, and
  `src/f_grain/definition.py` (added 2026-07-05) is an after-the-fact
  transcription, not a generator, so it simply missed `softness` during
  that transcription. Fixed `definition.py` to add `softness` (recording
  its real but oddly-untuned `0.0-5.0` live-dial range rather than
  "fixing" it to `0-1`, since this file documents production, it doesn't
  drive it). Fixed the doc's naming and added loose-thread notes.
  **Added `f_grain` to `plan.md`'s never-regenerate-via-`build_patcher.py`
  list** alongside `f_masonry`/`f_sirds`/`f_vf_advect`/`f_vf_seeds`.
- **`f_lens`** -- doc (dated 2026-07-16) predated the 2026-07-17 confirmed
  bug ("`f_lens` bypass only gates `lens_pix`, not `lens_halation`/
  tiltshift") already recorded in `plan.md` -- doc's Loose Threads didn't
  mention it at all. Added that section. Also fixed a stale Source File
  path (`.specify/f_lens/definition.py` -> `src/f_lens/definition.py`,
  left over from before the `src/` reorg).
- **`f_masonry`** -- doc still listed a `quantize` param
  ("0=slot-quantized drift, 1=continuous drift") that was removed from
  the codebox entirely in the 2026-07-05 ADR 7 candidate-search redesign
  (`definition.py`'s own header comment confirms: "quantize removed").
  But the live `.maxpat`'s `quantize` `live.dial`/`route` entry/
  `prepend quantize` message are all still present and unremoved --
  since `f_masonry` is on the never-regenerate list, nobody's gone back
  to strip the dead UI after the codebox stopped using it. Fixed the
  doc (removed the param row, updated Algorithm prose) and added a
  loose-thread flagging the dangling dial in the live patch for future
  by-hand removal.
- **`f_vf_warp`** -- doc only documented one outlet (`out0`), but the
  module actually has two (`out0`="composite", `out1`="warped" in Max's
  0-indexed numbering / `out1`/`out2` in the Gen codebox's 1-indexed
  convention). Confirmed in the codebox that `out1`(codebox)/`out2` is
  assigned `warped_sample` unconditionally, with no `bypass` term at all
  -- matches `plan.md`'s confirmed 2026-07-17 bug exactly. Also found
  `strength`'s doc range (`0-1`, default `0.1`) didn't match
  `definition.py` (`min 0.0, max 1.5, default 0.0`). Fixed both plus
  added a Known Bug section.

### Removed the Anthropic API call from `build/generate_helpfiles.py`
Matt reiterated a standing instruction (asked once previously, repeated
this session) that this codebase must never call the Anthropic API from
any script. Rewrote `generate_helpfiles.py` to remove `call_claude()`,
the `anthropic` import, `ANTHROPIC_API_KEY` handling, and the
budget/token-tracking machinery entirely -- it now only builds and
prints (or writes via `--write-prompt`) the generation prompt for
in-session manual use. No other code path exists. Verified via repo-wide
grep that no other `.py`/`.js`/`.sh` file references `anthropic`,
`ANTHROPIC_API_KEY`, or any Claude model string / API call pattern --
`generate_helpfiles.py`'s only remaining match is its own docstring
explaining the constraint.

**Also added to memory** (not just this file) as a hard, standing
constraint, since it was violated by omission once already: never call
the Anthropic API from within this codebase or any script/tool
invocation, full stop.

---

## Current audit state (37 modules total)

Run `python3.13 build/extract_params.py --all --dry-run` any time to
refresh this.

- **19 current** (was 4 at start of session)
- **15 ready** -- have `docs/f-reference`, no helpfile yet (unchanged;
  not this session's scope)
- **0 stale** (was 15 -- fully cleared this session)
- **3 blocked** (no `docs/f-reference` at all, unchanged) --
  `f_chladni_audio`, `f_modules`, `f_vf_vortex_multi_version`

---

## Loose threads / open items for next session

- **`f_hue_processor`'s open UI bug** ("hue_lower/hue_upper missing UI
  path", per HANDOFF history) is still unresolved -- doc-level review
  this session confirmed params match `definition.py` cleanly, but the
  bug itself needs a fresh look in Max to characterize the actual
  current symptom. Not touched this session.
- **`f_masonry`'s dead `quantize` control** -- confirmed real (live
  `.maxpat` still has the dial/route/message, codebox has used none of
  it since 2026-07-05). Not urgent, but should be removed by hand next
  time this module is opened for other reasons (never via
  `build_patcher.py` regen -- it's on the never-regenerate list).
- **`f_vf_warp`'s bypass bug** (doesn't gate the `out1`/"warped" outlet)
  -- now fully documented in `docs/f-reference/f_vf_warp.md`'s new Known
  Bug section, but still needs an actual fix + task written into
  `.specify/f_vf_warp/tasks.md` per `plan.md` Work Queue item 9. Not
  fixed this session, only documented.
- **`f_lens`'s bypass bug** (only gates `lens_pix`, not
  `lens_halation`/tiltshift) -- same story, now documented in the doc's
  Loose Threads, still not fixed. Tied to the pending `f_focus`
  extraction per `plan.md` item 9's sibling note.
- **The 15-item stale-helpfile queue is closed.** No next-session
  pickup list remains from that workstream. Whatever's picked up next
  should come from `.specify/plan.md`'s Work Queue / Paused-blocked
  sections instead (e.g. `f_vf_optical_flow`'s `smoothstep` edge-fill
  work, `f_vf_warp`'s bypass fix, the `f_lens` v2 bypass cleanup).

## Committed state

Not committed -- this session's changes (4 doc fixes, 4 `definition.py`/
`plan.md` edits, 15 regenerated `.maxhelp` files, `generate_helpfiles.py`
rewrite) sit alongside the still-uncommitted work from prior sessions
(helpfile pipeline tooling fixes, `f_vf_optical_flow`). Natural split if
breaking this up: (1) the four real content/definition.py fixes
(`f_grain`, `f_lens`, `f_masonry`, `f_vf_warp`) plus their regenerated
helpfiles and the 11 prose-only regens as one commit, (2)
`generate_helpfiles.py`'s API removal as its own small commit.
