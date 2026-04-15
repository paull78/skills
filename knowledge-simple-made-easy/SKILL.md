---
name: knowledge-simple-made-easy
description: Architecture knowledge from Rich Hickey's "Simple Made Easy" talk. Use as a grilling lens when evaluating designs for accidental complexity, complecting, and whether "easy" choices are hiding future pain.
---

# Simple Made Easy — Rich Hickey

## Core Distinction

- **Simple:** not interleaved, not complected. One role, one concept, one dimension. Objective property.
- **Easy:** near at hand, familiar, within current capability. Relative to the person. Subjective property.
- Simple and easy are independent axes. Easy things can be complex. Hard things can be simple.

## Complecting

Complecting = braiding together things that could be independent. The root cause of complexity.

Common complections:
- State and identity (mutable objects)
- State and time (no separation of "when" from "what")
- Order and meaning (positional arguments, sequential coupling)
- Caller and callee (direct coupling vs queues/channels)
- What and how (specificity where abstraction would do)
- Policy and mechanism in the same module

## Simplicity Toolkit

| Complex | Simple alternative |
|---------|--------------------|
| Mutable state | Values, immutable data |
| Objects | Functions, namespaces |
| Inheritance | Composition, protocols |
| Positional args | Named/map args |
| ORM | Declarative data access |
| Actors with state | Queues, pure functions |
| Conditionals everywhere | Polymorphism, data-driven dispatch |

## Key Principles

- Choose simple over easy, especially at architectural boundaries.
- Simplicity is a prerequisite for reliability.
- Ease of understanding now trades against ease of change later.
- "I can rewrite it in two weeks" is not simplicity — it's familiarity.

## Grilling Questions

- What is being complected here that could be kept separate?
- Is this choice simple, or just familiar?
- If requirements change in one dimension, how many things break?
- Can you reason about this component in isolation?
- Are you trading future flexibility for present convenience?
