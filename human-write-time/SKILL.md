---
name: human-write-time
description: Write human-facing prose that doesn't read as AI-generated, and de-slop drafts that do. Hard-bans negative parallelism ("it's not X, it's Y"), dead AI vocabulary, em dashes, puffery, participle padding, and chatbot leakage; loads an optional voice profile so the result sounds like the author instead of a house style. Use when writing or editing blog posts, essays, newsletters, emails, social copy, landing pages, READMEs, docs, release notes, or marketing copy, and whenever the user says "human-write-time", "make this sound human", "de-slop this", "humanize this", "this reads like AI", or complains that a draft sounds LLM-generated. Not for code, commit messages, or chat replies.
---

# Human Write Time

Write prose that reads as though a person wrote it, and repair prose that doesn't.

Two layers, kept separate:

- **De-slop layer.** Removes machine tells. Applies to all human-facing prose, always.
- **Voice layer.** Makes the result sound like a particular author. Loads only when there is a voice to match and the register calls for one.

Most failures come from applying the second layer where only the first belongs.

## Modes

| Mode | Trigger | You deliver |
|------|---------|-------------|
| **Generate** | Asked to write something new | The piece. Nothing else unless asked. |
| **Audit** | Handed an existing draft, file, or paste | Rewritten text, then the change log table |
| **Embedded** | This skill loaded inside a larger task | Final text only. No draft, no audit, no change log, no commentary. |

In file mode, rewrite the file in place with the final version only. Leave code blocks, frontmatter, data, and link targets untouched. Report a short summary in conversation, not in the file.

## Step 1. Register check

Ask what kind of text this is before touching voice.

**Neutral registers** (reference docs, API documentation, technical specs, legal text, encyclopedic writing, changelogs): plain and voiceless *is* the human register here. Apply the de-slop layer. Do not inject first person, opinion, humor, or personality. Adding voice to a reference doc makes it worse and more obviously generated.

**Voiced registers** (essays, blog posts, newsletters, emails, opinion, social copy, most marketing): apply both layers.

If it sits between the two, stay closer to neutral. Under-voicing is recoverable, over-voicing is not.

## Step 2. Voice source

For voiced registers, resolve in this order and stop at the first hit:

1. A path or sample the user gives you in the request.
2. `VOICE.md` or `.claude/VOICE.md` in the current repo. This is the *project's* house voice. It wins for anything published under that project, including its README and docs, even when the author has a personal profile.
3. `~/.claude/VOICE.md`. This is the *author's* personal voice, and it applies everywhere else.
4. Surrounding context: the rest of the document, earlier messages in the thread, other posts on the same site, the repo's existing prose.
5. Nothing found. Ask for one sample of the author's writing before drafting. Do not invent a house style and do not default to the personality rules below.

Read the profile's writing samples before its rules. A paragraph the author actually wrote carries more signal than any list of preferences, including this file's.

**A voice profile overrides this skill.** If the profile uses em dashes, keep em dashes at the profile's frequency. If it writes long unbroken paragraphs, write long unbroken paragraphs. The skill supplies defaults, the author supplies the truth.

When you have a sample, read it for sentence length distribution, vocabulary level, punctuation habits, recurring phrases, how it opens and closes, and what it never does. Match those habits instead of applying generic rules.

## Step 3. Frequency tiers

Every rule below carries a tier. This matters: a model that satisfies a ban list perfectly produces clean prose with no texture, which is its own tell.

- **HARD.** Never. One instance is a defect. Rewrite the sentence.
- **STRONG (70 to 80%).** The default. Deviate when the content genuinely calls for it, not when it's convenient.
- **LIGHT.** Preference. Context decides. Anything unlabeled is light.

Do not avoid a HARD-listed word forever when it is genuinely the right word in its literal sense. "Robust standard errors" is statistics. "Harness" is a piece of equipment. "Align the columns" is a real instruction. The ban targets the puffery sense, not the dictionary.

---

# HARD rules

## 1. Negative parallelism and reframe constructions

The single most reliable marker of machine text. Every model does it, several times per response, because the pattern is dense in persuasive writing, TED talks, op-eds, and marketing copy. It makes a shallow idea feel profound at zero cost. Readers now register it as *machine* before they register the content.

Banned shapes:

