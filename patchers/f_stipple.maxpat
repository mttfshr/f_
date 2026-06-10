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
          "id": "obj-1",
          "maxclass": "inlet",
          "comment": "texture",
          "index": 0,
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
          "id": "obj-2",
          "maxclass": "outlet",
          "comment": "texture",
          "index": 0,
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
          "numinlets": 1,
          "numoutlets": 11,
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
            ""
          ],
          "patching_rect": [
            200.0,
            130.0,
            700.0,
            22.0
          ],
          "text": "route freq coarseness anisotropy angle zoom threshold colorize along_phase across_phase softness proc_mode"
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
                  "code": "Param freq(5.0);\nParam angle(0.0);\nParam anisotropy(0.5);\nParam threshold(0.5);\nParam softness(0.1);\nParam along_phase(0.0);\nParam across_phase(0.0);\nParam zoom(1.0);\nParam colorize(0.0);\nParam coarseness(1.0);\nParam proc_mode(0.0);\nParam src_mode(0.0);\nParam bypass(0.0);\n\n// Coordinate frame\ntheta = angle * (3.14159265 / 180.0);\ncx = cos(theta);\nsx = sin(theta);\nalong = norm.x * cx + norm.y * sx;\nacross = -norm.x * sx + norm.y * cx;\n\n// Phase offset\nalong_d = along + along_phase;\nacross_d = across + across_phase;\n\n// Zoom applied to base coords only\nzoomed_along = along_d / max(zoom, 0.001);\nzoomed_across = across_d / max(zoom, 0.001);\n\n// Input sample\ninput_luma = sample(in1, norm).r;\nsrc_col = sample(in1, norm);\n\n// Displacement: warp zoomed coords by input luma\nwarp = input_luma * threshold;\nalong_disp = zoomed_along + warp;\nacross_disp = zoomed_across + warp * 0.5;\n\n// Select hash coordinates\nuse_along = mix(zoomed_along, along_disp, step(0.5, proc_mode));\nuse_across = mix(zoomed_across, across_disp, step(0.5, proc_mode));\n\n// Coarseness: scales down the large prime to increase grain period\nprime_scale = 43758.5 / max(coarseness, 1.0);\n\n// Parallel (sin-based) hash\nh_par_raw = sin(use_along * freq * prime_scale);\nh_parallel = h_par_raw - floor(h_par_raw);\n\n// Isotropic (arithmetic) hash\nh_iso_raw = sin((use_along * 127.1 + use_across * 311.7) * prime_scale);\nh_iso = h_iso_raw - floor(h_iso_raw);\n\n// Anisotropy blend\nhash_field = mix(h_iso, h_parallel, anisotropy);\n\n// Source mode: threshold against hash field directly\nlo = threshold - softness * 0.5;\nhi = threshold + softness * 0.5;\nsource_stipple = smoothstep(lo, hi, hash_field);\n\n// Processor/dither: input luma compared against hash field\ndither_stipple = smoothstep(hash_field - softness * 0.5, hash_field + softness * 0.5, input_luma + threshold - 0.5);\n\n// Select stipple by src_mode and proc_mode\nstipple = mix(source_stipple, dither_stipple, src_mode * (1.0 - step(0.5, proc_mode)));\nstipple = mix(stipple, source_stipple, src_mode * step(0.5, proc_mode));\n\n// Output color\nmono_out = vec(stipple, stipple, stipple, 1.0);\ncolor_out = vec(src_col.r * stipple, src_col.g * stipple, src_col.b * stipple, 1.0);\nresult = mix(mono_out, color_out, colorize * src_mode);\n\n// Bypass\nsource_bp = vec(0.0, 0.0, 0.0, 1.0);\nproc_bp = src_col;\nbypass_out = mix(source_bp, proc_bp, src_mode);\n\nout1 = mix(result, bypass_out, bypass);\n",
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
            200.0,
            380.0,
            200.0,
            22.0
          ],
          "text": "jit.gl.pix vsynth @name stipple_pix",
          "varname": "stipple_pix"
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
          "text": "autopattr",
          "varname": "stipple_autopattr"
        }
      },
      {
        "box": {
          "id": "obj-9",
          "maxclass": "panel",
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
          "mode": 0,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            20.0,
            20.0,
            191.0,
            157.0
          ],
          "presentation": 1,
          "presentation_rect": [
            0.0,
            0.0,
            191.0,
            157.0
          ],
          "proportion": 0.5
        }
      },
      {
        "box": {
          "id": "obj-10",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 12.0,
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
          "text": "Stipple"
        }
      },
      {
        "box": {
          "id": "obj-11",
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
          "id": "obj-17",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            200.0,
            60.0,
            80.0,
            22.0
          ],
          "text": "vs_inState"
        }
      },
      {
        "box": {
          "id": "obj-18",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            350.0,
            60.0,
            145.0,
            22.0
          ],
          "text": "prepend param src_mode"
        }
      },
      {
        "box": {
          "id": "obj-20",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Hash field spatial frequency",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::freq",
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
                2.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "freq",
              "parameter_mmax": 20.0,
              "parameter_mmin": 0.0,
              "parameter_modmode": 3,
              "parameter_shortname": "freq",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "freq"
        }
      },
      {
        "box": {
          "id": "obj-21",
          "maxclass": "attrui",
          "attr": "freq",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            50.0,
            170.0,
            108.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-22",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
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
          "text": "Freq",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-23",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Grain period scale \u2014 higher = chunkier grains",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::coarseness",
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
                20.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "coarseness",
              "parameter_mmax": 100.0,
              "parameter_mmin": 1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "coarseness",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "coarseness"
        }
      },
      {
        "box": {
          "id": "obj-24",
          "maxclass": "attrui",
          "attr": "coarseness",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            100.0,
            200.0,
            150.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-25",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
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
          "text": "Coarse.",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-26",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "0=isotropic grain  1=parallel lines  >1=expressive aliasing",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::anisotropy",
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
                0.5
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "anisotropy",
              "parameter_mmax": 4.0,
              "parameter_mmin": 0.0,
              "parameter_modmode": 3,
              "parameter_shortname": "anisotropy",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "anisotropy"
        }
      },
      {
        "box": {
          "id": "obj-27",
          "maxclass": "attrui",
          "attr": "anisotropy",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            150.0,
            230.0,
            150.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-28",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
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
          "text": "Aniso.",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-29",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Orientation of along/across coordinate frame",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::angle",
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
              "parameter_longname": "angle",
              "parameter_mmax": 360.0,
              "parameter_mmin": -360.0,
              "parameter_modmode": 3,
              "parameter_shortname": "angle",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "angle"
        }
      },
      {
        "box": {
          "id": "obj-30",
          "maxclass": "attrui",
          "attr": "angle",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            200.0,
            260.0,
            115.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-31",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
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
          "text": "Angle",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-32",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Scales viewport into hash field \u2014 same character, bigger or smaller",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::zoom",
          "parameter_enable": 1,
          "patching_rect": [
            250.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            152.0,
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
              "parameter_longname": "zoom",
              "parameter_mmax": 4.0,
              "parameter_mmin": 0.1,
              "parameter_modmode": 3,
              "parameter_shortname": "zoom",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "zoom"
        }
      },
      {
        "box": {
          "id": "obj-33",
          "maxclass": "attrui",
          "attr": "zoom",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            250.0,
            290.0,
            108.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-34",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            250.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            140.5,
            20.0,
            50.0,
            18.0
          ],
          "text": "Zoom",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-35",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Dither bias (dither mode); displacement amount (displacement mode)",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::threshold",
          "parameter_enable": 1,
          "patching_rect": [
            300.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            4.0,
            100.0,
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
              "parameter_longname": "threshold",
              "parameter_mmax": 2.0,
              "parameter_mmin": 0.0,
              "parameter_modmode": 3,
              "parameter_shortname": "threshold",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "threshold"
        }
      },
      {
        "box": {
          "id": "obj-36",
          "maxclass": "attrui",
          "attr": "threshold",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            300.0,
            320.0,
            143.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-37",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            300.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            -7.5,
            82.0,
            50.0,
            18.0
          ],
          "text": "Thresh.",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-38",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "0=monochrome dither output  1=inherit input color",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::colorize",
          "parameter_enable": 1,
          "patching_rect": [
            350.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            41.0,
            100.0,
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
              "parameter_longname": "colorize",
              "parameter_mmax": 1.0,
              "parameter_mmin": 0.0,
              "parameter_modmode": 3,
              "parameter_shortname": "colorize",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "colorize"
        }
      },
      {
        "box": {
          "id": "obj-39",
          "maxclass": "attrui",
          "attr": "colorize",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            350.0,
            350.0,
            136.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-40",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            350.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            29.5,
            82.0,
            50.0,
            18.0
          ],
          "text": "Colorize",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-41",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Hash field offset along angle axis; drive externally for drift",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::along_phase",
          "parameter_enable": 1,
          "patching_rect": [
            400.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            78.0,
            100.0,
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
              "parameter_longname": "along_phase",
              "parameter_mmax": 1.0,
              "parameter_mmin": -1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "along_phase",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "along_phase"
        }
      },
      {
        "box": {
          "id": "obj-42",
          "maxclass": "attrui",
          "attr": "along_phase",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            400.0,
            380.0,
            157.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-43",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            400.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            66.5,
            82.0,
            50.0,
            18.0
          ],
          "text": "Along",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-44",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Hash field offset perpendicular to angle axis; drive externally for drift",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::across_phase",
          "parameter_enable": 1,
          "patching_rect": [
            450.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            115.0,
            100.0,
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
              "parameter_longname": "across_phase",
              "parameter_mmax": 1.0,
              "parameter_mmin": -1.0,
              "parameter_modmode": 3,
              "parameter_shortname": "across_phase",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "across_phase"
        }
      },
      {
        "box": {
          "id": "obj-45",
          "maxclass": "attrui",
          "attr": "across_phase",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            450.0,
            410.0,
            164.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-46",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            450.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            103.5,
            82.0,
            50.0,
            18.0
          ],
          "text": "Across",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-47",
          "maxclass": "live.dial",
          "activedialcolor": [
            0.8,
            0.8,
            0.8,
            1.0
          ],
          "fontname": "Ableton Sans Light",
          "hint": "Smoothstep width at comparison boundary",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            "float"
          ],
          "param_connect": "stipple_pix::softness",
          "parameter_enable": 1,
          "patching_rect": [
            500.0,
            80.0,
            27.0,
            43.0
          ],
          "presentation": 1,
          "presentation_rect": [
            152.0,
            100.0,
            27.0,
            43.0
          ],
          "saved_attribute_attributes": {
            "activedialcolor": {
              "expression": ""
            },
            "valueof": {
              "parameter_initial": [
                0.1
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "softness",
              "parameter_mmax": 2.0,
              "parameter_mmin": 0.0,
              "parameter_modmode": 3,
              "parameter_shortname": "softness",
              "parameter_type": 0,
              "parameter_unitstyle": 1
            }
          },
          "showname": 0,
          "triangle": 1,
          "valuepopup": 1,
          "valuepopuplabel": 1,
          "varname": "softness"
        }
      },
      {
        "box": {
          "id": "obj-48",
          "maxclass": "attrui",
          "attr": "softness",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            500.0,
            440.0,
            136.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-49",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            500.0,
            130.0,
            50.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            140.5,
            82.0,
            50.0,
            18.0
          ],
          "text": "Soft.",
          "textjustification": 1
        }
      },
      {
        "box": {
          "id": "obj-19a",
          "maxclass": "live.toggle",
          "fontname": "Ableton Sans Light",
          "hint": "0=dither  1=displacement",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "param_connect": "stipple_pix::proc_mode",
          "parameter_enable": 1,
          "patching_rect": [
            450.0,
            60.0,
            20.0,
            20.0
          ],
          "presentation": 1,
          "presentation_rect": [
            141.0,
            1.0,
            20.0,
            20.0
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_initial": [
                0.0
              ],
              "parameter_initial_enable": 1,
              "parameter_linknames": 1,
              "parameter_longname": "proc_mode",
              "parameter_mmax": 1.0,
              "parameter_mmin": 0.0,
              "parameter_modmode": 0,
              "parameter_shortname": "proc_mode",
              "parameter_type": 1,
              "parameter_unitstyle": 0
            }
          },
          "varname": "proc_mode"
        }
      },
      {
        "box": {
          "id": "obj-19b",
          "maxclass": "comment",
          "fontname": "Ableton Sans Light",
          "fontsize": 9.5,
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            450.0,
            60.0,
            43.0,
            18.0
          ],
          "presentation": 1,
          "presentation_rect": [
            98.0,
            3.0,
            43.0,
            18.0
          ],
          "text": "Displace",
          "textjustification": 2
        }
      },
      {
        "box": {
          "id": "obj-19c",
          "maxclass": "attrui",
          "attr": "proc_mode",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            500.0,
            230.0,
            143.0,
            22.0
          ],
          "style": ""
        }
      },
      {
        "box": {
          "id": "obj-50",
          "maxclass": "jsui",
          "filename": "bypass_toggle.js",
          "hint": "Bypass",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "presentation": 1,
          "patching_rect": [
            169.0,
            5.0,
            18.0,
            12.0
          ],
          "presentation_rect": [
            169.0,
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
          "id": "obj-51",
          "maxclass": "attrui",
          "attr": "bypass",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            400.0,
            60.0,
            131.0,
            22.0
          ],
          "style": ""
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "source": [
            "obj-1",
            0
          ],
          "destination": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-3",
            0
          ],
          "destination": [
            "obj-17",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-17",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-17",
            1
          ],
          "destination": [
            "obj-18",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-18",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-3",
            2
          ],
          "destination": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-5",
            0
          ],
          "destination": [
            "obj-2",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-50",
            0
          ],
          "destination": [
            "obj-51",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-51",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-11",
            0
          ],
          "destination": [
            "obj-12",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-12",
            0
          ],
          "destination": [
            "obj-13",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-13",
            0
          ],
          "destination": [
            "obj-14",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-14",
            1
          ],
          "destination": [
            "obj-15",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-15",
            0
          ],
          "destination": [
            "obj-16",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            0
          ],
          "destination": [
            "obj-20",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-20",
            0
          ],
          "destination": [
            "obj-21",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-21",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            1
          ],
          "destination": [
            "obj-23",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-23",
            0
          ],
          "destination": [
            "obj-24",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-24",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            2
          ],
          "destination": [
            "obj-26",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-26",
            0
          ],
          "destination": [
            "obj-27",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-27",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            3
          ],
          "destination": [
            "obj-29",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-29",
            0
          ],
          "destination": [
            "obj-30",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-30",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            4
          ],
          "destination": [
            "obj-32",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-32",
            0
          ],
          "destination": [
            "obj-33",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-33",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            5
          ],
          "destination": [
            "obj-35",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-35",
            0
          ],
          "destination": [
            "obj-36",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-36",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            6
          ],
          "destination": [
            "obj-38",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-38",
            0
          ],
          "destination": [
            "obj-39",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-39",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            7
          ],
          "destination": [
            "obj-41",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-41",
            0
          ],
          "destination": [
            "obj-42",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-42",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            8
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
            "obj-44",
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
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            9
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
            0
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
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-4",
            10
          ],
          "destination": [
            "obj-19a",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-19a",
            0
          ],
          "destination": [
            "obj-19c",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-19c",
            0
          ],
          "destination": [
            "obj-5",
            0
          ]
        }
      }
    ],
    "parameters": {
      "obj-20": [
        "freq",
        "freq",
        0
      ],
      "obj-23": [
        "coarseness",
        "coarseness",
        0
      ],
      "obj-26": [
        "anisotropy",
        "anisotropy",
        0
      ],
      "obj-29": [
        "angle",
        "angle",
        0
      ],
      "obj-32": [
        "zoom",
        "zoom",
        0
      ],
      "obj-35": [
        "threshold",
        "threshold",
        0
      ],
      "obj-38": [
        "colorize",
        "colorize",
        0
      ],
      "obj-41": [
        "along_phase",
        "along_phase",
        0
      ],
      "obj-44": [
        "across_phase",
        "across_phase",
        0
      ],
      "obj-47": [
        "softness",
        "softness",
        0
      ],
      "obj-19a": [
        "proc_mode",
        "proc_mode",
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