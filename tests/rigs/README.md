# tests/rigs

Standalone Max patches for hearing or measuring a module, kept outside the module itself
(audio archetype decision, `build/spec.md` "Audio archetypes" Q1b). Hand-authored bpatcher-composition
JSON (allowed by the `vsynth-bpatcher` skill); not run by any test, not shipped in the package.

- `f_a_ripple_rig.maxpat`: an `f_a_ripple` bpatcher into `ezdac~`, `scope~`, `spectroscope~` and `peakamp~`.
  Written 2026-11-16, not opened in Max (Matt's check, `.specify/f_a_ripple/tasks.md` T013).
