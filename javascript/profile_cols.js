// profile_cols.js
// CPU-side column luminance profile for f_util_profile
// Input: width×1 char matrix from jit.gl.asyncread → jit.dimop @op avg @step 1 640
//        Each cell is the average RGBA of one column of the source texture.
// Output: 1×128 float32 jit_matrix — interpolated luminance profile across columns
// Param:  res_cols (int 1–128, default 64) — number of analysis slabs

outlets = 1;

var res = 64;
var lastOut = null;

function init() {
    lastOut = new JitterMatrix(1, "float32", 1, 128);
    for (var i = 0; i < 128; i++) {
        lastOut.setcell([0, i], "val", 0.5);
    }
}
init();

function jit_matrix(name) {
    var m     = new JitterMatrix(name);
    var width = m.dim[0];

    var colsPerSlab = width / res;
    var slabs = [];
    for (var s = 0; s < res; s++) {
        var col = Math.floor(s * colsPerSlab + colsPerSlab / 2);
        col = Math.min(col, width - 1);
        var px = m.getcell([col, 0]);
        slabs[s] = (0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]) / 255.0;
    }

    var out = new JitterMatrix(1, "float32", 1, 128);
    for (var j = 0; j < 128; j++) {
        var t    = (res > 1) ? j * (res - 1) / 127.0 : 0;
        var lo   = Math.floor(t);
        var hi   = Math.min(lo + 1, res - 1);
        var frac = t - lo;
        var val  = slabs[lo] * (1.0 - frac) + slabs[hi] * frac;
        out.setcell([0, j], "val", val);
    }

    lastOut = out;
    outlet(0, "jit_matrix", out.name);
}

function res_cols(n) {
    res = Math.max(1, Math.min(128, Math.round(n)));
}
