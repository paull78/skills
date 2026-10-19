---
name: project-build
description: Execute the current project-time plan step by step, tests first, verified with real output, recording memory, marking progress on disk and committing each step, stopping at milestone gates, resuming cleanly after a context reset, and running parallel steps in git worktrees when the plan allows. Use when /project-time hands off to it, or the user wants to continue building, resume after a reset, run the next step, or run a gate.
---

# Project Build

Works through `docs/current/plan/` one step at a time. The disk is the source of truth: progress is written before and after every step, so a reset at any moment loses at most the conversation.

Follow the conventions in the project-time block of `AGENTS.md`. If the plan is missing, invoke `project-time`.

**Precondition.** The plan should be `Status: approved`. If it isn't, say so and ask. If the user insists, write a `decision` entry recording that Gate 1 was skipped and why, and set the plan to `Status: approved`.

## 1. Resume

Read `plan/INDEX.md` and the three memory indexes (general, project, cycle) with their pinned items. Compare the spec's `Branch:` with the current branch; if they differ, invoke `project-time`. Then reconcile three sources:

- the **INDEX**: `Current:`, the marks, Last stop;
- **git log**: `git log --oneline --grep '^<slug> step [0-9]'`;
- the **working tree**: `git status --porcelain`.

| Finding | Do |
|---|---|
| All three agree | Continue |
| A single step `[~]`, no parallel run in progress: INDEX says `[~] NN` but a `<slug> step NN` commit exists | The reset hit between commit and INDEX update. Mark NN `[x]`, advance `Current:`, commit the INDEX as `<slug>: progress fixed after reset`, continue |
| Several steps `[~]` at once, or agent worktrees in `git worktree list` other than those Last stop names as kept | An interrupted parallel run. For each step, check whether its branch is merged; rebuild its memory candidates from the diff and commit message before marking `[x]`. Never mark `[x]` without recording memory |
| `Current: gate M<n> (pending)` | The gate was interrupted or awaits the go-ahead. Run section 4 from the start |
| Last stop starts with "amending spec" or "updating plan" | Invoke `project-spec` (amend mode) or `project-plan` (update mode) to finish it |
| Uncommitted changes | Mid-step work. Read Last stop, run the step's tests to see where it stands, continue the step. **Never discard uncommitted work** |
| Anything else that doesn't line up | Stop. Show the mismatch and ask |

## 2. Run length

Run step after step through the current milestone and stop at its gate, or earlier on a blocker. If the user asked for one step, or to stop after a given step, do that instead. The user can ask for an extra gate at any point; run section 4 there.

## 3. Each step

1. **Start.** Mark the step `[~]` and set `Current: step NN (in progress). Last stop: starting.` Save it before touching code.
2. **Read** the step file and the memory area files it relates to.
3. **Tests first.** Write the tests the step lists. Run them and see them fail for the expected reason. Implement until they pass. Refactor with the tests green. A step with a declared exception skips this and relies on its verify command. If a listed test passes before any implementation, don't skip past it: make sure it can fail (stage the implementation, or briefly break the code path) and record a `discovery` entry saying which tests were born green and why.
4. **Verify.** Run the step's verify command and quote its last few lines verbatim in your message, in a code block: a tool call alone isn't showing it. Then run each non-`manual:` line under Done when. Never report "should pass".
5. **Memory checkpoint.** Was anything decided, discovered, pivoted or pinned during this step, or did an issue come up? Write each as an entry. Then always tell the user in one line: `Memory: nothing new`, or `Memory: <id> (<type>) <gist>; ...`.
6. **Finish.** Mark `[x]`, advance `Current:` to the next step in INDEX order whose needs are done, or to `gate M<n> (pending)` if this was the milestone's last step, or to `wrap` if it was the plan's last step, and commit code, plan and memory together as `<slug> step NN: <name> (<AC ids>)`.

When pausing mid-step, or after a milestone inside a long step, update Last stop with one concrete line: what's done, what's next.

## 4. Gate

At the end of each milestone except the last one. Call it the Milestone N gate.

1. Run the full test command from the INDEX header and quote its summary lines verbatim.
2. Check each acceptance criterion this milestone covers against the running code, with an input that would fail if the criterion were broken. Show the command and its output for each one, or name the test that covers it.
3. List every `manual:` item from the milestone's steps for the user to check.
4. **Memory sweep.** Anything decided or learned since the last gate that isn't recorded? An index getting long, or an area file past about 200 lines? Split it and update the index.
5. Recap in a few bullets: what works now, deviations from the plan, memory entries added, the memory sweep result (even "nothing unrecorded"), open issues.
6. Wait for the user's go-ahead. On approval, mark the milestone `✅ gate passed <YYYY-MM-DD>`, advance `Current:` to the next milestone's first step, and commit as `<slug>: gate M<n> passed`.

The last milestone has no gate here: when its last step is done, set `Current: wrap` and invoke `project-wrap`. Its final gate runs the same checks for the whole cycle.

## 5. Parallel mode

When the INDEX mode is `parallel where possible` and the next steps are marked `∥` with all their needs done, orchestrate instead of doing them yourself. If the user asked for sequential this time, or sub-agents with worktree isolation aren't available, run them one by one.

1. Mark each step in the group `[~]`, set `Current: steps NN, MM (parallel, in progress)`, and commit the INDEX as `<slug>: start steps NN, MM (parallel)`.
2. Dispatch one sub-agent per step, each in its own git worktree (the Agent tool with worktree isolation), all in one message, with the prompt below.
3. When all have reported, merge each finished branch in step order. Resolve a trivial conflict. For a non-trivial one, abort that merge, remove its worktree and branch, set the step back to `[ ]` with a note in Last stop, and run it sequentially afterwards.
4. Run the full test command on the merged result.
5. Record memory from each report's candidates, after checking they hold. Mark done steps `[x]` and blocked ones `[!]` with an issue entry. Commit as `<slug>: record steps NN, MM`.
6. Remove each merged worktree and its branch (`git worktree remove`, `git branch -d`). Keep a blocked step's worktree and name it in Last stop.

Sub-agent prompt:

```
You are implementing one step of a plan, alone, in your own git worktree.

<the full step file>

Context: <memory entries this step relates to>. Other steps running in parallel touch <their Files touched>; don't edit those files. Keep scratch files inside the worktree.

Rules:
- Do not create or modify anything under docs/. Report instead.
- Tests first: write the listed tests, run them and see them fail, implement until they pass, refactor. If the step declares an exception, rely on its verify command. If a listed test passes before any implementation, make sure it can fail and report it as a memory candidate.
- Run the verify command and keep its real output.
- Commit your work in this worktree as: <slug> step NN: <name> (<AC ids>)

Report exactly:
Status: done | blocked
Branch and commit: <branch> <sha>
Verify output: <last 30 lines>
Memory candidates: one per line, "<decision|discovery|issue> · <fact> · Why: <reason>"
Notes: anything that affects other steps
```

## 6. When things go wrong

- **Verify keeps failing** after three honest attempts, each on a different hypothesis: mark the step `[!] → <issue id>`, write an `issue` entry with what was tried and what was observed, stop and report. Suggest instrumenting the code (`instrument-time`) or systematic debugging rather than more guessing.
- **The spec is wrong, or the user changes their mind:** invoke `project-spec` in amend mode. It updates the plan through `project-plan` and comes back here.
- **The plan is wrong** (a step too big, a missing dependency): invoke `project-plan` in update mode.
- **A pivot during a step:** record it in memory before continuing, never after.
