# Project workflow skills: design

Date: 2026-09-29
Status: draft, awaiting review

## Goal

A set of skills that runs a development cycle from first question to final recap, for a new project or for a single feature in an existing one:

1. Setup: a standard docs folder and standing instructions every session sees.
2. Spec: an interview, one question at a time, until the user says the spec is done.
3. Plan: milestones and steps, trackable across context resets, verified by tests, gated at the main points, parallel where the project allows it and the user wants it.
4. Build: step by step, with progress marked on disk so work resumes cleanly after `/clear`, compaction or a new session.
5. Wrap: a recap and takeaways distilled from memory.

Throughout all phases the agent keeps a hierarchical memory: decisions, discoveries, pivots, issues, and anything the user asks to pin down.

The user normally types one command, `/project-time`, and the workflow works out where it is.

## Decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Standalone suite, borrowing ideas from `prd-time`, `task-time` and `save-time` but not calling them | One shared state model (docs folder, memory, progress). Skills unaware of it would drift from it. |
| 2 | Router skill plus four phase skills, each its own folder with a `project-` prefix | Claude Code re-injects the body of an invoked skill after compaction (up to about 5k tokens per skill), but not reference files the skill told the agent to read. Separate skills keep each phase's rules alive through long sessions. |
| 3 | Plain skill folders, not a plugin | Matches the repo, installs with `npx skills` into several agents. Of the plugin extras only a custom step-worker agent would help, and a fixed sub-agent prompt covers it. Can be wrapped in a plugin later without rewriting. |
| 4 | Standing rules live in a versioned block in the project's `AGENTS.md`; `CLAUDE.md` imports it with `@AGENTS.md` | Always loaded in every session and re-read after compaction, so memory rules apply even when no skill is loaded. Claude Code ignores `AGENTS.md` when a `CLAUDE.md` exists, hence the import. Other agents read `AGENTS.md` natively. |
| 5 | No `SessionStart` hook | The router reads state as its first step anyway; the `AGENTS.md` rule covers ad-hoc sessions. A hook adds per-project machinery for a marginal gain. Revisit if agents skip the memory read in practice. |
| 6 | Memory is a lean index plus area files opened on demand; entries carry a type tag | Reading by area matches how work happens ("what did we decide about auth"); type tags keep "all pivots" a grep away. |
| 7 | Pinned items live in the memory index itself | Things the user wants pinned must be in context every session, not one file away. |
| 8 | Pivots supersede, never delete | The history of changed minds is what the recap needs. |
| 9 | Plan is a folder: `INDEX.md` progress board plus one self-contained file per step | Same index-and-detail pattern as memory; a parallel sub-agent can pick up a step file cold. |
| 10 | Spec interview elicits by default, with an optional challenge round before Gate 0 | Keeps the interview moving; the challenge pass (optionally through `knowledge-*` lenses) is there when the stakes justify it. |
| 11 | Tests first by default; declared exceptions still need a verify command; human-only checks are flagged `manual` and collected at the next gate | Discipline where it pays, no test theatre for scaffolding or visual work. |
| 12 | One build run goes until the next gate or a blocker | Milestone gates are the pause points; the user can still ask for "one step" or "stop after 04". |
| 13 | Auto-commit per step, never push | Clean rollback per step, straightforward parallel merges. Adopting the workflow is standing permission, stated in the `AGENTS.md` block. |
| 14 | Everything is a cycle; one active cycle per branch, in `docs/current/` | A new project is the first cycle, a feature is a later one. Same skills, spec depth scales with type. Separate branches keep parallel features apart. |
| 15 | Two-level memory: cycle memory is written during work, consolidated into project memory at wrap | Parallel branches never write the same files, so no merge conflicts; consolidation is where takeaways get distilled. |
| 16 | Wrap happens on the branch, before merge | The archive and the memory consolidation land in the branch diff and get reviewed with the PR; `main` never carries a `docs/current/`. |
| 17 | Cross-project lessons go to `~/.claude/project-lessons.md`, one user approval per lesson | Lessons about the user or their tools outlive the project. Claude's own auto-memory is scoped per directory, so it can't carry them. |
| 18 | `docs/memory/overview.md` is updated at every wrap | Once the first spec is archived, something live has to describe the system as a whole for the next feature's spec. |
| 19 | Cycle type is inferred, not asked: `project` when the repo is blank (no archive, no tracked files outside `docs/`, `AGENTS.md`, `CLAUDE.md`, `README*`, `LICENSE*` and dotfiles), `feature` otherwise. The router states it and the user can override | Saves a question in the common case. Looking at the code, not only at memory, keeps an existing codebase that adopts the workflow from being mistaken for a new project. The override covers a large rewrite, which needs a project-depth spec. |

