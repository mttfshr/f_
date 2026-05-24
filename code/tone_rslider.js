// tone_rslider.js
// Luminance range selector for tone_curve bpatcher.
// Same as luma_rslider.js but draws S/M/H region labels to indicate
// that all three bands are active — not a single selection window.
// out0 = low_mid, out1 = mid_high (both 0.0–1.0)
autowatch = 1;
inlets  = 3;   // 0 = set_low, 1 = set_high (suppress output), 2 = edge_falloff
outlets = 2;   // 0 = low_mid, 1 = mid_high

var low  = 0.33;
var high = 0.66;
var edge_falloff = 0.1;
var min_val = 0.0;
var max_val = 1.0;
var handle_px = 8;

var dragging = "none";
var drag_offset_low  = 0.0;
var drag_offset_high = 0.0;

mgraphics.init();
mgraphics.relative_coords = 0;

function smoothstep_js(edge0, edge1, x) {
    var t = Math.min(Math.max((x - edge0) / (edge1 - edge0), 0.0), 1.0);
    return t * t * (3.0 - 2.0 * t);
}

function paint() {
    var w = box.rect[2] - box.rect[0];
    var h = box.rect[3] - box.rect[1];

    var low_x  = val_to_x(low,  w);
    var high_x = val_to_x(high, w);
    var cx     = (low_x + high_x) / 2.0;

    // background
    mgraphics.set_source_rgba(0.15, 0.15, 0.15, 1.0);
    mgraphics.rectangle(0, 0, w, h);
    mgraphics.fill();

    // greyscale gradient strip — smoothstep dimming mirrors Gen codebox band weights
    var ef = edge_falloff;
    for (var i = 0; i < w; i++) {
        var brightness = i / w;
        var lum_val = i / w;
        var sw_w = 1.0 - smoothstep_js(low - ef, low + ef, lum_val);
        var hw_w = smoothstep_js(high - ef, high + ef, lum_val);
        var mw_w = Math.max(1.0 - sw_w - hw_w, 0.0);
        var dimmed = 0.3 + 0.7 * mw_w;
        mgraphics.set_source_rgba(brightness * dimmed, brightness * dimmed, brightness * dimmed, 1.0);
        mgraphics.move_to(i, 0);
        mgraphics.line_to(i, h);
        mgraphics.stroke();
    }

    // band overlay tint
    mgraphics.set_source_rgba(1.0, 1.0, 1.0, 0.08);
    mgraphics.rectangle(low_x, 0, high_x - low_x, h);
    mgraphics.fill();

    // low handle
    mgraphics.set_source_rgba(1.0, 1.0, 1.0, 1.0);
    mgraphics.move_to(low_x, 0);
    mgraphics.line_to(low_x, h);
    mgraphics.stroke();

    // high handle
    mgraphics.move_to(high_x, 0);
    mgraphics.line_to(high_x, h);
    mgraphics.stroke();

    // center marker
    mgraphics.set_source_rgba(1.0, 1.0, 1.0, 0.4);
    mgraphics.move_to(cx, 0);
    mgraphics.line_to(cx, h);
    mgraphics.stroke();

    // S / M / H region labels
    mgraphics.select_font_face("Arial");
    mgraphics.set_font_size(8);
    mgraphics.set_source_rgba(1.0, 1.0, 1.0, 0.5);

    var label_y = h / 2.0 + 3.0;  // vertically centered

    // S — center of shadow region
    var s_cx = low_x / 2.0;
    if (s_cx > 4.0) {
        mgraphics.move_to(s_cx - 3.0, label_y);
        mgraphics.show_text("S");
    }

    // M — center of midtone region
    var m_cx = (low_x + high_x) / 2.0;
    mgraphics.move_to(m_cx - 3.5, label_y);
    mgraphics.show_text("M");

    // H — center of highlight region
    var h_cx = (high_x + w) / 2.0;
    if (h_cx < w - 4.0) {
        mgraphics.move_to(h_cx - 3.0, label_y);
        mgraphics.show_text("H");
    }

    // value label — shown while dragging (replaces region labels during interaction)
    if (dragging != "none") {
        var label_str, label_x;
        if (dragging == "low") {
            label_str = low.toFixed(2);
            label_x   = low_x;
        } else if (dragging == "high") {
            label_str = high.toFixed(2);
            label_x   = high_x;
        } else {
            label_str = ((low + high) / 2.0).toFixed(2);
            label_x   = cx;
        }

        mgraphics.select_font_face("Arial");
        mgraphics.set_font_size(9);

        var pill_w  = 24.0;
        var pill_h  = 13.0;
        var pill_x  = Math.min(Math.max(label_x - pill_w / 2.0, 1.0), w - pill_w - 1.0);
        var pill_y  = (h - pill_h) / 2.0;

        mgraphics.set_source_rgba(0.0, 0.0, 0.0, 0.75);
        mgraphics.rectangle(pill_x, pill_y, pill_w, pill_h);
        mgraphics.fill();

        mgraphics.set_source_rgba(1.0, 1.0, 1.0, 1.0);
        mgraphics.move_to(pill_x + 3.0, pill_y + pill_h - 3.0);
        mgraphics.show_text(label_str);
    }
}

// Inlet handlers
function msg_float(v) {
    if (inlet == 0) {
        low = Math.min(Math.max(v, min_val), high - 0.01);
        mgraphics.redraw();
    } else if (inlet == 1) {
        high = Math.max(Math.min(v, max_val), low + 0.01);
        mgraphics.redraw();
    } else if (inlet == 2) {
        edge_falloff = Math.min(Math.max(v, 0.0), 0.5);
        mgraphics.redraw();
    }
}

function msg_int(v) {
    msg_float(v);
}

function onclick(x, y, but, cmd, shift, capslock, option, ctrl) {
    var w      = box.rect[2] - box.rect[0];
    var low_x  = val_to_x(low,  w);
    var high_x = val_to_x(high, w);

    if (Math.abs(x - low_x) <= handle_px) {
        dragging = "low";
    } else if (Math.abs(x - high_x) <= handle_px) {
        dragging = "high";
    } else if (x > low_x && x < high_x) {
        dragging = "band";
        drag_offset_low  = x - low_x;
        drag_offset_high = high_x - x;
    } else {
        dragging = "none";
    }
}

function ondrag(x, y, but, cmd, shift, capslock, option, ctrl) {
    var w        = box.rect[2] - box.rect[0];
    var val      = x_to_val(x, w);
    var span, new_low, new_high;

    if (dragging == "low") {
        low = Math.min(Math.max(val, min_val), high - 0.01);
    } else if (dragging == "high") {
        high = Math.max(Math.min(val, max_val), low + 0.01);
    } else if (dragging == "band") {
        span     = high - low;
        new_low  = x_to_val(x - drag_offset_low,  w);
        new_high = x_to_val(x + drag_offset_high, w);
        if (new_low  < min_val) { new_low = min_val;  new_high = min_val  + span; }
        if (new_high > max_val) { new_high = max_val; new_low  = max_val  - span; }
        low  = new_low;
        high = new_high;
    }

    output();
    mgraphics.redraw();
}

function onmouseup(x, y, but, cmd, shift, capslock, option, ctrl) {
    dragging = "none";
    mgraphics.redraw();
}

function output() {
    outlet(1, high);
    outlet(0, low);
}

function val_to_x(val, w) {
    return (val - min_val) / (max_val - min_val) * w;
}

function x_to_val(x, w) {
    return Math.min(Math.max(x / w * (max_val - min_val) + min_val, min_val), max_val);
}
