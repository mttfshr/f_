// lens_tiltcenter.js
// Computes jit.fx.cf.tiltshift center x,y from tilt_pos and tilt_axis.
//
// Inlets:
//   0 — tilt_pos (float, 0-1; 0.5 = band at frame center)
//   1 — tilt_axis (float, 0-1; mapped internally to 0-180 degrees)
//
// Outlet:
//   0 — "center <x> <y>" message for jit.fx.cf.tiltshift
//
// In linear mode: moves the focal band along the angle direction.
// In radial mode: shifts the focal point from center.
// offset range ±1.0 keeps the band within frame at all slope values.

inlets = 2;
outlets = 1;

var tilt_pos = 0.5;
var tilt_axis = 0.0;

function msg_float(v) {
    if (inlet == 0) {
        tilt_pos = v;
    } else {
        tilt_axis = v;
    }
    compute();
}

function msg_int(v) {
    msg_float(v);
}

function compute() {
    var offset = (tilt_pos - 0.5) * 2.0;
    var angle_deg = tilt_axis * 180.0;
    var angle_rad = angle_deg * Math.PI / 180.0;
    var cx = offset * (-Math.sin(angle_rad));
    var cy = offset * Math.cos(angle_rad);
    outlet(0, "center", cx, cy);
    outlet(0, "angle", angle_deg);
}
