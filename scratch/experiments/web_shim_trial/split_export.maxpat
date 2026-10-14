{
 "fileversion": 1,
 "appversion": {
  "major": 9,
  "minor": 2,
  "revision": 0,
  "architecture": "x64",
  "modernui": 1
 },
 "patcher": {
  "boxes": [
   {
    "box": {
     "maxclass": "newobj",
     "text": "loadbang",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      40.0,
      20.0,
      50.0,
      22.0
     ],
     "id": "loadbang"
    }
   },
   {
    "box": {
     "maxclass": "newobj",
     "text": "delay 500",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      40.0,
      60.0,
      60.0,
      22.0
     ],
     "id": "delay1"
    }
   },
   {
    "box": {
     "maxclass": "jit.gl.pix",
     "text": "jit.gl.pix foo @gen split_export @exportfolder /Users/matt/Github/f_/scratch/experiments/web_shim_trial/_exports",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "jit_matrix",
      ""
     ],
     "patching_rect": [
      40.0,
      100.0,
      400.0,
      22.0
     ],
     "id": "pix"
    }
   },
   {
    "box": {
     "maxclass": "message",
     "text": "exportcode webgl",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      40.0,
      140.0,
      120.0,
      22.0
     ],
     "id": "send_webgl"
    }
   },
   {
    "box": {
     "maxclass": "newobj",
     "text": "delay 2000",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      40.0,
      180.0,
      60.0,
      22.0
     ],
     "id": "delay2"
    }
   },
   {
    "box": {
     "maxclass": "message",
     "text": "exportcode isf",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      40.0,
      220.0,
      120.0,
      22.0
     ],
     "id": "send_isf"
    }
   },
   {
    "box": {
     "maxclass": "newobj",
     "text": "delay 2000",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      40.0,
      260.0,
      60.0,
      22.0
     ],
     "id": "delay3"
    }
   },
   {
    "box": {
     "maxclass": "message",
     "text": "close",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      40.0,
      300.0,
      60.0,
      22.0
     ],
     "id": "close_msg"
    }
   },
   {
    "box": {
     "maxclass": "newobj",
     "text": "thispatcher",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "bang",
      ""
     ],
     "patching_rect": [
      40.0,
      330.0,
      70.0,
      22.0
     ],
     "id": "closer"
    }
   },
   {
    "box": {
     "maxclass": "newobj",
     "text": "print split_export",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      300.0,
      250.0,
      60.0,
      22.0
     ],
     "id": "out_print"
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "source": [
      "loadbang",
      0
     ],
     "destination": [
      "delay1",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "delay1",
      0
     ],
     "destination": [
      "pix",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "delay1",
      0
     ],
     "destination": [
      "send_webgl",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "send_webgl",
      0
     ],
     "destination": [
      "pix",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "delay1",
      0
     ],
     "destination": [
      "delay2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "delay2",
      0
     ],
     "destination": [
      "send_isf",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "send_isf",
      0
     ],
     "destination": [
      "pix",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "delay2",
      0
     ],
     "destination": [
      "delay3",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "delay3",
      0
     ],
     "destination": [
      "close_msg",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "close_msg",
      0
     ],
     "destination": [
      "closer",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "pix",
      1
     ],
     "destination": [
      "out_print",
      0
     ]
    }
   }
  ],
  "params": []
 }
}