---
name: cad-ux-time
description: Best-in-class interaction and UX design for CAD, drawing, diagramming, whiteboard and floor-plan editors in the browser (Canvas2D, WebGL or SVG), distilled from tldraw, Figma, AutoCAD, SketchUp, Onshape, Rhino, NN/g and WCAG 2.2. Use when designing, specifying, building, reviewing or auditing a canvas editor's tools and modes, typed lengths and precision input, snapping, selection and handles, zoom and pan, refused-edit feedback and warnings, undo, inspector panels and numeric fields, shortcuts, multiplayer presence, touch and pen, canvas accessibility or plan drawing conventions, when asked to make a canvas tool feel like Figma, tldraw, SketchUp or AutoCAD, or when the user mentions cad-ux-time.
---

# CAD UX Time

A canvas editor is judged in the hand: does the drawing follow the pointer, does it say what it snapped to, can you type the exact number, does it tell you *where* and *why* it refused. This skill holds the rules that make that feel right, the numbers to start from, and a way to design, review and audit against them.

**Core principle: gesture for intent, keyboard for exactness, the canvas for feedback.** The pointer gives direction and placement. Typed values give precision. Every consequence shows on the canvas, at the pointer, while it still matters.

**Not for** marketing pages, data-viz charts or generative art. For DOM-only chrome a web-interface guideline is enough. This skill adds what those can't see.

## Modes

Pick the mode from the request. In a repo, first read its spec, design notes and keymap. Existing decisions are constraints: changing one is a proposal with a reason, never a silent override. Respect any length the user asks for. Compress sections rather than drop the ones on refusal, undo and snapping.

### Design: spec a tool or feature

1. Fill `references/tool-spec-template.md`: states, input map, snapping, refusal, commit and undo, collaboration, non-drag path, touch, numbers, out of scope, acceptance scenarios.
2. Check it against the laws below and the checklists in the reference files you touched.
3. **Conflict check.** Run every key, modifier and gesture, *including any new one you invent*, against:
   - the existing keymap;
   - the default modifier map (law 10);
   - the platform's keys (law 11);
   - the other tools.
4. Cut what the product doesn't need, and write the stated constraint instead.

### Build: implement it

- **Pure state machine.** Keep tool logic as `idle → pointing → dragging → commit`, apart from DOM events and rendering, so scripted gestures can test it headless.
- **Screen-px constants in one place.** Snap radius, hit margin, handle size and drag threshold live together. Convert them to world units at hit-test time, with the current zoom.
- **Scenarios first.** Write acceptance scenarios as scripted gestures before the code: click, type, Enter, Esc, a drag across an obstacle.

### Review: code or diff

Walk the laws as a checklist. Report findings, most severe first:

```
[Blocker|High|Medium|Nit] <title>
Where: <file:line or screen + gesture>
Rule: <law N / reference file>
User sees: <the felt problem in one line>
Fix: <concrete change, with numbers>
```

- **Blocker:** breaks data or a core gesture.
- **High:** felt on every use.
- **Medium:** felt in some situations.
- **Nit:** polish.

### Audit: the UX of a running app

1. **Inventory first.** Write down what exists, per area: tools, precision, snapping, selection, navigation, feedback, undo, panels, discoverability, collaboration, touch, accessibility, visuals.
   - Read the code or spec.
   - Look at the app itself: screenshots of real gestures through a browser tool (Playwright or a browser MCP). DOM linters can't see canvas pixels.
   - If you couldn't look, say so.
2. **Compare** each area with its reference checklist. Credit what is already best-in-class, so nobody "fixes" it. Check that the credit holds up against the laws (for example, sticky placement tools invite double drops).
3. **Rank by impact on the core flow × cost.** For a demo or MVP, the first five minutes decide: the opening view, the first tool, the first refusal. **The product's signature feature always gets its own item.**
4. **Conflict check** every proposal (see Design).
5. **Output the top N.** Each item gives the behaviour to build, why (law or source), its conflicts and its cost (S/M/L). End with a short "deliberately not now" list.

## The laws

1. **Direct manipulation is sacred.**
   - Give feedback on pointer-down.
   - Track the pointer 1:1 and keep the grab offset.
   - Complete on pointer-up. The gesture can be aborted with Esc (WCAG 2.5.2).
   - Call `setPointerCapture`, and handle `pointerup` and `pointercancel`.
   - Leave the moving item out of its own snap and hit candidates.
   - Never wait on the network for a local edit.
2. **Pointing is not dragging.**
   - A drag starts only past 4 px (mouse) or 6 px (touch).
   - Below that, release is a click. Selecting must never move anything.
3. **Preview, then commit once.**
   - Moves update a transient preview. The document, the undo stack and the network change once, on commit.
   - **One gesture = one undo step.** In a chain, each segment is one gesture. Merge runs of nudges into one step.
   - **Cancel ≠ undo:** Esc reverts and leaves no redo entry.
