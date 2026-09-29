"""
reconcile_skills.py -- one-off (2026-09-29). Reconcile the diverged copies of
jit-gen-codebox and relocate misfiled gen~ content.

Situation found this session:
  * claude-scaffold/skills/{f-helpfile,vsynth-bpatcher} are already SYMLINKS
    into f_/skills -- current by construction, untouched here.
  * max-patch-notation is a byte-identical real duplicate.
  * jit-gen-codebox diverged BOTH ways: f_ was missing two findings that only
    existed in claude-scaffold (the `Param mix` operator collision -- cited by
    .specify/plan.md item 1 and the reason `mix_pct` exists library-wide -- and
    the discrete-item gate/silhouette finding), while claude-scaffold was
    missing everything f_ gained since June.
  * f_'s jit-gen-codebox also carried a whole `## gen~ / Audio-Domain Codebox`
    section. That is misfiled in a jit.gl.pix skill, and claude-scaffold's
    gen-tilde-codebox did NOT contain it, so it would be lost, not deduplicated.

What this does:
  1. Restores the two scaffold-only sections into f_'s jit-gen-codebox at their
     original anchors.
  2. Moves the gen~ section out of f_'s jit-gen-codebox into gen-tilde-codebox.
  3. Leaves the filesystem moves/symlinks to the shell step that follows.

Run once, then verify with the printed report. Not part of the build system.
"""
import re
from pathlib import Path

GH = Path("/Users/matt/Github")
F_JIT = GH / "f_/skills/jit-gen-codebox/SKILL.md"
CS_JIT = GH / "claude-scaffold/skills/jit-gen-codebox/SKILL.md"


def section(text, header, stop=("\n## ", "\n### ", "\n---")):
    """Return the block starting at `header` up to the next heading/rule."""
    i = text.index(header)
    j = len(text)
    for s in stop:
        k = text.find(s, i + len(header))
        if k != -1:
            j = min(j, k)
    return text[i:j].rstrip() + "\n"


def main():
    f = F_JIT.read_text()
    cs = CS_JIT.read_text()
    report = []

    # --- 1. restore the two scaffold-only findings -----------------------
    restores = [
        ("### `Param` named after a built-in operator (e.g. `mix`) — confirmed 2026-07-12",
         "### `active` as a variable name"),
        ("### Discrete-item gate is a bounding box, not the shape's silhouette (confirmed 2026-07-22)",
         "### `vec4 + vec4` addition on stored variables"),
    ]
    for hdr, anchor in restores:
        assert hdr not in f, "already present in f_: %s" % hdr
        block = section(cs, hdr)
        assert anchor in f, "anchor missing in f_: %s" % anchor
        f = f.replace(anchor, block + "\n" + anchor, 1)
        report.append("restored into f_  (%d chars): %s" % (len(block), hdr[:60]))

    # --- 2. lift the gen~ section out ------------------------------------
    gen_hdr = "## gen~ / Audio-Domain Codebox — DIFFERENT COMPILER, DO NOT ASSUME GPU RULES TRANSFER"
    i = f.index(gen_hdr)
    gen_block = f[i:].rstrip() + "\n"
    f = f[:i].rstrip() + "\n"
    if f.endswith("---\n"):                    # drop the now-dangling rule
        f = f[: -len("---\n")].rstrip() + "\n"
    report.append("lifted gen~ section out of f_ jit-gen-codebox (%d chars, %d subsections)"
                  % (len(gen_block), gen_block.count("\n### ")))
    return f, gen_block, report


GEN_INTRO = """
---

## Carried over from `jit-gen-codebox` (2026-09-29)

The findings below were originally filed in the `jit.gl.pix` skill during
`f_a_purr` development and moved here when the two copies of that skill were
reconciled. They are gen~ rules, not GPU rules.
"""

if __name__ == "__main__":
    f_new, gen_block, report = main()

    # sanity: nothing from either source may be silently dropped
    old_f = F_JIT.read_text()
    for h in re.findall(r"^### .+$", old_f, re.M):
        assert h in f_new or h in gen_block, "LOST a section: %s" % h

    F_JIT.write_text(f_new)

    # gen~ block is appended to gen-tilde-codebox by the shell step, which
    # first moves that skill into f_/skills. Stage it here.
    staged = GH / "f_/scratch/gen_tilde_addendum.md"
    body = gen_block.split("\n", 1)[1].lstrip("\n")     # drop the old ## header
    staged.write_text(GEN_INTRO + "\n" + body)

    print("\n".join(report))
    print("staged gen~ addendum -> %s" % staged)
    print("f_ jit-gen-codebox now %d lines" % len(f_new.splitlines()))
