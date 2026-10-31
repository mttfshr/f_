{
    "patcher": {
        "fileversion": 1,
        "appversion": {
            "major": 9,
            "minor": 2,
            "revision": 0,
            "architecture": "x64",
            "modernui": 1
        },
        "classnamespace": "box",
        "rect": [ 72.0, 115.0, 1151.0, 882.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 0,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 105.0, 11.0, 96.0, 420.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 15.0, 6.0, 79.0, 316.0 ],
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
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 829.0, 619.0, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "f_demo_aniso_blur.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 829.0, 706.0, 138.0, 35.0 ],
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
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 728.0, 618.0, 96.85526317358028, 146.5 ],
                    "varname": "vs_render",
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 810.0, 585.0, 157.0, 22.0 ],
                    "varname": "vs_output[1]",
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
                    "name": "vs_camera_s.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 221.0, 181.0, 140.0, 48.0 ],
                    "varname": "vs_camera_s",
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
                    "id": "obj-7",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_tensormap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 234.0, 327.0, 154.0, 84.0 ],
                    "varname": "f_tf_tensormap",
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
                    "id": "obj-30",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_aniso_blur.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 517.0, 176.0, 190.0, 90.0 ],
                    "varname": "f_tf_aniso_blur",
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
                    "id": "obj-31",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_aniso_blur.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 486.0, 390.0, 190.0, 90.0 ],
                    "varname": "f_tf_aniso_blur[1]",
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
                    "id": "obj-32",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 797.0, 107.0, 311.0, 196.0 ],
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
                    "id": "obj-33",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 793.0, 310.0, 319.0, 203.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontsize": 14.0,
                    "id": "obj-40",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 221.0, 8.0, 460.0, 22.0 ],
                    "text": "f_tf_aniso_blur: smooths ALONG edges, not across them"
                }
            },
            {
                "box": {
                    "fontsize": 12.0,
                    "id": "obj-41",
                    "linecount": 4,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 221.0, 36.0, 513.0, 60.0 ],
                    "text": "camera -> tensormap -> aniso_blur (tensor in0), and camera -> aniso_blur (source in1).\nTOP preview / output = A: structure-aligned smoothing.\nBOTTOM preview = B: the plain-blur reference (same Length; Floor 1, Width Gate 0 = circular).\nAt a long Length B turns to mush; A keeps edges crisp and streaks along them."
                }
            },
            {
                "box": {
                    "fontsize": 12.0,
                    "id": "obj-42",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 524.0, 136.0, 238.0, 20.0 ],
                    "text": "A: structure-aligned (Floor 0, Width Gate 1)"
                }
            },
            {
                "box": {
                    "fontsize": 12.0,
                    "id": "obj-43",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 480.0, 359.0, 251.0, 20.0 ],
                    "text": "B: plain blur reference (Floor 1, Width Gate 0)"
                }
            },
            {
                "box": {
                    "fontsize": 12.0,
                    "id": "obj-44",
                    "linecount": 6,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 221.0, 490.0, 490.0, 87.0 ],
                    "text": "Settings (preset slot 1; recall it if the dials did not load):\ntensormap: Radius 6, Strength 100.\naniso_blur: Length 28, Strength 2, Width Gate 1 (A) / 0 (B), Floor 0 (A) / 1 (B),\nT-Map Strength = tensormap's Strength (100): they must match.\nPoint the camera at texture or edges (hair, wood, fabric, text). Flat smooth areas stay\nunblurred at Floor 0, by design. Tensor goes in the FIRST inlet from tensormap OUTLET 0."
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-10", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "order": 0,
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-32", 0 ],
                    "order": 1,
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-31", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-30", 0 ],
                    "order": 1,
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-31", 0 ],
                    "order": 0,
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-30", 1 ],
                    "order": 1,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-31", 1 ],
                    "order": 0,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "order": 2,
                    "source": [ "obj-8", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-1::obj-10": [ "vs_preset_name", "vs_preset_name", 0 ],
            "obj-1::obj-11": [ "live.text[5]", "live.text", 0 ],
            "obj-1::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-1::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-1::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-1::obj-45::obj-16": [ "live.menu[16]", "live.menu[16]", 0 ],
            "obj-1::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-1::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-1::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-1::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-2::obj-19": [ "dim_x", "dim_x", 0 ],
            "obj-2::obj-23": [ "dim_y", "dim_y", 0 ],
            "obj-2::obj-36": [ "live.text", "live.text", 0 ],
            "obj-2::obj-40": [ "live.text[1]", "live.text", 0 ],
            "obj-2::obj-41": [ "dim_y[1]", "dim_y", 0 ],
            "obj-2::obj-42": [ "dim_x[1]", "dim_x", 0 ],
            "obj-2::obj-45": [ "live.text[2]", "live.text", 0 ],
            "obj-2::obj-48": [ "live.text[4]", "live.text", 0 ],
            "obj-2::obj-5": [ "live.text[3]", "live.text", 0 ],
            "obj-2::obj-6": [ "live.text[16]", "live.text", 0 ],
            "obj-30::obj-20": [ "strength_scale[1]", "strength_scale", 0 ],
            "obj-30::obj-23": [ "length[1]", "length", 0 ],
            "obj-30::obj-26": [ "width_gate[1]", "width_gate", 0 ],
            "obj-30::obj-29": [ "floor_pct[1]", "floor_pct", 0 ],
            "obj-30::obj-32": [ "strength[1]", "strength", 0 ],
            "obj-31::obj-20": [ "strength_scale", "strength_scale", 0 ],
            "obj-31::obj-23": [ "length", "length", 0 ],
            "obj-31::obj-26": [ "width_gate", "width_gate", 0 ],
            "obj-31::obj-29": [ "floor_pct", "floor_pct", 0 ],
            "obj-31::obj-32": [ "strength", "strength", 0 ],
            "obj-3::obj-1": [ "toggle[3]", "toggle[1]", 0 ],
            "obj-3::obj-10": [ "toggle[4]", "toggle[2]", 0 ],
            "obj-3::obj-36": [ "uppr_x[1]", "uppr_x", 0 ],
            "obj-4::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-4::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-4::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-4::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-4::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-4::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-4::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-4::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-4::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-4::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-4::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-4::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-4::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-4::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-4::obj-40": [ "f_module_8_disp", "live.menu", 0 ],
            "obj-4::obj-41": [ "f_module_8_file", "live.menu", 0 ],
            "obj-4::obj-44": [ "f_module_9_disp", "live.menu", 0 ],
            "obj-4::obj-45": [ "f_module_9_file", "live.menu", 0 ],
            "obj-4::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-4::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-5::obj-14": [ "live.menu[18]", "live.menu", 0 ],
            "obj-5::obj-16": [ "live.menu[29]", "live.menu", 0 ],
            "obj-5::obj-18": [ "live.menu[33]", "live.menu", 0 ],
            "obj-5::obj-2": [ "live.menu[23]", "live.menu", 0 ],
            "obj-5::obj-22": [ "live.menu[26]", "live.menu", 0 ],
            "obj-5::obj-24": [ "live.menu[31]", "live.menu", 0 ],
            "obj-5::obj-25": [ "live.menu[27]", "live.menu", 0 ],
            "obj-5::obj-26": [ "live.menu[30]", "live.menu", 0 ],
            "obj-5::obj-27": [ "live.menu[28]", "live.menu", 0 ],
            "obj-5::obj-29": [ "live.menu[24]", "live.menu", 0 ],
            "obj-5::obj-30": [ "live.menu[19]", "live.menu", 0 ],
            "obj-5::obj-33": [ "live.menu[32]", "live.menu", 0 ],
            "obj-5::obj-36": [ "live.menu[20]", "live.menu", 0 ],
            "obj-5::obj-52": [ "live.menu[21]", "live.menu", 0 ],
            "obj-5::obj-53": [ "live.menu[22]", "live.menu", 0 ],
            "obj-5::obj-56": [ "live.menu[25]", "live.menu", 0 ],
            "obj-7::obj-20": [ "strength[2]", "strength", 0 ],
            "obj-7::obj-23": [ "radius", "radius", 0 ],
            "obj-8::obj-20": [ "cam_invx", "flip_x", 0 ],
            "obj-8::obj-3": [ "what", "live.text", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-1::obj-11": {
                    "parameter_longname": "live.text[5]"
                },
                "obj-1::obj-15": {
                    "parameter_longname": "live.tab"
                },
                "obj-1::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-2::obj-19": {
                    "parameter_longname": "dim_x"
                },
                "obj-2::obj-23": {
                    "parameter_longname": "dim_y",
                    "parameter_shortname": "dim_y"
                },
                "obj-2::obj-36": {
                    "parameter_longname": "live.text"
                },
                "obj-2::obj-40": {
                    "parameter_longname": "live.text[1]"
                },
                "obj-2::obj-41": {
                    "parameter_longname": "dim_y[1]"
                },
                "obj-2::obj-42": {
                    "parameter_longname": "dim_x[1]"
                },
                "obj-2::obj-45": {
                    "parameter_longname": "live.text[2]"
                },
                "obj-2::obj-48": {
                    "parameter_longname": "live.text[4]"
                },
                "obj-2::obj-5": {
                    "parameter_longname": "live.text[3]"
                },
                "obj-2::obj-6": {
                    "parameter_longname": "live.text[16]"
                },
                "obj-30::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength_scale[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-30::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "length[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-30::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "width_gate[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-30::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_longname": "floor_pct[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-30::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-31::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-14": {
                    "parameter_longname": "live.menu[18]"
                },
                "obj-5::obj-16": {
                    "parameter_longname": "live.menu[29]"
                },
                "obj-5::obj-18": {
                    "parameter_longname": "live.menu[33]"
                },
                "obj-5::obj-2": {
                    "parameter_longname": "live.menu[23]"
                },
                "obj-5::obj-22": {
                    "parameter_longname": "live.menu[26]"
                },
                "obj-5::obj-24": {
                    "parameter_longname": "live.menu[31]"
                },
                "obj-5::obj-25": {
                    "parameter_longname": "live.menu[27]"
                },
                "obj-5::obj-26": {
                    "parameter_longname": "live.menu[30]"
                },
                "obj-5::obj-27": {
                    "parameter_longname": "live.menu[28]"
                },
                "obj-5::obj-29": {
                    "parameter_longname": "live.menu[24]"
                },
                "obj-5::obj-30": {
                    "parameter_longname": "live.menu[19]"
                },
                "obj-5::obj-33": {
                    "parameter_longname": "live.menu[32]"
                },
                "obj-5::obj-36": {
                    "parameter_longname": "live.menu[20]"
                },
                "obj-5::obj-52": {
                    "parameter_longname": "live.menu[21]"
                },
                "obj-5::obj-53": {
                    "parameter_longname": "live.menu[22]"
                },
                "obj-5::obj-56": {
                    "parameter_longname": "live.menu[25]"
                },
                "obj-7::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[2]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0,
        "boxgroups": [
            {
                "boxes": [ "obj-1", "obj-10" ]
            }
        ]
    }
}