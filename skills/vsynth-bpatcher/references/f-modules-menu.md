# f_modules menu

The module insertion menu, `f_addmod.js`, and how to add a module. Part of the vsynth-bpatcher skill.

`package/patchers/f_modules.maxpat` is the f_ module insertion menu. Drop it as a bpatcher directly into a user patch — no wrapper needed. Selecting an item from any category menu spawns the corresponding `f_` bpatcher adjacent to the menu.

## Architecture

- One categorized `live.menu` per category (visible, display names), each paired with a hidden `live.menu` (filenames); categories are listed in `src/f_modules/menu.py`
- Selection: display menu outlet 0 → filename menu inlet 0; filename menu outlet 1 → `prepend addmod` → `gate` → `js f_addmod.js`
- Gate is held open by `loadmess 1` → `pipe 250` on load (debounce — prevents spurious spawn on patch open)
- `f_addmod.js` navigates **one level up** (`this.patcher.parentpatcher`) — f_modules is a direct bpatcher in the user's patch, not nested in a wrapper

## f_addmod.js

`javascript/f_addmod.js` spawns the bpatcher:

```javascript
function addmod(mod) {
    var size = SIZES[mod] || [200, 150];
    var loc = this.patcher.box.rect;       // f_modules coords in user's patch
    var offset = 85;
    var target = this.patcher.parentpatcher;
    var myobj = target.newobject("bpatcher");
    target.bringtofront(myobj);
    myobj.message("bgmode", 1);
    myobj.message("border", 0);           // no border — matches hand-placed convention
    myobj.replace("f_" + mod + ".maxpat");
    myobj.rect = [loc[0]+offset, loc[1], loc[0]+offset+w, loc[1]+h];
}
```

Key decisions:
- **Hardcoded size table** (`SIZES` dict keyed by bare module name) — not reliant on `moduleSize` Global, so sizing is correct even on cold spawn before the module has ever been opened
- **`border: 0`** — matches how bpatchers look when placed by hand
- **`bgmode: 1`** — required for bpatcher to show its presentation layer

## Adding a New Module

**`f_modules.maxpat` and the `SIZES` table of `f_addmod.js` are generated** (build_cleanup T021, 2026-10-05) by `build/generate_menu.py` from `src/f_modules/menu.py`: never hand-edit either file. `build/py.sh build/generate_menu.py --check` exits 1 if either is stale.

To add a module, add one entry to `src/f_modules/menu.py` and regenerate:

1. **`CATEGORIES`** — `(display, module, kinds)` in the right category, where `kinds` is `N` (neither), `V` (vecfield), `T` (tensor) or `VT` (both). The category labels and members must match the README Patches table (the table `f_Launch` is generated from); the generator fails loudly if they differ, if the patcher does not exist, or if a shipped patcher is neither in the menu nor in `NOT_IN_MENU` (with a reason). A ∇ category takes only modules that carry the vecfield kind, and a `T_` category only the tensor kind. The menu must also fit the 380 px panel the example patches embed it at: nine categories fit at the 39 px slot pitch, and the generator fails the check if a tenth would not (reduce the pitch, or grow the panel and re-size the embeds).
2. **Size** — nothing to do: it is the module's presentation panel rect, rounded. Add a `SIZE_OVERRIDES` entry (with a reason) only for a module whose content extends past its panel; an override equal to the panel size fails the check as stale.

## Why No f_menu Wrapper

The original design had `f_menu.maxpat` as a thin bpatcher wrapper around `f_modules.maxpat` (mirroring Vsynth's `vs_menu` → `vs_modules` pattern). This was removed — `f_modules` is self-contained and the extra indirection broke the `f_addmod.js` parent navigation. Use `f_modules.maxpat` directly.

## Editing Warning

The generator reproduces the shipped patcher byte for byte, so a regeneration with unchanged data changes nothing (`git diff` it anyway). A tweak made by hand in Max is lost on the next regeneration and shows up as a stale file in `--check`: write it into `build/generate_menu.py` (the box templates) or `src/f_modules/menu.py` (the data) instead. The earlier one-off scripts in `tools/` and `build/tools/f_modules/build_modules.py` (the old 5-category generator) are deleted; they are in git history.

## Module categories

The categories and their members live in `CATEGORIES` in `src/f_modules/menu.py`, which must match the README Patches table (the generator checks); don't copy the list here, it went stale once already. Categories are grouped by visual character, not archetype (reorganized 2026-07-10; renamed since). ∇ categories hold only vecfield-kind modules and `T_` categories only tensor-kind ones; a module's label gets a " ∇" or " T_" suffix from its kinds, inside or outside those categories. Shipped patchers left out of the menu are in `NOT_IN_MENU`, each with a reason.
