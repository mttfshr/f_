// f_util_mod_handler.js
//
// Consumer-side mod message handler for f_util_matrix.
//
// Receives mod assignments from the matrix on inlet 0:
//   <param> <source_idx> <amount>   e.g. "mortar 0 0.6"
//   source_idx 0 → param_mod_amt_a
//   source_idx 1 → param_mod_amt_b
//
// Receives base values from dials on inlet 1, via prepend:
//   <param> <base_value>            e.g. "mortar 0.4"
//   Wire each dial outlet → [prepend <paramname>] → js inlet 1
//
// On mod assignment: stores amount, outputs mod param to pix:
//   param mortar_mod_amt_a 0.6
//
// On base value: outputs base param to pix:
//   param mortar 0.4
//
// Codebox convention per modulatable param:
//   Param foo;
//   Param foo_mod_amt_a;
//   Param foo_mod_amt_b;
//   float foo_eff = foo + a_sample * foo_mod_amt_a + b_sample * foo_mod_amt_b;
//
// Inlets:
//   0 — mod assignments from matrix: <param> <source_idx> <amount>
//   1 — base values from dials, prepended with param name: <param> <value>
//
// Outlets:
//   0 — param messages to pix in0
//   1 — echo: set <source_idx> <param> <amount>  (to keep grid and strip in sync)

outlets = 2;
inlets = 2;

// amounts[paramName][source_idx] = amount
var amounts = {};

function anything() {
	var param = messagename;
	var args = arrayfromargs(arguments);

	if (inlet === 0) {
		// mod assignment: <param> <source_idx> <amount>
		if (args.length < 2) return;
		var src = args[0];  // 0 = a, 1 = b
		var amount = args[1];
		var suffix = (src === 0) ? "_mod_amt_a" : "_mod_amt_b";

		if (!amounts[param]) amounts[param] = {};
		amounts[param][src] = amount;

		outlet(0, "param", param + suffix, amount);
		outlet(1, "set", src, param, amount);

	} else if (inlet === 1) {
		// base value: <param> <value>
		if (args.length < 1) return;
		outlet(0, "param", param, args[0]);
	}
}

// Clear all stored amounts and zero all mod params
function clear() {
	for (var p in amounts) {
		for (var src in amounts[p]) {
			var suffix = (parseInt(src) === 0) ? "_mod_amt_a" : "_mod_amt_b";
			outlet(0, "param", p + suffix, 0.0);
		}
	}
	amounts = {};
}

// Dump current state to Max console
function dump() {
	for (var p in amounts) {
		for (var src in amounts[p]) {
			var suffix = (parseInt(src) === 0) ? "_mod_amt_a" : "_mod_amt_b";
			post(p + suffix + " = " + amounts[p][src] + "\n");
		}
	}
}
