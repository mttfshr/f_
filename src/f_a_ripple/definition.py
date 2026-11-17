# f_a_ripple patcher definition (audio_gen archetype; build/spec.md "Audio archetypes")
# Input to build/build_patcher.py.  Created 2026-11-16 (audio archetype Phase A).
# The gen~ codebox is src/f_a_ripple/codebox.gen (master copy; see its README.md).
from pathlib import Path

CODEBOX = (Path(__file__).parent / "codebox.gen").read_text()

patcher = {
    "name": "f_a_ripple",
    "prefix": "far",
    "title": "f_a_ripple",
    "archetype": "audio_gen",
    "core": "gen",
    "audio_in": False,                  # a generator: no inlet~
    "presentation_width": 330.0,        # 7 columns x 46 + margins
    "presentation_height": 152.0,       # title strip + 2 rows of dials
    "columns": 7,
    "codebox": CODEBOX,
    "params": [
        # Row 1: targeting and modulation
        {"name": "band", "type": "int", "min": 1, "max": 7, "default": 6, "label": "Band",
         "hint": "Octave band that carries the ripple, 1 (1-2 kHz) to 7 (8-16 kHz)"},
        {"name": "mod_type", "type": "menu", "options": ["AM", "PM"], "default": 0, "label": "Mod",
         "hint": "Amplitude or phase modulation of the band's partials"},
        {"name": "depth", "type": "float", "min": 0.0, "max": 1.0, "default": 1.0, "label": "Depth"},
        {"name": "tmr", "type": "float", "min": 0.1, "max": 256.0, "default": 1.0, "exponent": 3.0, "label": "TMR",
         "hint": "Temporal modulation rate in Hz (untested above about 10 Hz)"},
        {"name": "smr_mean", "type": "float", "min": 0.0, "max": 12.0, "default": 4.5, "label": "SMR Mean",
         "hint": "Mean spectral modulation rate, cycles per octave"},
        {"name": "smr_range", "type": "float", "min": 0.0, "max": 12.0, "default": 3.0, "label": "SMR Range",
         "hint": "Range of the spectral modulation rate; above the mean it reverses the ripple slope"},
        {"name": "smr_cycle", "type": "float", "min": 1.0, "max": 60.0, "default": 8.0, "label": "SMR Cycle",
         "hint": "Seconds for one sweep of the spectral modulation rate"},
        # Row 2: PM depth, carrier, level
        {"name": "pm_turns", "type": "float", "min": 0.5, "max": 8.0, "default": 0.5, "label": "PM Turns",
         "hint": "PM depth in full turns; 0.5 is the trial's actual depth"},
        {"name": "f0_lo", "type": "float", "min": 50.0, "max": 400.0, "default": 96.0, "label": "F0 Lo",
         "hint": "Low end of the random fundamental, Hz"},
        {"name": "f0_hi", "type": "float", "min": 50.0, "max": 400.0, "default": 256.0, "label": "F0 Hi",
         "hint": "High end of the random fundamental, Hz"},
        {"name": "stim_dur", "type": "float", "min": 1.0, "max": 30.0, "default": 4.0, "label": "Duration",
         "hint": "Seconds per stimulus; a new fundamental is drawn at each"},
        {"name": "ramp_pct", "type": "float", "min": 5.0, "max": 50.0, "default": 25.0, "label": "Ramp %",
         "hint": "Raised-cosine ramp at each end, percent of the stimulus"},
        {"name": "hearing_profile", "type": "menu", "options": ["NH", "Mild", "Mod", "Severe"], "default": 0,
         "label": "Hearing", "hint": "Hearing-correction boost staircase (0, 15, 30, 45 dB)"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 1.0, "default": 0.1, "label": "Gain",
         "hint": "Output level before the tanh safety ceiling"},
    ],
}
