---
name: test-verify-time
description: Assess test quality after implementation. Checks whether tests verify behavior (not implementation), evaluates edge case coverage, testing pyramid balance, test independence, and brittleness. Use when user wants to review test quality, validate tests after a task, or mentions "test-verify-time".
---

# Test Verify Time

Assess the quality of tests after implementation — not just whether they pass, but whether they're actually good.

## When to Use

- **After all tasks are complete** — as part of or right after reconciliation. This is the primary use case: a full assessment of the entire test suite across all implemented tasks.
- Anytime the user wants a standalone test quality review of a module or the full codebase.

Note: each individual task already includes a lightweight test quality check (behavior-focused, edge cases, refactor-safe). This skill is the thorough, cross-cutting review.

## Process

1. **Identify tests to review.** Either:
   - Tests created/modified in the current task
   - All tests in a specified module
   - Full test suite (if asked)

2. **Run the checks below.** Report findings grouped by severity (critical / warning / suggestion).

3. **Produce a short verdict:** pass, pass-with-warnings, or needs-attention.

## Quality Checks

### Behavior vs Implementation

- Do tests assert on observable outcomes (return values, side effects, state changes) or on internal mechanics (method calls, private state, execution order)?
- Would a valid refactor break these tests? If yes, they're testing implementation.
- **Critical** if tests would break on internal rename/restructure without behavior change.

### Edge Cases

- Are boundary conditions covered? (empty inputs, nulls, max values, off-by-one)
- Are error paths tested, not just happy paths?
- Are concurrent/async scenarios covered where relevant?
- **Warning** if only happy path is tested.

### Testing Pyramid Balance

- Is the ratio reasonable? Many unit tests, fewer integration, fewer E2E.
- Are expensive tests (E2E, browser) testing things that cheaper tests could cover?
- Are there missing integration tests at module boundaries?
- **Warning** if pyramid is inverted or a layer is missing entirely.

### Test Independence

- Can each test run in isolation, in any order?
- Do tests share mutable state (global variables, database rows, files)?
- Do tests clean up after themselves?
- **Critical** if tests depend on execution order.

### Brittleness

- Do tests rely on specific string formatting, timestamps, or random values?
- Do tests break when unrelated code changes?
- Are there excessive mocks that mirror implementation structure?
- **Warning** if mocks replicate the entire dependency graph.

### Clarity

- Can you understand what the test verifies from its name alone?
- Does a test failure message tell you what went wrong without reading the test body?
- Is each test focused on one assertion/behavior?
- **Suggestion** level — not blocking but improves maintainability.

## Output

```
## Test Quality Report

**Verdict:** [pass | pass-with-warnings | needs-attention]

### Critical
- [issues that must be fixed]

### Warnings
- [issues worth addressing]

### Suggestions
- [optional improvements]

### Summary
- Tests reviewed: N
- Behavior-focused: N/N
- Edge cases covered: [adequate | gaps in X]
- Pyramid balance: [healthy | top-heavy | missing layer]
- Independence: [clean | shared state in X]
```
