# human-write-time v2: design

Date: 2026-09-29
Status: approved in conversation, implementing

## Problems

1. `human-write-time/SKILL.md` is 24,351 characters. Claude Code re-injects an invoked skill after compaction up to about 5k tokens (~17.5k characters), so the tail (self-check, audit format, rules) is lost in long sessions, including `project-wrap`, which loads it to write recaps.
2. Output still reads as AI, subtly (user report).
3. Output doesn't sound like the author even with `~/.claude/VOICE.md` loaded (user report).

## What the research says (sources in the conversation record)

- Ban lists backfire: named phrases get primed, banned words get synonym-swapped, the not-X-but-Y shape returns in disguise. A one-line goal instruction cut epanorthosis by half to three quarters; the stated target is the human rate, not zero (Boggia 2026; Antislop, ICLR 2026).
- Some current rules create tells: "vary sentence length" breeds dramatic fragments; "active voice" is wrong (humans use agentless passives about twice as often as GPT-4o, Reinhart et al. PNAS 2025); banning em dashes pushes colons and semicolons.
- Newer tells are missing: arguing with no one, method narration, invented concept labels, "That distinction matters." closers, Claude-isms (load-bearing, quietly, genuinely, "It <verb>s no <noun>").
- Voice imitation of informal writing is the hard case (17–44% authorship accuracy vs 86–97% for news) and drifts to a generic register. What helps: samples first as continuation context, contrastive neutral-vs-original pairs, measured stylometry rather than impressions, drafting from the author's material rather than polishing a generic draft, and making every generic "sound human" default conditional on the samples.
- Italian has its own tells (connectives inoltre/tuttavia/in conclusione, "In un mondo sempre più", epanorthosis near 3x in oratory) and some English rules don't transfer.
- The author's own `VOICE.md` Sections 2 and 3 repeat the generic defaults and contradict the samples (contractions, fragments, physical verbs, paragraph length, active voice). The skill must let samples outrank stated rules, and the user decides whether to prune the profile.

## Design

Files:

```
human-write-time/
  SKILL.md                 core, target ~10k characters, hard limit 17.5k
  references/tells-en.md   English catalogue: tells by strength, fixes, before/after pairs, backfires
  references/tells-it.md   Italian catalogue
  scripts/voice_stats.py   stylometry of samples vs draft
tools/test_voice_stats.py  tests
```

Core principles, stated early in SKILL.md:
- Match the author's rate, not zero.
- Write from the goal and the samples; scan against the catalogue after drafting, never before.
- Samples outrank rules, the profile's included.

Flow for voiced registers:
1. Register check (unchanged).
2. Voice source (unchanged order) plus matching by language and register.
3. Voice card: run `voice_stats.py` on the matching samples; write a neutral paraphrase of 2 or 3 samples and list what the author does that the neutral version lacks; result is 5 to 8 traits including what the author never does. The card overrides every generic default; the draft never gains a feature the samples lack.
4. Draft from the author's material with samples first, framed as continuing the author's writing.
5. Review pass: read the catalogue for the draft's language, hunt shapes, run `voice_stats.py` on the draft against the samples, revise what's out of range.
6. Self-check: surviving shapes, facts not in the source, stats in range, features the samples lack.

The core keeps: modes, register check, the strongest tells (one sighting counts), craft, information mandate, false positives and the date check, self-check, audit output, rules. Rule changes: active voice to light; "vary sentence length" becomes "let content vary it"; dashes removed by restructuring, never by colon or semicolon swaps, strong for Claude and Italian conventions for Italian; elegant variation and false ranges to weak-alone. Less markdown in the core itself.

`voice_stats.py`:
- Inputs: `--voice PATH` (extracts `### Sample:` sections of a VOICE.md: body lines after the heading, skipping HTML comments, up to the first line starting with `**` or the next heading), `--sample PATH` (repeatable, whole file), `--draft PATH`, `--lang auto|en|it`.
- Samples are filtered to the draft's language when any match.
- Metrics per text: sentence length mean, spread, share under 8 and over 30 words; sentences per paragraph; per 1,000 words dashes, colons, semicolons, parentheses, questions, exclamations, ellipses; contractions (English); share of sentences opening with a conjunction (And/But/So, E/Ma/Quindi/Però); first-person rate.
- Output: a markdown table with the samples' range, the draft value, and a flag when the draft falls outside the range widened by a margin. Without `--draft`, prints the samples' profile.
- Standard library only.

## Verification

- `tools/check_skills.py human-write-time` passes (size, frontmatter).
- `tools/test_voice_stats.py` passes.
- A/B: for 3 of the author's samples, produce a neutral paraphrase, then have the old skill (from `main`) and the new one rewrite it in the author's voice through `claude -p`. Compare each against the original with `voice_stats.py`, and give the user the pairs blind to judge. Also count one-sighting tells in each output.
