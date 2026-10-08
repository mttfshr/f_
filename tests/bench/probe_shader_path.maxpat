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
    "classnamespace": "box",
    "rect": [
      100.0,
      100.0,
      520.0,
      360.0
    ],
    "boxes": [
      {
        "box": {
          "id": "in0",
          "maxclass": "inlet",
          "patching_rect": [
            20.0,
            20.0,
            30.0,
            22.0
          ],
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "o0",
          "maxclass": "outlet",
          "patching_rect": [
            20.0,
            300.0,
            30.0,
            22.0
          ],
          "numinlets": 1,
          "numoutlets": 0
        }
      },
      {
        "box": {
          "id": "shA",
          "maxclass": "newobj",
          "text": "jit.gl.shader vsynth @name #0.probe_a @file f_caustic_sheets_probe.jxs",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            20.0,
            100.0,
            420.0,
            22.0
          ],
          "outlettype": [
            "",
            ""
          ]
        }
      },
      {
        "box": {
          "id": "shB",
          "maxclass": "newobj",
          "text": "jit.gl.shader vsynth @name #0.probe_b @file probe_nonexistent_control.jxs",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            20.0,
            140.0,
            420.0,
            22.0
          ],
          "outlettype": [
            "",
            ""
          ]
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "source": [
            "in0",
            0
          ],
          "destination": [
            "o0",
            0
          ]
        }
      }
    ]
  }
}