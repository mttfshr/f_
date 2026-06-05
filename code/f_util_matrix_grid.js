// f_util_matrix_grid.js
// jsui for f_util_matrix — param rows × source columns, scrollable
// Layout is fully dynamic — fills box width at paint time.
//
// Inlets:
//   0 — control messages:
//         params <name1> <name2> ...        — rebuild param rows
//         bypass <0|1>                      — grey out all cells
//         clear                             — zero all amounts
//         set <source_idx> <param> <amount> — set a cell programmatically
//         strip                             — enter single-row strip mode
//         focus <param_name>               — (strip mode) set focused param
//
// Outlets:
//   0 — cell change: <param> <source_idx> <amount>

outlets = 1;
inlets = 1;

autowatch = 1;

mgraphics.init();
mgraphics.relative_coords = 0;
mgraphics.autofill = 0;

var NUM_SOURCES = 3;
var SOURCE_LABELS = ["A", "B", "C"];

var params = [];
var amounts = [];
var bypass = false;

// strip mode state
var strip_mode = false;      // true when this instance is the context strip
var focused_param = null;    // null = no focus (strip shows placeholder)

// fixed layout constants
var HEADER_H  = 18;
var CELL_H    = 20;
var PAD       = 3;
var SCROLL_W  = 10;
var LABEL_FRAC = 0.42;  // label column as fraction of content width

// scroll state
var scroll_offset = 0;

// colors
var COL_BG           = [0.08, 0.08, 0.08, 1.0];
var COL_BORDER       = [0.0,  0.035, 0.227, 1.0];
var COL_HEADER_BG    = [0.12, 0.12, 0.12, 1.0];
var COL_LABEL_BG     = [0.10, 0.10, 0.10, 1.0];
var COL_CELL_BG      = [0.05, 0.05, 0.05, 1.0];
var COL_BAR_POS      = [0.3,  0.6,  1.0,  0.85];
var COL_BAR_NEG      = [1.0,  0.4,  0.2,  0.85];
var COL_TEXT         = [0.85, 0.85, 0.85, 1.0];
var COL_TEXT_DIM     = [0.35, 0.35, 0.35, 1.0];
var COL_BYPASS       = [0.0,  0.0,  0.0,  0.5];
var COL_SCROLL_BG    = [0.08, 0.08, 0.08, 1.0];
var COL_SCROLL_THUMB = [0.45, 0.45, 0.55, 1.0];
var COL_SCROLL_BORDER= [0.0,  0.035, 0.227, 1.0];

// drag state
var drag_param     = -1;
var drag_source    = -1;
var drag_start_y   = 0;
var drag_start_amt = 0.0;

// ---- layout — computed at paint/hit time from box width ----

function get_dims() {
	var w = box.rect[2] - box.rect[0];
	var h = box.rect[3] - box.rect[1];
	var needs_scroll = params.length > get_visible_rows(h);
	var content_w = needs_scroll ? w - SCROLL_W : w;
	var label_w = Math.floor(content_w * LABEL_FRAC);
	var cell_w  = Math.floor((content_w - label_w) / NUM_SOURCES);
	return {w: w, h: h, content_w: content_w, label_w: label_w, cell_w: cell_w, needs_scroll: needs_scroll};
}

function get_display_h() {
	return box.rect[3] - box.rect[1];
}

function get_visible_rows(h) {
	return Math.floor((h - HEADER_H) / CELL_H);
}

function clamp_scroll() {
	var h = get_display_h();
	var vis = get_visible_rows(h);
	var max_offset = Math.max(0, params.length - vis);
	scroll_offset = Math.max(0, Math.min(scroll_offset, max_offset));
}

function init_amounts() {
	amounts = [];
	for (var p = 0; p < params.length; p++) {
		amounts[p] = [];
		for (var s = 0; s < NUM_SOURCES; s++) {
			amounts[p][s] = 0.0;
		}
	}
	scroll_offset = 0;
}

// ---- hit test ----

