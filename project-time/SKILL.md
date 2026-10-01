---
name: project-time
description: Entry point for the project workflow. Sets up the docs folder and standing memory rules on first run, then reads the state on disk and continues the active cycle (spec, plan, build, or wrap) for a new project or a feature. Use when the user types /project-time, wants to start a new project or feature with a spec and a tracked plan, or says continue, resume, or what's next on the project.
---

# Project Time

The front door of the project workflow. It makes sure the repo is set up, then hands off to the phase skill that owns the current state. It never does a phase's work itself.

Every piece of work is a **cycle**: the first build of a new project, or a feature. A cycle lives in `docs/current/` on its own branch and goes spec → plan → build → wrap, with a gate at each main point. Decisions, discoveries, pivots, issues and pins go into a hierarchical memory. The files on disk are the source of truth, so any session resumes by running `/project-time`.

| Phase skill | Owns |
|---|---|
| `project-spec` | the interview, `docs/current/spec.md`, Gate 0, spec amendments |
| `project-plan` | `docs/current/plan/`, Gate 1, plan updates |
| `project-build` | steps, progress, milestone gates, parallel runs |
| `project-wrap` | final gate, recap, memory consolidation, lessons, archive |

## 1. Setup check

Run on every invocation. Each check is cheap; write only what is missing or outdated.

1. **Git.** `git rev-parse --is-inside-work-tree`. Not a repo: offer `git init`. If the user declines, carry on and skip every commit in the workflow.
2. **AGENTS.md block.** Look for `<!-- project-time:start v2 -->` … `<!-- project-time:end -->`.
   - No block: append the block from the Templates section, creating `AGENTS.md` if needed.
   - Older version marker, or text that differs from the template: replace everything between the markers, markers included.
   - Identical: leave it alone.
3. **CLAUDE.md import.** Claude Code ignores `AGENTS.md` when a `CLAUDE.md` exists, so `CLAUDE.md` must import it. No file: create it containing `@AGENTS.md`. File without an `@AGENTS.md` line: append one.
4. **Project memory.** Create `docs/memory/INDEX.md` and `docs/memory/overview.md` from the templates if missing. Leave any other `docs/` content alone. If one of these paths exists but isn't ours, ask; never overwrite.

If anything was written, commit only those files as `project-time: setup`.

## 2. Route

Read the `Status:` field in the headers of `docs/current/spec.md` and `docs/current/plan/INDEX.md`, and the current branch.

| State | Action |
|---|---|
| No `docs/current/` | Start a new cycle (section 3) |
| Spec `Status: draft` | Invoke `project-spec` |
| Spec `approved`, plan missing or `Status: draft` | Invoke `project-plan` |
| Plan `approved`, any step not `[x]` | Invoke `project-build` |
| Every step `[x]`, or `Current:` starts with `wrap` | Invoke `project-wrap` |

Before routing, compare the spec header's `Branch:` with the current branch. If they differ, stop and explain: either the user switched branches, or a branch was merged without wrapping. Ask how to proceed, and offer to wrap the cycle here.

If the user asks for something specific, route to its owner instead: "reopen" or "change the spec" → `project-spec` (amend mode); "change the plan" → `project-plan` (update mode); "a recap", "where do we stand" → `project-wrap` (interim recap).

**Hand off by invoking the phase skill with the Skill tool, not by reading its file.** In Claude Code an invoked skill survives context compaction; a file read doesn't. In agents without a Skill tool (Codex and others), read the phase skill's `SKILL.md`, from the folder next to this skill's, and follow it. Pass one line of context: the cycle slug and the state you found.

## 3. Start a new cycle

1. **Slug.** Ask for a short kebab-case name, or propose one from the user's message. It prefixes memory IDs and commit messages, so keep it short. It must not match a slug under `docs/archive/` or an ID prefix in `docs/memory/`.
2. **Type.** Infer it, don't ask. The repo is **blank** when `docs/archive/` is missing or empty and `git ls-files` lists nothing outside `docs/`, `AGENTS.md`, `CLAUDE.md`, `README*`, `LICENSE*` and dotfiles.
   - Blank → `project`. Not blank → `feature`.
   - State it in one line and carry on: "Starting feature cycle `import`. Say so if this is a project-level rewrite." A user override to `project` in a non-blank repo means a rewrite: a full-depth spec that still reads existing memory and code.
3. **Branch.** If the repo is not blank and you're on the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `main` or `master`), offer `git switch -c feature/<slug>`. A blank repo's first cycle may stay where it is. One active cycle per branch.
4. **Skeleton.** Create `docs/current/spec.md` and `docs/current/memory/INDEX.md` from the templates. Commit as `<slug>: start cycle`.
5. Invoke `project-spec`.

## Templates

### AGENTS.md block (v2)

```markdown
<!-- project-time:start v2 -->
## Project workflow (project-time)

This repo runs the project-time workflow. Its state lives in `docs/`: the files are the source of truth, the conversation is scratch.

- `docs/memory/`: project memory. Read it; setup creates it and only `project-wrap` changes it.
- `docs/current/`: the active cycle on this branch. `spec.md`, `plan/INDEX.md` with `plan/step-NN-*.md`, and `memory/` (cycle memory).
- `docs/archive/<date>-<slug>/`: finished cycles.

**Session start.** Read `docs/memory/INDEX.md`. If `docs/current/` exists, also read `docs/current/memory/INDEX.md` and `docs/current/plan/INDEX.md`. Open area files only when they relate to the work at hand.

**Memory.** Record in `docs/current/memory/` as soon as it happens, before moving on:
- a decision (with the why and the rejected options), a discovery, a pivot, an issue;
- anything the user asks to pin or remember: a one-liner under `## Pinned` in the cycle memory INDEX, as `- <slug>.<NN> · <the rule>`. With no active cycle, a pin waits for the next cycle: say so.

Entries go in area files by topic, each area listed in one line in the INDEX:

    ### <slug>.<NN> · <decision|discovery|pivot|issue> · <YYYY-MM-DD> · <phase or step>
    <the fact>
    **Why:** <reason; rejected options>

NN is the highest number in the cycle plus one, pins included. Never delete an entry. A pivot adds a new entry marked `Supersedes <id>` and appends `Superseded by <id>` to the old one. If the old one is in project memory, add `- <old> → <new> · <one line>` under `## Overrides` in the cycle INDEX instead. Cycle memory wins over project memory while the cycle is active. Pins from both indexes apply.

**Commits.** The workflow commits at setup, cycle start, gates, each finished build step, spec amendments, plan updates, parallel-run start and record, interim recaps, and wrap, each with only the files that step touched. Messages start with `<slug>:` or `<slug> step NN:`. Never push, and never merge a feature branch into the default branch.

**Sub-agents** never write under `docs/`. They report back; the main agent records.

**To continue work,** run `/project-time`.
<!-- project-time:end -->
```

### docs/memory/INDEX.md

```markdown
# Memory: project

Durable project memory. Changed only when a cycle wraps.

## Pinned

## Areas
- overview.md · what the system is, its main parts, where things live
```

### docs/memory/overview.md

```markdown
# Overview

What the system is, its main parts and where they live, how to run and test it. Rewritten at every wrap; empty until the first cycle wraps.
```

### docs/current/spec.md

```markdown
# Spec: <slug>

Cycle: <slug> · Type: <project|feature> · Branch: <branch> · Status: draft

## Open questions
- Everything: the interview has not started.
```

### docs/current/memory/INDEX.md

```markdown
# Memory: <slug> (cycle)

## Pinned

## Overrides

## Areas
```
