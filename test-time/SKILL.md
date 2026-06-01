---
name: test-time
description: Write tests, add test coverage, or evaluate and strengthen an existing test suite — going far beyond happy-path examples to actually find bugs. Use this whenever the user wants to write or add tests for any code, harden or improve a test suite, fuzz something, find bugs through testing, or review and strengthen the tests on a PR or branch before merging. This includes plain everyday requests like "write tests for this", "add test coverage for utils/x.py", "are these tests any good?", "make these tests more thorough", or "write tests that would catch this bug" — reach for it even when the user never says "fuzz", "edge case", or "property test". Under the hood it applies aggressive techniques: black-box testing through public APIs, randomized/fuzz testing with guided inputs, invariants and properties instead of fixed outputs, reference-implementation oracles, corner cases at critical thresholds, malformed inputs, and stress testing at scale. Strongly prefer this over writing tests directly — the entire point is to test more aggressively than the default. Not for debugging a failing or flaky test, configuring CI or a test runner, or wiring up mocks — those are other tools.
---

# Test Time

Tests exist to **find bugs now, catch regressions later, and let you refactor without fear.** They are not a coverage ritual or a checklist. A test that can never fail is dead weight; a test that only passes the inputs the author already thought of barely earns its keep.

The default instinct — "write a few tests for the happy path" — produces weak suites. This skill exists to push hard in the opposite direction: test *behavior* through public APIs, throw *enormous variety* at the system, and check *invariants* rather than memorized outputs. The goal is to maximize the number of distinct states you exercise, especially the fragile ones, not to color in coverage lines.

## Two modes

