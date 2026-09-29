# Project Workflow Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Five skills (`project-time`, `project-spec`, `project-plan`, `project-build`, `project-wrap`) that run a spec → plan → build → wrap cycle for a new project or a feature, with hierarchical memory and progress that survives context resets.

**Architecture:** Each skill is a plain folder with a `SKILL.md`, as in the rest of this repo. `project-time` sets up a repo (docs skeleton, a versioned block in `AGENTS.md`, `@AGENTS.md` in `CLAUDE.md`) and routes to the phase skill by reading status headers on disk. Shared conventions live in the `AGENTS.md` block, not in the skills. Verification has two layers: a static checker (YAML frontmatter, installer-safe description, size budget) and scripted scenario runs through headless `claude -p` in throwaway git repos, asserting on files and git history.

**Tech Stack:** Markdown skills; Python 3 + PyYAML + pytest via `uv run --with`; bash + `claude -p` (Claude Code 2.1.283) for scenarios.

**Spec:** `docs/superpowers/specs/2026-09-29-project-workflow-design.md`

**Status:** executed. The `SKILL.md` texts below are the first drafts; the committed skills were revised after the scenario reviews (Gate 0 approval rules, AC written during the interview, build checkpoint and verify wording, parallel resume and cleanup, the last milestone gate folded into wrap). The committed files are authoritative.

---

## File structure

| Path | Responsibility |
|---|---|
| `tools/check_skills.py` | Static checks for any skill folder |
| `tools/test_check_skills.py` | Tests for the checker |
| `tools/scenarios/lib.sh` | Scenario helpers: scratch repos, snapshots, `turn`, `drive`, assertions |
| `tools/scenarios/brief.md` | The toy project brief (a word-frequency CLI) |
| `tools/scenarios/NN-*.sh` | One scenario per spec verification item |
| `tools/scenarios/fixtures/parallel/` | A hand-built mid-plan state with two `∥` steps |
| `tools/scenarios/README.md` | How to run scenarios; the manual compaction check |
| `project-time/SKILL.md` | Setup + router + templates, including the `AGENTS.md` block |
| `project-spec/SKILL.md` | Interview, spec template, Gate 0, amend mode |
| `project-plan/SKILL.md` | Milestones, step files, Gate 1, update mode |
| `project-build/SKILL.md` | Resume reconciliation, step loop, gates, parallel orchestration |
| `project-wrap/SKILL.md` | Final gate, recap, consolidation, lessons, archive |
| `README.md` | New "Project workflow" section |

Scenarios chain through snapshots: each one starts from the state an earlier one saved (`spec-started`, `spec-approved`, `plan-approved`, `at-final-gate`, `wrapped`), so a skill can be re-tested without replaying the whole cycle. Scenario runs are slow (minutes to tens of minutes, several `claude -p` calls each): run them with `run_in_background` and read the log afterwards.

---

### Task 1: Skill checker

**Files:**
- Create: `tools/check_skills.py`
- Test: `tools/test_check_skills.py`

- [ ] **Step 1: Write the failing tests**

`tools/test_check_skills.py`:

```python
from check_skills import MAX_CHARS, check_skill, main


def make_skill(root, name="demo", description="Does a thing. Use when asked.", body="# Demo\n", folder=None):
    d = root / (folder or name)
    d.mkdir()
    (d / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: {description}\n---\n\n{body}", encoding="utf-8"
    )
    return d


def test_valid_skill_passes(tmp_path):
    assert check_skill(make_skill(tmp_path)) == []


def test_missing_skill_file(tmp_path):
    d = tmp_path / "empty"
    d.mkdir()
    assert "missing SKILL.md" in check_skill(d)[0]


def test_name_must_match_folder(tmp_path):
    errors = check_skill(make_skill(tmp_path, name="other", folder="demo"))
    assert any("does not match folder" in e for e in errors)


def test_colon_space_in_description_is_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, description="Does things: many of them."))
    assert any("not valid YAML" in e or "': '" in e for e in errors)


def test_quoted_colon_space_is_still_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, description='"Does things: many of them."'))
    assert errors


def test_block_scalar_description_is_rejected(tmp_path):
    d = tmp_path / "demo"
    d.mkdir()
    (d / "SKILL.md").write_text(
        "---\nname: demo\ndescription: >\n  Does things: many of them.\n---\n\n# Demo\n",
        encoding="utf-8",
    )
    errors = check_skill(d)
    assert any("single-line plain scalar" in e for e in errors)


def test_wrapped_quoted_description_is_rejected(tmp_path):
    d = tmp_path / "demo"
    d.mkdir()
    (d / "SKILL.md").write_text(
        '---\nname: demo\ndescription: "Does things\n  well: nicely."\n---\n\n# Demo\n',
        encoding="utf-8",
    )
    errors = check_skill(d)
    assert any("single-line plain scalar" in e for e in errors)


def test_space_hash_in_description_is_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, description="Counts words #fast"))
    assert any("' #'" in e for e in errors)


def test_oversize_skill_is_rejected(tmp_path):
    errors = check_skill(make_skill(tmp_path, body="x" * MAX_CHARS))
    assert any("budget" in e for e in errors)


def test_main_exit_codes(tmp_path, capsys):
    good = make_skill(tmp_path, name="good")
    bad = tmp_path / "bad"
    bad.mkdir()
    assert main(["check_skills.py", str(good)]) == 0
    assert main(["check_skills.py", str(good), str(bad)]) == 1
    assert "missing SKILL.md" in capsys.readouterr().out
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `uv run --with pyyaml --with pytest pytest -q tools/test_check_skills.py`
Expected: collection error, `ModuleNotFoundError: No module named 'check_skills'`

- [ ] **Step 3: Write the checker**

`tools/check_skills.py`:

```python
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
    # read_text() translates CRLF to LF, which the split on "---\n" relies on.
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
    parsed_description = meta.get("description")
    # Require a single-line plain scalar so the raw text we check is the
    # whole description: a block scalar or a wrapped quoted string would
    # otherwise let ": " or " #" hide on a line we never look at.
    if not raw or raw[0] in ">|\"'" or raw != parsed_description:
        errors.append(f"{path}: description must be a single-line plain scalar")
    if raw:
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `uv run --with pyyaml --with pytest pytest -q tools/test_check_skills.py`
Expected: `10 passed`

- [ ] **Step 5: Run the checker on the existing skills**

Run: `uv run --with pyyaml python tools/check_skills.py */ 2>&1 | tail -5`
Expected: `missing SKILL.md` for folders that aren't skills (`docs/`, `tools/`, the `*-workspace` folders), nothing else. If an existing skill fails a rule, note it for the user; do not fix it in this plan.

- [ ] **Step 6: Commit**

```bash
git add tools/check_skills.py tools/test_check_skills.py
git commit -m "Add a static checker for skill folders"
```

---

### Task 2: Scenario harness

**Files:**
- Create: `tools/scenarios/lib.sh`
- Create: `tools/scenarios/brief.md`
- Create: `tools/scenarios/00-smoke.sh`

- [ ] **Step 1: Write the library**

`tools/scenarios/lib.sh`:

