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
        "rect": [ 426.0, 106.0, 1268.0, 877.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 244.0, 26.0, 97.0, 146.0 ],
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
                    "id": "obj-2",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 14.0, 79.0, 316.0 ],
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
                    "id": "obj-3",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 344.0, 96.0, 380.0 ],
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
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_camera_s.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 128.0, 232.0, 150.0, 110.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_tensormap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 288.0, 421.0, 170.0, 110.0 ],
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
                    "id": "obj-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_tf_axisflow.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 688.0, 393.0, 170.0, 100.0 ],
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
                    "id": "obj-7",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_weave.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 450.0, 40.0, 232.0, 180.0 ],
                    "varname": "f_weave",
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
                    "name": "f_vf_warp.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 547.0, 641.0, 91.0, 94.0 ],
                    "varname": "f_vf_warp",
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
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 541.0, 802.0, 157.0, 22.0 ],
                    "varname": "vs_output",
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-6", 0 ],
                    "source": [ "obj-5", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 1 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-8", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-1::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-1::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-1::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-1::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-1::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-1::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-1::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-1::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-1::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-1::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-2::obj-14": [ "live.menu[30]", "live.menu", 0 ],
            "obj-2::obj-16": [ "live.menu[31]", "live.menu", 0 ],
            "obj-2::obj-18": [ "live.menu[32]", "live.menu", 0 ],
            "obj-2::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-2::obj-22": [ "live.menu[33]", "live.menu", 0 ],
            "obj-2::obj-24": [ "live.menu[9]", "live.menu", 0 ],
            "obj-2::obj-25": [ "live.menu[10]", "live.menu", 0 ],
            "obj-2::obj-26": [ "live.menu[11]", "live.menu", 0 ],
            "obj-2::obj-27": [ "live.menu[12]", "live.menu", 0 ],
            "obj-2::obj-29": [ "live.menu[13]", "live.menu", 0 ],
            "obj-2::obj-30": [ "live.menu[14]", "live.menu", 0 ],
            "obj-2::obj-33": [ "live.menu[15]", "live.menu", 0 ],
            "obj-2::obj-36": [ "live.menu[3]", "live.menu", 0 ],
            "obj-2::obj-52": [ "live.menu[4]", "live.menu", 0 ],
            "obj-2::obj-53": [ "live.menu[5]", "live.menu", 0 ],
            "obj-2::obj-56": [ "live.menu[6]", "live.menu", 0 ],
            "obj-3::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-3::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-3::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-3::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-3::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-3::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-3::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-3::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-3::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-3::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-3::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-3::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-3::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-3::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-3::obj-40": [ "f_module_8_disp", "live.menu", 0 ],
            "obj-3::obj-41": [ "f_module_8_file", "live.menu", 0 ],
            "obj-3::obj-44": [ "f_module_9_disp", "live.menu", 0 ],
            "obj-3::obj-45": [ "f_module_9_file", "live.menu", 0 ],
            "obj-3::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-3::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-4::obj-20": [ "cam_invx", "flip_x", 0 ],
            "obj-4::obj-3": [ "what", "live.text", 0 ],
            "obj-5::obj-20": [ "strength", "strength", 0 ],
            "obj-5::obj-23": [ "radius", "radius", 0 ],
            "obj-6::obj-20": [ "mode", "mode", 0 ],
            "obj-6::obj-23": [ "angle[1]", "angle", 0 ],
            "obj-6::obj-26": [ "gain[1]", "gain", 0 ],
            "obj-6::obj-29": [ "gate", "gate", 0 ],
            "obj-7::obj-20": [ "density", "density", 0 ],
            "obj-7::obj-23": [ "angle", "angle", 0 ],
            "obj-7::obj-26": [ "weight", "weight", 0 ],
            "obj-7::obj-29": [ "marklen", "marklen", 0 ],
            "obj-7::obj-32": [ "offset", "offset", 0 ],
            "obj-7::obj-35": [ "phase", "phase", 0 ],
            "obj-7::obj-38": [ "softness", "softness", 0 ],
            "obj-7::obj-41": [ "variant", "variant", 0 ],
            "obj-7::obj-44": [ "irreg", "irreg", 0 ],
            "obj-7::obj-47": [ "nscale", "nscale", 0 ],
            "obj-7::obj-50": [ "weight_m", "weight_m", 0 ],
            "obj-7::obj-53": [ "irreg_m", "irreg_m", 0 ],
            "obj-7::obj-56": [ "marklen_m", "marklen_m", 0 ],
            "obj-7::obj-59": [ "mmode", "mmode", 0 ],
            "obj-8::obj-20": [ "gain", "gain", 0 ],
            "obj-8::obj-23": [ "mix_pct", "mix_pct", 0 ],
            "obj-9::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-9::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-9::obj-36": [ "uppr_x", "uppr_x", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "parameter_overrides": {
                "obj-5::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-6::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_longname": "angle[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[1]",
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
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-7::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-47": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-50": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-53": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-56": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-7::obj-59": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
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
                "obj-8::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}