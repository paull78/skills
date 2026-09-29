---
name: human-write-time
description: Write human-facing prose that sounds like its author and not like a model, and de-slop drafts that don't. Measures the author's voice from real writing samples and lets them outrank generic rules, hunts machine tells after drafting (negative parallelism, staged closers, aphorisms, puffery, chatbot residue, invented specifics) in English and Italian, and never adds facts. Use when writing or editing blog posts, essays, newsletters, emails, social copy, landing pages, READMEs, docs, release notes, recaps, or marketing copy, and whenever the user says "human-write-time", "make this sound human", "make this sound like me", "de-slop this", "humanize this", "this reads like AI", or complains that a draft sounds LLM-generated. Not for code, commit messages, or chat replies.
---

# Human Write Time

Write prose a careful reader would believe a person wrote, and that the author would recognise as theirs. Repair prose that fails either test.

Two layers, kept separate. The de-slop layer removes machine tells and applies to all human-facing prose. The voice layer makes the text sound like one particular author, and applies only when there is a voice to match and the register calls for one. Most failures come from applying the second where only the first belongs, or from replacing the author's habits with a generic "human" style.

Three principles run through everything below:

1. **Match the author's rate, not zero.** People use contrast, lists of three, dashes and short sentences too. Models use them everywhere. The target is how often *this author* does it.
2. **Write from the goal and the samples, then scan.** Don't draft with a list of banned phrases in view: naming a phrase primes it. The catalogues in `references/` are for the review pass after drafting.
3. **Samples outrank rules.** A paragraph the author actually wrote beats any stated preference, including this file's and including rules written in the author's own profile.

## Modes

| Mode | Trigger | Deliver |
|---|---|---|
| Generate | Asked to write something new | The piece only |
| Audit | Handed an existing draft, file or paste | The rewrite, then the change log |
| Embedded | Loaded inside a larger task | Final text only, no commentary |

In file mode, rewrite the file in place with the final version only. Leave code blocks, frontmatter, data and link targets untouched, and report a short summary in conversation.

## 1. Register

Neutral registers (reference docs, API docs, specs, legal text, encyclopedic writing, changelogs): plain and voiceless is the human register. Apply the de-slop layer only. Don't inject first person, opinion, humor or personality; that makes a reference doc worse and more obviously generated.

Voiced registers (essays, posts, newsletters, emails, memos, recaps, opinion, social, most marketing): both layers. If a text sits between the two, stay closer to neutral.

## 2. Voice source

For voiced registers, take the first that exists:

1. A path or sample the user gives in the request.
2. `VOICE.md` or `.claude/VOICE.md` in the current repo: the project's house voice, which wins for anything published under that project.
3. `~/.claude/VOICE.md`: the author's personal voice, everywhere else.
4. Surrounding context: the rest of the document, the thread, the repo's existing prose.
5. Nothing: ask for one sample of the author's writing before drafting. Don't invent a house style.

Within the source, pick the samples that match the target language first and the register second. An Italian email is matched against Italian samples, a company memo against the memo. The profile's notes on the register ("By context" sections and the like) apply too, but where a stated rule and the samples disagree, follow the samples.

## 3. Voice card

Before drafting a voiced piece, build a private voice card. It's the fix for output that sounds human but like someone else.

