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
   600.0,
   400.0
  ],
  "boxes": [
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i1",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "outlettype": [
      "signal",
      "signal",
      "signal"
     ],
     "patching_rect": [
      20,
      20,
      62,
      23
     ],
     "text": "fftin~ 1"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i3",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      150,
      20,
      90,
      23
     ],
     "text": "index~ fad_gain"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i5",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      150,
      60,
      90,
      23
     ],
     "text": "index~ fad_phase"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i4",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      20,
      60,
      62,
      23
     ],
     "text": "cartopol~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i6",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      20,
      100,
      62,
      23
     ],
     "text": "*~ 1."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i7",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "signal"
     ],
     "patching_rect": [
      20,
      140,
      62,
      23
     ],
     "text": "+~ 0."
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i8",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "signal",
      "signal"
     ],
     "patching_rect": [
      20,
      180,
      62,
      23
     ],
     "text": "poltocar~"
    }
   },
   {
    "box": {
     "fontname": "Ableton Sans Light",
     "fontsize": 12.0,
     "id": "i9",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 0,
     "outlettype": [],
     "patching_rect": [
      20,
      220,
      62,
      23
     ],
     "text": "fftout~ 1"
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "destination": [
      "i4",
      0
     ],
     "source": [
      "i1",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i4",
      1
     ],
     "source": [
      "i1",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i3",
      0
     ],
     "source": [
      "i1",
      2
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i5",
      0
     ],
     "source": [
      "i1",
      2
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i6",
      0
     ],
     "source": [
      "i4",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i6",
      1
     ],
     "source": [
      "i3",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i7",
      0
     ],
     "source": [
      "i4",
      1
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i7",
      1
     ],
     "source": [
      "i5",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i8",
      0
     ],
     "source": [
      "i6",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i8",
      1
     ],
     "source": [
      "i7",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i9",
      0
     ],
     "source": [
      "i8",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "i9",
      1
     ],
     "source": [
      "i8",
      1
     ]
    }
   }
  ]
 }
}