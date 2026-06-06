// hue_range.js
autowatch = 1;
inlets  = 2;
outlets = 3;

var low  = 84.0;
var high = 156.0;

function msg_float(v) {
    if (inlet == 0) low  = v;
    if (inlet == 1) high = v;
    calc();
}

msg_int = msg_float;

function calc() {
    var center = (low + high) / 2.0;
    var lower  = center - low;
    var upper  = high - center;
    outlet(2, upper);
    outlet(1, lower);
    outlet(0, center);
}

calc();