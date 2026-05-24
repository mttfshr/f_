// hue_rslider.js
autowatch = 1;
inlets  = 3;   // 0 = set_low, 1 = set_high, 2 = edge_falloff (all suppress output)
outlets = 2;

var low  = 84.0;
var high = 156.0;
var min_val = 0.0;
var max_val = 360.0;
var handle_px = 8;
var edge_falloff = 0.0;

var dragging = "none";
var drag_offset_low  = 0.0;
var drag_offset_high = 0.0;

mgraphics.init();
mgraphics.relative_coords = 0;

function paint() {
    var w = box.rect[2] - box.rect[0];
    var h = box.rect[3] - box.rect[1];

    var low_x      = val_to_x(low,  w);
    var high_x     = val_to_x(high, w);
    var cx         = (low_x + high_x) / 2.0;
    var falloff_px = (edge_falloff / (max_val - min_val)) * w;

    // background
    mgraphics.set_source_rgba(0.15, 0.15, 0.15, 1.0);
    mgraphics.rectangle(0, 0, w, h);
    mgraphics.fill();

    // hue spectrum strip — binary dimming replaced with smooth falloff shoulders
    for (var i = 0; i < w; i++) {
        var hue = i / w;
        var rgb = hsv_to_rgb(hue, 1.0, 1.0);
        var dimmed;

        if (i >= low_x && i <= high_x) {
            // inside flat-top band
            dimmed = 1.0;
        } else if (falloff_px > 0.0 && i >= low_x - falloff_px && i < low_x) {
            // left shoulder: ramp 0.25 → 1.0
            dimmed = 0.25 + 0.75 * ((i - (low_x - falloff_px)) / falloff_px);
        } else if (falloff_px > 0.0 && i > high_x && i <= high_x + falloff_px) {
            // right shoulder: ramp 1.0 → 0.25
            dimmed = 1.0 - 0.75 * ((i - high_x) / falloff_px);
        } else {
            dimmed = 0.25;
        }

        mgraphics.set_source_rgba(rgb[0] * dimmed, rgb[1] * dimmed, rgb[2] * dimmed, 1.0);
        mgraphics.move_to(i, 0);
        mgraphics.line_to(i, h);
        mgraphics.stroke();
    }

    // band overlay tint
    mgraphics.set_source_rgba(1.0, 1.0, 1.0, 0.1);
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
    mgraphics.set_source_rgba(1.0, 1.0, 1.0, 0.5);
    mgraphics.move_to(cx, 0);
    mgraphics.line_to(cx, h);
    mgraphics.stroke();

    // degree label — only shown while dragging, one at a time, with pill background
    if (dragging != "none") {
        var label_str, label_x;
        if (dragging == "low") {
            label_str = Math.round(low)  + "\xB0";
            label_x   = low_x;
        } else if (dragging == "high") {
            label_str = Math.round(high) + "\xB0";
            label_x   = high_x;
        } else {
            // band drag: show center value above center marker
            label_str = Math.round((low + high) / 2.0) + "\xB0";
            label_x   = cx;
        }

        mgraphics.select_font_face("Arial");
        mgraphics.set_font_size(9);

        var pill_w  = 24.0;
        var pill_h  = 13.0;
        var pill_x  = Math.min(Math.max(label_x - pill_w / 2.0, 1.0), w - pill_w - 1.0);
        var pill_y  = (h - pill_h) / 2.0;

        // dark pill
        mgraphics.set_source_rgba(0.0, 0.0, 0.0, 0.75);
        mgraphics.rectangle(pill_x, pill_y, pill_w, pill_h);
        mgraphics.fill();

        // white text centered in pill
        mgraphics.set_source_rgba(1.0, 1.0, 1.0, 1.0);
        mgraphics.move_to(pill_x + 3.0, pill_y + pill_h - 3.0);
        mgraphics.show_text(label_str);
    }
}

// Inlet handlers — intentionally no output() call, so numbox → jsui doesn't loop back
function msg_float(v) {
    if (inlet == 0) {
        low = Math.min(Math.max(v, min_val), high - 1.0);
        mgraphics.redraw();
    } else if (inlet == 1) {
        high = Math.max(Math.min(v, max_val), low + 1.0);
        mgraphics.redraw();
    } else if (inlet == 2) {
        edge_falloff = Math.min(Math.max(v, 0.0), 180.0);
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
    var w   = box.rect[2] - box.rect[0];
    var val = x_to_val(x, w);
    var span, new_low, new_high;

    if (dragging == "low") {
        low = Math.min(Math.max(val, min_val), high - 1.0);
    } else if (dragging == "high") {
        high = Math.max(Math.min(val, max_val), low + 1.0);
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
}

function output() {
    outlet(1, high);
    outlet(0, low);
}

function val_to_x(val, w) {
    return (val - min_val) / (max_val - min_val) * w;
}

function x_to_val(x, w) {
    return Math.min(Math.max((x / w) * (max_val - min_val) + min_val, min_val), max_val);
}

function hsv_to_rgb(h, s, v) {
    var h6 = h * 6.0;
    var r  = Math.min(Math.max(Math.abs(h6 - 3.0) - 1.0, 0.0), 1.0);
    var g  = Math.min(Math.max(2.0 - Math.abs(h6 - 2.0), 0.0), 1.0);
    var b  = Math.min(Math.max(2.0 - Math.abs(h6 - 4.0), 0.0), 1.0);
    return [
        v * (1.0 - s + s * r),
        v * (1.0 - s + s * g),
        v * (1.0 - s + s * b)
    ];
}