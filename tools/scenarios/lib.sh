#!/usr/bin/env bash
# Helpers for scenario runs of the project workflow skills in throwaway repos.
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1

SCENARIOS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO="$(cd "$SCENARIOS/../.." && pwd)"
WORKFLOW_SKILLS=(project-time project-spec project-plan project-build project-wrap)
SNAPSHOTS="${SCENARIO_SNAPSHOTS:-$HOME/.cache/project-workflow-snapshots}"
GENERAL="$HOME/.agents/memory"
LESSONS="$GENERAL/lessons.md"
USER_CLAUDE_MD="$HOME/.claude/CLAUDE.md"
OLD_LESSONS="$HOME/.claude/project-lessons.md"
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
  # project,local only: skills installed in ~/.claude/skills would otherwise shadow the
  # working copies linked into the scratch repo, and the scenarios would test the wrong code.
  local args=(-p "$prompt" --output-format json --permission-mode acceptEdits
    --setting-sources project,local
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

# Keep the real general memory (~/.agents/memory/), ~/.claude/CLAUDE.md and the old
# ~/.claude/project-lessons.md out of the tests' reach: setup and wrap write them.
# Every scenario sources this file, so every run is protected.
GENERAL_BACKUP="$(mktemp -d)"
for p in "$GENERAL" "$USER_CLAUDE_MD" "$OLD_LESSONS"; do
  [ -e "$p" ] && cp -R "$p" "$GENERAL_BACKUP/$(basename "$p")"
done
restore_general() {
  for p in "$GENERAL" "$USER_CLAUDE_MD" "$OLD_LESSONS"; do
    rm -rf "$p"
    [ -e "$GENERAL_BACKUP/$(basename "$p")" ] && cp -R "$GENERAL_BACKUP/$(basename "$p")" "$p"
  done
  return 0
}
trap restore_general EXIT
# Kept for older scenario scripts; the protection above already runs.
protect_lessons() { :; }
