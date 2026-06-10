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
      800.0,
      600.0
    ],
    "openinpresentation": 1,
    "boxes": [
      {
        "box": {
          "comment": "texture",
          "id": "obj-1",
          "index": 0,
          "maxclass": "inlet",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            30.0,
            30.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "comment": "texture",
          "id": "obj-2",
          "index": 0,
          "maxclass": "outlet",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            30.0,
            500.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-3",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 3,
          "outlettype": [
            "",
            "",
            ""
          ],
          "patching_rect": [
            200.0,
            90.0,
            215.0,
            22.0
          ],
          "text": "routepass jit_gl_texture jit_matrix"
        }
      },
      {
        "box": {
          "id": "obj-4",
          "maxclass": "newobj",
          "numinlets": 5,
          "numoutlets": 5,
          "outlettype": [
            "",
            "",
            "",
            "",
            ""
          ],
          "patching_rect": [
            200.0,
            130.0,
            182.0,
            22.0
          ],
          "text": "route dt decay injection mix_amt"
        }
      },
      {
        "box": {
          "id": "obj-5",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 2,
          "outlettype": [
            "jit_gl_texture",
            ""
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
              700.0,
              600.0
            ],
            "boxes": [
              {
                "box": {
                  "id": "gen-obj-1",
                  "maxclass": "newobj",
                  "numinlets": 0,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "patching_rect": [
                    22.0,
                    30.0,
                    28.0,
                    22.0
                  ],
                  "text": "in 1"
                }
              },
              {
                "box": {
                  "id": "gen-obj-2",
                  "maxclass": "newobj",
                  "numinlets": 0,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "patching_rect": [
                    80.0,
                    30.0,
                    28.0,
                    22.0
                  ],
                  "text": "in 2"
                }
              },
              {
                "box": {
                  "id": "gen-obj-3",
                  "maxclass": "newobj",
                  "numinlets": 0,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "patching_rect": [
                    138.0,
                    30.0,
                    28.0,
                    22.0
                  ],
                  "text": "in 3"
                }
              },
              {
                "box": {
                  "code": "Param dt(0.02);\nParam decay(0.95);\nParam injection(0.05);\nParam mix_amt(1.0);\nParam bypass(0.0);\nParam src_vecfield(0.0);\n\nuv = norm;\n\n// Vecfield: sample inline (no stored variable component access)\nfx = (sample(in2, uv).x - 0.5) * 2.0;\nfy = (sample(in2, uv).y - 0.5) * 2.0;\n\n// Suppress displacement when vecfield unconnected (src_vecfield = 0)\nconnected = step(0.5, src_vecfield);\nfx = fx * connected;\nfy = fy * connected;\n\n// Backward-displaced UV, clamped to edge\nsrc_uv = vec(clamp(uv.x - fx * dt, 0.0, 1.0), clamp(uv.y - fy * dt, 0.0, 1.0));\n\n// Advect previous frame, add source injection\nadvected = sample(in3, src_uv) * decay;\nresult = clamp(advected + sample(in1, uv) * injection, 0.0, 1.0);\n\n// Wet/dry, then bypass\nmixed = mix(sample(in1, uv), result, mix_amt);\nout1 = mix(mixed, sample(in1, uv), bypass);\n",
                  "fontface": 0,
                  "fontname": "<Monospaced>",
                  "fontsize": 12.0,
                  "id": "gen-obj-4",
                  "maxclass": "codebox",
                  "numinlets": 3,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "patching_rect": [
                    22.0,
                    80.0,
                    550.0,
                    380.0
                  ]
                }
              },
              {
                "box": {
                  "id": "gen-obj-5",
                  "maxclass": "newobj",
                  "numinlets": 1,
                  "numoutlets": 0,
                  "patching_rect": [
                    22.0,
                    490.0,
                    35.0,
                    22.0
                  ],
                  "text": "out 1"
                }
              }
            ],
            "lines": [
              {
                "patchline": {
                  "destination": [
                    "gen-obj-4",
                    0
                  ],
                  "source": [
                    "gen-obj-1",
                    0
                  ]
                }
              },
              {
                "patchline": {
                  "destination": [
                    "gen-obj-4",
                    1
                  ],
                  "source": [
                    "gen-obj-2",
                    0
                  ]
                }
              },
              {
                "patchline": {
                  "destination": [
                    "gen-obj-4",
                    2
                  ],
                  "source": [
                    "gen-obj-3",
                    0
                  ]
                }
              },
              {
                "patchline": {
                  "destination": [
                    "gen-obj-5",
                    0
                  ],
                  "source": [
                    "gen-obj-4",
                    0
                  ]
                }
              }
            ]
          },
          "patching_rect": [
            200.0,
            380.0,
            333.0,
            22.0
          ],
          "text": "jit.gl.pix vsynth @name #0_advect_pix @type char @adapt 1",
          "varname": "#0_advect_pix"
        }
      },
      {
        "box": {
          "id": "obj-50",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "jit_gl_texture",
            ""
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
              400.0,
              300.0
            ],
            "boxes": [
              {
                "box": {
                  "id": "gen-obj-1",
                  "maxclass": "newobj",
                  "numinlets": 0,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "patching_rect": [
                    22.0,
                    30.0,
                    28.0,
                    22.0
                  ],
                  "text": "in 1"
                }
              },
              {
                "box": {
                  "id": "gen-obj-2",
                  "maxclass": "newobj",
                  "numinlets": 1,
                  "numoutlets": 0,
                  "patching_rect": [
                    22.0,
                    100.0,
                    35.0,
                    22.0
                  ],
                  "text": "out 1"
                }
              }
            ],
            "lines": [
              {
                "patchline": {
                  "destination": [
                    "gen-obj-2",
                    0
                  ],
                  "source": [
                    "gen-obj-1",
                    0
                  ]
                }
              }
            ]
          },
          "patching_rect": [
            200.0,
            440.0,
            343.0,
            22.0
          ],
          "text": "jit.gl.pix vsynth @name #0_advect_pass @type char @adapt 1",
          "varname": "#0_advect_pass"
        }
      },
      {
        "box": {
          "id": "obj-6",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 4,
          "outlettype": [
            "",
            "",
            "",
            ""
          ],
          "patching_rect": [
            500.0,
            500.0,
            56.0,
            22.0
          ],
          "restore": {
            "bypass": [
              0
            ],
            "decay": [
              0.97
            ],
            "dt": [
              0.01
            ],
            "injection": [
              0.02
            ],
            "mix_amt": [
              1.0
            ]
          },
          "text": "autopattr",
          "varname": "vfadvect_autopattr"
        }
      },
      {
        "box": {
          "angle": 270.0,
          "background": 1,
          "bgcolor": [
            0.0,
            0.0,
            0.0,
            1.0
          ],
          "border": 1,
          "bordercolor": [
            0.0,
            0.03529411765,
            0.2274509804,
            1.0
          ],
          "id": "obj-9",
          "maxclass": "panel",
          "mode": 0,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            20.0,
            20.0,
            190.0,
            130.0
          ],
          "presentation": 1,
          "presentation_rect": [
            0.0,
            0.0,
            190.0,
            130.0
          ],
          "proportion": 0.5
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 12.0,
          "id": "obj-10",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            20.0,
            20.0,
            80.0,
            21.0
          ],
          "presentation": 1,
          "presentation_rect": [
            -1.5,
            0.0,
            80.0,
            21.0
          ],
          "text": "Advect"
        }
      },
      {
        "box": {
          "comment": "vecfield",
          "id": "obj-51",
          "index": 0,
          "maxclass": "inlet",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            90.0,
            30.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-52",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            90.0,
            80.0,
            80.0,
            22.0
          ],
          "text": "vs_inState"
        }
      },
      {
        "box": {
          "id": "obj-53",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            90.0,
            130.0,
            180.0,
            22.0
          ],
          "text": "prepend param src_vecfield"
        }
      },
      {
        "box": {
          "id": "obj-11",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "bang"
          ],
          "patching_rect": [
            600.0,
            50.0,
            60.0,
            22.0
          ],
          "text": "loadbang"
        }
      },
      {
        "box": {
          "id": "obj-12",
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            600.0,
            80.0,
            180.0,
            22.0
          ],
          "text": "getattr presentation_rect"
        }
      },
      {
        "box": {
          "id": "obj-13",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            600.0,
            110.0,
            80.0,
            22.0
          ],
          "save": [
            "#N",
            "thispatcher",
            ";",
            "#Q",
            "end",
            ";"
          ],
          "text": "thispatcher"
        }
      },
      {
        "box": {
          "id": "obj-14",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            600.0,
            140.0,
            60.0,
            22.0
          ],
          "text": "zl slice 2"
        }
      },
      {
        "box": {
          "id": "obj-15",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            600.0,
            170.0,
            80.0,
            22.0
          ],
          "text": "prepend tam"
        }
      },
      {
        "box": {
          "id": "obj-16",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            600.0,
            200.0,
            100.0,
            22.0
          ],
          "saved_object_attributes": {
            "filename": "moduleSize.js",
            "parameter_enable": 0
          },
          "text": "js moduleSize.js"
        }
      },
      {
        "box": {
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "id": "obj-20",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "#0_advect_pix::dt",
          "parameter_enable": 1,
          "patching_rect": [
            50.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            4.0,
            38.0,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "activedialcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_initial": [
                0.01
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "dt",
              "parameter_mmax": 0.05,
              "parameter_modmode": 3,
              "parameter_shortname": "dt",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "dt"
        }
      },
      {
        "box": {
          "attr": "dt",
          "id": "obj-21",
          "maxclass": "attrui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            50.0,
            170.0,
            127.5,
            22.0
          ]
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-22",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            50.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            -7.5,
            20.0,
            50.0,
            18.0
          ],
          "text": "dt",
          "textjustification": 1
        }
      },
      {
        "box": {
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "id": "obj-23",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "#0_advect_pix::decay",
          "parameter_enable": 1,
          "patching_rect": [
            100.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            41.0,
            38.0,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "activedialcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_initial": [
                0.97
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "decay",
              "parameter_mmax": 1.5,
              "parameter_mmin": 0.8,
              "parameter_modmode": 3,
              "parameter_shortname": "decay",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "decay"
        }
      },
      {
        "box": {
          "attr": "decay",
          "id": "obj-24",
          "maxclass": "attrui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            100.0,
            200.0,
            127.5,
            22.0
          ]
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-25",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            100.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            29.5,
            20.0,
            50.0,
            18.0
          ],
          "text": "Decay",
          "textjustification": 1
        }
      },
      {
        "box": {
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "id": "obj-26",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "#0_advect_pix::injection",
          "parameter_enable": 1,
          "patching_rect": [
            150.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            78.0,
            38.0,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "activedialcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_initial": [
                0.02
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "injection",
              "parameter_mmax": 0.2,
              "parameter_modmode": 3,
              "parameter_shortname": "injection",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "injection"
        }
      },
      {
        "box": {
          "attr": "injection",
          "id": "obj-27",
          "maxclass": "attrui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            150.0,
            230.0,
            143.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-28",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            150.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            66.5,
            20.0,
            50.0,
            18.0
          ],
          "text": "Inject",
          "textjustification": 1
        }
      },
      {
        "box": {
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "id": "obj-29",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "#0_advect_pix::mix_amt",
          "parameter_enable": 1,
          "patching_rect": [
            200.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            115.0,
            38.0,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "activedialcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_initial": [
                1.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "mix_amt",
              "parameter_mmax": 2.0,
              "parameter_modmode": 3,
              "parameter_shortname": "mix_amt",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "mix_amt"
        }
      },
      {
        "box": {
          "attr": "mix_amt",
          "id": "obj-30",
          "maxclass": "attrui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            200.0,
            260.0,
            129.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-31",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            200.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            103.5,
            20.0,
            50.0,
            18.0
          ],
          "text": "Mix",
          "textjustification": 1
        }
      },
      {
        "box": {
          "filename": "bypass_toggle.js",
          "hint": "Bypass",
          "id": "obj-32",
          "maxclass": "jsui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            168.0,
            5.0,
            18.0,
            12.0
          ],
          "presentation": 1,
          "presentation_rect": [
            168.0,
            5.0,
            18.0,
            12.0
          ],
          "valuepopuplabel": 1,
          "varname": "bypass"
        }
      },
      {
        "box": {
          "attr": "bypass",
          "id": "obj-33",
          "maxclass": "attrui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            400.0,
            60.0,
            131.0,
            22.0
          ]
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "destination": [
            "obj-3",
            0
          ],
          "source": [
            "obj-1",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-12",
            0
          ],
          "source": [
            "obj-11",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-13",
            0
          ],
          "source": [
            "obj-12",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-14",
            0
          ],
          "source": [
            "obj-13",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-15",
            0
          ],
          "source": [
            "obj-14",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-16",
            0
          ],
          "source": [
            "obj-15",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-21",
            0
          ],
          "source": [
            "obj-20",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            0
          ],
          "source": [
            "obj-21",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-24",
            0
          ],
          "source": [
            "obj-23",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            0
          ],
          "source": [
            "obj-24",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-27",
            0
          ],
          "source": [
            "obj-26",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            0
          ],
          "source": [
            "obj-27",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-30",
            0
          ],
          "source": [
            "obj-29",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-4",
            0
          ],
          "source": [
            "obj-3",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            0
          ],
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            0
          ],
          "source": [
            "obj-30",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-33",
            0
          ],
          "source": [
            "obj-32",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            0
          ],
          "source": [
            "obj-33",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-20",
            0
          ],
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-23",
            0
          ],
          "source": [
            "obj-4",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-26",
            0
          ],
          "source": [
            "obj-4",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-29",
            0
          ],
          "source": [
            "obj-4",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-2",
            0
          ],
          "order": 1,
          "source": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-50",
            0
          ],
          "order": 0,
          "source": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            2
          ],
          "source": [
            "obj-50",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-52",
            0
          ],
          "source": [
            "obj-51",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            1
          ],
          "source": [
            "obj-52",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-53",
            0
          ],
          "source": [
            "obj-52",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-5",
            0
          ],
          "source": [
            "obj-53",
            0
          ]
        }
      }
    ],
    "parameters": {
      "obj-20": [
        "dt",
        "dt",
        0
      ],
      "obj-23": [
        "decay",
        "decay",
        0
      ],
      "obj-26": [
        "injection",
        "injection",
        0
      ],
      "obj-29": [
        "mix_amt",
        "mix_amt",
        0
      ],
      "parameterbanks": {
        "0": {
          "index": 0,
          "name": "",
          "parameters": [
            "-",
            "-",
            "-",
            "-",
            "-",
            "-",
            "-",
            "-"
          ],
          "buttons": [
            "-",
            "-",
            "-",
            "-",
            "-",
            "-",
            "-",
            "-"
          ]
        }
      },
      "inherited_shortname": 1
    },
    "autosave": 0
  }
}