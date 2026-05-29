// lens_toggle.js
// Receives 0 (lens panel) or 1 (field panel).
// Scripts presentation visibility via thispatcher script sendbox.

var LENS_OBJS = [
    "aberration",   "distortion",   "transmission", "tilt",
    "tilt_axis",    "tilt_pos",     "slope",        "mode",
    "lbl_aberration", "lbl_distortion", "lbl_transmission", "lbl_tilt",
    "lbl_tilt_axis",  "lbl_tilt_pos",   "lbl_slope",        "lbl_mode"
];

var FIELD_OBJS = [
    "aberration_mod",     "distortion_mod",
    "transmission_mod",   "surface_mod",
    "lbl_aberration_mod", "lbl_distortion_mod",
    "lbl_transmission_mod","lbl_surface_mod"
];

function msg_int(v)   { setpanel(v); }
function msg_float(v) { setpanel(Math.round(v)); }

function setpanel(show_field) {
    var i;
    for (i = 0; i < LENS_OBJS.length; i++) {
        outlet(0, "script", "sendbox", LENS_OBJS[i], "hidden", show_field ? 1 : 0);
    }
    for (i = 0; i < FIELD_OBJS.length; i++) {
        outlet(0, "script", "sendbox", FIELD_OBJS[i], "hidden", show_field ? 0 : 1);
    }
}
