// f_util_vary.js -- engine of f_util_vary (control-side variation). Spec: .specify/f_util_vary/spec.md; design: ideas/f_util_vary.md.
//
// Inlet 0: bases, any `<param> <value>` (the ordinary control messages a module takes). Every base goes out of EVERY outlet as `<param> <value>`;
//          an outlet's table row adds variation to its own copy. No row, amount 0 and chance 0 all give the plain base: with an empty table
//          this is a transparent wire.
// Inlet 1: vary's own settings and table lines: roll, tick, seed, amount, chance, wobble (a scale), slew (ms), debug, refresh, clear, dump,
//          and the table lines   row / param / group, `add` (a blank row), `cell <i> <field> <value>` (an edit in row i's controls), `restore ...` (from the pattr).   (Kept off inlet 0 so a module param named `amount` or `seed` cannot collide.)
// Outlets 0..OUTS-1: one per destination (1..OUTS in the table).
//
// Table lines:
//   param <name> <lo> <hi>                                   default range for a param (rows may write - for lo and hi)
//   group <name> <corr 0..1>                                 correlation: 1 = members share one draw, 0 = independent
//   row <outlet> <param> [lo hi amount% chance% wobble% group trim% mode sign]
//        mode: u (uniform re-roll) | d (drunk: bounded walk)    sign: bi | up | down    group: name or -
// effective = clamp(base + trim + offset * amount + wobble, lo, hi), in units of the range. The offset is held between rolls; the draw is
// corr * (group's shared draw) + (1 - corr) * (the row's own draw). One global seed; every group and row derives its own streams from it.
inlets = 2; outlets = 10;   // 0-3 destinations; 4 monitor (a list of 0..1 row positions, for a multislider); 5 labels (`set ...` for a comment);
                            // 6 table state for a pattr (`restore ...`); 7 `script ...` for a thispatcher (the row UIs are scripted); 8 to the row UIs (`<i> <field> <value>`);
                            // 9 group correlation dials (`g<n> <corr>`)
