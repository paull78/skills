# Project workflow scenarios

Scripted runs of the `project-*` skills through headless `claude -p`, in throwaway git repos under `$TMPDIR`. Each script prints `PASS:` lines or stops at the first `FAIL:`. The conversation is logged next to the scratch repo, in `<scratch>.log`.

## Running

```bash
tools/scenarios/00-smoke.sh      # the harness itself
tools/scenarios/01-setup.sh      # saves snapshot spec-started
tools/scenarios/02-spec.sh       # needs spec-started, saves spec-approved
tools/scenarios/03-plan.sh       # needs spec-approved, saves plan-approved
tools/scenarios/04-build.sh      # needs plan-approved, saves at-final-gate
tools/scenarios/05-resume.sh     # needs plan-approved
tools/scenarios/06-pivot.sh      # needs plan-approved
tools/scenarios/07-parallel.sh   # needs spec-started, uses fixtures/parallel
tools/scenarios/08-wrap.sh       # needs at-final-gate, saves wrapped
tools/scenarios/09-feature.sh    # needs wrapped
tools/scenarios/10-two-branches.sh  # needs wrapped
```

Snapshots live in `${SCENARIO_SNAPSHOTS:-$HOME/.cache/project-workflow-snapshots}/` ($TMPDIR is cleaned by macOS, so snapshots default to `~/.cache` instead). After changing one skill, re-run from the first scenario that exercises it; earlier snapshots stay valid.

Runs are slow and cost tokens: each `turn` is a full `claude -p` call. Run them in the background.

The skills are linked into each scratch repo's `.claude/skills/`, and every `claude -p` call runs with `--setting-sources project,local`, so the scenarios test the working copy even when the same skills are installed in `~/.claude/skills/` (an installed skill would otherwise win). The cost: your user-level settings and plugins don't load during scenarios.

Every scenario backs up the general memory (`~/.agents/memory/`), `~/.claude/CLAUDE.md` and the old `~/.claude/project-lessons.md`, and restores them on exit, because setup and wrap write there.

## Manual check: compaction

`claude -p` can't trigger compaction reliably, so this one is by hand.

1. Copy the snapshot: `cp -R "${SCENARIO_SNAPSHOTS:-$HOME/.cache/project-workflow-snapshots}/plan-approved" "$TMPDIR/compact-check" && cd "$TMPDIR/compact-check"`.
2. Start `claude` and run `/project-time Only do step 01, then stop.`
3. When it stops, run `/compact`.
4. Type `continue with the next step`.
5. Check that it works on step 02, not step 01 again; writes and runs the tests before the implementation; gives the one-line memory checkpoint; and commits as `wordfreq step 02: ...`.

## Manual check: general memory

A headless run may be refused writes outside the repo, so `08-wrap.sh` accepts a lesson handed over instead of written. In an interactive session on a copy of the `at-final-gate` snapshot, back up `~/.agents/memory/`, run `/project-time`, approve the wrap and one lesson, accept any permission prompt, and check that `~/.agents/memory/lessons.md` gets exactly one new line and the INDEX lists the area. Restore the folder afterwards.
