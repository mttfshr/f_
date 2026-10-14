{
 "patcher": {
  "fileversion": 1,
  "appversion": {
   "major": 9,
   "minor": 1,
   "revision": 4,
   "architecture": "x64",
   "modernui": 1
  },
  "rect": [
   100.0,
   100.0,
   1000.0,
   900.0
  ],
  "boxes": [
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "c0",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      20,
      560,
      20.0
     ],
     "text": "f_a_decorrelate v1 — production DSP patch (Phase 4). Built 2026-10-12 from the T7b scratch patches. Band param drives edges+geomean; mod_type AM/PM; gain/mix; tanh safety ceiling. v1 ranges: depth 0-1, tmr 0.1-4 Hz (Phase 3). Packaging (bpatcher/menu/help) is T013-T015."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-band",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      60,
      130,
      20.0
     ],
     "text": "band (1-7)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-band",
     "maxclass": "number",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      150,
      60,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-mod",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      95,
      130,
      20.0
     ],
     "text": "mod_type (0=AM 1=PM)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-mod",
     "maxclass": "number",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      150,
      95,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-depth",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      130,
      130,
      20.0
     ],
     "text": "depth (0-1)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-depth",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      130,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-tmr",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      165,
      130,
      20.0
     ],
     "text": "tmr (0.1-4 Hz)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-tmr",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      165,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-mean",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      200,
      130,
      20.0
     ],
     "text": "smr_mean (cyc/oct)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-mean",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      200,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-range",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      235,
      130,
      20.0
     ],
     "text": "smr_range"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-range",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      235,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-cyc",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      270,
      130,
      20.0
     ],
     "text": "smr_cycle (s)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-cyc",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      270,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-q",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      305,
      130,
      20.0
     ],
     "text": "q (rad)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-q",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      305,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-p",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      340,
      130,
      20.0
     ],
     "text": "p (rad)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-p",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      340,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-gain",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      375,
      130,
      20.0
     ],
     "text": "gain"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-gain",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      375,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "cp-mix",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      410,
      130,
      20.0
     ],
     "text": "mix (0-1)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "p-mix",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      410,
      60,
      23.0
     ]
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "lb",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      20,
      445,
      50,
      23
     ],
     "text": "loadbang"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m0",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 6"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m1",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 0"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m2",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m3",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m4",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 4.5"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m5",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 3."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m6",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 8."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m7",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 0."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m8",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 0."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m9",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "m10",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      470,
      60,
      23
     ],
     "text": "message 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "c-band",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      585,
      400,
      20.0
     ],
     "text": "band lookup: edges + bin geomean per band (2048/44.1k, measured in the spike)"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "coll",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 4,
     "outlettype": [
      "anything",
      "float",
      "float",
      "float"
     ],
     "patching_rect": [
      150,
      605,
      120,
      23
     ],
     "text": "coll bandtable 1"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "t-sel",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 8,
     "outlettype": [
      "bang",
      "bang",
      "bang",
      "bang",
      "bang",
      "bang",
      "bang",
      "int"
     ],
     "patching_rect": [
      150,
      630,
      100,
      23
     ],
     "text": "sel 1 2 3 4 5 6 7"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "f-lo",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      280,
      605,
      60,
      23
     ],
     "text": "flonum"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "f-hi",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      350,
      605,
      60,
      23
     ],
     "text": "flonum"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "f-gm",
     "maxclass": "flonum",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "float",
      "float"
     ],
     "patching_rect": [
      420,
      605,
      60,
      23
     ],
     "text": "flonum"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mb1",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      655,
      160,
      23
     ],
     "text": "message store 1 1000 2000 1468.6"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mb2",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      677,
      160,
      23
     ],
     "text": "message store 2 1400 2800 2070.6"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mb3",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      699,
      160,
      23
     ],
     "text": "message store 3 2000 4000 2935.9"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mb4",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      721,
      160,
      23
     ],
     "text": "message store 4 2800 5700 4169.1"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mb5",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      743,
      160,
      23
     ],
     "text": "message store 5 4000 8000 5882.7"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mb6",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      765,
      160,
      23
     ],
     "text": "message store 6 5700 11000 8200.8"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mb7",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      150,
      787,
      160,
      23
     ],
     "text": "message store 7 8000 16000 11776.4"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pfft",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      20,
      845,
      240,
      23
     ],
     "text": "pfft~ f_a_decorrelate_inner 2048 4"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "in-audio",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      20,
      815,
      40,
      23
     ],
     "text": "inlet~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "xmix",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      20,
      885,
      50,
      23
     ],
     "text": "*~ 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "dryg",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      90,
      885,
      50,
      23
     ],
     "text": "*~ 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "mixsub",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      160,
      885,
      50,
      23
     ],
     "text": "!-~ 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "sum",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      230,
      885,
      50,
      23
     ],
     "text": "+~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "tanh",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      300,
      885,
      50,
      23
     ],
     "text": "tanh~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "gainx",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      370,
      885,
      50,
      23
     ],
     "text": "*~ 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "out-audio",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      450,
      885,
      50,
      23
     ],
     "text": "outlet~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "c-out",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      945,
      480,
      20.0
     ],
     "text": "wet/dry mix (mix param), tanh safety ceiling (output bounded [-1,1] by construction per the idea file Safety section), gain trim after. pfft~ delay = win-hop = 1536 samples (35 ms) on the wet path only."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "c-sweep",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      20,
      985,
      480,
      20.0
     ],
     "text": "gain/phase curve sweeps: uzi/expr/peek~ into buffers T7a-style; AM gain curve + PM phase curve, both written every 50 ms; mod_type selects inside the inner subpatch"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "buf-g",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      20,
      1015,
      130,
      23
     ],
     "text": "buffer~ fad_gain 100"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "buf-p",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      160,
      1015,
      130,
      23
     ],
     "text": "buffer~ fad_phase 100"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "metro",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "bang",
      "bang"
     ],
     "patching_rect": [
      20,
      1045,
      60,
      23
     ],
     "text": "metro 50"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "tog",
     "maxclass": "toggle",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "int"
     ],
     "patching_rect": [
      20,
      1015,
      20,
      23
     ],
     "text": "toggle"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "t3",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 5,
     "outlettype": [
      "bang",
      "bang",
      "bang",
      "bang",
      "bang"
     ],
     "patching_rect": [
      20,
      1070,
      70,
      23
     ],
     "text": "t b b b b b"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "gen-ctrl",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      300,
      1045,
      400,
      23.0
     ],
     "text": "gen~",
     "patcher": {
      "boxes": [
       {
        "box": {
         "fontname": "Ableton Sans Light",
         "fontsize": 12.0,
         "id": "gc-in",
         "maxclass": "newobj",
         "numinlets": 1,
         "numoutlets": 1,
         "outlettype": [
          "signal"
         ],
         "patching_rect": [
          20,
          20,
          40,
          23.0
         ],
         "text": "in 1"
        }
       },
       {
        "box": {
         "fontname": "Ableton Sans Light",
         "fontsize": 12.0,
         "id": "gc-cb",
         "maxclass": "codebox",
         "numinlets": 1,
         "numoutlets": 2,
         "outlettype": [
          "signal",
          "signal"
         ],
         "patching_rect": [
          20,
          50,
          350,
          23.0
         ],
         "text": "codebox",
         "code": "// control supplier (from T7a obj-600, always-run: a processor has no\n// stimulus reset cycle). Outputs phase_base = q + tmr*t, s_env = S(t).\nParam tmr(1.0);\nParam smr_mean(4.5);\nParam smr_range(3.0);\nParam smr_cycle(8.0);\nParam q(0.0);\nParam p(0.0);\n\nHistory t(0);\ns_env = smr_mean + smr_range * sin(p + twopi * t / smr_cycle);\nphase_base = q + tmr * t;\nt = t + 1.0 / samplerate;\n\nout1 = phase_base;\nout2 = s_env;\n"
        }
       },
       {
        "box": {
         "fontname": "Ableton Sans Light",
         "fontsize": 12.0,
         "id": "gc-o1",
         "maxclass": "newobj",
         "numinlets": 1,
         "numoutlets": 1,
         "outlettype": [
          "signal"
         ],
         "patching_rect": [
          20,
          100,
          40,
          23.0
         ],
         "text": "out 1"
        }
       },
       {
        "box": {
         "fontname": "Ableton Sans Light",
         "fontsize": 12.0,
         "id": "gc-o2",
         "maxclass": "newobj",
         "numinlets": 1,
         "numoutlets": 1,
         "outlettype": [
          "signal"
         ],
         "patching_rect": [
          100,
          100,
          40,
          23.0
         ],
         "text": "out 2"
        }
       }
      ],
      "lines": [
       {
        "patchline": {
         "destination": [
          "gc-cb",
          0
         ],
         "source": [
          "gc-in",
          0
         ]
        }
       },
       {
        "patchline": {
         "destination": [
          "gc-o1",
          0
         ],
         "source": [
          "gc-cb",
          0
         ]
        }
       },
       {
        "patchline": {
         "destination": [
          "gc-o2",
          0
         ],
         "source": [
          "gc-cb",
          1
         ]
        }
       }
      ]
     }
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pre-tmr",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "anything"
     ],
     "patching_rect": [
      300,
      1020,
      90,
      23
     ],
     "text": "prepend tmr"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pre-smr_mean",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "anything"
     ],
     "patching_rect": [
      300,
      1020,
      90,
      23
     ],
     "text": "prepend smr_mean"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pre-smr_range",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "anything"
     ],
     "patching_rect": [
      300,
      1020,
      90,
      23
     ],
     "text": "prepend smr_range"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pre-smr_cycle",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "anything"
     ],
     "patching_rect": [
      300,
      1020,
      90,
      23
     ],
     "text": "prepend smr_cycle"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pre-q",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "anything"
     ],
     "patching_rect": [
      300,
      1020,
      90,
      23
     ],
     "text": "prepend q"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pre-p",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "anything"
     ],
     "patching_rect": [
      300,
      1020,
      90,
      23
     ],
     "text": "prepend p"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "snap-pb",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      300,
      1105,
      60,
      23
     ],
     "text": "snapshot~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "snap-se",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      370,
      1105,
      60,
      23
     ],
     "text": "snapshot~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "uzi-g",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 3,
     "outlettype": [
      "bang",
      "bang",
      "int"
     ],
     "patching_rect": [
      20,
      1135,
      70,
      23
     ],
     "text": "uzi 1024 0"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "uzi-p",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 3,
     "outlettype": [
      "bang",
      "bang",
      "int"
     ],
     "patching_rect": [
      160,
      1135,
      70,
      23
     ],
     "text": "uzi 1024 0"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "expr-g",
     "maxclass": "newobj",
     "numinlets": 9,
     "numoutlets": 1,
     "outlettype": [
      "float"
     ],
     "patching_rect": [
      20,
      1195,
      900,
      23
     ],
     "text": "expr 1.+($f9==0)*(($f1*44100/2048>=$f6)*($f1*44100/2048<$f7))*$f5*sin(6.283185307*($f2+(ln(($f1*44100/2048)/$f4)/ln(2))*$f3))"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "expr-p",
     "maxclass": "newobj",
     "numinlets": 9,
     "numoutlets": 1,
     "outlettype": [
      "float"
     ],
     "patching_rect": [
      20,
      1225,
      900,
      23
     ],
     "text": "expr ($f9==1)*((($f1*44100/2048)>=$f6)*(($f1*44100/2048)<$f7))*1.5707963*(1.+$f5*sin(6.283185307*($f2+(ln(($f1*44100/2048)/$f4)/ln(2))*$f3)))"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "t-ii-g",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      20,
      1165,
      40,
      23
     ],
     "text": "t i i"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pack-g",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "list"
     ],
     "patching_rect": [
      20,
      1255,
      60,
      23
     ],
     "text": "pack 0. 0."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "peek-g",
     "maxclass": "newobj",
     "numinlets": 3,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      20,
      1285,
      100,
      23
     ],
     "text": "peek~ fad_gain"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "t-ii-p",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "int",
      "int"
     ],
     "patching_rect": [
      160,
      1165,
      40,
      23
     ],
     "text": "t i i"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "pack-p",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "list"
     ],
     "patching_rect": [
      160,
      1255,
      60,
      23
     ],
     "text": "pack 0. 0."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "peek-p",
     "maxclass": "newobj",
     "numinlets": 3,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      160,
      1285,
      100,
      23
     ],
     "text": "peek~ fad_phase"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "sr-expr-g",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      700,
      1195,
      70,
      23
     ],
     "text": "message 44100."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "sr-expr-p",
     "maxclass": "message",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      700,
      1225,
      70,
      23
     ],
     "text": "message 44100."
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "destination": [
      "m0",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-band",
      0
     ],
     "source": [
      "m0",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m1",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-mod",
      0
     ],
     "source": [
      "m1",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m2",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-depth",
      0
     ],
     "source": [
      "m2",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m3",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-tmr",
      0
     ],
     "source": [
      "m3",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m4",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-mean",
      0
     ],
     "source": [
      "m4",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m5",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-range",
      0
     ],
     "source": [
      "m5",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m6",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-cyc",
      0
     ],
     "source": [
      "m6",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m7",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-q",
      0
     ],
     "source": [
      "m7",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m8",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-p",
      0
     ],
     "source": [
      "m8",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m9",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-gain",
      0
     ],
     "source": [
      "m9",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "m10",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "p-mix",
      0
     ],
     "source": [
      "m10",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "t-sel",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "t-sel",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "t-sel",
      2
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "t-sel",
      3
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "t-sel",
      4
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "t-sel",
      5
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "t-sel",
      6
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "f-lo",
      0
     ],
     "source": [
      "coll",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "f-hi",
      0
     ],
     "source": [
      "coll",
      2
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "f-gm",
      0
     ],
     "source": [
      "coll",
      3
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "t-sel",
      0
     ],
     "source": [
      "p-band",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mb1",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "mb1",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mb2",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "mb2",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mb3",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "mb3",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mb4",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "mb4",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mb5",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "mb5",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mb6",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "mb6",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mb7",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "coll",
      0
     ],
     "source": [
      "mb7",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pfft",
      0
     ],
     "source": [
      "in-audio",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "xmix",
      0
     ],
     "source": [
      "pfft",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "xmix",
      1
     ],
     "source": [
      "p-mix",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "mixsub",
      0
     ],
     "source": [
      "p-mix",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "dryg",
      0
     ],
     "source": [
      "in-audio",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "dryg",
      1
     ],
     "source": [
      "mixsub",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "sum",
      0
     ],
     "source": [
      "xmix",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "sum",
      1
     ],
     "source": [
      "dryg",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "tanh",
      0
     ],
     "source": [
      "sum",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gainx",
      0
     ],
     "source": [
      "tanh",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gainx",
      1
     ],
     "source": [
      "p-gain",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "out-audio",
      0
     ],
     "source": [
      "gainx",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "metro",
      0
     ],
     "source": [
      "tog",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "t3",
      0
     ],
     "source": [
      "metro",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pre-tmr",
      0
     ],
     "source": [
      "p-tmr",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gen-ctrl",
      0
     ],
     "source": [
      "pre-tmr",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pre-smr_mean",
      0
     ],
     "source": [
      "p-mean",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gen-ctrl",
      0
     ],
     "source": [
      "pre-smr_mean",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pre-smr_range",
      0
     ],
     "source": [
      "p-range",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gen-ctrl",
      0
     ],
     "source": [
      "pre-smr_range",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pre-smr_cycle",
      0
     ],
     "source": [
      "p-cyc",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gen-ctrl",
      0
     ],
     "source": [
      "pre-smr_cycle",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pre-q",
      0
     ],
     "source": [
      "p-q",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gen-ctrl",
      0
     ],
     "source": [
      "pre-q",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pre-p",
      0
     ],
     "source": [
      "p-p",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "gen-ctrl",
      0
     ],
     "source": [
      "pre-p",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "snap-pb",
      0
     ],
     "source": [
      "t3",
      4
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "snap-se",
      0
     ],
     "source": [
      "t3",
      3
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "snap-pb",
      0
     ],
     "source": [
      "gen-ctrl",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "snap-se",
      0
     ],
     "source": [
      "gen-ctrl",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "uzi-p",
      0
     ],
     "source": [
      "t3",
      2
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "uzi-g",
      0
     ],
     "source": [
      "t3",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "t-ii-g",
      0
     ],
     "source": [
      "uzi-g",
      2
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      0
     ],
     "source": [
      "t-ii-g",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pack-g",
      0
     ],
     "source": [
      "t-ii-g",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pack-g",
      1
     ],
     "source": [
      "expr-g",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "peek-g",
      0
     ],
     "source": [
      "pack-g",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "t-ii-p",
      0
     ],
     "source": [
      "uzi-p",
      2
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      0
     ],
     "source": [
      "t-ii-p",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pack-p",
      0
     ],
     "source": [
      "t-ii-p",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "pack-p",
      1
     ],
     "source": [
      "expr-p",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "peek-p",
      0
     ],
     "source": [
      "pack-p",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      1
     ],
     "source": [
      "snap-pb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      2
     ],
     "source": [
      "snap-se",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      3
     ],
     "source": [
      "f-gm",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      4
     ],
     "source": [
      "p-depth",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      5
     ],
     "source": [
      "f-lo",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      6
     ],
     "source": [
      "f-hi",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      7
     ],
     "source": [
      "sr-expr-g",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "sr-expr-g",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-g",
      8
     ],
     "source": [
      "p-mod",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      1
     ],
     "source": [
      "snap-pb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      2
     ],
     "source": [
      "snap-se",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      3
     ],
     "source": [
      "f-gm",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      4
     ],
     "source": [
      "p-depth",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      5
     ],
     "source": [
      "f-lo",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      6
     ],
     "source": [
      "f-hi",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      7
     ],
     "source": [
      "sr-expr-p",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "sr-expr-p",
      0
     ],
     "source": [
      "lb",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "expr-p",
      8
     ],
     "source": [
      "p-mod",
      0
     ]
    }
   }
  ]
 }
}