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
     "text": "Tensor Smooth",
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
     "text": "One-pole temporal smoother for a Tensor Map \u2014 inertia for edges, with attack none / release dial. Feeds Glyph, Hatch",
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
      68.0
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
     "text": "External Control Messages\n\nrelease [0 \u2013 1]\nbypass [0 / 1]",
     "fontsize": 12.0,
     "linecount": 4
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
      238.0,
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
     "text": "References\n\nOne-pole recurrence on the tensor's raw components;\nstandard. Tensor-space framing: opposite-edge axes\nreinforce instead of cancelling (the f_tensorfield\nhub's argument). jit.fx.tp.filter is the stock\nrecurrence \u2014 this module is its performable\nre-shape (see docs note).\n\nSee docs/f-reference/f_tf_smooth.md.",
     "fontsize": 12.0,
     "linecount": 10
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
     "name": "f_tf_smooth.maxpat",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
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
     "varname": "f_tf_smooth"
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
      128.0,
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
     "text": "Input: Tensor Map outlet 0.\nrelease 0 = live, 0.9 = heavy inertia.",
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