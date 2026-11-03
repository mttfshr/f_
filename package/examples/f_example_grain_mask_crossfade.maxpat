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
                    "name": "vs_camera_s.maxpat",
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
                        30.0,
                        40.0,
                        150.0,
                        110.0
                    ],
                    "viewvisibility": 1,
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
                    "name": "f_grain.maxpat",
                    "numinlets": 1,
                    "numoutlets": 3,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        30.0,
                        200.0,
                        227.0,
                        164.0
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
                    "name": "vs_blendmode_mixer.maxpat",
                    "numinlets": 2,
                    "numoutlets": 13,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture",
                        "jit_gl_texture"
                    ],
                    "patching_rect": [
                        300.0,
                        200.0,
                        180.0,
                        120.0
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
                    "name": "f_channel_grader.maxpat",
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
                        540.0,
                        200.0,
                        190.0,
                        110.0
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
                    "name": "vs_output.maxpat",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "offset": [
                        0.0,
                        0.0
                    ],
                    "outlettype": [],
                    "patching_rect": [
                        300.0,
                        420.0,
                        157.0,
                        22.0
                    ],
                    "viewvisibility": 1,
                    "id": "obj-8"
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
                        2
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
                        "obj-4",
                        0
                    ],
                    "destination": [
                        "obj-6",
                        1
                    ],
                    "order": 1
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-5",
                        1
                    ],
                    "destination": [
                        "obj-7",
                        0
                    ],
                    "order": 1
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-7",
                        0
                    ],
                    "destination": [
                        "obj-6",
                        1
                    ],
                    "order": 0
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-6",
                        0
                    ],
                    "destination": [
                        "obj-8",
                        0
                    ]
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
