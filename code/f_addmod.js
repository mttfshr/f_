sizeReceiver = new Global("moduleSize");

// Add f_ module to parent patcher

function addmod(mod) {

	loc = this.patcher.box.rect;
	offset = 85;

	var myobj = this.patcher.parentpatcher.newobject("bpatcher");
	this.patcher.parentpatcher.bringtofront(myobj);
		myobj.message("bgmode", 1);
		myobj.message("border", 1);
		myobj.replace("f_" + mod + ".maxpat");
		myobj.rect = [loc[0]+offset, loc[1], sizeReceiver.x+loc[0]+offset, sizeReceiver.y+loc[1]];

}
