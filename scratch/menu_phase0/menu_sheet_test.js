// menu_sheet_test.js -- Phase 0 scratch for .specify/f_modules_menu (T002, T003, T004).
// A jsui mock of the COMPACT index sheet: two columns, 12 px rows, 11 pt text, round type dots.
// The data below is illustrative (hand-copied from signal_type labels and the spec flags); the real
// build derives it from menu.py, each module's signal_type and the README.
//
// What to look at in Max:
//   T002  Is it legible at 11 pt / 12 px pitch on your laptop, in the dark?  Are the dots readable?
//   T003  Hover a row, wait a second: does a tooltip with the module's one-liner appear?
//   T004  Open the Max console (cmd-M): the measured width of every name is printed on load;
//         lines marked "TOO WIDE" need a short label.  Send the jsui the message "measure" to repeat.
// Click a row: the module name is printed to the console (the real sheet sends "addmod <module>").

mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;
outlets = 1;

var FONT = "Arial";            // change here to compare fonts
var FONT_PT = 11;
var PITCH = 12;                // row pitch, px
var GAP = 3;                   // gap between subgroup runs, px
var COL_W = 115;
var DOT = 7, DOT_GAP = 2, DOT_X = 4, NAME_X = 19, NAME_W = 85, RIGHT_DOT_X = 107;

var CYAN = [0.35, 0.75, 0.95, 1];   // SIGNAL_TYPE_COLORS "nabla"
var AMBER = [0.85, 0.55, 0.20, 1];  // SIGNAL_TYPE_COLORS "T_"
var GRAYDOT = [0.28, 0.28, 0.28, 1];// DOT_NONE
var GREEN = [0.45, 0.80, 0.50, 1];  // temporal (spec: soft green, tuned at tier 3)
var TEXT = [0.80, 0.80, 0.80, 1];
var DIM = [0.45, 0.45, 0.45, 1];    // unverified names
var HEAD_DIM = [0.62, 0.62, 0.62, 1];  // unmarked section titles: quieter than the names
var RULE = [0.25, 0.25, 0.25, 1];      // hairline under every section title
var BG = [0, 0, 0, 1];

// entry: [display, module, in, out, flags]   in/out: "v" vecfield, "t" tensor, "" none ("-" = no in-dot)
// flags: "s" source (runs with nothing patched in), "T" temporal, "u" unverified
var GROUPS = [
 ["Patterns", "", [
  [["Masonry","masonry","-","","s"],["Stipple","stipple","-","","s"],["Grain","grain","-","","sT"],["Weave","weave","-","","s"],["Seeds","vf_seeds","v","",""]],
  [["Kuramoto-Sivashinsky","ks","-","","sT"],["Chladni","chladni","-","v","s"]]]],
 ["Space & Optics", "", [
  [["Mobius","mobius","","",""],["Droste","droste","","",""],["Ngon","ngon","","","u"]],
  [["Stereo","stereo","","",""],["SIRDS","sirds","","",""]],
  [["Lens","lens","","",""]]]],
 ["Color / Tone", "", [
  [["Channel Grader","channel_grader","","",""],["Hue Processor","hue_processor","","",""],["Luma Processor","luma_processor","","",""],["Tone Curve","tone_curve","","",""]]]],
 ["Fields", "v", [
  [["Vortex","vf_vortex","-","v","s"],["Vortex Multi","vf_vortex_multi","-","v","s"]],
  [["Flow","vf_flow","-","v","s"],["Repulse","vf_repulse","","v",""],["Optical Flow","vf_optical_flow","","v",""]],
  [["Fluid","vf_fluid","v","v","T"],["Lattice Boltzmann","vf_lbm","-","v","sT"]],
  [["Vorticity","vf_vorticity","v","v",""]]]],
 ["Adapters", "", [
  [["Fieldmap","vf_fieldmap","","v",""],["Split","vf_split","v","",""],["Potential","vf_potential","v","","T"]]]],
 ["Effects", "v", [
  [["Warp","vf_warp","v","",""],["Caustic","caustic","v","",""]],
  [["Streak","vf_streak","v","",""],["Glow","vf_glow","v","",""]],
  [["Chroma","vf_chroma","v","",""],["Prism","vf_prism","v","v",""]],
  [["Advect","vf_advect","v","v","T"]]]],
 ["Tensor", "t", [
  [["Tensormap","tf_tensormap","","t",""]],
  [["Smooth","tf_smooth","t","t","Tu"],["Sharpen","tf_sharpen","t","t","u"]],
  [["Aniso Blur","tf_aniso_blur","t","","u"],["Hatch","tf_hatch","t","","u"],["Glyph","tf_glyph","t","","u"]],
  [["Axis Flow","tf_axisflow","t","v",""]]]],
 ["Routing / Mod", "", [
  [["Tex Router","texrouter","","",""],["Profile","util_profile","","",""],["Matrix 2","util_matrix_2","","",""]]]]
];
var SHORT = {"Kuramoto-Sivashinsky":"Kuramoto-Siv.", "Lattice Boltzmann":"Lattice Boltz."};
var HEAD_MARK = {"v": "\u2207 ", "t": "T_ "};   // headings keep the marks (decision 3)
// the key, drawn in the free space under the right column
var KEY_ROWS = [
  {items: [[CYAN, "vecfield"], [AMBER, "tensor"]]},
  {items: [[GRAYDOT, "other"], [GREEN, "temporal"]]},
  {text: "no left dot: source", dim: false},
  {text: "dim name: unverified", dim: true}
];
var ONELINER = "(the real sheet shows the README one-liner here)";

