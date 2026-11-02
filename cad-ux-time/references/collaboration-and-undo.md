# Collaboration and undo

## Undo and redo

- **One gesture = one undo step.**
  - Mark the history at gesture start and squash on commit (tldraw `markHistoryStoppingPoint` / `squashToMark`; Liveblocks `pause()` / `resume()`).
  - In a chain, each committed segment is one gesture, so one step. Undoing a whole chain at once is a valid alternative; if you choose it, state it.
  - A run of nudges merges into one step.
- **Cancel is not undo.** Esc mid-gesture reverts with no redo entry.
- **Undo inside a chain** removes the last segment and moves the anchor back. Undo past the first segment leaves the tool idle.
- **Selection is preserved, not recorded.** The user can undo, select, copy and redo (tldraw `record-preserveRedoStack`). Do restore the selection that belonged to the undone change, so the user sees what changed back.
- **Never record camera moves, cursor positions or presence** as undo steps.
- **Bring undone edits into view.** If an undo affects something off-screen, pan to it or show a brief locator. An invisible undo feels like nothing happened.
- **Undo and redo are visible buttons too**, not only Cmd+Z and Cmd+Shift+Z (also Ctrl+Y on Windows). This matters on touch, where Procreate uses two-finger tap for undo and three-finger tap for redo.

### Multiplayer undo

- **Undo only your own changes.** Remote changes are never undone locally (tldraw ignores `source: 'remote'`). Rewinding whole-document snapshots breaks under multiplayer (Liveblocks).
- **Figma's invariant.** "If you undo a lot, copy something, and redo back to the present, the document should not change." Undo writes the inverse operation as a *new* change, and redo history is rewritten at undo time.
- **When a collaborator's edit invalidates your undo** (they deleted the thing you moved), skip that entry, or drop the history from that point. Say so briefly: "Can't undo: Ana deleted that wall". Never apply a stale inverse that breaks the drawing.
- **Deleting under a collaborator:** the deleted data lives in the deleter's undo stack, so only they can restore it (Figma).

## Version history

Per-user undo can't restore a collaborator's deletion, and undo stacks die with the session. Version history is the recovery path for everything else:
- Named and automatic snapshots.
- A preview of an older version before restoring it.
- "Restore as a copy" so nothing current is lost.
- For a small product, "duplicate project" plus a few autosaved snapshots is enough. State the limit.

## Presence

| Element | Rule |
|---|---|
| Cursors | Drawn at constant screen size, in the user's colour, with a name tag (and, if useful, the state or view they are in: "Ana · Night"). Broadcast every 50–100 ms and interpolate on the receiving side, so cursors glide instead of jumping. |
| Selections | **Draw remote selections**: an outline in the user's colour, visibly different from your own (for example dashed, no handles, a small initial badge). Without them two people edit the same object and fight. |
| In-progress edits | Optionally draw the collaborator's ghost or rubber band in their colour at low alpha, never as a snap target. |
| Idle | After about 3 s still, shrink the name tag to a dot. After about 60 s, fade the cursor (tldraw thresholds). |
| Avatars | Show who is here in the chrome. A click on an avatar **follows** that user. |
| Colours | One stable colour per user, chosen to avoid your own selection colour and the warning and error colours, and readable at 3:1 on the canvas. |

### Follow mode

- **Opt in from the avatar.** Figma first forced everyone to follow a presenter and found it "felt wrong".
- **While following, frame the viewport in the followed user's colour** and show a "Following Ana · Stop" bar.
- **Any canvas interaction stops following** (Onshape). The followed user can see who is following them.
- **Spotlight** is the inverse: a presenter asks everyone to follow.
- **Persist a "hide cursors" toggle.** Figma users complain that theirs resets every session.

## Concurrent edits

- **Optimistic local edits.** Apply them immediately. Ignore incoming server values for properties you have pending edits on, to avoid flicker. Resolve conflicts with last writer wins per property, as Figma's multiplayer post describes.
- **A remote change under an active gesture:**
  - Re-validate the preview after any remote change. If it is now invalid, show the refusal as usual.
  - Cancel only if an entity the gesture depends on was deleted, or changed so the gesture can't continue (the anchor joint is gone). Say why at the spot: "Ana deleted this wall".
- **Refusals after an optimistic commit** fade back with a reason at the element (see feedback-and-errors.md).
- **Layout or view state per user:** if each user can look at a different state or variant, say so in their cursor tag, and don't let an edit in someone else's state look like it moved your items.
- **Be honest in the UI.** Don't claim real-time when edits are queued: show "Offline · 3 edits waiting".

## Review checklist

- [ ] One gesture = one step; cancel ≠ undo; chain semantics stated.
- [ ] Per-user undo; stale entries skipped with a reason; the Figma invariant holds.
- [ ] Selection preserved; camera and presence not recorded; undone edits brought into view.
- [ ] Remote cursors interpolated, idle fade, constant size.
- [ ] Remote selections drawn, distinct from local.
- [ ] Follow opt-in, stopped by any interaction.
- [ ] Remote change mid-gesture cancels with a reason.
