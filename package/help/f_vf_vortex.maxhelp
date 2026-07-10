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
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "Vortex",
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
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "Fixed-point vector field generator -- sink, source, spiral, rotation",
                    "varname": "autohelp_top_digest[3]"
                }
            },
            {
                "box": {
                    "bgcolor": [ 0.2, 0.2, 0.2, 0.0 ],
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "id": "d-8",
                    "linecount": 12,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 150.0, 274.0, 179.0 ],
                    "saved_attribute_attributes": {
                        "textcolor": {
                            "expression": "themecolor.live_control_fg"
                        }
                    },
                    "text": "External Control Messages\n\ncx [0.0 -- 1.0]\ncy [0.0 -- 1.0]\nconvergence [-1.0 -- 1.0]\ncurl [-1.0 -- 1.0]\nfalloff [0.0 -- 10.0]\ncx_amt [0.0 -- 1.0]\ncy_amt [0.0 -- 1.0]\nconvergence_amt [0.0 -- 1.0]\ncurl_amt [0.0 -- 1.0]\nbypass [0 / 1]"
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "r-1",
                    "linecount": 15,
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 15.0, 400.0, 270.0, 223.0 ],
                    "text": "References\n\nf_vecfield encoding convention:\nR = fx*0.5+0.5, G = fy*0.5+0.5\nConsumers decode via (sample - 0.5) * 2.0\n\nField topology (convergence x curl):\nsink: conv>0, curl=0\nsource: conv<0, curl=0\nrotation: conv=0, curl!=0\nspiral sink: conv>0, curl!=0\nspiral source: conv<0, curl!=0\n\nFalloff: exp(-r * falloff) -- no ring artifact.\nOriginal derivation -- not from external source."
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
                    "bgmode": 1,
                    "border": 1,
                    "clickthrough": 0,
                    "enablehscroll": 0,
                    "enablevscroll": 0,
                    "id": "d-4",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "f_vf_vortex.maxpat",
                    "numinlets": 5,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 24.0, 201.0, 165.0 ],
                    "varname": "f_vf_vortex",
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
                    "id": "d-5",
                    "lockeddragscroll": 0,
                    "lockedsize": 0,
                    "maxclass": "bpatcher",
                    "name": "vs_preview.maxpat",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "offset": [ 0.0, 0.0 ],
                    "outlettype": [ "jit_gl_texture" ],
                    "patching_rect": [ 338.0, 380.0, 236.0, 249.0 ],
                    "viewvisibility": 1
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "d-5", 0 ],
                    "source": [ "d-4", 0 ]
                }
            }
        ],
        "parameters": {
            "d-4::obj-20": [ "cx", "cx", 0 ],
            "d-4::obj-23": [ "cy", "cy", 0 ],
            "d-4::obj-26": [ "convergence", "convergence", 0 ],
            "d-4::obj-29": [ "curl", "curl", 0 ],
            "d-4::obj-32": [ "falloff", "falloff", 0 ],
            "d-4::obj-35": [ "cx_amt", "cx_amt", 0 ],
            "d-4::obj-38": [ "cy_amt", "cy_amt", 0 ],
            "d-4::obj-41": [ "convergence_amt", "convergence_amt", 0 ],
            "d-4::obj-44": [ "curl_amt", "curl_amt", 0 ],
            "parameterbanks": {
                "0": {
                    "index": 0,
                    "name": "",
                    "parameters": [ "-", "-", "-", "-", "-", "-", "-", "-" ],
                    "buttons": [ "-", "-", "-", "-", "-", "-", "-", "-" ]
                }
            },
            "inherited_shortname": 1
        },
        "autosave": 0
    }
}