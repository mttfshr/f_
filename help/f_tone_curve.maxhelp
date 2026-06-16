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
                    "text": "Tone Curve",
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
                    "text": "Shadow / midtone / highlight brightness adjustment",
                    "varname": "autohelp_top_digest[3]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "linecount": 11,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 150.0, 270.0, 162.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": { "expression": "themecolor.live_control_fg" }
                    },
                    "text": "External Control Messages\n\nshadows [-1.0 -- 1.0]\nmidtones [-1.0 -- 1.0]\nhighlights [-1.0 -- 1.0]\nlow_mid [0.0 -- 1.0]\nmid_high [0.0 -- 1.0]\nedge_falloff [0.0 -- 0.5]\nbypass [0 / 1]",
                    "textjustification": 0
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "r-1",
                    "linecount": 12,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 360.0, 270.0, 180.0 ],
                    "text": "References\n\nThree-band additive lift weighted by luma:\nsw = shadow weight (below low_mid)\nhw = highlight weight (above mid_high)\nmw = 1 - sw - hw (midtone remainder)\n\nlift = shadows*sw + midtones*mw + highlights*hw\n\nBand weights sum to 1.0 at all luma values.\nShares low_mid / mid_high / edge_falloff\nconvention with f_luma_processor.\n\nOriginal derivation -- not from external source."
                }
            },
            {
                "box": {
                    "id": "obj-1",
                    "maxclass": "panel",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 0.0, -2.0, 303.0, 765.0 ]
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
                    "name": "f_tone_curve.maxpat",
                    "numinlets": 2, "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 293.75, 154.0, 91.0 ],
                    "varname": "f_tone_curve",
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
