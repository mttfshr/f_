#!/opt/homebrew/bin/python3.13
"""
generate_helpfiles.py — generate f_ helpfiles via Claude API.

Reads build/helpfile_queue.json (written by extract_params.py), calls the
Anthropic API for each pending entry, writes the helpfile, and updates the
queue with status and token spend.

Usage:
    python3.13 build/generate_helpfiles.py                  # process all pending
    python3.13 build/generate_helpfiles.py f_grain          # single module
    python3.13 build/generate_helpfiles.py --budget 50000   # token ceiling (default: 50000)
    python3.13 build/generate_helpfiles.py --dry-run        # print prompt, no API call

Requirements:
    ANTHROPIC_API_KEY env var set
    pip install anthropic
"""

import json
import os
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
HELP_DIR = REPO_ROOT / "package" / "help"
STATE_FILE = REPO_ROOT / "build" / "helpfile_queue.json"
TEMPLATE_PATH = REPO_ROOT / "package" / "help" / "f_droste.maxhelp"
SKILL_PATH = Path.home() / "Github/claude-scaffold/skills/f-helpfile/SKILL.md"

DEFAULT_BUDGET = 50_000
MODEL = "claude-sonnet-4-6"

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
# API call
# ---------------------------------------------------------------------------

def call_claude(system: str, user: str) -> tuple[str, int, int]:
    """Returns (response_text, input_tokens, output_tokens)."""
    try:
        import anthropic
    except ImportError:
        print("ERROR: anthropic package not installed. Run: pip install anthropic", file=sys.stderr)
        sys.exit(1)

    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    response = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        system=system,
        messages=[{"role": "user", "content": user}],
    )
    text = response.content[0].text
    return text, response.usage.input_tokens, response.usage.output_tokens


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
    dry_run = "--dry-run" in args
    args = [a for a in args if a != "--dry-run"]

    budget = DEFAULT_BUDGET
    for i, arg in enumerate(args):
        if arg == "--budget" and i + 1 < len(args):
            budget = int(args[i + 1])
            args = args[:i] + args[i+2:]
            break

    # Filter to named modules if given
    filter_names = set()
    for a in args:
        if not a.startswith("--"):
            filter_names.add(a if a.startswith("f_") else f"f_{a}")

    if not dry_run and "ANTHROPIC_API_KEY" not in os.environ:
        print("ERROR: ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(1)

    # Load supporting files
    skill_text = SKILL_PATH.read_text()
    template_json = TEMPLATE_PATH.read_text()

    queue = load_queue()
    total_tokens = 0
    processed = 0
    skipped = 0

    pending = [
        e for e in queue
        if e["status"] == "pending"
        and (not filter_names or e["module_name"] in filter_names)
    ]

    if not pending:
        print("No pending entries in queue.")
        return

    print(f"Budget: {budget:,} tokens")
    print(f"Pending: {len(pending)} module(s)\n")

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

        if dry_run:
            print(f"=== DRY RUN: {module_name} ===")
            print(user_prompt[:2000], "...[truncated]" if len(user_prompt) > 2000 else "")
            print()
            continue

        # Budget check — rough estimate before calling (1 token ≈ 4 chars)
        estimated_input = len(SYSTEM_PROMPT + user_prompt) // 4
        if total_tokens + estimated_input > budget:
            print(f"  BUDGET LIMIT: stopping before {module_name} (estimated {estimated_input:,} input tokens, {total_tokens:,} used so far)")
            entry["status"] = "skipped_budget"
            skipped += 1
            continue

        print(f"  Generating {module_name}...", end=" ", flush=True)

        try:
            raw, input_tokens, output_tokens = call_claude(SYSTEM_PROMPT, user_prompt)
        except Exception as e:
            print(f"ERROR: {e}")
            entry["status"] = "error"
            entry["error"] = str(e)
            save_queue(queue)
            continue

        total_tokens += input_tokens + output_tokens
        print(f"{input_tokens:,}in + {output_tokens:,}out = {input_tokens+output_tokens:,} tokens (running total: {total_tokens:,})")

        # Validate JSON
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError as e:
            print(f"    WARNING: response is not valid JSON: {e}")
            print(f"    Raw response saved to build/{module_name}_raw.txt")
            (REPO_ROOT / "build" / f"{module_name}_raw.txt").write_text(raw)
            entry["status"] = "error_json"
            entry["error"] = str(e)
            save_queue(queue)
            continue

        # Write helpfile
        helpfile_path = Path(entry["helpfile_path"])
        helpfile_path.parent.mkdir(exist_ok=True)
        helpfile_path.write_text(json.dumps(parsed, indent=4))
        print(f"    Written: {helpfile_path}")

        entry["status"] = "done"
        entry["tokens_used"] = input_tokens + output_tokens
        processed += 1
        save_queue(queue)

    print(f"\nDone. {processed} generated, {skipped} skipped (budget). Total tokens: {total_tokens:,}")


if __name__ == "__main__":
    main()
