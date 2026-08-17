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
        "rect": [ 112.0, 111.0, 970.0, 876.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_stereo.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 163.0, 703.0, 160.0, 90.0 ],
                    "varname": "f_stereo",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-26",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 117.0, 488.5, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "seeds2.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 117.0, 575.5, 138.0, 35.0 ],
                    "priority": {
                        "vs_wfg_3::wfg3_freq_range": -1,
                        "vs_wfg_3::wfg3_fm_range": -1,
                        "vs_wfg_3::wfg3_pm_range": -1,
                        "vs_wfg_3[1]::wfg3_freq_range": -1,
                        "vs_wfg_3[1]::wfg3_fm_range": -1,
                        "vs_wfg_3[1]::wfg3_pm_range": -1,
                        "vs_wfg_3[2]::wfg3_freq_range": -1,
                        "vs_wfg_3[2]::wfg3_fm_range": -1,
                        "vs_wfg_3[2]::wfg3_pm_range": -1
                    },
                    "saved_object_attributes": {
                        "client_rect": [ 854, 172, 1208, 300 ],
                        "parameter_enable": 0,
                        "parameter_mappable": 0,
                        "storage_rect": [ 766, 44, 1220, 302 ]
                    },
                    "text": "pattrstorage @greedy 1 @changemode 1",
                    "varname": "Vsynth"
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-25",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_cos_palettes.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 158.0, 355.9342105263158, 113.0, 44.13157894736842 ],
                    "varname": "vs_cos_palettes",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-24",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_repulse.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 265.0, 228.0, 165.0, 80.0 ],
                    "varname": "f_vf_repulse",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-23",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 821.0, 134.0131004366812, 178.0, 132.0 ],
                    "varname": "vs_wfg_3[2]",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-22",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 710.0, 4.0, 178.0, 132.0 ],
                    "varname": "vs_wfg_3[1]",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-20",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 563.0, 141.0, 112.0, 102.02620087336243 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "jit_gl_texture", "" ],
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
                        "rect": [ 84.0, 139.0, 1100.0, 700.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 50.0, 14.0, 28.0, 22.0 ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "code": "Param n_mirrors(6.0);\nParam bypass(0.0);\n\ntheta = pi / n_mirrors;\n\nzx = snorm.x;\nzy = snorm.y;\n\nfor (i = 0; i < 32; i += 1) {\n    test0 = step(zy, 0.0);\n    crossTheta = zx*sin(theta) - zy*cos(theta);\n    test1 = step(crossTheta, 0.0);\n\n    ct = cos(2.0*theta);\n    st = sin(2.0*theta);\n\n    newzx0 = zx;\n    newzy0 = 0.0 - zy;\n    newzx1 = ct*zx + st*zy;\n    newzy1 = st*zx - ct*zy;\n\n    zx, zy = mix(mix(zx, newzx1, test1), newzx0, test0),\n              mix(mix(zy, newzy1, test1), newzy0, test0);\n}\n\nuv_x = clamp(zx*0.5+0.5, 0.0, 1.0);\nuv_y = clamp(zy*0.5+0.5, 0.0, 1.0);\n\neffect_out = sample(in1, vec(uv_x, uv_y));\nout1 = mix(effect_out, sample(in1, norm), bypass);",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "obj-3",
                                    "maxclass": "codebox",
                                    "numinlets": 1,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 50.0, 46.0, 900.0, 500.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-4",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 59.0, 560.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "obj-3", 0 ],
                                    "source": [ "obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "obj-4", 0 ],
                                    "source": [ "obj-3", 0 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 477.0, 114.0, 174.0, 22.0 ],
                    "text": "jit.gl.pix @name poincare_pix"
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-12",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 246.0, 27.0, 178.0, 132.0 ],
                    "varname": "vs_wfg_3",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "attr": "bypass",
                    "id": "obj-14",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 516.0, 56.0, 150.0, 22.0 ]
                }
            },
            {
                "box": {
                    "attr": "n_mirrors",
                    "id": "obj-15",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 516.0, 86.0, 150.0, 22.0 ]
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-18",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_weave.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 682.0, 303.0, 225.0, 150.0 ],
                    "varname": "f_weave",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-13",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 666.0, 552.0, 193.0, 181.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 495.0, 252.0, 112.0, 102.02620087336243 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-9",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 516.0, 712.0, 112.0, 102.02620087336243 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 342.0, 707.0, 112.0, 102.02620087336243 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_seeds.maxpat",
                    "numinlets": 4,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 310.0, 411.0, 197.0, 222.0 ],
                    "varname": "f_vf_seeds",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-17",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 183.0, 815.0, 157.0, 22.0 ],
                    "varname": "vs_output",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-21",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 14.0, 330.0, 101.0, 383.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 99.0, 4.0, 96.85526317358028, 146.5 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 14.0, 4.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "order": 2,
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "order": 1,
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-6", 2 ],
                    "order": 0,
                    "source": [ "obj-18", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 2 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-18", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "order": 1,
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-6", 1 ],
                    "order": 0,
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-6", 0 ],
                    "source": [ "obj-25", 1 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "order": 1,
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-25", 0 ],
                    "order": 0,
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-6", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-6", 2 ]
                }
            }
        ],
        "parameters": {
            "obj-12::obj-10": [ "wfg3_bias", "Bias", 0 ],
            "obj-12::obj-14": [ "wfg3_biasm", "BM", 0 ],
            "obj-12::obj-17": [ "live.menu[22]", "live.menu", 0 ],
            "obj-12::obj-22": [ "live.toggle[1]", "live.toggle[1]", 0 ],
            "obj-12::obj-24": [ "live.toggle", "live.toggle", 0 ],
            "obj-12::obj-25": [ "wfg3_curve", "curve", 0 ],
            "obj-12::obj-29": [ "wfg3_freq", "Freq", 0 ],
            "obj-12::obj-30": [ "wfg3_angle", "Angle", 0 ],
            "obj-12::obj-4": [ "wfg3_fm", "FM", 0 ],
            "obj-12::obj-42": [ "live.toggle[5]", "live.toggle", 0 ],
            "obj-12::obj-53": [ "wfg3_speed", "Speed", 0 ],
            "obj-12::obj-6": [ "wfg3_pm", "PM", 0 ],
            "obj-12::obj-63": [ "wfg3_phase", "Phase", 0 ],
            "obj-12::obj-65": [ "wfg3_shape", "Shape", 0 ],
            "obj-12::obj-72": [ "wfg3_phase_time_switch", "wfg2_phase_time_switch", 0 ],
            "obj-17::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-17::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-17::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "obj-18::obj-20": [ "density[1]", "density", 0 ],
            "obj-18::obj-23": [ "angle[4]", "angle", 0 ],
            "obj-18::obj-26": [ "weight", "weight", 0 ],
            "obj-18::obj-29": [ "marklen", "marklen", 0 ],
            "obj-18::obj-32": [ "regularity", "regularity", 0 ],
            "obj-18::obj-35": [ "phase[4]", "phase", 0 ],
            "obj-18::obj-50": [ "softness", "softness", 0 ],
            "obj-18::obj-53": [ "shape[3]", "shape", 0 ],
            "obj-1::obj-14": [ "live.menu[1]", "live.menu", 0 ],
            "obj-1::obj-16": [ "live.menu[2]", "live.menu", 0 ],
            "obj-1::obj-18": [ "live.menu[16]", "live.menu", 0 ],
            "obj-1::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-1::obj-22": [ "live.menu[17]", "live.menu", 0 ],
            "obj-1::obj-24": [ "live.menu[9]", "live.menu", 0 ],
            "obj-1::obj-25": [ "live.menu[10]", "live.menu", 0 ],
            "obj-1::obj-26": [ "live.menu[11]", "live.menu", 0 ],
            "obj-1::obj-27": [ "live.menu[12]", "live.menu", 0 ],
            "obj-1::obj-29": [ "live.menu[13]", "live.menu", 0 ],
            "obj-1::obj-30": [ "live.menu[14]", "live.menu", 0 ],
            "obj-1::obj-33": [ "live.menu[15]", "live.menu", 0 ],
            "obj-1::obj-36": [ "live.menu[3]", "live.menu", 0 ],
            "obj-1::obj-52": [ "live.menu[4]", "live.menu", 0 ],
            "obj-1::obj-53": [ "live.menu[5]", "live.menu", 0 ],
            "obj-1::obj-56": [ "live.menu[6]", "live.menu", 0 ],
            "obj-21::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-21::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-21::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-21::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-21::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-21::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-21::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-21::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-21::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-21::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-21::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-21::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-21::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-21::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-21::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-21::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-22::obj-10": [ "wfg3_bias[1]", "Bias", 0 ],
            "obj-22::obj-14": [ "wfg3_biasm[1]", "BM", 0 ],
            "obj-22::obj-17": [ "live.menu[19]", "live.menu", 0 ],
            "obj-22::obj-22": [ "live.toggle[7]", "live.toggle[1]", 0 ],
            "obj-22::obj-24": [ "live.toggle[6]", "live.toggle", 0 ],
            "obj-22::obj-25": [ "wfg3_curve[1]", "curve", 0 ],
            "obj-22::obj-29": [ "wfg3_freq[1]", "Freq", 0 ],
            "obj-22::obj-30": [ "wfg3_angle[1]", "Angle", 0 ],
            "obj-22::obj-4": [ "wfg3_fm[1]", "FM", 0 ],
            "obj-22::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-22::obj-53": [ "wfg3_speed[1]", "Speed", 0 ],
            "obj-22::obj-6": [ "wfg3_pm[1]", "PM", 0 ],
            "obj-22::obj-63": [ "wfg3_phase[1]", "Phase", 0 ],
            "obj-22::obj-65": [ "wfg3_shape[1]", "Shape", 0 ],
            "obj-22::obj-72": [ "wfg3_phase_time_switch[1]", "wfg2_phase_time_switch", 0 ],
            "obj-23::obj-10": [ "wfg3_bias[2]", "Bias", 0 ],
            "obj-23::obj-14": [ "wfg3_biasm[2]", "BM", 0 ],
            "obj-23::obj-17": [ "live.menu[23]", "live.menu", 0 ],
            "obj-23::obj-22": [ "live.toggle[9]", "live.toggle[1]", 0 ],
            "obj-23::obj-24": [ "live.toggle[10]", "live.toggle", 0 ],
            "obj-23::obj-25": [ "wfg3_curve[2]", "curve", 0 ],
            "obj-23::obj-29": [ "wfg3_freq[2]", "Freq", 0 ],
            "obj-23::obj-30": [ "wfg3_angle[2]", "Angle", 0 ],
            "obj-23::obj-4": [ "wfg3_fm[2]", "FM", 0 ],
            "obj-23::obj-42": [ "live.toggle[8]", "live.toggle", 0 ],
            "obj-23::obj-53": [ "wfg3_speed[2]", "Speed", 0 ],
            "obj-23::obj-6": [ "wfg3_pm[2]", "PM", 0 ],
            "obj-23::obj-63": [ "wfg3_phase[2]", "Phase", 0 ],
            "obj-23::obj-65": [ "wfg3_shape[2]", "Shape", 0 ],
            "obj-23::obj-72": [ "wfg3_phase_time_switch[2]", "wfg2_phase_time_switch", 0 ],
            "obj-24::obj-20": [ "gain", "gain", 0 ],
            "obj-24::obj-23": [ "reach", "reach", 0 ],
            "obj-24::obj-26": [ "threshold", "threshold", 0 ],
            "obj-24::obj-29": [ "mode", "mode", 0 ],
            "obj-25::obj-13": [ "vs_cp_menu", "live.menu", 0 ],
            "obj-25::obj-26": [ "live.arrows[1]", "live.arrows", 0 ],
            "obj-25::obj-8": [ "vs_cp_mode", "Mode", 0 ],
            "obj-26::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-26::obj-11": [ "live.text", "live.text", 0 ],
            "obj-26::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-26::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-26::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-26::obj-45::obj-16": [ "live.menu[24]", "live.menu[16]", 0 ],
            "obj-26::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-26::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-26::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-26::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-2::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-2::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-2::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-2::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-2::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-2::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-2::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-2::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-2::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-2::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-5::obj-10": [ "lon", "lon", 0 ],
            "obj-5::obj-12": [ "lat", "lat", 0 ],
            "obj-5::obj-14": [ "spin", "spin", 0 ],
            "obj-5::obj-16": [ "proj", "proj", 0 ],
            "obj-5::obj-32": [ "circ", "circ", 0 ],
            "obj-6::obj-200": [ "density", "density", 0 ],
            "obj-6::obj-203": [ "jitter", "jitter", 0 ],
            "obj-6::obj-206": [ "size", "size", 0 ],
            "obj-6::obj-209": [ "stretch", "stretch", 0 ],
            "obj-6::obj-212": [ "strength", "strength", 0 ],
            "obj-6::obj-215": [ "mag_weight", "mag_weight", 0 ],
            "obj-6::obj-218": [ "field_priority", "field_priority", 0 ],
            "obj-6::obj-221": [ "field_gain", "field_gain", 0 ],
            "obj-6::obj-224": [ "bomb", "bomb", 0 ],
            "obj-6::obj-227": [ "phase[2]", "phase", 0 ],
            "obj-6::obj-230": [ "size_mod", "size_mod", 0 ],
            "obj-6::obj-233": [ "stretch_mod", "stretch_mod", 0 ],
            "obj-6::obj-236": [ "color_mode", "color_mode", 0 ],
            "obj-6::obj-470": [ "range_field_gain", "range_field_gain", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-12::obj-17": {
                    "parameter_longname": "live.menu[22]"
                },
                "obj-12::obj-29": {
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-12::obj-4": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-12::obj-42": {
                    "parameter_longname": "live.toggle[5]"
                },
                "obj-12::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-18::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "density[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "density",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "angle[4]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "angle",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "phase[4]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "phase",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-50": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-18::obj-53": {
                    "parameter_invisible": 0,
                    "parameter_longname": "shape[3]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "shape",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-1::obj-14": {
                    "parameter_longname": "live.menu[1]"
                },
                "obj-1::obj-16": {
                    "parameter_longname": "live.menu[2]"
                },
                "obj-1::obj-18": {
                    "parameter_longname": "live.menu[16]"
                },
                "obj-1::obj-22": {
                    "parameter_longname": "live.menu[17]"
                },
                "obj-22::obj-10": {
                    "parameter_longname": "wfg3_bias[1]"
                },
                "obj-22::obj-14": {
                    "parameter_longname": "wfg3_biasm[1]"
                },
                "obj-22::obj-22": {
                    "parameter_longname": "live.toggle[7]"
                },
                "obj-22::obj-24": {
                    "parameter_longname": "live.toggle[6]"
                },
                "obj-22::obj-25": {
                    "parameter_longname": "wfg3_curve[1]"
                },
                "obj-22::obj-29": {
                    "parameter_longname": "wfg3_freq[1]",
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-22::obj-30": {
                    "parameter_longname": "wfg3_angle[1]"
                },
                "obj-22::obj-4": {
                    "parameter_longname": "wfg3_fm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-22::obj-53": {
                    "parameter_longname": "wfg3_speed[1]"
                },
                "obj-22::obj-6": {
                    "parameter_longname": "wfg3_pm[1]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-22::obj-63": {
                    "parameter_longname": "wfg3_phase[1]"
                },
                "obj-22::obj-65": {
                    "parameter_longname": "wfg3_shape[1]"
                },
                "obj-22::obj-72": {
                    "parameter_longname": "wfg3_phase_time_switch[1]"
                },
                "obj-23::obj-10": {
                    "parameter_longname": "wfg3_bias[2]"
                },
                "obj-23::obj-14": {
                    "parameter_longname": "wfg3_biasm[2]"
                },
                "obj-23::obj-17": {
                    "parameter_longname": "live.menu[23]"
                },
                "obj-23::obj-22": {
                    "parameter_longname": "live.toggle[9]"
                },
                "obj-23::obj-24": {
                    "parameter_longname": "live.toggle[10]"
                },
                "obj-23::obj-25": {
                    "parameter_longname": "wfg3_curve[2]"
                },
                "obj-23::obj-29": {
                    "parameter_longname": "wfg3_freq[2]",
                    "parameter_range": [ 0.0, 1020.0 ]
                },
                "obj-23::obj-30": {
                    "parameter_longname": "wfg3_angle[2]"
                },
                "obj-23::obj-4": {
                    "parameter_longname": "wfg3_fm[2]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-23::obj-42": {
                    "parameter_longname": "live.toggle[8]"
                },
                "obj-23::obj-53": {
                    "parameter_longname": "wfg3_speed[2]"
                },
                "obj-23::obj-6": {
                    "parameter_longname": "wfg3_pm[2]",
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-23::obj-63": {
                    "parameter_longname": "wfg3_phase[2]"
                },
                "obj-23::obj-65": {
                    "parameter_longname": "wfg3_shape[2]"
                },
                "obj-23::obj-72": {
                    "parameter_longname": "wfg3_phase_time_switch[2]"
                },
                "obj-24::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-24::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-26::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-26::obj-45::obj-16": {
                    "parameter_longname": "live.menu[24]"
                },
                "obj-5::obj-10": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-12": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-14": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-16": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-221": {
                    "parameter_range": [ 0.0, 0.2 ]
                },
                "obj-6::obj-227": {
                    "parameter_longname": "phase[2]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-26", "obj-10" ]
            }
        ]
    }
}