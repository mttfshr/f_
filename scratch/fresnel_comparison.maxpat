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
        "rect": [ 247.0, 95.0, 1134.0, 881.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-19",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_camera_fm.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 232.0, 62.0, 129.8699999999999, 103.0 ],
                    "varname": "vs_camera_fm",
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
                    "id": "obj-18",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 922.0, 72.0, 79.0, 316.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Arial",
                    "fontsize": 13.0,
                    "id": "obj-1",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 40.0, 20.0, 914.0, 21.0 ],
                    "text": "Fresnel-effect scratch comparison -- one shared source, three chains. See docs/f-reference/module-inventory.md (fresnel discussion) and f_vecfield_type.md."
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
                    "patching_rect": [ 40.0, 60.0, 100.0, 150.0 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Arial",
                    "fontsize": 12.0,
                    "id": "obj-3",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 420.0, 62.0, 263.0, 20.0 ],
                    "text": "shared source (swap for any test image/pattern)"
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
                    "name": "vs_wfg_polarizer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 420.0, 90.0, 220.0, 132.0 ],
                    "varname": "src_wfg",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Arial",
                    "fontsize": 12.0,
                    "id": "obj-5",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 60.0, 258.0, 250.0, 20.0 ],
                    "text": "vortex field -- feeds chains A + C"
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
                    "name": "f_vf_vortex.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 64.0, 273.0, 201.0, 160.0 ],
                    "varname": "vortex",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Arial",
                    "fontsize": 12.0,
                    "id": "obj-7",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 420.0, 258.0, 352.0, 20.0 ],
                    "text": "fieldmap -- field derived from source's own gradient, chain B only"
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
                    "name": "f_vf_fieldmap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 420.0, 288.0, 155.0, 96.0 ],
                    "varname": "fieldmap",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Arial",
                    "fontsize": 12.0,
                    "id": "obj-9",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 60.0, 424.0, 373.0, 20.0 ],
                    "text": "A -- vortex -> caustic (streamline convergence: smooth optical focus)"
                }
            },
            {
                "box": {
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "obj-10",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_caustic.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 88.0, 468.0, 231.0, 108.0 ],
                    "varname": "caustic_A",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Arial",
                    "fontsize": 12.0,
                    "id": "obj-11",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 420.0, 424.0, 364.0, 20.0 ],
                    "text": "B -- fieldmap -> warp (content-driven displacement, no brightening)"
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
                    "name": "f_vf_warp.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 420.0, 454.0, 155.0, 96.0 ],
                    "varname": "warp_B",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "fontname": "Arial",
                    "fontsize": 12.0,
                    "id": "obj-13",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 780.0, 424.0, 340.0, 20.0 ],
                    "text": "C -- vortex -> warp (direct displacement, same field as A)"
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
                    "name": "f_vf_warp.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture" ],
                    "patching_rect": [ 780.0, 454.0, 155.0, 96.0 ],
                    "varname": "warp_C",
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
                    "id": "obj-15",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 88.0, 594.0, 269.0, 283.0 ],
                    "varname": "preview_A",
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
                    "id": "obj-16",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 412.0, 576.0, 263.0, 273.0 ],
                    "varname": "preview_B",
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
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 780.0, 610.0, 191.0, 174.0 ],
                    "varname": "preview_C",
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-10", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-17", 0 ],
                    "source": [ "obj-14", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-10", 0 ],
                    "order": 1,
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "order": 2,
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "order": 0,
                    "source": [ "obj-19", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-6", 0 ],
                    "order": 0,
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-8", 0 ],
                    "order": 1,
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 1 ],
                    "source": [ "obj-6", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-10", 1 ],
                    "order": 0,
                    "source": [ "obj-8", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 1 ],
                    "order": 1,
                    "source": [ "obj-8", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-10::obj-20": [ "mix_pct", "mix_pct", 0 ],
            "obj-10::obj-23": [ "gain", "gain", 0 ],
            "obj-10::obj-26": [ "scale", "scale", 0 ],
            "obj-10::obj-29": [ "softness", "softness", 0 ],
            "obj-10::obj-32": [ "color_shift", "color_shift", 0 ],
            "obj-12::obj-20": [ "strength[1]", "strength", 0 ],
            "obj-14::obj-20": [ "strength", "strength", 0 ],
            "obj-18::obj-14": [ "live.menu[30]", "live.menu", 0 ],
            "obj-18::obj-16": [ "live.menu[31]", "live.menu", 0 ],
            "obj-18::obj-18": [ "live.menu[32]", "live.menu", 0 ],
            "obj-18::obj-2": [ "live.menu", "live.menu", 0 ],
            "obj-18::obj-22": [ "live.menu[33]", "live.menu", 0 ],
            "obj-18::obj-24": [ "live.menu[9]", "live.menu", 0 ],
            "obj-18::obj-25": [ "live.menu[10]", "live.menu", 0 ],
            "obj-18::obj-26": [ "live.menu[11]", "live.menu", 0 ],
            "obj-18::obj-27": [ "live.menu[12]", "live.menu", 0 ],
            "obj-18::obj-29": [ "live.menu[13]", "live.menu", 0 ],
            "obj-18::obj-30": [ "live.menu[14]", "live.menu", 0 ],
            "obj-18::obj-33": [ "live.menu[15]", "live.menu", 0 ],
            "obj-18::obj-36": [ "live.menu[3]", "live.menu", 0 ],
            "obj-18::obj-52": [ "live.menu[4]", "live.menu", 0 ],
            "obj-18::obj-53": [ "live.menu[5]", "live.menu", 0 ],
            "obj-18::obj-56": [ "live.menu[6]", "live.menu", 0 ],
            "obj-19::obj-11": [ "toggle", "scale_freq_x", 0 ],
            "obj-19::obj-18": [ "can2_scale_freq_y", "scale_freq_y", 0 ],
            "obj-19::obj-19": [ "cam2_on_off", "live.text", 0 ],
            "obj-19::obj-20": [ "cam2_fm_x", "XM", 0 ],
            "obj-19::obj-21": [ "cam2_fm_y", "YM", 0 ],
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
            "obj-4::obj-10": [ "bias", "Bias", 0 ],
            "obj-4::obj-14": [ "bm", "BM", 0 ],
            "obj-4::obj-17": [ "live.menu[41]", "live.menu", 0 ],
            "obj-4::obj-22": [ "live.text[3]", "live.text", 0 ],
            "obj-4::obj-29": [ "freq", "Freq", 0 ],
            "obj-4::obj-30": [ "angle", "Angle", 0 ],
            "obj-4::obj-42": [ "live.toggle[2]", "live.toggle", 0 ],
            "obj-4::obj-47": [ "polarizer", "Morph", 0 ],
            "obj-4::obj-51": [ "live.menu[40]", "live.menu", 0 ],
            "obj-4::obj-53": [ "speed", "Speed", 0 ],
            "obj-4::obj-54": [ "morph", "Morph", 0 ],
            "obj-4::obj-6": [ "pm", "PM", 0 ],
            "obj-4::obj-65": [ "shape", "Shape", 0 ],
            "obj-4::obj-71": [ "phase", "Phase", 0 ],
            "obj-4::obj-72": [ "phase_time_switch", "phase_time_switch", 0 ],
            "obj-6::obj-20": [ "cx", "cx", 0 ],
            "obj-6::obj-23": [ "cy", "cy", 0 ],
            "obj-6::obj-26": [ "convergence", "convergence", 0 ],
            "obj-6::obj-29": [ "curl", "curl", 0 ],
            "obj-6::obj-32": [ "falloff", "falloff", 0 ],
            "obj-6::obj-35": [ "cx_amt", "cx_amt", 0 ],
            "obj-6::obj-38": [ "cy_amt", "cy_amt", 0 ],
            "obj-6::obj-41": [ "convergence_amt", "convergence_amt", 0 ],
            "obj-6::obj-44": [ "curl_amt", "curl_amt", 0 ],
            "obj-8::obj-20": [ "gain[1]", "gain", 0 ],
            "obj-8::obj-23": [ "scale[1]", "scale", 0 ],
            "obj-8::obj-28": [ "rotate", "rotate", 0 ],
            "obj-8::obj-31": [ "thresh", "thresh", 0 ],
            "parameter_overrides": {
                "obj-12::obj-20": {
                    "parameter_longname": "strength[1]"
                },
                "obj-19::obj-20": {
                    "parameter_range": [ -0.1, 0.1 ]
                },
                "obj-4::obj-6": {
                    "parameter_range": [ -1.0, 1.0 ]
                },
                "obj-8::obj-20": {
                    "parameter_longname": "gain[1]"
                },
                "obj-8::obj-23": {
                    "parameter_longname": "scale[1]"
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}