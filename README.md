# Skills

Personal skills for Claude Code and other coding agents.

An agent can solve a problem from several angles, and the job is to understand them and pick the one you can maintain. These skills help you keep control of the resulting code and steer the agent where you want.

Frontier agents can already do most of this when you ask. These skills write the behaviour down, so you don't have to ask every time, and a smaller, cheaper model gets the same instructions to follow.

## Install

Skills install with the [`skills`](https://github.com/vercel-labs/skills) CLI:

```bash
npx skills add paull78/skills --skill explain-time --global
```

Change the name to install any other skill, and drop `--global` to install into the current project only. To see what is available:

```bash
npx skills add paull78/skills --list
```

## The skills

### Understanding code

When you build with an agent the cycles are tight, and cycle after cycle the session's context fills up with implementation details. Little by little you lose the grasp of the code structure and the architecture, and asking the working agent to explain them spends the context it needs for the work.

| Skill | What it does |
|-------|--------------|
| [explain-time](./explain-time) | Takes those questions to a second chat in the same repo, read only on the code. It knows another agent is editing the same files, so a half-written function, or a test that fails because its code doesn't exist yet, doesn't confuse it. Ask it how the architecture fits together, how an algorithm works, what a feature does, or why you see a particular behaviour. It answers in simple terms, without acronyms, with a small diagram when it helps. When you want to keep an answer, it writes a short report to `~/.agents/explain/<repo>/`, outside the repo. |

### Testing and debugging

Make the agent look for bugs in its own work, and see what the code does when it runs.

| Skill | What it does |
|-------|--------------|
| [test-time](./test-time) | Writes or strengthens a test suite that goes looking for bugs: tests through the public API, random and malformed inputs, rules that must always hold, comparison with a reference implementation, corner cases at thresholds and stress runs. Expected results come from the spec, never from the running code. |
| [test-verify-time](./test-verify-time) | Judges a test suite after the implementation: whether the tests check behaviour, cover edge cases, stay independent and avoid brittleness, and whether the testing pyramid is balanced. |
| [instrument-time](./instrument-time) | For hard problems where editing blind wastes attempts, like stubborn bugs, flaky tests or performance tuning. It adds logs or traces to see what the code does at runtime, then iterates on what it sees until the bug is fixed or the goal is met. |

### Reviewing code

Check what the agent wrote before you merge.

| Skill | What it does |
|-------|--------------|
| [review-time](./review-time) | Sends the same diff to Claude, Codex and Copilot in parallel, then merges the findings into one report that shows who found what and how many agents agree. |
| [comment-time](./comment-time) | Checks that comments are necessary, brief, clear and accurate, that they say something the code doesn't, and that they aren't out of date. Runs on the whole repo, a branch diff, the changed files or a single file. |

### Writing and handing off

Keep your own voice in the text, and stop and resume the work when you want.

| Skill | What it does |
|-------|--------------|
| [human-write-time](./human-write-time) | Writes prose that doesn't read as AI-generated, and cleans up drafts that do. An optional `VOICE.md` makes the result sound like its author instead of a house style. Ideas from [humanizer](https://github.com/blader/humanizer) by [blader](https://github.com/blader). |
| [save-time](./save-time) | Writes a markdown recap of the conversation so the work can be resumed later: decisions and their reasons, plans in flight, gotchas, pitfalls and the current state. It leaves out what is obvious from the code or git history. |

### Design

Tell the agent how a canvas editor should behave.

| Skill | What it does |
|-------|--------------|
| [cad-ux-time](./cad-ux-time) | Interaction design for CAD, drawing and floor-plan editors in the browser, with 18 laws, starting numbers and four modes: design, build, review and audit. References cover tools and typed input, snapping, selection, navigation, refusals, collaboration and undo, panels, canvas accessibility and plan drawing conventions. Distilled from tldraw, Figma, AutoCAD, SketchUp, Onshape, NN/g and WCAG 2.2. Ideas from [ux-designer-skill](https://github.com/szilu/ux-designer-skill), [web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines), [Emil Kowalski's skills](https://github.com/emilkowalski/skills), [impeccable](https://github.com/pbakaus/impeccable) and [interface-design](https://github.com/Dammyjay93/interface-design). |

### Architecture lenses

You choose the principles and the agent tests a design against them. Use one or several on their own, or in the challenge round of [project-spec](https://github.com/paull78/project-time).

| Skill | Source | What it looks at |
|-------|--------|------------------|
| [knowledge-clean-architecture](./knowledge-clean-architecture) | Robert C. Martin | SOLID, the dependency rule, component principles |
| [knowledge-simple-made-easy](./knowledge-simple-made-easy) | Rich Hickey | Complecting, simplicity against ease |
| [knowledge-design-of-design](./knowledge-design-of-design) | Fred Brooks | Constraints, conceptual integrity, tradeoffs |
| [knowledge-pragmatic-programmer](./knowledge-pragmatic-programmer) | Hunt & Thomas | DRY, orthogonality, tracer bullets |
| [knowledge-fundamentals-of-sw-architecture](./knowledge-fundamentals-of-sw-architecture) | Richards & Ford | Characteristics, topology, fitness functions |
| [knowledge-pattern-language](./knowledge-pattern-language) | Christopher Alexander | Forces, wholeness, emergent order |
| [knowledge-hexagonal-architecture](./knowledge-hexagonal-architecture) | Alistair Cockburn & Juan Manuel Garrido de Paz | Ports, adapters, the configurator, test-first isolation. It goes deeper than the others, with reference files on pitfalls, transactions, queries and errors, per-language idioms, contract tests, boundary enforcement tools and legacy migration. |

## Project workflow

The project workflow skills (`project-time`, `project-spec`, `project-plan`, `project-build`, `project-wrap`) live in their own repo, **[paull78/project-time](https://github.com/paull78/project-time)**. They take a project or a feature through spec, plan, build and wrap, with gates you approve and three levels of memory that survive context resets.

```bash
npx skills add paull78/project-time --skill '*' --global
```
