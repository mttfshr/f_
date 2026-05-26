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
      629.0,
      148.0,
      1268.0,
      665.0
    ],
    "boxes": [
      {
        "box": {
          "id": "obj-89",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            22.5,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "comment": "",
          "id": "obj-11",
          "index": 0,
          "maxclass": "outlet",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            25.0,
            633.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "comment": "",
          "id": "obj-108",
          "index": 0,
          "maxclass": "inlet",
          "numinlets": 0,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            30.0,
            -26.0,
            30.0,
            30.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-2",
          "items": [
            "Log",
            ",",
            "Bessel"
          ],
          "maxclass": "umenu",
          "numinlets": 1,
          "numoutlets": 3,
          "outlettype": [
            "int",
            "",
            ""
          ],
          "parameter_enable": 0,
          "patching_rect": [
            985.0,
            8.0,
            110.0,
            22.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-3",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 3,
          "outlettype": [
            "bang",
            "bang",
            ""
          ],
          "patching_rect": [
            1120.0,
            30.0,
            90.0,
            22.0
          ],
          "text": "select 0 1"
        }
      },
      {
        "box": {
          "fontface": 0,
          "fontname": "Arial",
          "fontsize": 12.0,
          "id": "obj-4",
          "maxclass": "number~",
          "mode": 2,
          "numinlets": 2,
          "numoutlets": 2,
          "outlettype": [
            "signal",
            "float"
          ],
          "patching_rect": [
            1207.0,
            81.0,
            56.0,
            22.0
          ],
          "sig": 1.0
        }
      },
      {
        "box": {
          "id": "obj-5",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "bang"
          ],
          "patching_rect": [
            1310.0,
            30.0,
            75.0,
            22.0
          ],
          "text": "loadbang"
        }
      },
      {
        "box": {
          "id": "obj-6",
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            1310.0,
            65.0,
            35.0,
            22.0
          ],
          "text": "1."
        }
      },
      {
        "box": {
          "id": "obj-7",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            20.0,
            61.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.99418774 0.99431728"
        }
      },
      {
        "box": {
          "id": "obj-8",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            20.0,
            120.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.98347727 0.98445204"
        }
      },
      {
        "box": {
          "id": "obj-9",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            20.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-10",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            20.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-12",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            20.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-13",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            20.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-14",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            40.0,
            444.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-15",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            20.0,
            522.0,
            96.0,
            22.0
          ],
          "text": "prepend m0amp"
        }
      },
      {
        "box": {
          "id": "obj-17",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            140.0,
            39.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.98857298 0.98905486"
        }
      },
      {
        "box": {
          "id": "obj-18",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            140.0,
            120.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.97288657 0.97534911"
        }
      },
      {
        "box": {
          "id": "obj-19",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            140.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-20",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            140.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-21",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            140.0,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-22",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            140.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-23",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            140.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-24",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            150.0,
            439.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-25",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            140.0,
            510.0,
            96.0,
            22.0
          ],
          "text": "prepend m1amp"
        }
      },
      {
        "box": {
          "id": "obj-27",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            260.0,
            48.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.97720052 0.97898637"
        }
      },
      {
        "box": {
          "id": "obj-28",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            260.0,
            120.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.96270243 0.96710741"
        }
      },
      {
        "box": {
          "id": "obj-29",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            260.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-30",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            260.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-31",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            260.0,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-32",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            260.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-33",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            260.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-34",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            280.0,
            444.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-35",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            260.0,
            510.0,
            96.0,
            22.0
          ],
          "text": "prepend m2amp"
        }
      },
      {
        "box": {
          "id": "obj-37",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            380.0,
            30.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.95326745 0.95985655"
        }
      },
      {
        "box": {
          "id": "obj-38",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            380.0,
            133.5,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.95253981 0.95931131"
        }
      },
      {
        "box": {
          "id": "obj-39",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            380.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-40",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            380.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-41",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            380.0,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-42",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            380.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-43",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            380.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-44",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            403.0,
            439.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-45",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            380.0,
            510.0,
            96.0,
            22.0
          ],
          "text": "prepend m3amp"
        }
      },
      {
        "box": {
          "id": "obj-47",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            500.0,
            30.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.90005272 0.92413385"
        }
      },
      {
        "box": {
          "id": "obj-48",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            500.0,
            120.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.94227761 0.95181669"
        }
      },
      {
        "box": {
          "id": "obj-49",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            500.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-50",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            500.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-51",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            500.0,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-52",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            500.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-53",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            500.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-54",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            515.0,
            439.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-55",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            500.0,
            510.0,
            96.0,
            22.0
          ],
          "text": "prepend m4amp"
        }
      },
      {
        "box": {
          "id": "obj-57",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            620.0,
            39.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.77373327 0.86001582"
        }
      },
      {
        "box": {
          "id": "obj-58",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            620.0,
            120.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.93185118 0.94454462"
        }
      },
      {
        "box": {
          "id": "obj-59",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            620.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-60",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            620.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-61",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            620.0,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-62",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            620.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-63",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            620.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-64",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            640.0,
            444.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-65",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            620.0,
            510.0,
            96.0,
            22.0
          ],
          "text": "prepend m5amp"
        }
      },
      {
        "box": {
          "id": "obj-67",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            740.0,
            48.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.45850375 0.75567092"
        }
      },
      {
        "box": {
          "id": "obj-68",
          "linecount": 4,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            745.25,
            113.5,
            104.5,
            62.0
          ],
          "text": "1.0 0.0 -1.0 -1.92121964 0.93744531"
        }
      },
      {
        "box": {
          "id": "obj-69",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            740.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-70",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            740.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-71",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            740.0,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-72",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            740.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-73",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            740.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-74",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            755.0,
            444.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-75",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            740.0,
            510.0,
            96.0,
            22.0
          ],
          "text": "prepend m6amp"
        }
      },
      {
        "box": {
          "id": "obj-77",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            860.0,
            39.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -0.68088499 0.62980827"
        }
      },
      {
        "box": {
          "id": "obj-78",
          "linecount": 3,
          "maxclass": "message",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            860.0,
            120.0,
            115.0,
            49.0
          ],
          "text": "1.0 0.0 -1.0 -1.9103841 0.93050348"
        }
      },
      {
        "box": {
          "id": "obj-79",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 5,
          "outlettype": [
            "float",
            "float",
            "float",
            "float",
            "float"
          ],
          "patching_rect": [
            860.0,
            184.0,
            115.0,
            22.0
          ],
          "text": "unpack 0. 0. 0. 0. 0."
        }
      },
      {
        "box": {
          "id": "obj-80",
          "maxclass": "newobj",
          "numinlets": 6,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            860.0,
            230.0,
            65.0,
            22.0
          ],
          "text": "biquad~"
        }
      },
      {
        "box": {
          "id": "obj-81",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            860.0,
            290.0,
            35.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-82",
          "maxclass": "newobj",
          "numinlets": 3,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            860.0,
            350.0,
            110.0,
            22.0
          ],
          "text": "slide~ 441 44100"
        }
      },
      {
        "box": {
          "id": "obj-83",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            860.0,
            410.0,
            35.0,
            22.0
          ],
          "text": "*~"
        }
      },
      {
        "box": {
          "id": "obj-84",
          "maxclass": "meter~",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            891.0,
            439.0,
            95.0,
            14.0
          ]
        }
      },
      {
        "box": {
          "id": "obj-85",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            ""
          ],
          "patching_rect": [
            860.0,
            510.0,
            96.0,
            22.0
          ],
          "text": "prepend m7amp"
        }
      },
      {
        "box": {
          "id": "obj-87",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            1005.0,
            68.0,
            45.0,
            20.0
          ],
          "text": "LOG"
        }
      },
      {
        "box": {
          "id": "obj-88",
          "maxclass": "comment",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            1000.0,
            119.0,
            55.0,
            20.0
          ],
          "text": "BESSEL"
        }
      },
      {
        "box": {
          "id": "obj-90",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            20.0,
            475.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "id": "obj-91",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            140.0,
            290.0,
            40.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-92",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            140.0,
            462.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "id": "obj-93",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            260.0,
            290.0,
            40.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-94",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            260.0,
            462.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "id": "obj-95",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            380.0,
            290.0,
            40.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-96",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            380.0,
            462.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "id": "obj-97",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            500.0,
            290.0,
            40.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-98",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            500.0,
            462.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "id": "obj-99",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            620.0,
            290.0,
            40.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-100",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            620.0,
            462.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "id": "obj-101",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            740.0,
            290.0,
            40.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-102",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            740.0,
            462.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "id": "obj-103",
          "maxclass": "newobj",
          "numinlets": 1,
          "numoutlets": 1,
          "outlettype": [
            "signal"
          ],
          "patching_rect": [
            860.0,
            290.0,
            40.0,
            22.0
          ],
          "text": "abs~"
        }
      },
      {
        "box": {
          "id": "obj-104",
          "maxclass": "newobj",
          "numinlets": 2,
          "numoutlets": 1,
          "outlettype": [
            "float"
          ],
          "patching_rect": [
            860.0,
            462.0,
            90.0,
            22.0
          ],
          "text": "snapshot~ 20"
        }
      },
      {
        "box": {
          "comment": "m0amp-m7amp",
          "id": "obj-1",
          "index": 0,
          "maxclass": "outlet",
          "numinlets": 1,
          "numoutlets": 0,
          "patching_rect": [
            70.0,
            95.0,
            40.0,
            22.0
          ]
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "destination": [
            "obj-89",
            0
          ],
          "source": [
            "obj-10",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-65",
            0
          ],
          "source": [
            "obj-100",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-75",
            0
          ],
          "source": [
            "obj-102",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-85",
            0
          ],
          "source": [
            "obj-104",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            0
          ],
          "order": 14,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-19",
            0
          ],
          "order": 13,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-20",
            0
          ],
          "order": 12,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-29",
            0
          ],
          "order": 11,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-30",
            0
          ],
          "order": 10,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-39",
            0
          ],
          "order": 9,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-40",
            0
          ],
          "order": 8,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-49",
            0
          ],
          "order": 7,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-50",
            0
          ],
          "order": 6,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-59",
            0
          ],
          "order": 5,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-60",
            0
          ],
          "order": 4,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-69",
            0
          ],
          "order": 3,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-70",
            0
          ],
          "order": 2,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-79",
            0
          ],
          "order": 1,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-80",
            0
          ],
          "order": 0,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-9",
            0
          ],
          "order": 15,
          "source": [
            "obj-108",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-13",
            0
          ],
          "source": [
            "obj-12",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-14",
            0
          ],
          "order": 0,
          "source": [
            "obj-13",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-90",
            0
          ],
          "order": 1,
          "source": [
            "obj-13",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-15",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-19",
            0
          ],
          "source": [
            "obj-17",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-19",
            0
          ],
          "source": [
            "obj-18",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-20",
            5
          ],
          "source": [
            "obj-19",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-20",
            4
          ],
          "source": [
            "obj-19",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-20",
            3
          ],
          "source": [
            "obj-19",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-20",
            2
          ],
          "source": [
            "obj-19",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-20",
            1
          ],
          "source": [
            "obj-19",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-3",
            0
          ],
          "source": [
            "obj-2",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-21",
            0
          ],
          "source": [
            "obj-20",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-22",
            0
          ],
          "source": [
            "obj-21",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-23",
            0
          ],
          "source": [
            "obj-22",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-24",
            0
          ],
          "order": 0,
          "source": [
            "obj-23",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-92",
            0
          ],
          "order": 1,
          "source": [
            "obj-23",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-25",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-29",
            0
          ],
          "source": [
            "obj-27",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-29",
            0
          ],
          "source": [
            "obj-28",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-30",
            5
          ],
          "source": [
            "obj-29",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-30",
            4
          ],
          "source": [
            "obj-29",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-30",
            3
          ],
          "source": [
            "obj-29",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-30",
            2
          ],
          "source": [
            "obj-29",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-30",
            1
          ],
          "source": [
            "obj-29",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-17",
            0
          ],
          "order": 6,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-18",
            0
          ],
          "order": 6,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-27",
            0
          ],
          "order": 5,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-28",
            0
          ],
          "order": 5,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-37",
            0
          ],
          "order": 4,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-38",
            0
          ],
          "order": 4,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-47",
            0
          ],
          "order": 3,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-48",
            0
          ],
          "order": 3,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-57",
            0
          ],
          "order": 2,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-58",
            0
          ],
          "order": 2,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-67",
            0
          ],
          "order": 1,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-68",
            0
          ],
          "order": 1,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-7",
            0
          ],
          "order": 7,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-77",
            0
          ],
          "order": 0,
          "source": [
            "obj-3",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-78",
            0
          ],
          "order": 0,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-8",
            0
          ],
          "order": 7,
          "source": [
            "obj-3",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-31",
            0
          ],
          "source": [
            "obj-30",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-32",
            0
          ],
          "source": [
            "obj-31",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-33",
            0
          ],
          "source": [
            "obj-32",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-34",
            0
          ],
          "order": 0,
          "source": [
            "obj-33",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-94",
            0
          ],
          "order": 1,
          "source": [
            "obj-33",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-35",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-39",
            0
          ],
          "source": [
            "obj-37",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-39",
            0
          ],
          "source": [
            "obj-38",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-40",
            5
          ],
          "source": [
            "obj-39",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-40",
            4
          ],
          "source": [
            "obj-39",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-40",
            3
          ],
          "source": [
            "obj-39",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-40",
            2
          ],
          "source": [
            "obj-39",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-40",
            1
          ],
          "source": [
            "obj-39",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-13",
            1
          ],
          "order": 7,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-23",
            1
          ],
          "order": 6,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-33",
            1
          ],
          "order": 5,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-43",
            1
          ],
          "order": 4,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-53",
            1
          ],
          "order": 3,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-63",
            1
          ],
          "order": 2,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-73",
            1
          ],
          "order": 1,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-83",
            1
          ],
          "order": 0,
          "source": [
            "obj-4",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-41",
            0
          ],
          "source": [
            "obj-40",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-42",
            0
          ],
          "source": [
            "obj-41",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-43",
            0
          ],
          "source": [
            "obj-42",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-44",
            0
          ],
          "order": 0,
          "source": [
            "obj-43",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-96",
            0
          ],
          "order": 1,
          "source": [
            "obj-43",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-45",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-49",
            0
          ],
          "source": [
            "obj-47",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-49",
            0
          ],
          "source": [
            "obj-48",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-50",
            5
          ],
          "source": [
            "obj-49",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-50",
            4
          ],
          "source": [
            "obj-49",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-50",
            3
          ],
          "source": [
            "obj-49",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-50",
            2
          ],
          "source": [
            "obj-49",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-50",
            1
          ],
          "source": [
            "obj-49",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-6",
            0
          ],
          "source": [
            "obj-5",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-51",
            0
          ],
          "source": [
            "obj-50",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-52",
            0
          ],
          "source": [
            "obj-51",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-53",
            0
          ],
          "source": [
            "obj-52",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-54",
            0
          ],
          "order": 0,
          "source": [
            "obj-53",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-98",
            0
          ],
          "order": 1,
          "source": [
            "obj-53",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-55",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-59",
            0
          ],
          "source": [
            "obj-57",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-59",
            0
          ],
          "source": [
            "obj-58",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-60",
            5
          ],
          "source": [
            "obj-59",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-60",
            4
          ],
          "source": [
            "obj-59",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-60",
            3
          ],
          "source": [
            "obj-59",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-60",
            2
          ],
          "source": [
            "obj-59",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-60",
            1
          ],
          "source": [
            "obj-59",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-2",
            0
          ],
          "order": 1,
          "source": [
            "obj-6",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-4",
            0
          ],
          "order": 0,
          "source": [
            "obj-6",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-61",
            0
          ],
          "source": [
            "obj-60",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-62",
            0
          ],
          "source": [
            "obj-61",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-63",
            0
          ],
          "source": [
            "obj-62",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-100",
            0
          ],
          "order": 1,
          "source": [
            "obj-63",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-64",
            0
          ],
          "order": 0,
          "source": [
            "obj-63",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-65",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-69",
            0
          ],
          "source": [
            "obj-67",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-69",
            0
          ],
          "source": [
            "obj-68",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-70",
            5
          ],
          "source": [
            "obj-69",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-70",
            4
          ],
          "source": [
            "obj-69",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-70",
            3
          ],
          "source": [
            "obj-69",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-70",
            2
          ],
          "source": [
            "obj-69",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-70",
            1
          ],
          "source": [
            "obj-69",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-9",
            0
          ],
          "source": [
            "obj-7",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-71",
            0
          ],
          "source": [
            "obj-70",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-72",
            0
          ],
          "source": [
            "obj-71",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-73",
            0
          ],
          "source": [
            "obj-72",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-102",
            0
          ],
          "order": 1,
          "source": [
            "obj-73",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-74",
            0
          ],
          "order": 0,
          "source": [
            "obj-73",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-75",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-79",
            0
          ],
          "source": [
            "obj-77",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-79",
            0
          ],
          "source": [
            "obj-78",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-80",
            5
          ],
          "source": [
            "obj-79",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-80",
            4
          ],
          "source": [
            "obj-79",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-80",
            3
          ],
          "source": [
            "obj-79",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-80",
            2
          ],
          "source": [
            "obj-79",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-80",
            1
          ],
          "source": [
            "obj-79",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-9",
            0
          ],
          "source": [
            "obj-8",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-81",
            0
          ],
          "source": [
            "obj-80",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-82",
            0
          ],
          "source": [
            "obj-81",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-83",
            0
          ],
          "source": [
            "obj-82",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-104",
            0
          ],
          "order": 1,
          "source": [
            "obj-83",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-84",
            0
          ],
          "order": 0,
          "source": [
            "obj-83",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-11",
            0
          ],
          "source": [
            "obj-85",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-12",
            0
          ],
          "source": [
            "obj-89",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            5
          ],
          "source": [
            "obj-9",
            4
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            4
          ],
          "source": [
            "obj-9",
            3
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            3
          ],
          "source": [
            "obj-9",
            2
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            2
          ],
          "source": [
            "obj-9",
            1
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-10",
            1
          ],
          "source": [
            "obj-9",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-15",
            0
          ],
          "source": [
            "obj-90",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-25",
            0
          ],
          "source": [
            "obj-92",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-35",
            0
          ],
          "source": [
            "obj-94",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-45",
            0
          ],
          "source": [
            "obj-96",
            0
          ]
        }
      },
      {
        "patchline": {
          "destination": [
            "obj-55",
            0
          ],
          "source": [
            "obj-98",
            0
          ]
        }
      }
    ],
    "autosave": 0
  }
}