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
      1040.0,
      620.0
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
            20.0,
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
          "id": "out1",
          "maxclass": "outlet",
          "patching_rect": [
            120.0,
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
            220.0,
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
          "id": "obj-920",
          "maxclass": "newobj",
          "text": "route scale weight r n gain mix_pct bypass",
          "numinlets": 1,
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
            20.0,
            60.0,
            480.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-901",
          "maxclass": "newobj",
          "text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "jit_gl_texture",
            ""
          ],
          "patching_rect": [
            20.0,
            120.0,
            330.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-902",
          "maxclass": "newobj",
          "text": "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "jit_gl_texture",
            ""
          ],
          "patching_rect": [
            400.0,
            120.0,
            330.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-903",
          "maxclass": "newobj",
          "text": "route out_name",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            20.0,
            160.0,
            100.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-904",
          "maxclass": "newobj",
          "text": "route out_name",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            400.0,
            160.0,
            100.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-905",
          "maxclass": "newobj",
          "text": "join",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            20.0,
            200.0,
            60.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-906",
          "maxclass": "newobj",
          "text": "prepend texture",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            20.0,
            240.0,
            110.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-907",
          "maxclass": "newobj",
          "text": "r draw",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            180.0,
            90.0,
            50.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-908",
          "maxclass": "message",
          "text": "getout_name",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            180.0,
            120.0,
            90.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-909",
          "maxclass": "newobj",
          "text": "jit.gl.node vsynth @capture 1 @name #0.node @type float32 @adapt 0 @dim 1024 1024 @erase_color 0 0 0 0",
          "numinlets": 1,
          "numoutlets": 3,
          "outlettype": [
            "jit_gl_texture",
            "",
            ""
          ],
          "patching_rect": [
            400.0,
            300.0,
            400.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-910",
          "maxclass": "newobj",
          "text": "jit.gl.shader vsynth @name #0.sc @file f_caustic_sheets.jxs",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            20.0,
            300.0,
            330.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-911",
          "maxclass": "newobj",
          "text": "jit.gl.gridshape vsynth @shape plane @dim 2 2 @matrixoutput 1 @automatic 0",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "jit_matrix",
            ""
          ],
          "patching_rect": [
            20.0,
            400.0,
            400.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-912",
          "maxclass": "newobj",
          "text": "jit.gl.mesh #0.node @draw_mode points @shader #0.sc @blend_enable 1 @blend_mode 1 1 @depth_enable 0 @point_size 2 @color 1 1 1 1 @lighting_enable 0",
          "numinlets": 1,
          "numoutlets": 2,
          "outlettype": [
            "",
            ""
          ],
          "patching_rect": [
            20.0,
            440.0,
            600.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-921",
          "maxclass": "newobj",
          "text": "prepend param scale",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            20.0,
            350.0,
            130.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-922",
          "maxclass": "newobj",
          "text": "prepend param weight",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            160.0,
            350.0,
            140.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-923",
          "maxclass": "newobj",
          "text": "prepend param res",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            310.0,
            350.0,
            120.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-924",
          "maxclass": "message",
          "text": "dim $1 $1",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            440.0,
            350.0,
            70.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-925",
          "maxclass": "message",
          "text": "dim $1 $1, bang",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            520.0,
            350.0,
            110.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-935",
          "maxclass": "newobj",
          "text": "loadbang",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            "bang"
          ],
          "patching_rect": [
            640.0,
            60.0,
            70.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-936",
          "maxclass": "message",
          "text": "r 1024, weight 0.2500, n 2048",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            640.0,
            100.0,
            330.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-950",
          "maxclass": "newobj",
          "text": "jit.gl.pix vsynth @name #0.sheets @type float32 @adapt 1",
          "numinlets": 3,
          "numoutlets": 3,
          "outlettype": [
            "jit_gl_texture",
            "jit_gl_texture",
            ""
          ],
          "patching_rect": [
            20.0,
            500.0,
            520.0,
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
              560.0,
              340.0
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
                    140.0,
                    30.0,
                    100.0,
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
                    250.0,
                    30.0,
                    100.0,
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
                  "text": "in 3",
                  "id": "gen-obj-3",
                  "patching_rect": [
                    30.0,
                    90.0,
                    100.0,
                    22.0
                  ]
                }
              },
              {
                "box": {
                  "maxclass": "codebox",
                  "code": "// f_caustic sheets mode: COMPOSITE stage (spec .specify/f_caustic_scatter/spec.md, \"Composite (sheets)\")\n//\n// in1 = light-source texture. The composite is built over it and this pix FOLLOWS ITS SIZE (@adapt 1, no fixed @dim)\n// in2 = the scatter node's float32 illuminance capture: square, fixed size (the `detail` step), HDR. Read with\n//       sample(in2, norm), which upscales it bilinearly to the output size\n// in3 = f_vecfield, read ONLY by the unconnected-field guard\n//\n// out1 = composite  mix(source, clamp(source + light, 0, 1), mix_pct / 100)\n// out2 = caustic layer, tone mapped and clamped (the same meaning as the soft path's out2)\n//\n// This is now the module's only stage (soft mode and the select stages were removed 2026-10-10), so bypass is\n// handled HERE: bypass_gate mixes both outlets to the source last (\"every outlet mixes to its passthrough\").\n//\n// Skill checklist (skills/jit-gen-codebox; the look-patch tone stage broke on the first two):\n//   - functions are defined BEFORE every statement, and a Param declaration is a statement\n//   - components (.x .y .z) are read INLINE on sample(), never on a stored variable\n//   - no Param is named after a built-in (mix, step, ...); no variable named cell/in/norm/snorm/dim\n//   - Param values are not visible inside a function body: pass them as arguments\n\ntm(v, ex) {\n\tt = v / (1.0 + v);\n\treturn pow(t, ex);\n}\n\nParam gain(0.5);\nParam mix_pct(0.0);\nParam expo(0.7);\nParam bypass_gate(0.0);\n\n// `gain` keeps its meaning from the soft-mode era; the sheets branch applies this constant (calibrated against the\n// old soft layer in task T034; 2.0 made the default gain 0.5 equal the look-patch's lev = 1).\nk_sheets = 2.0;\n// expo: the tone curve's exponent -- was a fixed internal constant (0.7, the look-patch default, spec Decisions\n// item 3) until 2026-10-10, now a user Param (lower = highlights compress harder, higher = more contrast).\n\nuv = norm;\n\n// Unconnected-vecfield guard (spec Decisions item 6; probe T008: an unconnected pix inlet reads a constant\n// (0, 0, 0, 1), black WITH alpha 1, so the test must use R and G only). Real vecfields encode zero as 0.5, so a\n// texture that is exactly 0 in R and G at four fixed points is \"no field\": zero the light, keep the source.\nfsum = sample(in3, vec(0.25, 0.25)).x + sample(in3, vec(0.25, 0.25)).y\n     + sample(in3, vec(0.75, 0.25)).x + sample(in3, vec(0.75, 0.25)).y\n     + sample(in3, vec(0.25, 0.75)).x + sample(in3, vec(0.25, 0.75)).y\n     + sample(in3, vec(0.75, 0.75)).x + sample(in3, vec(0.75, 0.75)).y;\npresent = fsum > 0.0;\n\ncaustic_r = tm(sample(in2, uv).x * gain * k_sheets, expo) * present;\ncaustic_g = tm(sample(in2, uv).y * gain * k_sheets, expo) * present;\ncaustic_b = tm(sample(in2, uv).z * gain * k_sheets, expo) * present;\n\ncaustic_out = vec(clamp(caustic_r, 0.0, 1.0),\n                  clamp(caustic_g, 0.0, 1.0),\n                  clamp(caustic_b, 0.0, 1.0),\n                  1.0);\n\nsrc_r = sample(in1, uv).x;\nsrc_g = sample(in1, uv).y;\nsrc_b = sample(in1, uv).z;\n\ncomposite = vec(clamp(src_r + caustic_r, 0.0, 1.0),\n                clamp(src_g + caustic_g, 0.0, 1.0),\n                clamp(src_b + caustic_b, 0.0, 1.0),\n                1.0);\n\nsource_pass = vec(src_r, src_g, src_b, 1.0);\n\nwet = mix(source_pass, composite, mix_pct / 100.0);\nout1 = mix(wet, source_pass, bypass_gate);\nout2 = mix(caustic_out, source_pass, bypass_gate);\n",
                  "numinlets": 3,
                  "numoutlets": 2,
                  "outlettype": [
                    "",
                    ""
                  ],
                  "fontname": "<Monospaced>",
                  "fontsize": 12.0,
                  "id": "gen-obj-4",
                  "patching_rect": [
                    140.0,
                    90.0,
                    100.0,
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
                  "id": "gen-obj-5",
                  "patching_rect": [
                    250.0,
                    90.0,
                    100.0,
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
                  "id": "gen-obj-6",
                  "patching_rect": [
                    30.0,
                    150.0,
                    100.0,
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
                    "gen-obj-4",
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
                    "gen-obj-4",
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
                    2
                  ]
                }
              },
              {
                "patchline": {
                  "source": [
                    "gen-obj-4",
                    0
                  ],
                  "destination": [
                    "gen-obj-5",
                    0
                  ]
                }
              },
              {
                "patchline": {
                  "source": [
                    "gen-obj-4",
                    1
                  ],
                  "destination": [
                    "gen-obj-6",
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
          "id": "obj-951",
          "maxclass": "newobj",
          "text": "prepend param gain",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            560.0,
            450.0,
            130.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-952",
          "maxclass": "newobj",
          "text": "prepend param mix_pct",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            700.0,
            450.0,
            140.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-953",
          "maxclass": "newobj",
          "text": "prepend param bypass_gate",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            850.0,
            450.0,
            160.0,
            22.0
          ]
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "source": [
            "obj-901",
            1
          ],
          "destination": [
            "obj-903",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-902",
            1
          ],
          "destination": [
            "obj-904",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-903",
            0
          ],
          "destination": [
            "obj-905",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-904",
            0
          ],
          "destination": [
            "obj-905",
            1
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-905",
            0
          ],
          "destination": [
            "obj-906",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-907",
            0
          ],
          "destination": [
            "obj-908",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-908",
            0
          ],
          "destination": [
            "obj-901",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-908",
            0
          ],
          "destination": [
            "obj-902",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-911",
            0
          ],
          "destination": [
            "obj-912",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-906",
            0
          ],
          "destination": [
            "obj-912",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            0
          ],
          "destination": [
            "obj-921",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            1
          ],
          "destination": [
            "obj-922",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            2
          ],
          "destination": [
            "obj-923",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            2
          ],
          "destination": [
            "obj-924",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            3
          ],
          "destination": [
            "obj-925",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-921",
            0
          ],
          "destination": [
            "obj-910",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-922",
            0
          ],
          "destination": [
            "obj-910",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-923",
            0
          ],
          "destination": [
            "obj-910",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-924",
            0
          ],
          "destination": [
            "obj-909",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-925",
            0
          ],
          "destination": [
            "obj-911",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-935",
            0
          ],
          "destination": [
            "obj-936",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-936",
            0
          ],
          "destination": [
            "obj-920",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "in0",
            0
          ],
          "destination": [
            "obj-920",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            7
          ],
          "destination": [
            "obj-901",
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
            "obj-902",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            7
          ],
          "destination": [
            "obj-950",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-909",
            0
          ],
          "destination": [
            "obj-950",
            1
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
            "obj-950",
            2
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            4
          ],
          "destination": [
            "obj-951",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            5
          ],
          "destination": [
            "obj-952",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-920",
            6
          ],
          "destination": [
            "obj-953",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-951",
            0
          ],
          "destination": [
            "obj-950",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-952",
            0
          ],
          "destination": [
            "obj-950",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-953",
            0
          ],
          "destination": [
            "obj-950",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "obj-909",
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
            "obj-950",
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
            "obj-950",
            1
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