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
| [test-verify-time](./test-verify-time) | Full test quality assessment after all tasks complete — checks behavior focus, edge cases, pyramid balance, independence, and brittleness. |
| [review-time](./review-time) | Multi-agent code review — dispatches diff to Claude, Codex, Copilot in parallel, aggregates findings with consensus scoring. |
| [comment-time](./comment-time) | Audit comments for necessity, brevity, non-triviality, clarity, accuracy, and rot. Scope: repo, branch diff, changed files, or current file. |
| [explain-time](./explain-time) | Write a top-down explanatory document about a system or subsystem for a reader who knows code but not the domain. Jargon defined inline, real walk-throughs, file:line citations, glossary. |

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
