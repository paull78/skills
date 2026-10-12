# English tells: the review-pass catalogue

Read this after drafting, never before. Naming a phrase primes it, so the draft is written from the goal and the samples, and this list is for hunting what got through.

How to use it:

- Hunt shapes, not strings. A banned word swapped for a synonym is the same tell ("tapestry" to "mosaic", "it's important to note" to "keep in mind", "earns its place" to "is worth keeping"). A not-X-but-Y rewritten into two sentences is still not-X-but-Y.
- Calibrate, don't eliminate. The target is the author's rate, which for most shapes is low but not zero. People use contrast, triads and dashes too; machines use them everywhere.
- Section A tells count on one sighting. Everything else counts only in clusters: three in a paragraph means something, one on a page means a person wrote a sentence.
- A banned word used in its literal sense is fine. "Robust standard errors" is statistics, "harness" is equipment, "align the columns" is an instruction.

## A. Strong: one sighting is a defect

### A1. Not X but Y, in every costume

Negating a framing nobody held so the correction sounds profound. The most measured tell there is: up to 6 times the human rate in some models, near 3 times in Italian oratory.

Shapes: "It's not X, it's Y." "Not X. Y." "This isn't about X. It's about Y." "Not only X, but also Y." "Less X, more Y." "Stop X. Start Y." "You don't need X. You need Y." "The question isn't X." "Y rather than X" (in the posture sense). "It <verb>s no <noun>" ("It asks no permission"). Split across sentences: "This does not mean every choice is equal. It means..." Disguised: "While X might seem right, Y is actually...", "Sure, X works. But Y is where...", "X gets the attention, but Y is what actually...". Tail form: "...with no guessing, no setup, no friction."

Fix: delete the negated half. If the sentence survives as "I think Y" with nothing lost, X was a dummy.

> Before: This does not mean every choice is equal. It means there is no external system that confirms which choice is right.
> After: No external system confirms which choice is right, although the choices still have different consequences.

