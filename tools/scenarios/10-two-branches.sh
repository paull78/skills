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
