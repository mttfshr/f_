# Batch 4 triage (2026-11-06)

Offline by Claude and omp, nothing run in Max. Rows combine omp report `f_omp_runs/batch4-triage-1/REPORT.md` (snapshot `3abb8ab`) with Claude's spot-checks of the repo. Unmarked facts are per that report, not verified. Doc-clean claims in that report are NOT trustworthy: it found 0 of 2 planted errors.

| Module | Status | Reason |
|---|---|---|
| `f_vf_warp` | Candidate | 46 boxes stale; bypass_gate, named bench entry (opened). Tier-3 note is stale (`HANDOFF_ARCHIVE.md:941`) |
| `f_stipple` | Candidate | T034-T037 live checks, T038 optional cost; bypass_gate, named entry (opened) |
| `f_vf_glow` | Candidate | Helpfile unwired and thin; line 25 stale `strength`; T039-T043 unbuilt, Matt's call |
| `f_vf_prism` | Candidate | T001 residue (bench comment, `exp()` note, both opened); "Two outlets" and `strength` stale; helpfile unwired |
| `f_vf_advect` | Needs work | `definition.py:15` and `spec.md:239` wrong on out3 under bypass (opened); `G-edge-wrap` residue, Matt's call; helpfile unwired |
| `f_vf_streak` | Needs work | Falloff: weight sum 8 - 4 * falloff is zero at 2.0, in the dial range, no guard seen. No decision found on record; Matt's call. T055 sweep |
| `f_vf_vortex` | Held | Native bypass, not asserted; docs say neutral. "At vs_black (0.5)" looks wrong (inferred, not run) |
| `f_vf_optical_flow` | Held | Native (`attrui bypass` into three pix, opened), frame not asserted |
| `f_vf_seeds` | Held | Open gate-box bug (`tasks.md:436`, opened); native, not asserted |
| `f_vf_repulse` | Out | Filed T002, T003 not done |
| `f_sirds` | Out | Filed T001-T003 not done; doc paths wrong (opened) |

`status.json` lists `f_vf_warp` under `stable/`: stale. The folder is at the `.specify/` root; git shows one commit on the old path, `6bc874f` (a move is inferred).

Groups: A = warp, stipple, glow, prism. B = advect, streak, and vortex if migrated. Later = optical_flow, seeds.

Open for Matt: streak falloff; whether `G-edge-wrap` closes and advect out3 taps (`codebox_advect.gen:71-74`) block; glow T039-T043 carry over; bypass calls for vortex, optical_flow, seeds; vortex `vs_black`; advect Trail cap.

## omp harness results

| Run | Method | Plants found | Notes |
|---|---|---|---|
| `batch4-triage-1` | one worker per module | 0 of 2 | Not trustworthy for docs |
| `doc-ledger-pilot-1` | every claim ruled, two blind passes | 6 of 9 | Gate failed; script checks 6 of 6 default and route plants |
| `doc-prose-pilot-2` | decompose, answer blind from code, compare | 11 of 12 | Gate passed narrowly; 12 of 15 flags correct; missed real `vs_black` error |

Reports in `f_omp_runs/` contain planted errors that exist only in those run folders. Never apply a fix from them without checking the repo. An omp `agree` is not a clean bill: preflight still reads the patcher and doc. Before a wave on the remaining modules, fix the premise, shared-word and `agree` leaks (skill `omp-fanout`, `references/lessons.md`) and plant errors in every run.
