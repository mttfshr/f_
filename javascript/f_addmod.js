sizeReceiver = new Global("moduleSize");

// Add f_ module to parent patcher.
// f_addmod.js runs inside f_modules.maxpat, which is a bpatcher inside f_menu.maxpat,
// which is itself a bpatcher in the user's patch — so we need two levels up.

function addmod(mod) {

	loc = this.patcher.parentpatcher.box.rect; // f_menu bpatcher's coords in user's patch
	offset = 85;

	var target = this.patcher.parentpatcher.parentpatcher; // user's patch
	var myobj = target.newobject("bpatcher");
	target.bringtofront(myobj);
		myobj.message("bgmode", 1);
		myobj.message("border", 1);
		myobj.replace("f_" + mod + ".maxpat");
		myobj.rect = [loc[0]+offset, loc[1], sizeReceiver.x+loc[0]+offset, sizeReceiver.y+loc[1]];

}
