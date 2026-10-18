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
     "text": "Tensor Glyph",
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
     "text": "One oriented ellipse per grid cell from a Tensor Map \u2014 the debug tap for the whole tensor family",
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
     "text": "External Control Messages\n\ngrid [2 \u2013 256]\nglyph_scale [0 \u2013 2]\nthickness [0 \u2013 1]\nsoftness [0 \u2013 1]\ngate [0 \u2013 1]\nmax_aspect [1 \u2013 32]\nwidth [64 \u2013 8192]\nheight [64 \u2013 8192]\nbypass [0 / 1]",
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
     "text": "References\n\nTensor glyphs (ellipses/crosses at cell lattice)\nare standard scientific-viz practice (Kindlmann's\nsuperquadrics; Delmarcelle & Hesselink's\nhyperstreamlines for the lineage). No loops \u2014\nclosed-form ring.\n\nSee docs/f-reference/f_tf_glyph.md.",
     "fontsize": 12.0,
     "linecount": 9
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
     "name": "f_tf_glyph.maxpat",
     "numinlets": 2,
     "numoutlets": 1,
     "outlettype": [
      "jit_gl_texture"
     ],
     "patching_rect": [
      338.0,
      24.0,
      154.0,
      124.0
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
     "varname": "f_tf_glyph"
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
      168.0,
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
      168.0,
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
     "text": "Input: Tensor Map outlet 0. grid sets\ncell pitch; gate keeps weak edges quiet.",
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