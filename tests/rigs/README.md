# tests/rigs

Standalone Max patches for hearing or measuring a module, kept outside the module itself
(audio archetype decision, `build/spec.md` "Audio archetypes" Q1b). Hand-authored bpatcher-composition
JSON (allowed by the `vsynth-bpatcher` skill); not run by any test, not shipped in the package.

- `f_a_ripple_rig.maxpat`: an `f_a_ripple` bpatcher into `ezdac~`, `scope~`, `spectroscope~` and `peakamp~`.
  Written 2026-11-16, not opened in Max (Matt's check, `.specify/f_a_ripple/tasks.md` T013).
- `f_a_purr_rig.maxpat`: an `f_a_purr` bpatcher with a `phasor~ 0.3` into its breath-phase inlet, `ezdac~`, a `scope~` on each outlet and a `peakamp~`. Written 2026-11-16, not opened in Max.
- `f_a_decorrelate_rig.maxpat`: a `noise~` carrier into an `f_a_decorrelate` bpatcher, `ezdac~`, `spectroscope~`, `scope~`. Written 2026-11-16, not opened in Max. (The T002 null rig of the v1 work is outside the repo.)
