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
        "rect": [ 100.0, 100.0, 800.0, 600.0 ],
        "openinpresentation": 1,
        "boxes": [
            {
                "box": {
                    "fontface": 0,
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-7",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 35.0, 35.0, 81.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 47.0, 0.0, 81.0, 21.0 ],
                    "text": "vecfield",
                    "textcolor": [ 0.45098039215686275, 0.47058823529411764, 0.5764705882352941, 1.0 ]
                }
            },
            {
                "box": {
                    "comment": "texture in",
                    "id": "obj-1",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 30.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "light src",
                    "id": "obj-50",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 100.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "vec field",
                    "id": "obj-51",
                    "index": 0,
                    "maxclass": "inlet",
                    "numinlets": 0,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 170.0, 30.0, 30.0, 30.0 ]
                }
            },
            {
                "box": {
                    "comment": "composited",
                    "id": "obj-2",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 30.0, 560.0, 30.0, 30.0 ],
                    "tricolor": [ 0.9529411764705882, 0.6901960784313725, 0.6196078431372549, 1.0 ]
                }
            },
            {
                "box": {
                    "comment": "caustic layer",
                    "id": "obj-52",
                    "index": 0,
                    "maxclass": "outlet",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 100.0, 560.0, 30.0, 30.0 ],
                    "tricolor": [ 0.6196078431372549, 0.9529411764705882, 0.6588235294117647, 1.0 ]
                }
            },
            {
                "box": {
                    "id": "obj-3",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "", "", "" ],
                    "patching_rect": [ 200.0, 90.0, 215.0, 22.0 ],
                    "text": "routepass jit_gl_texture jit_matrix"
                }
            },
            {
                "box": {
                    "id": "obj-4",
                    "maxclass": "newobj",
                    "numinlets": 5,
                    "numoutlets": 5,
                    "outlettype": [ "", "", "", "", "" ],
                    "patching_rect": [ 200.0, 130.0, 252.0, 22.0 ],
                    "text": "route intensity scale softness color_shift"
                }
            },
            {
                "box": {
                    "id": "obj-5",
                    "maxclass": "newobj",
                    "numinlets": 3,
                    "numoutlets": 3,
                    "outlettype": [ "jit_gl_texture", "jit_gl_texture", "" ],
                    "patcher": {
                        "fileversion": 1,
                        "appversion": {
                            "major": 9,
                            "minor": 1,
                            "revision": 4,
                            "architecture": "x64",
                            "modernui": 1
                        },
                        "classnamespace": "jit.gen",
                        "rect": [ 100.0, 100.0, 700.0, 600.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "gen-obj-1",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 22.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-2",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 80.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 2"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-3",
                                    "maxclass": "newobj",
                                    "numinlets": 0,
                                    "numoutlets": 1,
                                    "outlettype": [ "" ],
                                    "patching_rect": [ 138.0, 30.0, 28.0, 22.0 ],
                                    "text": "in 3"
                                }
                            },
                            {
                                "box": {
                                    "code": "// f_caustic codebox v4 — per-channel displaced trace for chromatic aberration\n// Local field direction at uv used to offset R and B starting UVs\n// cs = color_shift * 0.15, decoupled from step_size\n// in2 = light source texture\n// in3 = f_vecfield (RG encoded: 0.5 = zero, 0=neg, 1=pos)\n\nParam intensity(0.5);\nParam scale(0.3);\nParam softness(0.3);\nParam color_shift(0.0);\nParam bypass(0.0);\n\nuv = norm;\n\nh = 1.0 / 512.0;\nstep_size = scale / 8.0;\ncs = color_shift * 0.15;\n\n// --- local field direction at uv for chromatic offset ---\n// just one sample — no pre-trace needed\nlf_x = (sample(in3, uv).x - 0.5) * 2.0;\nlf_y = (sample(in3, uv).y - 0.5) * 2.0;\nlf_len = sqrt(lf_x*lf_x + lf_y*lf_y) + 0.0001;\nlf_nx = lf_x / lf_len;\nlf_ny = lf_y / lf_len;\n\n// --- three starting UVs ---\n// perpendicular to field direction: symmetric R/B around attractor\nuvRx = uv.x + (-lf_ny) * cs; uvRy = uv.y + lf_nx * cs;\nuvGx = uv.x;                  uvGy = uv.y;\nuvBx = uv.x - (-lf_ny) * cs; uvBy = uv.y - lf_nx * cs;\n\n// =============================================================\n// GREEN accumulation (reference trace)\n// =============================================================\npos0x = uvGx; pos0y = uvGy;\nf0x = (sample(in3, vec(pos0x, pos0y)).x - 0.5) * 2.0;\nf0y = (sample(in3, vec(pos0x, pos0y)).y - 0.5) * 2.0;\ndiv0 = ((sample(in3, vec(pos0x+h, pos0y)).x - sample(in3, vec(pos0x-h, pos0y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos0x, pos0y+h)).y - sample(in3, vec(pos0x, pos0y-h)).y) * 2.0 / (2.0*h));\nw0 = max(-div0, 0.0);\nsg0 = sample(in2, vec(pos0x, pos0y)).y;\n\npos1x = pos0x - f0x*step_size; pos1y = pos0y - f0y*step_size;\nf1x = (sample(in3, vec(pos1x, pos1y)).x - 0.5) * 2.0;\nf1y = (sample(in3, vec(pos1x, pos1y)).y - 0.5) * 2.0;\ndiv1 = ((sample(in3, vec(pos1x+h, pos1y)).x - sample(in3, vec(pos1x-h, pos1y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos1x, pos1y+h)).y - sample(in3, vec(pos1x, pos1y-h)).y) * 2.0 / (2.0*h));\nw1 = max(-div1, 0.0);\nsg1 = sample(in2, vec(pos1x, pos1y)).y;\n\npos2x = pos1x - f1x*step_size; pos2y = pos1y - f1y*step_size;\nf2x = (sample(in3, vec(pos2x, pos2y)).x - 0.5) * 2.0;\nf2y = (sample(in3, vec(pos2x, pos2y)).y - 0.5) * 2.0;\ndiv2 = ((sample(in3, vec(pos2x+h, pos2y)).x - sample(in3, vec(pos2x-h, pos2y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos2x, pos2y+h)).y - sample(in3, vec(pos2x, pos2y-h)).y) * 2.0 / (2.0*h));\nw2 = max(-div2, 0.0);\nsg2 = sample(in2, vec(pos2x, pos2y)).y;\n\npos3x = pos2x - f2x*step_size; pos3y = pos2y - f2y*step_size;\nf3x = (sample(in3, vec(pos3x, pos3y)).x - 0.5) * 2.0;\nf3y = (sample(in3, vec(pos3x, pos3y)).y - 0.5) * 2.0;\ndiv3 = ((sample(in3, vec(pos3x+h, pos3y)).x - sample(in3, vec(pos3x-h, pos3y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos3x, pos3y+h)).y - sample(in3, vec(pos3x, pos3y-h)).y) * 2.0 / (2.0*h));\nw3 = max(-div3, 0.0);\nsg3 = sample(in2, vec(pos3x, pos3y)).y;\n\npos4x = pos3x - f3x*step_size; pos4y = pos3y - f3y*step_size;\nf4x = (sample(in3, vec(pos4x, pos4y)).x - 0.5) * 2.0;\nf4y = (sample(in3, vec(pos4x, pos4y)).y - 0.5) * 2.0;\ndiv4 = ((sample(in3, vec(pos4x+h, pos4y)).x - sample(in3, vec(pos4x-h, pos4y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos4x, pos4y+h)).y - sample(in3, vec(pos4x, pos4y-h)).y) * 2.0 / (2.0*h));\nw4 = max(-div4, 0.0);\nsg4 = sample(in2, vec(pos4x, pos4y)).y;\n\npos5x = pos4x - f4x*step_size; pos5y = pos4y - f4y*step_size;\nf5x = (sample(in3, vec(pos5x, pos5y)).x - 0.5) * 2.0;\nf5y = (sample(in3, vec(pos5x, pos5y)).y - 0.5) * 2.0;\ndiv5 = ((sample(in3, vec(pos5x+h, pos5y)).x - sample(in3, vec(pos5x-h, pos5y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos5x, pos5y+h)).y - sample(in3, vec(pos5x, pos5y-h)).y) * 2.0 / (2.0*h));\nw5 = max(-div5, 0.0);\nsg5 = sample(in2, vec(pos5x, pos5y)).y;\n\npos6x = pos5x - f5x*step_size; pos6y = pos5y - f5y*step_size;\nf6x = (sample(in3, vec(pos6x, pos6y)).x - 0.5) * 2.0;\nf6y = (sample(in3, vec(pos6x, pos6y)).y - 0.5) * 2.0;\ndiv6 = ((sample(in3, vec(pos6x+h, pos6y)).x - sample(in3, vec(pos6x-h, pos6y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos6x, pos6y+h)).y - sample(in3, vec(pos6x, pos6y-h)).y) * 2.0 / (2.0*h));\nw6 = max(-div6, 0.0);\nsg6 = sample(in2, vec(pos6x, pos6y)).y;\n\npos7x = pos6x - f6x*step_size; pos7y = pos6y - f6y*step_size;\nf7x = (sample(in3, vec(pos7x, pos7y)).x - 0.5) * 2.0;\nf7y = (sample(in3, vec(pos7x, pos7y)).y - 0.5) * 2.0;\ndiv7 = ((sample(in3, vec(pos7x+h, pos7y)).x - sample(in3, vec(pos7x-h, pos7y)).x) * 2.0 / (2.0*h))\n      +((sample(in3, vec(pos7x, pos7y+h)).y - sample(in3, vec(pos7x, pos7y-h)).y) * 2.0 / (2.0*h));\nw7 = max(-div7, 0.0);\nsg7 = sample(in2, vec(pos7x, pos7y)).y;\n\naccum_g = (w0*sg0 + w1*sg1 + w2*sg2 + w3*sg3 + w4*sg4 + w5*sg5 + w6*sg6 + w7*sg7);\n\n// =============================================================\n// RED accumulation (trace from uvR)\n// =============================================================\nrpos0x = uvRx; rpos0y = uvRy;\nrf0x = (sample(in3, vec(rpos0x, rpos0y)).x - 0.5) * 2.0;\nrf0y = (sample(in3, vec(rpos0x, rpos0y)).y - 0.5) * 2.0;\nrdiv0 = ((sample(in3, vec(rpos0x+h, rpos0y)).x - sample(in3, vec(rpos0x-h, rpos0y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos0x, rpos0y+h)).y - sample(in3, vec(rpos0x, rpos0y-h)).y) * 2.0 / (2.0*h));\nrw0 = max(-rdiv0, 0.0);\nsr0 = sample(in2, vec(rpos0x, rpos0y)).x;\n\nrpos1x = rpos0x - rf0x*step_size; rpos1y = rpos0y - rf0y*step_size;\nrf1x = (sample(in3, vec(rpos1x, rpos1y)).x - 0.5) * 2.0;\nrf1y = (sample(in3, vec(rpos1x, rpos1y)).y - 0.5) * 2.0;\nrdiv1 = ((sample(in3, vec(rpos1x+h, rpos1y)).x - sample(in3, vec(rpos1x-h, rpos1y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos1x, rpos1y+h)).y - sample(in3, vec(rpos1x, rpos1y-h)).y) * 2.0 / (2.0*h));\nrw1 = max(-rdiv1, 0.0);\nsr1 = sample(in2, vec(rpos1x, rpos1y)).x;\n\nrpos2x = rpos1x - rf1x*step_size; rpos2y = rpos1y - rf1y*step_size;\nrf2x = (sample(in3, vec(rpos2x, rpos2y)).x - 0.5) * 2.0;\nrf2y = (sample(in3, vec(rpos2x, rpos2y)).y - 0.5) * 2.0;\nrdiv2 = ((sample(in3, vec(rpos2x+h, rpos2y)).x - sample(in3, vec(rpos2x-h, rpos2y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos2x, rpos2y+h)).y - sample(in3, vec(rpos2x, rpos2y-h)).y) * 2.0 / (2.0*h));\nrw2 = max(-rdiv2, 0.0);\nsr2 = sample(in2, vec(rpos2x, rpos2y)).x;\n\nrpos3x = rpos2x - rf2x*step_size; rpos3y = rpos2y - rf2y*step_size;\nrf3x = (sample(in3, vec(rpos3x, rpos3y)).x - 0.5) * 2.0;\nrf3y = (sample(in3, vec(rpos3x, rpos3y)).y - 0.5) * 2.0;\nrdiv3 = ((sample(in3, vec(rpos3x+h, rpos3y)).x - sample(in3, vec(rpos3x-h, rpos3y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos3x, rpos3y+h)).y - sample(in3, vec(rpos3x, rpos3y-h)).y) * 2.0 / (2.0*h));\nrw3 = max(-rdiv3, 0.0);\nsr3 = sample(in2, vec(rpos3x, rpos3y)).x;\n\nrpos4x = rpos3x - rf3x*step_size; rpos4y = rpos3y - rf3y*step_size;\nrf4x = (sample(in3, vec(rpos4x, rpos4y)).x - 0.5) * 2.0;\nrf4y = (sample(in3, vec(rpos4x, rpos4y)).y - 0.5) * 2.0;\nrdiv4 = ((sample(in3, vec(rpos4x+h, rpos4y)).x - sample(in3, vec(rpos4x-h, rpos4y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos4x, rpos4y+h)).y - sample(in3, vec(rpos4x, rpos4y-h)).y) * 2.0 / (2.0*h));\nrw4 = max(-rdiv4, 0.0);\nsr4 = sample(in2, vec(rpos4x, rpos4y)).x;\n\nrpos5x = rpos4x - rf4x*step_size; rpos5y = rpos4y - rf4y*step_size;\nrf5x = (sample(in3, vec(rpos5x, rpos5y)).x - 0.5) * 2.0;\nrf5y = (sample(in3, vec(rpos5x, rpos5y)).y - 0.5) * 2.0;\nrdiv5 = ((sample(in3, vec(rpos5x+h, rpos5y)).x - sample(in3, vec(rpos5x-h, rpos5y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos5x, rpos5y+h)).y - sample(in3, vec(rpos5x, rpos5y-h)).y) * 2.0 / (2.0*h));\nrw5 = max(-rdiv5, 0.0);\nsr5 = sample(in2, vec(rpos5x, rpos5y)).x;\n\nrpos6x = rpos5x - rf5x*step_size; rpos6y = rpos5y - rf5y*step_size;\nrf6x = (sample(in3, vec(rpos6x, rpos6y)).x - 0.5) * 2.0;\nrf6y = (sample(in3, vec(rpos6x, rpos6y)).y - 0.5) * 2.0;\nrdiv6 = ((sample(in3, vec(rpos6x+h, rpos6y)).x - sample(in3, vec(rpos6x-h, rpos6y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos6x, rpos6y+h)).y - sample(in3, vec(rpos6x, rpos6y-h)).y) * 2.0 / (2.0*h));\nrw6 = max(-rdiv6, 0.0);\nsr6 = sample(in2, vec(rpos6x, rpos6y)).x;\n\nrpos7x = rpos6x - rf6x*step_size; rpos7y = rpos6y - rf6y*step_size;\nrf7x = (sample(in3, vec(rpos7x, rpos7y)).x - 0.5) * 2.0;\nrf7y = (sample(in3, vec(rpos7x, rpos7y)).y - 0.5) * 2.0;\nrdiv7 = ((sample(in3, vec(rpos7x+h, rpos7y)).x - sample(in3, vec(rpos7x-h, rpos7y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(rpos7x, rpos7y+h)).y - sample(in3, vec(rpos7x, rpos7y-h)).y) * 2.0 / (2.0*h));\nrw7 = max(-rdiv7, 0.0);\nsr7 = sample(in2, vec(rpos7x, rpos7y)).x;\n\naccum_r = (rw0*sr0 + rw1*sr1 + rw2*sr2 + rw3*sr3 + rw4*sr4 + rw5*sr5 + rw6*sr6 + rw7*sr7);\n\n// =============================================================\n// BLUE accumulation (trace from uvB)\n// =============================================================\nbpos0x = uvBx; bpos0y = uvBy;\nbf0x = (sample(in3, vec(bpos0x, bpos0y)).x - 0.5) * 2.0;\nbf0y = (sample(in3, vec(bpos0x, bpos0y)).y - 0.5) * 2.0;\nbdiv0 = ((sample(in3, vec(bpos0x+h, bpos0y)).x - sample(in3, vec(bpos0x-h, bpos0y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos0x, bpos0y+h)).y - sample(in3, vec(bpos0x, bpos0y-h)).y) * 2.0 / (2.0*h));\nbw0 = max(-bdiv0, 0.0);\nsb0 = sample(in2, vec(bpos0x, bpos0y)).z;\n\nbpos1x = bpos0x - bf0x*step_size; bpos1y = bpos0y - bf0y*step_size;\nbf1x = (sample(in3, vec(bpos1x, bpos1y)).x - 0.5) * 2.0;\nbf1y = (sample(in3, vec(bpos1x, bpos1y)).y - 0.5) * 2.0;\nbdiv1 = ((sample(in3, vec(bpos1x+h, bpos1y)).x - sample(in3, vec(bpos1x-h, bpos1y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos1x, bpos1y+h)).y - sample(in3, vec(bpos1x, bpos1y-h)).y) * 2.0 / (2.0*h));\nbw1 = max(-bdiv1, 0.0);\nsb1 = sample(in2, vec(bpos1x, bpos1y)).z;\n\nbpos2x = bpos1x - bf1x*step_size; bpos2y = bpos1y - bf1y*step_size;\nbf2x = (sample(in3, vec(bpos2x, bpos2y)).x - 0.5) * 2.0;\nbf2y = (sample(in3, vec(bpos2x, bpos2y)).y - 0.5) * 2.0;\nbdiv2 = ((sample(in3, vec(bpos2x+h, bpos2y)).x - sample(in3, vec(bpos2x-h, bpos2y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos2x, bpos2y+h)).y - sample(in3, vec(bpos2x, bpos2y-h)).y) * 2.0 / (2.0*h));\nbw2 = max(-bdiv2, 0.0);\nsb2 = sample(in2, vec(bpos2x, bpos2y)).z;\n\nbpos3x = bpos2x - bf2x*step_size; bpos3y = bpos2y - bf2y*step_size;\nbf3x = (sample(in3, vec(bpos3x, bpos3y)).x - 0.5) * 2.0;\nbf3y = (sample(in3, vec(bpos3x, bpos3y)).y - 0.5) * 2.0;\nbdiv3 = ((sample(in3, vec(bpos3x+h, bpos3y)).x - sample(in3, vec(bpos3x-h, bpos3y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos3x, bpos3y+h)).y - sample(in3, vec(bpos3x, bpos3y-h)).y) * 2.0 / (2.0*h));\nbw3 = max(-bdiv3, 0.0);\nsb3 = sample(in2, vec(bpos3x, bpos3y)).z;\n\nbpos4x = bpos3x - bf3x*step_size; bpos4y = bpos3y - bf3y*step_size;\nbf4x = (sample(in3, vec(bpos4x, bpos4y)).x - 0.5) * 2.0;\nbf4y = (sample(in3, vec(bpos4x, bpos4y)).y - 0.5) * 2.0;\nbdiv4 = ((sample(in3, vec(bpos4x+h, bpos4y)).x - sample(in3, vec(bpos4x-h, bpos4y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos4x, bpos4y+h)).y - sample(in3, vec(bpos4x, bpos4y-h)).y) * 2.0 / (2.0*h));\nbw4 = max(-bdiv4, 0.0);\nsb4 = sample(in2, vec(bpos4x, bpos4y)).z;\n\nbpos5x = bpos4x - bf4x*step_size; bpos5y = bpos4y - bf4y*step_size;\nbf5x = (sample(in3, vec(bpos5x, bpos5y)).x - 0.5) * 2.0;\nbf5y = (sample(in3, vec(bpos5x, bpos5y)).y - 0.5) * 2.0;\nbdiv5 = ((sample(in3, vec(bpos5x+h, bpos5y)).x - sample(in3, vec(bpos5x-h, bpos5y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos5x, bpos5y+h)).y - sample(in3, vec(bpos5x, bpos5y-h)).y) * 2.0 / (2.0*h));\nbw5 = max(-bdiv5, 0.0);\nsb5 = sample(in2, vec(bpos5x, bpos5y)).z;\n\nbpos6x = bpos5x - bf5x*step_size; bpos6y = bpos5y - bf5y*step_size;\nbf6x = (sample(in3, vec(bpos6x, bpos6y)).x - 0.5) * 2.0;\nbf6y = (sample(in3, vec(bpos6x, bpos6y)).y - 0.5) * 2.0;\nbdiv6 = ((sample(in3, vec(bpos6x+h, bpos6y)).x - sample(in3, vec(bpos6x-h, bpos6y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos6x, bpos6y+h)).y - sample(in3, vec(bpos6x, bpos6y-h)).y) * 2.0 / (2.0*h));\nbw6 = max(-bdiv6, 0.0);\nsb6 = sample(in2, vec(bpos6x, bpos6y)).z;\n\nbpos7x = bpos6x - bf6x*step_size; bpos7y = bpos6y - bf6y*step_size;\nbf7x = (sample(in3, vec(bpos7x, bpos7y)).x - 0.5) * 2.0;\nbf7y = (sample(in3, vec(bpos7x, bpos7y)).y - 0.5) * 2.0;\nbdiv7 = ((sample(in3, vec(bpos7x+h, bpos7y)).x - sample(in3, vec(bpos7x-h, bpos7y)).x) * 2.0 / (2.0*h))\n       +((sample(in3, vec(bpos7x, bpos7y+h)).y - sample(in3, vec(bpos7x, bpos7y-h)).y) * 2.0 / (2.0*h));\nbw7 = max(-bdiv7, 0.0);\nsb7 = sample(in2, vec(bpos7x, bpos7y)).z;\n\naccum_b = (bw0*sb0 + bw1*sb1 + bw2*sb2 + bw3*sb3 + bw4*sb4 + bw5*sb5 + bw6*sb6 + bw7*sb7);\n\n// =============================================================\n// normalize, intensity, softness\n// =============================================================\nnorm_factor = 1.0 / 8.0;\ncaustic_r = accum_r * norm_factor * intensity;\ncaustic_g = accum_g * norm_factor * intensity;\ncaustic_b = accum_b * norm_factor * intensity;\n\nluma = caustic_r * 0.299 + caustic_g * 0.587 + caustic_b * 0.114;\nsoft_mask = smoothstep(0.0, softness + 0.001, luma);\ncaustic_r = caustic_r * soft_mask;\ncaustic_g = caustic_g * soft_mask;\ncaustic_b = caustic_b * soft_mask;\n\n// color_shift saturation: attenuate G, boost R and B\ncaustic_g = caustic_g * (1.0 - color_shift * 0.3);\ncaustic_r = caustic_r * (1.0 + color_shift * 0.5);\ncaustic_b = caustic_b * (1.0 + color_shift * 0.5);\n\n// out2: isolated caustic layer\ncaustic_out = vec(clamp(caustic_r, 0.0, 1.0),\n                  clamp(caustic_g, 0.0, 1.0),\n                  clamp(caustic_b, 0.0, 1.0),\n                  1.0);\n\n// out1: additive composite over source\nsrc_r = sample(in2, uv).x;\nsrc_g = sample(in2, uv).y;\nsrc_b = sample(in2, uv).z;\n\ncomposite = vec(clamp(src_r + caustic_r, 0.0, 1.0),\n                clamp(src_g + caustic_g, 0.0, 1.0),\n                clamp(src_b + caustic_b, 0.0, 1.0),\n                1.0);\n\nsource_pass = vec(src_r, src_g, src_b, 1.0);\nblack = vec(0.0, 0.0, 0.0, 1.0);\n\nout1 = mix(composite, source_pass, bypass);\nout2 = mix(caustic_out, black, bypass);",
                                    "fontface": 0,
                                    "fontname": "<Monospaced>",
                                    "fontsize": 12.0,
                                    "id": "gen-obj-4",
                                    "maxclass": "codebox",
                                    "numinlets": 3,
                                    "numoutlets": 2,
                                    "outlettype": [ "", "" ],
                                    "patching_rect": [ 22.0, 80.0, 580.0, 440.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-5",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 22.0, 540.0, 35.0, 22.0 ],
                                    "text": "out 1"
                                }
                            },
                            {
                                "box": {
                                    "id": "gen-obj-6",
                                    "maxclass": "newobj",
                                    "numinlets": 1,
                                    "numoutlets": 0,
                                    "patching_rect": [ 100.0, 540.0, 35.0, 22.0 ],
                                    "text": "out 2"
                                }
                            }
                        ],
                        "lines": [
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-4", 0 ],
                                    "source": [ "gen-obj-1", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-4", 1 ],
                                    "source": [ "gen-obj-2", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-4", 2 ],
                                    "source": [ "gen-obj-3", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-5", 0 ],
                                    "source": [ "gen-obj-4", 0 ]
                                }
                            },
                            {
                                "patchline": {
                                    "destination": [ "gen-obj-6", 0 ],
                                    "source": [ "gen-obj-4", 1 ]
                                }
                            }
                        ]
                    },
                    "patching_rect": [ 200.0, 380.0, 320.0, 22.0 ],
                    "text": "jit.gl.pix vsynth @name caustic_pix @type float32",
                    "varname": "caustic_pix"
                }
            },
            {
                "box": {
                    "id": "obj-6",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 4,
                    "outlettype": [ "", "", "", "" ],
                    "patching_rect": [ 500.0, 500.0, 56.0, 22.0 ],
                    "restore": {
                        "bypass": [ 0 ],
                        "color_shift": [ 0.0 ],
                        "intensity": [ 0.5 ],
                        "scale": [ 0.3 ],
                        "softness": [ 0.3 ]
                    },
                    "text": "autopattr",
                    "varname": "caustic_autopattr"
                }
            },
            {
                "box": {
                    "id": "obj-53",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 100.0, 80.0, 80.0, 22.0 ],
                    "text": "vs_inState"
                }
            },
            {
                "box": {
                    "angle": 270.0,
                    "background": 1,
                    "bgcolor": [ 0.0, 0.0, 0.0, 1.0 ],
                    "border": 1,
                    "bordercolor": [ 0.0, 0.03529411765, 0.2274509804, 1.0 ],
                    "id": "obj-9",
                    "maxclass": "panel",
                    "mode": 0,
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 190.0, 100.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 0.0, 0.0, 162.0, 92.0 ],
                    "proportion": 0.5
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 12.0,
                    "id": "obj-10",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 20.0, 20.0, 80.0, 21.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -1.5, 0.0, 80.0, 21.0 ],
                    "text": "Caustic"
                }
            },
            {
                "box": {
                    "id": "obj-11",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "bang" ],
                    "patching_rect": [ 600.0, 50.0, 60.0, 22.0 ],
                    "text": "loadbang"
                }
            },
            {
                "box": {
                    "id": "obj-12",
                    "maxclass": "message",
                    "numinlets": 2,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 80.0, 180.0, 22.0 ],
                    "text": "getattr presentation_rect"
                }
            },
            {
                "box": {
                    "id": "obj-13",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 600.0, 110.0, 80.0, 22.0 ],
                    "save": [ "#N", "thispatcher", ";", "#Q", "end", ";" ],
                    "text": "thispatcher"
                }
            },
            {
                "box": {
                    "id": "obj-14",
                    "maxclass": "newobj",
                    "numinlets": 2,
                    "numoutlets": 2,
                    "outlettype": [ "", "" ],
                    "patching_rect": [ 600.0, 140.0, 60.0, 22.0 ],
                    "text": "zl slice 2"
                }
            },
            {
                "box": {
                    "id": "obj-15",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 170.0, 80.0, 22.0 ],
                    "text": "prepend tam"
                }
            },
            {
                "box": {
                    "id": "obj-16",
                    "maxclass": "newobj",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "patching_rect": [ 600.0, 200.0, 100.0, 22.0 ],
                    "saved_object_attributes": {
                        "filename": "moduleSize.js",
                        "parameter_enable": 0
                    },
                    "text": "js moduleSize.js"
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-20",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "caustic_pix::intensity",
                    "parameter_enable": 1,
                    "patching_rect": [ 50.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 4.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.5 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "intensity",
                            "parameter_mmax": 2.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "intensity",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "intensity"
                }
            },
            {
                "box": {
                    "attr": "intensity",
                    "id": "obj-21",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 50.0, 170.0, 140.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-22",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 50.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ -7.5, 20.0, 50.0, 18.0 ],
                    "text": "Intens",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-23",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "caustic_pix::scale",
                    "parameter_enable": 1,
                    "patching_rect": [ 100.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 41.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.3 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "scale",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "scale",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "scale"
                }
            },
            {
                "box": {
                    "attr": "scale",
                    "id": "obj-24",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 100.0, 170.0, 140.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-25",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 100.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 29.5, 20.0, 50.0, 18.0 ],
                    "text": "Scale",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-26",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "caustic_pix::softness",
                    "parameter_enable": 1,
                    "patching_rect": [ 150.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 78.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.3 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "softness",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "softness",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "softness"
                }
            },
            {
                "box": {
                    "attr": "softness",
                    "id": "obj-27",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 150.0, 170.0, 140.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-28",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 150.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 66.5, 20.0, 50.0, 18.0 ],
                    "text": "Soft",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "activedialcolor": [ 0.8, 0.8, 0.8, 1.0 ],
                    "fontname": "Ableton Sans Light",
                    "hint": "",
                    "id": "obj-29",
                    "maxclass": "live.dial",
                    "numinlets": 1,
                    "numoutlets": 2,
                    "outlettype": [ "", "float" ],
                    "param_connect": "caustic_pix::color_shift",
                    "parameter_enable": 1,
                    "patching_rect": [ 200.0, 80.0, 27.0, 43.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 115.0, 38.0, 27.0, 43.0 ],
                    "saved_attribute_attributes": {
                        "activedialcolor": {
                            "expression": ""
                        },
                        "valueof": {
                            "parameter_initial": [ 0.0 ],
                            "parameter_initial_enable": 1,
                            "parameter_linknames": 1,
                            "parameter_longname": "color_shift",
                            "parameter_mmax": 1.0,
                            "parameter_modmode": 3,
                            "parameter_shortname": "color_shift",
                            "parameter_type": 0,
                            "parameter_unitstyle": 1
                        }
                    },
                    "showname": 0,
                    "triangle": 1,
                    "valuepopup": 1,
                    "valuepopuplabel": 1,
                    "varname": "color_shift"
                }
            },
            {
                "box": {
                    "attr": "color_shift",
                    "id": "obj-30",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 200.0, 170.0, 140.0, 22.0 ]
                }
            },
            {
                "box": {
                    "fontname": "Ableton Sans Light",
                    "fontsize": 9.5,
                    "id": "obj-31",
                    "maxclass": "comment",
                    "numinlets": 1,
                    "numoutlets": 0,
                    "patching_rect": [ 200.0, 130.0, 50.0, 18.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 103.5, 20.0, 50.0, 18.0 ],
                    "text": "Color",
                    "textjustification": 1
                }
            },
            {
                "box": {
                    "filename": "bypass_toggle.js",
                    "hint": "Bypass",
                    "id": "obj-32",
                    "maxclass": "jsui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 168.0, 5.0, 18.0, 12.0 ],
                    "presentation": 1,
                    "presentation_rect": [ 138.0, 5.0, 18.0, 12.0 ],
                    "valuepopuplabel": 1,
                    "varname": "bypass"
                }
            },
            {
                "box": {
                    "attr": "bypass",
                    "id": "obj-33",
                    "maxclass": "attrui",
                    "numinlets": 1,
                    "numoutlets": 1,
                    "outlettype": [ "" ],
                    "parameter_enable": 0,
                    "patching_rect": [ 400.0, 60.0, 131.0, 22.0 ]
                }
            }
        ],
        "lines": [
            {
                "patchline": {
                    "destination": [ "obj-3", 0 ],
                    "source": [ "obj-1", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-12", 0 ],
                    "source": [ "obj-11", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-13", 0 ],
                    "source": [ "obj-12", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-14", 0 ],
                    "source": [ "obj-13", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-15", 0 ],
                    "source": [ "obj-14", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-16", 0 ],
                    "source": [ "obj-15", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-21", 0 ],
                    "source": [ "obj-20", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-21", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-24", 0 ],
                    "source": [ "obj-23", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-24", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-27", 0 ],
                    "source": [ "obj-26", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-27", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-30", 0 ],
                    "source": [ "obj-29", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-4", 0 ],
                    "source": [ "obj-3", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-3", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-30", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-33", 0 ],
                    "source": [ "obj-32", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 0 ],
                    "source": [ "obj-33", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-20", 0 ],
                    "source": [ "obj-4", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-23", 0 ],
                    "source": [ "obj-4", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-26", 0 ],
                    "source": [ "obj-4", 2 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-29", 0 ],
                    "source": [ "obj-4", 3 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-2", 0 ],
                    "source": [ "obj-5", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-52", 0 ],
                    "source": [ "obj-5", 1 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-53", 0 ],
                    "source": [ "obj-50", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 2 ],
                    "source": [ "obj-51", 0 ]
                }
            },
            {
                "patchline": {
                    "destination": [ "obj-5", 1 ],
                    "source": [ "obj-53", 0 ]
                }
            }
        ],
        "parameters": {
            "obj-20": [ "intensity", "intensity", 0 ],
            "obj-23": [ "scale", "scale", 0 ],
            "obj-26": [ "softness", "softness", 0 ],
            "obj-29": [ "color_shift", "color_shift", 0 ],
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