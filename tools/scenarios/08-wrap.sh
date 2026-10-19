#!/usr/bin/env bash
# Final gate, recap, consolidation, one approved lesson, archive.
source "$(dirname "$0")/lib.sh"

from_snapshot at-final-gate
protect_lessons
turn "/project-time"
drive '[ ! -d docs/current ]' "Gate approved and manual checks confirmed. The consolidation looks right. Cycle pins are project-wide. Approve only the first lesson." 10

arch="$(ls -d docs/archive/*-wordfreq 2>/dev/null | head -1 || true)"
[ -n "$arch" ] || fail "no archive folder"
for f in spec.md plan/INDEX.md memory/INDEX.md recap.md; do assert_file "$arch/$f"; done
for h in 'What was built' 'How it went' 'Decisions that stand' 'Takeaways'; do assert_grep "$arch/recap.md" "^## $h"; done
grep -q 'empty until the first cycle wraps' docs/memory/overview.md && fail "overview not rewritten"
grep -rqE '^### wordfreq\.[0-9]+' docs/memory || fail "no entries promoted to project memory"
# General memory is outside the repo: a headless run may be refused the write, so the skill hands the line to the user instead.
if [ -f "$LESSONS" ]; then
  grep 'wordfreq' "$LESSONS" >/dev/null || fail "approved lesson not written"
  [ "$(grep -c 'wordfreq' "$LESSONS")" -le 1 ] || fail "more than the one approved lesson written"
else
  grep 'lessons.md' <<< "$LAST" >/dev/null || fail "approved lesson neither written nor handed to the user"
fi
assert_last_commit '^wordfreq: wrap'
assert_clean_tree
pass "wrap"

save_snapshot wrapped
