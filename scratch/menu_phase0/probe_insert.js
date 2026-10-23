// probe_insert.js -- Phase 0 scratch for .specify/f_modules_menu, T001 (decision gate G1).
// Question: when a click in a FLOATING palette window runs this, which patcher does
// max.frontpatcher return, and can we insert an object into it?
//
// Message "insert": prints the frontmost patcher's name (and this palette's own name), then adds a
// button to the frontmost patcher when it is not the palette.  "insert_any" adds one regardless.
// Open menu_target_probe.maxpat and menu_palette_probe.maxpat, click in the target patch's window
// first, then click [insert] in the palette, and read the Max console.

function describe(p) { return p ? (p.name || "(unnamed)") + "  [" + (p.filepath || "no filepath") + "]" : "none"; }

function insert() {
  var fp = max.frontpatcher, me = this.patcher;
  post("T001 frontpatcher = " + describe(fp) + "\n");
  post("T001 this palette  = " + describe(me) + "\n");
  if (!fp) { post("T001 RESULT: no front patcher\n"); return; }
  if (fp.name === me.name) { post("T001 RESULT: front patcher IS the palette; nothing inserted\n"); return; }
  fp.newdefault(30, 60, "button");
  post("T001 RESULT: inserted a button into " + (fp.name || "(unnamed)") + "\n");
}

function insert_any() {
  var fp = max.frontpatcher;
  if (fp) { fp.newdefault(30, 90, "button"); post("T001 inserted into " + describe(fp) + "\n"); }
}
