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
      760.0,
      560.0
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
            400.0,
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
          "id": "out0",
          "maxclass": "outlet",
          "patching_rect": [
            620.0,
            520.0,
            30.0,
            22.0
          ],
          "numinlets": 1,
          "numoutlets": 0
        }
      },
      {
        "box": {
          "id": "rt",
          "maxclass": "newobj",
          "text": "route d weight psize n fy r bypass k h snap jit latn taps",
          "numinlets": 1,
          "numoutlets": 14,
          "patching_rect": [
            20.0,
            60.0,
            540.0,
            22.0
          ],
          "outlettype": [
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
          ]
        }
      },
      {
        "box": {
          "id": "slabS",
          "maxclass": "newobj",
          "text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            20.0,
            110.0,
            300.0,
            22.0
          ],
          "outlettype": [
            "jit_gl_texture",
            ""
          ]
        }
      },
      {
        "box": {
          "id": "slabF",
          "maxclass": "newobj",
          "text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            400.0,
            110.0,
            300.0,
            22.0
          ],
          "outlettype": [
            "jit_gl_texture",
            ""
          ]
        }
      },
      {
        "box": {
          "id": "rtS",
          "maxclass": "newobj",
          "text": "route out_name",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            20.0,
            160.0,
            100.0,
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
          "id": "rtF",
          "maxclass": "newobj",
          "text": "route out_name",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            400.0,
            160.0,
            100.0,
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
          "id": "join",
          "maxclass": "newobj",
          "text": "join",
          "numinlets": 2,
          "numoutlets": 1,
          "patching_rect": [
            20.0,
            200.0,
            60.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepTex",
          "maxclass": "newobj",
          "text": "prepend texture",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            20.0,
            240.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "rdraw",
          "maxclass": "newobj",
          "text": "r draw",
          "numinlets": 0,
          "numoutlets": 1,
          "patching_rect": [
            180.0,
            60.0,
            50.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "getname",
          "maxclass": "message",
          "text": "getout_name",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            180.0,
            90.0,
            90.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "node",
          "maxclass": "newobj",
          "text": "jit.gl.node vsynth @capture 1 @name #0.node @type float32 @adapt 0 @dim 256 256 @erase_color 0 0 0 0",
          "numinlets": 1,
          "numoutlets": 3,
          "patching_rect": [
            400.0,
            300.0,
            330.0,
            22.0
          ],
          "outlettype": [
            "jit_gl_texture",
            "",
            ""
          ]
        }
      },
      {
        "box": {
          "id": "shader",
          "maxclass": "newobj",
          "text": "jit.gl.shader vsynth @name #0.sc @file spike_scatter.jxs",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            20.0,
            300.0,
            270.0,
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
          "id": "grid",
          "maxclass": "newobj",
          "text": "jit.gl.gridshape vsynth @shape plane @dim 256 256 @matrixoutput 1 @automatic 0",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            20.0,
            400.0,
            400.0,
            22.0
          ],
          "outlettype": [
            "jit_matrix",
            ""
          ]
        }
      },
      {
        "box": {
          "id": "mesh",
          "maxclass": "newobj",
          "text": "jit.gl.mesh #0.node @draw_mode points @shader #0.sc @blend_enable 1 @blend_mode 1 1 @depth_enable 0 @point_size 3 @color 1 1 1 1 @lighting_enable 0",
          "numinlets": 1,
          "numoutlets": 2,
          "patching_rect": [
            20.0,
            440.0,
            560.0,
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
          "id": "lb",
          "maxclass": "newobj",
          "text": "loadbang",
          "numinlets": 0,
          "numoutlets": 1,
          "patching_rect": [
            440.0,
            360.0,
            60.0,
            22.0
          ],
          "outlettype": [
            "bang"
          ]
        }
      },
      {
        "box": {
          "id": "firstbang",
          "maxclass": "message",
          "text": "bang",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            440.0,
            390.0,
            40.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "prepD",
          "maxclass": "newobj",
          "text": "prepend param d",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            20.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepW",
          "maxclass": "newobj",
          "text": "prepend param weight",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            140.0,
            350.0,
            140.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepP",
          "maxclass": "newobj",
          "text": "prepend point_size",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            290.0,
            350.0,
            120.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepY",
          "maxclass": "newobj",
          "text": "prepend param fy",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            560.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "dimn",
          "maxclass": "message",
          "text": "dim $1 $1, bang",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            420.0,
            320.0,
            110.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "prepR",
          "maxclass": "newobj",
          "text": "prepend param res",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            680.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "dimr",
          "maxclass": "message",
          "text": "dim $1 $1",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            680.0,
            320.0,
            70.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "prepH",
          "maxclass": "newobj",
          "text": "prepend param h",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            800.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepSn",
          "maxclass": "newobj",
          "text": "prepend param snap",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            920.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepJ",
          "maxclass": "newobj",
          "text": "prepend param jit",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            1040.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepLn",
          "maxclass": "newobj",
          "text": "prepend param latn",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            1160.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "prepTp",
          "maxclass": "newobj",
          "text": "prepend param taps",
          "numinlets": 1,
          "numoutlets": 1,
          "patching_rect": [
            1280.0,
            350.0,
            110.0,
            22.0
          ],
          "outlettype": [
            ""
          ]
        }
      },
      {
        "box": {
          "id": "note",
          "maxclass": "comment",
          "text": "scatter spike: see tests/spike_scatter.py. d weight psize n via inlet 0; inlet 0 texture = source, inlet 1 = f_vecfield.",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            20.0,
            460.0,
            560.0,
            20.0
          ]
        }
      },
      {
        "box": {
          "id": "tone",
          "maxclass": "newobj",
          "text": "jit.gl.pix vsynth @type float32 @adapt 0 @dim 1920 1080",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "jit_gl_texture",
            ""
          ],
          "patching_rect": [
            700.0,
            440.0,
            300.0,
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
              500.0,
              300.0
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
                    30.0,
                    90.0,
                    200.0,
                    22.0
                  ]
                }
              },
              {
                "box": {
                  "maxclass": "codebox",
                  "code": "tm(v, ex) {\n\tt = v / (1.0 + v);\n\treturn pow(t, ex);\n}\nParam lev(1.0);\nParam expo(0.7);\nr = tm(sample(in1, norm).x * lev, expo);\ng = tm(sample(in1, norm).y * lev, expo);\nb = tm(sample(in1, norm).z * lev, expo);\nout1 = vec(r, g, b, 1.0);\n",
                  "numinlets": 1,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "fontname": "<Monospaced>",
                  "fontsize": 12.0,
                  "id": "gen-obj-2",
                  "patching_rect": [
                    30.0,
                    150.0,
                    200.0,
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
                  "id": "gen-obj-3",
                  "patching_rect": [
                    30.0,
                    210.0,
                    200.0,
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
                    "gen-obj-2",
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
                    0
                  ]
                }
              }
            ]
          }
        }
      },
      {
        "box": {
          "id": "tone2",
          "maxclass": "newobj",
          "text": "jit.gl.pix vsynth @type float32",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "jit_gl_texture",
            ""
          ],
          "patching_rect": [
            700.0,
            480.0,
            300.0,
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
              500.0,
              300.0
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
                    30.0,
                    90.0,
                    200.0,
                    22.0
                  ]
                }
              },
              {
                "box": {
                  "maxclass": "codebox",
                  "code": "tm(v, ex) {\n\tt = v / (1.0 + v);\n\treturn pow(t, ex);\n}\nParam lev(1.0);\nParam expo(0.7);\nr = tm(sample(in1, norm).x * lev, expo);\ng = tm(sample(in1, norm).y * lev, expo);\nb = tm(sample(in1, norm).z * lev, expo);\nout1 = vec(r, g, b, 1.0);\n",
                  "numinlets": 1,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "fontname": "<Monospaced>",
                  "fontsize": 12.0,
                  "id": "gen-obj-2",
                  "patching_rect": [
                    30.0,
                    150.0,
                    200.0,
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
                  "id": "gen-obj-3",
                  "patching_rect": [
                    30.0,
                    210.0,
                    200.0,
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
                    "gen-obj-2",
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
                    0
                  ]
                }
              }
            ]
          }
        }
      },
      {
        "box": {
          "id": "out1",
          "maxclass": "outlet",
          "patching_rect": [
            660.0,
            560.0,
            30.0,
            22.0
          ],
          "numinlets": 1,
          "numoutlets": 0
        }
      },
      {
        "box": {
          "id": "out2",
          "maxclass": "outlet",
          "patching_rect": [
            700.0,
            560.0,
            30.0,
            22.0
          ],
          "numinlets": 1,
          "numoutlets": 0
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
            "rt",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            13
          ],
          "destination": [
            "slabS",
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
            "slabF",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "slabS",
            1
          ],
          "destination": [
            "rtS",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "slabF",
            1
          ],
          "destination": [
            "rtF",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rtS",
            0
          ],
          "destination": [
            "join",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rtF",
            0
          ],
          "destination": [
            "join",
            1
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "join",
            0
          ],
          "destination": [
            "prepTex",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rdraw",
            0
          ],
          "destination": [
            "getname",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "getname",
            0
          ],
          "destination": [
            "slabS",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "getname",
            0
          ],
          "destination": [
            "slabF",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "lb",
            0
          ],
          "destination": [
            "firstbang",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "firstbang",
            0
          ],
          "destination": [
            "grid",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "grid",
            0
          ],
          "destination": [
            "mesh",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepTex",
            0
          ],
          "destination": [
            "mesh",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "node",
            0
          ],
          "destination": [
            "out0",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            0
          ],
          "destination": [
            "prepD",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            1
          ],
          "destination": [
            "prepW",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            2
          ],
          "destination": [
            "prepP",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            3
          ],
          "destination": [
            "dimn",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            4
          ],
          "destination": [
            "prepY",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            5
          ],
          "destination": [
            "prepR",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            5
          ],
          "destination": [
            "dimr",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepR",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "dimr",
            0
          ],
          "destination": [
            "node",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepD",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepW",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepY",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepP",
            0
          ],
          "destination": [
            "mesh",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "dimn",
            0
          ],
          "destination": [
            "grid",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            8
          ],
          "destination": [
            "prepH",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepH",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            9
          ],
          "destination": [
            "prepSn",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepSn",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            10
          ],
          "destination": [
            "prepJ",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            11
          ],
          "destination": [
            "prepLn",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepJ",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepLn",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "rt",
            12
          ],
          "destination": [
            "prepTp",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prepTp",
            0
          ],
          "destination": [
            "shader",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "node",
            0
          ],
          "destination": [
            "tone",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "node",
            0
          ],
          "destination": [
            "tone2",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "tone",
            0
          ],
          "destination": [
            "out1",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "tone2",
            0
          ],
          "destination": [
            "out2",
            0
          ]
        }
      }
    ]
  }
}