1. **Measure.** Run the stats script on the matching samples:
   `python3 <this skill's folder>/scripts/voice_stats.py --voice ~/.claude/VOICE.md --lang <en|it>`
   (or `--sample <file>` for samples that aren't in a VOICE.md). Note the ranges: sentence length and spread, sentences per paragraph, punctuation per 1,000 words, contractions, conjunction openers, first-person rate.
2. **Contrast.** For two or three samples, write a one-paragraph neutral paraphrase in plain assistant prose, then list what the author does that the neutral version lacks. Their word order, the connectors they reach for, how they open, where they put the point, what they repeat instead of varying, which imperfections they keep.
3. **Write the card.** Five to eight traits in the author's terms, each with a quoted example, plus the things the samples never do.

The card overrides every generic default. Contractions, direct address, parenthetical asides, short sentences, paragraphs opening with And or But: use each only if the samples show it, and at their rate. **Never introduce a feature the samples lack.** If the author never asks rhetorical questions, the draft has none; if their paragraphs run to four sentences, so do the draft's.

With no voice source and a voiced register, fall back to plain human defaults: get to the point in the first sentence, name the agent, prose over bullets, digits for numbers, stop when the point is made.

## 4. Draft

Draft from the author's material: the brief, notes, facts, opinions and anecdotes they gave you. Don't write a generic draft and then "voice" it; edits anchor on the draft, and the result stays closer to the model than to the author.

Put the matching samples in front of you as the text you're continuing, not as rules to satisfy. Write the piece as the next thing this author wrote.

What makes prose human, beyond avoiding tells:

- **Specifics from the material.** Names, numbers, dates, real instances. Specificity is the whole game, and it only ever comes from the source.
- **A stance.** Commit where the material supports it. Hedge honestly and in the first person ("I think", "probably") where the author is unsure; never stack qualifiers.
- **Lopsided weight.** One point gets four paragraphs, another a clause, because the author cares more about one.
- **Unresolved tension** where it is unresolved. Not every section needs a takeaway.
- **Rhythm from content.** A long sentence that carries a real list, a short one where the point is short. Never manufacture fragments for effect.
- **Ordinary words, repeated.** Use the name again rather than cycling synonyms.

## 5. Review pass

After drafting, read the catalogue for the draft's language: `references/tells-en.md` or `references/tells-it.md`. Hunt shapes, not strings: a banned word swapped for a synonym, or a not-X-but-Y split across two sentences, is the same tell.

These count on one sighting, and they're the ones that survive first passes:

- **Not X but Y** in any costume: "It's not X, it's Y", "Not only X but Y", "Stop X. Start Y", "Y rather than X", "It asks no permission", the version split across two sentences, the tail ", no guessing, no friction". Delete the negated half, unless the reader really holds X or X is the author's own former view.
- **Dramatic closers and fragment rows**: a one-line moral, "The result?", "Enter X.", "That distinction matters."
- **Aphorisms and invented concept labels**: "X is the language of Y", "the acceleration trap".
- **Staged run-ups and staged candor**: "Here's the thing", "Honestly?", "Look,", "Worth stating plainly".
- **Arguing with no one and method narration**: "A tempting approach would be...", "Anything unconfirmed is flagged rather than guessed."
- **Preview, recap and a takeaway on every section.**
- **Chat residue**: "Great question", "I hope this helps", "Let me know if".
- **Em dashes in Claude output**: remove them by restructuring (split the sentence, use and/but/so, or parentheses if the author uses them). Never swap them all for colons or semicolons. In Italian, follow the author's punctuation, including spaced en dashes if they use them.
- **Invented specifics**: any fact, number, name, quote or source not in the material.

Everything else in the catalogues counts only in clusters: three in a paragraph means something, one on a page means a person wrote a sentence.

Then check the voice in numbers: save the draft and run the script with `--draft <file>` against the same samples. Revise anything flagged out of range, then run it again. Treat the flags as evidence, not law: a short piece has noisy numbers, and a flag on a metric the brief itself explains (a list of questions the user asked for) can stand.

## Information mandate

Preserve the information, not the shape. Every claim, name, number, date, quotation and citation in the source survives. Never add one. A fabrication is a defect even when it reads more human than the vague sentence it replaced: when a vague sentence has no facts under it, keep it vague, cut it, or ask the author.

Reordering paragraphs, merging sections and cutting headings are allowed, because the shape is usually where the machine left its prints. What survives reordering is the hierarchy: if the source treats one point as the main event and another as an aside, that ranking holds.

## Leave alone

Over-editing ruins human writing. These are not tells on their own: correct grammar, formal vocabulary used accurately, mixed registers, dry plain writing, ordinary transitions, a single dash, one short emphatic sentence, passive voice, unsourced claims, a flagged word inside a quotation or a name.

Preserve on sight: specific hard-to-invent details, unresolved mixed feelings, dated references, asides and self-corrections, uneven rhythm, and the author's idiosyncrasies, including spelling and punctuation habits and non-native constructions that are clearly theirs. Don't normalise a voice into compliance.

The date check: ChatGPT went public on 30 November 2022. Text written before that was written by a person whatever it looks like. In audit mode, check the date first; if the text predates the tooling, say so and leave it alone.

## Self-check before delivering

Mandatory in every mode, including embedded, because these patterns are what fluent generation produces by default and only a reread catches them:

1. Which one-sighting tells from section 5 are still there? Look hardest for not-X-but-Y, closers, dashes and invented specifics.
2. Does the text state any fact, name, number, date or source that isn't in the material? Remove it.
3. For a voiced piece: is every metric in range, and does the draft do anything the samples never do?
4. Does it sound like something this author would write, or like a model working hard to imitate them? If it feels performed, pull back toward the samples.

Fix what you find, then deliver. Report the self-check only in audit mode.

## Audit output

The rewritten text first, then a short log:

```
### Changes
| Where | Tell | Fix |
|---|---|---|
| ¶2 | Not X but Y | Deleted the negated half |
| ¶4 (x3) | Participle tail | Cut the tails |

Voice: <metrics that moved into range, or "n/a">
Left alone: <things that looked like tells but are the author's>
```

Group repeated fixes into one row with a count.

## Rules

- Never change what the text means to make it sound better.
- Never find-and-replace. Every change is a rewrite of the sentence, reread in place.
- Don't over-correct into choppy terseness; that's the other recognisable failure.
- In generate mode, deliver the piece alone: no preamble, no offer to revise.
- When the author's samples contradict a rule here, the samples win.