```bash
#!/usr/bin/env bash
# Helpers for scenario runs of the project workflow skills in throwaway repos.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

SCENARIOS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO="$(cd "$SCENARIOS/../.." && pwd)"
WORKFLOW_SKILLS=(project-time project-spec project-plan project-build project-wrap)
SNAPSHOTS="${SCENARIO_SNAPSHOTS:-$HOME/.cache/project-workflow-snapshots}"
LESSONS="$HOME/.claude/project-lessons.md"
TOOLS=(Read Write Edit Glob Grep Skill Agent
  "Bash(git:*)" "Bash(mkdir:*)" "Bash(ls:*)" "Bash(cat:*)" "Bash(mv:*)" "Bash(cp:*)"
  "Bash(python3:*)" "Bash(test:*)" "Bash(grep:*)" "Bash(find:*)" "Bash(wc:*)"
  "Bash(date:*)" "Bash(make:*)" "Bash(sed:*)" "Bash(awk:*)" "Bash(head:*)" "Bash(tail:*)"
  "Bash(touch:*)" "Bash(shasum:*)" "Bash(echo:*)" "Bash(sort:*)" "Bash(diff:*)" "Bash(cd:*)")
SESSION=""
LAST=""

# Canned user replies.
ACCEPT="I'll take your recommendation."
ACCEPT_OK="Yes, OK. I'll take your recommendation."
FINISH_SPEC="I'll take your recommendation. If you think the spec covers everything: it's done, skip the challenge round, and I approve it."
AUTOPILOT="Yes. Take your recommendation. Whatever you are asking me to approve (outline, spec, plan, gate, consolidation) is approved; use sequential mode; manual checks are confirmed; to bring the branch up to date, merge the default branch into it; never merge the feature branch into the default branch, I do that myself; no lessons to promote; pins are done with."

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

_link_skills() {
  mkdir -p .claude/skills
  for s in "${WORKFLOW_SKILLS[@]}"; do
    [ -d "$SKILLS_REPO/$s" ] && ln -sfn "$SKILLS_REPO/$s" ".claude/skills/$s"
  done
  grep -qx '.claude/' .git/info/exclude || echo '.claude/' >> .git/info/exclude
  grep -qx '__pycache__/' .git/info/exclude || echo '__pycache__/' >> .git/info/exclude
  grep -qx '*.pyc' .git/info/exclude || echo '*.pyc' >> .git/info/exclude
}

new_scratch() {
  SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/project-workflow.XXXXXX")"
  TRANSCRIPT="$SCRATCH.log"
  cd "$SCRATCH"
  git init -q -b main
  git commit -q --allow-empty -m "init"
  _link_skills
  SESSION=""
  echo "scratch: $SCRATCH  log: $TRANSCRIPT"
}

save_snapshot() {
  mkdir -p "$SNAPSHOTS"
  rm -rf "${SNAPSHOTS:?}/$1"
  cp -R "$SCRATCH" "$SNAPSHOTS/$1"
  echo "snapshot: $1"
}

from_snapshot() {
  [ -d "$SNAPSHOTS/$1" ] || fail "no snapshot '$1'; run the scenario that saves it first"
  SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/project-workflow.XXXXXX")"
  TRANSCRIPT="$SCRATCH.log"
  cp -R "$SNAPSHOTS/$1/." "$SCRATCH/"
  cd "$SCRATCH"
  _link_skills
  SESSION=""
  echo "scratch: $SCRATCH (from $1)  log: $TRANSCRIPT"
}

# One user message. Continues the current session unless reset_session was called.
turn() {
  local prompt="$1" out rc
  local args=(-p "$prompt" --output-format json --permission-mode acceptEdits
    --add-dir "$HOME/.claude" --allowedTools "${TOOLS[@]}")
  [ -n "$SESSION" ] && args+=(--resume "$SESSION")
  rc=0
  out="$(claude "${args[@]}" </dev/null)" || rc=$?
  if [ "$rc" != 0 ]; then
    printf '\n## claude -p failed (attempt 1)\nprompt: %s\nexit: %s\noutput: %s\n' "$prompt" "$rc" "$out" >> "$TRANSCRIPT"
    sleep 30
    rc=0
    out="$(claude "${args[@]}" </dev/null)" || rc=$?
    if [ "$rc" != 0 ]; then
      printf '\n## claude -p failed (attempt 2)\nprompt: %s\nexit: %s\noutput: %s\n' "$prompt" "$rc" "$out" >> "$TRANSCRIPT"
      fail "claude -p exited $rc twice (session $SESSION)"
    fi
  fi
  SESSION="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["session_id"])')"
  LAST="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("result", ""))')"
  local denials
  denials="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin).get("permission_denials"); print(d) if d else None')"
  [ -n "$denials" ] && printf '\n## permission denials\n%s\n' "$denials" >> "$TRANSCRIPT"
  printf '\n## user\n%s\n\n## agent\n%s\n' "$prompt" "$LAST" >> "$TRANSCRIPT"
  printf '\n--- agent ---\n%s\n' "$LAST"
}

# Simulates /clear or a brand-new session.
reset_session() { SESSION=""; printf '\n# ---- session reset ----\n' >> "$TRANSCRIPT"; }

# Keep replying with $2 until the shell condition $1 holds, at most $3 turns.
drive() {
  local cond="$1" reply="$2" max="${3:-12}" i
  for ((i = 0; i < max; i++)); do
    eval "$cond" && return 0
    turn "$reply"
  done
  eval "$cond" || fail "condition never held after $max turns: $cond"
}

assert_file() { [ -f "$1" ] || fail "missing file $1"; }
assert_grep() { grep -qE -- "$2" "$1" || fail "$1 does not match /$2/"; }
assert_count() {
  local n
  n="$(grep -cE -- "$2" "$1" || true)"
  [ "$n" = "$3" ] || fail "$1: /$2/ matched $n times, want $3"
}
assert_clean_tree() { [ -z "$(git status --porcelain)" ] || fail "working tree not clean: $(git status --porcelain | tr '\n' ' ')"; }
assert_last_commit() { git log -1 --format=%s | grep -E -- "$1" >/dev/null || fail "last commit '$(git log -1 --format=%s)' does not match /$1/"; }
assert_commit() { git log --format=%s | grep -E -- "$1" >/dev/null || fail "no commit matching /$1/"; }

# Lines of one milestone in the plan index.
milestone_block() { awk -v n="$1" '/^## /{p = ($2 == "Milestone" && $3 == n)} p' docs/current/plan/INDEX.md; }
# The full test command from the plan index header.
test_cmd() { sed -nE 's/.*Test: `([^`]+)`.*/\1/p' docs/current/plan/INDEX.md | head -1; }

# Keep the real ~/.claude/project-lessons.md out of the tests' reach.
protect_lessons() {
  LESSONS_BACKUP="$(mktemp)"
  if [ -f "$LESSONS" ]; then cp "$LESSONS" "$LESSONS_BACKUP"; HAD_LESSONS=1; else HAD_LESSONS=0; fi
  echo "lessons backup: $LESSONS_BACKUP"
  trap restore_lessons EXIT
}
restore_lessons() {
  if [ "$HAD_LESSONS" = 1 ]; then cp "$LESSONS_BACKUP" "$LESSONS"; else rm -f "$LESSONS"; fi
}
```

- [ ] **Step 2: Write the toy brief**

`tools/scenarios/brief.md`:

```markdown
I want a tiny Python command-line tool called wordfreq. `python3 wordfreq.py FILE` prints the 10 most frequent words in the file, one `word count` per line, most frequent first. Counting is case-insensitive and ties are broken alphabetically. A `--top N` option changes 10 to N. Standard library only, tests with `python3 -m unittest`. It's for me alone, no packaging. Keep the plan to two milestones and at most four steps in total. For every question, I'll usually prefer your recommendation.
```

- [ ] **Step 3: Write a smoke scenario for the harness itself**

`tools/scenarios/00-smoke.sh`:

```bash
#!/usr/bin/env bash
# Checks the harness: a scratch repo, one turn, a resumed turn.
source "$(dirname "$0")/lib.sh"

new_scratch
turn "Reply with exactly the word: pineapple"
grep -qi pineapple <<< "$LAST" || fail "first turn"
[ -n "$SESSION" ] || fail "no session id"
turn "What word did you just reply with? Answer with that word only."
grep -qi pineapple <<< "$LAST" || fail "resume lost the session"
[ -L .claude/skills/project-time ] || [ ! -d "$SKILLS_REPO/project-time" ] || fail "skills not linked"
pass "smoke"
```

- [ ] **Step 4: Run the smoke scenario**

Run: `chmod +x tools/scenarios/*.sh && tools/scenarios/00-smoke.sh`
Expected: ends with `PASS: smoke`. If `--resume` returns a new session id each time, that is fine: `turn` tracks whatever comes back. If `claude -p` rejects a flag, fix `turn` before going on.

- [ ] **Step 5: Commit**

```bash
git add tools/scenarios/lib.sh tools/scenarios/brief.md tools/scenarios/00-smoke.sh
git commit -m "Add the scenario harness for the project workflow skills"
```

---

### Task 3: project-time

**Files:**
- Create: `project-time/SKILL.md`
- Create: `tools/scenarios/01-setup.sh`

- [ ] **Step 1: Write the scenario (the failing test)**

`tools/scenarios/01-setup.sh`:

```bash
#!/usr/bin/env bash
# Setup on a blank repo, then a second run that must change nothing.
source "$(dirname "$0")/lib.sh"

new_scratch
turn "/project-time new project, slug wordfreq. I'll describe it when you ask."

assert_grep AGENTS.md '<!-- project-time:start v2 -->'
assert_grep AGENTS.md '<!-- project-time:end -->'
assert_grep CLAUDE.md '^@AGENTS.md$'
assert_file docs/memory/INDEX.md
assert_file docs/memory/overview.md
assert_grep docs/current/spec.md 'Type: project'
assert_grep docs/current/spec.md 'Status: draft'
assert_grep docs/current/spec.md 'Branch: main'
assert_file docs/current/memory/INDEX.md
assert_commit '^project-time: setup'
assert_commit '^wordfreq: start cycle'
[ "$(git branch --show-current)" = main ] || fail "blank repo should stay on main"
pass "setup"

commits_before="$(git rev-list --count HEAD)"
agents_before="$(shasum AGENTS.md)"
reset_session
turn "/project-time"
[ "$(git rev-list --count HEAD)" = "$commits_before" ] || fail "second run made commits"
[ "$(shasum AGENTS.md)" = "$agents_before" ] || fail "second run changed AGENTS.md"
assert_count AGENTS.md 'project-time:start' 1
pass "idempotent"

save_snapshot spec-started
```

- [ ] **Step 2: Run the checker to verify it fails**

Run: `uv run --with pyyaml python tools/check_skills.py project-time`
Expected: `project-time: missing SKILL.md`, exit 1

- [ ] **Step 3: Write the skill**

`project-time/SKILL.md`:

````markdown
---
name: project-time
description: Entry point for the project workflow. Sets up the docs folder and standing memory rules on first run, then reads the state on disk and continues the active cycle (spec, plan, build, or wrap) for a new project or a feature. Use when the user types /project-time, wants to start a new project or feature with a spec and a tracked plan, or says continue, resume, or what's next on the project.
---

# Project Time

The front door of the project workflow. It makes sure the repo is set up, then hands off to the phase skill that owns the current state. It never does a phase's work itself.

Every piece of work is a **cycle**: the first build of a new project, or a feature. A cycle lives in `docs/current/` on its own branch and goes spec → plan → build → wrap, with a gate at each main point. Decisions, discoveries, pivots, issues and pins go into a hierarchical memory. The files on disk are the source of truth, so any session resumes by running `/project-time`.

| Phase skill | Owns |
|---|---|
| `project-spec` | the interview, `docs/current/spec.md`, Gate 0, spec amendments |
| `project-plan` | `docs/current/plan/`, Gate 1, plan updates |
| `project-build` | steps, progress, milestone gates, parallel runs |
| `project-wrap` | final gate, recap, memory consolidation, lessons, archive |

## 1. Setup check

Run on every invocation. Each check is cheap; write only what is missing or outdated.

1. **Git.** `git rev-parse --is-inside-work-tree`. Not a repo: offer `git init`. If the user declines, carry on and skip every commit in the workflow.
2. **AGENTS.md block.** Look for `<!-- project-time:start v1 -->` … `<!-- project-time:end -->`.
   - No block: append the block from the Templates section, creating `AGENTS.md` if needed.
   - Older version marker, or text that differs from the template: replace everything between the markers, markers included.
   - Identical: leave it alone.
3. **CLAUDE.md import.** Claude Code ignores `AGENTS.md` when a `CLAUDE.md` exists, so `CLAUDE.md` must import it. No file: create it containing `@AGENTS.md`. File without an `@AGENTS.md` line: append one.
4. **Project memory.** Create `docs/memory/INDEX.md` and `docs/memory/overview.md` from the templates if missing. Leave any other `docs/` content alone. If one of these paths exists but isn't ours, ask; never overwrite.

If anything was written, commit only those files as `project-time: setup`.

## 2. Route

Read the `Status:` field in the headers of `docs/current/spec.md` and `docs/current/plan/INDEX.md`, and the current branch.

| State | Action |
|---|---|
| No `docs/current/` | Start a new cycle (section 3) |
| Spec `Status: draft` | Invoke `project-spec` |
| Spec `approved`, plan missing or `Status: draft` | Invoke `project-plan` |
| Plan `approved`, any step not `[x]` | Invoke `project-build` |
| Every step `[x]` | Invoke `project-wrap` |

Before routing, compare the spec header's `Branch:` with the current branch. If they differ, stop and explain: either the user switched branches, or a branch was merged without wrapping. Ask how to proceed, and offer to wrap the cycle here.

If the user asks for something specific, route to its owner instead: "reopen" or "change the spec" → `project-spec` (amend mode); "change the plan" → `project-plan` (update mode); "a recap", "where do we stand" → `project-wrap` (interim recap).

**Hand off by invoking the phase skill with the Skill tool, never by reading its file.** An invoked skill survives context compaction; a file read doesn't. Pass one line of context: the cycle slug and the state you found.

## 3. Start a new cycle

1. **Slug.** Ask for a short kebab-case name, or propose one from the user's message. It prefixes memory IDs and commit messages, so keep it short.
2. **Type.** Infer it, don't ask. The repo is **blank** when `docs/archive/` is missing or empty and `git ls-files` lists nothing outside `docs/`, `AGENTS.md`, `CLAUDE.md`, `README*`, `LICENSE*` and dotfiles.
   - Blank → `project`. Not blank → `feature`.
   - State it in one line and carry on: "Starting feature cycle `import`. Say so if this is a project-level rewrite." A user override to `project` in a non-blank repo means a rewrite: a full-depth spec that still reads existing memory and code.
3. **Branch.** If the repo is not blank and you're on the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `main` or `master`), offer `git switch -c feature/<slug>`. A blank repo's first cycle may stay where it is. One active cycle per branch.
4. **Skeleton.** Create `docs/current/spec.md` and `docs/current/memory/INDEX.md` from the templates. Commit as `<slug>: start cycle`.
5. Invoke `project-spec`.

## Templates

### AGENTS.md block (v1)

```markdown
<!-- project-time:start v1 -->
## Project workflow (project-time)

This repo runs the project-time workflow. Its state lives in `docs/`: the files are the source of truth, the conversation is scratch.

- `docs/memory/`: project memory. Read it; only `project-wrap` changes it.
- `docs/current/`: the active cycle on this branch. `spec.md`, `plan/INDEX.md` with `plan/step-NN-*.md`, and `memory/` (cycle memory).
- `docs/archive/<date>-<slug>/`: finished cycles.

**Session start.** Read `docs/memory/INDEX.md`. If `docs/current/` exists, also read `docs/current/memory/INDEX.md` and `docs/current/plan/INDEX.md`. Open area files only when they relate to the work at hand.

**Memory.** Record in `docs/current/memory/` as soon as it happens, before moving on:
- a decision (with the why and the rejected options), a discovery, a pivot, an issue;
- anything the user asks to pin or remember: a one-liner with an ID under `## Pinned` in the cycle memory INDEX.

Entries go in area files by topic, each area listed in one line in the INDEX:

    ### <slug>.<NN> · <decision|discovery|pivot|issue> · <YYYY-MM-DD> · <phase or step>
    <the fact>
    **Why:** <reason; rejected options>

NN is the highest number in the cycle plus one. Never delete an entry. A pivot adds a new entry marked `Supersedes <id>` and appends `Superseded by <id>` to the old one. If the old one is in project memory, add `- <old> → <new> · <one line>` under `## Overrides` in the cycle INDEX instead. Cycle memory wins over project memory while the cycle is active. Pins from both indexes apply.

**Commits.** The workflow commits at setup, cycle start, each gate, each finished build step, and wrap. Never push.

**Sub-agents** never write under `docs/`. They report back; the main agent records.

**To continue work,** run `/project-time`.
<!-- project-time:end -->
```

### docs/memory/INDEX.md

```markdown
# Memory: project

Durable project memory. Changed only when a cycle wraps.

## Pinned

## Areas
- overview.md · what the system is, its main parts, where things live
```

### docs/memory/overview.md

```markdown
# Overview

What the system is, its main parts and where they live, how to run and test it. Rewritten at every wrap; empty until the first cycle wraps.
```

### docs/current/spec.md

```markdown
# Spec: <slug>

Cycle: <slug> · Type: <project|feature> · Branch: <branch> · Status: draft

## Open questions
- Everything: the interview has not started.
```

### docs/current/memory/INDEX.md

```markdown
# Memory: <slug> (cycle)

## Pinned

## Overrides

## Areas
```
````

- [ ] **Step 4: Run the checker to verify it passes**

Run: `uv run --with pyyaml python tools/check_skills.py project-time`
Expected: `ok: 1 skill(s)`

- [ ] **Step 5: Run the scenario**

Run (background): `tools/scenarios/01-setup.sh`
Expected: `PASS: setup`, `PASS: idempotent`, `snapshot: spec-started`. `project-spec` doesn't exist yet, so the router's hand-off will fail or improvise; that doesn't affect these assertions. If the agent improvises a spec interview in the first turn, check that it didn't write anything the assertions forbid.

- [ ] **Step 6: Review the transcript**

Read `$SCRATCH.log` (path printed at the start). Check what assertions can't: the type was stated in one line and not asked; the agent didn't do phase work itself; the hand-off used the Skill tool. Fix the skill and re-run step 5 if not.

- [ ] **Step 7: Commit**

```bash
git add project-time/SKILL.md tools/scenarios/01-setup.sh
git commit -m "Add project-time, the project workflow entry point"
```

---

### Task 4: project-spec

**Files:**
- Create: `project-spec/SKILL.md`
- Create: `tools/scenarios/02-spec.sh`

- [ ] **Step 1: Write the scenario**

`tools/scenarios/02-spec.sh`:

```bash
#!/usr/bin/env bash
# Interview written as it goes, interrupted and resumed, through Gate 0.
source "$(dirname "$0")/lib.sh"

from_snapshot spec-started
turn "/project-time"
turn "$(cat "$SCENARIOS/brief.md")"
turn "$ACCEPT"
turn "$ACCEPT"

assert_grep docs/current/spec.md '^## Open questions'
[ "$(grep -c '^## ' docs/current/spec.md)" -ge 3 ] || fail "spec not written as the interview goes"
grep -rqE '^### wordfreq\.[0-9]+ · decision' docs/current/memory || fail "no decision entries during the interview"
pass "written as it goes"

sections_before="$(grep '^## ' docs/current/spec.md)"
reset_session
turn "/project-time"
grep -qiE 'describe (the|your) (project|tool)|what (do|would) you (want|like) to build' <<< "$LAST" && fail "resume re-asked for the description"
while read -r h; do grep -qxF "$h" docs/current/spec.md || fail "section lost across the reset: $h"; done <<< "$sections_before"
pass "resumed"

drive 'grep -q "Status: approved" docs/current/spec.md' "$FINISH_SPEC" 15
assert_grep docs/current/spec.md 'AC-01'
assert_grep docs/current/spec.md 'Test command'
assert_commit '^wordfreq: spec approved \(gate 0\)'
pass "gate 0"

save_snapshot spec-approved
```

- [ ] **Step 2: Run the checker to verify it fails**

Run: `uv run --with pyyaml python tools/check_skills.py project-spec`
Expected: `project-spec: missing SKILL.md`

- [ ] **Step 3: Write the skill**

`project-spec/SKILL.md`:

````markdown
---
name: project-spec
description: Run the specification interview for a project-time cycle, one question at a time until the user says the spec is done, writing docs/current/spec.md as it goes, with an optional challenge round and an approval gate. Also amends an approved spec during the build. Use when /project-time hands off to it, or the user wants to write, resume, reopen or change the spec of the current project or feature.
---

# Project Spec

Turns what the user has in mind into `docs/current/spec.md`: what gets built, what doesn't, and how we'll know it works. Memory holds the why.

Follow the conventions in the project-time block of `AGENTS.md` (layout, memory entries, commits). If `docs/current/spec.md` doesn't exist, invoke `project-time` instead: it creates the cycle.

**Modes.** Spec `Status: draft` → interview, new or resumed. Spec `Status: approved` and the user wants a change → amend mode (last section).

## 1. Before the first question

- Read the spec header (`Type:`), the whole spec if resuming, both memory indexes, and `~/.claude/project-lessons.md` if it exists. Apply relevant lessons, and say so when one shapes a recommendation.
- If the repo has code: read `docs/memory/overview.md`, then explore the parts of the codebase the work touches. Never ask what the repo already answers.
- **Resuming:** say in two lines where things stand, then continue from the first item under Open questions.
- **New:** ask the user to describe the project or feature in their own words, unless they already have.

## 2. The interview

- **One question per message.** Multiple choice where possible, your recommended option first with a one-line reason. Open-ended is fine when options would be guesses.
- **Walk the decision tree one branch at a time**, to its end, before opening the next. When an answer raises new questions, add them to Open questions.
- **Order for `project`:** purpose → users → scope and non-goals → behaviour → data → constraints → architecture → testing approach.
- **Order for `feature`:** goal → affected areas → behaviour → acceptance criteria → testing → non-goals. Skip what project memory already settles, and cite it: "per `init.04` we're on SQLite, so no question there."
- **After every answer, before the next question:**
  1. Update `spec.md`: write or refine the section the answer resolves, remove the item from Open questions, add any new ones.
  2. If the answer settled a real choice, write a `decision` entry in cycle memory: the choice, why, and the options rejected. The spec says what; memory says why.
- Raise contradictions and risks the moment you see them. Otherwise elicit, don't debate: the challenge round is for that.
- **Acceptance criteria** get IDs `AC-01`, `AC-02`… Each describes observable behaviour a test can check. Vague ones ("fast", "user-friendly") get a number or an example, or get cut.
- The user can say "pin this" at any time: follow the pin rule in `AGENTS.md` immediately.

## 3. Finishing

1. **Coverage.** When you think the tree is covered, say so and list what's left under Open questions. Only the user ends the interview: they keep going or say it's done.
2. **Challenge round (optional).** Offer it. List the installed `knowledge-*` skills by name and let the user pick any, none, or skip the round. If taken: load the chosen lenses, stress-test the spec's assumptions one question at a time, and record what changes like any other answer.
3. **Self-review.** Fix inline: placeholders, sections that contradict each other, requirements with two readings (pick one and confirm it), acceptance criteria no test could check, a missing testing approach or test command.
4. **Gate 0.** Recap in 5 to 10 bullets: goal, scope and non-goals, key decisions with their memory IDs, number of acceptance criteria, open risks. Ask for approval. On approval: set `Status: approved`, commit spec and cycle memory as `<slug>: spec approved (gate 0)`, then invoke `project-plan`.

## Spec template

```markdown
# Spec: <slug>

Cycle: <slug> · Type: <project|feature> · Branch: <branch> · Status: draft

## Goal
## Users
## Scope and non-goals
## Behaviour
<!-- user-visible scenarios -->
## Data
## Constraints
## Architecture
## Acceptance criteria
- AC-01 · <observable behaviour>
## Testing approach
<!-- kinds of tests, what gets tested how -->
Test command: `<command that runs the whole suite>`
## Open questions
- <question>
```

A `feature` spec may drop Users, Data, Constraints and Architecture when they don't change. Acceptance criteria and Testing approach are never dropped. When Open questions is empty, write `- none`.

## Amend mode

For an approved spec the user wants to change, usually mid-build.

1. Ask what changes and why, one question at a time, until the change is clear.
2. Edit the affected sections. New acceptance criteria take the next free number; removed ones are struck through (`~~AC-04 · ...~~`), never renumbered.
3. Add a `## Amendments` section at the end if missing, and a line in it: `- <YYYY-MM-DD> · <what changed> · see <memory id>`.
4. Write a `pivot` entry in cycle memory. If the change reverses a project-memory entry, add an Overrides line too.
5. Light Gate 0: recap the change in 2 to 4 bullets and ask for OK. Commit as `<slug>: spec amended`.
6. Invoke `project-plan` in update mode, so the steps not started yet follow the change.
````

- [ ] **Step 4: Run the checker**

Run: `uv run --with pyyaml python tools/check_skills.py project-spec`
Expected: `ok: 1 skill(s)`

- [ ] **Step 5: Run the scenario**

Run (background): `tools/scenarios/02-spec.sh`
Expected: `PASS: written as it goes`, `PASS: resumed`, `PASS: gate 0`, `snapshot: spec-approved`. The hand-off to `project-plan` at the end will fail or improvise, since it doesn't exist yet; the assertions don't depend on it.

- [ ] **Step 6: Review the transcript**

Check in `$SCRATCH.log`: exactly one question per message; a recommendation on multiple-choice questions; the challenge round offered with the installed `knowledge-*` skills listed; a Gate 0 recap with memory IDs. Fix and re-run if not.

- [ ] **Step 7: Commit**

```bash
git add project-spec/SKILL.md tools/scenarios/02-spec.sh
git commit -m "Add project-spec, the spec interview and amend mode"
```

---

### Task 5: project-plan

**Files:**
- Create: `project-plan/SKILL.md`
- Create: `tools/scenarios/03-plan.sh`

- [ ] **Step 1: Write the scenario**

`tools/scenarios/03-plan.sh`:

```bash
#!/usr/bin/env bash
# Outline approved before any step file, then a traceable plan through Gate 1.
source "$(dirname "$0")/lib.sh"

from_snapshot spec-approved
turn "/project-time"
ls docs/current/plan/step-* >/dev/null 2>&1 && fail "step files written before the outline was approved"
pass "outline first"

turn "The outline is approved."
drive 'grep -q "Status: approved" docs/current/plan/INDEX.md 2>/dev/null' "Approved. Mode: sequential. Stop right after the gate 1 commit; don't start building." 6

assert_grep docs/current/plan/INDEX.md 'Mode: sequential'
[ -n "$(test_cmd)" ] || fail "no Test: command in the plan header"
assert_grep docs/current/plan/INDEX.md 'gate pending'
for f in docs/current/plan/step-*.md; do
  assert_grep "$f" '^## Verify'
  assert_grep "$f" '^## Done when'
  assert_grep "$f" '^## Tests to write first'
done
for ac in $(grep -oE 'AC-[0-9]+' docs/current/spec.md | sort -u); do
  grep -qw "$ac" docs/current/plan/step-*.md || fail "$ac is not covered by any step"
done
assert_commit '^wordfreq: plan approved \(gate 1\)'
pass "gate 1"

assert_count docs/current/plan/INDEX.md '^- \[(x|~)\]' 0
git log --format=%s | grep -E '^wordfreq step' >/dev/null && fail "build started inside 03"

save_snapshot plan-approved
```

- [ ] **Step 2: Run the checker to verify it fails**

Run: `uv run --with pyyaml python tools/check_skills.py project-plan`
Expected: `project-plan: missing SKILL.md`

- [ ] **Step 3: Write the skill**

`project-plan/SKILL.md`:

````markdown
---
name: project-plan
description: Turn an approved project-time spec into a plan that survives context resets, with milestones as vertical slices, one self-contained file per step with tests first and a verify command, explicit dependencies and parallel-safe groups, and a gate at every milestone. Also updates the plan after a pivot. Use when /project-time hands off to it, or the user wants to plan, re-plan or change the plan of the current cycle.
---

# Project Plan

Writes `docs/current/plan/`: an `INDEX.md` progress board and one file per step. A fresh session, or a sub-agent, must be able to pick up any step from its file alone.

Follow the conventions in the project-time block of `AGENTS.md`. If `docs/current/spec.md` is missing, invoke `project-time`.

**Modes.** No plan, or plan `Status: draft` → new plan. Plan approved and called after a spec amendment or a pivot → update mode (last section).

**Precondition.** The spec should be `Status: approved`. If it isn't, say so and ask. If the user insists on planning anyway, write a `decision` entry recording that Gate 0 was skipped and why.

## 1. Read

The spec, both memory indexes and the area files relevant to the work, `~/.claude/project-lessons.md` if it exists, and the codebase layout. If `plan/INDEX.md` exists as a draft, resume from it.

## 2. Milestone outline

Propose milestones as **vertical slices**: each ends with something working and testable end to end, never "the backend layer". The first milestone is a walking skeleton, the thinnest path through the whole system. For each milestone give its name, what works at its end, the acceptance criteria it covers, and its steps in one line each.

Ask for approval of the outline. Write no step files before it's approved. Once approved, write `plan/INDEX.md` with `Status: draft` so a reset doesn't lose the outline.

## 3. Steps

One file per step, `plan/step-NN-<name>.md`, from the step template.

- **Size.** Fits comfortably in one session and ends in one commit. Split anything bigger.
- **Tests first.** A step that adds logic or behaviour lists the tests to write before the code, concretely: test names and what each asserts.
- **Declared exceptions.** A step that can't be unit-tested (scaffolding, config, visual work) says so under Tests, with the reason, and still has a verify command: a build, a lint, the app booting, a page rendering.
- **Manual checks.** Anything that needs a human eye gets a `manual:` line under Done when. These are collected at the next gate.
- **Verify command.** Every step has one, runnable as is, with its expected result.
- **Needs.** Every step lists the steps it depends on, or `none`.
- **Parallel.** Mark two steps `∥` only if neither needs the other, directly or indirectly, and their Files touched lists share nothing, shared manifests, migration lists and route tables included. When in doubt, sequential.

## 4. Self-review

Fix inline before the gate:
- Every `AC-xx` in the spec maps to at least one step. Put the mapping in your recap.
- Every step has Tests (or a declared exception), a Verify command and Done when.
- Needs point only to existing steps, with no cycles.
- No placeholders, and no "handle edge cases" without saying which.

## 5. Gate 1

Recap: milestones with what works at the end of each, step count, parallel groups, manual checks, the AC mapping. Ask for approval and for the default execution mode, `sequential` or `parallel where possible`. Record the mode in the INDEX header, set `Status: approved`, commit as `<slug>: plan approved (gate 1)`, then invoke `project-build`.

## Templates

### plan/INDEX.md

```markdown
# Plan: <slug>

Status: draft · Mode: sequential · Test: `<the spec's test command>`
Current: step 01 (not started). Last stop: none.

## Milestone 1 · <name>  ⛔ gate pending
<what works at the end of this milestone>
- [ ] 01 <name>                (needs none)
- [ ] 02 <name>                (needs 01)
- [ ] 03 <name>                (needs 01)  ∥ 02

## Milestone 2 · <name>  ⛔ gate pending
<what works at the end of this milestone>
- [ ] 04 <name>                (needs 02, 03)

## Notes
```

Marks: `[ ]` todo, `[~]` in progress, `[x]` done, `[!]` blocked, followed by `→ <issue id>`. A passed gate reads `✅ gate passed <YYYY-MM-DD>` in place of `⛔ gate pending`.

### plan/step-NN-<name>.md

```markdown
# Step NN · <name>

**Milestone:** <n> · **Needs:** <steps or none> · **Covers:** <AC ids>

## Goal
<what exists after this step that didn't before>

## Files touched
- `<path>`: <what changes>

## Tests to write first
- `<test name>`: <what it asserts>

## Implementation notes
<approach, relevant memory IDs, pitfalls>

## Verify
`<command>` → <expected result>

## Done when
- <observable condition>
- manual: <what a human checks, only if needed>
```

For a declared exception, Tests to write first holds one line instead: `Exception: <why this step can't be unit-tested>`.

## Update mode

After a spec amendment, or a pivot found during the build:

1. Change only steps marked `[ ]`. Done and in-progress steps are never rewritten; if one needs rework, add a new step for it.
2. New steps take the next free number and sit in the INDEX in execution order, so the numbers in the list needn't be sequential.
3. Re-check dependencies and `∥` marks for everything touched, and redo the AC mapping.
4. Add a line under `## Notes`: `- <YYYY-MM-DD> · plan updated: <what changed> · see <memory id>`. Write a `pivot` entry if the amendment didn't already.
5. Show the user the change and ask for OK. Commit as `<slug>: plan updated`, then return to `project-build`.
````

- [ ] **Step 4: Run the checker**

Run: `uv run --with pyyaml python tools/check_skills.py project-plan`
Expected: `ok: 1 skill(s)`

- [ ] **Step 5: Run the scenario**

Run (background): `tools/scenarios/03-plan.sh`
Expected: `PASS: outline first`, `PASS: gate 1`, `snapshot: plan-approved`.

- [ ] **Step 6: Review the transcript and the plan**

Read `docs/current/plan/` in the scratch repo. Check: milestone 1 is a walking skeleton; step files are self-contained (could a stranger run step 02 from its file alone?); tests are concrete, not "write tests for X". Fix the skill and re-run if not.

- [ ] **Step 7: Commit**

```bash
git add project-plan/SKILL.md tools/scenarios/03-plan.sh
git commit -m "Add project-plan, milestones and self-contained step files"
```

---

### Task 6: project-build

**Files:**
- Create: `project-build/SKILL.md`
- Create: `tools/scenarios/04-build.sh`
- Create: `tools/scenarios/05-resume.sh`
- Create: `tools/scenarios/06-pivot.sh`
- Create: `tools/scenarios/07-parallel.sh`
- Create: `tools/scenarios/fixtures/parallel/` (8 files, step 5)

- [ ] **Step 1: Write the build-to-gate scenario**

`tools/scenarios/04-build.sh`:

```bash
#!/usr/bin/env bash
# Builds milestone 1, stops at its gate, then runs to the final gate.
source "$(dirname "$0")/lib.sh"

from_snapshot plan-approved
turn "/project-time"

milestone_block 1 | grep -E '^- \[( |~)\]' >/dev/null && fail "milestone 1 has unfinished steps"
milestone_block 1 | grep 'gate pending' >/dev/null || fail "milestone 1 gate should still be pending"
milestone_block 2 | grep -E '^- \[x\]' >/dev/null && fail "build ran past the milestone 1 gate"
assert_commit '^wordfreq step 01'
cmd="$(test_cmd)"; [ -n "$cmd" ] || fail "no Test: command"; eval "$cmd" || fail "tests fail at gate 1"
assert_clean_tree
pass "stopped at gate 1"

turn "Gate approved, continue. Stop at the final gate; don't wrap."
milestone_block 1 | grep 'gate passed' >/dev/null || fail "gate 1 not recorded as passed"
drive '[ -f docs/current/plan/INDEX.md ] && ! grep -qE "^- \[( |~)\]" docs/current/plan/INDEX.md' "Gate approved, continue. Stop at the final gate; don't wrap." 4
cmd="$(test_cmd)"; [ -n "$cmd" ] || fail "no Test: command"; eval "$cmd" || fail "tests fail at the final gate"
pass "reached the final gate"

save_snapshot at-final-gate
```

- [ ] **Step 2: Write the resume scenario**

`tools/scenarios/05-resume.sh`:

```bash
#!/usr/bin/env bash
# Resets mid-step with a dirty tree, and between a step commit and its index update.
source "$(dirname "$0")/lib.sh"

from_snapshot plan-approved
turn "/project-time Only do step 01, and stop right after writing its failing tests, before implementing anything."
assert_grep docs/current/plan/INDEX.md '\[~\] 01'
dirty="$(git status --porcelain --untracked-files=all | awk '{print $NF}' | grep -v '^docs/' || true)"
[ -n "$dirty" ] || fail "expected uncommitted test files"
grep -qi test <<< "$dirty" || fail "no uncommitted test file"

reset_session
turn "/project-time Finish step 01, then stop."
for f in $dirty; do [ -e "$f" ] || fail "uncommitted work lost: $f"; done
assert_grep docs/current/plan/INDEX.md '\[x\] 01'
assert_commit '^wordfreq step 01'
pass "dirty-tree resume"

perl -pi -e 's/\[x\] 01/[~] 01/' docs/current/plan/INDEX.md
git commit -qam "test: simulate a reset between step commit and index update"
step_commits="$(git log --format=%s | grep -c '^wordfreq step 01')"
reset_session
turn "/project-time Reconcile and tell me the state. Don't start any new step."
assert_grep docs/current/plan/INDEX.md '\[x\] 01'
[ "$(git log --format=%s | grep -c '^wordfreq step 01')" = "$step_commits" ] || fail "step 01 was redone"
pass "index-lag resume"
```

- [ ] **Step 3: Write the pivot scenario**

`tools/scenarios/06-pivot.sh`:

```bash
#!/usr/bin/env bash
# A change of mind mid-build: spec amended, plan updated, done steps untouched, pin recorded.
source "$(dirname "$0")/lib.sh"

from_snapshot plan-approved
turn "/project-time Only do step 01, then stop."
step01="$(shasum docs/current/plan/step-01-*.md)"

turn "Change of plan: add a --min-length N option that ignores words shorter than N. Also, pin this: the output stays plain text, never colours."
drive 'git log --format=%s | grep "^wordfreq: plan updated" >/dev/null' "$ACCEPT_OK Stop after the plan update; don't continue building." 8

assert_grep docs/current/spec.md '^## Amendments'
assert_grep docs/current/spec.md 'min-length'
grep -rqE '^### wordfreq\.[0-9]+ · pivot' docs/current/memory || fail "no pivot entry"
awk '/^## Pinned/{p=1; next} /^## /{p=0} p' docs/current/memory/INDEX.md | grep -iE 'plain.?text|colou?r|ansi' >/dev/null || fail "pin not in the cycle index"
awk '/^## Notes/{p=1; next} p' docs/current/plan/INDEX.md | grep -E '[0-9]{4}-[0-9]{2}-[0-9]{2} · plan updated' >/dev/null || fail "no dated plan note"
grep -lE 'min-length' docs/current/plan/step-*.md >/dev/null || fail "no step covers min-length"
[ "$(shasum docs/current/plan/step-01-*.md)" = "$step01" ] || fail "a done step was rewritten"
assert_commit '^wordfreq: spec amended'
pass "pivot"
```

- [ ] **Step 4: Write the parallel scenario**

`tools/scenarios/07-parallel.sh`:

```bash
#!/usr/bin/env bash
# Two independent steps run in worktrees; sub-agents leave docs/ alone.
source "$(dirname "$0")/lib.sh"

from_snapshot spec-started
cp -R "$SCENARIOS/fixtures/parallel/." .
git add -A
git commit -qm "wordfreq step 01: core counting (AC-01)"
python3 -m unittest -q || fail "fixture tests fail"

turn "/project-time Run steps 02 and 03 in parallel, then stop at the gate."

assert_grep docs/current/plan/INDEX.md '\[x\] 02'
assert_grep docs/current/plan/INDEX.md '\[x\] 03'
python3 -m unittest -q || fail "tests fail after the merge"
[ "$(git log --format=%s | grep -cE '^wordfreq step 0[23]')" -ge 2 ] || fail "missing step commits"
for sha in $(git log --format=%H --grep '^wordfreq step 0[23]:'); do
  git show --name-only --format= "$sha" | grep '^docs/' >/dev/null && fail "step commit $sha touched docs/"
done
assert_commit '^wordfreq: record steps'
assert_clean_tree
pass "parallel"
```

The "step commits don't touch `docs/`" check is what tells parallel from sequential: in sequential mode each step commit includes the plan and memory updates.

- [ ] **Step 5: Write the parallel fixture**

`tools/scenarios/fixtures/parallel/wordfreq.py`:

```python
"""Print the most frequent words in a text file."""
import re
import sys
from collections import Counter


def top_words(text, n=10):
    words = re.findall(r"[a-z']+", text.lower())
    counts = Counter(words)
    return sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:n]


def main(argv):
    with open(argv[1], encoding="utf-8") as f:
        for word, count in top_words(f.read()):
            print(f"{word} {count}")


if __name__ == "__main__":
    main(sys.argv)
```

`tools/scenarios/fixtures/parallel/test_wordfreq.py`:

```python
import unittest

from wordfreq import top_words


class TopWordsTest(unittest.TestCase):
    def test_counts_case_insensitively(self):
        self.assertEqual(top_words("The the THE cat"), [("the", 3), ("cat", 1)])

    def test_breaks_ties_alphabetically(self):
        self.assertEqual(top_words("b a"), [("a", 1), ("b", 1)])

    def test_limits_to_n(self):
        self.assertEqual(len(top_words("a b c d", n=2)), 2)


if __name__ == "__main__":
    unittest.main()
```

`tools/scenarios/fixtures/parallel/docs/current/spec.md`:

```markdown
# Spec: wordfreq

Cycle: wordfreq · Type: project · Branch: main · Status: approved

## Goal
A command-line tool that prints the most frequent words in a text file.

## Scope and non-goals
In scope: counting, a `--top` option, a stopword filter module. Out of scope: other languages, stemming.

## Behaviour
`python3 wordfreq.py FILE` prints `word count` lines, most frequent first, ties alphabetical.

## Acceptance criteria
- AC-01 · Words are counted case-insensitively, ties broken alphabetically, top 10 by default.
- AC-02 · `--top N` prints the N most frequent words instead of 10.
- AC-03 · `filter_stopwords(pairs)` drops the stopwords the, a, an, and, of, to from a list of (word, count) pairs.

## Testing approach
Unit tests with the standard library.
Test command: `python3 -m unittest -q`

## Open questions
- none
```

`tools/scenarios/fixtures/parallel/docs/current/plan/INDEX.md`:

```markdown
# Plan: wordfreq

Status: approved · Mode: parallel where possible · Test: `python3 -m unittest -q`
Current: step 02 (not started). Last stop: none.

## Milestone 1 · Counting CLI  ⛔ gate pending
The CLI counts words and takes --top; a stopword filter exists.
- [x] 01 core counting         (needs none)
- [ ] 02 top option            (needs 01)  ∥ 03
- [ ] 03 stopword filter       (needs 01)  ∥ 02

## Notes
```

`tools/scenarios/fixtures/parallel/docs/current/plan/step-01-core-counting.md`:

```markdown
# Step 01 · core counting

**Milestone:** 1 · **Needs:** none · **Covers:** AC-01

## Goal
`top_words(text, n)` and a CLI that prints the 10 most frequent words of a file.

## Files touched
- `wordfreq.py`: new, counting and CLI
- `test_wordfreq.py`: new

## Tests to write first
- `test_counts_case_insensitively`: "The the THE cat" gives the 3, cat 1
- `test_breaks_ties_alphabetically`: "b a" gives a before b
- `test_limits_to_n`: n=2 returns two pairs

## Implementation notes
Regex `[a-z']+` on the lowercased text, `collections.Counter`, sort by count descending then by word.

## Verify
`python3 -m unittest -q` → OK

## Done when
- The three tests pass.
```

`tools/scenarios/fixtures/parallel/docs/current/plan/step-02-top-option.md`:

```markdown
# Step 02 · top option

**Milestone:** 1 · **Needs:** 01 · **Covers:** AC-02

## Goal
`python3 wordfreq.py FILE --top N` prints the N most frequent words.

## Files touched
- `wordfreq.py`: parse `--top` with argparse in `main`
- `test_cli.py`: new

## Tests to write first
- `test_top_option_limits_output`: `main` on a temp file with `--top 2` prints exactly two lines
- `test_default_is_ten`: a file with 12 distinct words prints ten lines

## Implementation notes
Keep `top_words` unchanged; only `main` changes. Capture output with `contextlib.redirect_stdout`.

## Verify
`python3 -m unittest -q` → OK

## Done when
- Both tests pass, and step 01's tests still pass.
```

`tools/scenarios/fixtures/parallel/docs/current/plan/step-03-stopword-filter.md`:

```markdown
# Step 03 · stopword filter

**Milestone:** 1 · **Needs:** 01 · **Covers:** AC-03

## Goal
A `filter_stopwords(pairs)` function that drops English stopwords from `(word, count)` pairs.

## Files touched
- `stopwords.py`: new
- `test_stopwords.py`: new

## Tests to write first
- `test_drops_stopwords`: [("the", 5), ("cat", 2)] gives [("cat", 2)]
- `test_keeps_order`: the remaining pairs keep their original order

## Implementation notes
Stopwords: the, a, an, and, of, to. Not wired into the CLI in this step.

## Verify
`python3 -m unittest -q` → OK

## Done when
- Both tests pass.
```

- [ ] **Step 6: Run the checker to verify it fails**

Run: `uv run --with pyyaml python tools/check_skills.py project-build`
Expected: `project-build: missing SKILL.md`

- [ ] **Step 7: Write the skill**

`project-build/SKILL.md`:

````markdown
---
name: project-build
description: Execute the current project-time plan step by step, tests first, verified with real output, recording memory, marking progress on disk and committing each step, stopping at milestone gates, resuming cleanly after a context reset, and running parallel steps in git worktrees when the plan allows. Use when /project-time hands off to it, or the user wants to continue building, resume after a reset, run the next step, or run a gate.
---

# Project Build

Works through `docs/current/plan/` one step at a time. The disk is the source of truth: progress is written before and after every step, so a reset at any moment loses at most the conversation.

Follow the conventions in the project-time block of `AGENTS.md`. If the plan is missing, invoke `project-time`.

**Precondition.** The plan should be `Status: approved`. If it isn't, say so and ask. If the user insists, write a `decision` entry recording that Gate 1 was skipped and why.

## 1. Resume

Read `plan/INDEX.md`, both memory indexes and their pinned items. Then reconcile three sources:

- the **INDEX**: `Current:`, the marks, Last stop;
- **git log**: `git log --oneline --grep '^<slug> step'`;
- the **working tree**: `git status --porcelain`.

| Finding | Do |
|---|---|
| All three agree | Continue |
| INDEX says `[~] NN` but a `<slug> step NN` commit exists | The reset hit between commit and INDEX update. Mark NN `[x]`, advance `Current:`, commit the fix, continue |
| Uncommitted changes | Mid-step work. Read Last stop, run the step's tests to see where it stands, continue the step. **Never discard uncommitted work** |
| Anything else that doesn't line up | Stop. Show the mismatch and ask |

## 2. Run length

Run step after step through the current milestone and stop at its gate, or earlier on a blocker. If the user asked for one step, or to stop after a given step, do that instead.

## 3. Each step

1. **Start.** Mark the step `[~]` and set `Current: step NN (in progress). Last stop: starting.` Save it before touching code.
2. **Read** the step file and the memory area files it relates to.
3. **Tests first.** Write the tests the step lists. Run them and see them fail for the expected reason. Implement until they pass. Refactor with the tests green. A step with a declared exception skips this and relies on its verify command.
4. **Verify.** Run the step's verify command and show the real output. Never report "should pass".
5. **Memory checkpoint.** Was anything decided, discovered, pivoted or pinned during this step, or did an issue come up? Write each as an entry. "Nothing new" is a valid answer, but say it explicitly, in one line, to the user.
6. **Finish.** Mark `[x]`, advance `Current:` to the next step, and commit code, plan and memory together as `<slug> step NN: <name> (<AC ids>)`.

When pausing mid-step, or after a milestone inside a long step, update Last stop with one concrete line: what's done, what's next.

## 4. Gate

At the end of each milestone:

1. Run the full test command from the INDEX header and show the result.
2. Check each acceptance criterion this milestone covers against the running code.
3. List every `manual:` item from the milestone's steps for the user to check.
4. **Memory sweep.** Anything decided or learned since the last gate that isn't recorded? An index getting long, or an area file past about 200 lines? Split it and update the index.
5. Recap in a few bullets: what works now, deviations from the plan, memory entries added, open issues.
6. Wait for the user's go-ahead. On approval, mark the milestone `✅ gate passed <YYYY-MM-DD>` and commit as `<slug>: gate M<n> passed`.

After the last milestone's gate, invoke `project-wrap`.

## 5. Parallel mode

When the INDEX mode is `parallel where possible` and the next steps are marked `∥` with all their needs done, orchestrate instead of doing them yourself. If the user asked for sequential this time, or sub-agents with worktree isolation aren't available, run them one by one.

1. Mark each step in the group `[~]` and commit the INDEX.
2. Dispatch one sub-agent per step, each in its own git worktree (the Agent tool with worktree isolation), all in one message, with the prompt below.
3. When all have reported, merge each finished branch in step order. Resolve a trivial conflict. For a non-trivial one, abort that merge, set the step back to `[ ]` with a note in Last stop, and run it sequentially afterwards.
4. Run the full test command on the merged result.
5. Record memory from each report's candidates, after checking they hold. Mark done steps `[x]` and blocked ones `[!]` with an issue entry. Commit as `<slug> steps NN, MM: record progress`.

Sub-agent prompt:

```
You are implementing one step of a plan, alone, in your own git worktree.

<the full step file>

Rules:
- Do not create or modify anything under docs/. Report instead.
- Tests first: write the listed tests, run them and see them fail, implement until they pass, refactor. If the step declares an exception, rely on its verify command.
- Run the verify command and keep its real output.
- Commit your work in this worktree as: <slug> step NN: <name> (<AC ids>)

Report exactly:
Status: done | blocked
Branch and commit: <branch> <sha>
Verify output: <last 30 lines>
Memory candidates: one per line, "<decision|discovery|issue> · <fact> · Why: <reason>"
Notes: anything that affects other steps
```

## 6. When things go wrong

- **Verify keeps failing** after three honest attempts, each on a different hypothesis: mark the step `[!] → <issue id>`, write an `issue` entry with what was tried and what was observed, stop and report. Suggest instrumenting the code (`instrument-time`) or systematic debugging rather than more guessing.
- **The spec is wrong, or the user changes their mind:** invoke `project-spec` in amend mode. It updates the plan through `project-plan` and comes back here.
- **The plan is wrong** (a step too big, a missing dependency): invoke `project-plan` in update mode.
- **A pivot during a step:** record it in memory before continuing, never after.
````

- [ ] **Step 8: Run the checker**

Run: `uv run --with pyyaml python tools/check_skills.py project-build`
Expected: `ok: 1 skill(s)`

- [ ] **Step 9: Run the four scenarios**

Run (background, one at a time): `tools/scenarios/04-build.sh`, `05-resume.sh`, `06-pivot.sh`, `07-parallel.sh`
Expected: every `PASS:` line, and `snapshot: at-final-gate` from 04. After 04, `project-wrap` doesn't exist yet, so the final hand-off won't work; the assertions stop before it.

- [ ] **Step 10: Review the transcripts**

Check: test runs appear before implementation in each step; the one-line memory checkpoint appears after each step; the gate recap lists manual items and memory entries; in 07, two Agent dispatches in one message. Fix and re-run the affected scenario if not.

- [ ] **Step 11: Commit**

```bash
git add project-build/SKILL.md tools/scenarios/04-build.sh tools/scenarios/05-resume.sh \
  tools/scenarios/06-pivot.sh tools/scenarios/07-parallel.sh tools/scenarios/fixtures
git commit -m "Add project-build, the resumable step loop with gates and parallel runs"
```

---

### Task 7: project-wrap

**Files:**
- Create: `project-wrap/SKILL.md`
- Create: `tools/scenarios/08-wrap.sh`

- [ ] **Step 1: Write the scenario**

`tools/scenarios/08-wrap.sh`:

```bash
#!/usr/bin/env bash
# Final gate, recap, consolidation, one approved lesson, archive.
source "$(dirname "$0")/lib.sh"

from_snapshot at-final-gate
protect_lessons
turn "/project-time"
drive '[ ! -d docs/current ]' "Gate approved and manual checks confirmed. The consolidation looks right. Cycle pins are project-wide. Approve only the first lesson." 10

arch="$(ls -d docs/archive/*-wordfreq 2>/dev/null | head -1 || true)"
[ -n "$arch" ] || fail "no archive folder"
for f in spec.md plan/INDEX.md memory/INDEX.md recap.md; do assert_file "$arch/$f"; done
for h in 'What was built' 'How it went' 'Decisions that stand' 'Takeaways'; do assert_grep "$arch/recap.md" "^## $h"; done
grep -q 'empty until the first cycle wraps' docs/memory/overview.md && fail "overview not rewritten"
grep -rqE '^### wordfreq\.[0-9]+' docs/memory || fail "no entries promoted to project memory"
# ~/.claude is a protected path: headless runs can't write it, so the skill hands the line to the user instead.
if [ -f "$LESSONS" ]; then
  grep 'wordfreq' "$LESSONS" >/dev/null || fail "approved lesson not written"
  [ "$(grep -c 'wordfreq' "$LESSONS")" -le 1 ] || fail "more than the one approved lesson written"
else
  grep 'project-lessons.md' <<< "$LAST" >/dev/null || fail "approved lesson neither written nor handed to the user"
fi
assert_last_commit '^wordfreq: wrap'
assert_clean_tree
pass "wrap"

save_snapshot wrapped
```

- [ ] **Step 2: Run the checker to verify it fails**

Run: `uv run --with pyyaml python tools/check_skills.py project-wrap`
Expected: `project-wrap: missing SKILL.md`

- [ ] **Step 3: Write the skill**

`project-wrap/SKILL.md`:

````markdown
---
name: project-wrap
description: Close a project-time cycle with a final gate, a recap distilled from memory and plan, consolidation of cycle memory into project memory and the overview, promotion of approved cross-project lessons, and archiving of docs/current. Also writes interim recaps mid-cycle. Use when /project-time hands off to it, all plan steps are done, or the user wants to wrap up, finish or close the cycle, write takeaways, or get a recap of where the project stands.
---

# Project Wrap

Closes a cycle. Turns what's scattered across memory and plan into a recap a person can read, moves what's worth keeping into project memory, and archives the rest.

Follow the conventions in the project-time block of `AGENTS.md`. If `docs/current/` is missing, there's nothing to wrap: say so.

**Modes.** Every step `[x]` → full wrap. Otherwise, or when the user asks for "a recap" or "where do we stand" → interim recap: write section 2 only, commit it as `<slug>: interim recap`, and stop.

## 1. Final gate

1. **Bring the branch up to date**, for a cycle on a branch other than the default one: consolidation must merge into the latest project memory. Ask the user whether to rebase onto the default branch or merge it in. Recommend merge if the branch has been pushed.
2. Run the full test command from the plan INDEX and show the result.
3. Check every acceptance criterion in the spec against the running code, struck-through ones excluded. List any that fail.
4. List every `manual:` item not already confirmed at a milestone gate.
5. Wait for the user's go-ahead.

## 2. Recap

Write `docs/current/recap.md` from memory and plan, not from the conversation. It's prose for people: if the `human-write-time` skill is installed, follow it, along with `~/.claude/VOICE.md` if present.

```markdown
# Recap: <slug>

<cycle, type, branch, first and last date>

## What was built
<against the spec; deviations and why, with memory IDs>

## How it went
<milestones with gate dates; the pivot chain: what we believed, what changed our mind, what we did>

## Decisions that stand
- <id> · <decision> · <one-line why>

## Discoveries

## Open issues and known limitations

## Takeaways
<what worked, what to do differently next time>
```

Decisions that stand lists current entries only: skip anything superseded.

## 3. Consolidate memory

Go through cycle memory entry by entry and sort each one:

- **Promote:** decisions that still stand and constrain future work; discoveries that matter beyond this cycle; pivots that change a project-level entry.
- **Archive only:** detail that mattered only inside this cycle.
- **Cycle pins:** ask about each one, project-wide or done with.

Show the user the sorted list and ask for OK. Then:

1. Copy each promoted entry, ID unchanged, into the matching area file in `docs/memory/`. Create the area file and its INDEX line if needed.
2. For each Overrides line: append `Superseded by <new id>` to the project entry, and make sure the new entry is promoted.
3. Move approved pins under `## Pinned` in `docs/memory/INDEX.md`.
4. Rewrite `docs/memory/overview.md` to describe the system as it is now: what it is, its main parts and where they live, how to run and test it, the key decision IDs. Under a page.

## 4. Promote lessons

Some takeaways are about the user, their tools or their way of working, not this project: "library X breaks on scanned PDFs", "milestones of three to five steps worked best". Propose these as a numbered list and let the user approve each one. Append the approved ones to `~/.claude/project-lessons.md`, creating it with the header below if missing, one line each:

```markdown
# Project lessons

Cross-project lessons, approved one by one when a cycle wraps. Read by project-spec and project-plan.

- <YYYY-MM-DD> · <repo>/<slug> · <lesson>
```

When the file passes about 100 lines, group the lines under topic headings.

## 5. Archive

`git mv docs/current docs/archive/<YYYY-MM-DD>-<slug>` with today's date, then commit everything as `<slug>: wrap`. Don't push, don't merge. Tell the user the cycle is closed, the branch is ready to merge, and the next `/project-time` starts a new cycle.
````

- [ ] **Step 4: Run the checker**

Run: `uv run --with pyyaml python tools/check_skills.py project-wrap`
Expected: `ok: 1 skill(s)`

- [ ] **Step 5: Run the scenario**

Run (background): `tools/scenarios/08-wrap.sh`
Expected: `PASS: wrap`, `snapshot: wrapped`. Then confirm `~/.claude/project-lessons.md` is back to its previous state (restored by the trap).

- [ ] **Step 6: Review the recap**

Read `docs/archive/*-wordfreq/recap.md` in the scratch repo. Check: built from memory (memory IDs cited), the pivot chain present if there were pivots, no superseded decisions under Decisions that stand, and it reads like a person wrote it. Fix and re-run if not.

- [ ] **Step 7: Commit**

```bash
git add project-wrap/SKILL.md tools/scenarios/08-wrap.sh
git commit -m "Add project-wrap, recap, consolidation, lessons and archive"
```

---

### Task 8: Feature cycles

**Files:**
- Create: `tools/scenarios/09-feature.sh`
- Create: `tools/scenarios/10-two-branches.sh`

- [ ] **Step 1: Write the feature-cycle scenario**

`tools/scenarios/09-feature.sh`:

```bash
#!/usr/bin/env bash
# A later cycle is a feature on its own branch and leaves project memory alone;
# an explicit rewrite overrides the inferred type.
source "$(dirname "$0")/lib.sh"

from_snapshot wrapped
mem_before="$(find docs/memory -type f -exec shasum {} + | sort)"
turn "/project-time new cycle, slug json-out: add a --json flag that prints the result as a JSON object."
drive '[ -f docs/current/spec.md ]' "Yes, create the branch." 3
[ "$(git branch --show-current)" = feature/json-out ] || fail "branch not created"
assert_grep docs/current/spec.md 'Type: feature'
assert_grep docs/current/spec.md 'Branch: feature/json-out'
turn "$ACCEPT"
turn "$ACCEPT"
[ "$(find docs/memory -type f -exec shasum {} + | sort)" = "$mem_before" ] || fail "project memory changed during the cycle"
pass "feature cycle"

from_snapshot wrapped
turn "/project-time new cycle, slug v2. This is a project-level rewrite, not a feature."
drive '[ -f docs/current/spec.md ]' "Yes, create the branch." 3
assert_grep docs/current/spec.md 'Type: project'
pass "type override"
```

- [ ] **Step 2: Write the two-branches scenario**

`tools/scenarios/10-two-branches.sh`:

```bash
#!/usr/bin/env bash
# Two feature cycles active at once on separate branches, wrapped and merged one after the other.
source "$(dirname "$0")/lib.sh"

start_cycle() { # slug, description
  assert_clean_tree
  git switch -q main
  reset_session
  turn "/project-time new cycle, slug $1: $2 Keep it to one milestone with at most two steps."
  drive 'grep -q "Status: approved" docs/current/plan/INDEX.md 2>/dev/null' "$AUTOPILOT Stop right after the gate 1 commit; don't start building." 25
}
finish_cycle() { # slug
  assert_clean_tree
  git switch -q "feature/$1"
  reset_session
  turn "/project-time"
  drive "ls -d docs/archive/*-$1 >/dev/null 2>&1" "$AUTOPILOT" 25
  assert_clean_tree
  git switch -q main
  git merge -q --no-ff --no-edit "feature/$1" || fail "merging feature/$1 conflicted"
}

from_snapshot wrapped
protect_lessons
start_cycle json-out "add a --json flag that prints the result as a JSON object."
start_cycle makefile "add a Makefile whose test target runs the unit tests."
finish_cycle json-out
finish_cycle makefile

assert_file docs/archive/*-json-out/recap.md
assert_file docs/archive/*-makefile/recap.md
[ ! -d docs/current ] || fail "docs/current left on main"
grep -rq '<<<<<<<' docs && fail "conflict markers under docs/"
python3 -m unittest -q || fail "tests fail on main"
pass "two branches"
```

- [ ] **Step 3: Run both scenarios**

Run (background): `tools/scenarios/09-feature.sh`, then `tools/scenarios/10-two-branches.sh`
Expected: `PASS: feature cycle`, `PASS: type override`, `PASS: two branches`. Scenario 10 is the longest run in the plan: two full cycles.

- [ ] **Step 4: Review the transcripts**

In 09, check the spec interview reads `overview.md` and skips questions project memory settles (stack, test command). In 10, check the `makefile` wrap asked to bring the branch up to date before consolidating. Fix the relevant skill and re-run if not.

- [ ] **Step 5: Commit**

```bash
git add tools/scenarios/09-feature.sh tools/scenarios/10-two-branches.sh
git commit -m "Add feature-cycle scenarios for the project workflow"
```

---

### Task 9: Scenario README and the manual compaction check

**Files:**
- Create: `tools/scenarios/README.md`

- [ ] **Step 1: Write the README**

`tools/scenarios/README.md`:

````markdown
# Project workflow scenarios

Scripted runs of the `project-*` skills through headless `claude -p`, in throwaway git repos under `$TMPDIR`. Each script prints `PASS:` lines or stops at the first `FAIL:`. The conversation is logged next to the scratch repo, in `<scratch>.log`.

## Running

```bash
tools/scenarios/00-smoke.sh      # the harness itself
tools/scenarios/01-setup.sh      # saves snapshot spec-started
tools/scenarios/02-spec.sh       # needs spec-started, saves spec-approved
tools/scenarios/03-plan.sh       # needs spec-approved, saves plan-approved
tools/scenarios/04-build.sh      # needs plan-approved, saves at-final-gate
tools/scenarios/05-resume.sh     # needs plan-approved
tools/scenarios/06-pivot.sh      # needs plan-approved
tools/scenarios/07-parallel.sh   # needs spec-started, uses fixtures/parallel
tools/scenarios/08-wrap.sh       # needs at-final-gate, saves wrapped
tools/scenarios/09-feature.sh    # needs wrapped
tools/scenarios/10-two-branches.sh  # needs wrapped
```

Snapshots live in `${SCENARIO_SNAPSHOTS:-$HOME/.cache/project-workflow-snapshots}/` ($TMPDIR is cleaned by macOS, so snapshots default to `~/.cache` instead). After changing one skill, re-run from the first scenario that exercises it; earlier snapshots stay valid.

Runs are slow and cost tokens: each `turn` is a full `claude -p` call. Run them in the background.

The skills are linked into each scratch repo's `.claude/skills/`, so the scenarios test the working copy. Your user-level settings and plugins load too, which is intended: interference from them is a real finding.

`08-wrap.sh` backs up `~/.claude/project-lessons.md` and restores it on exit, in case a run manages to write it.

## Manual check: compaction

`claude -p` can't trigger compaction reliably, so this one is by hand.

1. Copy the snapshot: `cp -R "${SCENARIO_SNAPSHOTS:-$HOME/.cache/project-workflow-snapshots}/plan-approved" "$TMPDIR/compact-check" && cd "$TMPDIR/compact-check"`.
2. Start `claude` and run `/project-time Only do step 01, then stop.`
3. When it stops, run `/compact`.
4. Type `continue with the next step`.
5. Check that it works on step 02, not step 01 again; writes and runs the tests before the implementation; gives the one-line memory checkpoint; and commits as `wordfreq step 02: ...`.

## Manual check: the lessons file

`~/.claude/` is a protected path, so `claude -p` can't write `~/.claude/project-lessons.md` and `08-wrap.sh` only checks that the lesson was handed over. In an interactive session on a copy of the `at-final-gate` snapshot, run `/project-time`, approve the wrap and one lesson, accept the permission prompt, and check the file gets the header and exactly one lesson line. Remove or restore the file afterwards.
````

- [ ] **Step 2: Run the manual compaction check**

Follow the README's manual check. Record the outcome (pass, or what went wrong) for the final report to the user. If it fails because the `project-build` rules were lost, check the skill is under the size budget and that `project-time` hands off with the Skill tool.

- [ ] **Step 3: Commit**

```bash
git add tools/scenarios/README.md
git commit -m "Document the project workflow scenarios and the compaction check"
```

---

### Task 10: README and final checks

**Files:**
- Modify: `README.md` (after the Process table, before "### Architecture Knowledge")

- [ ] **Step 1: Check how the installer takes several skills**

Run: `npx skills add --help 2>&1 | grep -iA2 -- '--skill'`
Expected: tells whether `--skill` accepts several names. The README below uses a loop, which works either way; switch to a single command if several names are supported.

- [ ] **Step 2: Add the README section**

Insert before `### Architecture Knowledge`:

````markdown
### Project workflow

A spec → plan → build → wrap cycle for a new project or a single feature, with a hierarchical memory of decisions, discoveries, pivots and pins, and progress on disk that survives context resets. You type `/project-time`; it sets the repo up on first run and continues wherever the work stands.

| Skill | Description |
|-------|-------------|
| [project-time](./project-time) | Entry point. Sets up `docs/`, a standing-rules block in `AGENTS.md`, and routes to the phase that owns the current state. |
| [project-spec](./project-spec) | One-question-at-a-time interview written to the spec as it goes, optional challenge round, approval gate, amend mode. |
| [project-plan](./project-plan) | Milestones as vertical slices, self-contained step files with tests first, parallel-safe groups, a gate per milestone. |
| [project-build](./project-build) | Resumable step loop: tests first, real verification, memory checkpoints, a commit per step, parallel steps in worktrees. |
| [project-wrap](./project-wrap) | Final gate, recap from memory, consolidation into project memory, approved cross-project lessons, archive. |

Install all five:

```bash
for s in project-time project-spec project-plan project-build project-wrap; do
  npx skills add paull78/skills --skill "$s" --global
done
```
````

- [ ] **Step 3: Run the full static check**

Run: `uv run --with pyyaml python tools/check_skills.py project-time project-spec project-plan project-build project-wrap && uv run --with pyyaml --with pytest pytest -q tools/test_check_skills.py`
Expected: `ok: 5 skill(s)` and `10 passed`

- [ ] **Step 4: Check the installer sees the skills**

Run: `npx skills add . --list 2>&1 | grep -E 'project-(time|spec|plan|build|wrap)'`
Expected: all five listed. If the local path form isn't supported, push the branch only after asking the user, or skip this step and say so.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "Add the project workflow skills to the README"
```

- [ ] **Step 6: Report**

Tell the user: which scenarios passed, which needed skill fixes and what changed, the outcome of the manual compaction check, and anything left open. Don't push or merge: the branch `project-workflow` is theirs to review.
