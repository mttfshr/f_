// node vary_engine_check.js : offline check of package/javascript/f_util_vary.js with a tiny Max-js shim (T001).
var fs = require("fs"), vm = require("vm"), path = require("path"), assert = require("assert");
function load() {
  var out = [], posts = [];
  var ctx = {outlet: function () { out.push(Array.prototype.slice.call(arguments)); }, post: function () { posts.push(Array.prototype.slice.call(arguments).join(" ")); },
             arrayfromargs: function (x) { return Array.prototype.slice.call(x); }, Date: Date, Math: Math, inlet: 0, messagename: ""};
  vm.createContext(ctx);
  vm.runInContext(fs.readFileSync(path.join(__dirname, "../../../package/javascript/f_util_vary.js"), "utf8"), ctx);
  ctx.out = out; ctx.posts = posts; ctx.have = {}; ctx.removed = [];
  ctx.patcher = {getnamed: function (n) { return ctx.have[n] ? {n: n} : null; }, remove: function (o) { ctx.removed.push(o.n); delete ctx.have[o.n]; }};
  ctx.base = function (n) { ctx.inlet = 0; ctx.messagename = n; ctx.anything.apply(ctx, Array.prototype.slice.call(arguments, 1)); };
  ctx.set = function (n) { ctx.inlet = 1; ctx.messagename = n; ctx.anything.apply(ctx, Array.prototype.slice.call(arguments, 1)); };
  ctx.row = function () { ctx.set.apply(ctx, ["row"].concat(Array.prototype.slice.call(arguments))); };
  return ctx;
}
var on = function (c, o, name) { return c.out.filter(function (m) { return m[0] == o && m[1] == name; }); };
var lastv = function (c, o, name) { var m = on(c, o, name); return m[m.length - 1][2]; };

// 1. an empty table is a transparent wire: every base goes out of every outlet unchanged
var c = load(); c.base("x", 0.25);
assert.deepStrictEqual(c.out, [[0, "x", 0.25], [1, "x", 0.25], [2, "x", 0.25], [3, "x", 0.25]], "passthrough to every outlet");
c.out.length = 0; c.base("hue", 0.1, 0.2); assert.deepStrictEqual(c.out[0], [0, "hue", 0.1, 0.2], "a list passes through whole");

// 2. a row on outlet 2 varies only outlet 2; the others still get the plain base
c = load(); c.row(2, "x", -1, 1, 50, 100); c.base("x", 0); c.out.length = 0; c.set("seed", 17);
assert(on(c, 1, "x").length >= 1 && Math.abs(lastv(c, 1, "x")) > 0, "outlet 2 varied");
c.out.length = 0; c.base("x", 0.3);
assert.strictEqual(on(c, 0, "x")[0][2], 0.3, "outlet 1 plain"); assert.strictEqual(on(c, 2, "x")[0][2], 0.3, "outlet 3 plain"); assert.strictEqual(on(c, 3, "x")[0][2], 0.3, "outlet 4 plain");
assert.notStrictEqual(on(c, 1, "x")[0][2], 0.3, "outlet 2 not plain");

// 3. determinism and recall: the same seed gives the same draw
var a = load(), b = load();
[a, b].forEach(function (k) { k.row(1, "x", -1, 1, 50, 100, 0, "g"); k.row(2, "x", -1, 1, 50, 100, 0, "g"); k.base("x", 0); k.set("seed", 17); });
assert.strictEqual(JSON.stringify(a.out), JSON.stringify(b.out), "same seed, same draw");
var v17 = lastv(a, 0, "x"); a.set("seed", 18); assert.notStrictEqual(lastv(a, 0, "x"), v17); a.set("seed", 17); assert.strictEqual(lastv(a, 0, "x"), v17, "roll 17 recalls");

// 4. clamp; no emit from a row before its base; amount 0 returns the base
c = load(); c.row(1, "v", 0, 1, 100, 100); c.set("roll"); assert.strictEqual(c.out.filter(function (m) { return m[0] < 4; }).length, 0, "no emit before a base");
c.base("v", 0.99); for (var i = 0; i < 50; i++) { c.set("roll"); var e = lastv(c, 0, "v"); assert(e >= 0 && e <= 1, "clamped"); }
c.set("amount", 0); assert.strictEqual(lastv(c, 0, "v"), 0.99, "amount 0 -> base");

