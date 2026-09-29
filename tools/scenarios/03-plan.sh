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
