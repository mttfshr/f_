// Add f_ module to parent patcher.
// f_addmod.js runs inside f_modules.maxpat, which is a bpatcher directly
// in the user's patch — so we need one level up.

// Authoritative presentation sizes [w, h] keyed by bare module name.
// Source of truth: presentation panel rect in each .maxpat file.
var SIZES = {
    "masonry":        [342, 241],
    "chladni":        [299, 234],
    "stipple":        [191, 157],
    "grain":          [227, 164],
    "droste":         [150,  89],
    "mobius":         [185,  90],
    "stereo":         [160,  90],
    "lens":           [175, 155],
    "caustic":        [190, 100],
    "channel_grader": [150, 165],
    "hue_processor":  [150, 120],
    "luma_processor": [150, 120],
    "tone_curve":     [150, 120],
    "texrouter":      [213, 130],
    "util_profile":   [200, 120],
    "vf_vortex":      [196, 160],
    "vf_vortex_multi":[191, 284],
    "vf_fieldmap":    [100,  80],
    "vf_warp":        [ 78,  90],
    "vf_streak":      [190, 100],
    "vf_advect":      [190, 130],
    "vf_glow":        [190, 120],
    "vf_repulse":     [165,  80],
    "vf_split":       [ 80,  80],
    "vf_chroma":      [190, 100]
};

function addmod(mod) {
    var size = SIZES[mod] || [200, 150]; // fallback if a new module isn't listed yet
    var w = size[0];
    var h = size[1];

    var loc = this.patcher.box.rect; // f_modules bpatcher coords in user's patch
    var offset = 85;

    var target = this.patcher.parentpatcher; // user's patch
    var myobj = target.newobject("bpatcher");
    target.bringtofront(myobj);
    myobj.message("bgmode", 1);
    myobj.message("border", 0);
    myobj.replace("f_" + mod + ".maxpat");
    myobj.rect = [loc[0] + offset, loc[1], loc[0] + offset + w, loc[1] + h];
}
