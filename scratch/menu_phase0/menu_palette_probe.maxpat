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
        "rect": [
            700,
            80,
            230,
            110
        ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "newobj",
                    "patching_rect": [
                        20,
                        20,
                        60,
                        22
                    ],
                    "text": "loadbang",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        "bang"
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "message",
                    "patching_rect": [
                        20,
                        50,
                        200,
                        22
                    ],
                    "text": "window flags float, window exec",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "patching_rect": [
                        20,
                        80,
                        70,
                        22
                    ],
                    "text": "thispatcher",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [
                        "",
                        ""
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "message",
                    "patching_rect": [
                        20,
                        120,
                        60,
                        22
                    ],
                    "text": "insert",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        10,
                        10,
                        90,
                        22
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "message",
                    "patching_rect": [
                        110,
                        120,
                        70,
                        22
                    ],
                    "text": "insert_any",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        110,
                        10,
                        100,
                        22
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "patching_rect": [
                        20,
                        160,
                        130,
                        22
                    ],
                    "text": "js probe_insert.js",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-7",
                    "maxclass": "comment",
                    "patching_rect": [
                        20,
                        200,
                        330,
                        50
                    ],
                    "text": "Phase 0 probe (T001, T005). Click in menu_target_probe first, then click [insert] here. Console says which patcher was in front and whether a button was added to it. T005: this window should float above others on load.",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "presentation": 1,
                    "presentation_rect": [
                        10,
                        40,
                        210,
                        62
                    ]
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "source": [
                        "obj-1",
                        0
                    ],
                    "destination": [
                        "obj-2",
                        0
                    ]
                }
            },
            {
                "patchline": {
                    "source": [
                        "obj-2",
                        0
                    ],
                    "destination": [
                        "obj-3",
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
            }
        ]
    }
}
