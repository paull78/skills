# Accessibility for canvas editors

A canvas is a single opaque element to assistive technology. Everything drawn on it needs a second representation, or it doesn't exist for keyboard, screen-reader or voice-control users. DOM linters (axe, the Vercel guidelines, AccessLint) audit only the chrome, so treat canvas content as *undetermined* until it has been checked by hand.

## WCAG 2.2 criteria that bite canvas apps

| Criterion | Level | What it means here |
|---|---|---|
| 2.1.1 Keyboard | A | Every function reachable by keyboard: tools, selection, move, edit values, view |
| 2.5.1 Pointer Gestures | A | Multi-point or path gestures (pinch zoom, two-finger undo, three-finger redo) need a single-pointer alternative: zoom buttons, visible undo/redo |
| 2.5.2 Pointer Cancellation | A | Complete actions on pointer-up, abortable (move away, Esc); pointer-down gives feedback only |
| 2.5.7 Dragging Movements | AA | Every drag also has a **single-pointer, non-drag** path. Keyboard support alone doesn't satisfy it. |
| 2.5.8 Target Size (Minimum) | AA | Targets at least 24×24 CSS px, or spaced so a 24 px circle around each doesn't overlap another. This covers handles. |
| 1.4.11 Non-text Contrast | AA | 3:1 for UI components and meaningful graphics: handles, selection outlines, snap markers, focus rings, collaborator colours |
| 1.4.1 Use of Color | A | Never colour alone: invalid = red **and** dashed **and** a reason; warnings get a shape |
| 2.4.7 / 2.4.11 Focus Visible / Not Obscured | AA | Focus is visible, and panels or floating bars don't cover the focused item |
| 2.3.3 Animation from Interactions | AAA | Respect `prefers-reduced-motion` (a good practice even at AA) |
| 4.1.2 / 4.1.3 Name, Role, Value / Status Messages | A / AA | Controls have names; status changes such as refusals and saves are announced without stealing focus |

## Patterns

**1. Mirror DOM (Figma).**
- Keep a DOM tree beside the canvas with one focusable element per meaningful object (room, wall, door, object), positioned with CSS transforms over the drawn object.
- **Don't** use visually-hidden CSS for it. Magnifiers, focus rings and voice control ("click Sofa") need real positions.
- Sync selection both ways: canvas selection moves DOM focus, and DOM focus selects on the canvas.
- Figma's write-up: https://www.figma.com/blog/building-accessibility-into-a-canvas-based-product/

**2. Keyboard navigation: pick a focus model.**
- **A. One tab stop, roving focus (recommended for large drawings).**
  - The canvas is a single tab stop.
  - Inside it, arrow keys move between objects (nearest in that direction), and Tab leaves the canvas.
  - There is no risk of 1,000 tab stops.
- **B. Tab cycling (tldraw).**
  - Tab and Shift+Tab move through objects in reading order (rows by y, then x), and Ctrl/Cmd+arrow jumps to the nearest object.
  - A skip link or Esc leaves the canvas, so it is never a keyboard trap (2.1.2).
- **In both models:**
  - Leave decorative items out.
  - Tab follows SKILL law 5: while a value is being typed it locks the value, and mid-gesture it cycles snap candidates.

**3. Keyboard editing.**
- Arrow keys nudge the selection in world units.
- Enter opens the selected object's inspector fields.
- Delete removes it.
- R rotates.
- A keyboard "virtual cursor" for drawing (arrows move a crosshair by one grid step, Enter places a point) makes drawing tools usable without a pointer. Typed lengths already cover most of this (Figma has keyboard creation with a crosshair, plus keyboard box select).

**4. Announcements.**
- Use one `aria-live="polite"` region and coalesce bursts: "Moved 5 cm right", not five announcements.
- Announce a refusal once, on release or when its reason changes, debounced. Never on every pointer move, or the screen reader floods. `assertive` only for refusals that block what the user just tried: "Refused: crosses the kitchen wall".
- Selection: "[name], [type]. [n] of [total]" (tldraw), or "4 objects selected".

**5. Inspector as the universal alternative.**
- Position, size, rotation, lengths and the room an object is in, all editable as labelled fields.
- That gives the 2.5.7 non-drag path and the 2.1.1 keyboard path at once.

**6. Forced colours.** Canvas pixels ignore Windows high-contrast mode (`forced-colors: active`). Detect it, and redraw with the system colours (`CanvasText`, `Canvas`, `Highlight`, `GrayText`) read from CSS, with heavier lines.

**7. Settings.**
- Reduced motion.
- An option to turn off single-key shortcuts, because they clash with screen-reader and voice-control commands (WCAG 2.1.4 Character Key Shortcuts, A).
- Labels on icon buttons.
- High-contrast drawing: heavier lines, no grid.

## Scope honestly

Full canvas accessibility is a large project. For a demo or MVP, state the supported level in the spec, and still do the cheap parts:
- inspector fields for every draggable property;
- `aria-live` refusals and edits;
- visible focus;
- 3:1 contrast;
- a non-colour cue for invalid states;
- reduced motion;
- an option to disable single-key shortcuts.

Don't claim WCAG conformance for the canvas without a manual audit.

## Review checklist

- [ ] Non-drag path for every drag (2.5.7); single-pointer path for every multi-finger gesture (2.5.1); actions complete on pointer-up (2.5.2); keyboard path for every function.
- [ ] A chosen focus model; no keyboard trap.
- [ ] Forced-colours mode handled, or stated as out of scope.
- [ ] Handles and markers at 24 px targets and 3:1 contrast; never colour alone.
- [ ] Refusals and edits announced through a live region; bursts coalesced.
- [ ] Focus visible and not obscured; focus returns after dialogs.
- [ ] Single-key shortcuts can be turned off (2.1.4).
- [ ] Reduced motion respected.
- [ ] The canvas accessibility level is stated, not implied.
