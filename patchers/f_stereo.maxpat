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
      869.0,
      129.0,
      402.0,
      762.0
    ],
    "openinpresentation": 1,
    "boxes": [
      {
        "box": {
          "angle": 270.0,
          "background": 1,
          "bgcolor": [
            0,
            0,
            0,
            1
          ],
          "border": 1,
          "bordercolor": [
            0.0,
            0.03529411765,
            0.2274509804,
            1.0
          ],
          "id": "obj-1",
          "maxclass": "panel",
          "mode": 0,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            20.0,
            20.0,
            185.0,
            90.0
          ],
          "presentation": 1,
          "presentation_rect": [
            0.0,
            0.0,
            159.5,
            90.0
          ],
          "proportion": 0.5
        }
      },
      {
        "box": {
          "filename": "bypass_toggle.js",
          "hint": "Bypass",
          "id": "obj-2",
          "maxclass": "jsui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            700.0,
            30.0,
            18.0,
            12.0
          ],
          "presentation": 1,
          "presentation_rect": [
            138.0,
            5.0,
            18.0,
            12.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_invisible": 1,
              "parameter_longname": "bypass",
              "parameter_modmode": 4,
              "parameter_shortname": "bypass",
              "parameter_type": 1,
              "parameter_unitstyle": 0
            }
          },
          "valuepopuplabel": 1,
          "varname": "bypass"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 12.0,
          "id": "obj-3",
          "linecount": 2,
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            20.0,
            20.0,
            80.0,
            35.0
          ],
          "presentation": 1,
          "presentation_rect": [
            0.0,
            1.0,
            101.5,
            21.0
          ],
          "text": "Stereo Projection"
        }
      },
      {
        "box": {
          "comment": "texture / control",
          "id": "obj-4",
          "index": 0,
          "maxclass": "inlet",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            50.0,
            30.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "comment": "control",
          "id": "obj-5",
          "index": 0,
          "maxclass": "inlet",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            200.0,
            30.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "comment": "texture",
          "id": "obj-6",
          "index": 0,
          "maxclass": "outlet",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            50.0,
            600.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-7",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 3,
          "outlettype": [
            "",
            "",
            ""
          ],
          "patching_rect": [
            50.0,
            100.0,
            230.0,
            22.0
          ],
          "text": "routepass jit_gl_texture jit_matrix"
        }
      },
      {
        "box": {
          "id": "obj-8",
          "maxclass": "newobj",
          "numinlets": 7,
          "numoutlets": 7,
          "outlettype": [
            "",
            "",
            "",
            "",
            "",
            "",
            ""
          ],
          "patching_rect": [
            200.0,
            100.0,
            300.0,
            22.0
          ],
          "text": "route bypass lon lat spin proj circ"
        }
      },
      {
        "box": {
          "id": "obj-9",
          "maxclass": "attrui",
          "attr": "bypass",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            700.0,
            80.0,
            150.0,
            22.0
          ],
          "style": ""
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
          "hint": "lon",
          "id": "obj-10",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stereo_pix::lon",
          "parameter_enable": 1,
          "patching_rect": [
            408.0,
            320.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            8.0,
            40.0,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "activedialcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_initial": [
                0.5
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "lon",
              "parameter_mmax": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "lon",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "lon"
        }
      },
      {
        "box": {
          "id": "obj-11",
          "maxclass": "attrui",
          "attr": "lon",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            408.0,
            420.0,
            150.0,
            22.0
          ],
          "style": ""
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
            408.0,
            364.0,
            36.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            10.0,
            24.0,
            36.0,
            18.0
          ],
          "text": "Lon"
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
          "hint": "lat",
          "id": "obj-12",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stereo_pix::lat",
          "parameter_enable": 1,
          "patching_rect": [
            443.0,
            320.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            45.333333333333336,
            40.0,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "activedialcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_initial": [
                0.5
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "lat",
              "parameter_mmax": 1.0,
              "parameter_mmin": -1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "lat",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "lat"
        }
      },
      {
        "box": {
          "id": "obj-13",
          "maxclass": "attrui",
          "attr": "lat",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            443.0,
            420.0,
            150.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "id": "obj-29",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            443.0,
            364.0,
            36.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            49.0,
            24.0,
            36.0,
            18.0
          ],
          "text": "Lat"
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
          "hint": "spin",
          "id": "obj-14",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stereo_pix::spin",
          "parameter_enable": 1,
          "patching_rect": [
            478.0,
            320.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            82.66666666666667,
            40.0,
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
              "parameter_longname": "spin",
              "parameter_mmax": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "spin",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "spin"
        }
      },
      {
        "box": {
          "id": "obj-15",
          "maxclass": "attrui",
          "attr": "spin",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            478.0,
            420.0,
            150.0,
            22.0
          ],
          "style": ""
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
            478.0,
            364.0,
            36.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            82.0,
            24.0,
            36.0,
            18.0
          ],
          "text": "Spin"
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
          "hint": "proj",
          "id": "obj-16",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stereo_pix::proj",
          "parameter_enable": 1,
          "patching_rect": [
            513.0,
            320.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            120.0,
            40.0,
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
              "parameter_longname": "proj",
              "parameter_mmax": 2.0,
              "parameter_mmin": -2.0,
              "parameter_modmode": 3,
              "parameter_shortname": "proj",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "proj"
        }
      },
      {
        "box": {
          "id": "obj-17",
          "maxclass": "attrui",
          "attr": "proj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            513.0,
            420.0,
            150.0,
            22.0
          ],
          "style": ""
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
            513.0,
            364.0,
            36.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            120.0,
            24.0,
            36.0,
            18.0
          ],
          "text": "Proj"
        }
      },
      {
        "box": {
          "activebgcolor": [
            0.06666666666666667,
            0.06274509803921569,
            0.06274509803921569,
            1.0
          ],
          "activebgoncolor": [
            0.06666666666666667,
            0.06274509803921569,
            0.06274509803921569,
            1.0
          ],
          "activetextcolor": [
            0.7568627450980392,
            0.7568627450980392,
            0.7568627450980392,
            1.0
          ],
          "activetextoncolor": [
            0.6588235294117647,
            0.6588235294117647,
            0.6588235294117647,
            1.0
          ],
          "bordercolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "id": "obj-32",
          "maxclass": "live.text",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "parameter_enable": 1,
          "patching_rect": [
            750.0,
            30.0,
            54.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            102.5,
            4.5,
            32.5,
            14.0
          ],
          "rounded": 4.0,
          "saved_attribute_attributes": {
            "activebgcolor": {
              "expression": ""
            },
            "activebgoncolor": {
              "expression": ""
            },
            "activetextcolor": {
              "expression": ""
            },
            "activetextoncolor": {
              "expression": ""
            },
            "bordercolor": {
              "expression": "themecolor.live_arranger_grid_tiles"
            },
            "valueof": {
              "parameter_enum": [
                "val1",
                "val2"
              ],
              "parameter_initial": [
                1.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "circ",
              "parameter_mmax": 1,
              "parameter_modmode": 0,
              "parameter_shortname": "circ",
              "parameter_speedlim": 0.0,
              "parameter_type": 2
            }
          },
          "text": "full",
          "texton": "mask",
          "varname": "circ"
        }
      },
      {
        "box": {
          "id": "obj-33",
          "maxclass": "attrui",
          "attr": "circ",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            750.0,
            80.0,
            150.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-20",
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
              733.0,
              318.0,
              339.0,
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
                  "code": "Param lon(0.5);\nParam lat(0.5);\nParam spin(0.0);\nParam proj(0.0);\nParam bypass(0.0);\nParam circ(1.0);\n\n// 1. UV to centered complex plane\nzx = (norm.x - 0.5) * 2.0;\nzy = (norm.y - 0.5) * 2.0;\n\n// 2. Display projection: sphere point from screen UV\nr2 = zx*zx + zy*zy;\n\n// Stereographic\ndenom = 1.0 + r2;\nsx_s = 2.0 * zx / denom;\nsy_s = 2.0 * zy / denom;\nsz_s = (1.0 - r2) / denom;\n\n// Orthographic\nsx_o = zx;\nsy_o = zy;\nsz_o = sqrt(max(1.0 - r2, 0.0));\n\n// Blend: 0 = ortho, 1 = stereo, outside range = extended effects\nsx = mix(sx_o, sx_s, proj);\nsy = mix(sy_o, sy_s, proj);\nsz = mix(sz_o, sz_s, proj);\n\n// 3. Rotation angles\nTWO_PI = 3.14159265359 * 2.0;\nPI = 3.14159265359;\nlon_a  = (lon - 0.5) * TWO_PI;\nlat_a  = (lat - 0.5) * PI;\nspin_a = spin * TWO_PI;\n\nca = cos(lat_a);  sa = sin(lat_a);\ncb = cos(lon_a);  sb = sin(lon_a);\ncs = cos(spin_a); ss = sin(spin_a);\n\n// 4. R = Rz(spin) x Ry(lon) x Rx(lat)\nrx = cs*cb*sx + (cs*sb*sa - ss*ca)*sy + (cs*sb*ca + ss*sa)*sz;\nry = ss*cb*sx + (ss*sb*sa + cs*ca)*sy + (ss*sb*ca - cs*sa)*sz;\nrz =   -sb*sx +              cb*sa*sy +              cb*ca*sz;\n\n// 5. Equirectangular sampling\nux = atan2(ry, rx) / TWO_PI + 0.5;\nuy = asin(rz) / PI + 0.5;\neffect_out = sample(in1, vec(ux, uy, 0));\n\n// 6. Circular mask (optional)\ndist = length(vec(norm.x - 0.5, norm.y - 0.5));\noutside = step(0.5, dist);\nmasked = mix(effect_out, vec(0, 0, 0, 1), outside * circ);\n\n// 7. Bypass\nout1 = mix(masked, sample(in1, norm), bypass);",
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
                    600.0,
                    440.0
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
                    550.0,
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
            50.0,
            500.0,
            270.0,
            22.0
          ],
          "text": "jit.gl.pix vsynth @name stereo_pix @type char",
          "varname": "stereo_pix"
        }
      },
      {
        "box": {
          "id": "obj-21",
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
            30.0,
            210.0,
            22.0
          ],
          "restore": {
            "bypass[1]": [
              0
            ],
            "circ": [
              1.0
            ],
            "lat": [
              0.5
            ],
            "lon": [
              0.5
            ],
            "proj": [
              0.0
            ],
            "spin": [
              0.0
            ]
          },
          "text": "autopattr @varname stereo_autopattr",
          "varname": "u_stereo_autopattr"
        }
      },
      {
        "box": {
          "id": "obj-22",
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
          "id": "obj-23",
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
          "id": "obj-24",
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
          "id": "obj-25",
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
          "id": "obj-26",
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
          "id": "obj-27",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            600.0,
            200.0,
            120.0,
            22.0
          ],
          "saved_object_attributes": {
            "filename": "moduleSize.js",
            "parameter_enable": 0
          },
          "text": "js moduleSize.js"
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-10",
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
            "obj-20",
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
            "obj-15",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-17",
            0
          ],
          "source": [
            "obj-16",
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
            "obj-17",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-9",
            0
          ],
          "source": [
            "obj-2",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-6",
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
            "obj-23",
            0
          ],
          "source": [
            "obj-22",
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
            "obj-25",
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
            "obj-26",
            0
          ],
          "source": [
            "obj-25",
            1
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
            "obj-20",
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
            "obj-7",
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
            "obj-8",
            0
          ],
          "source": [
            "obj-5",
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
            "obj-7",
            1
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
            "obj-7",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-8",
            0
          ],
          "source": [
            "obj-7",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            0
          ],
          "source": [
            "obj-8",
            1
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
            "obj-8",
            2
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
            "obj-8",
            3
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
            "obj-8",
            4
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
            "obj-8",
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
            "obj-8",
            5
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
            "obj-9",
            0
          ]
        }
      }
    ],
    "parameters": {
      "obj-10": [
        "lon",
        "lon",
        0
      ],
      "obj-12": [
        "lat",
        "lat",
        0
      ],
      "obj-14": [
        "spin",
        "spin",
        0
      ],
      "obj-16": [
        "proj",
        "proj",
        0
      ],
      "obj-2": [
        "bypass",
        "bypass",
        0
      ],
      "obj-32": [
        "circ",
        "circ",
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