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
     "text": "Tensor Map",
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
     "text": "Structure tensor of any texture -- where edges run, how strong, how sure. Feeds Axis Flow",
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
      119.0
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
     "text": "External Control Messages\n\nstrength [1 \u2013 1000]\nradius [0 \u2013 16]\nbypass [0 / 1]",
     "fontsize": 12.0,
     "linecount": 7
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
      289.0,
      270.0,
      120.0
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
     "text": "References\n\nStructure tensor: Bigun & Granlund (1987),\n\"Optimal orientation detection of linear\nsymmetry\"; Kass & Witkin (1987), \"Analyzing\noriented patterns\". Sobel gradient, box\nwindow, closed-form 2x2 eigen: standard.\n\nSee docs/f-reference/f_tf_tensormap.md and\ndocs/f-reference/f_tensor_type.md. Outlet 1\nis angle-doubled: not a vecfield.",
     "fontsize": 12.0,
     "linecount": 11
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
     "id": "d-4",
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
      24.0,
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
      128.0,
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
      500.0,
      148.0,
      210.0,
      51.0
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
     "text": "Preview shows outlet 1: hue = edge\ndirection. Wire it to Axis Flow.",
     "fontsize": 12.0,
     "linecount": 2
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "destination": [
      "d-5",
      0
     ],
     "source": [
      "d-4",
      1
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