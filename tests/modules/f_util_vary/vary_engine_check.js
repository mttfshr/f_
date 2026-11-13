// node vary_engine_check.js : offline check of package/javascript/f_util_vary.js with a tiny Max-js shim (T001).
var fs = require("fs"), vm = require("vm"), path = require("path"), assert = require("assert");
function load() {
  var out = [], posts = [];
  var ctx = {outlet: function () { out.push(Array.prototype.slice.call(arguments)); }, post: function () { posts.push(Array.prototype.slice.call(arguments).join(" ")); },
             arrayfromargs: function (x) { return Array.prototype.slice.call(x); }, Date: Date, Math: Math, inlet: 0, messagename: ""};
  vm.createContext(ctx);
  vm.runInContext(fs.readFileSync(path.join(__dirname, "../../../package/javascript/f_util_vary.js"), "utf8"), ctx);
  ctx.out = out; ctx.posts = posts;
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
assert.deepStrictEqual(a.out, b.out, "same seed, same draw");
var v17 = lastv(a, 0, "x"); a.set("seed", 18); assert.notStrictEqual(lastv(a, 0, "x"), v17); a.set("seed", 17); assert.strictEqual(lastv(a, 0, "x"), v17, "roll 17 recalls");

// 4. clamp; no emit from a row before its base; amount 0 returns the base
c = load(); c.row(1, "v", 0, 1, 100, 100); c.set("roll"); assert.strictEqual(c.out.length, 0, "no emit before a base");
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
console.log("ok");