function hit_cell(px, py) {
	var d = get_dims();
	if (px < d.label_w) return null;
	var s = Math.floor((px - d.label_w) / d.cell_w);
	if (s < 0 || s >= NUM_SOURCES) return null;

	if (strip_mode) {
		if (focused_param === null) return null;
		var pi = params.indexOf(focused_param);
		if (pi < 0) return null;
		return {source: s, param: pi};
	}

	// grid mode
	var vis = get_visible_rows(d.h);
	if (py < HEADER_H) return null;
	var row = Math.floor((py - HEADER_H) / CELL_H);
	if (row < 0 || row >= vis) return null;
	var p = row + scroll_offset;
	if (p < 0 || p >= params.length) return null;
	return {source: s, param: p};
}

// ---- control messages ----

function anything() {
	var msg = messagename;
	var args = arrayfromargs(arguments);
	if (msg === "params") {
		params = args;
		init_amounts();
		mgraphics.redraw();
	} else if (msg === "bypass") {
		bypass = (args[0] > 0);
		mgraphics.redraw();
	} else if (msg === "clear") {
		do_clear();
	} else if (msg === "set" && args.length >= 3) {
		var si = args[0];
		var pname = args[1];
		var amt = args[2];
		var pi = params.indexOf(String(pname));
		if (pi >= 0 && si >= 0 && si < NUM_SOURCES) {
			amounts[pi][si] = Math.max(-1.0, Math.min(1.0, amt));
			mgraphics.redraw();
		}
	} else if (msg === "strip") {
		strip_mode = true;
		mgraphics.redraw();
	} else if (msg === "focus") {
		if (!strip_mode) return;
		var name = args.length > 0 ? String(args[0]) : null;
		focused_param = (name && params.indexOf(name) >= 0) ? name : null;
		mgraphics.redraw();
	}
}

function do_clear() {
	for (var p = 0; p < params.length; p++) {
		for (var s = 0; s < NUM_SOURCES; s++) {
			if (amounts[p][s] !== 0.0) {
				amounts[p][s] = 0.0;
				outlet(0, params[p], s, 0.0);
			}
		}
	}
	mgraphics.redraw();
}

// ---- drawing ----

function draw_row(g, d, p, cy) {
	// draws one data row for param index p at vertical position cy
	// used by both grid mode and strip mode

	// label bg
	g.set_source_rgba(COL_LABEL_BG[0], COL_LABEL_BG[1], COL_LABEL_BG[2], COL_LABEL_BG[3]);
	g.rectangle(0, cy, d.label_w, CELL_H);
	g.fill();

	// label text
	var label = params[p];
	if (label.length > 12) label = label.substring(0, 11) + "~";
	g.set_source_rgba(COL_TEXT[0], COL_TEXT[1], COL_TEXT[2], COL_TEXT[3]);
	g.set_font_size(9);
	g.move_to(PAD, cy + CELL_H * 0.5 + 4);
	g.text_path(label);
	g.fill();

	// source cells
	for (var s = 0; s < NUM_SOURCES; s++) {
		var cx = d.label_w + s * d.cell_w;
		var amt = amounts[p][s];

		g.set_source_rgba(COL_CELL_BG[0], COL_CELL_BG[1], COL_CELL_BG[2], COL_CELL_BG[3]);
		g.rectangle(cx + 1, cy + 1, d.cell_w - 1, CELL_H - 1);
		g.fill();

		// source label (A/B) — small dim text top-left of cell
		g.set_source_rgba(COL_TEXT_DIM[0], COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3]);
		g.set_font_size(7);
		g.move_to(cx + PAD, cy + 7);
		g.text_path(SOURCE_LABELS[s]);
		g.fill();

		// center line
		var mid_x = cx + d.cell_w * 0.5;
		g.set_source_rgba(COL_BORDER[0], COL_BORDER[1], COL_BORDER[2], COL_BORDER[3]);
		g.set_line_width(0.5);
		g.move_to(mid_x, cy + PAD);
		g.line_to(mid_x, cy + CELL_H - PAD);
		g.stroke();

		// column separator
		g.set_source_rgba(COL_BORDER[0], COL_BORDER[1], COL_BORDER[2], COL_BORDER[3]);
		g.set_line_width(0.5);
		g.move_to(cx, cy);
		g.line_to(cx, cy + CELL_H);
		g.stroke();

		// amount bar
		if (Math.abs(amt) > 0.005) {
			var bar_col = (amt > 0) ? COL_BAR_POS : COL_BAR_NEG;
			g.set_source_rgba(bar_col[0], bar_col[1], bar_col[2], bar_col[3]);
			var bar_w = Math.abs(amt) * (d.cell_w * 0.5 - PAD - 1);
			var bar_x = (amt > 0) ? mid_x : mid_x - bar_w;
			g.rectangle(bar_x, cy + PAD + 1, bar_w, CELL_H - PAD * 2 - 2);
			g.fill();
		}

		// value label
		if (Math.abs(amt) > 0.005) {
			var val_str = amt.toFixed(2);
			g.set_source_rgba(COL_TEXT[0], COL_TEXT[1], COL_TEXT[2], COL_TEXT[3]);
			g.set_font_size(9);
			g.move_to(cx + PAD, cy + CELL_H - PAD - 1);
			g.text_path(val_str);
			g.fill();
		}
	}
}

