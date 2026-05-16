---
name: explain-time
description: Write an explanatory document about an existing system, subsystem, or codebase area for a reader who knows code but not this domain's jargon or established patterns. Top-down narrative, jargon defined inline, real walk-throughs, file:line citations, glossary. Use when the user wants to explain how something works, write an architecture/system explainer, write onboarding or internal docs, document a tricky subsystem for new readers, mentions "explain-time", or asks for a "how does X work" document. Do NOT use for API reference manuals, end-user product docs, tutorials, PRDs, or in-chat explanations — this is specifically for written explanatory documents that newcomers will read cold.
---

# Explain Time

Write an explanatory document about an existing system for a smart engineer who doesn't know this domain's jargon or conventions yet. The reader should be able to walk in cold, build a mental model, then dive into the code with confidence.

The goal is **understanding**, not coverage. A good explain-time doc ends with the reader knowing what's going on; it does not exhaustively catalog every field, edge case, or option. That's what reference docs are for.

## The Core Principle

Most technical docs fail in the same way: they jump straight into "how" without establishing "what is this, who's involved, and why does it work this way at all." An explain-time doc inverts that. You teach the reader the world first, then the code. By the time they hit a code snippet, they already know what role it plays.

If you find yourself writing a code block before the reader knows who the actors are, stop and back up.

## When to Use This Skill

**Use when:**
- An engineer asks "how does X work" in a way that suggests they want a document, not a chat reply
- The user wants onboarding docs, system explainers, architecture write-ups, or "explain this subsystem" docs
- A subsystem touches concepts the reader probably doesn't know (auth, distributed systems, payment flows, weird domain models) — anything where jargon would otherwise be a wall
- The user says "explain-time" or asks to rewrite an existing doc to be clearer

**Don't use when:**
- The answer fits in a chat reply (a paragraph or two)
- The user wants reference docs (full API surface, exhaustive field listings)
- The user wants a tutorial (task-oriented, "do these steps")
- The user wants a PRD (requirements, not explanations)
- The user wants commit messages, code comments, or PR descriptions

## Step 1 — Interview the Reader Into Existence

Before writing anything, know **who** the doc is for and **what they already know**. Ask the user briefly, or infer from context, then state your assumed audience explicitly at the top of the doc in a blockquote. The reader should know within five seconds whether this doc is aimed at them.

Things worth pinning down:

- **What do they know?** ("an engineer in this codebase but not this domain", "a frontend dev who doesn't know how our auth works", "a new hire on day three").
- **What can you assume they don't know?** List the specific jargon you'll have to define.
- **What's the scope?** One subsystem? One file? A cross-cutting flow? Don't try to explain everything — pick a finite topic.
- **What's the goal?** ("be able to make changes safely", "be able to debug an incident", "be able to talk about it in a design review").

Stating the audience in the doc itself is not optional. It's the contract — every choice below flows from it.

## Step 2 — Outline Before Drafting

The canonical structure that worked for the reference auth doc:

1. **Big picture** — Who are the parties? What problem does this solve? One-sentence summary of the solution. Often best with an ASCII diagram of the actors.
2. **Walk through a real example end-to-end** — Pick one concrete request/event/scenario and follow it through every layer. Number the steps. This is the spine of the doc.
3. **What a [consumer] actually sees** — Once the flow is clear, zoom into what the surface looks like from a consumer's perspective (a handler, a caller, a UI component).
4. **Sub-mechanisms** — Pieces that didn't fit cleanly in the walk-through but matter (caching, retries, lifecycle, authorization layers).
5. **Related-but-different things** — Explicitly call out adjacent systems that the reader might confuse with this one. Worth its own section.
6. **Quirks worth knowing** — Client-specific weirdness, legacy bits, surprising behavior.
7. **Lifecycle / reference table** — Compact table the reader can scan when they come back to the doc later.
8. **Glossary** — Every defined term, alphabetized at the end as a backstop.
9. **Open questions and risks** — Honest list of what's brittle, missing, or unclear today.

Adjust the section count to the topic, but keep the order: **picture → walk-through → consumer view → mechanism details → adjacent confusions → reference → glossary → gaps**. Numbered "Part 1 — …, Part 2 — …" headings help the reader know where they are.

## Step 3 — Research and Verify

You're going to claim things. Every claim about code must be verified by reading the code, not guessed from naming.

- **Open the actual files.** Don't trust subagent summaries on load-bearing claims — verify the ones the doc rests on.
- **Cite `file.ts:line` for every concrete claim.** Anchored citations let the reader jump to source. Vague references ("in the auth module") are useless.
- **Check the negative claims too.** If you say "this doesn't do X," confirm by searching.
- **Quote small code snippets** to ground explanations. Three to ten lines per quote, max — long quotes drown the prose.

If a claim can't be verified, mark it explicitly: "I believe X but didn't confirm" — better than a confident lie.

## Step 4 — Draft Using These Patterns

These are the techniques that make the doc readable. Use them liberally.

### Define jargon inline, on first use, with an analogy if possible

The first time a term appears, define it in the same sentence. Add an analogy when one fits. Then use the term freely.

