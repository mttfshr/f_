#!/bin/bash
# Run one file with the test import path (tests/lib, every tests/ subdirectory, build/), numpy via uv.
#   tests/py.sh tests/modules/fluid/test_fluid_mirror.py
#   tests/py.sh tests/bench/make_bench.py
cd "$(dirname "$0")/.." || exit 1
. tests/_log.sh >/dev/null 2>&1
exec uv run --no-project --with numpy python3 "$@"
