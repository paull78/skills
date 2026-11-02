# Tools, modes and precision input

## Every tool is a state chart

```
            pointerdown              moved > drag threshold
  IDLE ─────────────────▶ POINTING ─────────────────────────▶ DRAGGING
   ▲                         │ pointerup (no drag) = click        │ pointerup = commit
   │                         ▼                                    ▼
   └──────────── done ◀── CLICK ACTION                COMMIT (one undo step)
                 Esc anywhere above IDLE → cancel: revert preview, no history entry
```

- **Pointing is not dragging.** Pointer-down only *arms* the gesture. Drag starts past 4 screen px with a mouse and 6 px with touch (tldraw `dragDistanceSquared` 16 / 36). Below the threshold, pointer-up is a click.
- **A click without a drag does something sensible.** A placement tool drops the object at its default size (tldraw box tools). A wall tool starts a chain.
- **Preview, don't commit.** Moves update a transient preview. The document changes once, on commit. Never write to the document, push undo, or broadcast on every pointer move.
- **Cancel is not undo.** Esc mid-gesture restores the pre-gesture state and leaves nothing in the redo stack (tldraw `bailToMark`).
- **Use pointer capture.** Call `setPointerCapture` on down, and handle `pointerup` *and* `pointercancel`. Without it the gesture breaks when the cursor leaves the canvas.
- **Keep the grab offset.** The grabbed point stays under the cursor. The object's origin must not jump to the pointer.
- **Feedback on pointer-down, completion on pointer-up.** Highlight the target and show handles right away, and keep the feedback continuous. The action itself completes on release and can be aborted (Esc, or moving back before the drag threshold). That is WCAG 2.5.2 Pointer Cancellation.
- **Leave the dragged item out of its own snap and hit candidates.** Otherwise it snaps to itself and feels sticky.
- **Ignore extra touch points** after a one-finger drag starts. A second finger means a navigation gesture (pinch or pan), so cancel the edit cleanly.

## The Esc ladder

One rung per press, starting from whatever state the user is in:

| Rung | State | Effect |
|---|---|---|
| 1 | A typed value in the buffer | Clear the buffer; the gesture continues |
| 2 | Gesture or rubber band in progress | Cancel it. Committed chain segments stay, the tool stays armed, nothing enters redo |
| 3 | Tool idle | Return to Select |
| 4 | Select with a selection | Clear the selection |

An on-canvas text edit counts as a gesture: Esc leaves text editing (see below), and the next press continues down the ladder.

Multi-point tools (polyline, wall chain) finish on Enter, a double-click, or a click on the last or first point (first point closes the loop). Excalidraw's hint is "Click on last point or press Esc or Enter to finish". In AutoCAD, Enter or Space at an empty prompt repeats the last command.

## Sticky or one-shot

- **Default for creation tools:** one-shot, then back to Select, with a visible **lock** to keep the tool armed (tldraw `isToolLocked`, Excalidraw "Keep selected tool active after drawing").
- **Chain tools (walls, polylines)** keep drawing until finished. That is the CAD norm.
- **Placement tools (furniture, symbols):** with a sticky tool, a click meant to select the object you just placed drops a second copy. Either make the tool one-shot with a modifier to repeat, or show the armed state loudly: a ghost under the cursor plus the active button.
- **Whatever the choice,** show a latched mode with **at least two indicators**: the pressed toolbar button plus a cursor or hint change (NN/g, Modes).

## Quasimodes over latched modes

Use held keys for temporary behaviour. The mode ends when the key is released, so the user can't forget it is on.

Default modifier map. Give each modifier one meaning per gesture type, and write it into the tool spec:

| Hold | Click | Drawing / dragging a point | Moving an object | Resizing | Hover |
|---|---|---|---|---|---|
| Shift | Add to / toggle selection | Constrain: ortho or 15° steps; lock inference direction | Constrain to an axis | Keep proportions | - |
| Alt/Option | - | - | Duplicate (Alt-drag) | From the centre | Measure distances (Figma) |
| Cmd (Mac) / Ctrl (Win) | Deep select (Figma) | Bypass snapping (tldraw) | Bypass snapping | Bypass snapping | - |
| Space | - | Pan, mid-gesture included | Pan | Pan | Pan |

- **On macOS, Ctrl-click is right-click.** That is why the snap bypass is Cmd on Mac, not Ctrl. Never make Ctrl-click a canvas action on Mac.
- **Products differ.** Onshape bypasses with Shift, some CAD tools with Alt. If your users come from one product, follow it, and record the deviation.
- **If Space already does something in a tool,** for example finishing a chain, give tap and hold different meanings, or move the other action.

Explain modifiers where the user is looking. A hint line while the tool is active: "Hold Shift to constrain angle · ⌘ to place freely · Enter to finish" (Excalidraw-style hints, with a setting to hide them).

## Keyboard routing

Decide in order. The first layer that consumes the key wins.

1. **A focused text field or contenteditable, or IME composition** (`e.isComposing`): the field gets the key, and no shortcuts fire.
2. **The active gesture's value buffer:** digits, `.`, `,`, unit letters, operators, Backspace, Tab, Enter, Esc.
3. **The tool's own keys.**
4. **Global shortcuts.**

