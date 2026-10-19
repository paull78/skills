---
name: project-spec
description: Run the specification interview for a project-time cycle, one question at a time until the user says the spec is done, writing docs/current/spec.md as it goes, with an optional challenge round and an approval gate. Also amends an approved spec during the build. Use when /project-time hands off to it, or the user wants to write, resume, reopen or change the spec of the current project or feature.
---

# Project Spec

Turns what the user has in mind into `docs/current/spec.md`: what gets built, what doesn't, and how we'll know it works. Memory holds the why.

Follow the conventions in the project-time block of `AGENTS.md` (layout, memory entries, commits). If `docs/current/spec.md` doesn't exist, invoke `project-time` instead: it creates the cycle.

**Modes.** Spec `Status: draft` → interview, new or resumed. Spec `Status: approved` and the user wants a change → amend mode (last section).

## 1. Before the first question

- Read the spec header (`Type:`), the whole spec if resuming, the three memory indexes (general, project, cycle) and the general area files that relate to the work, lessons included. Apply what's relevant, and say so when a general entry shapes a recommendation.
- If the repo has code: read `docs/memory/overview.md`, then explore the parts of the codebase the work touches. Never ask what the repo already answers.
- **Resuming:** say in two lines where things stand, then continue from the first item under Open questions. If Open questions is `- none`, go to section 3.
- **New:** ask the user to describe the project or feature in their own words, unless they already have.

## 2. The interview

- **One question per message.** Multiple choice where possible, your recommended option first with a one-line reason. Open-ended is fine when options would be guesses.
- **Walk the decision tree one branch at a time**, to its end, before opening the next. When an answer raises new questions, add them to Open questions.
- **Order for `project`:** purpose → users → scope and non-goals → behaviour → acceptance criteria → data → constraints → architecture → testing approach.
- **Order for `feature`:** goal → affected areas → behaviour → acceptance criteria → testing → non-goals. Skip what project memory already settles, and cite it: "per `init.04` we're on SQLite, so no question there."
- **After every answer, before the next question:**
  1. Update `spec.md`: write or refine the section the answer resolves, remove the item from Open questions, add any new ones. When the answer settles observable behaviour, add or refine the `AC-xx` that checks it in the same edit.
  2. If the answer settled a real choice, write a `decision` entry in cycle memory: the choice, why, and the options rejected. The spec says what; memory says why.
- Raise contradictions and risks the moment you see them. Otherwise elicit, don't debate: the challenge round is for that.
- If you fill a section without asking because the answer is obvious, say so in the same message ("Data: none, no stored state") so the user can object.
- If the user asks to finish while questions are still open, say once which ones are open and why they matter, then carry on with the next question. Don't repeat that notice, and don't offer to settle the rest in bulk.
- **Acceptance criteria** get IDs `AC-01`, `AC-02`… Each describes observable behaviour a test can check. Vague ones ("fast", "user-friendly") get a number or an example, or get cut.
- The user can say "pin this" at any time: follow the pin rule in `AGENTS.md` immediately.

## 3. Finishing

1. **Coverage.** When you think the tree is covered, say so and list what's left under Open questions. Only the user ends the interview: they keep going or say it's done.
2. **Challenge round (optional).** Offer it. List the installed `knowledge-*` skills by name and let the user pick any, none, or skip the round. If the user already declined it, say in one line that it's skipped and name the lenses that were available. If taken: load the chosen lenses, stress-test the spec's assumptions one question at a time, and record what changes like any other answer.
3. **Self-review.** Fix inline: placeholders, sections that contradict each other, requirements with two readings (pick one and confirm it), acceptance criteria no test could check, a missing testing approach or test command. A gap or risk you notice here goes under Open questions and gets asked, one question at a time, before Gate 0. Never raise a new risk after approval.
4. **Gate 0.** Recap in 5 to 10 bullets: goal, scope and non-goals, key decisions with their memory IDs, the acceptance criteria, open risks (write "open risks: none" if there are none). Ask for approval, in a message of its own. An approval given before the user has seen the recap ("if it's done, I approve") only means: finish the steps above and show the recap. Commit only after a yes that comes after the recap. On approval: set `Status: approved`, commit spec and cycle memory as `<slug>: spec approved (gate 0)`, then invoke `project-plan`.

## Spec template

```markdown
# Spec: <slug>

Cycle: <slug> · Type: <project|feature> · Branch: <branch> · Status: draft

## Goal
## Users
## Scope and non-goals
## Behaviour
<!-- user-visible scenarios -->
## Data
## Constraints
## Architecture
## Acceptance criteria
- AC-01 · <observable behaviour>
## Testing approach
<!-- kinds of tests, what gets tested how -->
Test command: `<command that runs the whole suite>`
## Open questions
- <question>
```

A `feature` spec may drop Users, Data, Constraints and Architecture when they don't change. Acceptance criteria and Testing approach are never dropped. When Open questions is empty, write `- none`.

## Amend mode

For an approved spec the user wants to change, usually mid-build.

1. Set the plan INDEX Last stop to `amending spec: <gist>` before editing.
2. Ask what changes and why, one question at a time, until the change is clear.
3. Edit the affected sections. New acceptance criteria take the next free number; removed ones are struck through (`~~AC-04 · ...~~`), never renumbered.
4. Add a `## Amendments` section at the end if missing, and a line in it: `- <YYYY-MM-DD> · <what changed> · see <memory id>`.
5. Write a `pivot` entry in cycle memory. If the change reverses a project-memory entry, add an Overrides line too.
6. Light Gate 0: recap the change in 2 to 4 bullets and ask for OK. Set Last stop to `updating plan: <gist>`. Commit only `spec.md`, the plan INDEX and cycle memory as `<slug>: spec amended`; leave other uncommitted work alone.
7. Invoke `project-plan` in update mode, so the steps not started yet follow the change.
