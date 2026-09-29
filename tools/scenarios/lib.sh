#!/usr/bin/env bash
# Helpers for scenario runs of the project workflow skills in throwaway repos.
set -euo pipefail

SCENARIOS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO="$(cd "$SCENARIOS/../.." && pwd)"
WORKFLOW_SKILLS=(project-time project-spec project-plan project-build project-wrap)
SNAPSHOTS="${TMPDIR:-/tmp}/project-workflow-snapshots"
LESSONS="$HOME/.claude/project-lessons.md"
TOOLS=(Read Write Edit Glob Grep Skill Agent
  "Bash(git:*)" "Bash(mkdir:*)" "Bash(ls:*)" "Bash(cat:*)" "Bash(mv:*)" "Bash(cp:*)"
  "Bash(python3:*)" "Bash(test:*)" "Bash(grep:*)" "Bash(find:*)" "Bash(wc:*)"
  "Bash(date:*)" "Bash(make:*)" "Bash(sed:*)" "Bash(awk:*)" "Bash(head:*)" "Bash(tail:*)"
  "Bash(touch:*)" "Bash(shasum:*)")
SESSION=""
LAST=""

# Canned user replies.
ACCEPT="I'll take your recommendation."
ACCEPT_OK="Yes, OK. I'll take your recommendation."
FINISH_SPEC="I'll take your recommendation. If you think the spec covers everything: it's done, skip the challenge round, and I approve it."
AUTOPILOT="Yes. Take your recommendation. Whatever you are asking me to approve (outline, spec, plan, gate, consolidation) is approved; use sequential mode; manual checks are confirmed; merge rather than rebase; no lessons to promote; pins are done with."

fail() { echo "FAIL: $*" >&2; exit 1; }
pass() { echo "PASS: $*"; }

_link_skills() {
  mkdir -p .claude/skills
  for s in "${WORKFLOW_SKILLS[@]}"; do
    [ -d "$SKILLS_REPO/$s" ] && ln -sfn "$SKILLS_REPO/$s" ".claude/skills/$s"
  done
  grep -qx '.claude/' .git/info/exclude || echo '.claude/' >> .git/info/exclude
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
  local prompt="$1" out
  local args=(-p "$prompt" --output-format json --permission-mode acceptEdits
    --add-dir "$HOME/.claude" --allowedTools "${TOOLS[@]}")
  [ -n "$SESSION" ] && args+=(--resume "$SESSION")
  out="$(claude "${args[@]}")"
  SESSION="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["session_id"])')"
  LAST="$(printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("result", ""))')"
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
assert_last_commit() { git log -1 --format=%s | grep -qE -- "$1" || fail "last commit '$(git log -1 --format=%s)' does not match /$1/"; }
assert_commit() { git log --format=%s | grep -qE -- "$1" || fail "no commit matching /$1/"; }

# Lines of one milestone in the plan index.
milestone_block() { awk -v n="$1" '/^## /{p = ($2 == "Milestone" && $3 == n)} p' docs/current/plan/INDEX.md; }
# The full test command from the plan index header.
test_cmd() { sed -nE 's/.*Test: `([^`]+)`.*/\1/p' docs/current/plan/INDEX.md | head -1; }

# Keep the real ~/.claude/project-lessons.md out of the tests' reach.
protect_lessons() {
  LESSONS_BACKUP="$(mktemp)"
  if [ -f "$LESSONS" ]; then cp "$LESSONS" "$LESSONS_BACKUP"; HAD_LESSONS=1; else HAD_LESSONS=0; fi
  trap restore_lessons EXIT
}
restore_lessons() {
  if [ "$HAD_LESSONS" = 1 ]; then cp "$LESSONS_BACKUP" "$LESSONS"; else rm -f "$LESSONS"; fi
}