function paint() {
	var g = mgraphics;
	var d = get_dims();

	// background
	g.set_source_rgba(COL_BG[0], COL_BG[1], COL_BG[2], COL_BG[3]);
	g.rectangle(0, 0, d.w, d.h);
	g.fill();

	if (strip_mode) {
		paint_strip(g, d);
	} else {
		paint_grid(g, d);
	}

	// bypass overlay
	if (bypass) {
		g.set_source_rgba(COL_BYPASS[0], COL_BYPASS[1], COL_BYPASS[2], COL_BYPASS[3]);
		g.rectangle(0, 0, d.w, d.h);
		g.fill();
	}
}

function paint_strip(g, d) {
	// outer border
	g.set_source_rgba(COL_BORDER[0], COL_BORDER[1], COL_BORDER[2], COL_BORDER[3]);
	g.set_line_width(1.0);
	g.rectangle(0, 0, d.w, d.h);
	g.stroke();

	if (focused_param === null) {
		// placeholder — no focus yet
		g.set_source_rgba(COL_TEXT_DIM[0], COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3]);
		g.set_font_size(9);
		g.move_to(PAD + 2, d.h * 0.5 + 4);
		g.text_path("— no focus —");
		g.fill();
		return;
	}

	var pi = params.indexOf(focused_param);
	if (pi < 0) return;

	draw_row(g, d, pi, 0);

	// outer border on top
	g.set_source_rgba(COL_BORDER[0], COL_BORDER[1], COL_BORDER[2], COL_BORDER[3]);
	g.set_line_width(1.0);
	g.rectangle(0, 0, d.w, d.h);
	g.stroke();
}