## Skills

| Skill | Role | Hands off to |
|---|---|---|
| `project-time` | Entry point: setup on first run, then reads state and invokes the right phase skill | any phase |
| `project-spec` | Interview into `docs/current/spec.md`, challenge round, Gate 0. Also amend mode during build | `project-plan` |
| `project-plan` | Spec into `docs/current/plan/`, milestone outline checkpoint, Gate 1 | `project-build` |
| `project-build` | Runs steps test-first, marks progress, writes memory, commits, stops at gates. Orchestrates parallel groups | `project-wrap` when all steps are done |
| `project-wrap` | Final gate, recap, memory consolidation, lessons promotion, archive | none |

Each phase skill checks that setup has happened; if not, it hands off to `project-time`. Each `SKILL.md` stays under about 5k tokens so it is re-injected whole after compaction. Shared conventions are not copied into the skills: they live in the `AGENTS.md` block, and every skill refers to it.

## Layout

```
AGENTS.md                      project-time block between versioned markers
CLAUDE.md                      contains @AGENTS.md
docs/
  memory/                      project memory, durable, written only at wrap
    INDEX.md                   pinned rules + one line per area file
    overview.md                what the system is, main parts, where things live
    <area>.md
  current/                     the active cycle on this branch; absent when none
    spec.md
    plan/
      INDEX.md                 progress board
      step-NN-<name>.md
    memory/                    cycle memory, the working log
      INDEX.md                 pinned (cycle-scoped) + overrides + one line per area
      <area>.md
    recap.md                   written at wrap, archived with the rest
  archive/
    <YYYY-MM-DD>-<slug>/       wrapped cycles: spec, plan, cycle memory, recap
~/.claude/project-lessons.md   global, cross-project lessons
```

Archive folders are named by date and slug, not by number, because numbers would collide across parallel branches.

## The AGENTS.md block

Written by setup between `<!-- project-time:start v1 -->` and `<!-- project-time:end -->`. Every `/project-time` run checks the marker: missing means write it, mangled means repair it, older version means upgrade it. About 30 lines covering:

- The docs layout above, in brief.
- At session start: read `docs/memory/INDEX.md`, and if `docs/current/` exists, `docs/current/memory/INDEX.md` and `docs/current/plan/INDEX.md`.
- Memory rules: when to write, entry format, ID scheme, supersede instead of delete, cycle overrides project, pins go straight to the index.
- "Pin this" or "remember this" from the user creates a pinned entry immediately.
- Write memory only to `docs/current/memory/`. Project memory changes only at wrap.
- Commit policy: one commit per finished step, never push.
- Sub-agents never write under `docs/`.
- To continue work, run `/project-time`.

## Memory

**Levels.** Global lessons, project memory, cycle memory. During a cycle the agent reads project and cycle memory and writes only cycle memory.

**Read order.** At session start: both indexes. On demand: area files from either level that relate to the work at hand. When the two disagree, the cycle wins while it is active. Global lessons are read by `project-spec` and `project-plan` only.

**Index format.** Each index holds three things, and nothing else:

```markdown
# Memory: import (cycle)

## Pinned
- import.02 · All amounts are integer cents, never floats.

## Overrides
- init.12 → import.04 · PDF parsing moves from pdf.js to a server-side parser.

## Areas
- parsing.md · PDF and CSV readers, edge cases found
- data-model.md · invoice tables, migrations
```

The project index has Pinned and Areas; Overrides only exists in cycle indexes.

**Entry format.**

```markdown
### import.07 · decision · 2026-09-29 · step 04
Scanned PDFs are rejected with a clear error, not OCR'd.
**Why:** OCR would add a heavy dependency, and the spec lists scanned input as a non-goal. Rejected: tesseract.js.
```

