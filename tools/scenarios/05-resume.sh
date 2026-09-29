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