function paint_grid(g, d) {
	var vis = get_visible_rows(d.h);

	if (params.length === 0) {
		g.set_source_rgba(COL_TEXT_DIM[0], COL_TEXT_DIM[1], COL_TEXT_DIM[2], COL_TEXT_DIM[3]);
		g.set_font_size(10);
		g.move_to(8, d.h * 0.5 + 5);
		g.text_path("no params");
		g.fill();
		return;
	}

	// header row
	g.set_source_rgba(COL_HEADER_BG[0], COL_HEADER_BG[1], COL_HEADER_BG[2], COL_HEADER_BG[3]);
	g.rectangle(0, 0, d.content_w, HEADER_H);
	g.fill();

	// source labels in header + column separators
	g.set_font_size(10);
	for (var s = 0; s < NUM_SOURCES; s++) {
		var cx = d.label_w + s * d.cell_w;
		g.set_source_rgba(COL_TEXT[0], COL_TEXT[1], COL_TEXT[2], COL_TEXT[3]);
		g.move_to(cx + d.cell_w * 0.5 - 4, HEADER_H - 5);
		g.text_path(SOURCE_LABELS[s]);
		g.fill();

		g.set_source_rgba(COL_BORDER[0], COL_BORDER[1], COL_BORDER[2], COL_BORDER[3]);
		g.set_line_width(0.5);
		g.move_to(cx, 0);
		g.line_to(cx, d.h);
		g.stroke();
	}

	// label column header bg
	g.set_source_rgba(COL_LABEL_BG[0], COL_LABEL_BG[1], COL_LABEL_BG[2], COL_LABEL_BG[3]);
	g.rectangle(0, 0, d.label_w, HEADER_H);
	g.fill();

	// param rows
	for (var row = 0; row < vis; row++) {
		var p = row + scroll_offset;
		if (p >= params.length) break;
		var cy = HEADER_H + row * CELL_H;

		// row separator
		g.set_source_rgba(COL_BORDER[0], COL_BORDER[1], COL_BORDER[2], COL_BORDER[3]);
		g.set_line_width(0.5);
		g.move_to(0, cy);
		g.line_to(d.content_w, cy);
		g.stroke();

		draw_row(g, d, p, cy);
	}

	// outer border
	g.set_source_rgba(COL_BORDER[0], COL_BORDER[1], COL_BORDER[2], COL_BORDER[3]);
	g.set_line_width(1.0);
	g.rectangle(0, 0, d.content_w, d.h);
	g.stroke();

	// scrollbar
	if (d.needs_scroll) {
		var sb_x = d.content_w;
		var sb_h = d.h - HEADER_H;
		var max_offset = params.length - vis;

		g.set_source_rgba(COL_SCROLL_BG[0], COL_SCROLL_BG[1], COL_SCROLL_BG[2], COL_SCROLL_BG[3]);
		g.rectangle(sb_x, HEADER_H, SCROLL_W, sb_h);
		g.fill();

		g.set_source_rgba(COL_SCROLL_BORDER[0], COL_SCROLL_BORDER[1], COL_SCROLL_BORDER[2], COL_SCROLL_BORDER[3]);
		g.set_line_width(0.5);
		g.rectangle(sb_x, HEADER_H, SCROLL_W, sb_h);
		g.stroke();

		var thumb_h = Math.max(20, sb_h * (vis / params.length));
		var thumb_range = sb_h - thumb_h;
		var thumb_y = HEADER_H + (max_offset > 0 ? (scroll_offset / max_offset) * thumb_range : 0);
		g.set_source_rgba(COL_SCROLL_THUMB[0], COL_SCROLL_THUMB[1], COL_SCROLL_THUMB[2], COL_SCROLL_THUMB[3]);
		g.rectangle(sb_x + 2, thumb_y + 2, SCROLL_W - 4, thumb_h - 4);
		g.fill();
	}
}

// ---- mouse ----

function onclick(x, y, but, cmd, shift, capslock, opt, ctrl) {
	if (bypass) return;
	var cell = hit_cell(x, y);
	if (!cell) return;
	drag_param     = cell.param;
	drag_source    = cell.source;
	drag_start_y   = y;
	drag_start_amt = amounts[cell.param][cell.source];
}

function ondrag(x, y, but, cmd, shift, capslock, opt, ctrl) {
	if (bypass || drag_param < 0) return;
	var scale = shift ? 0.001 : 0.01;
	var new_amt = drag_start_amt - (y - drag_start_y) * scale;
	new_amt = Math.max(-1.0, Math.min(1.0, new_amt));
	amounts[drag_param][drag_source] = new_amt;
	outlet(0, params[drag_param], drag_source, new_amt);

	if (Math.abs(new_amt) > 0.005) {
		for (var s = 0; s < NUM_SOURCES; s++) {
			if (s !== drag_source && Math.abs(amounts[drag_param][s]) > 0.005) {
				amounts[drag_param][s] = 0.0;
				outlet(0, params[drag_param], s, 0.0);
			}
		}
	}
	mgraphics.redraw();
}

function onmouseup(x, y, but, cmd, shift, capslock, opt, ctrl) {
	drag_param  = -1;
	drag_source = -1;
}

function ondblclick(x, y, but, cmd, shift, capslock, opt, ctrl) {
	if (bypass) return;
	var cell = hit_cell(x, y);
	if (!cell) return;
	amounts[cell.param][cell.source] = 0.0;
	outlet(0, params[cell.param], cell.source, 0.0);
	mgraphics.redraw();
}

function onwheel(x, y, wheel_x, wheel_y, modifiers) {
	if (params.length === 0) return;
	scroll_offset += (wheel_y > 0) ? 1 : -1;
	clamp_scroll();
	mgraphics.redraw();
}