var rects = [];     // {x,y,w,h,module,label}
var cells = [];     // drawing list, built by layout()
var hover = -1;

function colorOf(k) { return k === "v" ? CYAN : (k === "t" ? AMBER : GRAYDOT); }

function layout() {
  // flow groups in menu order; break columns at the group boundary that best balances height
  var rows = [], g, s, e;
  for (g = 0; g < GROUPS.length; g++) {
    var n = 1;
    for (s = 0; s < GROUPS[g][2].length; s++) n += GROUPS[g][2][s].length;
    rows.push(n * PITCH + (GROUPS[g][2].length - 1) * GAP);
  }
  var total = 0, i; for (i = 0; i < rows.length; i++) total += rows[i];
  var acc = 0, brk = 0, best = 1e9;
  for (i = 0; i < rows.length - 1; i++) {
    acc += rows[i];
    var d = Math.abs(acc - (total - acc));
    if (d < best) { best = d; brk = i + 1; }
  }
  cells = []; rects = [];
  var col = 0, y = 0;
  for (g = 0; g < GROUPS.length; g++) {
    if (g === brk) { col = 1; y = 0; }
    var x0 = col * COL_W;
    var head = (HEAD_MARK[GROUPS[g][1]] || "") + GROUPS[g][0].toUpperCase();
    cells.push({kind: "head", x: x0 + 2, y: y, text: head, mark: GROUPS[g][1]});
    y += PITCH;
    for (s = 0; s < GROUPS[g][2].length; s++) {
      if (s > 0) y += GAP;
      for (e = 0; e < GROUPS[g][2][s].length; e++) {
        var ent = GROUPS[g][2][s][e];
        var idx = cells.length;
        cells.push({kind: "row", x: x0, y: y, e: ent});
        rects.push({x: x0, y: y, w: COL_W, h: PITCH, module: ent[1], cell: idx});
        y += PITCH;
      }
    }
    y += GAP;
  }
  var colEnd = [0, 0], hmax = 0;
  for (i = 0; i < cells.length; i++) {
    var cc = Math.floor(cells[i].x / COL_W);
    colEnd[cc] = Math.max(colEnd[cc], cells[i].y + PITCH);
    hmax = Math.max(hmax, cells[i].y + PITCH);
  }
  // key: one heading row + KEY_ROWS rows, anchored to the bottom of the right column
  var keyH = (1 + KEY_ROWS.length) * PITCH;
  var ky = Math.max(colEnd[1] + GAP, hmax - keyH);
  cells.push({kind: "head", x: COL_W + 2, y: ky, text: "KEY", mark: ""});
  for (i = 0; i < KEY_ROWS.length; i++) cells.push({kind: "key", x: COL_W, y: ky + (i + 1) * PITCH, row: KEY_ROWS[i]});
  hmax = Math.max(hmax, ky + keyH);
  post("menu_sheet_test: left column " + colEnd[0] + " px, right column " + colEnd[1] + " px, key at y=" + ky);
  post("menu_sheet_test: break after group " + brk + "; tallest column " + hmax + " px; jsui should be " + (2 * COL_W) + " x " + Math.ceil(hmax) + " px\n");
}

function label(ent) { return SHORT[ent[0]] || ent[0]; }

function dot(cx, cy, c) {
  mgraphics.set_source_rgba(c[0], c[1], c[2], c[3]);
  mgraphics.arc(cx, cy, DOT / 2, 0, 2 * Math.PI);
  mgraphics.fill();
}

