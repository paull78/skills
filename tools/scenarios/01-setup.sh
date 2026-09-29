#!/usr/bin/env bash
# Setup on a blank repo, then a second run that must change nothing.
source "$(dirname "$0")/lib.sh"

new_scratch
turn "/project-time new project, slug wordfreq. I'll describe it when you ask."

assert_grep AGENTS.md '<!-- project-time:start v2 -->'
assert_grep AGENTS.md '<!-- project-time:end -->'
assert_grep CLAUDE.md '^@AGENTS.md$'
assert_file docs/memory/INDEX.md
assert_file docs/memory/overview.md
assert_grep docs/current/spec.md 'Type: project'
assert_grep docs/current/spec.md 'Status: draft'
assert_grep docs/current/spec.md 'Branch: main'
assert_file docs/current/memory/INDEX.md
assert_commit '^project-time: setup'
assert_commit '^wordfreq: start cycle'
[ "$(git branch --show-current)" = main ] || fail "blank repo should stay on main"
pass "setup"

commits_before="$(git rev-list --count HEAD)"
agents_before="$(shasum AGENTS.md)"
reset_session
turn "/project-time"
[ "$(git rev-list --count HEAD)" = "$commits_before" ] || fail "second run made commits"
[ "$(shasum AGENTS.md)" = "$agents_before" ] || fail "second run changed AGENTS.md"
assert_count AGENTS.md 'project-time:start' 1
pass "idempotent"

save_snapshot spec-started