- Types: `decision`, `discovery`, `pivot`, `issue`, `pinned`. Pinned entries are one-liners that live directly in the index's Pinned section, not in area files.
- IDs are `<cycle-slug>.<NN>`, unique across branches without a shared counter. The next number is the highest existing one in the cycle plus one.
- A pivot adds a new entry with `Supersedes <id>` and edits the old one to add `Superseded by <id>`. If the old entry is in project memory, the cycle index gets an Overrides line instead, and the edit to project memory waits for wrap.
- Rejected options and the reasons go in the entry. The spec records what was decided; memory records why.

**Hygiene.** Indexes stay lean: few pins, one line per area. An area file past about 200 lines gets split and the index updated. Each gate's memory sweep checks this.

## Cycles and branches

- `docs/current/` absent: the router starts a new cycle. It asks for a short name (the slug) and infers the type: `project` if the repo is blank (`docs/archive/` empty or missing, and `git ls-files` shows nothing outside `docs/`, `AGENTS.md`, `CLAUDE.md`, `README*`, `LICENSE*` and dotfiles), `feature` otherwise. It states the inferred type in one line ("Starting feature cycle `import`; say so if this is a project-level rewrite") and moves on unless the user overrides.
- If the repo is not blank and the current branch is the default branch, the router offers to create `feature/<slug>`, whatever the type. A blank repo's first cycle may stay on the default branch.
- Whatever the type, the first wrap in a repo creates project memory and `overview.md`; later wraps update them.
- The spec header records the cycle: `Cycle: import · Type: feature · Branch: feature/import · Status: draft`.
- Only one cycle can be active per branch. Two features in progress means two branches or worktrees.
- If the router or build finds `docs/current/` on the default branch after a feature cycle's branch was merged unwrapped, it warns and offers to wrap it there.

**Project vs feature.** Same skills, same plan and build loop, same gates. The type only tunes these:

| | `project` | `feature` |
|---|---|---|
| Typical case | First cycle in a repo, or a large rewrite (override) | Any later cycle that adds to or changes what exists |
| Starting knowledge | Blank repo, empty memory (a rewrite reads existing memory and code) | Project memory, `overview.md` and the codebase are read before the first question |
| Spec depth | Full: every section, the whole decision tree | Lighter: goal, affected areas, behaviour, AC, testing, non-goals; skips what project memory already settles |
| At wrap | Consolidation creates project memory and `overview.md` (for a rewrite, reworks them) | Consolidation updates them and applies overrides |

A feature can still change a project-level rule; it does it through an override and a pivot entry that wrap applies to project memory.

## project-time (router)

**Setup** (first run in a repo):
1. No git repo: offer `git init`. If declined, the workflow still runs and commit steps are skipped.
2. Create `docs/memory/INDEX.md` and `docs/memory/overview.md` if missing. Existing `docs/` content is left alone; if one of our paths already exists as something else, ask, never overwrite.
3. Write the `AGENTS.md` block (append to an existing `AGENTS.md`). Make sure `CLAUDE.md` exists and contains `@AGENTS.md`.
4. Commit the setup.

**Routing**, by reading status headers:

| State | Action |
|---|---|
| Setup missing | Setup, then start a new cycle |
| No `docs/current/` | Start a new cycle, then `project-spec` |
| Spec missing or `Status: draft` | `project-spec` (resumes from open questions) |
| Spec `approved`, plan missing or `draft` | `project-plan` |
| Plan `approved`, steps left | `project-build` |
| All steps done, no recap | `project-wrap` |

The router invokes the phase skill with the Skill tool rather than reading its file, so the phase counts as invoked and survives compaction.

## project-spec

