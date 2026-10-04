# tools/

Not the supported build system. If you're looking to build your own
`f_`-style bpatchers, use `build/` instead (see `build/spec.md`).

What's left here are the two scripts that edit the `f_modules` menu patcher
(`rebuild_modules_menu.py`, `append_nabla_menu.py`). They are slated to be
replaced by a single generator. Until then, `package/patchers/f_modules.maxpat`
is the only accurate source of the menu: `rebuild_modules_menu.py` lacks
`f_vf_fluid`, so running it would overwrite the shipped patcher with an
older menu.

Earlier one-off migration scripts (masonry, util_profile, instate/routepass,
vecfield labels, texrouter) were removed after they ran. Find them in git
history, e.g. `git log --diff-filter=D --name-only -- tools/`.
