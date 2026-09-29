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