1. The user describes the project or feature. For a feature, or any cycle in a repo with code, the agent reads `docs/memory/overview.md` and explores the codebase first, so it does not ask what the repo already answers. It also reads global lessons.
2. The interview: one question per message, multiple choice where possible, recommendation first. It walks the decision tree branch by branch: purpose, users, scope and non-goals, behaviour, data, constraints, architecture, testing approach. Feature cycles skip what project memory already settles.
3. `docs/current/spec.md` is created after the first answer and updated after every resolved question, with an Open questions section at the bottom. A reset mid-interview resumes from the open questions.
4. Each resolved question with a real choice behind it gets a memory entry with the why and the rejected options.
5. When the agent thinks the tree is covered, it says so and lists anything still open. The user keeps going or says done.
6. It offers an optional challenge round, with the user's choice of installed `knowledge-*` lenses.
7. Self-review: placeholders, contradictions, ambiguity. Then Gate 0: a recap of the spec and the user's approval. Status becomes `approved`.

**Spec sections:** Goal, Users, Scope and non-goals, Behaviour (user-visible scenarios), Data, Constraints, Architecture, Acceptance criteria (`AC-01`...), Testing approach, Open questions. Feature specs may drop sections that don't apply; acceptance criteria and testing approach are never dropped.

**Amend mode.** Invoked during build when the user wants to change the spec. It edits the spec, notes the amendment in the header, writes a `pivot` entry, then hands off to `project-plan` to update affected steps that haven't started. Gate 0 is re-confirmed lightly: one recap of the change and the user's OK.

## project-plan

1. Read the spec, both memory indexes and global lessons.
2. Propose the milestone outline as vertical slices: each milestone ends with something working and testable end to end. The user approves the outline before any step file is written.
3. Write the step files and the index.
4. Self-review: every `AC-xx` maps to at least one step; every step has a verify command; no placeholders. Then Gate 1: the user approves the plan and chooses the default execution mode (sequential, or parallel where possible), recorded in the index header. Status becomes `approved`.

**Plan index:**

```markdown
# Plan: import
Status: approved · Mode: parallel where possible
Current: step 04 (in progress). Last stop: parser done, edge-case tests pending.

## Milestone 1 · Core data  ✅ gate passed 2026-09-30
- [x] 01 scaffold
- [x] 02 data model            (needs 01)
## Milestone 2 · Import  ⛔ gate pending
- [x] 03 CSV reader            (needs 02)  ∥ 04
- [~] 04 PDF parser            (needs 02)  ∥ 03
- [ ] 05 import UI             (needs 03, 04)
```

Status marks: `[ ]` todo, `[~]` in progress, `[x]` done, `[!]` blocked (with a pointer to the issue entry).

**Step file sections:** Goal, Acceptance criteria covered, Needs, Files touched, Tests to write first (or the declared exception and why), Implementation notes, Verify command, Done when. A step should fit comfortably in one session and end in one commit.

**Parallel marks.** Dependencies are always recorded. Two steps get `∥` only if neither needs the other and their "Files touched" lists don't overlap.

**Gates.** Every milestone ends in one. The user can ask for extra gates anywhere.

**Changing the plan during build.** Only steps not yet started get edited. Each change gets a `pivot` entry and a note in the index. Finished steps are never rewritten.

## project-build

**Resume.** Read the plan index and both memory indexes. Then reconcile three sources: the index, `git log` (the last step commit for this cycle), and the working tree.
- Index says `[~] 04` but a step 04 commit exists: the reset hit between commit and index update. Fix the index, continue.
- Uncommitted changes: mid-step work. Read Last stop, run the tests to see where things stand, continue. Uncommitted work is never discarded.
- Anything else that doesn't reconcile: stop, show the mismatch, ask.

**Per step:**
1. Mark `[~]`, update `Current:`. On disk before work starts.
2. Read the step file and the memory area files it relates to.
3. Tests first, watch them fail, implement until green, refactor. Declared exceptions run the verify command instead.
4. Run the verify command and show the real output.
5. Memory checkpoint, mandatory: anything decided, discovered, pivoted, pinned, or an issue? Write the entries. "Nothing new" is a valid answer but must be given explicitly.
6. Mark `[x]`, advance `Current:`, commit code, plan and memory together: `import step 04: PDF parser (AC-03, AC-04)`.

When pausing mid-step, or after notable progress inside a long step, update the Last stop line.

**Run length.** Continues through the milestone's steps and stops at the gate, or earlier on a blocker. The user can ask for one step, or to stop after a given step.

