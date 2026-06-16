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
        "rect": [ 100.0, 99.0, 871.0, 780.0 ],
        "gridonopen": 2,
        "toolbarvisible": 0,
        "helpsidebarclosed": 1,
        "boxes": [
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Medium",
                    "fontsize": 36.0,
                    "id": "h-1",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 15.0, 270.0, 50.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": { "expression": "themecolor.live_control_fg" }
                    },
                    "text": "Chladni",
                    "varname": "autohelp_top_digest[4]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 14.0,
                    "id": "h-2",
                    "linecount": 2,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 75.0, 270.0, 40.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": { "expression": "themecolor.live_control_fg" }
                    },
                    "text": "Circular plate Chladni nodal figures -- 8 Bessel modes",
                    "varname": "autohelp_top_digest[3]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "linecount": 38,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 150.0, 270.0, 530.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": { "expression": "themecolor.live_control_fg" }
                    },
                    "text": "External Control Messages\n\nAmplitudes (primary signal inputs):\nm0amp [0.0 -- 1.0]\nm1amp [0.0 -- 1.0]\nm2amp [0.0 -- 1.0]\nm3amp [0.0 -- 1.0]\nm4amp [0.0 -- 1.0]\nm5amp [0.0 -- 1.0]\nm6amp [0.0 -- 1.0]\nm7amp [0.0 -- 1.0]\n\nBessel zeros (tuning):\nz0 [0.5 -- 15.0]\nz1 [0.5 -- 15.0]\nz2 [0.5 -- 15.0]\nz3 [0.5 -- 15.0]\nz4 [0.5 -- 15.0]\nz5 [0.5 -- 15.0]\nz6 [0.5 -- 15.0]\nz7 [0.5 -- 15.0]\n\nPhase offsets:\nph0 [-6.28 -- 6.28]  (global + m0)\nph1 [-6.28 -- 6.28]\nph2 [-6.28 -- 6.28]\nph3 [-6.28 -- 6.28]\nph4 [-6.28 -- 6.28]\nph5 [-6.28 -- 6.28]\nph6 [-6.28 -- 6.28]\nph7 [-6.28 -- 6.28]\n\ndishradius [0.1 -- 4.0]\nreflectamt [0.0 -- 1.0]\nlinesharpness [0.1 -- 100.0]\nglobalscale [0.0 -- 2.0]\nview_mode [0.0 -- 1.0]\nbypass [0 / 1]",
                    "textjustification": 0
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "r-1",
                    "linecount": 14,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 695.0, 270.0, 208.0 ],
                    "text": "References\n\nChladni figures: Ernst Chladni (1787)\n\"Entdeckungen uber die Theorie des Klanges\"\n\nBessel function approximation (large-x asymptotic):\nsqrt(2/pi*r) * cos(r - z_m) per mode m\nDefaults z0-z7 = first zeros of J_0 through J_7.\n\nModal superposition: Kinsler et al.\n\"Fundamentals of Acoustics\" (4th ed.)\n\nEEG band mapping (Delta-Gamma) derived in\ndevelopment -- not from external source.\nview_mode blend: original derivation."
                }
            },
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "panel",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 0.0, -2.0, 303.0, 1000.0 ]
                }
            },
            {
                "box": {
                    "bgmode": 1, "border": 1, "clickthrough": 0,
                    "enablehscroll": 0, "enablevscroll": 0,
                    "id": "d-3", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_sources_main.maxpat",
                    "numinlets": 1, "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 23.75, 296.4, 125.5 ],
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1, "border": 1, "clickthrough": 0,
                    "enablehscroll": 0, "enablevscroll": 0,
                    "id": "d-6", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_wfg_s.maxpat",
                    "numinlets": 1, "numoutlets": 2,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture", "float" ],
                    "patching_rect": [ 417.0, 195.75, 75.0, 73.5 ],
                    "varname": "vs_wfg_s",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.0, 0.0, 0.0, 0.0 ],
                    "bubble": 1, "bubbleside": 1,
                    "fontface": 0, "fontname": "Ableton Sans Light", "fontsize": 13.0,
                    "id": "d-7", "maxclass": "comment",
                    "numinlets": 1, "numoutlets": 0,
                    "patching_rect": [ 500.0, 220.75, 64.0, 26.0 ],
                    "text": "time_s"
                }
            },
            {
                "box": {
                    "bgmode": 1, "border": 1, "clickthrough": 0,
                    "enablehscroll": 0, "enablevscroll": 0,
                    "id": "d-4", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_chladni.maxpat",
                    "numinlets": 2, "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 293.75, 154.0, 91.0 ],
                    "varname": "f_chladni",
                    "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1, "border": 1, "clickthrough": 0,
                    "enablehscroll": 0, "enablevscroll": 0,
                    "id": "d-5", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1, "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 404.75, 236.0, 249.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            { "patchline": { "destination": [ "d-4", 0 ], "source": [ "d-3", 0 ] } },
            { "patchline": { "destination": [ "d-5", 0 ], "source": [ "d-4", 0 ] } },
            { "patchline": { "destination": [ "d-4", 1 ], "source": [ "d-6", 1 ] } }
        ],
        "parameters": {
            "parameterbanks": {
                "0": { "index": 0, "name": "", "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ], "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ] }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}
