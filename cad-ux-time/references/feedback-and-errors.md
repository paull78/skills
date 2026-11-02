# Feedback, refusals and warnings

## Show the result before it happens

- **Ghost preview.** Draw the wall, object or edit at its would-be position, in its real shape. For walls that means the true thickness and the mitred corners as they will be committed.
- **Live measurements during every gesture:**
  - the length and angle next to the cursor or at the segment midpoint;
  - distances to the nearest neighbours while moving an object (Figma Alt-hover distance lines, tldraw gap lines), drawn in the accent colour because red is reserved for refusals;
  - the new size on the grip while resizing.
- **Use one consistent number format.** Same unit and precision everywhere (drawing, inspector, dimensions, export), for example `3.25 m` and `85 cm`. Don't show "3.2500000001".
- **Say what will happen on release:**
  - the cursor changes (copy `+`, `not-allowed`);
  - the target highlights (the wall a door will sit on, the room an object will land in).

## Refuse in place

When a rule rejects an edit (walls would cross, an object would leave its room, an opening would overlap another), the user must see **where** and **why** without looking away from the pointer.

```
  live, during the gesture                     on release
  ─────────────────────────                    ──────────────────────────
  ghost turns red (+ dashed: not colour only)  snap back to the start, or (long moves)
  offending element highlighted                  stop at the last valid position
  reason in words AT THE CURSOR:               drawing unchanged by the refused part,
    "Crosses the kitchen wall"                   no history entry for it
  cursor: not-allowed                          reason stays until the next pointer move
                                               aria-live: announced once
```

Rules:
- **Keep the reason at the point of action.**
  - For pointer gestures, that is the cursor.
  - For typed values and inspector edits, it is the field.
  - NN/g calls toasts "a bad way to implement an error message" because they disappear and sit far from the cause. A status-bar line has the same problem.
  - A toast, if there is one, only echoes the reason. The exception is a command-line-driven app whose users already read the command line: there the line *is* the point of action.
- **Choose what release does after a refused move.**
  - Snapping back to the start is the simplest, and right for short moves and drawing clicks.
  - For long drags, stopping at the last valid position keeps the user's work.
  - Sliding along the obstacle is the most polished and the most work.
  - Pick one per tool and state it.
- **Announce once.** Live validation fires on every move, so screen readers hear the refusal once: on release, or when its reason changes, debounced. Never on every pointer move.
- **Show why while it matters, not after.** Validate the preview on every move so the user can steer away *before* releasing. Don't let the user release and only then learn the edit was refused.
- **Name the culprit.** "Crosses the kitchen wall" beats "Invalid position". Highlight the specific element in the way.
- **Write the reason in plain words, never vague, never apologetic.** Say what blocks the edit, and how to fix it when that isn't obvious: "Too short: walls must be at least 5 cm".
- **A refusal leaves no trace.** The document is unchanged and there is nothing to undo.
- **A typed value that is refused keeps the buffer and the field open, tinted**, so the user can correct it rather than retype it.
- **Run a cheap check live and the full check on commit** if the full check costs a frame. When they disagree, the commit wins, and the refusal is then shown at the spot.
- **Remote or server refusals** after an optimistic commit:
  - The element fades back to the last accepted state.
  - A short note appears *at the element*, naming the cause if known: "Removed: conflicts with Ana's wall".
  - The gesture or chain continues when its anchor still exists.

## Warnings are not errors

Some conditions are allowed but worth knowing: a door swing blocked by furniture, a walkway narrower than 60 cm, a window behind a wardrobe.

- **Use an indicator, not an alert.** It is persistent and conditional: it stays exactly as long as the condition holds (NN/g, indicators vs notifications).
- **Give warnings a separate colour role** (amber) and a separate shape (a hatched wedge or a "!" badge), so they can't be confused with selection or with refusals.
- **Never block the edit.** Explain in a tooltip or in the inspector: "Door swing blocked by Wardrobe".
- **Let the user see them all.** Offer a count or a list in the inspector ("3 warnings").

## Confirmations and destructive actions

- **Don't confirm reversible actions.** Undo is the safety net, and NN/g warns that frequent confirmations train people to click Yes without reading.
- **Confirm only what undo can't restore:** deleting a whole project, discarding unsynced work. Make the confirmation specific ("Delete 'Flat 3B' and its 4 layouts?"). For the most destructive cases, use typed confirmation or a timed undo window.
- **Destructive buttons say what they do.** "Delete project", not "OK".

## Status of work: saving and sync

- **Show sync state honestly and quietly:** saved, saving, offline (with the number of edits queued), conflict.
- **Never block a local edit on the network.** Apply it optimistically and reconcile.
- **Latency:**
  - Under 100 ms needs no indicator.
  - Over 1 s, show progress.
  - Over 10 s, show progress with a cancel.

## Empty, loading and first-run states

- **An empty canvas invites action.** "Press W to draw walls · or import a plan picture" disappears after the first edit.
- **An empty project list offers a way forward:** "New project" plus "Open the sample flat". A sample beats a blank page in a demo.
- **Loading:** a skeleton of the chrome right away, then the drawing. Never a spinner over an empty white page.
- **Copy:**
  - A button says exactly what happens, and the toast echoes it: "Export PDF" → "PDF exported".
  - Errors say what happened and what to do next.

## Motion

- **Never animate frequent actions:** nudges, tool switches, selection changes, snap jumps, undo. Anything done more than about 100 times a day gets no animation (Emil Kowalski, interface-design).
- **UI transitions take 150–250 ms** (panels, popovers). Camera moves like zoom-to-fit run 200–300 ms and are interruptible.
- **Use motion to explain a state change** the user would otherwise miss, for example furniture moving between two layouts. Make it skippable and keep it display-only: the document jumps to its final state at once.
- **Respect `prefers-reduced-motion`.** Replace motion with an instant change or a cross-fade.
- **No decorative motion on the canvas:** no shakes, bounces or pulses on errors. The reason text does the work.

## Review checklist

- [ ] Ghost and live measurements in every gesture; one number format.
- [ ] Refusals show red + dashed, the culprit highlighted, and the reason at the cursor (at the field for typed edits); release snaps back or stops at the last valid position; no history entry; announced once.
- [ ] A toast is never the only channel for an error; reasons are in plain words.
- [ ] Warnings are persistent indicators in their own colour and shape.
- [ ] No confirmations on undoable actions.
- [ ] Sync state visible; no network wait on local edits.
- [ ] Empty states invite action; no animation on frequent actions; reduced motion respected.