- "This isn't X. This is Y."
- "Not X. Y."
- "It's not just about X, it's about Y."
- "Not only X, but also Y."
- "Less X, more Y."
- "Forget X. This is Y."
- "X? No. Y."
- "Stop thinking X. Start thinking Y."
- "You don't need X. You need Y."
- "The question isn't X, the question is Y."
- "X is dead, Y is the future."
- "X is overrated, Y is what matters."
- Any sentence that negates a framing and then asserts the corrected one.

Variants that survive a careless first pass:

- "While X might seem right, Y is actually..." (same skeleton, different coat)
- "Sure, X works. But Y is where the real..." (concession plus pivot)
- "X gets all the attention, but Y is what actually..." (third disguise)
- Tailing negation: "...with no guessing, no setup, no friction."

**The fix.** Delete everything before the positive claim. "It's not about the prompt, it's about the context" becomes "It's about the context." The negated half carries no information. A reader does not need to be told what a thing isn't before being told what it is.

## 2. Dead AI vocabulary

Statistically overrepresented in model output. Grouped so the pattern generalizes to words not listed.

- **Hype.** revolutionize, game-changer, cutting-edge, groundbreaking, breakthrough, unleash, supercharge, unlock, transformative, disruptive, unprecedented, 10x anything.
- **Corporate abstraction.** leverage, synergy, holistic, streamline, optimize, scalable, robust, seamless, frictionless, turnkey, plug-and-play, future-proof, data-driven, mission-critical, empower, democratize, ecosystem.
- **Praise and puffery.** meticulous, meticulously, unparalleled, vibrant, commendable, visionary, pioneering, trailblazing, renowned, breathtaking, stunning, nestled, iconic.
- **Fake-depth nouns.** tapestry, realm, landscape (abstract), interplay, testament, paradigm, intricacies, fabric, journey (abstract).
- **Significance inflation.** crucial, pivotal, vital, essential, profound, enduring, key (as adjective).
- **Verb tics.** delve, harness, foster, garner, showcase, underscore, accentuate, elevate, navigate (metaphorical), surpass, captivate, reimagine, redefine, highlight (meaning "shows").

## 3. Em dashes and en dashes

Remove all of them. Use commas, periods, colons, semicolons, or parentheses. Restructure the sentence if none of those fit.

Single documented exception: a voice profile or writing sample that uses dashes. Then match its frequency.

## 4. Copula avoidance

"Serves as," "stands as," "represents," "marks a," "boasts a," "features a," "offers a," "holds the distinction of being," used to dodge a plain verb.

> AI: The library serves as a foundation for the parser.
> Human: The parser is built on the library.

Say "is." Say "has."

## 5. Participle padding

Present-participle phrases bolted onto a sentence to fake analysis: "highlighting its importance," "underscoring the significance," "reflecting broader trends," "symbolizing the shift," "contributing to the rich tapestry of."

Delete the phrase. If the analysis is real, it earns its own sentence with a specific claim.

## 6. Puffery and significance inflation

"A pivotal moment in the evolution of." "Marking a significant shift toward." "Setting the stage for." "Left an indelible mark on." "A key turning point."

State the fact. Let the reader decide what it means.

Same family, borrowed notability. A sentence whose only job is to establish that the subject matters: press logos recited in a row, follower counts, funding totals, award lists, "as featured in," "trusted by teams at." Keep the ones a reader needs. Cut the ones that are there to impress, and never assemble a list of them to open a piece.

## 7. False ranges

"From ancient traditions to modern innovations." "From startups to enterprises." If you cannot name meaningful middle ground between the two poles, the range is decorative. Delete it, or list the specific things.

## 8. Rule of three

Three adjectives in a row. Three parallel short phrases. Three-item lists used to make thin analysis look complete. "Faster, cheaper, and more reliable."

Use two. Use four. Or name the one thing that actually matters.

## 9. Elegant variation

Cycling synonyms for the same referent because repetition feels wrong: a person becomes "the protagonist," then "the key player," then "the eponymous figure." A tool becomes "the platform," then "the solution," then "the offering."

Use the name again. Honest repetition beats forced synonyms.

## 10. Meta commentary and signposting

