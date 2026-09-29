# Step 02 · top option

**Milestone:** 1 · **Needs:** 01 · **Covers:** AC-02

## Goal
`python3 wordfreq.py FILE --top N` prints the N most frequent words.

## Files touched
- `wordfreq.py`: parse `--top` with argparse in `main`
- `test_cli.py`: new

## Tests to write first
- `test_top_option_limits_output`: `main` on a temp file with `--top 2` prints exactly two lines
- `test_default_is_ten`: a file with 12 distinct words prints ten lines

## Implementation notes
Keep `top_words` unchanged; only `main` changes. Capture output with `contextlib.redirect_stdout`.

## Verify
`python3 -m unittest -q` → OK

## Done when
- Both tests pass, and step 01's tests still pass.
