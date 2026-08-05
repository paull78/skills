# Skills

Personal Claude Code skills collection.

## Install

```bash
npx @anthropic-ai/claude-code-skills install github:paull78/skills/<skill-name>
```

## Skills

### Process

| Skill | Description |
|-------|-------------|
| [question-time](./question-time) | Relentless Socratic interrogation of plans and designs. Inspired by [grill-me](https://github.com/mattpocock/skills/tree/main/grill-me) by [Matt Pocock](https://github.com/mattpocock). |
| [prd-time](./prd-time) | PRD creation with architecture selection, codebase exploration, and relentless questioning. Inspired by [write-a-prd](https://github.com/mattpocock/skills/tree/main/write-a-prd) by [Matt Pocock](https://github.com/mattpocock). |
| [task-time](./task-time) | Break a PRD into independent, parallelizable task files with TDD where appropriate and a final reconciliation task. |
| [test-time](./test-time) | Write or strengthen a test suite with aggressive bug-hunting — black-box via public APIs, guided fuzzing, invariants over fixed outputs, reference oracles, threshold corner cases, malformed inputs, stress testing. Derives expected results from the spec, never the running code. |
| [test-verify-time](./test-verify-time) | Full test quality assessment after all tasks complete — checks behavior focus, edge cases, pyramid balance, independence, and brittleness. |
| [instrument-time](./instrument-time) | Instrument code to gain eyes on its runtime behavior, then iterate against that real signal to fix the bug or hit the goal. For hard, multi-attempt problems — stubborn bugs, flaky tests, performance tuning — where editing blind wastes attempts. |
| [review-time](./review-time) | Multi-agent code review — dispatches diff to Claude, Codex, Copilot in parallel, aggregates findings with consensus scoring. |
| [comment-time](./comment-time) | Audit comments for necessity, brevity, non-triviality, clarity, accuracy, and rot. Scope: repo, branch diff, changed files, or current file. |
| [explain-time](./explain-time) | Write a top-down explanatory document about a system or subsystem for a reader who knows code but not the domain. Jargon defined inline, real walk-throughs, file:line citations, glossary. |
| [save-time](./save-time) | Write a markdown recap of the current conversation so the work can be resumed later. Captures decisions and their rationale, plans in flight, gotchas, pitfalls, and where things stand. Omits anything obvious from the code or git history. |
| [human-write-time](./human-write-time) | Write prose that doesn't read as AI-generated, and de-slop drafts that do. Hard-bans negative parallelism, dead AI vocabulary, em dashes, participle padding; loads an optional `VOICE.md` so the result sounds like the author rather than a house style. Ideas from [humanizer](https://github.com/blader/humanizer) by [blader](https://github.com/blader). |

### Architecture Knowledge

Composable lenses for challenging designs against established principles. Use standalone or loaded by question-time.

| Skill | Source |
|-------|--------|
| [knowledge-clean-architecture](./knowledge-clean-architecture) | Robert C. Martin — SOLID, dependency rule, component principles |
| [knowledge-simple-made-easy](./knowledge-simple-made-easy) | Rich Hickey — complecting, simplicity vs ease |
| [knowledge-design-of-design](./knowledge-design-of-design) | Fred Brooks — constraints, conceptual integrity, tradeoffs |
| [knowledge-pragmatic-programmer](./knowledge-pragmatic-programmer) | Hunt & Thomas — DRY, orthogonality, tracer bullets |
| [knowledge-fundamentals-of-sw-architecture](./knowledge-fundamentals-of-sw-architecture) | Richards & Ford — characteristics, topology, fitness functions |
| [knowledge-pattern-language](./knowledge-pattern-language) | Christopher Alexander — forces, wholeness, emergent order |
