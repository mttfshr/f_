// hue_strip.js
autowatch = 1;
inlets = 4;

var width = 300;
var height = 40;

var hue_center  = 120.0;
var hue_lower   = 36.0;
var hue_upper   = 36.0;
var edge_falloff = 10.0;

var mat = new JitterObject("jit.matrix", 4, "char", width, height);

function bang() { draw(); }

function msg_int(v)   { msg_float(v); }
function msg_float(v) {
    post("inlet", inlet, "value", v, "\n");
    if (inlet == 0) hue_center = v;
    if (inlet == 1) hue_lower  = v;
    if (inlet == 2) hue_upper  = v;
    if (inlet == 3) edge_falloff = v;
    draw();
}

function draw() {
    var center_n = hue_center   / 360.0;
    var lower_n  = hue_lower    / 360.0;
    var upper_n  = hue_upper    / 360.0;
    var fall_n   = Math.max(edge_falloff / 360.0, 0.00001);
    var center_x = Math.round(center_n * width);

    for (var x = 0; x < width; x++) {
        var h   = x / width;
        var rgb = hsv_to_rgb(h, 1.0, 1.0);

        // mirrors Gen codebox exactly
        var wrapped     = ((h - center_n + 0.5) % 1.0 + 1.0) % 1.0;
        var signed_dist = wrapped - 0.5;

        var upper_t = smoothstep(upper_n, upper_n + fall_n, Math.max(signed_dist,  0.0));
        var lower_t = smoothstep(lower_n, lower_n + fall_n, Math.max(-signed_dist, 0.0));
        var mask    = (1.0 - upper_t) * (1.0 - lower_t);

        // full brightness in band, dim outside, gradient in falloff zone
        var brightness = 0.2 + mask * 0.8;

        for (var y = 0; y < height; y++) {
            var r = Math.round(rgb[0] * 255 * brightness);
            var g = Math.round(rgb[1] * 255 * brightness);
            var b = Math.round(rgb[2] * 255 * brightness);
            mat.setcell2d(x, y, 255, r, g, b);  // ARGB
        }
    }

    // center marker — white, 3px wide
    for (var mx = Math.max(0, center_x - 1); mx <= Math.min(width - 1, center_x + 1); mx++) {
        for (var y = 0; y < height; y++) {
            mat.setcell2d(mx, y, 255, 255, 255, 255);
        }
    }

    outlet(0, "jit_matrix", mat.name);
}

function smoothstep(edge0, edge1, x) {
    var t = Math.min(Math.max((x - edge0) / (edge1 - edge0), 0.0), 1.0);
    return t * t * (3.0 - 2.0 * t);
}

function hsv_to_rgb(h, s, v) {
    var h6 = h * 6.0;
    var r  = Math.min(Math.max(Math.abs(h6 - 3.0) - 1.0, 0.0), 1.0);
    var g  = Math.min(Math.max(2.0 - Math.abs(h6 - 2.0), 0.0), 1.0);
    var b  = Math.min(Math.max(2.0 - Math.abs(h6 - 4.0), 0.0), 1.0);
    return [
        v * (1.0 - s + s * r),
        v * (1.0 - s + s * g),
        v * (1.0 - s + s * b)
    ];
}

draw();