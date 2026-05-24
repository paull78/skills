---
name: save-time
description: Write a markdown recap of the current conversation so the work can be resumed later — by a future session, another agent, or the user themselves. Captures decisions and their rationale, plans in flight, gotchas hit, pitfalls to avoid, open questions, and where things stand. Omits anything obvious from the code or git history. Use when the user says "save-time", asks to recap, snapshot, checkpoint, or hand off the conversation, wants to stop and resume later, or needs a brain-dump before context is compacted or the session ends.
---

# Save Time

Write a markdown file that recaps the current conversation well enough for someone — a future Claude session, a teammate, or the user after a weekend away — to resume the work without re-reading the whole transcript.

## The Core Principle

A good recap is a **handoff document**, not a transcript. It captures what a fresh reader could not reconstruct from the repo alone: the *why* behind decisions, the dead ends already explored, the surprises encountered, and where the cursor is right now.

Everything that can be re-derived from `git log`, `git diff`, file contents, or a quick re-read of the PRD does not belong here. If a future reader could find it in 30 seconds by looking at the code, leave it out.

Signal over completeness. A short, sharp recap is more useful than a long, faithful one.

## When to Use

**Use when:**
- The user says "save-time", "recap", "checkpoint", "snapshot the conversation", or "hand this off"
- Context is about to be compacted and important reasoning would be lost
- The session is wrapping up mid-task and work will resume later
- The user is switching machines, taking a break, or passing work to a teammate
- A long exploration produced decisions whose rationale lives only in the conversation

**Don't use when:**
- The work is already fully captured in a plan file, PRD, or commit message — point the user at that instead
- The user wants a PR description (different audience, different shape)
- The user wants documentation for end readers (use `explain-time`)
- The conversation is trivial or single-shot

## Output Location

Default to `recaps/<short-topic>-YYYY-MM-DD.md` in the repo root. If a `plans/` or `docs/` directory is more idiomatic for the project, mirror that. State the path before writing so the user can redirect.

If a previous recap on the same topic exists, prefer updating it (append a new dated section) over creating a parallel file — recaps that fragment across many files defeat the purpose.

## Process

1. **Skim the conversation for load-bearing moments.** Decisions made, assumptions adopted, blind alleys walked, surprises hit, things the user explicitly flagged as important. Ignore routine tool calls, file reads, and back-and-forth that produced no lasting decision.

2. **Identify the cursor.** Where exactly does work resume? A file, a function, a failing test, a question waiting on the user, a PR awaiting review.

3. **List the open threads.** Anything started but not finished, anything deferred, anything the user said "we'll come back to."

4. **Capture the gotchas.** Concretely: things that surprised you or the user, subtle constraints discovered, behavior that contradicted intuition, environment-specific quirks. These are the most expensive things to rediscover.

5. **Capture the rejected options.** "We considered X but went with Y because Z" — this prevents the next session from re-litigating settled choices.

6. **Write the recap using the template below.** Keep it scannable. Bullets over prose. Concrete file paths and identifiers over vague gestures.

7. **Self-review with the inference test.** For each line, ask: *could a fresh reader infer this from the repo in under a minute?* If yes, delete the line.

## What to Capture

- **Decisions and their why.** The decision alone is in the code; the *why* is only in the conversation. Always pair them.
- **Plans in flight.** What was about to happen next, in concrete terms (file, function, test, command).
- **Gotchas.** Things that bit you or could bite the next reader. Be specific — "the cache key includes the locale, not just the user id" beats "watch out for caching".
- **Pitfalls and dead ends.** Approaches tried and abandoned, with one-line reasons. Saves the next session from retrying them.
- **Open questions.** Things waiting on the user, on a teammate, on a deploy, or on more investigation.
- **Pointers.** File:line citations, PR numbers, ticket IDs, dashboard URLs, branch names — the breadcrumbs the next session needs.
- **State of the repo.** Branch, dirty files, whether tests pass, whether anything is committed yet.

## What to Omit

- The conversation's chronological order. Reorganize by topic, not by turn.
- Routine tool calls and file reads that produced no decision.
- Restatements of the PRD, plan, or task file — link to them instead.
- Code snippets that exist in the repo. Cite `file.ts:42` instead of pasting.
- Praise, hedging, social filler, "let me check…" narration.
- Anything obvious from the diff or the most recent commit messages.
- Future-you's job. Don't predict what the next session should do beyond the immediate next step; that's planning, not recap.

## Recap Template

```md
# Recap: <topic> — <YYYY-MM-DD>

> Audience: a future session (or teammate) resuming this work cold. Assumes they can read code and run the repo, but were not in the conversation.

## Where things stand
- **Branch:** <branch-name>
- **Working tree:** <clean | dirty: list key uncommitted files>
- **Tests:** <pass | failing: which>
- **Next concrete step:** <one sentence — what to do first on resume>

## Goal
One-paragraph reminder of what we're trying to accomplish and why. Link to the PRD/plan/issue if one exists.

## Decisions made (and why)
- **<decision>** — <one-line why>. <pointer if applicable>
- ...

## Plans in flight
- **<thing started>** — <where it stands, what's left>. <file:line or PR#>
- ...

## Gotchas
- **<surprising thing>** — <one-line explanation so it doesn't bite again>
- ...

## Rejected options
- **<option considered>** — <one-line reason it was dropped>
- ...

## Open questions
- **<question>** — <who/what it's waiting on>
- ...

## Pointers
- <file:line> — <what's notable here>
- <PR / issue / URL> — <what it is>
- ...

## How to resume
1. <first concrete action>
2. <second>
3. ...
```

Sections with no entries should be removed, not left empty — empty sections are noise.

## Style Rules

- Bullets over paragraphs. The reader is scanning, not reading.
- Concrete over abstract. `auth/session.ts:88` beats "the session module". `"Tenants over 100k rows hit the slow path"` beats "performance issues at scale".
- Past tense for what happened, present tense for current state, imperative for next steps.
- One line per bullet where possible. If a point needs a paragraph, it's probably two points.
- No emoji unless the user asked for them.
- No marketing voice. No "we elegantly decided…" — just say what was decided and why.
- Link, don't paste. If the PRD has it, link to the PRD.

## A Quick Self-Review Before Saving

1. **Inference test.** For every bullet, could a fresh reader derive it from the code/git in under a minute? Delete those.
2. **Cursor test.** Could the reader, after reading this, know exactly what command to run or file to open first? If not, fix the "How to resume" section.
3. **Why test.** Every decision should have a why. If a decision has none, either add it or drop the bullet — the decision is already in the code.
4. **Gotcha test.** Anything that surprised you in this session — is it written down? Those are the most valuable lines in the doc.
5. **Length check.** If the recap is longer than the PRD, something is wrong. Cut.
