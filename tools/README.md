# tools/

One-off, module-specific scripts used during development — not the supported
build system. If you're looking to build your own `f_`-style bpatchers, use
`build/` instead (see `build/spec.md`).

Most of what's here are surgical, single-purpose migrations that already ran
against a specific patcher at a specific point in history (e.g.
`tools/masonry/*`, `tools/util_profile/*`, `tools/append_nabla_menu.py`).
Several hardcode absolute paths to this author's machine and are kept only
as a record of how a particular fix was made — they are not meant to be
re-run, and aren't guaranteed to still work against the current patchers.