function paint() {
  var w = box.rect[2] - box.rect[0], h = box.rect[3] - box.rect[1];
  mgraphics.set_source_rgba(BG[0], BG[1], BG[2], 1);
  mgraphics.rectangle(0, 0, w, h); mgraphics.fill();
  mgraphics.select_font_face(FONT); mgraphics.set_font_size(FONT_PT);
  for (var i = 0; i < cells.length; i++) {
    var c = cells[i];
    if (c.kind === "head") {
      var col = c.mark === "v" ? CYAN : (c.mark === "t" ? AMBER : HEAD_DIM);
      mgraphics.set_source_rgba(col[0], col[1], col[2], 1);
      mgraphics.move_to(c.x, c.y + PITCH - 3); mgraphics.show_text(c.text);
      mgraphics.set_source_rgba(RULE[0], RULE[1], RULE[2], 1);
      mgraphics.rectangle(c.x - 2, c.y + PITCH - 1, COL_W - 8, 1); mgraphics.fill();
      continue;
    }
    if (c.kind === "key") {
      var kmid = c.y + PITCH / 2, r = c.row;
      mgraphics.set_source_rgba(HEAD_DIM[0], HEAD_DIM[1], HEAD_DIM[2], 1);
      if (r.items) {
        for (var k = 0; k < r.items.length; k++) {
          var kx = c.x + DOT_X + k * 57;
          dot(kx + DOT / 2, kmid, r.items[k][0]);
          mgraphics.set_source_rgba(HEAD_DIM[0], HEAD_DIM[1], HEAD_DIM[2], 1);
          mgraphics.move_to(kx + DOT + 3, c.y + PITCH - 2); mgraphics.show_text(r.items[k][1]);
        }
      } else {
        var kc = r.dim ? DIM : HEAD_DIM;
        mgraphics.set_source_rgba(kc[0], kc[1], kc[2], 1);
        mgraphics.move_to(c.x + DOT_X, c.y + PITCH - 2); mgraphics.show_text(r.text);
      }
      continue;
    }
    var ent = c.e, midy = c.y + PITCH / 2;
    if (i === hover) { mgraphics.set_source_rgba(0.15, 0.15, 0.2, 1); mgraphics.rectangle(c.x, c.y, COL_W, PITCH); mgraphics.fill(); }
    if (ent[2] !== "-") dot(c.x + DOT_X + DOT / 2, midy, colorOf(ent[2]));
    dot(c.x + DOT_X + DOT + DOT_GAP + DOT / 2, midy, colorOf(ent[3]));
    var tc = ent[4].indexOf("u") >= 0 ? DIM : TEXT;
    mgraphics.set_source_rgba(tc[0], tc[1], tc[2], 1);
    mgraphics.move_to(c.x + NAME_X, c.y + PITCH - 2); mgraphics.show_text(label(ent));
    if (ent[4].indexOf("T") >= 0) dot(c.x + RIGHT_DOT_X, midy, GREEN);
  }
}

function hit(x, y) {
  for (var i = 0; i < rects.length; i++) {
    var r = rects[i];
    if (x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h) return i;
  }
  return -1;
}

function onclick(x, y) {
  var i = hit(x, y);
  if (i >= 0) post("addmod " + rects[i].module + "\n");
}

function onidle(x, y) {
  var i = hit(x, y), cell = i >= 0 ? rects[i].cell : -1;
  if (cell !== hover) {
    hover = cell; mgraphics.redraw();
    // T003: try to set this box's own hint; wire outlet 0 to a [thispatcher]; varname of this jsui = "sheet"
    if (i >= 0) outlet(0, "script", "sendbox", "sheet", "hint", rects[i].module + ": " + ONELINER);
    else outlet(0, "script", "sendbox", "sheet", "hint", "");
  }
}
function onidleout() { if (hover !== -1) { hover = -1; mgraphics.redraw(); } }

function measure() {   // T004
  mgraphics.select_font_face(FONT); mgraphics.set_font_size(FONT_PT);
  for (var g = 0; g < GROUPS.length; g++)
    for (var s = 0; s < GROUPS[g][2].length; s++)
      for (var e = 0; e < GROUPS[g][2][s].length; e++) {
        var ent = GROUPS[g][2][s][e], t = label(ent);
        var m = mgraphics.text_measure(t), flag = m[0] > NAME_W ? "  <-- TOO WIDE (limit " + NAME_W + ")" : "";
        post("measure: " + t + " = " + Math.round(m[0]) + " px" + flag + "\n");
      }
}

function measure_key() {
  mgraphics.select_font_face(FONT); mgraphics.set_font_size(FONT_PT);
  for (var i = 0; i < KEY_ROWS.length; i++) {
    var r = KEY_ROWS[i], w;
    if (r.text) w = mgraphics.text_measure(r.text)[0] + DOT_X;
    else w = DOT_X + 57 + DOT + 3 + mgraphics.text_measure(r.items[1][1])[0];
    post("key row " + i + " = " + Math.round(w) + " px" + (w > COL_W - 4 ? "  <-- TOO WIDE (limit " + (COL_W - 4) + ")" : "") + "\n");
  }
}

function bang() { layout(); measure(); measure_key(); mgraphics.redraw(); }
function loadbang() { bang(); }
layout();
