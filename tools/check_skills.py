#!/usr/bin/env python3
"""Static checks for skill folders: strict YAML frontmatter, an installer-safe
description, and a size that survives context compaction.

Usage: uv run --with pyyaml python tools/check_skills.py <skill-dir>...
"""
import sys
from pathlib import Path

import yaml

# Claude Code re-injects an invoked skill after compaction up to ~5k tokens.
# At ~3.5 characters per token that is ~17,500 characters.
MAX_CHARS = 17_500


def _raw_description(frontmatter):
    for line in frontmatter.splitlines():
        if line.startswith("description:"):
            return line.split(":", 1)[1].strip()
    return None


def check_skill(skill_dir):
    skill_dir = Path(skill_dir)
    path = skill_dir / "SKILL.md"
    if not path.is_file():
        return [f"{skill_dir}: missing SKILL.md"]
    text = path.read_text(encoding="utf-8")
    parts = text.split("---\n", 2)
    if len(parts) != 3 or parts[0] != "":
        return [f"{path}: frontmatter must open and close with ---"]
    try:
        meta = yaml.safe_load(parts[1])
    except yaml.YAMLError as e:
        return [f"{path}: frontmatter is not valid YAML ({getattr(e, 'problem', e)})"]
    if not isinstance(meta, dict):
        return [f"{path}: frontmatter is not a mapping"]

    errors = []
    if meta.get("name") != skill_dir.name:
        errors.append(f"{path}: name {meta.get('name')!r} does not match folder {skill_dir.name!r}")
    raw = _raw_description(parts[1])
    if not raw:
        errors.append(f"{path}: description missing")
    else:
        # Checked on the raw line: YAML silently drops a " #" comment tail.
        if ": " in raw:
            errors.append(f"{path}: description contains ': ', which breaks the skills installer")
        if " #" in raw:
            errors.append(f"{path}: description contains ' #', which YAML reads as a comment")
    if len(text) > MAX_CHARS:
        errors.append(f"{path}: {len(text)} characters, over the {MAX_CHARS} budget")
    return errors


def main(argv):
    if len(argv) < 2:
        print("usage: check_skills.py <skill-dir>...", file=sys.stderr)
        return 2
    errors = [e for d in argv[1:] for e in check_skill(d)]
    for e in errors:
        print(e)
    if not errors:
        print(f"ok: {len(argv) - 1} skill(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
