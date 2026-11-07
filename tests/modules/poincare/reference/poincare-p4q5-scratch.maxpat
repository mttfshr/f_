{
    "patcher": {
        "fileversion": 1,
        "appversion": { "major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1 },
        "classnamespace": "box",
        "rect": [ 59.0, 114.0, 1000.0, 850.0 ],
        "boxes": [
            {
                "box": {
                    "bgmode": 0, "border": 0, "clickthrough": 0, "enablehscroll": 0, "enablevscroll": 0,
                    "id": "obj-6", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher", "name": "f_modules.maxpat",
                    "numinlets": 0, "numoutlets": 0, "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 339.0, 96.0, 249.0 ], "viewvisibility": 1
                }
            },
            {
                "box": {
                    "id": "obj-2", "maxclass": "newobj", "numinlets": 0, "numoutlets": 1,
                    "outlettype": [ "" ], "patching_rect": [ 226.0, 241.0, 42.0, 22.0 ], "text": "r draw"
                }
            },
            {
                "box": {
                    "id": "obj-5", "maxclass": "newobj", "numinlets": 1, "numoutlets": 2,
                    "outlettype": [ "jit_gl_texture", "" ],
                    "patcher": {
                        "fileversion": 1,
                        "appversion": { "major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1 },
                        "classnamespace": "jit.gen",
                        "rect": [ 107.0, 95.0, 1161.0, 801.0 ],
                        "boxes": [
                            {
                                "box": {
                                    "id": "obj-1", "maxclass": "newobj", "numinlets": 0, "numoutlets": 1,
                                    "outlettype": [ "" ], "patching_rect": [ 50.0, 14.0, 28.0, 22.0 ], "text": "in 1"
                                }
                            },
                            {
                                "box": {
                                    "code": "invertX(px, py, cx, cy, r2) {\n    dx = px - cx;\n    dy = py - cy;\n    p2 = max(dx*dx + dy*dy, 0.0001);\n    return dx * (r2 / p2) + cx;\n}\n\ninvertY(px, py, cx, cy, r2) {\n    dx = px - cx;\n    dy = py - cy;\n    p2 = max(dx*dx + dy*dy, 0.0001);\n    return dy * (r2 / p2) + cy;\n}\n\ncmulre(are, aim, bre, bim) {\n    return are*bre - aim*bim;\n}\n\ncmulim(are, aim, bre, bim) {\n    return are*bim + aim*bre;\n}\n\ncdivre(are, aim, bre, bim) {\n    dd = max(bre*bre + bim*bim, 0.0001);\n    return (are*bre + aim*bim) / dd;\n}\n\ncdivim(are, aim, bre, bim) {\n    dd = max(bre*bre + bim*bim, 0.0001);\n    return (aim*bre - are*bim) / dd;\n}\n\nmobPtX(Are,Aim,Bre,Bim,Cre,Cim,Dre,Dim,Px,Py) {\n    numre = cmulre(Px,Py,Are,Aim) + Bre;\n    numim = cmulim(Px,Py,Are,Aim) + Bim;\n    denre = cmulre(Px,Py,Cre,Cim) + Dre;\n    denim = cmulim(Px,Py,Cre,Cim) + Dim;\n    return cdivre(numre,numim,denre,denim);\n}\n\nmobPtY(Are,Aim,Bre,Bim,Cre,Cim,Dre,Dim,Px,Py) {\n    numre = cmulre(Px,Py,Are,Aim) + Bre;\n    numim = cmulim(Px,Py,Are,Aim) + Bim;\n    denre = cmulre(Px,Py,Cre,Cim) + Dre;\n    denim = cmulim(Px,Py,Cre,Cim) + Dim;\n    return cdivim(numre,numim,denre,denim);\n}\n\nParam edge_d(2.0581710272714915);\nParam edge_r2(3.2360679774997867);\nParam scale(1.0);\nParam use_mapped(1.0);\n\ntheta = pi / 4.0;\n\nc0x = edge_d*sin(0.0*theta*2.0); c0y = edge_d*cos(0.0*theta*2.0);\nc1x = edge_d*sin(1.0*theta*2.0); c1y = edge_d*cos(1.0*theta*2.0);\nc2x = edge_d*sin(2.0*theta*2.0); c2y = edge_d*cos(2.0*theta*2.0);\nc3x = edge_d*sin(3.0*theta*2.0); c3y = edge_d*cos(3.0*theta*2.0);\n\nzx0 = snorm.x * scale;\nzy0 = snorm.y * scale;\nzx = zx0;\nzy = zy0;\n\nalive = 1.0;\ndepth = 0.0;\nlast_id = -1.0;\n\nNare = 1.0; Naim = 0.0;\nNbre = 0.0; Nbim = 0.0;\nNcre = 0.0; Ncim = 0.0;\nNdre = 1.0; Ndim = 0.0;\n\nfor (i = 0; i < 24; i += 1) {\n    ins0 = step((zx-c0x)*(zx-c0x) + (zy-c0y)*(zy-c0y), edge_r2);\n    ins1 = step((zx-c1x)*(zx-c1x) + (zy-c1y)*(zy-c1y), edge_r2);\n    ins2 = step((zx-c2x)*(zx-c2x) + (zy-c2y)*(zy-c2y), edge_r2);\n    ins3 = step((zx-c3x)*(zx-c3x) + (zy-c3y)*(zy-c3y), edge_r2);\n\n    any_inside = max(max(ins0,ins1),max(ins2,ins3));\n    apply_gate = alive * any_inside;\n\n    hit_id = mix(mix(mix(mix(0.0, 4.0, ins3), 3.0, ins2), 2.0, ins1), 1.0, ins0);\n    last_id = mix(last_id, hit_id, apply_gate);\n\n    hit_cx = mix(mix(mix(mix(0.0, c3x, ins3), c2x, ins2), c1x, ins1), c0x, ins0);\n    hit_cy = mix(mix(mix(mix(0.0, c3y, ins3), c2y, ins2), c1y, ins1), c0y, ins0);\n\n    Mare = hit_cx; Maim = hit_cy;\n    Mbre = edge_r2 - (hit_cx*hit_cx + hit_cy*hit_cy); Mbim = 0.0;\n    Mcre = 1.0; Mcim = 0.0;\n    Mdre = 0.0 - hit_cx; Mdim = hit_cy;\n\n    CNare = Nare; CNaim = 0.0 - Naim;\n    CNbre = Nbre; CNbim = 0.0 - Nbim;\n    CNcre = Ncre; CNcim = 0.0 - Ncim;\n    CNdre = Ndre; CNdim = 0.0 - Ndim;\n\n    Nnew_are = cmulre(Mare,Maim,CNare,CNaim) + cmulre(Mbre,Mbim,CNcre,CNcim);\n    Nnew_aim = cmulim(Mare,Maim,CNare,CNaim) + cmulim(Mbre,Mbim,CNcre,CNcim);\n    Nnew_bre = cmulre(Mare,Maim,CNbre,CNbim) + cmulre(Mbre,Mbim,CNdre,CNdim);\n    Nnew_bim = cmulim(Mare,Maim,CNbre,CNbim) + cmulim(Mbre,Mbim,CNdre,CNdim);\n    Nnew_cre = cmulre(Mcre,Mcim,CNare,CNaim) + cmulre(Mdre,Mdim,CNcre,CNcim);\n    Nnew_cim = cmulim(Mcre,Mcim,CNare,CNaim) + cmulim(Mdre,Mdim,CNcre,CNcim);\n    Nnew_dre = cmulre(Mcre,Mcim,CNbre,CNbim) + cmulre(Mdre,Mdim,CNdre,CNdim);\n    Nnew_dim = cmulim(Mcre,Mcim,CNbre,CNbim) + cmulim(Mdre,Mdim,CNdre,CNdim);\n\n    Nare, Nbre = mix(Nare, Nnew_are, apply_gate), mix(Nbre, Nnew_bre, apply_gate);\n    Naim, Nbim = mix(Naim, Nnew_aim, apply_gate), mix(Nbim, Nnew_bim, apply_gate);\n    Ncre, Ndre = mix(Ncre, Nnew_cre, apply_gate), mix(Ndre, Nnew_dre, apply_gate);\n    Ncim, Ndim = mix(Ncim, Nnew_cim, apply_gate), mix(Ndim, Nnew_dim, apply_gate);\n\n    zx, zy = mix(zx, invertX(zx,zy,hit_cx,hit_cy,edge_r2), apply_gate),\n              mix(zy, invertY(zx,zy,hit_cx,hit_cy,edge_r2), apply_gate);\n\n    alive, depth = alive * any_inside, depth + apply_gate;\n}\n\nis_odd = mod(depth, 2.0);\ncheck_holo_x = mobPtX(Nare,Naim,Nbre,Nbim,Ncre,Ncim,Ndre,Ndim, zx0, zy0);\ncheck_holo_y = mobPtY(Nare,Naim,Nbre,Nbim,Ncre,Ncim,Ndre,Ndim, zx0, zy0);\ncheck_holo_xneg = mobPtX(Nare,Naim,Nbre,Nbim,Ncre,Ncim,Ndre,Ndim, zx0, 0.0-zy0);\ncheck_holo_yneg = mobPtY(Nare,Naim,Nbre,Nbim,Ncre,Ncim,Ndre,Ndim, zx0, 0.0-zy0);\ncheck_x = mix(check_holo_x, check_holo_xneg, is_odd);\ncheck_y = mix(check_holo_y, check_holo_yneg, is_odd);\nerr_x = check_x - zx;\nerr_y = check_y - zy;\nerr_mag = sqrt(err_x*err_x + err_y*err_y);\ndebug_ok = step(err_mag, 0.3);\ndebug_col_r = mix(1.0, 0.0, debug_ok);\ndebug_col_g = mix(0.0, 1.0, debug_ok);\ndebug_col_b = 0.0;\n\nis_debug = step(1.5, use_mapped);\nis_depth_view = step(2.5, use_mapped);\nis_err_view = step(3.5, use_mapped);\n\ndepth_r = mod(depth, 2.0);\ndepth_g = mod(floor(depth / 2.0), 2.0);\ndepth_b = mod(floor(depth / 4.0), 2.0);\n\nerr_col_r = 0.5 + 0.5 * clamp(err_x / 1.0, -1.0, 1.0);\nerr_col_g = 0.5 + 0.5 * clamp(err_y / 1.0, -1.0, 1.0);\nerr_col_b = 0.5;\n\nbg = step(last_id, -0.5);\nid_idx = max(last_id, 0.0);\n\ncol_r = mod(id_idx, 2.0);\ncol_g = mod(floor(id_idx / 2.0), 2.0);\ncol_b = step(3.5, id_idx);\n\ncol_r = mix(col_r, 0.3, bg);\ncol_g = mix(col_g, 0.3, bg);\ncol_b = mix(col_b, 0.3, bg);\n\ncol_r = mix(col_r, debug_col_r, is_debug);\ncol_g = mix(col_g, debug_col_g, is_debug);\ncol_b = mix(col_b, debug_col_b, is_debug);\n\ncol_r = mix(col_r, depth_r, is_depth_view);\ncol_g = mix(col_g, depth_g, is_depth_view);\ncol_b = mix(col_b, depth_b, is_depth_view);\n\ncol_r = mix(col_r, err_col_r, is_err_view);\ncol_g = mix(col_g, err_col_g, is_err_view);\ncol_b = mix(col_b, err_col_b, is_err_view);\n\nin_disk = step(zx0*zx0 + zy0*zy0, 1.0);\ncol_r = mix(0.0, col_r, in_disk);\ncol_g = mix(0.0, col_g, in_disk);\ncol_b = mix(0.0, col_b, in_disk);\n\nresult = vec(col_r, col_g, col_b, 1.0);\nout1 = result;\n",
                                    "fontface": 0, "fontname": "<Monospaced>", "fontsize": 12.0,
                                    "id": "obj-3", "maxclass": "codebox", "numinlets": 1, "numoutlets": 1,
                                    "outlettype": [ "" ], "patching_rect": [ 50.0, 46.0, 979.0, 700.0 ]
                                }
                            },
                            {
                                "box": {
                                    "id": "obj-4", "maxclass": "newobj", "numinlets": 1, "numoutlets": 0,
                                    "patching_rect": [ 59.0, 760.0, 35.0, 22.0 ], "text": "out 1"
                                }
                            }
                        ],
                        "lines": [
                            { "patchline": { "destination": [ "obj-3", 0 ], "source": [ "obj-1", 0 ] } },
                            { "patchline": { "destination": [ "obj-4", 0 ], "source": [ "obj-3", 0 ] } }
                        ]
                    },
                    "patching_rect": [ 254.0, 407.0, 174.0, 22.0 ], "text": "jit.gl.pix @name poincare45_pix"
                }
            },
            {
                "box": {
                    "bgmode": 1, "border": 1, "clickthrough": 0, "enablehscroll": 0, "enablevscroll": 0,
                    "id": "obj-4", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher", "name": "vs_output.maxpat",
                    "numinlets": 1, "numoutlets": 0, "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 253.0, 530.0, 157.0, 22.0 ], "varname": "vs_output", "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1, "border": 1, "clickthrough": 0, "enablehscroll": 0, "enablevscroll": 0,
                    "id": "obj-3", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher", "name": "vs_render.maxpat",
                    "numinlets": 1, "numoutlets": 1, "offset": [ 0.0, 0.0 ], "outlettype": [ "" ],
                    "patching_rect": [ 110.0, 14.0, 96.85526317358028, 146.5 ], "viewvisibility": 1
                }
            },
            {
                "box": {
                    "bgmode": 1, "border": 1, "clickthrough": 0, "enablehscroll": 0, "enablevscroll": 0,
                    "id": "obj-1", "lockeddragscroll": 0, "lockedsize": 0,
                    "maxclass": "bpatcher", "name": "vs_modules.maxpat",
                    "numinlets": 0, "numoutlets": 0, "offset": [ 0.0, 0.0 ],
                    "patching_rect": [ 25.0, 14.0, 79.0, 316.0 ], "viewvisibility": 1
                }
            },
            {
                "box": {
                    "attr": "edge_d", "id": "obj-8", "maxclass": "attrui",
                    "numinlets": 1, "numoutlets": 1, "outlettype": [ "" ], "parameter_enable": 0,
                    "patching_rect": [ 292.0, 265.0, 150.0, 22.0 ]
                }
            },
            {
                "box": {
                    "attr": "edge_r2", "id": "obj-9", "maxclass": "attrui",
                    "numinlets": 1, "numoutlets": 1, "outlettype": [ "" ], "parameter_enable": 0,
                    "patching_rect": [ 292.0, 295.0, 150.0, 22.0 ]
                }
            },
            {
                "box": {
                    "attr": "scale", "id": "obj-11", "maxclass": "attrui",
                    "numinlets": 1, "numoutlets": 1, "outlettype": [ "" ], "parameter_enable": 0,
                    "patching_rect": [ 292.0, 325.0, 150.0, 22.0 ]
            }
            },
            {
                "box": {
                    "attr": "use_mapped", "id": "obj-13", "maxclass": "attrui",
                    "numinlets": 1, "numoutlets": 1, "outlettype": [ "" ], "parameter_enable": 0,
                    "patching_rect": [ 292.0, 355.0, 150.0, 22.0 ]
                }
            }
        ],
        "lines": [
            { "patchline": { "destination": [ "obj-5", 0 ], "source": [ "obj-2", 0 ] } },
            { "patchline": { "destination": [ "obj-4", 0 ], "source": [ "obj-5", 0 ] } },
            { "patchline": { "destination": [ "obj-5", 0 ], "source": [ "obj-8", 0 ] } },
            { "patchline": { "destination": [ "obj-5", 0 ], "source": [ "obj-9", 0 ] } },
            { "patchline": { "destination": [ "obj-5", 0 ], "source": [ "obj-11", 0 ] } },
            { "patchline": { "destination": [ "obj-5", 0 ], "source": [ "obj-13", 0 ] } }
        ],
        "autosave": 0
    }
}