---
name: task-time
description: Break a PRD into independent, parallelizable task files. Each file is self-contained, uses TDD where appropriate, and can be executed without cross-file dependencies. Includes a final reconciliation task. Use when user wants to split a PRD into tasks, create implementation work units, or mentions "task-time".
---

# Task Time

Break a PRD into independent task files that can all be executed in parallel.

## Core Principle

**One task file = one independent unit of work.** All task files can run concurrently with no cross-file dependencies. If steps depend on each other, they belong in the same file. The only task that depends on all others is the final reconciliation task.

## Splitting Strategy

**Prefer vertical slices.** Each task should be a thin, complete path through all layers it touches (schema, logic, API, UI, tests) for one narrow capability — not a horizontal layer done in full.

**Validate independence with these checks:**
- **File exclusivity:** no two concurrent tasks write to the same file
- **Interface stability:** the task doesn't change contracts that other tasks depend on
- **Bounded scope:** you can state in one sentence which files/modules the task modifies

**Optional — tracer bullet task:** For larger PRDs, consider making task-01 a thin end-to-end skeleton that establishes interfaces and contracts. Subsequent tasks then build against those stable interfaces. Skip this for small/medium PRDs where it would be overhead.

## Input

Read the PRD from `plans/<project-name>.md`. If no PRD is specified, ask the user which one to use.

## Process

1. **Analyze the PRD.** Identify independent units of work. Group dependent steps into the same task file — never split dependent work across files.

2. **If a task file becomes too large,** notify the user but do not abort. Inside that file, split into clearly marked units of work (sessions), each with its own structure, tests, and acceptance criteria. This allows context to be reset or compacted between units.

3. **For each task, decide TDD applicability.** Use TDD when:
   - The task has clear input/output behavior
   - Tests can be written before implementation without being trivial
   - Do NOT force TDD for: configuration, wiring, UI layout, migrations, or tasks where tests would just mirror implementation
   - When using TDD, tests must be written BEFORE implementation and must initially fail. Never write tests designed to pass.

4. **Extract acceptance criteria** from the PRD and distribute to the relevant task files.

5. **Write task files** to `plans/<project-name>/task-<NN>-<short-name>.md`

6. **Write the final reconciliation task** as the last numbered file.

## Task File Template

Each task file must be self-contained — implementable by an agent with no prior context beyond what's in the file.

```md
# Task <NN>: <Title>

**PRD:** plans/<project-name>.md

## Objective

What this task accomplishes in 1-2 sentences.

## Acceptance Criteria

Extracted from the PRD — only the criteria relevant to this task.

- [ ] criterion 1
- [ ] criterion 2

## Scope

Files and modules this task may modify. (Optional — include for larger PRDs to prevent conflicts between parallel tasks.)

## Approach

Whether this task uses TDD or not, and why.

## Steps

Mark each step done as soon as completed.

- [ ] step 1
- [ ] step 2
- [ ] ...

## Sanity Checks

- [ ] Code compiles without errors
- [ ] All existing tests still pass
- [ ] New tests pass (if TDD)
- [ ] No unintended side effects on other modules

## Quick Test Quality Check

- [ ] Tests assert on behavior (outputs, side effects), not implementation details
- [ ] Tests cover at least one edge case or error path, not just the happy path
- [ ] A valid refactor would not break these tests
```

## Large Task File — Session Split

When a task is too large for a single session, split inside the file:

```md
## Unit 1: <Name>

### Acceptance Criteria
- [ ] ...

### Steps
- [ ] ...

### Tests
- [ ] ...

---

## Unit 2: <Name>

### Acceptance Criteria
- [ ] ...

### Steps
- [ ] ...

### Tests
- [ ] ...
```

Each unit is completable in one session. Context can be safely reset between units.

## Reconciliation Task (always last)

The final task file must:

1. Re-read the original PRD
2. Verify every acceptance criterion is met across all completed tasks
3. Run full test suite and confirm all pass
4. Check for consistency between modules built by different tasks
5. Flag any drift from the original PRD
6. Assess test coverage — both unit tests and E2E tests — and flag gaps
7. Produce a reconciliation report: what was delivered, what diverged, what's missing, coverage gaps