// 5. correlation across outlets: corr 1 gives the same offset, corr 0 does not
c = load(); c.set("group", "g", 1); c.row(1, "x", -1, 1, 50, 100, 0, "g"); c.row(2, "x", -1, 1, 50, 100, 0, "g"); c.base("x", 0); c.set("roll");
assert(Math.abs(lastv(c, 0, "x") - lastv(c, 1, "x")) < 1e-12, "corr 1 -> same offset");
c.set("group", "g", 0); c.set("roll"); assert(Math.abs(lastv(c, 0, "x") - lastv(c, 1, "x")) > 1e-6, "corr 0 -> different");

// 6. chance 0 holds; sign up never below the base; drunk is bounded but moves; trim shifts by a share of the range
c = load(); c.row(1, "z", -1, 1, 100, 0); c.base("z", 0.2); for (i = 0; i < 20; i++) c.set("roll"); assert(on(c, 0, "z").every(function (m) { return m[2] == 0.2; }), "chance 0 holds");
c = load(); c.row(1, "u", -1, 1, 100, 100, 0, "-", 0, "u", "up"); c.base("u", 0); for (i = 0; i < 50; i++) { c.set("roll"); assert(lastv(c, 0, "u") >= 0, "sign up"); }
c = load(); c.row(1, "w", -1, 1, 100, 100, 0, "-", 0, "d", "bi"); c.base("w", 0); var mx = 0; for (i = 0; i < 500; i++) { c.set("roll"); mx = Math.max(mx, Math.abs(lastv(c, 0, "w"))); } assert(mx <= 1 && mx > 0.2, "drunk bounded but moving");
c = load(); c.row(1, "t", 0, 1, 0, 100, 0, "-", 25); c.base("t", 0.5); c.set("roll"); assert(Math.abs(lastv(c, 0, "t") - 0.75) < 1e-9, "trim 25% of range");

// 7. param range defaults, with - in a row
c = load(); c.set("param", "x", -0.1, 0.1); c.row(1, "x", "-", "-", 100, 100); c.base("x", 0); for (i = 0; i < 30; i++) c.set("roll");
assert(Math.max.apply(null, on(c, 0, "x").map(function (m) { return Math.abs(m[2]); })) <= 0.1 + 1e-12, "range from param default");

// 8. per-row wobble: only rows with wobble > 0 drift, and the roll draws do not change with wobble
c = load(); c.row(1, "a", 0, 1, 0, 100, 20); c.row(2, "a", 0, 1, 0, 100, 0); c.base("a", 0.5); for (i = 0; i < 40; i++) c.set("tick");
assert(on(c, 0, "a").length > 2 && on(c, 0, "a").some(function (m) { return Math.abs(m[2] - 0.5) > 1e-4; }), "row with wobble drifts");
assert(on(c, 1, "a").every(function (m) { return m[2] == 0.5; }), "row without wobble holds");
var w0 = load(), w1 = load(); [w0, w1].forEach(function (k) { k.row(1, "r", -1, 1, 50, 100, 0); k.base("r", 0); }); w1.row(1, "r", -1, 1, 50, 100, 30);
w1.set("seed", 3); for (i = 0; i < 20; i++) w1.set("tick"); w0.set("seed", 3); w1.set("seed", 3); // a seed reset zeroes the offsets in both
assert.strictEqual(lastv(w0, 0, "r"), lastv(w1, 0, "r"), "wobble ticks do not change the draw (separate stream)");

// 9. collisions: a base named like a setting is just a base on inlet 0; the same word on inlet 1 is the setting
c = load(); c.base("amount", 0.4); c.base("roll", 0.7); c.base("value", 1); assert.strictEqual(c.out.length, 12, "settings names on inlet 0 pass through"); assert.strictEqual(on(c, 0, "roll")[0][2], 0.7);
c.row(1, "x", -1, 1, 100, 100); c.base("x", 0); c.set("roll"); c.set("amount", 0); assert.strictEqual(lastv(c, 0, "x"), 0, "amount on inlet 1 is the setting");

// 10. re-applying a table keeps the bases (clear, then rows, then refresh)
c = load(); c.base("x", 0.4); c.set("clear"); c.row(3, "x", 0, 1, 100, 100); c.out.length = 0; c.set("refresh");
assert.strictEqual(on(c, 0, "x")[0][2], 0.4, "refresh sends the plain base to outlets without a row"); assert.strictEqual(on(c, 2, "x").length, 1, "and the row's outlet gets its value");

// 11. bad rows are reported, not added
c = load(); c.row(9, "x"); c.row(0, "x"); assert(c.posts.length == 2, "two bad rows reported"); c.base("x", 1); assert.strictEqual(c.out.length, 4, "still a plain wire");