"In this article, I will." "Let's dive in." "Let's explore." "Let's unpack." "Here's what you need to know." "Let me walk you through." "In this section we will discuss." "To put this in perspective." "In other words." "It goes without saying."

Say the thing. Do not announce that you are about to say the thing.

## 11. Dead transitions and filler

- Transitions: furthermore, moreover, additionally, that said, that being said, with that in mind, on top of that, it is also worth mentioning.
- Throat-clearing: "it's important to note that," "it's worth noting that," "what makes this particularly interesting is," "the implications here are," "the real question is," "at its core," "what really matters is."
- Bloat: "in order to" (use "to"), "due to the fact that" (use "because"), "at this point in time" (use "now"), "a wide variety of" (use "many" or name them).

## 12. Engagement bait and hype framing

"Let that sink in." "Read that again." "Full stop." "This changes everything." "Here's the part nobody's talking about." "What nobody tells you." "Most people don't realize." "Are you paying attention?" Any promise of superpowers or overnight transformation.

## 13. Vague attribution

"Experts argue." "Studies show." "Industry reports suggest." "Observers say." "It is widely believed."

Name the source or cut the claim. **Never invent an attribution to satisfy this rule.** An unsourced sentence deleted is correct. A plausible-sounding fabricated citation is a serious defect.

## 14. Chatbot leakage and sycophancy

"I hope this helps." "Let me know if you'd like." "Would you like me to." "Certainly." "Of course." "Great question." "Excellent point." "You're absolutely right."

These belong in chat. Strip them from anything published.

## 15. Cutoff disclaimers and gap-filling speculation

"As of my last update." "Based on available information." "While specific details are limited."

Also the softer version, where a guess about the world is dressed as knowledge: "the company likely faced challenges," "he probably maintained a low profile," "this may have contributed to."

State what is unknown, or leave it out. Note this is *not* the same as honest first-person uncertainty, which is required. See Craft below.

## 16. Generic upbeat conclusions

"Exciting times lie ahead." "The future looks bright." "Only time will tell." "In conclusion." "At the end of the day." "Ultimately." "Moving forward."

If the point is made, stop. Do not summarize what the reader finished two paragraphs ago. End on the last concrete thing you have to say.

## 17. Aphorism formulas

"X is the Y of Z." "X becomes a trap." "The best X is the one you actually Y." Constructions engineered to sound quotable. Replace with the concrete claim underneath.

## 18. Diff-anchored writing

Describing a thing by what changed instead of what it is. "This function was added to replace the old handler." Nobody reading it later cares about the diff.

> Write: This function retries failed uploads with exponential backoff.

## 19. Formulaic section shapes

"Challenges and Future Prospects" as a heading. "Despite these challenges, X continues to thrive." Any section that exists because an outline template said it should.

## 20. Formatting tells

- **Title Case In Headings.** Use sentence case.
- **Decorative emojis** in headings, bullets, or as paragraph markers. Remove.
- **Mechanical bolding** of every acronym, defined term, or first mention. Bold 1 to 2 genuine moments per section, no more.
- **Inline-header lists**, where every bullet is a bold term, a colon, then a sentence. If the items are prose, write prose.
- **Fragmented headers**: a one-line restatement of the heading sitting between the heading and the real content. Delete it.
- **Curly quotes** when the platform did not generate them. Use straight quotes.
- Hyphenated pairs stay hyphenated attributively ("a cross-functional team") and lose the hyphen predicatively ("the team is cross functional").

## 21. Fragment-question pivots and stage cues

A one-word question standing alone to set up its own answer: "The result?" "The catch?" "The problem?" "The kicker?" "The best part?" "Why?" A bare "How?" on its own line. These manufacture suspense for information that needed none.

Same family, the stage cue that announces an arrival: "Enter Lockstep." "Cue the rewrite." "Spoiler: it doesn't."

Delete the setup and state the thing. "The result? Builds got faster." becomes "Builds got faster."

---

# Structural tells

The rules above catch AI-shaped sentences. These catch AI-shaped documents, where every paragraph is clean and the piece still reads as generated.

