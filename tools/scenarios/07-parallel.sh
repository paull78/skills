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
