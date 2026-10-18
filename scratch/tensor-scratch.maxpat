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
        "rect": [ 727.0, 95.0, 1232.0, 902.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-15",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 252.0, 21.0, 220.0, 132.0 ],
                    "varname": "vs_wfg_polarizer",
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
                    "id": "obj-14",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 599.0, 319.0, 112.0, 102.02620087336243 ],
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
                    "id": "obj-23",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_caustic.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 465.0, 469.0, 227.0, 122.0 ],
                    "varname": "f_caustic",
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
                    "id": "obj-22",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_fluid.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 763.0, 399.0, 190.0, 150.0 ],
                    "varname": "f_vf_fluid",
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
                    "name": "vs_camera_fm.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 484.0, 27.0, 129.87, 103.0 ],
                    "varname": "vs_camera_fm",
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
                    "id": "obj-13",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_hatch.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 181.0, 608.0, 190.0, 155.0 ],
                    "varname": "f_tf_hatch",
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
                    "id": "obj-12",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_aniso_blur.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 181.0, 423.0, 229.0, 126.0 ],
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
                    "id": "obj-11",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_sharpen.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 376.0, 717.0, 154.0, 84.0 ],
                    "varname": "f_tf_sharpen",
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
                    "id": "obj-9",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_glyph.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 286.0, 222.0, 186.0, 153.0 ],
                    "varname": "f_tf_glyph",
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
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_smooth.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 763.0, 134.5, 157.0, 89.0 ],
                    "varname": "f_tf_smooth",
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
                    "name": "f_tf_axisflow.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 763.0, 237.0, 154.0, 124.0 ],
                    "varname": "f_tf_axisflow",
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
                    "name": "f_tf_tensormap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 763.0, 33.0, 154.0, 84.0 ],
                    "varname": "f_tf_tensormap",
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
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 18.0, 262.0, 96.0, 380.0 ],
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
                    "patching_rect": [ 1054.0, 697.0, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 1054.0, 784.0, 138.0, 35.0 ],
                    "priority": {
                        "vs_camera_fm::cam2_scale_freq_x": -1,
                        "vs_camera_fm::can2_scale_freq_y": -1,
                        "vs_wfg_polarizer::pm_range": -1,
                        "vs_wfg_polarizer::lock_freq": -1
                    },
                    "saved_object_attributes": {
                        "client_rect": [ 0, 100, 412, 440 ],
                        "parameter_enable": 0,
                        "parameter_mappable": 0,
                        "storage_rect": [ 0, 100, 592, 464 ]
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
                    "patching_rect": [ 953.0, 696.0, 96.85526317358028, 146.5 ],
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
                    "patching_rect": [ 669.0, 608.0, 157.0, 22.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 116.0, 21.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-6", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 1 ],
                    "source": [ "obj-22", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-23", 1 ]
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
                    "destination": [ "obj-14", 0 ],
                    "order": 1,
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-22", 0 ],
                    "order": 2,
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 1 ],
                    "order": 0,
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-9", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-11::obj-20": [ "sharpen", "sharpen", 0 ],
            "obj-12::obj-20": [ "strength_scale", "strength_scale", 0 ],
            "obj-12::obj-23": [ "length", "length", 0 ],
            "obj-12::obj-26": [ "width_gate", "width_gate", 0 ],
            "obj-12::obj-29": [ "floor_pct", "floor_pct", 0 ],
            "obj-12::obj-32": [ "strength[1]", "strength", 0 ],
            "obj-12::obj-35": [ "width[3]", "width", 0 ],
            "obj-12::obj-38": [ "height[3]", "height", 0 ],
            "obj-13::obj-20": [ "density", "density", 0 ],
            "obj-13::obj-23": [ "weight", "weight", 0 ],
            "obj-13::obj-26": [ "softness[1]", "softness", 0 ],
            "obj-13::obj-29": [ "elongation", "elongation", 0 ],
            "obj-13::obj-32": [ "strength[2]", "strength", 0 ],
            "obj-13::obj-35": [ "coherence_gate", "coherence_gate", 0 ],
            "obj-13::obj-38": [ "angle_offset", "angle_offset", 0 ],
            "obj-13::obj-41": [ "phase", "phase", 0 ],
            "obj-13::obj-44": [ "regularity", "regularity", 0 ],
            "obj-15::obj-10": [ "bias", "Bias", 0 ],
            "obj-15::obj-14": [ "bm", "BM", 0 ],
            "obj-15::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-15::obj-22": [ "live.text[6]", "live.text", 0 ],
            "obj-15::obj-29": [ "freq", "Freq", 0 ],
            "obj-15::obj-30": [ "angle[1]", "Angle", 0 ],
            "obj-15::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-15::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-15::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-15::obj-53": [ "speed", "Speed", 0 ],
            "obj-15::obj-54": [ "morph", "Morph", 0 ],
            "obj-15::obj-6": [ "pm", "PM", 0 ],
            "obj-15::obj-65": [ "shape", "Shape", 0 ],
            "obj-15::obj-71": [ "phase[1]", "Phase", 0 ],
            "obj-15::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
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
            "obj-20::obj-11": [ "toggle", "scale_freq_x", 0 ],
            "obj-20::obj-18": [ "can2_scale_freq_y", "scale_freq_y", 0 ],
            "obj-20::obj-19": [ "cam2_on_off", "live.text", 0 ],
            "obj-20::obj-20": [ "cam2_fm_x", "XM", 0 ],
            "obj-20::obj-21": [ "cam2_fm_y", "YM", 0 ],
            "obj-22::obj-20": [ "force", "force", 0 ],
            "obj-22::obj-23": [ "dt[1]", "dt", 0 ],
            "obj-22::obj-26": [ "viscosity", "viscosity", 0 ],
            "obj-22::obj-29": [ "project", "project", 0 ],
            "obj-22::obj-32": [ "drag", "drag", 0 ],
            "obj-22::obj-35": [ "gain[3]", "gain", 0 ],
            "obj-23::obj-20": [ "mix_pct[1]", "mix_pct", 0 ],
            "obj-23::obj-23": [ "gain[4]", "gain", 0 ],
            "obj-23::obj-26": [ "scale", "scale", 0 ],
            "obj-23::obj-29": [ "expo", "expo", 0 ],
            "obj-23::obj-310": [ "range_gain", "range_gain", 0 ],
            "obj-23::obj-32": [ "edge", "edge", 0 ],
            "obj-23::obj-320": [ "range_scale", "range_scale", 0 ],
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
            "obj-6::obj-20": [ "strength", "strength", 0 ],
            "obj-6::obj-23": [ "radius", "radius", 0 ],
            "obj-6::obj-26": [ "width", "width", 0 ],
            "obj-6::obj-29": [ "height", "height", 0 ],
            "obj-7::obj-20": [ "mode", "mode", 0 ],
            "obj-7::obj-23": [ "angle", "angle", 0 ],
            "obj-7::obj-26": [ "gain", "gain", 0 ],
            "obj-7::obj-29": [ "gate", "gate", 0 ],
            "obj-7::obj-32": [ "width[1]", "width", 0 ],
            "obj-7::obj-35": [ "height[1]", "height", 0 ],
            "obj-8::obj-20": [ "release", "release", 0 ],
            "obj-9::obj-20": [ "grid", "grid", 0 ],
            "obj-9::obj-23": [ "glyph_scale", "glyph_scale", 0 ],
            "obj-9::obj-26": [ "thickness", "thickness", 0 ],
            "obj-9::obj-29": [ "softness", "softness", 0 ],
            "obj-9::obj-32": [ "gate[1]", "gate", 0 ],
            "obj-9::obj-35": [ "max_aspect", "max_aspect", 0 ],
            "obj-9::obj-38": [ "width[2]", "width", 0 ],
            "obj-9::obj-41": [ "height[2]", "height", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-11::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "width[3]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-12::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "height[3]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "softness[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "strength[2]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-13::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-15::obj-22": {
                    "parameter_longname": "live.text[6]"
                },
                "obj-15::obj-30": {
                    "parameter_longname": "angle[1]"
                },
                "obj-15::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-15::obj-71": {
                    "parameter_longname": "phase[1]"
                },
                "obj-1::obj-11": {
                    "parameter_longname": "live.text[5]"
                },
                "obj-1::obj-15": {
                    "parameter_longname": "live.tab"
                },
                "obj-1::obj-32": {
                    "parameter_longname": "live.numbox[4]"
                },
                "obj-20::obj-20": {
                    "parameter_range": [ -0.1, 0.1 ]
                },
                "obj-22::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "dt[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-22::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[3]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_pct[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[4]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-23::obj-26": {
                    "parameter_range": [ 0.0, 1.0 ]
                },
                "obj-23::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
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
                "obj-6::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-7::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "width[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "height[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gate[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_longname": "width[2]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_longname": "height[2]",
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