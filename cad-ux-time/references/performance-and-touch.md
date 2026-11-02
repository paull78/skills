# Perceived performance, touch and pen

## Latency budgets

| Interaction | Budget | Source |
|---|---|---|
| Pen inking / drag with a stylus | users notice 2–16 ms; feels responsive at about 20 ms | Ink & Switch "Slow Software" |
| Finger drag | users notice 2–11 ms | Ink & Switch |
| Mouse drag | noticeability averages about 65 ms (34–137) | Ink & Switch |
| Tap or click response | noticed beyond about 70 ms | Ink & Switch |
| Any discrete action | ≤ 100 ms feels instant; > 1 s show progress; > 10 s progress + cancel | NN/g response-time limits |
| Continuous gesture frame | 16.7 ms at 60 Hz, including hit-test, snap, validate and draw | |

Rules:
- **Track the worst frame, not only the average.** One 200 ms hitch in a drag feels worse than a steady 30 fps (Figma, "Figma, faster").
- **Never wait on the network for a local edit.** Apply it optimistically and reconcile ("no spinners", Ink & Switch local-first).
- **Per pointer move, do the cheap work only:**
  - spatial-index snap and hit queries;
  - a quick preview check;
  - draw the overlay layer.
- **Run the full validation on commit.** If they disagree, the commit wins and the refusal is shown at the spot.
- **Coalesce rendering into `requestAnimationFrame`.**
- **Use coalesced and predicted events for freehand ink only.** `getCoalescedEvents()` gives smooth strokes, and `getPredictedEvents()` cuts perceived pen lag (Pointer Events Level 3). Predicted points are guesses: never use them for snapping, hit-testing or commits. Snapped CAD drags use the latest real event.
- **Split the scene into layers.** A static drawing goes on a cached layer or bitmap; the preview and overlays redraw each frame. Pan and zoom can transform the cached layer while a pinch is in progress and redraw sharply when it ends.
- **Budget and measure** with a scripted gesture on a large document (for example 1–10k walls). Assert frame times in a performance test rather than claiming "smooth".
- **Don't overclaim** in docs or UI ("instant", "real-time") without measurements.

## Touch and pen

- **Pen marks on contact,** with no mode switch or button first (Apple HIG). A common split: the pen draws, fingers navigate (pan, pinch). Let users change it.
- **Pen hover (Apple Pencil hover, Wacom):** preview only. Show the snap target or the ghost; never start an action on hover; don't vary the preview with hover height.
- **Bigger thresholds for coarse pointers:** drag start 6 px+, handle hit radius 20 px+, about 40 px targets, about 1 cm clearance around draggables. Detect per event with `pointerType` or per device with `(pointer: coarse)`.
- **No hover on touch.** Every hover-only affordance (tooltips, snap preview before the press, hover-revealed buttons) needs a touch path:
  - press-and-hold to preview;
  - a magnifier loupe showing the snap under the finger;
  - visible buttons.
- **Two-step placement on touch:** tap to set the first point, drag a handle for the second, and confirm. Typed lengths remain available.
- **Gestures:**
  - Two-finger tap = undo, three-finger tap = redo (Procreate). Always also show visible buttons (WCAG 2.5.1).
  - A quick pinch fits to the screen.
  - Two fingers pan and zoom.
  - A second finger during a one-finger edit cancels the edit and becomes navigation.
- **QuickShape (Procreate):** draw roughly, then hold, and the stroke snaps to a clean line or shape. It is a model for "sketch a wall, get a straight wall".
- **Palm rejection:** while a pen is active, ignore touch contacts that are not navigation gestures.
- **Keep thumbs and palms clear.** Place controls where the drawing hand doesn't cover them, and keep undo reachable by the other hand.
- **`touch-action: none` on the canvas only,** so the rest of the page scrolls normally.

## Review checklist

- [ ] The pointer-move path fits one frame (16.7 ms at 60 Hz, 8.3 ms at 120 Hz) at a realistic document size; measured, not assumed.
- [ ] Cheap check live, full validation on commit; spatial index.
- [ ] rAF-coalesced rendering; cached static layer.
- [ ] No network wait on local edits.
- [ ] Coarse-pointer thresholds; no hover-only affordances; second finger → navigation.
- [ ] Undo reachable on touch (gesture and button).
