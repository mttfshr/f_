#!/opt/homebrew/bin/python3.13
"""
generate_helpfiles.py — build the generation prompt for f_ helpfiles.

NO ANTHROPIC API CALLS. Per Matt's standing instruction (repeated
2026-07-19 after being asked once before), this script must never call
the Anthropic API. It only ever assembles and prints/writes the prompt
that a human-in-session Claude (already holding full context on the
module) uses to write the .maxhelp file directly via edit_block/
write_file. There is no other code path.

Reads build/helpfile_queue.json (written by extract_params.py) and
prints the full generation prompt for each pending entry to stdout (or
to build/<module>_prompt.txt with --write-prompt). Generation itself
happens in-session, by hand, using that prompt plus the skill/template
already in context — never via a script-issued API call.

Usage:
    python3.13 build/generate_helpfiles.py                    # print prompt for all pending
    python3.13 build/generate_helpfiles.py f_grain             # single module
    python3.13 build/generate_helpfiles.py f_grain --write-prompt  # write to build/f_grain_prompt.txt
"""

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
HELP_DIR = REPO_ROOT / "package" / "help"
STATE_FILE = REPO_ROOT / "build" / "helpfile_queue.json"
TEMPLATE_PATH = REPO_ROOT / "package" / "help" / "f_droste.maxhelp"
SKILL_PATH = REPO_ROOT / "skills" / "f-helpfile" / "SKILL.md"

# ---------------------------------------------------------------------------
# Prompt construction
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You generate Max/MSP .maxhelp files for the f_ Vsynth bpatcher library.

You will be given:
- A skill document describing the helpfile format and conventions
- The canonical template (f_droste.maxhelp) as a JSON reference
- Extracted metadata for the module to generate (params, hints, ranges, module type)
- Optionally: the module's docs/f_<name>.md for references content

Your output must be:
- Valid JSON only — no prose, no markdown fences, no explanation
- A complete .maxhelp patcher JSON following the f-helpfile skill conventions exactly
- The External Control Messages block must list only externally-addressable params
  (exclude any param of type "internal"; bypass goes last)
- The References block should use content from the docs file if provided,
  or a placeholder "References\n\n[see docs/f_<name>.md]" if not
- Object IDs must follow the skill naming: h-1, h-2, d-3, d-4, d-5, d-6, d-7, d-8, r-1, obj-1
- For generators: omit vs_sources_main (d-3) and LFO/time_s (d-6, d-7), bpatcher at top of right column
- For processors: include full signal flow as shown in template
- Suggested-chain comment (judgment call, not mechanical): read the docs and form a
  real sense of this module's essential character — what kind of effect it produces,
  what it needs to look interesting (a moving/textured source? a companion vecfield
  consumer to visualize a field that's otherwise invisible? a specific kind of input
  pattern?). If, and only if, that reading suggests 1-3 specific companion f_ modules
  that would meaningfully demonstrate the module's character in the exemplar patch
  (e.g. a vecfield producer wants a downstream consumer since the field itself has
  no visible output; a masking/threshold effect wants a source with real contrast to
  act on), add ONE additional comment box near the bpatcher/signal-flow area in the
  right column, worded as a hand-wiring suggestion, e.g. "Try feeding into: f_vf_warp
  or f_vf_advect (swap to compare)" or "Works best with a textured/moving source —
  try f_grain or live camera". Do not force this if the docs don't give clear signal
  either way — an absent or generic module doesn't need one. This box is a note for
  the module's author to wire by hand afterward, not a functional connection — do not
  wire real patchlines to it.

Do not output anything except the JSON.
"""


def build_user_prompt(entry: dict, skill_text: str, template_json: str, docs_text) -> str:
    module_name = entry["module_name"]
    short_name = entry["short_name"]
    module_type = entry["module_type"]

    # Format params for the prompt — exclude bypass from main list, add at end
    external_params = [p for p in entry["params"] if p["name"] != "bypass" and p["type"] != "internal"]
    has_bypass = any(p["name"] == "bypass" for p in entry["params"])

    param_lines = []
    for p in external_params:
        param_lines.append(f"  {p['name']} {p['range']}  # {p['hint']}")
    if has_bypass:
        param_lines.append("  bypass [0 / 1]")

    params_block = "\n".join(param_lines)

    docs_section = ""
    if docs_text:
        docs_section = f"\n\n--- DOCS (f_{module_name}.md) ---\n{docs_text}\n--- END DOCS ---"

    return f"""--- SKILL ---
{skill_text}
--- END SKILL ---