4. **The Esc ladder, one rung per press.**
   1. Clear the typed value.
   2. Cancel the gesture or rubber band. Committed chain segments stay, and the tool stays armed.
   3. Back to Select.
   4. Clear the selection.

   Chains finish on Enter, on a double-click, or on a click on the last point. A click on the first point closes the loop.
5. **Type the exact number without asking** (SketchUp VCB, AutoCAD Dynamic Input).
   - Mid-gesture, keys go to a value buffer drawn at the cursor. Never move focus to a DOM field.
   - Enter commits along the current direction.
   - Units and simple arithmetic parse. Bad input stays red and editable.
   - Say which length the number is: centreline or face.
   - **Tab depends on state:**
     - While typing a value, Tab moves from length to angle and locks the length.
     - Mid-gesture with nothing typed, Tab cycles overlapping snap candidates.
     - With no gesture, Tab moves between objects or leaves the canvas.
6. **Tolerances in screen px, geometry in world units.**
   - In px: snap radius, hit margin, handles, markers, labels, chrome line widths.
   - In world units: grid (adaptive 1-2-5), snap step, nudge, typed values.
   - Every spec says "constant screen px" for each piece of chrome.
   - Structural lines get a minimum on-screen width.
7. **Snapping explains itself, stays put, and gives way.**
   - A fixed priority order.
   - A marker **plus a word** ("Midpoint"), with a guide drawn back to the source.
   - **Hysteresis:** release at about 1.5× the capture radius.
   - **A per-gesture bypass and a persistent toggle**, plus a snap step that survives reload.
   - No position is ever unreachable.
8. **Refuse in place.**
   - Show a rejected edit red **and** dashed, with the culprit highlighted. Give the reason in plain words at the point of action, live, during the gesture:
     - at the cursor for pointer gestures;
     - at the field for typed or inspector edits.
   - On release: snap back, or for long moves stop at the last valid position. The document is unchanged, and the reason stays until the next move.
   - A toast, status line or `aria-live` region may only *echo* the reason.
   - Warnings (allowed but problematic) are persistent indicators with their own colour and shape, never errors.
9. **Show the number, and show what else moves.**
   - Live length, angle and distances to neighbours during every gesture.
   - One unit and precision format across canvas, inspector, dimensions and export.
   - The preview includes the connected geometry that will change: joined walls stretching, hosted doors sliding, rooms re-forming.
10. **Quasimodes over modes, with one modifier map.**
    - Held keys for temporary behaviour.
    - Default map, one meaning per modifier per gesture type, written into the tool spec:

      | Key | Meaning |
      |---|---|
      | Shift | Constrain (angle, axis, ratio); on click, add to selection |
      | Alt/Option | From centre (resize), duplicate (move), measure (hover) |
      | Cmd (Mac) / Ctrl (Win) | Bypass snapping while dragging |
      | Space (hold) | Pan, from any tool |

    - A latched mode shows twice: the pressed button plus a cursor or hint change.
    - The active tool shows one hint line naming its modifiers.
11. **Respect the platform's keys.**
    - Single-letter shortcuts fire only with no Cmd, Ctrl or Alt, never in text fields or during IME composition.
    - Never take browser keys: Cmd/Ctrl+W, T, N, R, L, Q, P, or browser zoom.
    - On a focused canvas, handle copy, cut, paste and select-all through the clipboard events. Leave them to the browser inside text fields.
    - **On macOS, Ctrl-click is right-click.**
    - Read the value buffer and letters from `e.key`. Use `e.code` only for Shift+digit shortcuts, or as a fallback when `e.key` isn't Latin.
12. **Never animate frequent actions.**
    - Nudges, tool switches, selection, snaps and undo are instant.
    - Chrome transitions run 150–250 ms. Camera moves can be interrupted.
    - No shakes on errors. Respect `prefers-reduced-motion`.
13. **Undo is personal and visible.**
    - Per user: remote changes are never undone. If an entry was invalidated by a collaborator, skip it and say so.
    - Selection is preserved; camera and presence are never recorded.
    - Bring off-screen undone edits into view.
    - Version history is the recovery path for everything else.
14. **Presence without noise.**
    - Remote cursors are interpolated, named, and fade when idle.
    - **Remote selections are drawn.**
    - Following another user is opt-in from the avatar, and any interaction stops it.
    - A remote change under your gesture re-validates the preview. It cancels the gesture only if an entity the gesture depends on is gone, and then says why at the spot.
15. **Accessibility basics.**
    - Every drag has a non-drag path (2.5.7): inspector fields, click-click, keys.
    - Every multi-finger gesture has a single-pointer path (2.5.1): zoom buttons, visible undo.
    - Targets are at least 24 px (2.5.8).
    - State colours have at least 3:1 contrast (1.4.11), and colour is never the only cue.
    - Edits are announced; a refusal is announced once, on release or when its reason changes.
    - Single-key shortcuts can be turned off (2.1.4).