1. **Write a new test set** — for a module, library, feature, or whole system.
2. **Evaluate and improve an existing test set** — typically when reviewing a PR or branch. Diagnose where the suite is weak, then actually strengthen it (don't just grade it).

Both modes draw on the same toolbox below. Figure out which mode you're in from the request, then follow the matching process.

## The philosophy (read this first — it's the *why*)

- **Test behavior, not implementation.** Go through the public API the way a real caller would. Don't reach into private functions or internal data structures. A suite wired to internals breaks on every refactor and gives false confidence; a suite wired to observable behavior survives refactors and tells you when the *contract* broke. Bonus: exercising the API also exercises everything underneath it.
- **Derive expected results from the spec, never from the running code.** This is the subtle trap that quietly defeats most test-writing: you run the function, see what it returns, and write `assert f(x) == <whatever it just returned>`. That test can *never* catch a bug — it asserts the implementation against itself, so it passes even when the behavior is wrong, silently blessing the defect as "correct." Always ask "what *should* this return, per the contract/spec/docstring?" and assert that. If the spec and the code disagree, your test should go **red** — that red is the bug report. A failing test that exposes a real contract violation is a success, not something to soften. Never edit a test to match surprising output until you've confirmed the output is actually correct.
- **States explored beats lines covered.** 100% line coverage with three fixed inputs is weak. The real question is: *how many distinct states am I putting the system into, and am I hitting the fragile ones?* Variety is the metric that matters.
- **Invariants beat fixed outputs.** Asserting `f(input) == "exact string"` only checks one case and is brittle. Asserting a property that must hold for *every* input lets you fire thousands of inputs at one assertion.
- **Knowing the implementation makes you a better black-box tester.** Read the code to find the thresholds, branches, and special cases — then attack them through the public API. This isn't a contradiction: you stay black-box at the interface, but you aim your inputs with inside knowledge.
- **A good suite is a safety harness for change.** It should be severe, fast, and reproducible enough that you (or an LLM) can refactor aggressively and trust a green run to mean "no regression."

This skill deliberately diverges from test-first / TDD: it assumes the implementation exists (or is being written) and uses knowledge of its real structure to target tests. If the user explicitly wants test-first red-green-refactor, use the `tdd` skill instead.

## The toolbox (techniques both modes use)

Reach for as many of these as fit the target. The first four are where most of the bug-finding power lives.

### Randomized / fuzz testing with *guided* inputs
Fixed example inputs explore a handful of states. Randomized inputs that change every run explore the space. But **pure random noise is weak** — it rarely reaches the interesting states (a random byte stream is almost never valid JSON). Bias the generator toward structure and richness:
- Generate *valid-ish* inputs that reach deep code paths, then also corrupt them.
- Oversample inputs that trigger special cases (e.g. for a compressor, generate data with repeats and patterns, not just uniform noise).
- Mutate and **crossover** a corpus of known-good inputs (bit flips, byte flips, splicing two valid documents together).
- **Always seed the RNG and print the seed** (and the failing input) on failure — a fuzz failure you can't reproduce is nearly worthless. Prefer a framework that shrinks failures to a minimal case.

### Invariants and properties
Instead of "this input produces this output," assert things that must be true for *all* inputs. Common families (look for these in any target):
- **Round-trip:** `decode(encode(x)) == x`, `parse(serialize(x)) == x`.
- **Idempotence:** `f(f(x)) == f(x)`.
- **Oracle / equivalence:** optimized path agrees with the simple path (see below).
- **Conservation:** nothing created or lost — counts, sums, set membership preserved.
- **Order independence / commutativity** where the contract promises it.
- **Postconditions:** sorted output is actually sorted; size after insert is size+1; a `get` after `put` returns what was put.
- **Never crashes / never leaks:** on *any* input — valid, malformed, or hostile — the system fails gracefully rather than corrupting state or crashing.
- **Metamorphic relations** when there's no exact oracle: a known transform of the input produces a predictable change in the output (resize an image and quality stays within bounds; add an irrelevant document and the top search result is unchanged).

### Reference-implementation oracle (model-based testing)
When the real implementation is complex, build a dead-simple, obviously-correct version *inside the test* (e.g. a plain hash map standing in for a radix tree, a naive O(n²) sort standing in for the optimized one). Run both on the same randomized operations and assert they agree. This catches subtle bugs that no hand-written assertion would, because the oracle encodes the *whole* contract.

### Corner cases and critical thresholds
Read the implementation for the values where behavior *changes* — capacity limits, representation switches, allocation boundaries — and hammer the edges. If something changes at 256 bytes, test 255, 256, and 257. General edges to always consider: empty, single element, exactly-at-capacity, one over, zero, negative, max int, duplicate keys, unicode, off-by-one boundaries. These are where the bugs actually live.

### Faulty / hostile inputs
Don't only test well-formed inputs. Feed truncated data, corrupted encodings, wrong types, gigantic values, deeply nested structures, and adversarial cases. The contract for bad input is usually "reject cleanly" — verify it does, rather than crashing or silently corrupting.

### Stress and scale
Push N toward the limits the system claims to handle — millions of keys/nodes/items, long-running sequences of mixed operations. Scaling bugs, rare races, and states unreachable at small N surface here.

### Sanitizers and built-in tooling
A passing assertion isn't the whole story. Where the ecosystem offers it, run tests under sanitizers and checkers so "correct output" also means "no memory error, no leak, no data race": AddressSanitizer / UBSan / Valgrind (C/C++), the race detector (`go test -race`), leak checks, and assertion-heavy debug builds. If the output is right *and* the tools are silent, the whole chain underneath is validated.

### Framework hints by ecosystem
Use the idiomatic property/fuzz tooling rather than rolling your own when possible:

| Ecosystem | Property-based | Fuzzing |
|---|---|---|
| Python | Hypothesis | Atheris, `hypothesis` |
| JS/TS | fast-check | fast-check, Jazzer.js |
| Java/Kotlin | jqwik | Jazzer |
| Rust | proptest, quickcheck | `cargo fuzz` (libFuzzer) |
| Go | testing/quick | native `go test` fuzzing |
| C/C++ | RapidCheck | libFuzzer, AFL++ |
| Ruby | — | — (hand-rolled generators) |

If no framework fits, a seeded loop generating randomized inputs and checking invariants is perfectly good — that's all a property tester is underneath.

## Mode A — Write a new test set

1. **Understand the contract.** Read the public API and any spec. What does a correct caller observe? What does the system promise (and to whom)?
2. **Read the implementation for fragility.** Find the thresholds, branches, allocation/representation switches, and error paths. These tell you where to aim. (Black-box at the interface, white-box in your input choices.)
3. **Pick the techniques that fit.** Most targets want: a few readable example tests for documentation + happy path, then the heavy artillery — fuzz/property tests on invariants, an oracle if one is buildable, corner cases at the thresholds you found, malformed-input tests, and a stress test. Codecs/parsers/serializers especially want round-trip + corruption fuzzing. Data structures especially want an oracle.
4. **Write the tests.** Match the project's existing test framework and conventions. Seed all randomness and print seed + failing input on failure. Keep the suite fast — fuzz/stress tests can be parameterized to run a small number of iterations in CI and a large number on demand.
5. **Confirm the tests actually bite.** A test that always passes proves nothing. Sanity-check by briefly breaking the implementation (flip a comparison, off-by-one a boundary, skip a step) and confirming a test goes red. Revert. This "mutation check" is the fastest way to know your invariants have teeth.
6. **Report** what you wrote (below).

## Mode B — Evaluate and improve an existing test set

1. **Get the changes.** For a PR or branch, compute the diff against the base:
   ```bash
   BRANCH=$(git branch --show-current)
   BASE=$(git merge-base HEAD main)
   git diff "$BASE"..HEAD
   ```
   (Or fetch a PR diff via `gh`.) For a whole module, just read its tests and code.
2. **Map what could break.** From the diff and the code, list the new/changed behaviors, the branches introduced, and the fragile states (new thresholds, new error paths, new inputs accepted).
3. **Read the existing tests** covering that area.
4. **Diagnose against the philosophy.** Where is the suite weak?
   - Tied to internals instead of the public API? (brittle, false confidence)
   - Fixed example data only, no randomization? (few states explored)
   - Exact-output assertions where an invariant would catch far more?
   - No oracle where one is cheap to build?
   - Thresholds and corner cases from *this change* untested?
   - Malformed / hostile inputs unhandled?
   - No stress/scale coverage where the change affects performance or capacity?
   - Tests that can't fail, or that would pass even if the new code were wrong?
5. **Improve — don't just grade.** Write the missing high-value tests: the invariant/property checks, the fuzz loop, the oracle, the corner cases at the new thresholds, the malformed-input cases. Prefer adding tests over only listing recommendations.
6. **Prove the new tests catch the regression they target.** Where feasible, confirm a test fails when the relevant line is broken (mutation check), so you know it's real protection and not decoration.
7. **Report** the diagnosis and what you added (below).

For a lighter, general-purpose test-quality checklist (pyramid balance, independence, naming/clarity) that isn't specifically about aggressive bug-hunting, `test-verify-time` complements this skill.

## Output

**Mode A (write):**
```
## Tests written

**Target:** [module / API]
**Files:** [test files created or modified]

### What they cover
- Invariants checked: [round-trip, idempotence, oracle agreement, ...]
- Fuzz/property tests: [what's randomized, how it's seeded]
- Corner cases / thresholds: [the specific edges hit and why]
- Faulty inputs: [what malformed cases are exercised]
- Stress: [scale tested, if any]

### Mutation check
- [which deliberate break(s) you confirmed turn a test red]

### Notes
- [how to run a longer fuzz/stress session; any gaps left and why]
```

**Mode B (evaluate + improve):**
```
## Test review

**Reviewed:** [PR #N | branch vs base | module]

### Gaps found (by severity)
- **Critical** — [behavior in the diff with no test that would catch it being wrong]
- **Weak** — [happy-path-only / fixed-data / internals-coupled tests]
- **Missing technique** — [no invariants / no fuzzing / no oracle / no corner cases where they'd pay off]

### Improvements applied
- [tests added, and what each now protects against]

### Mutation check
- [deliberate breaks confirmed caught by the new tests]

### Still recommended (not done)
- [higher-effort additions worth a follow-up, with rationale]
```

## Anti-patterns (don't ship these)

- **Testing private internals.** Breaks on refactor, doesn't reflect the real contract.
- **Fixed-data-only suites.** A handful of memorized inputs; no exploration.
- **Exact-output assertions where an invariant fits.** One case checked instead of a whole class.
- **Coverage-chasing.** Tests written to turn lines green rather than to find bugs. High coverage with weak assertions is worse than honest gaps — it hides them.
- **Over-mocking.** Mocks that mirror the implementation's call graph just re-assert the implementation and break when it's refactored.
- **Unseeded randomness.** A fuzz failure nobody can reproduce.
- **Characterization tests that bless bugs.** Writing `assert f(x) == <observed output>` for behavior you never checked against the spec. This *certifies* whatever the code currently does — bugs included — and is worse than no test, because it makes the defect look intentional and guards it against future fixes. Expected values come from the contract, not the console.
- **Tests that can't fail.** If breaking the code leaves the suite green, the test is decoration. The mutation check exists to catch exactly this.