> A **bearer token** — a string that proves the caller is allowed. Whoever holds it is treated as the user, like a movie ticket.

Avoid forward references ("we'll explain bearer tokens later"). If you can't define it where you need it, restructure so you can.

### Translate spec/standard names

When a thing has an industry name (OAuth, RFC 9728, SSE), tell the reader the name **and** that they don't need to know the spec to read the code. Names anchor the doc to external knowledge for readers who do know; the "don't need to know" reassurance frees the readers who don't.

### Show, don't summarize

Walk through one concrete example with realistic values:

- Use `"user-12345"` and `"alice@acme.com"`, not `<user_id>` and `<email>`.
- Use `POST /mcp` with a real-looking body, not "the client makes a request."
- Number the steps in the flow and stick to that numbering.

Concrete examples carry more information per token than abstract descriptions, and they're easier to remember.

### Pair code with English

Every code block should be followed (or preceded) by a plain-English line saying what it means. The "Translation:" pattern works well:

> ```json
> { "resource": "...", "authorization_servers": [...] }
> ```
>
> Translation: "I'm `/mcp`. Go to Cloud to get a token. Put it in the `Authorization` header."

If the reader could understand the code without the translation, the translation is too literal — skip it. If they couldn't understand without it, write it.

### Explain *why*, not just *what*

For every non-obvious choice, say why it's that way. "The token is cached for 5 minutes" is a fact. "The token is cached for 5 minutes so the common case (many tool calls in a single conversation) skips the network round trip — at the cost of up to 5 minutes of staleness when Cloud revokes a token" is an explanation. Always prefer the second.

### Mark key takeaways visibly

When something is **important** or **easy to miss**, mark it:

> **Critically: `--no-jwt` only affects `/authenticate`. It does not make `/mcp` work offline.**

Bold, "Critically:", "Note:", or pull-out callouts. Don't overuse — three to six in a doc is enough.

### Tables for fields, lifecycles, glossaries

Prose is great for narratives; tables are great for "look something up." Use a table whenever you find yourself writing N parallel sentences with the same structure. Field listings, TTLs, lifecycle states, glossaries — all tables.

### Separate the primary topic from adjacent confusions

If there's an adjacent system the reader is likely to conflate with this one, give it its own labeled section: "The Other [Thing]: …" or "Related-But-Different: …". Don't bury this in a footnote — the reader will conflate the systems unless you call it out.

### Address open questions honestly

End with the gaps. "Token revocation is 5 minutes laggy." "Scope is advertised but not enforced." "No fake-introspection mode for offline dev." This is the section that earns trust — it tells the reader the doc isn't selling them anything.

## Anti-Patterns to Avoid

- **Reference-doc structure** — alphabetized field listings before any narrative. Save them for the table near the end.
- **Jargon without definition.** If you use "introspection" or "RFC 7662" without saying what they mean in this codebase, the reader stalls.
- **Forward references.** "We'll cover that in Part 6" forces the reader to hold tension. Restructure so each section is self-contained.
- **Code walls.** A code block longer than ~15 lines without English in between is a sign you're describing rather than explaining.
- **Symmetric coverage.** Treating every field, every option, every edge case with equal weight. Spend tokens on what the reader will *actually need* — usually 80% of the value is in 20% of the surface.
- **Tone of authority without evidence.** Confident claims about code with no `file.ts:line` to back them. The doc dies the first time someone catches an error.
- **Sales voice.** "The elegant decoupled design…" — drop the adjectives. Engineers trust dry prose.
- **Burying the answer.** If the reader's main question is "how does auth work?", the one-sentence answer belongs in the first 200 words, not on page 4.

## A Quick Self-Review Before Handing It Over

After the draft, re-read with the reader's eyes:

1. **Cold-open test.** Could someone who's never seen this codebase open the doc and know what's going on by the end of Part 1?
2. **Jargon sweep.** Highlight every term-of-art. Was each one defined the first time it appeared?
3. **Citation sweep.** Every load-bearing claim should have a `file.ts:line`. Skim for unsupported assertions.
4. **Tone check.** Any sentence that reads like marketing? Cut it.
5. **The "so what" check.** For every non-trivial fact, can the reader say why it matters? If not, either add the why or drop the fact.

## Output Location

Default to `docs/<topic>.md` in the repo root, unless the user specifies otherwise. If the doc complements an existing one, use a parallel name (`docs/foo.md`, `docs/foo-auth.md`, `docs/foo-format.md`). State the path before writing so the user can redirect.

## Format Conventions

- Top-of-file blockquote stating the audience.
- Numbered "Part 1 — …" headings for the major sections of the narrative.
- Standard markdown headings (no HTML), tables, fenced code blocks with language tags.
- ASCII diagrams are fine for actor/flow pictures — keep them small (no more than a dozen lines).
- File:line citations as backticks: `bais/src/mcp/mcp-server.ts:56-63`.
- No emoji unless the user asked for them.
- Plain language. Short sentences. Active voice. The reader is smart; don't talk down to them, and don't try to impress them.
