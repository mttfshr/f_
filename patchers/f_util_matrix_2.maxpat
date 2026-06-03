{
	"patcher" : {
		"fileversion" : 1,
		"appversion" : {
			"major" : 9,
			"minor" : 1,
			"revision" : 4,
			"architecture" : "x64",
			"modernui" : 1
		},
		"classnamespace" : "box",
		"rect" : [ 100.0, 100.0, 700.0, 500.0 ],
		"openinpresentation" : 1,
		"gridsize" : [ 15.0, 15.0 ],
		"boxes" : [
			{
				"box" : {
					"id" : "obj-1",
					"maxclass" : "inlet",
					"numinlets" : 0,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 15.0, 30.0, 30.0, 30.0 ],
					"comment" : "control in"
				}
			},
			{
				"box" : {
					"id" : "obj-2",
					"maxclass" : "inlet",
					"numinlets" : 0,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 75.0, 30.0, 30.0, 30.0 ],
					"comment" : "source A texture in"
				}
			},
			{
				"box" : {
					"id" : "obj-3",
					"maxclass" : "inlet",
					"numinlets" : 0,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 135.0, 30.0, 30.0, 30.0 ],
					"comment" : "source B texture in"
				}
			},
			{
				"box" : {
					"id" : "obj-4",
					"maxclass" : "outlet",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 15.0, 420.0, 30.0, 30.0 ],
					"comment" : "mod assignments out"
				}
			},
			{
				"box" : {
					"id" : "obj-5",
					"maxclass" : "outlet",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 75.0, 420.0, 30.0, 30.0 ],
					"comment" : "source A texture out"
				}
			},
			{
				"box" : {
					"id" : "obj-6",
					"maxclass" : "outlet",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 135.0, 420.0, 30.0, 30.0 ],
					"comment" : "source B texture out"
				}
			},
			{
				"box" : {
					"id" : "obj-7",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 3,
					"outlettype" : [ "", "", "" ],
					"patching_rect" : [ 15.0, 90.0, 120.0, 22.0 ],
					"text" : "route bypass params"
				}
			},
			{
				"box" : {
					"id" : "obj-8",
					"maxclass" : "jsui",
					"filename" : "f_util_matrix_grid.js",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 200.0, 160.0, 216.0, 84.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 25.0, 216.0, 84.0 ],
					"varname" : "matrix_grid"
				}
			},

			{
				"box" : {
					"id" : "obj-11",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 200.0, 120.0, 90.0, 22.0 ],
					"text" : "prepend params"
				}
			},
			{
				"box" : {
					"id" : "obj-12",
					"maxclass" : "newobj",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 15.0, 160.0, 80.0, 22.0 ],
					"text" : "prepend bypass"
				}
			},
			{
				"box" : {
					"id" : "obj-13",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 5.0, 5.0, 120.0, 20.0 ],
					"fontname" : "Ableton Sans Light",
					"fontsize" : 12.0,
					"text" : "Matrix",
					"presentation" : 1,
					"presentation_rect" : [ 5.0, 5.0, 120.0, 20.0 ]
				}
			},
			{
				"box" : {
					"id" : "obj-14",
					"maxclass" : "panel",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 0.0, 0.0, 230.0, 120.0 ],
					"presentation" : 1,
					"presentation_rect" : [ 0.0, 0.0, 230.0, 120.0 ],
					"background" : 1,
					"bgcolor" : [ 0.0, 0.0, 0.0, 1.0 ],
					"bordercolor" : [ 0.0, 0.03529411765, 0.2274509804, 1.0 ]
				}
			}
		],
		"lines" : [
			{
				"patchline" : {
					"destination" : [ "obj-7", 0 ],
					"source" : [ "obj-1", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-5", 0 ],
					"source" : [ "obj-2", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-6", 0 ],
					"source" : [ "obj-3", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-12", 0 ],
					"source" : [ "obj-7", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-11", 0 ],
					"source" : [ "obj-7", 1 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-8", 0 ],
					"source" : [ "obj-11", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-8", 0 ],
					"source" : [ "obj-12", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-4", 0 ],
					"source" : [ "obj-8", 0 ]
				}
			}
		],
		"dependency_cache" : [],
		"autosave" : 0
	}
}
