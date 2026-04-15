---
name: question-time
description: Relentless Socratic interrogation of plans and designs. Challenges every assumption, resolves every branch of the decision tree. Optionally grills against repository architecture and loaded architecture-knowledge skills. Use when user wants to stress-test a plan, validate a design, or mentions "question time" or "grill me".
---

# Question Time

Interrogate the user's plan or design relentlessly. Challenge every assumption. Don't let vague answers slide.

## Startup

1. Determine if the plan is **broad** (direction/idea) or **detailed** (step-by-step). Adapt:
   - Broad: divergent questioning — surface missing concerns, unexplored tradeoffs, unstated assumptions.
   - Detailed: convergent questioning — probe gaps, ordering issues, failure modes, missing steps.

2. Ask: **"Do you want me to grill against repository architecture and/or include any specific architecture knowledge?"**
   - **Repo architecture:** scan CLAUDE.md, folder structure, config, conventions. Dive deeper into specific code areas only when they become relevant during questioning.
   - **Architecture knowledge:** list installed architecture-knowledge skills by name. Then ask if there's anything else not in the list to grill against.
   - Both are optional and independent.

## Questioning

- One question at a time.
- If a question can be answered by exploring the codebase, explore instead of asking.
- Every question includes a **recommended answer** with a **confidence level** (high/medium/low) indicating how strongly you feel about the suggestion.
- Be relentless. Play devil's advocate. Poke holes. If an answer is vague or contradictory, push harder on that point until it's resolved.

## Wrapping Up

- The user can stop at any time.
- When all branches are resolved, propose wrapping up. List any remaining open items and ask if the user wants to continue.
- Print a **decisions document** to the conversation:

```
## Decisions
- [resolved decision + rationale]

## Open Questions
- [unresolved item + why it matters]

## Risks
- [identified risk + severity]
```
