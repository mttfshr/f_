// type_dots.js
// The two type dots left of a module's name (2026-10-17).
//
// jsarguments: <takes> <outputs>, each "vec", "tensor" or "none".
//   top shape    = the type the module takes
//   bottom shape = the type the module outputs
//   vec    = filled inverted triangle, cyan   (the nabla in the title-bar label)
//   tensor = filled disc,              amber  (an ellipse)
//   none   = filled square,            dim gray
// Shape AND color carry the type, so the dots still read without color vision.
// Size intended: 7 x 14 px in presentation mode (two 5 px shapes, 2 px apart, 1 px margin all round).
// Generated into every patcher by build/build_patcher.py (type_dots_box); edit the look here.

autowatch = 1;
inlets  = 1;
outlets = 0;

mgraphics.init();
mgraphics.relative_coords = 0;

var COLORS = {
    vec:    [0.35, 0.75, 0.95, 1.0],
    tensor: [0.85, 0.55, 0.20, 1.0],
    none:   [0.28, 0.28, 0.28, 1.0]
};

function kind_of(a) {
    var s = (a === undefined || a === null) ? "none" : String(a).toLowerCase();
    return (s == "vec" || s == "tensor") ? s : "none";
}

// jsarguments[0] is the script's own name; the module's two arguments follow.
var takes   = kind_of(jsarguments[1]);
var outputs = kind_of(jsarguments[2]);

function shape(kind, x, y, s) {
    var c = COLORS[kind];
    mgraphics.set_source_rgba(c[0], c[1], c[2], c[3]);
    mgraphics.new_path();                      // a fresh path: no stray line from an earlier shape
    if (kind == "vec") {                       // inverted triangle: flat top, point down
        mgraphics.move_to(x, y);
        mgraphics.line_to(x + s, y);
        mgraphics.line_to(x + s / 2.0, y + s);
        mgraphics.close_path();
    } else if (kind == "tensor") {             // disc
        mgraphics.move_to(x + s, y + s / 2.0);     // start ON the circle so arc() adds no line
        mgraphics.arc(x + s / 2.0, y + s / 2.0, s / 2.0, 0, 6.2831853);
        mgraphics.close_path();
    } else {                                   // none: square
        mgraphics.rectangle(x, y, s, s);
    }
    mgraphics.fill();
}

// Fixed geometry, NOT derived from the box: Max can give a jsui a larger box than the patcher asks for (the first
// version sized the shapes from the box width and they came out ~9 px and overlapped).  Drawn from the box's
// top-left corner, so a larger box only means extra transparent space.
var SIZE = 5.0;
var GAP  = 2.0;
var PAD  = 1.0;   // transparent margin inside the box: the first look showed the disc's top-left shaved, as if the
                  // drawing area lost ~1 px at the box edge, so no shape touches the edge

function paint() {
    shape(takes,   PAD, PAD,                SIZE);   // top
    shape(outputs, PAD, PAD + SIZE + GAP,   SIZE);   // bottom
}