// 12. a blank row from `add` gets a row UI; its param is picked from the names seen; edits come back as `cell <i> <field> <value>`
var sc = function (c) { return c.out.filter(function (m) { return m[0] == 7 && m[1] == "script"; }); };
var ui = function (c) { return c.out.filter(function (m) { return m[0] == 8; }); };
c = load(); c.set("token", "T9"); c.set("add");
assert.strictEqual(sc(c).filter(function (m) { return m[2] == "newobject"; }).length, 1, "one bpatcher scripted for the new row");
assert.strictEqual(sc(c).filter(function (m) { return m[2] == "connect"; }).length, 1, "and one cord scripted (engine to row; the row answers by send)");
assert(sc(c)[0].indexOf("T9") > 0, "the instance token is in the row args");
assert(sc(c)[0].indexOf("vr1") > 0 && sc(c)[0].indexOf("f_util_vary_row.maxpat") > 0, "named vr1, from f_util_vary_row.maxpat");
c.base("x", 0); assert(ui(c).some(function (m) { return m[1] == 1 && m[2] == "names" && m[3] == "x"; }), "a base name is offered to the row's menu");
c.out.length = 0; c.base("x", 0); assert.strictEqual(on(c, 0, "x").length, 1, "a row with no param yet is a plain wire");
c.out.length = 0; c.set("add"); assert(ui(c).some(function (m) { return m[1] == 2 && m[2] == "names" && m[3] == "x"; }), "a row added after the names were seen is given them");
c.set("cell", 1, "param", "x"); c.set("cell", 1, "amt", 100); c.set("cell", 1, "lo", -1); c.set("cell", 1, "hi", 1); c.set("roll");
assert(Math.abs(lastv(c, 0, "x")) > 0, "the row works once its param is chosen"); assert(ui(c).some(function (m) { return m[1] == 1 && m[2] == "param_idx" && m[3] == 0; }), "param index pushed back");

// a row made by `add` (or edited by a cell) rolls and ticks without error, wobble included
c = load(); c.set("add"); c.set("cell", 1, "wob", 50); np = c.posts.length; c.set("roll"); c.set("tick"); c.set("cell", 1, "param", "x"); c.base("x", 0.5); c.set("roll"); c.set("tick"); assert.strictEqual(c.posts.length, np, "no error from a row made by add");

// no range set: unclamped, and the variation scales with the base (a base of 3 varies; a base of 0 uses 1)
c = load(); c.row(1, "q", "-", "-", 20, 100); c.base("q", 3); c.set("seed", 5); assert(lastv(c, 0, "q") != 3 && Math.abs(lastv(c, 0, "q") - 3) <= 0.6 + 1e-9, "unset range scales with the base");
c.base("q", 0); c.set("seed", 6); assert(lastv(c, 0, "q") != 0 && Math.abs(lastv(c, 0, "q")) <= 0.2 + 1e-9, "a base of 0 uses a range of 1");

// 13. a table line arriving as a list led by a symbol is the same as the message
c = load(); c.ctxlist = true; c.inlet = 1; c.messagename = "list"; c.anything("row", 2, "x", 0, 1, 10, 100); c.base("x", 0.5); assert(on(c, 1, "x").length == 1 && on(c, 0, "x").length == 1, "list-led row accepted");