Keep the contrast when the reader really holds X (a hiring manager who assumes you'd be "adjusting"), or when X is the author's own former view, stated as a revision.

### A2. Dramatic closers and fragment rows

A one-line paragraph that lands the moral. A row of fragments. "The result?" "The catch?" "Why?" standing alone. "Enter X." "Spoiler: it doesn't." "That distinction matters." "And that changes everything." A sentence explaining the example the reader just read.

> Before: It had no preference for symmetry. No aesthetic prior. No nostalgia for human taste. The old rules were gone.
> After: AlphaEvolve changed the search because it did not favor symmetry or human-looking designs.

Fix: fold the point into the sentence that earns it, or stop one sentence earlier.

**The payoff tail** is the same move inside one sentence: a long description of the thing, a comma, then a clause that lands its moral. ", and then measuring whether each piece earns its place." ", then seeing what actually holds up." ", and asking whether any of it was worth it." ", to find out what survives contact with real data." The sentence had already said what the thing is; the tail tells the reader how to feel about it, usually by awarding the project a virtue (rigour, honesty, restraint). The "and then" plus a gerund is the usual hinge, but a "to" infinitive, a past participle (", and then stress-tested against...to see what holds up") or a bare ", asking" does the same job.

> Before: ...a from-scratch, dependency-light study in building a production-shaped RAG pipeline on a strict Clean Architecture skeleton, and then measuring whether each piece earns its place.
> After: ...a RAG pipeline built from scratch, with few dependencies, on a strict Clean Architecture skeleton. The pipeline is then measured with and without each component.

Fix: stop at the thing, or give the second act its own sentence with a subject, a finite verb and the concrete object (what is measured, against what). Trading "earns its place" for "is worth keeping" or "justifies itself" leaves the tail intact.

### A3. Aphorisms and invented concept labels

"X is the Y of Z." "The best X is the one you actually Y." "Symmetry is the language of trust." Coined labels: "the supervision paradox", "the acceleration trap", "scope creep of the soul". "Where the complexity actually lives."

> Before: Symmetry is the language of trust.
> After: Symmetric layouts often feel more predictable to users.

Fix: say the concrete claim underneath. If there is none, cut.

### A4. Staged run-up and staged candor

"Here's the thing." "Look," "Honestly?" "Let's be real." "Let's break this down." "Here's what nobody tells you." "Worth stating plainly." "Honest take:" "And yes, I'm openly obsessed with..." (false vulnerability).

> Before: Is it worth the price? Honestly? It depends on how often you'll use it.
> After: Whether it's worth the price depends on how often you'll use it.

### A5. Arguing with no one, method narration, reasoning leaks

Rebutting an alternative nobody proposed: "A tempting approach would be to X, but...", "I'm not saying X." Narrating the method instead of doing it: "Anything unconfirmed is flagged rather than guessed." "What it changes is worth being precise about." "To be clear," "Let me be precise."

Fix: state the actual design or finding. Cut the performance of carefulness.

### A6. Preview, recap, tie-back

An intro announcing what the piece covers. A conclusion restating it. Summaries at every level. "So, to answer your question: yes." "In summary." "Ultimately." "At the end of the day."

Fix: start with the first real thing, stop after the last one.

### A7. A takeaway on every section

Each section closing with a one-line lesson. Most sections should just stop.

### A8. Chat residue and sycophancy

"Great question." "Certainly!" "You're absolutely right." "I hope this helps." "Let me know if you'd like..." "Would you like me to..." Cutoff disclaimers: "As of my last update", "based on available information".

### A9. Invented specifics

A number, name, quote, source or anecdote that was not in the material. The most damaging tell because it reads human. "Conflicts dropped 40%" when the source said "conflicts are down" is a fabrication, however much better it reads.

## B. Lexical: clusters only

The vocabulary drifts with each model generation, so treat these as families, not a list to grep.

- Style words, 2023 to mid-2024: delve, intricate, meticulous, tapestry, testament, vibrant, realm, landscape (abstract), interplay, pivotal, crucial, showcase, underscore, foster, garner, navigate (metaphorical), Additionally.
- Mid-2024 onward: align with, enhance, fostering, emphasizing, highlighting, showcasing, seamless, robust, leverage, holistic, streamline.
- Hype: revolutionize, game-changer, cutting-edge, groundbreaking, unlock, unleash, supercharge, transformative, unprecedented.
- Puffery: unparalleled, renowned, breathtaking, stunning, nestled, iconic, commendable, visionary.
- Claude-isms: load-bearing, quietly, genuinely, plainly, seam, sidecar, surface (as a verb), provenance, shipped, belt and suspenders, smoking gun, "that's the unlock", "and the trap is", "carry the argument", "X makes itself", "full stop".
- Merit idioms for parts of a system: "earns its place", "earns its keep", "pulls its weight", "pays for itself", "does the heavy lifting", "does real work", "has to justify itself", "whether X *actually* helps" (the "actually" is the posture). The component is awarded a virtue instead of a measurement. Say what it does or what was measured, or cut. Models also hand a project a stance toward itself ("honest about", "unapologetically", "opinionated"), which is the same move one level up.
- Coinages: "-shaped" ("production-shaped", "problem-shaped", "the shape of the work"), and "-light", "-first", "-grade", "-aware", "-heavy", "-native", "zero-" compounds built for the sentence. Genre frames borrowed from essays and art and dropped on a technical project: "a study in X", "an exercise in X", "a meditation on X", "a love letter to X". Use the plain description: "built from scratch with few dependencies", "like a production system".
- Throat-clearing: "it's worth noting", "it's important to note", "what makes this interesting is", "at its core", "the real question is".
- Dead transitions: furthermore, moreover, additionally, that said, with that in mind. (Check the author: "Moreover" can be theirs.)
- Bloat: "in order to", "due to the fact that", "at this point in time", "a wide variety of".
- Latinate register: long words where short ones do. Zombie nouns ("the implementation of the optimization") where a verb was hiding. Models use about twice the human rate of nominalizations.

Fix: the plain word, or the verb. Never a synonym of the same weight.

## C. Syntactic

- Participle tails: ", highlighting its importance", ", reflecting broader trends", ", symbolizing the shift". Measured at 5 times the human rate. Cut, or give the claim its own sentence. When the tail is coordinated (", and then measuring whether...") and lands a moral, it is the payoff tail in A2 and counts on one sighting.
  > Before: ...symbolizing Texas bluebonnets, the Gulf of Mexico, and the diverse Texan landscapes, reflecting the community's deep connection to the land.
  > After: ...colors meant to evoke Texas bluebonnets and the Gulf of Mexico.
- Hyphen stacks: two or more hyphenated compound modifiers on one noun. "a from-scratch, dependency-light study", "a small, dependency-free, single-file script", "a production-shaped, test-first pipeline". One compound is ordinary English (section G), and domain terms used literally ("type-safe", "schema-first", "open-source") don't count toward the stack; the stack is a sentence's worth of claims packed into adjectives built for the occasion. Unpack those into phrases or a clause: "built from scratch, with few dependencies".
- Colon-appositive openers: a short label, a colon, then a long appositive that carries the whole content. "This is a personal learning project: a from-scratch, dependency-light study in building..." Common as the first line of a README, bio or product page. The colon splices a second sentence onto the first and leaves the project without a verb. Give the appositive its own sentence: "This is a personal learning project. It builds..."
- Copula avoidance: "serves as", "stands as", "boasts", "features", "represents". Say is, has.
  > Before: Gallery 825 serves as the gallery's exhibition space, features four separate spaces and boasts over 3,000 square feet.
  > After: Gallery 825 is the gallery's exhibition space. It has four rooms totaling 3,000 square feet.
- Vague connection: "associated with", "linked to", "tied to", when the relation is known. Name it.
- Repeated openings: three sentences in a row starting the same way. Merge or change the subject.
- Compulsive counting: "Two constraints shape the design." "Three things matter here." Just give them.
- Rapid-fire analogy rows: "Apple didn't build Uber. Facebook didn't build Spotify."

## D. Structural

When the shape is the problem, fixing sentences won't help. Restructure first.

- Triads at every scale: three adjectives, three phrases, three examples, three bullets. Keep three when there are three; otherwise use the real number.
- Metronome rhythm: every sentence in the 14 to 22 word band, every paragraph 3 or 4 sentences. The fix is content, not decoration: a long sentence that carries a real list, a short one where the point really is short. Don't manufacture fragments; they are tell A2.
- Symmetric sections, same length and same number of points each.
- Uniform paragraph architecture: topic sentence, support, transition, every time.
- Forced balance: equal weight to both sides when one is right.
- Question headings on something that isn't an FAQ. Headings written for effect ("The decision, on one screen").
- Imposed listicle: one argument chopped into "5 ways".
- In replies: the decision buried after re-explaining context the reader already has. Put the answer first.

## E. Tonal

- Significance inflation: "a pivotal moment", "marking a shift toward", "setting the stage for", "left an indelible mark". State the fact.
- "Despite these challenges, X continues to thrive." Template section endings.
- Borrowed notability: logos, follower counts, "trusted by teams at", "as featured in" stacked to impress.
- Vague attribution: "experts say", "studies show". Name the source or cut the claim. Never invent one.
- Stacked qualifiers ("could potentially be argued"). Note that models use fewer real hedges and opinions than people do, so honest first-person stance ("I think this is wrong") is a human marker, not a tell.
- Gap-filling guesses dressed as knowledge: "the team likely struggled", "she probably grew up".
- Sales register in a technical or personal text.
- Modesty as a run-up: "a personal learning project", "a weekend experiment", "a small side project", "a humble attempt", hinged to a spec sheet of production features in the same sentence. The humble label is a fact about how the thing was made; the hinge is the posture. Keep both facts, drop the hinge: the label in one sentence, what the thing does in the next, without the colon or the "but".
- Creative prose: ghosts, whispers, the "soft hum" of anything, silence that "speaks", abstractions given senses (grief that "tastes").

## F. Formatting

Models use headers and bullets tens of times more than human baselines, and semicolons, parentheses and ellipses far less.

- Title Case In Headings: use sentence case.
- Bold-label bullets (a bold term, a colon, a sentence) where prose would do.
- Mechanical bolding of every term.
- Emojis and arrows as markers. Horizontal rules between every section.
- A heading restated in the first line under it.
- Lists where the content isn't enumerable. Prose is the default.
- Curly quotes the platform didn't generate.

## G. Weak alone

Count these only alongside stronger tells. They are ordinary human writing on their own.

- Em dashes. Claude still overuses them (about 9 per 1,000 words against a human 3), so remove them in Claude output, but a text without dashes proves nothing and one dash proves nothing. Remove by restructuring: split the sentence, or use and, but, so, or parentheses where the author uses them. Never swap every dash for a colon or semicolon; that's a Claude-ism too ("X exists in theory; in practice, Y").
- Passive voice. People use agentless passives about twice as often as GPT-4o. Don't convert them on principle.
- Elegant variation (synonym cycling) and false ranges ("from startups to enterprises"). Newer models rarely do either; treat them as historical.
- Hedges, a single hyphenated compound (the stack is section C), curly quotes, formal vocabulary used accurately.

## H. Fixes that backfire

1. Swapping dashes for colons or semicolons. Restructure instead.
2. Swapping banned words for synonyms. Say the plain thing or cut.
3. "Vary sentence length" producing dramatic fragments. Let the content vary it.
4. "Use active voice" everywhere. Keep the passives a person would keep.
5. "Be specific" producing invented numbers. Specifics come from the material or not at all.
6. "Add personality" producing staged candor, "Look,", fake asides and false vulnerability. Voice comes from the samples, not from a personality checklist.
7. "Use two or four instead of three" becoming its own tic. Use the real count.
8. Deliberate typos or errors to seem human. They cost credibility and don't fool careful readers.
9. Polishing a generic draft into the author's voice. The result stays closer to the model than to the author. Draft from the author's material and samples instead.
10. Beating detectors as a goal. The goal is prose a careful reader trusts.
