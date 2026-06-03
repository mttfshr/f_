// profile_rows.js
// CPU-side row luminance profile for f_util_profile
// Input: 1×height char matrix from jit.gl.asyncread → jit.dimop @op avg @step 640 1
//        Each cell is the average RGBA of one row of the source texture.
// Output: 128×1 float32 jit_matrix — interpolated luminance profile across rows
// Param:  res_rows (int 1–128, default 64) — number of analysis slabs

outlets = 1;

var res = 64;
var lastOut = null;

function init() {
    lastOut = new JitterMatrix(1, "float32", 128, 1);
    for (var i = 0; i < 128; i++) {
        lastOut.setcell([i, 0], "val", 0.5);
    }
}
init();

function jit_matrix(name) {
    var m      = new JitterMatrix(name);
    var height = m.dim[1];

    var rowsPerSlab = height / res;
    var slabs = [];
    for (var s = 0; s < res; s++) {
        var row = Math.floor(s * rowsPerSlab + rowsPerSlab / 2);
        row = Math.min(row, height - 1);
        var px = m.getcell([0, row]);
        slabs[s] = (0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]) / 255.0;
    }

    var out = new JitterMatrix(1, "float32", 128, 1);
    for (var j = 0; j < 128; j++) {
        var t    = (res > 1) ? j * (res - 1) / 127.0 : 0;
        var lo   = Math.floor(t);
        var hi   = Math.min(lo + 1, res - 1);
        var frac = t - lo;
        var val  = slabs[lo] * (1.0 - frac) + slabs[hi] * frac;
        out.setcell([j, 0], "val", val);
    }

    lastOut = out;
    outlet(0, "jit_matrix", out.name);
}

function res_rows(n) {
    res = Math.max(1, Math.min(128, Math.round(n)));
}