// 14. monitor and label outlets
c = load(); c.row(1, "x", 0, 1, 50, 100); c.row(2, "y", 0, 1, 50, 100); assert(c.out.some(function (m) { return m[0] == 5 && m[1] == "set" && m[2] == "o1.x o2.y"; }), "labels");
c.base("x", 0.5); c.base("y", 0.5); var mon = c.out.filter(function (m) { return m[0] == 4; }); assert(mon.length > 0 && mon[mon.length - 1][1].length == 2, "monitor list has one value per row");
// 15. cell edits: amount 0 stops the variation; a bad outlet or a duplicate is refused and the row repushed; group numbers become g1..g4; del removes the row
c = load(); c.row(1, "x", -1, 1, 50, 100, 0, "-", 0, "u", "bi"); c.base("x", 0); c.set("cell", 1, "amt", 0); c.set("roll"); assert.strictEqual(lastv(c, 0, "x"), 0, "amount 0");
c.set("cell", 1, "amt", 100); c.set("roll"); assert(Math.abs(lastv(c, 0, "x")) > 0, "and back up");
c.out.length = 0; var np = c.posts.length; c.set("cell", 1, "out", 9); assert(c.posts.length > np && ui(c).some(function (m) { return m[2] == "out" && m[3] == 1; }), "bad outlet refused, row repushed");
c.set("add"); c.set("cell", 2, "param", "x"); np = c.posts.length; c.set("cell", 2, "param", "x"); c.set("cell", 2, "out", 1); assert(c.posts.length > np, "duplicate outlet + param refused");
c.out.length = 0; c.set("cell", 1, "group", 2); assert(c.out.some(function (m) { return m[0] == 9 && m[1] == "g2"; }), "group dial pushed"); assert(ui(c).some(function (m) { return m[2] == "group" && m[3] == 2; }), "group number pushed back");
c.have = {vr1: 1, vr2: 1}; c.out.length = 0; c.set("cell", 1, "del", 1); assert.strictEqual(on(c, 0, "x")[0][2], 0, "after del the outlet is a plain wire again"); assert.deepStrictEqual(c.removed, ["vr2"], "the last row UI removed");
// a group made on the group dials correlates rows
c = load(); c.set("group", "g1", 0.8); c.row(1, "x", -1, 1, 50, 100, 0, "g1"); c.row(2, "x", -1, 1, 50, 100, 0, "g1"); c.base("x", 0); c.set("roll");
assert(Math.abs(lastv(c, 0, "x") - lastv(c, 1, "x")) < 0.3 * 0.5 * 2 + 1e-9 && lastv(c, 0, "x") != lastv(c, 1, "x"), "corr 0.8 correlates the rows");
// refresh removes any saved row UIs (an embedded patch keeps them) and builds them again from the table
c = load(); c.have = {vr1: 1, vr2: 1, vr3: 1}; c.row(1, "x"); c.removed.length = 0; c.out.length = 0; c.set("refresh");
assert.deepStrictEqual(c.removed.slice().sort(), ["vr1", "vr2", "vr3"], "saved row UIs removed"); assert.strictEqual(sc(c).filter(function (m) { return m[2] == "newobject"; }).length, 1, "one rebuilt from the table");

// 16. persistence: the table is stored as one `restore ...` list for a pattr, and restoring it rebuilds the same table
c = load(); c.set("param", "x", -1, 1); c.set("group", "g", 0.9); c.row(1, "x", "-", "-", 30, 80, 5, "g", 10, "d", "up"); c.set("add");
var stores = c.out.filter(function (m) { return m[0] == 6; }); var saved = stores[stores.length - 1].slice(1);
assert.strictEqual(saved[0], "restore"); var d2 = load(); d2.set.apply(d2, ["restore"].concat(saved.slice(1)));
var again = d2.out.filter(function (m) { return m[0] == 6; });
assert.strictEqual(again.length, 0, "restoring does not store again (no echo loop)");
d2.base("x", 0); d2.set("roll"); assert(on(d2, 0, "x").length >= 1, "the restored row is live");
d2.set("restore", ...saved.slice(1)); assert.strictEqual(d2.out.filter(function (m) { return m[0] == 6; }).length, 0, "the echo of an unchanged table is ignored");
var e = load(); e.inlet = 1; e.messagename = "list"; e.anything.apply(e, saved); assert(e.out.length > 0, "a list-led restore from the pattr is accepted");
assert(saved.indexOf("|") > 0 && saved.indexOf("group") >= 0 && saved.indexOf("row") >= 0 && saved.indexOf("param") >= 0, "everything is in the stored list");
assert.strictEqual(saved.filter(function (t) { return t == "row"; }).length, 1, "a blank row (no param yet) is not stored");
// the strip values (amount, chance, wobble, slew, seed) are part of the stored table and are pushed to their dials on a restore
c = load(); c.set("amount", 0.5); c.set("chance", 0.3); c.set("wobble", 0.2); c.set("slew", 120); c.set("seed", 9);
stores = c.out.filter(function (m) { return m[0] == 6; }); saved = stores[stores.length - 1].slice(1);
assert.deepStrictEqual(saved.slice(0, 8), ["restore", "globals", 0.5, 0.3, 0.2, 120, 9, "|"], "the strip values are in the stored list");
d2 = load(); d2.set.apply(d2, ["restore"].concat(saved.slice(1)));
["amount", 0.5, "chance", 0.3, "wobble", 0.2, "slew", 120, "seed", 9].forEach(function (v, i, a) { if (i % 2 == 0) assert(d2.out.some(function (m) { return m[0] == 9 && m[1] == v && m[2] == a[i + 1]; }), "dial " + v + " pushed on restore"); });
console.log("ok");
