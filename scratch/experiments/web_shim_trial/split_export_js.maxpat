{
 "fileversion": 1,
 "appversion": {
  "major": 9,
  "minor": 2,
  "revision": 0,
  "architecture": "x64",
  "modernui": 1
 },
 "patcher": {
  "boxes": [
   {
    "box": {
     "id": "driver",
     "maxclass": "newobj",
     "text": "js export_trial.js",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      ""
     ],
     "patching_rect": [
      40.0,
      40.0,
      130.0,
      22.0
     ]
    }
   },
   {
    "box": {
     "id": "lb",
     "maxclass": "newobj",
     "text": "loadbang",
     "numinlets": 1,
     "numoutlets": 1,
     "outlettype": [
      "bang"
     ],
     "patching_rect": [
      40.0,
      10.0,
      50.0,
      22.0
     ]
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "source": [
      "lb",
      0
     ],
     "destination": [
      "driver",
      0
     ]
    }
   }
  ],
  "params": []
 }
}