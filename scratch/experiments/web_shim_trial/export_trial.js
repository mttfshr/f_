// export_trial.js -- web_shim_candidates exportcode trial (scratch, 2026-10-12)
// Runs inside split_export_js.maxpat. Builds a jit.gl.pix with the
// f_vf_split genjit loaded, sends `exportcode webgl` then `exportcode isf`,
// records status + errors to _status.json (one JSON object per line),
// then closes the patcher window (never quits Max).

var OUTDIR, STATUS, pix, errprint, t0;

function bang() {
    var here = this.patcher.filepath.replace(/\/[^\/]*$/, "");
    OUTDIR = here + "/_exports";
    STATUS = here + "/_status.json";

    t0 = new Date();
    status("start", {});

    pix = this.patcher.newdefault(100, 100, "jit.gl.pix", "foo");
    errprint = this.patcher.newdefault(100, 160, "print", "pix_err");
    this.patcher.connect(pix, 1, errprint, 0);   // pix right outlet = errors

    try {
        pix.message("gen", "split_export.genjit");   // relative to patcher folder
    } catch (e) {
        status("gen_load_error", {error: String(e)});
        finish();
        return;
    }
    status("gen_loaded", {});
    pix.message("exportfolder", OUTDIR);

    try {
        pix.message("exportcode", "webgl");
        status("sent_webgl", {});
    } catch (e) {
        status("webgl_error", {error: String(e)});
    }
    new Task(do_isf, this).schedule(2000);
}

function do_isf() {
    status("webgl_phase_done", {files: listExports()});
    try {
        pix.message("exportcode", "isf");
        status("sent_isf", {});
    } catch (e) {
        status("isf_error", {error: String(e)});
    }
    new Task(do_finish, this).schedule(2000);
}

function do_finish() {
    status("isf_phase_done", {files: listExports()});
    finish();
}

function listExports() {
    var f = new Folder(OUTDIR), names = [];
    f.reset();
    while (!f.end) { names.push(f.filename); f.next(); }
    f.close();
    return names;
}

function status(stage, fields) {
    var rec = {stage: stage, t_ms: (new Date()) - t0};
    for (var k in fields) rec[k] = fields[k];
    var f = new File(STATUS, "readwrite", "JSON");
    if (stage === "start") f.eof = 0;
    else f.position = f.eof;          // append: keep every phase's record
    f.writestring(JSON.stringify(rec) + "\n");
    f.close();
}

function finish() {
    status("done", {files: listExports()});
    this.patcher.message("wclose");
}