---
name: knowledge-design-of-design
description: Architecture knowledge from Fred Brooks' "The Design of Design." Use as a grilling lens when evaluating the design process itself — how decisions are made, what constraints are honored, and whether the designer is being honest about tradeoffs.
---

# The Design of Design — Fred Brooks

## Core Thesis

Design is not a linear process. It is iterative, exploratory, and driven by constraints. Good design comes from good designers making judgment calls, not from process alone.

## Key Principles

- **Conceptual integrity** is the most important property of a system. One mind (or a small, aligned group) should own the vision.
- **Constraints are gifts.** They narrow the design space and force creative solutions. Embrace them early.
- **Design is about tradeoffs**, not optima. Every choice closes doors. Know which doors you're closing and why.
- **Budgets over targets.** Set hard budgets for resources (size, latency, complexity) and treat overruns as bugs, not features.
- **Great designs are redesigns.** First attempts teach you the problem. Expect to throw one away.
- **Exemplars over principles.** Study great designs directly, not just abstractions about design.
- **Rationalism fails.** You cannot derive a good design from first principles alone. Empiricism, prototyping, and taste matter.

## On Design Process

- Separate the problem-finding phase from the solution-finding phase.
- Design top-down, but validate bottom-up (build prototypes).
- Document the design rationale — why you rejected alternatives, not just what you chose.
- Beware "second-system effect": the temptation to overdesign the follow-up.

## Key Anti-Patterns

- Design by committee — diffuses conceptual integrity.
- Absence of constraints — leads to bloat and indecision.
- Skipping prototypes — trusting the model without testing it.
- Optimizing before understanding the problem space.
- Treating all requirements as equal.

## Grilling Questions

- Who owns the conceptual integrity of this design?
- What constraints are you working within? Have you listed them?
- What alternatives did you reject, and why?
- What would a prototype of the riskiest part look like?
- Is this a first design you're over-investing in?
