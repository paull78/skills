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
