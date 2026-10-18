"""Repo-root and tests/ locations for test files at any depth (replaces per-file
Path(__file__).parent.parent arithmetic). lib/ is on PYTHONPATH (tests/_log.sh)."""
from pathlib import Path

TESTS = Path(__file__).resolve().parent.parent
REPO = TESTS.parent
BENCH = TESTS / "bench"