--- TEMPLATE (f_droste.maxhelp) ---
{template_json}
--- END TEMPLATE ---

--- MODULE TO GENERATE ---
module_name: {module_name}
short_name: {short_name}  (use this as the Title text — "Grain" not "f_grain")
module_type: {module_type}  (processor=has texture input; generator=no source needed)

External Control Messages (in order):
{params_block}
{docs_section}

Generate the complete f_{short_name}.maxhelp JSON now.
"""


# ---------------------------------------------------------------------------
# NOTE: no API-call function here, deliberately. See module docstring.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Queue management
# ---------------------------------------------------------------------------

def load_queue() -> list[dict]:
    if not STATE_FILE.exists():
        print(f"ERROR: queue file not found at {STATE_FILE}", file=sys.stderr)
        print("Run extract_params.py first.", file=sys.stderr)
        sys.exit(1)
    with open(STATE_FILE) as f:
        return json.load(f)


def save_queue(queue: list[dict]) -> None:
    with open(STATE_FILE, "w") as f:
        json.dump(queue, f, indent=2)


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

def main():
    args = sys.argv[1:]
    write_prompt = "--write-prompt" in args
    args = [a for a in args if a != "--write-prompt"]

    # Filter to named modules if given
    filter_names = set()
    for a in args:
        if not a.startswith("--"):
            filter_names.add(a if a.startswith("f_") else f"f_{a}")

    # Load supporting files
    skill_text = SKILL_PATH.read_text()
    template_json = TEMPLATE_PATH.read_text()

    queue = load_queue()

    blocked = [
        e for e in queue
        if e["status"] == "pending"
        and not e.get("has_docs")
        and (not filter_names or e["module_name"] in filter_names)
    ]
    if blocked:
        print("Skipping (missing docs/f-reference/<name>.md — write that first, see build/spec.md):")
        for e in blocked:
            print(f"  - {e['module_name']}")
            e["status"] = "blocked_no_docs"
        save_queue(queue)
        print()

    pending = [
        e for e in queue
        if e.get("has_docs")
        and (
            e["status"] == "pending"
            # "stale" (docs updated since last helpfile) only regenerates when
            # explicitly named — never picked up in a bulk unfiltered run, so
            # regenerating a stale helpfile stays a deliberate per-module choice.
            or (e["status"] == "stale" and filter_names and e["module_name"] in filter_names)
        )
        and (not filter_names or e["module_name"] in filter_names)
    ]

    if not pending:
        print("No pending entries in queue.")
        return

    print(f"Pending: {len(pending)} module(s)")
    print("This script only builds the prompt -- it never calls the Anthropic")
    print("API. Take the printed (or written) prompt into an in-session Claude")
    print("conversation, which already holds the skill/template/docs context,")
    print("and have it write the .maxhelp file directly via edit_block/write_file.\n")

    for entry in pending:
        module_name = entry["module_name"]

        # Load docs if available
        docs_text = None
        if entry.get("has_docs") and entry.get("docs_path"):
            try:
                docs_text = Path(entry["docs_path"]).read_text()
            except OSError:
                pass

        user_prompt = build_user_prompt(entry, skill_text, template_json, docs_text)
        full_prompt = SYSTEM_PROMPT + "\n\n" + user_prompt

        if write_prompt:
            out_path = REPO_ROOT / "build" / f"{module_name}_prompt.txt"
            out_path.write_text(full_prompt)
            print(f"  Wrote prompt: {out_path}")
        else:
            print(f"=== {module_name} ===")
            print(full_prompt)
            print()


if __name__ == "__main__":
    main()
