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
          "id": "in1",
          "maxclass": "inlet",
          "patching_rect": [
            200.0,
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
          "id": "o1",
          "maxclass": "outlet",
          "patching_rect": [
            200.0,
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
          "id": "px",
          "maxclass": "newobj",
          "text": "jit.gl.pix vsynth @type float32",
          "numinlets": 2,
          "numoutlets": 3,
          "outlettype": [
            "jit_gl_texture",
            "jit_gl_texture",
            ""
          ],
          "patching_rect": [
            20.0,
            120.0,
            260.0,
            22.0
          ],
          "patcher": {
            "fileversion": 1,
            "appversion": {
              "major": 9,
              "minor": 1,
              "revision": 4,
              "architecture": "x64",
              "modernui": 1
            },
            "classnamespace": "jit.gen",
            "rect": [
              100.0,
              100.0,
              520.0,
              320.0
            ],
            "boxes": [
              {
                "box": {
                  "maxclass": "newobj",
                  "numinlets": 0,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "text": "in 1",
                  "id": "gen-obj-1",
                  "patching_rect": [
                    150.0,
                    30.0,
                    110.0,
                    22.0
                  ]
                }
              },
              {
                "box": {
                  "maxclass": "newobj",
                  "numinlets": 0,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "text": "in 2",
                  "id": "gen-obj-2",
                  "patching_rect": [
                    30.0,
                    90.0,
                    110.0,
                    22.0
                  ]
                }
              },
              {
                "box": {
                  "maxclass": "codebox",
                  "code": "out1 = vec(sample(in2, norm).x, sample(in2, norm).y, sample(in2, norm).z, sample(in2, norm).w);\nout2 = vec(sample(in1, norm).x, sample(in1, norm).y, sample(in1, norm).z, sample(in1, norm).w);\n",
                  "numinlets": 2,
                  "numoutlets": 2,
                  "outlettype": [
                    "",
                    ""
                  ],
                  "fontname": "<Monospaced>",
                  "fontsize": 12.0,
                  "id": "gen-obj-3",
                  "patching_rect": [
                    150.0,
                    90.0,
                    110.0,
                    22.0
                  ]
                }
              },
              {
                "box": {
                  "maxclass": "newobj",
                  "numinlets": 1,
                  "numoutlets": 0,
                  "text": "out 1",
                  "id": "gen-obj-4",
                  "patching_rect": [
                    30.0,
                    150.0,
                    110.0,
                    22.0
                  ]
                }
              },
              {
                "box": {
                  "maxclass": "newobj",
                  "numinlets": 1,
                  "numoutlets": 0,
                  "text": "out 2",
                  "id": "gen-obj-5",
                  "patching_rect": [
                    150.0,
                    150.0,
                    110.0,
                    22.0
                  ]
                }
              }
            ],
            "lines": [
              {
                "patchline": {
                  "source": [
                    "gen-obj-1",
                    0
                  ],
                  "destination": [
                    "gen-obj-3",
                    0
                  ]
                }
              },
              {
                "patchline": {
                  "source": [
                    "gen-obj-2",
                    0
                  ],
                  "destination": [
                    "gen-obj-3",
                    1
                  ]
                }
              },
              {
                "patchline": {
                  "source": [
                    "gen-obj-3",
                    0
                  ],
                  "destination": [
                    "gen-obj-4",
                    0
                  ]
                }
              },
              {
                "patchline": {
                  "source": [
                    "gen-obj-3",
                    1
                  ],
                  "destination": [
                    "gen-obj-5",
                    0
                  ]
                }
              }
            ]
          }
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
            "px",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "in1",
            0
          ],
          "destination": [
            "px",
            1
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "px",
            0
          ],
          "destination": [
            "o0",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "px",
            1
          ],
          "destination": [
            "o1",
            0
          ]
        }
      }
    ]
  }
}