**Gate.** Every milestone except the last: the last one's checks are run by `project-wrap`'s final gate, so the user never gets two identical gates back to back. Full test suite, the milestone's acceptance criteria checked, `manual` items listed for the user, memory sweep (anything unrecorded since the last gate? any index or area file due for a split?), a short recap, and the user's go-ahead. The index records the gate as passed with the date.

**Parallel mode.** When the next steps form a `∥` group and the mode allows it, build becomes an orchestrator:
- Each step goes to a sub-agent in its own git worktree, with a fixed prompt: the step file, the conventions, and the report format.
- Sub-agents never touch `docs/`. They report the result, the verify output and memory candidates.
- The orchestrator merges the worktrees, runs the full suite, writes the memory entries and updates the index. One writer for the shared state.
- A failed sub-agent gets its step marked `[!]` with an issue entry; the others merge. A non-trivial merge conflict sends that step back to sequential.

**Failures.** A verify command that keeps failing after a few honest attempts: mark `[!]`, write an `issue` entry, stop and report, and suggest `instrument-time` or systematic debugging instead of more guessing.

**Out of order.** Invoked with a draft spec or plan: warn and ask. If the user insists, proceed and record a `decision` entry that the gate was skipped and why.

## project-wrap

1. **Final gate.** Full suite green, every `AC-xx` checked against the spec, `manual` items confirmed by the user. For a feature, first rebase onto the target branch so consolidation merges into the latest project memory.
2. **Recap**, into `docs/current/recap.md`, built from memory and plan rather than from the chat:
   - What was built, against the spec, with deviations and why.
   - How it went: milestones with dates, and the pivot chain (what we believed, what changed our mind, what we did).
   - Decisions that stand, current ones only, each with its reason.
   - Discoveries, open issues, known limitations.
   - Takeaways: what worked, what to do differently.
   Follows `human-write-time` and the user's `VOICE.md` when installed.
3. **Consolidate** cycle memory into project memory: decisions that still stand, discoveries that matter beyond this cycle, overrides applied to the project entries they supersede, cycle pins the user marks as project-wide. Update `overview.md`. Feature-local detail stays in the archive.
4. **Promote lessons.** Propose the takeaways that look cross-project; append the ones the user approves to `~/.claude/project-lessons.md`, one line each with project and date, same lean-index style.
5. **Archive.** Move `docs/current/` to `docs/archive/<YYYY-MM-DD>-<slug>/` and commit.

Can also run as an interim recap mid-cycle, which writes the recap only and skips steps 3 to 5.

## Constraints

- Each `SKILL.md` under about 5k tokens.
- Descriptions are single-line plain YAML scalars with no `: ` and no ` #`, or the `npx skills` installer drops the skill.
- README gets a "Project workflow" section with a one-line install for all five skills.

## Verification

The trigger-rate optimizer under-measures process skills, so verification is by scenario runs in a scratch repo on a toy project (a small CLI):

1. Setup creates the skeleton and the block; a second run changes nothing.
2. Interrupt the spec interview, `/clear`, `/project-time`: resumes from open questions.
3. Reset mid-step with a dirty tree: resumes from Last stop, no work lost.
4. Build stops at the milestone gate with a proper recap.
5. A parallel group runs in worktrees; sub-agents leave `docs/` untouched; the orchestrator writes memory.
6. A pivot produces a supersede pair (or an override line), an edited plan step and an index note.
7. `/compact` mid-build: continues correctly.
8. Wrap produces the recap, consolidates memory, proposes lessons and archives.
9. A second cycle: type inferred as `feature`, offers the branch, reads project memory and overview, writes only cycle memory. Overriding to `project` gives a full-depth spec that still reads existing memory.
10. Two feature branches in parallel, both wrapped and merged: no conflicts under `docs/`.

Static checks: token size of each `SKILL.md`, YAML parse of each frontmatter.

## Build order

`project-time` and the `AGENTS.md` block first, since they define the conventions. Then `project-spec`, `project-plan`, `project-build`, `project-wrap`, each scenario-tested before the next.

## Out of scope

- `SessionStart` hook (decision 5).
- Plugin packaging (decision 3).
- Several active cycles on one branch.
- A custom step-worker agent definition.
