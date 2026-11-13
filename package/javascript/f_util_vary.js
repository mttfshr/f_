// f_util_vary.js -- engine of f_util_vary (control-side variation). Spec: .specify/f_util_vary/spec.md; design: ideas/f_util_vary.md.
//
// Inlet 0: bases, any `<param> <value>` (the ordinary control messages a module takes). Every base goes out of EVERY outlet as `<param> <value>`;
//          an outlet's table row adds variation to its own copy. No row, amount 0 and chance 0 all give the plain base: with an empty table
//          this is a transparent wire.
// Inlet 1: vary's own settings and table lines: roll, tick, seed, amount, chance, wobble (a scale), slew (ms), debug, refresh, clear, dump,
//          and the table lines   row / param / group / knob.   (Kept off inlet 0 so a module param named `amount` or `seed` cannot collide.)
// Outlets 0..OUTS-1: one per destination (1..OUTS in the table).
//
// Table lines:
//   param <name> <lo> <hi>                                   default range for a param (rows may write - for lo and hi)
//   group <name> <corr 0..1>                                 correlation: 1 = members share one draw, 0 = independent
//   row <outlet> <param> [lo hi amount% chance% wobble% group trim% mode sign]
//        mode: u (uniform re-roll) | d (drunk: bounded walk)    sign: bi | up | down    group: name or -
// effective = clamp(base + trim + offset * amount + wobble, lo, hi), in units of the range. The offset is held between rolls; the draw is
// corr * (group's shared draw) + (1 - corr) * (the row's own draw). One global seed; every group and row derives its own streams from it.
inlets = 2; outlets = 6;   // 0-3 destinations; 4 monitor (a list of 0..1 row positions, for a multislider); 5 labels (`set ...` for a comment)
// Everything lives in one closure: Max js calls any GLOBAL function named like an incoming message, and a base may be called anything.
function anything() { V.anything(messagename, arrayfromargs(arguments), inlet); }
var V = (function () {
var OUTS = 4;
var G = {amount: 1, chance: 1, wobble: 1, slew: 0, seed: 1};
var rows = [], byKey = {}, groups = {}, PARAM = {}, BASE = {}, KN = {}, last = 0, DEBUG = 0, t0 = 0, MON = 16;

function mul32(a, b) { return ((((a >>> 16) * b) % 65536) * 65536 + (a & 65535) * b) % 4294967296; }     // exact 32-bit multiply (doubles lose bits above 2^53)
function hash(s) { var h = 2166136261; for (var i = 0; i < s.length; i++) { h = (h ^ s.charCodeAt(i)) >>> 0; h = mul32(h, 16777619); } return h || 1; }
function nxt(r) { r.s = (r.s * 1664525 + 1013904223) % 4294967296; return r.s / 4294967296; }
function rs(r) { return nxt(r) * 2 - 1; }
function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }
function now() { return (new Date()).getTime(); }
function num(v, d) { return (v === undefined || v === "-" || isNaN(Number(v))) ? d : Number(v); }
function warm(r) { for (var i = 0; i < 3; i++) nxt(r); return r; }

function reseed() {
  var k, j, r;
  for (k in groups) { groups[k].rng = warm({s: hash(G.seed + "|g|" + k)}); groups[k].shared = 0; }
  for (j = 0; j < rows.length; j++) {
    r = rows[j]; var id = r.outlet + "|" + r.param;
    r.rng = warm({s: hash(G.seed + "|" + id)}); r.gate = warm({s: hash(G.seed + "|gate|" + id)}); r.wr = warm({s: hash(G.seed + "|wob|" + id)}); r.wk = 0;
  }
}
function ensureGroup(name) { if (name != "-" && !groups[name]) groups[name] = {corr: 0.5, shared: 0, rng: warm({s: hash(G.seed + "|g|" + name)})}; }

function defRange(p) { return PARAM[p] || {lo: 0, hi: 1}; }
function rowCmd(a) {
  var o = Math.round(num(a[0], 0)), p = a[1] === undefined ? "" : String(a[1]);
  if (o < 1 || o > OUTS || !p) { post("f_util_vary: bad row (outlet 1-" + OUTS + " and a param name needed): " + a.join(" ") + "\n"); return; }
  var d = defRange(p);
  var r = {outlet: o, param: p, lo: num(a[2], d.lo), hi: num(a[3], d.hi), amount: num(a[4], 10), chance: num(a[5], 100), wobble: num(a[6], 0),
           group: (a[7] === undefined || a[7] === "-") ? "-" : String(a[7]), trim: num(a[8], 0), mode: a[9] === undefined ? "u" : String(a[9]),
           sign: a[10] === undefined ? "bi" : String(a[10]), off: 0, tgt: 0, sent: null, wk: 0};
  var key = o + "|" + p;
  if (byKey[key] !== undefined) rows[byKey[key]] = r; else { byKey[key] = rows.length; rows.push(r); }
  ensureGroup(r.group); reseed(); labels();
}
function paramCmd(a) { if (a[0] !== undefined) PARAM[String(a[0])] = {lo: num(a[1], 0), hi: num(a[2], 1)}; }
function groupCmd(a) { if (a[0] === undefined) return; var n = String(a[0]); ensureGroup(n); groups[n].corr = clamp(num(a[1], 0.5), 0, 1); }
function clearCmd() { rows = []; byKey = {}; groups = {}; PARAM = {}; KN = {}; labels(); }          // bases are kept, so a re-applied table finds them

function value(r) {
  var range = r.hi - r.lo;
  return clamp(BASE[r.param] + r.trim / 100 * range + r.off * G.amount * r.amount / 100 * range + G.wobble * r.wobble / 100 * r.wk * range, r.lo, r.hi);
}
function emitRow(r, force) {
  if (BASE[r.param] === undefined) return;
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
  for (var i = 0; i < n; i++) { var r = rows[i]; l.push((BASE[r.param] === undefined || r.hi == r.lo) ? 0 : clamp((value(r) - r.lo) / (r.hi - r.lo), 0, 1)); }
  if (n) outlet(4, l);
}
function labels() {
  var t = [], n = Math.min(MON, rows.length);
  for (var i = 0; i < n; i++) t.push("o" + rows[i].outlet + "." + rows[i].param);
  outlet(5, "set", t.length ? t.join(" ") : "(no rows)");
}
// knob <n> row <outlet> <param> <field>   or   knob <n> group <name>.   Values arrive as `k <n> <0..1>` from a dial.
function knobCmd(a) {
  var n = Math.round(num(a[0], 0));
  if (n < 1 || n > 4) { post("f_util_vary: knob 1-4 only: " + a.join(" ") + "\n"); return; }
  if (a[1] == "row") KN[n] = {kind: "row", key: Math.round(num(a[2], 0)) + "|" + String(a[3]), field: String(a[4])};
  else if (a[1] == "group") KN[n] = {kind: "group", name: String(a[2])};
  else post("f_util_vary: knob needs row or group: " + a.join(" ") + "\n");
}
function knobSet(a) {
  var k = KN[Math.round(num(a[0], 0))], v = clamp(num(a[1], 0), 0, 1);
  if (!k) return;
  if (k.kind == "group") { if (groups[k.name]) groups[k.name].corr = v; return; }
  var i = byKey[k.key]; if (i === undefined) return;
  var r = rows[i];
  if (k.field == "amount") r.amount = v * 100; else if (k.field == "chance") r.chance = v * 100; else if (k.field == "wobble") r.wobble = v * 100;
  else if (k.field == "trim") r.trim = (v * 2 - 1) * 100; else return;
  emitRows(false);
}

function base(name, a) {                                   // a base arrives on inlet 0
  var v = num(a[0], NaN);
  if (!isNaN(v)) BASE[name] = v;
  for (var o = 1; o <= OUTS; o++) {
    var i = byKey[o + "|" + name];
    if (i !== undefined && !isNaN(v)) emitRow(rows[i], true);
    else outlet.apply(null, [o - 1, name].concat(a));      // no row for this outlet: the plain base
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
function refresh() { for (var p in BASE) base(p, [BASE[p]]); }      // re-send every known base through the (new) table
function seedCmd(v) { G.seed = num(v, 1); reseed(); for (var i = 0; i < rows.length; i++) { rows[i].tgt = 0; rows[i].off = 0; } roll(); }   // "roll N" recalls a draw
function dumpCmd() {
  for (var i = 0; i < rows.length; i++) { var r = rows[i]; post("out" + r.outlet, r.param, "base", BASE[r.param], "off", r.off.toFixed(3), "group", r.group, "\n"); }
}

function settings(name, a) {                                 // inlet 1
  switch (name) {
    case "row": rowCmd(a); break;
    case "param": paramCmd(a); break;
    case "group": groupCmd(a); break;
    case "knob": knobCmd(a); break;
    case "k": knobSet(a); break;
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
