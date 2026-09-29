---
name: project-wrap
description: Close a project-time cycle with a final gate, a recap distilled from memory and plan, consolidation of cycle memory into project memory and the overview, promotion of approved cross-project lessons, and archiving of docs/current. Also writes interim recaps mid-cycle. Use when /project-time hands off to it, all plan steps are done, or the user wants to wrap up, finish or close the cycle, write takeaways, or get a recap of where the project stands.
---

# Project Wrap

Closes a cycle. Turns what's scattered across memory and plan into a recap a person can read, moves what's worth keeping into project memory, and archives the rest.

Follow the conventions in the project-time block of `AGENTS.md`. If `docs/current/` is missing, there's nothing to wrap: say so.

**Modes.** Every step `[x]` → full wrap. Otherwise, or when the user asks for "a recap" or "where do we stand" → interim recap: write section 2 only, commit it as `<slug>: interim recap`, and stop.

## 1. Final gate

1. **Bring the branch up to date**, for a cycle on a branch other than the default one: consolidation must merge into the latest project memory. Ask the user whether to rebase onto the default branch or merge it in. Recommend merge if the branch has been pushed.
2. Run the full test command from the plan INDEX and show the result.
3. Check every acceptance criterion in the spec against the running code, struck-through ones excluded. List any that fail.
4. List every `manual:` item not already confirmed at a milestone gate.
5. Wait for the user's go-ahead.

## 2. Recap

Write `docs/current/recap.md` from memory and plan, not from the conversation. It's prose for people: if the `human-write-time` skill is installed, follow it, along with `~/.claude/VOICE.md` if present.

```markdown
# Recap: <slug>

<cycle, type, branch, first and last date>

## What was built
<against the spec; deviations and why, with memory IDs>

## How it went
<milestones with gate dates; the pivot chain: what we believed, what changed our mind, what we did>

## Decisions that stand
- <id> · <decision> · <one-line why>

## Discoveries

## Open issues and known limitations

## Takeaways
<what worked, what to do differently next time>
```

Decisions that stand lists current entries only: skip anything superseded.

## 3. Consolidate memory

Go through cycle memory entry by entry and sort each one:

- **Promote:** decisions that still stand and constrain future work; discoveries that matter beyond this cycle; pivots that change a project-level entry.
- **Archive only:** detail that mattered only inside this cycle.
- **Cycle pins:** ask about each one, project-wide or done with.

Show the user the sorted list and ask for OK. Then:

1. Copy each promoted entry, ID unchanged, into the matching area file in `docs/memory/`. Create the area file and its INDEX line if needed.
2. For each Overrides line: append `Superseded by <new id>` to the project entry, and make sure the new entry is promoted.
3. Move approved pins under `## Pinned` in `docs/memory/INDEX.md`.
4. Rewrite `docs/memory/overview.md` to describe the system as it is now: what it is, its main parts and where they live, how to run and test it, the key decision IDs. Under a page.

## 4. Promote lessons

Some takeaways are about the user, their tools or their way of working, not this project: "library X breaks on scanned PDFs", "milestones of three to five steps worked best". Propose these as a numbered list and let the user approve each one. Append the approved ones to `~/.claude/project-lessons.md`, creating it with the header below if missing, one line each:

```markdown
# Project lessons

Cross-project lessons, approved one by one when a cycle wraps. Read by project-spec and project-plan.

- <YYYY-MM-DD> · <repo>/<slug> · <lesson>
```

When the file passes about 100 lines, group the lines under topic headings.

## 5. Archive

`git mv docs/current docs/archive/<YYYY-MM-DD>-<slug>` with today's date, then commit everything as `<slug>: wrap`. Don't push, don't merge. Tell the user the cycle is closed, the branch is ready to merge, and the next `/project-time` starts a new cycle.
