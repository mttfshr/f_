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
        "rect": [ 426.0, 95.0, 1268.0, 877.0 ],
        "boxes": [
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
                    "name": "f_wc.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 211.0, 88.0, 272.0, 150.0 ],
                    "varname": "f_wc",
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
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 690.0, 118.0, 97.0, 146.0 ],
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
                    "id": "obj-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_optical_flow.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 200.0, 296.0, 195.0, 149.0 ],
                    "varname": "f_vf_optical_flow",
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
                    "name": "f_vf_fluid.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 410.0, 296.0, 195.0, 166.0 ],
                    "varname": "f_vf_fluid",
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
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 410.0, 496.0, 190.0, 150.0 ],
                    "varname": "f_vf_advect",
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
                    "patching_rect": [ 388.0, 702.0, 157.0, 22.0 ],
                    "varname": "vs_output",
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-6", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 1 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "source": [ "obj-7", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "order": 1,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-7", 0 ],
                    "order": 0,
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
            "obj-5::obj-20": [ "scale", "scale", 0 ],
            "obj-5::obj-23": [ "gain[2]", "gain", 0 ],
            "obj-5::obj-26": [ "mask_lo", "mask_lo", 0 ],
            "obj-5::obj-29": [ "mask_hi", "mask_hi", 0 ],
            "obj-5::obj-32": [ "decay[1]", "decay", 0 ],
            "obj-5::obj-35": [ "injection[1]", "injection", 0 ],
            "obj-5::obj-38": [ "step", "step", 0 ],
            "obj-5::obj-41": [ "reach", "reach", 0 ],
            "obj-5::obj-44": [ "mix_pct[1]", "mix_pct", 0 ],
            "obj-6::obj-20": [ "force", "force", 0 ],
            "obj-6::obj-23": [ "dt[1]", "dt", 0 ],
            "obj-6::obj-26": [ "viscosity", "viscosity", 0 ],
            "obj-6::obj-29": [ "project", "project", 0 ],
            "obj-6::obj-32": [ "drag", "drag", 0 ],
            "obj-6::obj-35": [ "gain[1]", "gain", 0 ],
            "obj-6::obj-38": [ "drift", "drift", 0 ],
            "obj-7::obj-20": [ "dt", "dt", 0 ],
            "obj-7::obj-23": [ "decay", "decay", 0 ],
            "obj-7::obj-26": [ "injection", "injection", 0 ],
            "obj-7::obj-29": [ "gain", "gain", 0 ],
            "obj-7::obj-32": [ "mix_pct", "mix_pct", 0 ],
            "obj-7::obj-35": [ "separate", "separate", 0 ],
            "obj-7::obj-38": [ "mode", "mode", 0 ],
            "obj-7::obj-41": [ "trail", "trail", 0 ],
            "obj-8::obj-19a": [ "freeze_on", "freeze_on", 0 ],
            "obj-8::obj-20": [ "pulse_depth", "pulse_depth", 0 ],
            "obj-8::obj-23": [ "pulse_period", "pulse_period", 0 ],
            "obj-8::obj-26": [ "sim_rate", "sim_rate", 0 ],
            "obj-8::obj-29": [ "pulse_mix", "pulse_mix", 0 ],
            "obj-8::obj-32": [ "pulse_gain", "pulse_gain", 0 ],
            "obj-8::obj-35": [ "grain_scale", "grain_scale", 0 ],
            "obj-8::obj-38": [ "out_mode", "out_mode", 0 ],
            "obj-8::obj-41": [ "pulse_space", "pulse_space", 0 ],
            "obj-8::obj-44": [ "out_view", "out_view", 0 ],
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
                    "parameter_longname": "gain[2]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_longname": "decay[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "injection[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-5::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_longname": "mix_pct[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
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
                    "parameter_longname": "dt[1]",
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
                "obj-6::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[1]",
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-6::obj-38": {
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
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-7::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-19a": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-26": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-29": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-8::obj-38": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-8::obj-41": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-8::obj-44": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}