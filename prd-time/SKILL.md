---
name: prd-time
description: Create a PRD through architecture selection, user interview, codebase exploration, and relentless questioning. Saves the PRD as a plan file in the repo. Use when user wants to write a PRD, create a product requirements document, plan a new feature, or mentions "prd-time".
---

This skill will be invoked when the user wants to create a PRD. You may skip steps if you don't consider them necessary.

1. Ask the user what architectural patterns to follow. Options:
   - Load installed architecture-knowledge skills (list available ones by name, then ask if there's anything else)
   - User explains a specific architectural pattern to follow
   - Follow the repository's existing best practices (explore CLAUDE.md, folder structure, conventions)

2. Ask the user for a detailed description of the problem and their envisioned solution. If a problem and solution are already present in the conversation context, ask the user if they want to add details to the problem statement or solution.

3. Use the best available agents to explore the repo, verify the user's assertions, and understand the current state of the codebase in relation to the problem and solution.

4. Use the question-time skill to ask the user questions about every aspect of the plan until you reach a common understanding. Be thorough — explore every decision and resolve all ambiguities.

5. Once you have a complete understanding of the problem and solution, use the template below to write the PRD. The PRD should be written as an MD file in the repo at `plans/<project-name>.md`.

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## Acceptance Criteria

A numbered list of concrete, testable conditions that define "done" for this feature. Each criterion should be verifiable — either it passes or it doesn't.

## Architecture Decisions

Architectural patterns chosen, key choices on topology and boundaries, and the tradeoffs that led to each decision. Reference any loaded architecture-knowledge skills or repository conventions that informed these decisions.

## Interface Contracts

APIs, schemas, module interfaces, and their expected behaviors. Do NOT include specific file paths or code snippets — they become outdated quickly.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Risks & Open Questions

Unresolved items, identified risks, and their severity. Include anything surfaced during the question-time interrogation that remains open.

## Out of Scope

A description of the things that are out of scope for this PRD.

</prd-template>
