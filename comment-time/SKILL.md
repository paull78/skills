---
name: comment-time
description: Assess comment quality across a repo, branch diff, changed files, or a single file. Checks for brevity, necessity, non-triviality, clarity, accuracy, and freedom from rot. Use when user wants a comment review, mentions "comment-time", or asks to audit comments before merging.
---

# Comment Time

Assess whether comments in code are worth their keep. Good comments encode the non-obvious. Everything else is noise, lies waiting to happen, or both.

## Scope

Pick scope from explicit user direction; otherwise infer from context:

- **Repo** — all source files (use sparingly; can be huge)
- **Branch** — comments in lines changed vs base branch (default: `main`)
- **Changed files** — uncommitted/staged files in the working tree
- **Current file** — the file the user is focused on
- **Specific paths** — files/dirs the user names

When ambiguous, ask once. Default to the narrowest reasonable scope (branch diff if on a feature branch, else changed files, else current file).

## Process

1. **Resolve scope.** Compute the file/line set:
   - Branch: `git diff --unified=0 $(git merge-base HEAD main)..HEAD`
   - Changed: `git diff --unified=0 HEAD` plus untracked source files
   - Current/specific: read those files directly
2. **Extract comments.** Find single-line, block, and docstring comments in the scoped lines. Include nearby code for context (a comment without its referent can't be judged).
3. **Apply the checks below.** Tag each finding with severity: **critical** / **warning** / **suggestion**.
4. **Report.** Group by file, then by severity. End with a verdict.

## Quality Checks

### Necessity — does this comment need to exist?

- Does the comment restate what well-named code already says? ("// increment counter" above `counter++`)
- Could a rename of the variable, function, or type make the comment redundant? If yes, prefer the rename.
- Is it ceremonial boilerplate (file headers, `@author`, change logs, banner separators)?
- **Critical** if the comment is pure restatement. **Warning** if a rename would remove the need.

### Non-Triviality — does it carry information?

- Does it explain a **WHY** that isn't visible from the code: a hidden constraint, invariant, workaround, surprising tradeoff, or external system quirk?
- Or does it explain a WHAT that's obvious from reading the next line?
- **Warning** if the comment only describes mechanics. **Suggestion** if it could be sharpened to focus on the why.

### Brevity — is it as short as it can be?

- Multi-paragraph docstrings on simple functions, multi-line block comments where one line would do.
- Repetition of the function signature in prose.
- Over-formatted JSDoc/RST/Sphinx blocks for internal code where a one-liner suffices.
- **Suggestion** unless verbosity is actively obscuring the point, then **warning**.

### Clarity — is it unambiguous to a cold reader?

- Vague hedges: "for now", "probably", "should work", "magic", "hacky".
- Pronouns or references without antecedent: "this is needed because of that".
- Jargon, acronyms, or ticket IDs with no link or context.
- **Warning** if a future maintainer would have to guess what it means.

### Accuracy — does it match the code?

- Stale comments referring to removed params, renamed functions, old behavior, or obsolete TODOs.
- Type/contract claims contradicted by the signature.
- "Returns null on error" when the function throws.
- **Critical** if the comment actively lies. A wrong comment is worse than no comment.

### Rot Indicators — comment-as-debt

- Commented-out code blocks (delete; git has it).
- TODO/FIXME/XXX without owner, date, or actionable context.
- References to current PR/task/ticket that won't make sense later ("added for the X flow", "see PR #123").
- Dated remarks ("temporary fix — 2019", "remove after v2 launch").
- **Warning** by default; **critical** if commented-out code obscures real logic.

### Placement & Form

- Comment far from the code it describes.
- Inline trailing comments crammed on long lines where a line above would read better.
- Docstring on a public API missing the one thing that matters (invariants, units, ownership, thread-safety) while documenting the obvious.
- **Suggestion** level unless placement causes misreading.

## Output

```
## Comment Quality Report

**Scope:** [repo | branch <name> vs <base> | changed files | <path>]
**Verdict:** [pass | pass-with-warnings | needs-attention]

### Critical
- **<file:line>** — <issue> — <suggested action>

### Warnings
- **<file:line>** — <issue> — <suggested action>

### Suggestions
- **<file:line>** — <issue> — <suggested action>

### Summary
- Files scanned: N
- Comments reviewed: N
- Delete recommended: N
- Rewrite recommended: N
- Keep as-is: N
```

## Rules

- Never auto-edit comments. Report only, unless the user explicitly asks for fixes.
- A removed comment is a valid recommendation — most bad comments should be deleted, not rewritten.
- If the code itself is what's unclear, say so: "rename `x` to `retryCount` instead of commenting".
- Don't flag license headers, SPDX tags, or shebangs — those serve tooling, not readers.
- Respect language norms: Python public APIs typically need docstrings; a one-line internal helper does not.
- Keep the report scannable. Group identical issues across files into one finding with a file list.
