# Step 03 · stopword filter

**Milestone:** 1 · **Needs:** 01 · **Covers:** AC-03

## Goal
A `filter_stopwords(pairs)` function that drops English stopwords from `(word, count)` pairs.

## Files touched
- `stopwords.py`: new
- `test_stopwords.py`: new

## Tests to write first
- `test_drops_stopwords`: [("the", 5), ("cat", 2)] gives [("cat", 2)]
- `test_keeps_order`: the remaining pairs keep their original order

## Implementation notes
Stopwords: the, a, an, and, of, to. Not wired into the CLI in this step.

## Verify
`python3 -m unittest -q` → OK

## Done when
- Both tests pass.
