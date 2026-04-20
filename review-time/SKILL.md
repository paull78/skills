---
name: review-time
description: Multi-agent code review that dispatches the same diff to all available AI agents (Claude, Codex, Copilot, etc.) in parallel, then aggregates findings into a unified report with attribution and consensus scoring. Use when user wants a code review, mentions "review-time", or wants to review a PR or branch before merging.
---

# Review Time

Multi-agent code review. Sends the same diff to all available AI agents in parallel, aggregates findings into one report. Consensus (flagged by multiple agents) = higher confidence.

## Input

Either:
- A PR number or URL (fetches diff from GitHub)
- Current branch vs base branch (defaults to main)

## Process

1. **Get the diff.** Fetch PR diff or compute branch diff.

2. **Ask for optional context:**
   > "Is there a PRD or architecture-knowledge skills to review against? (Or just a pure code review?)"
   - If PRD: load it and include acceptance criteria + architecture decisions as review context
   - If architecture knowledge: load specified skills as review lens
   - If neither: proceed with pure code review

3. **Detect available agents.** Check which CLI tools are installed:
   - `claude` (Claude Code CLI)
   - `codex` (OpenAI Codex CLI)
   - `gh copilot` or Copilot via draft PR (`@copilot` reviewer)
   - Other AI CLIs on PATH

   Present findings:
   > "Found: claude, codex, copilot. Use all three? Or pick specific ones?"

4. **Dispatch reviews in parallel.** Send the same diff and review prompt to each selected agent.

   **Review prompt asks for:**
   - Bugs and logic errors
   - Security vulnerabilities
   - Architecture and design issues
   - Code quality and readability
   - Test coverage gaps
   - Performance concerns

   If PRD or architecture knowledge was loaded, also ask:
   - Does the implementation match the PRD acceptance criteria?
   - Does it respect the specified architecture patterns?

   **Compute environment variables first:**
   ```bash
   BRANCH=$(git branch --show-current)
   BASE=$(git merge-base HEAD main)
   REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
   DIFF=$(git diff "$BASE"..HEAD)
   PR_NUMBER=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number')
   ```

   **Agent invocation:**

   - **Claude (self):** Review the diff directly — you are already Claude.

   - **Codex:**
     ```bash
     codex exec --full-auto --output-last-message /tmp/codex-review.md "Review the code changes on this branch. Run: git diff $BASE..HEAD to see the changes. Focus on bugs, logic errors, edge cases, security, architecture, and code quality. Output a structured review with file:line references."
     ```

   - **Copilot (via PR):** If `$PR_NUMBER` is set:
     ```bash
     gh pr edit "$PR_NUMBER" --add-reviewer @copilot
     ```
     Poll for Copilot's review (may take up to 5 minutes):
     ```bash
     gh api "repos/$REPO/pulls/$PR_NUMBER/comments" --jq '.[] | select(.user.login | test("copilot"; "i")) | {path, line, body}'
     ```
     If no PR exists and user doesn't want one created, skip Copilot.

   - **Other agents:** invoke via their CLI with equivalent prompt and read output.

5. **Aggregate findings.** Collect all responses, then:
   - Group by file and location
   - Deduplicate identical findings
   - Score by consensus: findings flagged by multiple agents get escalated severity
   - Attribute each finding to the agent(s) that raised it

6. **Print the report.**

## Output Format

```
## Code Review Report

**Reviewed:** [PR #N | branch-name vs main]
**Agents:** claude, codex, copilot
**Context:** [PRD: plans/X.md | architecture knowledge: Y, Z | none]

### Consensus Issues (flagged by 2+ agents)
- **[file:line]** — description (flagged by: claude, codex)

### Issues — Recommend Fix
- **[file:line]** — description — suggested fix (flagged by: agent)

### Issues — Need Input
- **[file:line]** — description — options/question (flagged by: agent)

### Suggestions
- **[file:line]** — description (flagged by: agent)

### Summary
- Total findings: N
- Consensus findings: N
- Files reviewed: N
- Agents used: N
```

## Rules

- Never block on a missing agent. If only one is available, run the review with that one.
- Do not post comments to the PR. Report is conversation-only.
- If agents disagree on severity, use the higher severity and note the disagreement.
- Keep the report concise — group related findings, don't repeat the same issue per agent.
