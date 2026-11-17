# f_a_decorrelate patcher definition (audio_pfft archetype; build/spec.md "Audio archetypes", Phase C)
# Input to build/build_patcher.py.  Created 2026-11-16.
# Hand-kept inputs, see src/f_a_decorrelate/README.md: inner.maxpat (the pfft~ subpatch, copied verbatim to
# package/patchers/f_a_decorrelate_inner.maxpat) and fragment.json (the control chain, spliced).
# v1 ranges and defaults are those of .specify/f_a_decorrelate/spec.md and plan.md (Phase 3).

patcher = {
    "name": "f_a_decorrelate",
    "prefix": "fad",
    "title": "f_a_decorrelate",
    "archetype": "audio_pfft",
    "core": "pfft",
    "inner": "inner.maxpat",
    "fft": [2048, 4],
    "fragment": "fragment.json",
    "latency_samples": 1536,            # window - hop = 2048 - 512: the wet path's delay, matched on the dry path
    "audio_in": True,
    "audio_in_comment": "audio in",
    "audio_outputs": ["audio out (35 ms latency)"],
    "safety_tanh": True,
    "presentation_width": 330.0,
    "presentation_height": 152.0,
    "columns": 7,
    "params": [
        {"name": "band", "type": "int", "min": 1, "max": 7, "default": 6, "label": "Band",
         "hint": "Octave band that carries the modulation, 1 (1-2 kHz) to 7 (8-16 kHz)"},
        {"name": "mod_type", "type": "menu", "options": ["AM", "PM"], "default": 0, "label": "Mod",
         "hint": "Per-bin gain (AM) or per-bin phase rotation (PM)"},
        {"name": "depth", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0, "label": "Depth",
         "hint": "Modulation depth; above 1 the bin gain goes negative (not offered)"},
        {"name": "tmr", "type": "float", "min": 0.1, "max": 4.0, "default": 1.0, "label": "TMR",
         "hint": "Temporal modulation rate in Hz; above about 4 the 2048-sample window is the limit"},
        {"name": "smr_mean", "type": "float", "min": 0.0, "max": 12.0, "default": 4.5, "label": "SMR Mean",
         "hint": "Mean spectral modulation rate, cycles per octave"},
        {"name": "smr_range", "type": "float", "min": 0.0, "max": 12.0, "default": 3.0, "label": "SMR Range",
         "hint": "Range of the spectral modulation rate"},
        {"name": "smr_cycle", "type": "float", "min": 1.0, "max": 60.0, "default": 8.0, "label": "SMR Cycle",
         "hint": "Seconds for one sweep of the spectral modulation rate"},
        {"name": "q", "type": "float", "min": 0.0, "max": 6.283185307, "default": 0.0, "label": "Phase q",
         "hint": "Starting phase of the temporal modulation, radians"},
        {"name": "p", "type": "float", "min": 0.0, "max": 6.283185307, "default": 0.0, "label": "Phase p",
         "hint": "Starting phase of the spectral modulation sweep, radians"},
        {"name": "mix", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0, "label": "Mix", "stage": "mix",
         "hint": "Wet / dry. The dry path is delayed to match the wet path"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 1.5, "default": 1.0, "label": "Gain", "stage": "gain",
         "hint": "Output trim after the tanh safety ceiling"},
    ],
}
