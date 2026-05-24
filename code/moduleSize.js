sizeSender = new Global("moduleSize");

// send modules' width and height to addmod.js
function tam(w, h) {

	sizeSender.x = w;
	sizeSender.y = h;

}

// embed bpatcher
function emb() {
	
	parent = this.patcher.parentpatcher;
	name = this.patcher.box.varname;

	parent.message("script", "sendbox", name, "embed", 1);

}