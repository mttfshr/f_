#!/usr/bin/env python3
"""
One-off driver: runs this scratch definition.py through the real
build_patcher.py generator, but writes the result here instead of to
package/patchers/ (which build_patcher.py's main() hardcodes). Not part
of the repo's build pipeline -- scratch/experiments/ only.
"""
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "build"))

import build_patcher  # noqa: E402

def main():
    def_path = Path(__file__).parent / "definition.py"
    defn = build_patcher.load_definition(def_path)
    side_files = {}
    result = build_patcher.build(defn, side_files=side_files)

    out_path = Path(__file__).parent / f"{defn['name']}.maxpat"
    with open(out_path, "w") as f:
        json.dump(result, f, indent="\t")
    print(f"Written: {out_path}")

    for path, content in side_files.items():
        print(f"(side file requested, not writing outside scratch): {path}")

if __name__ == "__main__":
    main()
