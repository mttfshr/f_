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
        "rect": [
            426.0,
            106.0,
            1268.0,
            877.0
        ],
        "autosave": 0,
        "boxes": [
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "vs_render.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        110.0,
                        14.0,
                        97.0,
                        146.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-1"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "vs_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [],
                    "patching_rect": [
                        25.0,
                        14.0,
                        79.0,
                        316.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-2"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "f_modules.maxpat",
                    "numinlets": 0,
                    "numoutlets": 0,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [],
                    "patching_rect": [
                        25.0,
                        344.0,
                        96.0,
                        380.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-3"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "vs_wfg_shapes.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        30.0,
                        40.0,
                        220.0,
                        132.0
                    ],
                    "viewvisibility": 1,
                    "varname": "vs_wfg_shapes_src",
                    "id": "obj-4"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "f_tf_tensormap.maxpat",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        30.0,
                        220.0,
                        170.0,
                        110.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-5"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "f_tf_smooth.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        230.0,
                        220.0,
                        150.0,
                        95.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-6"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "f_tf_sharpen.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        430.0,
                        220.0,
                        150.0,
                        95.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-7"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "f_tf_glyph.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        630.0,
                        220.0,
                        170.0,
                        110.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-8"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "vs_wfg_3.maxpat",
                    "numinlets": 3,
                    "numoutlets": 2,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        850.0,
                        40.0,
                        200.0,
                        140.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-9"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "f_tf_axisflow.maxpat",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        830.0,
                        220.0,
                        170.0,
                        100.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-10"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "f_vf_streak.maxpat",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        30.0,
                        420.0,
                        170.0,
                        115.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-11"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [],
                    "patching_rect": [
                        830.0,
                        420.0,
                        157.0,
                        22.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-12"
                }
            },
            {
                "box": {
                    "maxclass": "bpatcher",
                    "bgmode": 1,
                    "border": 0,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        230.0,
                        420.0,
                        112.0,
                        102.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-13"
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "source": [
                        "obj-4",
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
                        "obj-5",
                        0
                    ],
                    "destination": [
                        "obj-6",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-6",
                        0
                    ],
                    "destination": [
                        "obj-7",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-7",
                        0
                    ],
                    "destination": [
                        "obj-8",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-9",
                        0
                    ],
                    "destination": [
                        "obj-8",
                        1
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-7",
                        0
                    ],
                    "destination": [
                        "obj-10",
                        0
                    ],
                    "order": 1
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-10",
                        0
                    ],
                    "destination": [
                        "obj-11",
                        1
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
                        "obj-11",
                        0
                    ],
                    "order": 1
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
                        "obj-8",
                        0
                    ],
                    "destination": [
                        "obj-13",
                        0
                    ],
                    "order": 1
                }
            }
        ],
        "parameters": {
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
        }
    }
}
