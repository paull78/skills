---
name: project-plan
description: Turn an approved project-time spec into a plan that survives context resets, with milestones as vertical slices, one self-contained file per step with tests first and a verify command, explicit dependencies and parallel-safe groups, and a gate at every milestone. Also updates the plan after a pivot. Use when /project-time hands off to it, or the user wants to plan, re-plan or change the plan of the current cycle.
---

# Project Plan

Writes `docs/current/plan/`: an `INDEX.md` progress board and one file per step. A fresh session, or a sub-agent, must be able to pick up any step from its file alone.

Follow the conventions in the project-time block of `AGENTS.md`. If `docs/current/spec.md` is missing, invoke `project-time`.

**Modes.** No plan, or plan `Status: draft` → new plan. Plan `Status: approved` → update mode (last section).

**Precondition.** The spec should be `Status: approved`. If it isn't, say so and ask. If the user insists on planning anyway, write a `decision` entry recording that Gate 0 was skipped and why, and set the spec to `Status: approved`.

## 1. Read

The spec, the three memory indexes (general, project, cycle) and the area files relevant to the work at every level, general lessons included, and the codebase layout. If `plan/INDEX.md` exists as a draft, resume from it.

## 2. Milestone outline

Propose milestones as **vertical slices**: each ends with something working and testable end to end, never "the backend layer". The first milestone is a walking skeleton, the thinnest path through the whole system. For each milestone give its name, what works at its end, the acceptance criteria it covers, and its steps in one line each.

Ask for approval of the outline. Write no step files before it's approved. Once approved, write `plan/INDEX.md` with `Status: draft` so a reset doesn't lose the outline.

## 3. Steps

One file per step, `plan/step-NN-<name>.md`, from the step template.

- **Size.** Fits comfortably in one session and ends in one commit. Split anything bigger.
- **Tests first.** A step that adds logic or behaviour lists the tests to write before the code, concretely: test names and what each asserts.
- **Declared exceptions.** A step that can't be unit-tested (scaffolding, config, visual work) says so under Tests, with the reason, and still has a verify command: a build, a lint, the app booting, a page rendering.
- **Manual checks.** Anything that needs a human eye gets a `manual:` line under Done when. These are collected at the next gate.
- **Verify command.** Every step has one, runnable as is, with its expected result.
- **Needs.** Every step lists the steps it depends on, or `none`.
- **Parallel.** Mark two steps `∥` only if neither needs the other, directly or indirectly, and their Files touched lists share nothing, shared manifests, migration lists and route tables included. When in doubt, sequential.

## 4. Self-review

Fix inline before the gate:
- Every `AC-xx` in the spec maps to at least one step. Put the mapping in your recap.
- Every step has Tests (or a declared exception), a Verify command and Done when.
- Needs point only to existing steps, with no cycles.
- No placeholders, and no "handle edge cases" without saying which.

## 5. Gate 1

Recap: milestones with what works at the end of each, step count, parallel groups, manual checks, the AC mapping. Ask for approval and for the default execution mode, `sequential` or `parallel where possible`. Record the mode in the INDEX header, set `Status: approved`, commit as `<slug>: plan approved (gate 1)`, then invoke `project-build`.

## Templates

### plan/INDEX.md

```markdown
# Plan: <slug>

Status: draft · Mode: sequential · Test: `<the spec's test command>`
Current: step 01 (not started). Last stop: none.

## Milestone 1 · <name>  ⛔ gate pending
<what works at the end of this milestone>
- [ ] 01 <name>                (needs none)
- [ ] 02 <name>                (needs 01)
- [ ] 03 <name>                (needs 01)  ∥ 02

## Milestone 2 · <name>  ⛔ gate pending
<what works at the end of this milestone>
- [ ] 04 <name>                (needs 02, 03)

## Notes
```

Marks: `[ ]` todo, `[~]` in progress, `[x]` done, `[!]` blocked, followed by `→ <issue id>`. A passed gate reads `✅ gate passed <YYYY-MM-DD>` in place of `⛔ gate pending`. The last milestone's gate is `project-wrap`'s final gate.

### plan/step-NN-<name>.md

```markdown
# Step NN · <name>

**Milestone:** <n> · **Needs:** <steps or none> · **Covers:** <AC ids>

## Goal
<what exists after this step that didn't before>

## Files touched
- `<path>`: <what changes>

## Tests to write first
- `<test name>`: <what it asserts>

## Implementation notes
<approach, relevant memory IDs, pitfalls>

## Verify
`<command>` → <expected result>

## Done when
- <observable condition>
- manual: <what a human checks, only if needed>
```

For a declared exception, Tests to write first holds one line instead: `Exception: <why this step can't be unit-tested>`.

## Update mode

After a spec amendment, or a pivot found during the build:

1. Set the INDEX Last stop to `updating plan: <gist>` first.
2. Change only steps marked `[ ]`. Done and in-progress steps are never rewritten; if one needs rework, add a new step for it. An in-progress step may be narrowed to what's already done, with the rest moved to a new step. A `[ ]` step the change makes obsolete is removed from the INDEX and its file deleted, with the reason in the Notes line.
3. New steps take the next free number and sit in the INDEX in execution order, so the numbers in the list needn't be sequential.
4. Re-check dependencies and `∥` marks for everything touched, and redo the AC mapping. If the spec's `Test command:` changed, update `Test:` in the INDEX header.
5. Add a line under `## Notes`: `- <YYYY-MM-DD> · plan updated: <what changed> · see <memory id>`. Write a `pivot` entry if the amendment didn't already.
6. Show the user the change and ask for OK. Set Last stop to `plan updated: <gist>`. Commit only `docs/current/plan/` and cycle memory as `<slug>: plan updated`, then return to `project-build`.
