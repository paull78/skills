---
name: knowledge-pragmatic-programmer
description: Architecture knowledge from Hunt & Thomas' "The Pragmatic Programmer." Use as a challenge lens when evaluating designs for practical engineering discipline — DRY, orthogonality, reversibility, and tracer bullets.
---

# The Pragmatic Programmer — Hunt & Thomas

## Core Principles

- **DRY (Don't Repeat Yourself):** Every piece of knowledge must have a single, unambiguous, authoritative representation. Duplication is not just code — it's duplicated knowledge, intent, or policy.
- **Orthogonality:** Components should be independent. Changing one should not require changing another. Test: if I change X, how many other things do I have to touch?
- **Reversibility:** Assume decisions will change. Avoid locking in to vendors, frameworks, or architectures. Keep options open.
- **Tracer Bullets:** Build thin, end-to-end slices through the system first. Validates architecture, integration, and assumptions early.
- **Good Enough Software:** Know when to stop. Perfectionism is a form of procrastination. Ship and iterate.

## Design Heuristics

- **Design by Contract:** Define clear preconditions, postconditions, and invariants at boundaries.
- **Decoupling:** Tell, don't ask. Law of Demeter — talk only to immediate friends.
- **Domain Languages:** Write code in the language of the problem domain, not the solution domain.
- **Estimating:** Estimate to communicate uncertainty, not to commit. Iterate estimates as you learn.
- **Prototypes vs Tracer Bullets:** Prototypes are disposable (explore unknowns). Tracer bullets are kept (skeleton of real code).

## Key Anti-Patterns

- "It works on my machine" — environment coupling.
- Copy-paste reuse — DRY violation disguised as productivity.
- Big-bang integration — no tracer bullet, no early feedback.
- Assuming decisions are permanent.
- Programming by coincidence — it works but you don't know why.

## Challenge Questions

- Is this knowledge represented in exactly one place?
- If this decision turns out to be wrong, how hard is it to reverse?
- Can you build a tracer bullet through this in a day?
- Are these components truly orthogonal? What's the blast radius of a change?
- Are you programming by coincidence, or do you understand why this works?
