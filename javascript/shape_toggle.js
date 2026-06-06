// shape_toggle.js
// Neutral mode selector for two output shape choices.
// state=1: circle (masked output)   thumb on right, circle glyph
// state=0: full (unmasked output)   thumb on left, square glyph
// Both states are valid — no warning color.
// Size intended: 18 x 12px in presentation mode.

autowatch = 1;
inlets  = 1;
outlets = 1;

var state    = 1;   // 1 = circle, 0 = full
var hovering = 0;

mgraphics.init();
mgraphics.relative_coords = 0;

// --- Parameter support ---
function getvalueof() {
    return state;
}

function setvalueof(v) {
    state = (v != 0) ? 1 : 0;
    mgraphics.redraw();
}

// --- Drawing ---
function paint() {
    var w = box.rect[2] - box.rect[0];
    var h = box.rect[3] - box.rect[1];
    var r = h / 2.0;

    // Track: neutral gray for both states
    mgraphics.set_source_rgba(0.32, 0.32, 0.32, 1.0);
    rounded_rect(0, 0, w, h, r);
    mgraphics.fill();

    // Thumb position: left = full, right = circle
    var thumb_x = (state == 1) ? (w - r) : r;
    var thumb_y = h / 2.0;
    var thumb_r = r - 1.5;

    mgraphics.set_source_rgba(1.0, 1.0, 1.0, 0.92);

    if (state == 1) {
        // Circle glyph
        mgraphics.arc(thumb_x, thumb_y, thumb_r, 0, 6.2831853);
        mgraphics.fill();
    } else {
        // Square glyph
        var s = thumb_r * 1.3;
        mgraphics.rectangle(thumb_x - s / 2.0, thumb_y - s / 2.0, s, s);
        mgraphics.fill();
    }

    // Hover label above widget
    if (hovering) {
        var label = (state == 1) ? "circle" : "full";
        mgraphics.select_font_face("Arial");
        mgraphics.set_font_size(9);
        var pill_w = 32.0;
        var pill_h = 12.0;
        var pill_x = (w - pill_w) / 2.0;
        var pill_y = -(pill_h + 2.0);
        mgraphics.set_source_rgba(0.08, 0.08, 0.08, 0.82);
        rounded_rect(pill_x, pill_y, pill_w, pill_h, 3.0);
        mgraphics.fill();
        mgraphics.set_source_rgba(1.0, 1.0, 1.0, 0.9);
        mgraphics.move_to(pill_x + 4.0, pill_y + pill_h - 3.0);
        mgraphics.show_text(label);
    }
}

// --- Interaction ---
function onclick(x, y, but, cmd, shift, capslock, option, ctrl) {
    state = (state == 0) ? 1 : 0;
    outlet(0, state);
    mgraphics.redraw();
}

function onmouseenter(x, y, but, cmd, shift, capslock, option, ctrl) {
    hovering = 1;
    mgraphics.redraw();
}

function onmouseleave(x, y, but, cmd, shift, capslock, option, ctrl) {
    hovering = 0;
    mgraphics.redraw();
}

// Inlet: set state and output
function msg_int(v) {
    state = (v != 0) ? 1 : 0;
    outlet(0, state);
    mgraphics.redraw();
}

function msg_float(v) {
    state = (v != 0) ? 1 : 0;
    outlet(0, state);
    mgraphics.redraw();
}

// --- Helpers ---
function rounded_rect(x, y, w, h, r) {
    mgraphics.move_to(x + r, y);
    mgraphics.line_to(x + w - r, y);
    mgraphics.arc(x + w - r, y + r, r, -1.5707963, 0);
    mgraphics.line_to(x + w, y + h - r);
    mgraphics.arc(x + w - r, y + h - r, r, 0, 1.5707963);
    mgraphics.line_to(x + r, y + h);
    mgraphics.arc(x + r, y + h - r, r, 1.5707963, 3.1415927);
    mgraphics.line_to(x, y + r);
    mgraphics.arc(x + r, y + r, r, 3.1415927, 4.7123890);
    mgraphics.close_path();
}
