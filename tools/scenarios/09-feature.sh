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
