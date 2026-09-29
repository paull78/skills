# Spec: wordfreq

Cycle: wordfreq · Type: project · Branch: main · Status: approved

## Goal
A command-line tool that prints the most frequent words in a text file.

## Scope and non-goals
In scope: counting, a `--top` option, a stopword filter module. Out of scope: other languages, stemming.

## Behaviour
`python3 wordfreq.py FILE` prints `word count` lines, most frequent first, ties alphabetical.

## Acceptance criteria
- AC-01 · Words are counted case-insensitively, ties broken alphabetically, top 10 by default.
- AC-02 · `--top N` prints the N most frequent words instead of 10.
- AC-03 · `filter_stopwords(pairs)` drops the stopwords the, a, an, and, of, to from a list of (word, count) pairs.

## Testing approach
Unit tests with the standard library.
Test command: `python3 -m unittest -q`

## Open questions
- none
