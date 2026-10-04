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
		"rect" : [ 100.0, 100.0, 640.0, 280.0 ],
		"gridsize" : [ 15.0, 15.0 ],
		"boxes" : [
			{
				"box" : {
					"id" : "obj-1",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 30.0, 20.0, 580.0, 20.0 ],
					"text" : "T021 scratch test: does pcontrol open our helpfiles by bare name? Click each message, watch the console (Cmd-M)."
				}
			},
			{
				"box" : {
					"id" : "obj-2",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 60.0, 200.0, 22.0 ],
					"text" : "loadunique f_droste.maxhelp"
				}
			},
			{
				"box" : {
					"id" : "obj-3",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 250.0, 60.0, 360.0, 20.0 ],
					"text" : "1+2: does the help open? click twice: 2nd window, or brings 1st to front?"
				}
			},
			{
				"box" : {
					"id" : "obj-4",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 100.0, 200.0, 22.0 ],
					"text" : "load f_droste.maxhelp"
				}
			},
			{
				"box" : {
					"id" : "obj-5",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 250.0, 100.0, 360.0, 20.0 ],
					"text" : "3: close the help first, then same two questions; compare with loadunique"
				}
			},
			{
				"box" : {
					"id" : "obj-6",
					"maxclass" : "message",
					"numinlets" : 2,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 140.0, 200.0, 22.0 ],
					"text" : "loadunique f_nonexistent.maxhelp"
				}
			},
			{
				"box" : {
					"id" : "obj-7",
					"maxclass" : "comment",
					"numinlets" : 1,
					"numoutlets" : 0,
					"patching_rect" : [ 250.0, 140.0, 360.0, 20.0 ],
					"text" : "4: missing file: what does the console say? does anything open?"
				}
			},
			{
				"box" : {
					"id" : "obj-8",
					"maxclass" : "newobj",
					"numinlets" : 1,
					"numoutlets" : 1,
					"outlettype" : [ "" ],
					"patching_rect" : [ 30.0, 200.0, 60.0, 22.0 ],
					"text" : "pcontrol"
				}
			}
		],
		"lines" : [
			{
				"patchline" : {
					"destination" : [ "obj-8", 0 ],
					"source" : [ "obj-2", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-8", 0 ],
					"source" : [ "obj-4", 0 ]
				}
			},
			{
				"patchline" : {
					"destination" : [ "obj-8", 0 ],
					"source" : [ "obj-6", 0 ]
				}
			}
		]
	}
}