// Everything lives in one closure: Max js calls any GLOBAL function named like an incoming message, and a base may be called anything.
var G0 = this;                                            // the js global, as `this` for outlet.apply
function anything() {
  try { V.anything(messagename, arrayfromargs(arguments), inlet); }
  catch (e) { post("f_util_vary: error handling '" + messagename + "': " + e + (e.lineNumber ? " (line " + e.lineNumber + ")" : "") + "\n"); }
}
function _uiRemove(n) {                                   // delete the scripted row UI `vr<n>` if it exists (an embedded patch keeps them across a save)
  try { var o = this.patcher.getnamed("vr" + n); if (o) { this.patcher.remove(o); return 1; } } catch (e) { }
  return 0;
}
var V = (function () {
var OUTS = 4;
var G = {amount: 1, chance: 1, wobble: 1, slew: 0, seed: 1};
var rows = [], byKey = {}, groups = {}, gorder = [], PARAM = {}, BASE = {}, NAMES = [], last = 0, DEBUG = 0, t0 = 0, MON = 16;
var GR = 12, UIN = 0, restoring = false, lastSer = "";        // GR: most rows the panel has room for; UIN: row UIs made so far
var ROWY0 = 186, ROWH = 22, ROWW = 368;                      // presentation geometry of the row strips
var FIELD = {out: 0, param: 1, lo: 2, hi: 3, amt: 4, chance: 5, wob: 6, group: 7, trim: 8, mode: 9, sign: 10};

function mul32(a, b) { return ((((a >>> 16) * b) % 65536) * 65536 + (a & 65535) * b) % 4294967296; }     // exact 32-bit multiply (doubles lose bits above 2^53)
function hash(s) { var h = 2166136261; for (var i = 0; i < s.length; i++) { h = (h ^ s.charCodeAt(i)) >>> 0; h = mul32(h, 16777619); } return h || 1; }
function nxt(r) { r.s = (r.s * 1664525 + 1013904223) % 4294967296; return r.s / 4294967296; }
function rs(r) { return nxt(r) * 2 - 1; }
function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
function now() { return (new Date()).getTime(); }
function num(v, d) { return (v === undefined || v === "-" || v === "" || isNaN(Number(v))) ? d : Number(v); }
function warm(r) { for (var i = 0; i < 3; i++) nxt(r); return r; }

function reseed() {
  var k, j, r;
  for (k in groups) { groups[k].rng = warm({s: hash(G.seed + "|g|" + k)}); groups[k].shared = 0; }
  for (j = 0; j < rows.length; j++) {
    r = rows[j]; var id = r.outlet + "|" + r.param;
    r.rng = warm({s: hash(G.seed + "|" + id)}); r.gate = warm({s: hash(G.seed + "|gate|" + id)}); r.wr = warm({s: hash(G.seed + "|wob|" + id)}); r.wk = 0;
  }
}
function ensureGroup(name) { if (name != "-" && !groups[name]) { groups[name] = {corr: 0.5, shared: 0, rng: warm({s: hash(G.seed + "|g|" + name)})}; gorder.push(name); } }

function defRange(p) { return PARAM[p] || {lo: 0, hi: 1}; }
function keyOf(r) { return r.param ? r.outlet + "|" + r.param : ""; }      // a row with no param yet (just added) has no key and sends nothing
function mkRow(a, blankOk) {                                 // always with its random streams (a row made by `add` or a cell edit is never reseeded before its first roll or tick)
  var r = mkRow0(a, blankOk);
  if (r) { var id = r.outlet + "|" + r.param; r.rng = warm({s: hash(G.seed + "|" + id)}); r.gate = warm({s: hash(G.seed + "|gate|" + id)}); r.wr = warm({s: hash(G.seed + "|wob|" + id)}); }
  return r;
}
function mkRow0(a, blankOk) {                                 // a row record from [outlet, param, lo, hi, amount, chance, wobble, group, trim, mode, sign], or null
  var o = Math.round(num(a[0], 0)), p = (a[1] === undefined || a[1] === "") ? "" : String(a[1]);
  if (o < 1 || o > OUTS || (!p && !blankOk)) return null;
  var d = defRange(p);
  return {outlet: o, param: p, lo: num(a[2], d.lo), hi: num(a[3], d.hi), amount: num(a[4], 10), chance: num(a[5], 100), wobble: num(a[6], 0),
          group: (a[7] === undefined || a[7] === "" || a[7] === "-") ? "-" : String(a[7]), trim: num(a[8], 0), mode: (a[9] === undefined || a[9] === "") ? "u" : String(a[9]),
          sign: (a[10] === undefined || a[10] === "") ? "bi" : String(a[10]), off: 0, tgt: 0, sent: null, wk: 0};
}
function reindex() { byKey = {}; for (var i = 0; i < rows.length; i++) if (rows[i].param) byKey[keyOf(rows[i])] = i; }
function rowCmd(a) {
  var r = mkRow(a);
  if (!r) { post("f_util_vary: bad row (outlet 1-" + OUTS + " and a param name needed): " + a.join(" ") + "\n"); return; }
  var key = keyOf(r), idx;
  if (byKey[key] !== undefined) { idx = byKey[key]; rows[idx] = r; }
  else { if (rows.length >= GR) { post("f_util_vary: at most " + GR + " rows\n"); return; } idx = rows.length; byKey[key] = idx; rows.push(r); }
  ensureGroup(r.group); addName(r.param); reseed(); labels(); uiGrow(); pushRow(idx); gpush(); commit();
}
function addCmd() {
  if (rows.length >= GR) { post("f_util_vary: at most " + GR + " rows\n"); return; }
  rows.push(mkRow([1, ""], true)); labels(); uiGrow(); pushRow(rows.length - 1);
}
function paramCmd(a) { if (a[0] !== undefined) { PARAM[String(a[0])] = {lo: num(a[1], 0), hi: num(a[2], 1)}; commit(); } }
function groupCmd(a) { if (a[0] === undefined) return; var n = String(a[0]); ensureGroup(n); groups[n].corr = clamp(num(a[1], 0.5), 0, 1); gpush(); commit(); }
function clearCmd() { rows = []; byKey = {}; groups = {}; gorder = []; PARAM = {}; labels(); uiGrow(); commit(); }          // bases are kept, so a re-applied table finds them

function value(r) {
  var range = r.hi - r.lo;
  return clamp(BASE[r.param] + r.trim / 100 * range + r.off * G.amount * r.amount / 100 * range + G.wobble * r.wobble / 100 * r.wk * range, r.lo, r.hi);
}
function emitRow(r, force) {
  if (!r.param || BASE[r.param] === undefined) return;
  var v = value(r);
  if (force || r.sent === null || Math.abs(v - r.sent) > 1e-9) {
    r.sent = v; outlet(r.outlet - 1, r.param, v);
    if (DEBUG) post("vary", "out" + r.outlet, r.param, v.toFixed(5), "+" + (now() - t0) + "ms\n");
  }
}
function emitRows(force) {
  var any = false;
  for (var i = 0; i < rows.length; i++) { var before = rows[i].sent; emitRow(rows[i], force); if (rows[i].sent !== before) any = true; }
  if (any) monitor();
}
function monitor() {                                          // normalized position of each row's value in its range, for a multislider
  var l = [], n = Math.min(MON, rows.length);
  for (var i = 0; i < n; i++) { var r = rows[i]; l.push((!r.param || BASE[r.param] === undefined || r.hi == r.lo) ? 0 : clamp((value(r) - r.lo) / (r.hi - r.lo), 0, 1)); }
  if (n) outlet(4, l);
}
function labels() {
  var t = [], n = Math.min(MON, rows.length);
  for (var i = 0; i < n; i++) t.push("o" + rows[i].outlet + "." + (rows[i].param || "?"));
  outlet(5, "set", t.length ? t.join(" ") : "(no rows)");
}

// ---- the row UIs: one scripted bpatcher (f_util_vary_row.maxpat) per row, named vr<i>; it takes `<i> <field> <value>` from outlet 8 and answers `cell <i> <field> <value>` on inlet 1 ----
function uiMake(i) {
  var y = ROWY0 + (i - 1) * ROWH;
  outlet(7, "script", "newobject", "bpatcher", "@name", "f_util_vary_row.maxpat", "@args", i, "@varname", "vr" + i, "@presentation", 1, "@presentation_rect", 2, y, ROWW, 20,
         "@patching_rect", 560, y, ROWW, 20);
  outlet(7, "script", "connect", "eng", 8, "vr" + i, 0);
  outlet(7, "script", "connect", "vr" + i, 0, "eng", 1);
}
function uiGrow() {                                          // as many row UIs as rows
  if (restoring) return;
  while (UIN < rows.length) { UIN++; uiMake(UIN); pushNames(UIN); }
  while (UIN > rows.length) { _uiRemove(UIN); UIN--; }
}
function uiRebuild() {                                       // an embedded patch saves its scripted rows, so remove any that came back and build them from the table
  if (restoring) return;
  for (var n = 1; n <= GR; n++) _uiRemove(n);
  UIN = 0; uiGrow(); pushAll(); gpush();
}
function addName(p) { if (p && NAMES.indexOf(p) < 0) { NAMES.push(p); if (!restoring && UIN) pushAll(); } }
function pushNames(only) { if (!NAMES.length) return; for (var n = only || 1; n <= (only || UIN); n++) outlet.apply(G0, [8, n, "names"].concat(NAMES)); }      // `only`: just that row (a new one)
function pushRow(i) {
  if (restoring || i >= UIN) return;
  var r = rows[i], n = i + 1, g = /^g([1-4])$/.exec(r.group);
  outlet(8, n, "out", r.outlet); outlet(8, n, "param_idx", NAMES.indexOf(r.param)); outlet(8, n, "lo", r.lo); outlet(8, n, "hi", r.hi);
  outlet(8, n, "amt", r.amount); outlet(8, n, "chance", r.chance); outlet(8, n, "wob", r.wobble); outlet(8, n, "trim", r.trim);
  outlet(8, n, "group", g ? Number(g[1]) : 0); outlet(8, n, "mode", r.mode); outlet(8, n, "sign", r.sign);
}
function pushAll() { if (restoring) return; pushNames(); for (var i = 0; i < UIN; i++) pushRow(i); }
function gpush() { if (restoring) return; for (var n = 1; n <= 4; n++) if (groups["g" + n]) outlet(9, "g" + n, groups["g" + n].corr); }

function uiCell(a) {                                         // `cell <i> <field> <value>` from row i's controls (i counts from 1)
  var i = Math.round(num(a[0], 0)) - 1, f = String(a[1]), v = a.slice(2).join(" ");
  if (DEBUG) post("f_util_vary: cell", a.join(" "), "\n");
  if (i < 0 || i >= rows.length) return;
  if (f == "del") { rows.splice(i, 1); reindex(); reseed(); labels(); uiGrow(); pushAll(); resend(); commit(); return; }
  if (FIELD[f] === undefined) { post("f_util_vary: unknown row field " + f + "\n"); return; }
  if (f == "group") { var gn = num(v, 0); v = gn >= 1 ? "g" + Math.min(4, Math.round(gn)) : "-"; }
  var cells = rowCells(rows[i]).map(String); cells[FIELD[f]] = v;
  var nr = mkRow(cells, true), old = rows[i], oldKey = keyOf(old), key = nr ? keyOf(nr) : "";
  if (!nr || (key && key != oldKey && byKey[key] !== undefined)) { post("f_util_vary: cannot use that value (outlet 1-" + OUTS + ", one row per outlet and param)\n"); pushRow(i); return; }
  if (key == oldKey) { var k2 = ["rng", "gate", "wr", "off", "tgt", "sent", "wk"]; for (var j = 0; j < k2.length; j++) nr[k2[j]] = old[k2[j]]; rows[i] = nr; }
  else { rows[i] = nr; reindex(); reseed(); }
  ensureGroup(nr.group); addName(nr.param); labels(); pushRow(i); gpush(); commit();
  if (key != oldKey) resend(); else emitRows(false);
}

function rowCells(r) { return [r.outlet, r.param, r.lo, r.hi, r.amount, r.chance, r.wobble, r.group, r.trim, r.mode, r.sign]; }

// ---- persistence: the whole table as one list for a pattr (`restore row ... | group ... | param ...`); the pattr echoes it back, so an unchanged one is ignored.
// The pattr saves with the patch only when f_util_vary is placed as an EMBEDDED bpatcher (Matt's scratch test, 2026-11-13). A row with no param yet is not stored. ----
function serialize() {
  var t = ["restore"], i, k;
  for (k in PARAM) t.push("param", k, PARAM[k].lo, PARAM[k].hi, "|");
  for (i = 0; i < gorder.length; i++) t.push("group", gorder[i], groups[gorder[i]].corr, "|");
  for (i = 0; i < rows.length; i++) if (rows[i].param) t = t.concat(["row"], rowCells(rows[i]), ["|"]);
  return t;
}
function commit() {
  if (restoring) return;
  var t = serialize(), ser = t.join(" ");
  if (ser != lastSer) { lastSer = ser; outlet.apply(G0, [6].concat(t)); }
}
function restore(a) {
  var ser = ["restore"].concat(a).join(" ");
  if (ser == serialize().join(" ")) return;                    // the echo of what was just stored
  restoring = true;
  rows = []; byKey = {}; groups = {}; gorder = []; PARAM = {};
  var seg = [];
  for (var i = 0; i <= a.length; i++) {
    if (i == a.length || a[i] == "|") { if (seg.length) settings(String(seg[0]), seg.slice(1)); seg = []; } else seg.push(a[i]);
  }
  restoring = false; lastSer = serialize().join(" "); refresh();
}

function resend() { for (var p in BASE) base(p, [BASE[p]]); }      // re-send every known base through the table
function base(name, a) {                                   // a base arrives on inlet 0
  var v = num(a[0], NaN);
  if (!isNaN(v)) { BASE[name] = v; addName(name); }
  for (var o = 1; o <= OUTS; o++) {
    var i = byKey[o + "|" + name];
    if (i !== undefined && !isNaN(v)) emitRow(rows[i], true);
    else outlet.apply(G0, [o - 1, name].concat(a));      // no row for this outlet: the plain base
  }
  if (rows.length && !isNaN(v)) monitor();
}

function roll() {
  var k, j; t0 = now();
  for (k in groups) groups[k].shared = rs(groups[k].rng);
  for (j = 0; j < rows.length; j++) {
    var r = rows[j], g = r.group == "-" ? null : groups[r.group];
    var corr = g ? g.corr : 0, d = (g ? corr * g.shared : 0) + (1 - corr) * rs(r.rng);       // both streams advance on every roll
    var gate = nxt(r.gate) < clamp(r.chance * G.chance / 100, 0, 1);
    if (!gate) continue;
    if (r.mode == "d") {
      var lo = r.sign == "up" ? 0 : -1, hi = r.sign == "down" ? 0 : 1, v = r.tgt + 0.3 * d;
      r.tgt = v > hi ? 2 * hi - v : (v < lo ? 2 * lo - v : v); r.tgt = clamp(r.tgt, lo, hi);       // reflect at the bounds
    } else {
      r.tgt = r.sign == "up" ? Math.abs(d) : (r.sign == "down" ? -Math.abs(d) : d);
    }
  }
  if (G.slew <= 0) for (j = 0; j < rows.length; j++) rows[j].off = rows[j].tgt;
  emitRows(false);
}
function tick() {
  var t = now(), dt = last ? t - last : 16; last = t;
  var f = G.slew > 0 ? 1 - Math.exp(-dt / G.slew) : 1;
  for (var i = 0; i < rows.length; i++) {
    var r = rows[i];
    r.off += (r.tgt - r.off) * f;
    if (r.wobble > 0 && G.wobble > 0) r.wk = clamp(r.wk * 0.97 + rs(r.wr) * 0.08, -1, 1);     // slow leaky walk on its own stream
  }
  emitRows(false);
}
function refresh() { labels(); uiRebuild(); resend(); }      // loadbang: rebuild the row UIs from the table, then re-send every base
function seedCmd(v) { G.seed = num(v, 1); reseed(); for (var i = 0; i < rows.length; i++) { rows[i].tgt = 0; rows[i].off = 0; } roll(); }   // "roll N" recalls a draw
function dumpCmd() {
  for (var i = 0; i < rows.length; i++) { var r = rows[i]; post("out" + r.outlet, r.param, "base", BASE[r.param], "off", r.off.toFixed(3), "group", r.group, "\n"); }
}

function settings(name, a) {                                 // inlet 1
  switch (name) {
    case "row": rowCmd(a); break;
    case "param": paramCmd(a); break;
    case "group": groupCmd(a); break;
    case "add": addCmd(); break;
    case "cell": uiCell(a); break;
    case "restore": restore(a); break;
    case "roll": roll(); break;
    case "tick": tick(); break;
    case "refresh": refresh(); break;
    case "seed": seedCmd(a[0]); break;
    case "amount": G.amount = clamp(num(a[0], 1), 0, 4); emitRows(false); break;
    case "chance": G.chance = clamp(num(a[0], 1), 0, 1); break;
    case "wobble": G.wobble = clamp(num(a[0], 1), 0, 1); break;
    case "slew": G.slew = Math.max(0, num(a[0], 0)); break;
    case "debug": DEBUG = num(a[0], 1) ? 1 : 0; post("f_util_vary: debug " + DEBUG + "\n"); break;
    case "clear": clearCmd(); break;
    case "dump": dumpCmd(); break;
    default: if (name.charAt(0) != "#") post("f_util_vary: unknown setting " + name + "\n");
  }
}
  return {anything: function (name, a, inl) {
    if (name == "list" && a.length && typeof a[0] == "string") { name = a[0]; a = a.slice(1); }      // a text/coll line may arrive as a list led by a symbol
    if (inl == 1) settings(name, a); else base(name, a);
  }};
})();
