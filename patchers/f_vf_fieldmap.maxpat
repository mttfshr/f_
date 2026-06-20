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
          "comment": "texture / control",
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
          "comment": "vecfield",
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
            220.0,
            22.0
          ],
          "text": "route gain scale rotate thresh"
        }
      },
      {
        "box": {
          "id": "obj-5",
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
              34.0,
              483.0,
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
                  "code": "Param gain(4.0);\nParam scale(0.004);\nParam rotate(0.0);\nParam thresh(0.0);\nParam bypass(0.0);\n\n// inset UV by scale to keep neighbor samples within bounds\nsuv_x = norm.x * (1.0 - 2.0 * scale) + scale;\nsuv_y = norm.y * (1.0 - 2.0 * scale) + scale;\n\nL_center = sample(in1, vec(suv_x, suv_y)).x * 0.299 + sample(in1, vec(suv_x, suv_y)).y * 0.587 + sample(in1, vec(suv_x, suv_y)).z * 0.114;\nL_right  = sample(in1, vec(suv_x + scale, suv_y)).x * 0.299 + sample(in1, vec(suv_x + scale, suv_y)).y * 0.587 + sample(in1, vec(suv_x + scale, suv_y)).z * 0.114;\nL_left   = sample(in1, vec(suv_x - scale, suv_y)).x * 0.299 + sample(in1, vec(suv_x - scale, suv_y)).y * 0.587 + sample(in1, vec(suv_x - scale, suv_y)).z * 0.114;\nL_down   = sample(in1, vec(suv_x, suv_y + scale)).x * 0.299 + sample(in1, vec(suv_x, suv_y + scale)).y * 0.587 + sample(in1, vec(suv_x, suv_y + scale)).z * 0.114;\nL_up     = sample(in1, vec(suv_x, suv_y - scale)).x * 0.299 + sample(in1, vec(suv_x, suv_y - scale)).y * 0.587 + sample(in1, vec(suv_x, suv_y - scale)).z * 0.114;\n\ngx = (L_right - L_left) * gain;\ngy = (L_down  - L_up)   * gain;\n\nangle = rotate * pi / 180.0;\ncos_r = cos(angle);\nsin_r = sin(angle);\ngx2 = gx * cos_r - gy * sin_r;\ngy2 = gx * sin_r + gy * cos_r;\n\nfield   = vec(clamp(gx2 * 0.5 + 0.5, 0.0, 1.0), clamp(gy2 * 0.5 + 0.5, 0.0, 1.0), 0.5, 1.0);\nneutral = vec(0.5, 0.5, 0.5, 1.0);\n\nthreshed = mix(field, neutral, step(L_center, thresh));\n\nout1 = mix(threshed, neutral, bypass);",
                  "fontface": 0,
                  "fontname": "<Monospaced>",
                  "fontsize": 12.0,
                  "id": "gen-obj-2",
                  "maxclass": "codebox",
                  "numinlets": 1,
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
                  "id": "gen-obj-3",
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
                    "gen-obj-2",
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
                    "gen-obj-3",
                    0
                  ],
                  "source": [
                    "gen-obj-2",
                    0
                  ]
                }
              }
            ]
          },
          "patching_rect": [
            201.0,
            380.0,
            369.0,
            22.0
          ],
          "text": "jit.gl.pix vsynth @name fieldmap_pix @type float32 @boundmode 1",
          "varname": "fieldmap_pix"
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
            "rotate": [
              0.0
            ],
            "scale": [
              0.004
            ],
            "strength": [
              4.0
            ],
            "thresh": [
              0.0
            ]
          },
          "text": "autopattr",
          "varname": "fieldmap_autopattr"
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
          "text": "Fieldmap"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-8",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            20.0,
            20.0,
            60.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            56.0,
            3.0,
            60.0,
            18.0
          ],
          "text": "vecfield",
          "textcolor": [
            0.35,
            0.75,
            0.95,
            1.0
          ]
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
          "hint": "Gradient magnitude scale. Calibrate to input contrast.",
          "id": "obj-20",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "fieldmap_pix::gain",
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
                4.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "gain",
              "parameter_mmax": 10.0,
              "parameter_mmin": -10.0,
              "parameter_modmode": 3,
              "parameter_shortname": "gain",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "gain"
        }
      },
      {
        "box": {
          "attr": "strength",
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
            136.0,
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
          "text": "Strength",
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
          "hint": "Central difference step size (normalized UV). Low=fine, High=coarse.",
          "id": "obj-23",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "fieldmap_pix::scale",
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
                0.004
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "scale",
              "parameter_mmax": 0.05,
              "parameter_mmin": -0.05,
              "parameter_modmode": 3,
              "parameter_shortname": "scale",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "scale"
        }
      },
      {
        "box": {
          "attr": "scale",
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
          "text": "Scale",
          "textjustification": 1
        }
      },
      {
        "box": {
          "filename": "bypass_toggle.js",
          "hint": "Bypass",
          "id": "obj-26",
          "maxclass": "jsui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            78.0,
            5.0,
            18.0,
            12.0
          ],
          "presentation": 1,
          "presentation_rect": [
            129.0,
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
          "id": "obj-27",
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
          "hint": "Rotate gradient vector in degrees.",
          "id": "obj-28",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "fieldmap_pix::rotate",
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
                0.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "rotate",
              "parameter_mmax": 180.0,
              "parameter_mmin": -180.0,
              "parameter_modmode": 3,
              "parameter_shortname": "rotate",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "rotate"
        }
      },
      {
        "box": {
          "attr": "rotate",
          "id": "obj-29",
          "maxclass": "attrui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            150.0,
            200.0,
            136.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-30",
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
          "text": "Rotate",
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
          "hint": "Suppress field below source luma threshold.",
          "id": "obj-31",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "fieldmap_pix::thresh",
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
                0.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "thresh",
              "parameter_mmax": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "thresh",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "thresh"
        }
      },
      {
        "box": {
          "attr": "thresh",
          "id": "obj-32",
          "maxclass": "attrui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            200.0,
            240.0,
            136.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-33",
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
          "text": "Thresh",
          "textjustification": 1
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
            150.0,
            80.0
          ],
          "presentation": 1,
          "presentation_rect": [
            0.0,
            0.0,
            150.0,
            80.0
          ],
          "proportion": 0.5
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
            "obj-29",
            0
          ],
          "source": [
            "obj-28",
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
            "obj-32",
            0
          ],
          "source": [
            "obj-31",
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
            "obj-32",
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
            "obj-28",
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
            "obj-31",
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
          "source": [
            "obj-5",
            0
          ]
        }
      }
    ],
    "parameters": {
      "obj-20": [
        "strength",
        "strength",
        0
      ],
      "obj-23": [
        "scale",
        "scale",
        0
      ],
      "obj-28": [
        "rotate",
        "rotate",
        0
      ],
      "obj-31": [
        "thresh",
        "thresh",
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