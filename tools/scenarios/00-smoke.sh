#!/usr/bin/env bash
# Checks the harness: a scratch repo, one turn, a resumed turn.
source "$(dirname "$0")/lib.sh"

new_scratch
turn "Reply with exactly the word: pineapple"
grep -qi pineapple <<< "$LAST" || fail "first turn"
[ -n "$SESSION" ] || fail "no session id"
turn "What word did you just reply with? Answer with that word only."
grep -qi pineapple <<< "$LAST" || fail "resume lost the session"
[ -L .claude/skills/project-time ] || [ ! -d "$SKILLS_REPO/project-time" ] || fail "skills not linked"
pass "smoke"
