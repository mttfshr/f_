// masonry_toggle.js
// Receives 0 (controls panel) or 1 (matrix panel).
// Scripts presentation visibility via thispatcher script sendbox.

var CONTROLS_OBJS = [
    "courses",
    "bond",
    "offset",
    "angle",
    "skip",
    "quantize",
    "regularity",
    "drift",
    "phase",
    "speed_var",
    "mortar",
    "softness",
    "width",
    "roundness",
    "course_color",
    "brick_color",
    "course_seed",
    "brick_seed",
    "lbl_courses",
    "lbl_bond",
    "lbl_offset",
    "lbl_angle",
    "lbl_skip",
    "lbl_quantize",
    "lbl_regularity",
    "lbl_drift",
    "lbl_phase",
    "lbl_speed_var",
    "lbl_mortar",
    "lbl_softness",
    "lbl_width",
    "lbl_roundness",
    "lbl_course_color",
    "lbl_brick_color"
];

var MATRIX_OBJS = [
    "matrix_grid"
];

function msg_int(v)   { setpanel(v); }
function msg_float(v) { setpanel(Math.round(v)); }

function setpanel(show_matrix) {
    var i;
    for (i = 0; i < CONTROLS_OBJS.length; i++) {
        outlet(0, "script", "sendbox", CONTROLS_OBJS[i], "hidden", show_matrix ? 1 : 0);
    }
    for (i = 0; i < MATRIX_OBJS.length; i++) {
        outlet(0, "script", "sendbox", MATRIX_OBJS[i], "hidden", show_matrix ? 0 : 1);
    }
}