16. **The drawing is monochrome; colour is state.**
    - Weight order: cut walls (filled, poché) > seen items > swings and dimensions > grid.
    - Dimensions use ticks and strings.
    - Colour roles: self accent, snap, invalid red, warning amber, one per collaborator. Never use red for anything but invalid.
    - Overlays are added on top and never recolour the drawing.
    - Export is black on white.
17. **Discoverable and always reachable.**
    - Open fitted to the drawing; Shift+1 fits all, Shift+2 fits the selection.
    - A scale bar in world units.
    - Tooltips with shortcuts and a complete shortcut sheet (`?`). Add a command palette once there are about 20 actions.
    - Empty states that invite action.
    - A non-shortcut path to every action.
18. **Fast is a feature, and it is measured.**
    - The pointer-move path fits one frame (16.7 ms at 60 Hz, 8.3 ms at 120 Hz): spatial index, cheap live check, full validation on commit, rAF-coalesced rendering.
    - Track the worst frame, not the average.
    - Claim nothing ("instant", "accessible", "real-time") that wasn't measured.

## Starting numbers

| What | Value | Source |
|---|---|---|
| Drag start | 4 px mouse, 6 px touch | tldraw |
| Hit margin around thin lines | 3 px mouse, 4 px+ touch | tldraw |
| Handle | 8–10 px visual, ≥ 24 px hit (≈ 40 px touch) | WCAG 2.5.8, Microsoft |
| Snap capture / release | 8–10 px / ≈ 1.5× | tldraw, AutoCAD; ratio to tune |
| Grid | 1-2-5 world steps, ≥ 8–10 px apart on screen | common practice |
| Polar angles | 15°, also relative to the previous segment | AutoCAD, SketchUp |
| Nudge | 1 / 10 world units (1 cm / 10 cm on plans) | Figma (px), CAD |
| Nudge undo merge | ≈ 400 ms idle | common practice |
| Double-click / long press | 450 ms / 500 ms | tldraw |
| Cursor broadcast | every 50–100 ms, interpolated | szilu, Figma |
| Idle / inactive collaborator | 3 s / 60 s | tldraw |
| Response | ≤ 100 ms instant; > 1 s progress; > 10 s cancel | NN/g |
| Drag latency noticed | ≈ 65 ms mouse, < 20 ms pen | Ink & Switch |
| UI transition | 150–250 ms; 0 ms for frequent actions | Impeccable, Emil Kowalski |
| Contrast of state graphics | ≥ 3:1 | WCAG 1.4.11 |

## Traps seen in testing

| Trap | Instead |
|---|---|
| Space finishes a chain *and* Space pans | Give tap and hold different meanings, or pick one |
| Nudging in px "so it's visible when zoomed out" | Nudge in world units; zoom in for finer work |
| Sticky placement tools: the click meant to select drops a second copy | One-shot with a repeat modifier, or a loud armed state (ghost + button) |
| Inventing a shortcut ("S toggles snap") without checking it | Every new binding goes through the conflict check |
| A wish list that ignores scope, or leaves out the signature feature | Rank by core-flow impact × cost; the signature feature gets its own item |
| A spec that overruns the requested length | Compress the template; keep the refusal, undo and snap sections |

## References (load what the task needs)

- `references/tools-and-input.md`: state charts, the Esc ladder, sticky vs one-shot, quasimodes, keyboard routing, typed-value syntax, locks, on-canvas text, hints.
- `references/snapping.md`: units, adaptive grid, priority, feedback, tracking points, hysteresis code, bypass and toggles, object snapping.
- `references/selection-and-manipulation.md`: thresholds, hover, picking and cycling, window vs crossing, transforms, connected and hosted geometry, lock and hide, nudge, non-drag paths.
- `references/navigation.md`: wheel, trackpad and pinch with zoom-at-cursor code, view commands, scale bar, LOD.
- `references/feedback-and-errors.md`: the refusal pattern (canonical), ghosts, warnings, confirmations, sync state, empty states, motion.
- `references/collaboration-and-undo.md`: undo semantics (canonical), multiplayer undo, version history, presence, follow, concurrent edits.
- `references/panels-and-chrome.md`: layout, tool bar, inspector and numeric fields, shortcuts, context menus, dialogs, states, copy, dark mode.
- `references/accessibility.md`: WCAG 2.2 for canvas, mirror DOM, focus models, announcements, forced colours, honest scope.
- `references/drawing-conventions.md`: line weights, poché, doors, windows, dimensions and rounding, colour roles, overlays, z-order, export.
- `references/performance-and-touch.md`: latency budgets, frame path, pen and touch.
- `references/tool-spec-template.md`: the design-mode template with a worked section.
- `references/sources.md`: every source, and the skills this one distils.
