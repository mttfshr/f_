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
        "rect": [ 88.0, 95.0, 1000.0, 780.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-15",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_fieldmap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 454.0, 40.0, 165.0, 103.0 ],
                    "varname": "f_vf_fieldmap",
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
                    "name": "vs_camera_fm.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 733.0, 40.0, 129.87, 103.0 ],
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
                    "id": "obj-9",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_advect.maxpat",
                    "numinlets": 2,
                    "numoutlets": 3,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 610.0, 431.0, 197.0, 154.0 ],
                    "varname": "f_vf_advect",
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
                    "id": "obj-8",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_fluid.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 552.0, 241.0, 198.0, 150.0 ],
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
                    "id": "obj-6",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 228.0, 53.0, 96.85526317358028, 146.5 ],
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
                    "name": "vsc_presets.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "" ],
                    "patching_rect": [ 886.0, 538.0, 170.0, 144.5 ],
                    "varname": "vs_presets",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "autorestore": "fluid-scratch.json",
                    "hidden": 1,
                    "id": "obj-10",
                    "linecount": 2,
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 886.0, 625.0, 138.0, 35.0 ],
                    "presentation_linecount": 2,
                    "priority": {
                        "vs_wfg_s::wfg_fm_range": -1,
                        "vs_wfg_s::wfg_freq_range": -1,
                        "vs_wfg_rad::radwfg_freq_60mult": -1,
                        "vs_wfg_rad::radwfg_fm_range": -1,
                        "vs_wfg_rad::radwfg_freq_range": -1,
                        "vs_wfg_polarizer::pm_range": -1,
                        "vs_wfg_polarizer::lock_freq": -1,
                        "vs_camera_fm::cam2_scale_freq_x": -1,
                        "vs_camera_fm::can2_scale_freq_y": -1
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
                    "id": "obj-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 378.0, 527.0, 157.0, 22.0 ],
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
                    "patching_rect": [ 143.0, 53.0, 79.0, 316.0 ],
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
                    "id": "obj-1",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 32.0, 53.0, 96.0, 380.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "order": 0,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 0 ],
                    "order": 1,
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "color": [ 0.65, 0.65, 0.65, 0.0 ],
                    "destination": [ "obj-10", 0 ],
                    "hidden": 1,
                    "source": [ "obj-2", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-9", 1 ],
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-9", 1 ]
                }
            }
        ],
        "parameters": {
            "obj-14::obj-11": [ "toggle", "scale_freq_x", 0 ],
            "obj-14::obj-18": [ "can2_scale_freq_y", "scale_freq_y", 0 ],
            "obj-14::obj-19": [ "cam2_on_off", "live.text", 0 ],
            "obj-14::obj-20": [ "cam2_fm_x", "XM", 0 ],
            "obj-14::obj-21": [ "cam2_fm_y", "YM", 0 ],
            "obj-15::obj-20": [ "gain[2]", "gain", 0 ],
            "obj-15::obj-23": [ "scale", "scale", 0 ],
            "obj-15::obj-28": [ "rotate", "rotate", 0 ],
            "obj-15::obj-31": [ "thresh", "thresh", 0 ],
            "obj-1::obj-12": [ "f_module_1_disp", "live.menu", 0 ],
            "obj-1::obj-13": [ "f_module_1_file", "live.menu", 0 ],
            "obj-1::obj-16": [ "f_module_2_disp", "live.menu", 0 ],
            "obj-1::obj-17": [ "f_module_2_file", "live.menu", 0 ],
            "obj-1::obj-20": [ "f_module_3_disp", "live.menu", 0 ],
            "obj-1::obj-21": [ "f_module_3_file", "live.menu", 0 ],
            "obj-1::obj-24": [ "f_module_4_disp", "live.menu", 0 ],
            "obj-1::obj-25": [ "f_module_4_file", "live.menu", 0 ],
            "obj-1::obj-28": [ "f_module_5_disp", "live.menu", 0 ],
            "obj-1::obj-29": [ "f_module_5_file", "live.menu", 0 ],
            "obj-1::obj-32": [ "f_module_6_disp", "live.menu", 0 ],
            "obj-1::obj-33": [ "f_module_6_file", "live.menu", 0 ],
            "obj-1::obj-36": [ "f_module_7_disp", "live.menu", 0 ],
            "obj-1::obj-37": [ "f_module_7_file", "live.menu", 0 ],
            "obj-1::obj-8": [ "f_module_0_disp", "live.menu", 0 ],
            "obj-1::obj-9": [ "f_module_0_file", "live.menu", 0 ],
            "obj-2::obj-10": [ "textedit", "vs_preset_name", 0 ],
            "obj-2::obj-11": [ "live.text", "live.text", 0 ],
            "obj-2::obj-15": [ "live.tab", "live.tab", 0 ],
            "obj-2::obj-32": [ "live.numbox[4]", "live.numbox", 0 ],
            "obj-2::obj-44": [ "live.tab[3]", "live.tab", 0 ],
            "obj-2::obj-45::obj-16": [ "live.menu[16]", "live.menu[16]", 0 ],
            "obj-2::obj-45::obj-17": [ "live.button", "live.button", 0 ],
            "obj-2::obj-45::obj-19": [ "live.numbox[2]", "live.numbox[1]", 0 ],
            "obj-2::obj-45::obj-32": [ "live.numbox", "live.numbox", 0 ],
            "obj-2::obj-45::obj-9": [ "live.numbox[3]", "live.numbox", 0 ],
            "obj-4::obj-1": [ "toggle[1]", "toggle[1]", 0 ],
            "obj-4::obj-10": [ "toggle[3]", "toggle[2]", 0 ],
            "obj-4::obj-36": [ "uppr_x", "uppr_x", 0 ],
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
            "obj-6::obj-19": [ "dim_x[2]", "dim_x", 0 ],
            "obj-6::obj-23": [ "pwm[1]", "pwm", 0 ],
            "obj-6::obj-36": [ "live.text[11]", "live.text", 0 ],
            "obj-6::obj-40": [ "live.text[6]", "live.text", 0 ],
            "obj-6::obj-41": [ "dim_y[2]", "dim_y", 0 ],
            "obj-6::obj-42": [ "dim_x[3]", "dim_x", 0 ],
            "obj-6::obj-45": [ "live.text[10]", "live.text", 0 ],
            "obj-6::obj-48": [ "live.text[7]", "live.text", 0 ],
            "obj-6::obj-5": [ "live.text[9]", "live.text", 0 ],
            "obj-6::obj-6": [ "live.text[8]", "live.text", 0 ],
            "obj-8::obj-20": [ "force", "force", 0 ],
            "obj-8::obj-23": [ "dt", "dt", 0 ],
            "obj-8::obj-26": [ "viscosity", "viscosity", 0 ],
            "obj-8::obj-29": [ "project", "project", 0 ],
            "obj-8::obj-32": [ "drag", "drag", 0 ],
            "obj-8::obj-35": [ "gain", "gain", 0 ],
            "obj-9::obj-20": [ "dt[1]", "dt", 0 ],
            "obj-9::obj-23": [ "decay", "decay", 0 ],
            "obj-9::obj-26": [ "injection", "injection", 0 ],
            "obj-9::obj-29": [ "gain[1]", "gain", 0 ],
            "obj-9::obj-32": [ "separate", "separate", 0 ],
            "obj-9::obj-35": [ "mode", "mode", 0 ],
            "obj-9::obj-90": [ "mix_pct", "mix_pct", 0 ],
            "parameter_overrides": {
                "obj-14::obj-20": {
                    "parameter_range": [ -0.1, 0.1 ]
                },
                "obj-15::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "gain[2]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-15::obj-23": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-15::obj-28": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-15::obj-31": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-2::obj-32": {
                    "parameter_longname": "live.numbox[4]"
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
                "obj-9::obj-20": {
                    "parameter_invisible": 0,
                    "parameter_longname": "dt[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "dt",
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
                    "parameter_longname": "gain[1]",
                    "parameter_modmode": 3,
                    "parameter_shortname": "gain",
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-32": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 3,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 1
                },
                "obj-9::obj-35": {
                    "parameter_invisible": 0,
                    "parameter_modmode": 0,
                    "parameter_steps": 0,
                    "parameter_type": 0,
                    "parameter_unitstyle": 9
                },
                "obj-9::obj-90": {
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
                "boxes": [ "obj-2", "obj-10" ]
            }
        ]
    }
}