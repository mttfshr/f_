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
   100.0,
   99.0,
   871.0,
   780.0
  ],
  "gridonopen": 2,
  "toolbarvisible": 0,
  "helpsidebarclosed": 1,
  "boxes": [
   {
    "box": {
     "id": "h-1",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      15.0,
      15.0,
      270.0,
      50.0
     ],
     "fontface": 0,
     "fontname": "Ableton Sans Medium",
     "bgcolor": [
      0.2,
      0.2,
      0.2,
      0.0
     ],
     "saved_attribute_attributes": {
      "textcolor": {
       "expression": "themecolor.live_control_fg"
      }
     },
     "text": "Hatch",
     "fontsize": 36.0,
     "varname": "autohelp_top_digest[4]"
    }
   },
   {
    "box": {
     "id": "h-2",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      15.0,
      75.0,
      270.0,
      40.0
     ],
     "fontface": 0,
     "fontname": "Ableton Sans Light",
     "bgcolor": [
      0.2,
      0.2,
      0.2,
      0.0
     ],
     "saved_attribute_attributes": {
      "textcolor": {
       "expression": "themecolor.live_control_fg"
      }
     },
     "text": "Makes a tensor field's structure visible: strokes where direction is sure, grain where it is lost",
     "fontsize": 14.0,
     "linecount": 2,
     "varname": "autohelp_top_digest[3]"
    }
   },
   {
    "box": {
     "id": "d-8",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      15.0,
      150.0,
      270.0,
      187.0
     ],
     "fontface": 0,
     "fontname": "Ableton Sans Light",
     "bgcolor": [
      0.2,
      0.2,
      0.2,
      0.0
     ],
     "saved_attribute_attributes": {
      "textcolor": {
       "expression": "themecolor.live_control_fg"
      }
     },
     "text": "External Control Messages\n\nreach [0 – 1]\ngrain [0 – 1]\ndensity [0 – 1]\ncontrast [0 – 1]\nline_hard [0 – 1]\nstructure_floor [0 – 1]\nangle_offset [-1 – 1]\ncoh_floor [0 – 1]\nbypass [0 / 1]",
     "fontsize": 12.0,
     "linecount": 11
    }
   },
   {
    "box": {
     "id": "r-1",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      15.0,
      357.0,
      270.0,
      200.0
     ],
     "fontface": 0,
     "fontname": "Ableton Sans Light",
     "bgcolor": [
      0.2,
      0.2,
      0.2,
      0.0
     ],
     "saved_attribute_attributes": {
      "textcolor": {
       "expression": "themecolor.live_control_fg"
      }
     },
     "text": "References\n\nLine integral convolution: Cabral &\nLeedom (1993), \"Imaging vector fields\nusing line integral convolution\".\n\nAxis and coherence decode: the f_tf_glyph\nidiom (in-repo, ADR-2).\n\nCoherence as direction persistence (the\nscatter that turns lost direction into\ngrain): derived in development, not from\nan outside source.\n\nSee docs/f-reference/f_tf_hatch.md.",
     "fontsize": 12.0,
     "linecount": 15
    }
   },
   {
    "box": {
     "id": "obj-1",
     "maxclass": "panel",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      0.0,
      -2.0,
      303.0,
      765.0
     ]
    }
   },
   {
    "box": {
     "id": "d-3",
     "maxclass": "bpatcher",
     "name": "vs_sources_main.maxpat",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "jit_gl_texture"
     ],
     "patching_rect": [
      338.0,
      23.75,
      296.4,
      125.5
     ],
     "bgmode": 1,
     "border": 1,
     "clickthrough": 0,
     "enablehscroll": 0,
     "enablevscroll": 0,
     "lockeddragscroll": 0,
     "lockedsize": 0,
     "offset": [
      0.0,
      0.0
     ],
     "viewvisibility": 1
    }
   },
   {
    "box": {
     "id": "d-11",
     "maxclass": "bpatcher",
     "name": "f_tf_tensormap.maxpat",
     "numinlets": 1,
     "numoutlets": 2,
     "outlettype": [
      "jit_gl_texture",
      "jit_gl_texture"
     ],
     "patching_rect": [
      338.0,
      190.0,
      154.0,
      84.0
     ],
     "bgmode": 1,
     "border": 1,
     "clickthrough": 0,
     "enablehscroll": 0,
     "enablevscroll": 0,
     "lockeddragscroll": 0,
     "lockedsize": 0,
     "offset": [
      0.0,
      0.0
     ],
     "viewvisibility": 1,
     "varname": "f_tf_tensormap"
    }
   },
   {
    "box": {
     "id": "d-4",
     "maxclass": "bpatcher",
     "name": "f_tf_hatch.maxpat",
     "numinlets": 2,
     "numoutlets": 2,
     "outlettype": [
      "jit_gl_texture",
      "jit_gl_texture"
     ],
     "patching_rect": [
      338.0,
      294.0,
      191.0,
      152.0
     ],
     "bgmode": 1,
     "border": 1,
     "clickthrough": 0,
     "enablehscroll": 0,
     "enablevscroll": 0,
     "lockeddragscroll": 0,
     "lockedsize": 0,
     "offset": [
      0.0,
      0.0
     ],
     "viewvisibility": 1,
     "varname": "f_tf_hatch"
    }
   },
   {
    "box": {
     "id": "d-5",
     "maxclass": "bpatcher",
     "name": "vs_preview.maxpat",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "jit_gl_texture"
     ],
     "patching_rect": [
      338.0,
      466.0,
      236.0,
      249.0
     ],
     "bgmode": 1,
     "border": 1,
     "clickthrough": 0,
     "enablehscroll": 0,
     "enablevscroll": 0,
     "lockeddragscroll": 0,
     "lockedsize": 0,
     "offset": [
      0.0,
      0.0
     ],
     "viewvisibility": 1
    }
   },
   {
    "box": {
     "id": "d-9",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      545.0,
      294.0,
      215.0,
      82.0
     ],
     "fontface": 0,
     "fontname": "Ableton Sans Light",
     "bgcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "bubble": 1,
     "text": "In 0: raw tensor, Tensor Map outlet 0.\nOn moving sources put f_tf_smooth\nbetween them: Hatch holds no state.\nIn 1 (optional): stroke texture; left\nunconnected = the built-in blobs.",
     "fontsize": 12.0,
     "linecount": 5
    }
   },
   {
    "box": {
     "id": "d-10",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      590.0,
      466.0,
      175.0,
      66.0
     ],
     "fontface": 0,
     "fontname": "Ableton Sans Light",
     "bgcolor": [
      0.0,
      0.0,
      0.0,
      0.0
     ],
     "bubble": 1,
     "text": "Needs a running Vsynth render: the\noutput follows its size.\nOut 0: streaks. Out 1: the same\nfield without the Line style.",
     "fontsize": 12.0,
     "linecount": 4
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "destination": [
      "d-11",
      0
     ],
     "source": [
      "d-3",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "d-4",
      0
     ],
     "source": [
      "d-11",
      0
     ]
    }
   },
   {
    "patchline": {
     "destination": [
      "d-5",
      0
     ],
     "source": [
      "d-4",
      0
     ]
    }
   }
  ],
  "parameters": {
   "inherited_shortname": 1
  },
  "autosave": 0
 }
}