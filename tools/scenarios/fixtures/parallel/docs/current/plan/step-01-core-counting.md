# Step 01 · core counting

**Milestone:** 1 · **Needs:** none · **Covers:** AC-01

## Goal
`top_words(text, n)` and a CLI that prints the 10 most frequent words of a file.

## Files touched
- `wordfreq.py`: new, counting and CLI
- `test_wordfreq.py`: new

## Tests to write first
- `test_counts_case_insensitively`: "The the THE cat" gives the 3, cat 1
- `test_breaks_ties_alphabetically`: "b a" gives a before b
- `test_limits_to_n`: n=2 returns two pairs

## Implementation notes
Regex `[a-z']+` on the lowercased text, `collections.Counter`, sort by count descending then by word.

## Verify
`python3 -m unittest -q` → OK

## Done when
- The three tests pass.
