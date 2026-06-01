---
name: instrument-time
description: Instrument code to gain runtime visibility — logging, state dumps, traces, a quick harness — then iterate against that real signal to fix the bug or hit the goal, instead of editing blind and guessing. Use this for essentially ANY non-trivial debugging or investigation: a bug you can't fix by reading, a failure with no obvious cause, a flaky or intermittent test, an "it says it worked but didn't" mystery, a slow endpoint or performance target, or output you must tune over several attempts. Reach for it whenever someone describes a symptom they don't understand and the cause isn't visible on inspection — even if they never say "instrument" or "feedback loop", and especially once a first fix has already failed. Triggers include "instrument-time", "instrument this", "tighten the loop". Not for trivial one-line fixes you can verify by eye, writing a test suite (use tdd), production monitoring setup, code review, docs, or mechanical refactors.
---

# Instrument Time

Fast, tireless iteration is the agent's edge — but iteration only converges if you can see what each attempt did. So instrument the code to make its runtime behavior visible, then use that signal to evaluate your own changes and measure progress toward the goal. Without it, retrying is guessing.

## When to use

Problems that won't yield in one shot:

- A bug that survived the obvious fix, or that won't reproduce reliably.
- A feature or output you have to *tune* — get it working, then make it good.
- Performance, flakiness, or correctness work where reading the code doesn't reveal the cause.

Skip it for a one-line change you can verify by eye. The value starts the moment one attempt won't be enough.

## The core move

Before changing anything, answer: **how will I observe whether an attempt made this better, worse, or unchanged?**

If you have a cheap, automatic answer, iterate against it. If you don't, build that signal first — it's the most important step of the task. Editing before you can see the result wastes every attempt that follows.

## Instrument for runtime behavior

Tests check pass/fail against cases you imagined. The blindness on a hard problem is usually different: not knowing what the running system *actually does*. Reach for runtime visibility first — it's cheaper than a test suite and tells you *why*, not just *whether*:

- **Log the decision points** — inputs, outputs, branch taken at the boundaries that matter. Log the actual value, never the value you expect.
- **Dump state** — expose real internal state (`--dump-state`, a debug route, a REPL, a log line) instead of inferring it.
- **Write a throwaway harness** — a small driver that runs the real code path and prints what happened.
- **Capture real output** — hit the endpoint, render the component, run the command, read the actual response.
- **Make failures loud** — surface errors with context. A silent `catch` hides the signal you're hunting.
- **Measure, don't guess** — for performance, trace and time it; never reason about which line is slow.

## Lock the loop before you iterate

You'll run the check many times, so make it solid first:

1. **Reproduce reliably.** A flaky repro is a broken instrument — you can't tell a fix from luck. Pin it to something deterministic you can run on demand. This alone often cracks the problem.
2. **Make it cheap, fast, automatic.** One command, clear verdict. Every manual step and slow second is multiplied by the iteration count, so shrinking the loop *is* the work.
3. **Make it a gradient, not a gate.** See below.

## Iterate to convergence

- **One change per cycle, then observe.** Change several things at once and you can't tell which one moved the needle.
- **Keep what helps, revert what hurts.** Backtracking only works if each step's effect is legible.
- **Use a gradient, not pass/fail.** `"3 of 50 cases fail (was 12)"` or `"p95 = 180ms (was 320, target 100)"` shows direction and distance, so partial progress reads as progress and steers the next attempt. A bare pass/fail can't.
- **When stuck, add sight — don't thrash.** Repeating an attempt with no new information is the main failure mode. Add inspection points, narrow to a smaller slice that still reproduces, dump more state.
- **Keep a trail of attempt → observation.** Over many cycles it stops you looping back to what you already tried, and makes the diagnosis obvious in hindsight.

## Make the goal measurable

You can't iterate toward a vague goal. Restate it as something you read off each run — ideally a gradient:

| Vague | Measurable signal |
|---|---|
| "Fix the slow page" | "p95 for `/dashboard` < 200ms in the trace" |
| "Stop the flakiness" | "repro script fails 0/100 runs (now ~30/100)" |
| "Handle the edge cases" | "all 50 harness cases pass (now 38)" |

## Red flags

Each of these means you've gone blind — get sight before the next attempt:

| Thought | Reality |
|---|---|
| "This should work now." | You haven't run it. Run it, read the output. |
| "It's probably X that's slow." | You're guessing. Measure it. |
| "Let me change a few things and see." | You'll lose attribution. One change, then observe. |
| "It feels closer." | What does the number say? |
| "Let me just try that again." | Same attempt, no new info. Add sight first. |

## Notes

- **Tests have their place** as one instrument: a pure function, a regression to lock down, a boundary contract. A failing-then-passing test is a clean loop — hand off to the `tdd` skill. But they tell you *whether*, while instrumentation tells you *what* and *why*.
- **Keep durable instrumentation, clean up scratch.** Logging worth keeping (so the next change isn't blind) earns its place; one-off prints are noise once the question is answered.

## Before you call it done

1. **Did I observe it** — can I point to the output/measurement I read, not my reasoning about what should happen?
2. **Was the signal real** — did I exercise the path I changed, and does the repro that used to fail now pass?
3. **Did I converge or just stop** — is the gradient at target, or did I quit partway?