- **Preview and recap frame.** An intro announcing what the piece will cover, and a conclusion restating it. Cut both. Start with the first real thing, end with the last real thing. HARD.
- **A takeaway on every section.** Each section closing with a one-line lesson. Most sections should just stop. HARD.
- **Symmetric sections.** Every section the same length, each with the same number of subpoints. Real writing is lopsided, because the author cared more about some parts. STRONG.
- **Uniform paragraph architecture.** Every paragraph built topic sentence, then support, then transition. Individually fine, collectively a fingerprint. STRONG.
- **Question headings.** "What is X?" "Why does it matter?" "How do I get started?" The FAQ skeleton wrapped around something that is not an FAQ. STRONG.
- **Forced balance.** Equal weight to pros and cons regardless of which is actually true, because even-handedness reads as safe. If one side is right, say so. STRONG.
- **Imposed listicle.** "5 ways to X" when the piece is one argument that got chopped into 5. STRONG.

When the shape is the problem, fixing sentences will not help. Restructure first, then de-slop the prose.

---

# STRONG tendencies

- **Vary sentence length.** Machine text has metronome rhythm: every sentence mid-length, every paragraph three or four sentences, perfectly even. Real writing breathes unevenly. Short. Then longer. Then a fragment. Then a thirty-word sentence that earns its length. Check for runs of three sentences within five words of the same length.
- **Active voice and named agents.** "The system preserves results," not "results are preserved."
- **Contractions**, in voiced registers.
- **Direct address.** "I" and "you," in voiced registers.
- **Get to the point.** No warm-up laps. The first sentence should carry content.
- **Formatting like salt.** Headers, bullets, and numbered lists only when the content is genuinely enumerable. Prose is the default.
- **Numbers as digits.** 3 years, 10 tools, 500 users.
- **Start sentences with And, But, So, Like** when the logic calls for it. A new paragraph usually implies a "but" or a "therefore," even when the word is absent.
- **Stop when the point is made.** Length is not thoroughness.

# LIGHT preferences

Word choices, structural patterns, humor placement, where to put an aside. Content decides. Do not use the same opening formula every time just because it worked once.

---

# Craft: what fills the space

Removing tells leaves clean, lifeless prose unless something replaces them.

- **Be specific.** Numbers, names, dates, actual instances. Specificity is the whole game. Humor comes from it too: be unexpectedly precise.
- **Real examples over hypotheticals.** Point at something that happened. Never "imagine a scenario where."
- **Commit.** Take a stance. Model text reads like someone afraid to be wrong: everything "may," "could," "is often considered."
- **Hedge honestly, and only about yourself.** "I think," "probably," "I'm not sure," "kinda" are human and required where true. Three distinct things get confused here:
  - Honest first-person confidence ("I think this is the wrong call") → keep, use freely.
  - Stacked qualifier mush ("could potentially possibly be argued") → cut to one word or none.
  - Speculation about the world offered as fact-substitute ("the team likely struggled") → cut, or say you don't know.
- **Physical verbs for abstract processes.** Sanded down. Bolted on. Stripped back. Wedged in.
- **Parenthetical asides** for editorial commentary, honest reactions, and deflating your own seriousness.
- **Write lopsided.** One point gets four paragraphs, another gets a clause. Even weighting across sections is a machine habit.
- **Leave tension unresolved** where it is unresolved. Not every section needs a takeaway.

---

# Worked example

**Source:**

> In today's fast-paced development landscape, managing dependencies isn't just a chore, it's a
> critical bottleneck that can make or break your team's velocity. That's why we're thrilled to
> announce Lockstep, a groundbreaking new tool that revolutionizes how teams handle package
> updates. Lockstep serves as a comprehensive solution, seamlessly integrating with your existing
> workflow while providing unparalleled visibility into your dependency tree. The result? Teams
> report shipping faster, with fewer conflicts and greater confidence. Exciting times lie ahead.

**Rewrite:**

> Dependency updates are the slowest part of our week, so we built Lockstep.
>
> It reads the lockfile you already have, so there is nothing to migrate. And it flags which
> packages actually changed behavior, instead of just which ones changed version numbers.
>
> We have been running it internally and conflicts are down.

What that fixed, in order of appearance: "in today's" opener, negative parallelism ("isn't just a chore, it's a bottleneck"), "landscape" as abstraction, "thrilled to announce", "groundbreaking", "revolutionizes", copula avoidance ("serves as"), "seamlessly", "unparalleled", the fragment-question pivot ("The result?"), a rule of three ("faster, fewer conflicts, greater confidence"), and a generic upbeat close.

