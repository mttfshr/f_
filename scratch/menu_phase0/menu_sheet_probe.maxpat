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
            60,
            80,
            230,
            378
        ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "jsui",
                    "patching_rect": [
                        20,
                        140,
                        230,
                        378
                    ],
                    "filename": "menu_sheet_test.js",
                    "varname": "sheet",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ],
                    "presentation": 1,
                    "presentation_rect": [
                        0,
                        0,
                        230,
                        378
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-2",
                    "maxclass": "newobj",
                    "patching_rect": [
                        260,
                        140,
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
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "patching_rect": [
                        20,
                        100,
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
                    "id": "obj-4",
                    "maxclass": "message",
                    "patching_rect": [
                        100,
                        100,
                        60,
                        22
                    ],
                    "text": "measure",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [
                        ""
                    ]
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "comment",
                    "patching_rect": [
                        20,
                        20,
                        420,
                        60
                    ],
                    "text": "Phase 0 probe (T002, T003, T004). Presentation mode shows the sheet at 230 x 378. T002: judge legibility at 11 pt / 12 px pitch on your laptop, in the dark. T003: hover a row for a second: does a tooltip appear? (obj-1 outlet 0 -> thispatcher sets the hint.) T004: open the Max console; widths are printed on load, 'TOO WIDE' means a short label is needed.",
                    "numinlets": 1,
                    "numoutlets": 0
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
                        "obj-3",
                        0
                    ],
                    "destination": [
                        "obj-1",
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
                        "obj-1",
                        0
                    ]
                }
            }
        ]
    }
}