Rules:
- **Single-letter shortcuts fire only with no Cmd, Ctrl or Alt held.** Otherwise `w` steals Cmd+W.
- **Never take browser keys:** Cmd/Ctrl+W, T, N, R, L, Q, P (print), and browser zoom Cmd+0/±, except inside the canvas.
- **Clipboard and select-all are yours on a focused canvas.** Handle copy, cut and paste through the `copy`/`cut`/`paste` events, which give clipboard access and respect permissions, and handle Cmd/Ctrl+A. When a text field has focus, leave all of them to the browser.
- **Match single characters with anchored patterns.** `/^[0-9.,]$/`, not `/[0-9.]/`, which matches "F5".
- **The value buffer reads characters from `e.key`.** That way `8'6"`, `,` decimals and every layout type what the user sees on the keycap.
- **Letter shortcuts read `e.key`** so they follow the user's layout. Fall back to `e.code` when `e.key` isn't a Latin letter: Cyrillic or Greek layouts, or Mac Option+letter producing symbols.
- **Use `e.code` for Shift+digit shortcuts** (Shift+1 fit, Shift+2 selection). With Shift held, `e.key` is "!" on US layouts and something else elsewhere.
- **Don't move focus to a DOM field to capture a typed value.** The first keystroke gets lost and focus leaves the canvas. Feed a buffer in the tool state and draw it.

## Precision input while drawing

**Gesture for direction, keyboard for exactness.** This is the single most important precision pattern (SketchUp Measurements box/VCB, AutoCAD Dynamic Input, Rhino distance constraint).

- **Typing starts input immediately.** After the first point, typing `3.2` and pressing Enter places the next point 3.2 units along the current (snapped) direction. The user never clicks a field first.
- **Show the value at the cursor**, or at the segment midpoint, as the user types. Avoid a status bar far away.
- **Lock with Tab (AutoCAD Dynamic Input).** While a value is being typed, Tab confirms the length and moves to the angle field. Elsewhere Tab means something else: cycling snap candidates mid-gesture, moving between objects when idle (SKILL law 5). A locked field shows a lock icon (BricsCAD turns it red) and constrains the cursor. The mouse keeps steering the free value.
- **Distance constraint (Rhino).** Typing a length before the click holds the cursor on a circle of that radius while the mouse picks the direction.
- **The value stays retypable.** In SketchUp you can retype the last length until the next action starts.
- **Shapes take two values.** `l,w` for a rectangle. `3,` changes only the first and `,3` only the second (SketchUp).
- **Absolute and relative coordinates** for power users: `[x,y]` absolute and `<dx,dy>` relative (SketchUp), or `@dx,dy` (AutoCAD).
- **Units in any field.**
  - A bare number uses the document unit. `240cm`, `2.4m`, `8'6"` and `2400mm` override it.
  - Accept `,` as a decimal mark where the locale uses it.
  - Allow simple arithmetic (`3.2+0.115`, `2*1.2`), as Blender, Figma and Penpot do.
  - If the input doesn't parse, mark the field red and keep the buffer. Never silently commit 0.
- **Say which length.** For walls, label the reference: centreline, inner face, or outer face. Sweet Home 3D measures the centreline, which surprises users who measured inner faces. Keep the reference consistent between drawing, editing and dimensions.
- **Edit after the fact.**
  - Click the length label on a selected element to type a new value (magicplan, ArcSite, Planner 5D).
  - Say which end moves. The default is the end away from the anchor.
  - Optionally offer a lock that keeps the value fixed during later edits (magicplan "lock measurements").

## Ortho, polar and inference locks

- **Shift toggles ortho temporarily** (AutoCAD, Rhino). Polar increments divide 90°: 15, 30, 45.
- **Measure angles against both the world axes and the previous segment**, so "90° to the last wall" comes free.
- **SketchUp locks.**
  - Shift freezes the current inference direction, so you can then hover another point to take its projection: "as long as that wall".
  - The arrow keys lock axes.
  - Dwelling on a point makes alignments to it preferred.
- **Show the tracking ray as a dotted line** with a tooltip giving distance and angle.

## On-canvas text editing (labels, room names, notes)

- **Enter text editing** with a double-click on the label, or Enter on a selected label.
- **Keys:**
  - For single-line labels, Enter commits; Shift+Enter adds a newline where multi-line text is allowed.
  - A click elsewhere commits.
  - Esc leaves editing and keeps the text, as in Figma; undo reverts it. If your product prefers Esc to revert, say so in the hint line.
- **Shortcuts stay off while editing.** Typing "w" in a room name must not switch tools (keyboard routing layer 1).
- **The edit box sits exactly over the drawn label,** at the same size and font, so nothing jumps when editing starts or ends.
- **Commit as one undo step.** Empty text either deletes the label or restores the previous text. Pick one and state it.

## Contextual hints and command bar

- **One-line prompt for the active step**, e.g. "Next point or length · Enter to finish · Esc to cancel", as in the AutoCAD command line.
- **Hint after the long way.** Show a shortcut when the user finishes an action through the menu (NN/g, accelerators).
- **Command palette (Cmd/Ctrl+K):** search every action by name, with its shortcut shown, as in the Figma Actions menu and Rayon's command line. It is worth building once the action count passes about 20.