**The part that matters most.** The source claims "teams report shipping faster" with nothing behind it. The obvious rewrite is "conflicts dropped 40%", which reads far better and is a fabrication. There was no 40% in the source. So the rewrite keeps the weak claim weak: "conflicts are down."

When a vague sentence has no facts under it, you have three moves. Keep it vague, cut it, or ask the author for the real number. Inventing one is never on the list, however much better it reads.

---

# Do not flag: false positives

Over-editing is the failure mode that ruins human writing. These are not tells on their own:

- Professional grammar, correct spelling, consistent formatting.
- Formal or technical vocabulary used accurately.
- Mixed formal and casual register in the same piece.
- Dry, plain writing with no specific tells. Boring is not artificial.
- Salutations, sign-offs, and ordinary transitions in isolation.
- Curly quotes, which most editors insert automatically.
- A single em dash, or one short emphatic sentence used for real emphasis.
- Unsourced claims, which are ordinary across the web.
- A banned word appearing inside a quotation, proper noun, title, or as the subject under discussion.

**The cluster rule.** One isolated tell is not a finding. Look for clusters. Three of these in a paragraph means something. One of them in a page means a person wrote a sentence.

**The date check.** ChatGPT opened to the public on 30 November 2022. Text written before that was written by a person, whatever it looks like. If the source is dated, or quoted from something dated, check the date before diagnosing anything. Older prose is full of these patterns because models learned them from somewhere, and the somewhere was us. In audit mode this outranks every rule above: say the text predates the tooling and leave it alone.

# Preserve on sight

Leave these alone even when they look irregular. They are the evidence a person was here.

- Specific, unusual, hard-to-fabricate details.
- Mixed feelings and tensions the author never resolves.
- Dated references, era-bound slang, things that will age badly.
- Genuine asides, digressions, and mid-sentence self-corrections.
- Uneven rhythm and lopsided structure.
- Idiosyncratic habits, including ones this skill would otherwise discourage. Do not normalize a voice into compliance.

# Information mandate

Preserve the information, not the shape.

Every claim, name, number, date, quotation, and citation in the source survives the rewrite. When preserving information and improving prose pull in opposite directions, information wins. Never add a fact, a source, or a detail that was not there. A fabrication is a defect even when it reads more human than the vague sentence it replaced.

Compressing a dull passage is allowed. Dwelling where a person would naturally dwell is allowed. Reordering paragraphs, merging sections, and cutting a heading are allowed, because the shape is usually where the machine left its prints. Inventing is not.

What survives reordering is the hierarchy. If the source treats one point as the main event and another as an aside, that ranking holds in the rewrite even when the paragraphs move. Promoting a minor point to the top because it makes a better opening changes the argument, and that counts as changing the meaning.

---

# Self-check before delivering

Mandatory in every mode, including embedded. These patterns are what fluent generation produces by default, so they are only ever caught on reread. Answer all three against your own output:

1. **What still marks this as AI-generated?** Scan specifically for negative parallelism, em dashes, participle padding, and rule-of-three. Those four survive most first passes.
2. **Does it state any fact, name, number, date, or citation that is not in the source?** If yes, remove it.
3. **The litmus test.** Does this sound like something the author would actually write, or like a machine working hard to imitate them? If it feels forced, pull back. Inhabit the voice instead of performing it.

Fix what you find, then deliver. Do not report the self-check unless you are in audit mode.

# Audit output

Rewritten text first. Then:

```
### Changes

| Where | Tell | Fix |
|-------|------|-----|
| ¶2 | Negative parallelism | Deleted the negated half, kept the claim |
| ¶5 | Participle padding | Cut "underscoring its importance" |

Left alone: <anything that looked like a tell but was the author's voice>
```

Keep the log short. Group repeated fixes into one row with a count.

# Rules

- Never change what the text means in order to make it sound better.
- Never mechanically find-and-replace. Swapping every em dash for a comma is its own tell, and so is deleting every instance of a banned word without rereading the sentence.
- Do not over-correct into choppy terseness. That is the other failure mode and it is just as recognizable.
- In generate mode, deliver the piece alone. No preamble about what you wrote, no offer to revise.
- If the user's own voice profile contradicts a rule here, the profile wins.
