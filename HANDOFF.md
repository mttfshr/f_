# HANDOFF

_Session: 2026-08-05 through 2026-08-07_

## What happened

Long session. Picked up from a T3-in-progress state, resolved it, then
worked through T4, T5, T6, and — after a genuinely difficult multi-day
detour — T7 for `f_a_ripple`.

**T3 resolved.** Table-resolution quantization was the root cause of the
non-null residual (64-entry table too coarse against `peek`'s
floor-not-interpolate behavior); fixed by sizing the table up to 2048.
ADR-2's split logic confirmed correct.

**T4, T5, T6 built and passed** (T5/T6 partially — spectrogram comparison
against the paper's figures still unrun, no tool available any session).
T4 established the `run`-gated frozen-time pattern and a `reset`→`gen~`
reserved-word collision (documented). T5 combined T3's wavetable with T4's
modulator into full AM, confirmed close to indistinguishable from the
checkhearing.org reference by ear. T6 added a `mod_type` toggle for a
genuine same-state AM/PM A/B.

**T7 — the big one.** Built `f_a_ripple_scratch_t7a.maxpat` +
`t7a_inner.maxpat` (`pfft~`'s per-bin AM version). Signal path worked
early, after two real structural findings (`pfft~` requires an external
subpatch file, unlike `gen~`; a `gen~` codebox's true multi-signal inlets
need the `in1`...`inN` keyword syntax, not `Param`). But the actual AM
effect stayed completely absent through **four different `gen~`-inside-
`pfft~` control-routing architectures**, each ruled out by direct
`depth=0` vs. `depth=100` A/B listening, plus caching, reserved-word, and
spectral-leakage hypotheses all ruled out too. This was a real process
failure — guessing fixes from reference prose instead of reading actual
working examples — until Matt pushed on two things directly: whether the
help files had actually been read, and whether the external-subpatch
mechanism itself (not the routing details within it) was the more
suspect thing. Reading Cycling '74's own `pfft.pfftgen.maxpat`/
`fp_fft.maxpat` examples revealed the real idiom — **a per-bin gain curve
in a named `buffer~`, read via plain `index~`, no `gen~` involved at
all** — and a rebuild on that basis (message-rate `expr` driven by a
`uzi` sweep, since `gen~`+`snapshot~` can't keep pace with `uzi`'s speed)
**worked immediately**. T7 passed.

**Two new skills** came out of the T7 saga: `max-advanced-object-
methodology/SKILL.md` (read help/example patches before architecting with
an unfamiliar object; smallest verified increment; don't present a
documentation guess with confirmed-pattern confidence) and a full,
honest rewrite of `pfft-spectral-processing/SKILL.md` (the working
`buffer~`/`index~` pattern as canonical, four failed `gen~` architectures
kept as a "what didn't work" record).

## Done

- T3 passed (table 64→2048). spec.md, plan.md updated.
- T4 passed. spec.md, plan.md updated. `gen-tilde-codebox/SKILL.md`
  created and built out across this session (reserved-word collisions,
  multi-inlet findings, testing-methodology lessons).
- T5, T6 partially passed (listening confirmed, spectrogram unrun).
  spec.md, plan.md updated.
- T7 passed. `f_a_ripple_scratch_t7a.maxpat` and `t7a_inner.maxpat` in
  their final working state (`buffer~`/`index~`/`expr`/`uzi` pattern).
  Idea file's T7 entry fully rewritten with the complete story.
- Created `max-advanced-object-methodology/SKILL.md`.
- Rewrote `pfft-spectral-processing/SKILL.md` (working pattern +
  honest "what didn't work" record).

## Next session — start here

**T7b — PM in `pfft~`.** No longer blocked on a control-routing problem
(the `buffer~`/`index~` pattern generalizes to any per-bin curve,
including a phase-offset one). Real remaining question is DSP, not
plumbing: phase modulation in overlap-add STFT isn't obviously equivalent
to true per-partial phase advancement (each analysis frame only gives a
phase *snapshot*; naive per-frame phase offsets risk inter-frame
discontinuities/glitching). Will need `cartopol~`/`poltocar~` to
manipulate phase independently of magnitude — see
`pfft-spectral-processing/SKILL.md`'s "Open question: PM in `pfft~`"
section for the current thinking, thin as it is.

**Independently, whenever a spectrogram tool becomes available**: T5, T6,
and T7 all have an open spectrogram-comparison gap against the paper's
figures — same cause each time (no tool in-session), not urgent, but
worth closing whenever possible.

**T8 (cross-frequency correlation check)** remains the one the idea file
flags as "easy to skip and shouldn't be" — it's the only test of the
paper's actual claim rather than "sounds plausible." Not started.

## Loose threads

**Both `gen-tilde-codebox/SKILL.md` and `pfft-spectral-processing/
SKILL.md` grew substantially this session** — worth a read-through next
session to make sure they're still internally consistent and not
carrying stale cross-references, given how much got added/rewritten in
place under time pressure.

**Scratch patches are intentionally messy, by design, until Phase 2 is
fully done** (spectrogram gap): `f_a_ripple_scratch_t3.maxpat`,
`_t4.maxpat`, `_t5.maxpat`, `_t6.maxpat`, `_t7a.maxpat`,
`t7a_inner.maxpat`, `_t7a_bandcheck.maxpat`. Not cleaned up.

**`f_a_ripple_scratch_t7a_bandcheck.maxpat`** (the isolated
`freq_bin`/`modband` arithmetic checker) is still useful as a template
for isolating suspect arithmetic outside `pfft~`/`gen~` complexity in
future work — worth keeping even though T7's actual bug wasn't there.

**`f_a_decorrelate` stays fully blocked** on `f_a_ripple`'s T2-T6 (per
ADR-3) — T7 passing doesn't unblock it by itself, since T7 was an
architecture-comparison track (build A vs. build B), not part of the
gating sequence. Worth double-checking this dependency is still correctly
understood next session, given how much shifted around T7's own scope.

**Uncommitted.** Everything from this session — spec.md/plan.md/idea-file
updates, both new/rewritten skill files, all scratch patches — is on disk,
nothing committed. Matt commits manually.
