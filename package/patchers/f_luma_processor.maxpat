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
      362.0,
      254.0,
      829.0,
      804.0
    ],
    "openinpresentation": 1,
    "toolbars_unpinned_last_save": 2,
    "boxes": [
      {
        "box": {
          "filename": "bypass_toggle.js",
          "hint": "Bypass",
          "id": "obj-8",
          "maxclass": "jsui",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            115.0,
            99.0,
            18.0,
            12.0
          ],
          "presentation": 1,
          "presentation_rect": [
            129.0,
            4.0,
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
          "id": "obj-24",
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
            513.3333486318588,
            314.00000935792923,
            56.0,
            22.0
          ],
          "restore": {
            "bypass": [
              0
            ],
            "falloff": [
              0.09448818897637795
            ],
            "hue_shift": [
              0.0
            ],
            "live.numbox[2]": [
              0.09448818897637795
            ],
            "low_mid": [
              0.0
            ],
            "lum_shift": [
              0.0
            ],
            "mid_high": [
              1.0
            ],
            "sat_amt": [
              0.0
            ]
          },
          "text": "autopattr",
          "varname": "u099020110"
        }
      },
      {
        "box": {
          "activebgcolor": [
            0.0784313725490196,
            0.0784313725490196,
            0.0784313725490196,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "id": "obj-5",
          "maxclass": "live.numbox",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "parameter_enable": 1,
          "patching_rect": [
            158.75,
            366.0,
            46.0,
            15.0
          ],
          "presentation": 1,
          "presentation_rect": [
            1.0,
            99.25,
            34.0,
            15.0
          ],
          "saved_attribute_attributes": {
            "activebgcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_longname": "live.numbox[2]",
              "parameter_mmax": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "live.numbox",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "varname": "live.numbox[2]"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 8.0,
          "id": "obj-22",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            241.0,
            165.5,
            111.0,
            16.0
          ],
          "presentation": 1,
          "presentation_rect": [
            89.66666933894157,
            43.666667968034744,
            15.0,
            16.0
          ],
          "text": "hi"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 8.0,
          "id": "obj-21",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            226.0,
            150.5,
            111.0,
            16.0
          ],
          "presentation": 1,
          "presentation_rect": [
            42.375,
            43.625,
            22.166666626930237,
            16.0
          ],
          "text": "low"
        }
      },
      {
        "box": {
          "id": "obj-20",
          "maxclass": "live.numbox",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "jit.gl.pix_AA::mid_high",
          "parameter_enable": 1,
          "patching_rect": [
            252.0,
            599.0,
            44.0,
            15.0
          ],
          "presentation": 1,
          "presentation_rect": [
            103.75,
            44.125,
            44.0,
            15.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_initial": [
                0.66
              ],
              "parameter_linknames": 1,
              "parameter_longname": "mid_high",
              "parameter_mmax": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "mid_high",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "varname": "mid_high"
        }
      },
      {
        "box": {
          "id": "obj-7",
          "maxclass": "live.numbox",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "jit.gl.pix_AA::low_mid",
          "parameter_enable": 1,
          "patching_rect": [
            23.0,
            605.0,
            44.0,
            15.0
          ],
          "presentation": 1,
          "presentation_rect": [
            1.0000000298023224,
            44.000001311302185,
            44.0,
            15.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_initial": [
                0.3299999999999983
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "low_mid",
              "parameter_mmax": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "low_mid",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "varname": "low_mid"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "id": "obj-6",
          "maxclass": "comment",
          "numinlets": 0,
          "numoutlets": 0,
          "patching_rect": [
            169.00000503659248,
            141.3333375453949,
            146.0,
            21.0
          ],
          "presentation": 1,
          "presentation_rect": [
            -0.25,
            1.0000000298023224,
            97.0,
            21.0
          ],
          "suppressinlet": 1,
          "text": "Luma Processor"
        }
      },
      {
        "box": {
          "appearance": 1,
          "fontname": "Ableton Sans Light",
          "hint": "Edge falloff",
          "id": "obj-26",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "jit.gl.pix_AA::edge_falloff",
          "parameter_enable": 1,
          "patching_rect": [
            168.25,
            315.20000475645065,
            25.0,
            23.0
          ],
          "presentation": 1,
          "presentation_rect": [
            5.75,
            75.75,
            25.0,
            23.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "edge_falloff",
              "parameter_mmax": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "edge_falloff",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "shownumber": 0,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "falloff"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.0,
          "id": "obj-4",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            211.0,
            135.5,
            123.0,
            17.0
          ],
          "presentation": 1,
          "presentation_rect": [
            1.75,
            56.75,
            34.0,
            17.0
          ],
          "text": "Falloff"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "hint": "Saturation",
          "id": "obj-13",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "jit.gl.pix_AA::sat_amt",
          "parameter_enable": 1,
          "patching_rect": [
            226.0,
            132.00000196695328,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            43.00000128149986,
            69.66666874289513,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_initial": [
                0.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "sat_amt",
              "parameter_mmax": 1.0,
              "parameter_mmin": -1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "sat_amt",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "sat_amt"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.0,
          "id": "obj-38",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            226.0,
            150.5,
            116.0,
            17.0
          ],
          "presentation": 1,
          "presentation_rect": [
            118.66667020320892,
            56.666668355464935,
            25.0,
            17.0
          ],
          "text": "Rot"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.0,
          "id": "obj-37",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            211.0,
            135.5,
            121.0,
            17.0
          ],
          "presentation": 1,
          "presentation_rect": [
            82.33333578705788,
            56.666668355464935,
            27.0,
            17.0
          ],
          "text": "Lum"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "fontsize": 9.0,
          "id": "obj-36",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            196.0,
            120.5,
            117.0,
            17.0
          ],
          "presentation": 1,
          "presentation_rect": [
            44.66666799783707,
            56.666668355464935,
            27.0,
            17.0
          ],
          "text": "Sat"
        }
      },
      {
        "box": {
          "border": 0,
          "filename": "luma_rslider.js",
          "hint": "Hue band selection",
          "id": "obj-33",
          "maxclass": "jsui",
          "numinlets": 3,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            48.00000071525574,
            547.2000081539154,
            212.00000315904617,
            33.600000500679016
          ],
          "presentation": 1,
          "presentation_rect": [
            3.000000089406967,
            24.000000715255737,
            142.33333757519722,
            19.333333909511566
          ],
          "valuepopup": 1,
          "valuepopuplabel": 1
        }
      },
      {
        "box": {
          "id": "obj-19",
          "maxclass": "attrui",
          "attr": "edge_falloff",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            252.00000375509262,
            486.4000072479248,
            155.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-11",
          "maxclass": "attrui",
          "attr": "mid_high",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            249.5,
            688.5,
            142.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-10",
          "maxclass": "attrui",
          "attr": "low_mid",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            84.5,
            673.5,
            137.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-18",
          "maxclass": "attrui",
          "attr": "hue_shift",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            535.5,
            193.6000028848648,
            142.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-17",
          "maxclass": "attrui",
          "attr": "lum_shift",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            370.4000055193901,
            196.80000293254852,
            141.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-16",
          "maxclass": "attrui",
          "attr": "sat_amt",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            226.0,
            193.6000028848648,
            136.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "hint": "Hue rotation",
          "id": "obj-15",
          "maxclass": "live.dial",
          "needlemode": 2,
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "jit.gl.pix_AA::hue_shift",
          "parameter_enable": 1,
          "patching_rect": [
            535.5,
            135.00000196695328,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            116.33333680033684,
            70.00000208616257,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_initial": [
                0.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "hue_shift",
              "parameter_mmax": 180.0,
              "parameter_mmin": -180.0,
              "parameter_modmode": 3,
              "parameter_shortname": "hue_shift",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "hue_shift"
        }
      },
      {
        "box": {
          "fontname": "Ableton Sans Light",
          "hint": "Luminosity",
          "id": "obj-14",
          "maxclass": "live.dial",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "jit.gl.pix_AA::lum_shift",
          "parameter_enable": 1,
          "patching_rect": [
            370.4000055193901,
            137.60000205039978,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            80.66666907072067,
            70.00000208616257,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_initial": [
                0.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "lum_shift",
              "parameter_mmax": 1.0,
              "parameter_mmin": -1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "lum_shift",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "lum_shift"
        }
      },
      {
        "box": {
          "id": "obj-12",
          "maxclass": "attrui",
          "attr": "bypass",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            79.20000118017197,
            193.6000028848648,
            131.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "comment": "texture",
          "id": "obj-3",
          "index": 0,
          "maxclass": "outlet",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            450.5,
            459.5,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-39",
          "maxclass": "newobj",
          "numinlets": 8,
          "numoutlets": 8,
          "outlettype": [
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
          ],
          "patching_rect": [
            332.0,
            370.0,
            391.0,
            22.0
          ],
          "text": "route bypass sat_amt lum_shift hue_shift edge_falloff low_mid mid_high"
        }
      },
      {
        "box": {
          "comment": "texture / control",
          "id": "obj-2",
          "index": 0,
          "maxclass": "inlet",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            332.0,
            339.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-1",
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
              303.0,
              95.0,
              652.0,
              778.0
            ],
            "boxes": [
              {
                "box": {
                  "code": "Param low_mid(0.33);\nParam mid_high(0.66);\nParam edge_falloff(0.1);\nParam sat_amt(0.0);\nParam lum_shift(0.0);\nParam hue_shift(0.0);\nParam bypass(0.0);\n\nuv = norm;\nsrc = sample(in1, uv);\nr = src.r; g = src.g; b = src.b;\n\n// RGB -> HSV\ncmax = max(max(r, g), b);\ncmin = min(min(r, g), b);\ndelta = cmax - cmin;\n\n// hue\nhue = 0.0;\ns1 = step(0.00001, delta);\nhr = (g - b) / max(delta, 0.00001);\nhg = 2.0 + (b - r) / max(delta, 0.00001);\nhb = 4.0 + (r - g) / max(delta, 0.00001);\nhue = step(cmax, r + 0.00001) * hr\n    + step(cmax, g + 0.00001) * hg\n    + (1.0 - step(cmax, r + 0.00001)) * (1.0 - step(cmax, g + 0.00001)) * hb;\nhue = (hue / 6.0 + 1.0) - floor(hue / 6.0 + 1.0);\n\n// sat, val\nsat = s1 * delta / max(cmax, 0.00001);\nval = cmax;\n\n// luma for mask (pre-op, on raw pixel)\nlum = 0.299 * r + 0.587 * g + 0.114 * b;\n\n// flat-top luma mask \u2014 same smoothstep pattern as tone_curve\nlm = min(low_mid, mid_high);\nmh = max(low_mid, mid_high);\nef = edge_falloff;\nmask = smoothstep(lm - ef, lm + ef, lum) * (1.0 - smoothstep(mh - ef, mh + ef, lum));\n\n// HSV operations\nsat_out = clamp(sat + sat_amt * mask, 0.0, 1.0);\nval_out = clamp(val + lum_shift * mask, 0.0, 1.0);\nhue_out = hue + (hue_shift / 360.0) * mask;\nhue_out = hue_out - floor(hue_out);\n\n// HSV -> RGB (branch-free)\nh6 = hue_out * 6.0;\nkr = abs(h6 - 3.0) - 1.0;\nkg = 2.0 - abs(h6 - 2.0);\nkb = 2.0 - abs(h6 - 4.0);\nro = val_out * mix(1.0, clamp(kr, 0.0, 1.0), sat_out);\ngo = val_out * mix(1.0, clamp(kg, 0.0, 1.0), sat_out);\nbo = val_out * mix(1.0, clamp(kb, 0.0, 1.0), sat_out);\n\neffective = 1.0 - bypass;\nout1 = vec(mix(r, ro, effective),\n           mix(g, go, effective),\n           mix(b, bo, effective),\n           src.a);",
                  "fontface": 0,
                  "fontname": "<Monospaced>",
                  "fontsize": 12.0,
                  "id": "obj-5",
                  "maxclass": "codebox",
                  "numinlets": 1,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "patching_rect": [
                    50.0,
                    49.0,
                    508.0,
                    685.0
                  ]
                }
              },
              {
                "box": {
                  "id": "obj-1",
                  "maxclass": "newobj",
                  "numinlets": 0,
                  "numoutlets": 1,
                  "outlettype": [
                    ""
                  ],
                  "patching_rect": [
                    50.0,
                    14.0,
                    28.0,
                    22.0
                  ],
                  "text": "in 1"
                }
              },
              {
                "box": {
                  "id": "obj-4",
                  "maxclass": "newobj",
                  "numinlets": 1,
                  "numoutlets": 0,
                  "patching_rect": [
                    50.0,
                    746.0,
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
                    "obj-5",
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
                    "obj-4",
                    0
                  ],
                  "source": [
                    "obj-5",
                    0
                  ]
                }
              }
            ]
          },
          "patching_rect": [
            432.0,
            405.0,
            235.0,
            22.0
          ],
          "text": "jit.gl.pix @name luma_pix @drawto vsynth @type char",
          "varname": "jit.gl.pix_AA"
        }
      },
      {
        "box": {
          "angle": 270.0,
          "bgcolor": [
            0.058823529411764705,
            0.058823529411764705,
            0.058823529411764705,
            1.0
          ],
          "border": 1,
          "bordercolor": [
            0.0,
            0.03529411765,
            0.2274509804,
            1.0
          ],
          "id": "obj-23",
          "maxclass": "panel",
          "mode": 0,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            15.0,
            246.5,
            128.0,
            128.0
          ],
          "presentation": 1,
          "presentation_rect": [
            0.0,
            0.0,
            150.0,
            120.0
          ],
          "proportion": 0.5
        }
      },
      {
        "box": {
          "id": "obj-40",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
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
          "id": "obj-44",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            600.0,
            170.0,
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
          "id": "obj-45",
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
          "id": "obj-46",
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
            600.0,
            110.0,
            80.0,
            22.0
          ],
          "text": "thispatcher"
        }
      },
      {
        "box": {
          "id": "obj-47",
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
          "id": "obj-48",
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
          "id": "obj-rp100",
          "maxclass": "newobj",
          "text": "routepass jit_gl_texture jit_matrix",
          "numinlets": 1,
          "numoutlets": 3,
          "outlettype": [
            "jit_gl_texture",
            "jit_matrix",
            ""
          ],
          "patching_rect": [
            332.0,
            354.5,
            220.0,
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
            "obj-1",
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
            "obj-1",
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
            "obj-1",
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
            "obj-16",
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
            "obj-17",
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
            "obj-18",
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
            "obj-1",
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
            "obj-1",
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
            "obj-1",
            0
          ],
          "source": [
            "obj-18",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-1",
            0
          ],
          "source": [
            "obj-19",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-33",
            2
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
            "obj-19",
            0
          ],
          "order": 0,
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
          "order": 1,
          "source": [
            "obj-26",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            0
          ],
          "order": 0,
          "source": [
            "obj-33",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "order": 1,
          "source": [
            "obj-33",
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
          "order": 0,
          "source": [
            "obj-33",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-7",
            0
          ],
          "order": 1,
          "source": [
            "obj-33",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-1",
            0
          ],
          "source": [
            "obj-39",
            7
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
            "obj-39",
            1
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
            "obj-39",
            2
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
            "obj-39",
            3
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
            "obj-39",
            6
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
            "obj-39",
            4
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
            "obj-39",
            5
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
            "obj-39",
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
            "obj-5",
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
            "obj-7",
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
            "obj-8",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-40",
            0
          ],
          "destination": [
            "obj-45",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-45",
            0
          ],
          "destination": [
            "obj-46",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-46",
            0
          ],
          "destination": [
            "obj-47",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-47",
            1
          ],
          "destination": [
            "obj-48",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-48",
            0
          ],
          "destination": [
            "obj-44",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-2",
            0
          ],
          "destination": [
            "obj-rp100",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-rp100",
            0
          ],
          "destination": [
            "obj-1",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-rp100",
            2
          ],
          "destination": [
            "obj-39",
            0
          ]
        }
      }
    ],
    "parameters": {
      "obj-13": [
        "sat_amt",
        "sat_amt",
        0
      ],
      "obj-14": [
        "lum_shift",
        "lum_shift",
        0
      ],
      "obj-15": [
        "hue_shift",
        "hue_shift",
        0
      ],
      "obj-20": [
        "mid_high",
        "mid_high",
        0
      ],
      "obj-26": [
        "edge_falloff",
        "edge_falloff",
        0
      ],
      "obj-5": [
        "live.numbox[2]",
        "live.numbox",
        0
      ],
      "obj-7": [
        "low_mid",
        "low_mid",
        0
      ],
      "obj-8": [
        "bypass",
        "bypass",
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