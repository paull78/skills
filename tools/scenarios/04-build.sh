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
