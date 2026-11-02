# Selection and direct manipulation

## Thresholds (tldraw defaults, good reference numbers)

| | Mouse / pen | Touch (`pointerType === 'touch'` or `(pointer: coarse)`) |
|---|---|---|
| Drag start distance | 4 px | 6 px |
| Hit-test margin around thin geometry | 3 px | 4 px |
| Handle hit radius | 12 px | 20 px |
| Double-click window | 450 ms | |
| Long press | 500 ms | |

- **Hit areas follow WCAG 2.5.8.** A target is at least 24×24 CSS px, or has enough spacing around it. A handle can *look* 8–10 px if its hit area is bigger. Make the hit area at least as large as the drawn handle, never smaller.
- **For touch:** Microsoft recommends about 7.5 mm (about 40 epx) and Apple 44 pt. Leave about 1 cm of clear space around draggable objects (NN/g).

## Hover before commit

- **Highlight what a click would hit:** outline or tint the object, and enlarge the handle under the cursor.
- **Use the platform cursor for the action:** `move`, `nwse-resize`, `crosshair` for drawing, a rotate cursor near the rotation grip, `not-allowed` over an invalid drop.
- **Hover and selected must look different.** Hover is a thin outline. Selected adds handles and a stronger outline.
- **Handles win hit-testing** over the bodies of the objects under them.
- **Selection is stable.** A click on empty canvas clears it, but a click on a panel never does.

## Picking in dense drawings

- **Pick precedence for a CAD plan:** handle → joint/vertex → opening (door, window) → wall/edge → object → room/area.
- **Click again to cycle overlapping candidates.** Excalidraw: "{key}-click to cycle selection". Rayon uses Tab (in this skill, Tab cycles snap candidates mid-gesture; see SKILL law 5). Figma: right-click → "Select layer" lists everything under the cursor.
- **Groups (Figma):**
  - A click selects the top-level parent.
  - Double-click or Enter goes down a level, and Shift+Enter goes up.
  - Cmd/Ctrl-click deep-selects.

## Box selection

| Drag direction | Name | Selects | Look |
|---|---|---|---|
| Left → right | Window | Only what is **fully inside** | Solid border, blue tint |
| Right → left | Crossing | Anything the box **touches** | Dashed border, green tint |

- **Window and crossing are the AutoCAD convention.** Figma instead makes a plain drag select what is touched, and a Cmd-drag also deep-selects. Pick one convention, make it visible, and keep it consistent.
- **Shift adds or toggles.** Shift + box adds to the selection.
- **The box also needs a non-drag path** (WCAG 2.5.7): click one corner, then click the opposite corner.

## Moving, resizing, rotating

- **The object stays glued to the pointer, respecting the grab offset.** Use `setPointerCapture`. Move one-to-one with the pointer with no smoothing; smoothing reads as lag.
- **Commit once on release** as a single undo step. Esc during a drag reverts.
- **Show what moves:** a ghost at the target position with live measurements (length, angle, distances to neighbours).
- **Resize grips:**
  - Side grips change one dimension.
  - Corner grips change two. Shift keeps the proportions, Alt resizes from the centre.
  - Show the new dimension on the grip side as it changes.
- **Rotation:**
  - A grip offset outside the object.
  - Snap to 15° and to the angles of nearby walls.
  - A keyboard key rotates 90°. Say which direction (R = counter-clockwise is a choice; document it).
- **Nudge:**
  - Arrow keys move by a small step, Shift+arrow by a large one, in world units (1 cm / 10 cm for a plan; Figma uses 1 / 10 px).
  - Nudges are instant, never animated.
  - A run of nudges merges into one undo step after a pause of about 400 ms or more.
  - Call `preventDefault` so the page doesn't scroll.
- **Duplicate:** Cmd/Ctrl+D creates a copy at an offset or as a ghost to place. Alt-drag duplicates when the platform convention allows it.
- **Copy and paste:**
  - Paste at the cursor if it is over the canvas, otherwise in place.
  - In multi-state documents, a paste into another state lands at the same coordinates.

## Connected and hosted geometry

In CAD documents, elements depend on each other. Edits must show and keep those links:

- **Joined elements follow.** Moving a joint or wall stretches the walls connected to it. The preview shows every affected element, not only the dragged one.
- **Hosted elements ride along.**
  - Doors and windows slide along their host wall, clamped to it, and keep their offset when the wall moves.
  - Dragging one off its wall is refused with a reason or re-hosts it onto the wall under the cursor. Pick one and show which wall will receive it.
- **Derived things update live:** rooms re-form, areas update, dimension lines tied to joints follow.
- **Refusals cover the knock-on effects too.** If stretching a neighbour would make it cross another wall, the culprit shown is that neighbour.

## Lock and hide

- **Locked items** (an underlay, a reference wall) are skipped by hit-testing and can't be selected by a click, but stay snappable. Show a lock badge on hover, and unlock them from the inspector or a layer list.
- **Hidden items** neither draw, hit-test nor snap. Make "something is hidden" visible somewhere, so nobody hunts for a missing wall.

## Multi-selection and the inspector

- **Show "Mixed"** in a field where the selected values differ. Typing a value applies it to all of them.
- **Group transforms:** one bounding box with handles around the whole selection.
- **Figma Smart Selection** for evenly spaced items: handles in the gaps respace them all at once, and dragging an item's centre reorders it. It is a pure UI layer with no new object type, which keeps it cheap.

## Every drag has a non-drag path (WCAG 2.5.7 Dragging Movements, AA)

| Drag action | Single-pointer or keyboard alternative |
|---|---|
| Move | Select, then arrow keys; or type x/y in the inspector |
| Resize | Type width/depth in the inspector |
| Rotate | R key; or type the angle |
| Move a joint/vertex | Select the joint, type its coordinates or the adjoining lengths |
| Box select | Click a corner, then the opposite corner; or Select All by type |
| Draw a wall | Click, click (already a single-pointer path); typed lengths |

Keyboard support alone does not satisfy 2.5.7. It requires a *single-pointer* path that doesn't drag. Inspector fields usually provide it for free.

## Review checklist

- [ ] Drag threshold, with click and drag treated separately.
- [ ] Pointer capture; `pointerup` and `pointercancel` handled; Esc reverts.
- [ ] Grab offset kept.
- [ ] Preview while dragging; commit once on release; one undo step.
- [ ] Hover feedback and cursor changes; hover looks different from selected.
- [ ] Handles constant on screen (px), hit area ≥ 24 px, bigger on touch.
- [ ] Overlapping candidates can be cycled.
- [ ] Nudge in world units, not animated, merged in undo.
- [ ] Connected geometry previewed (joined walls, hosted openings, rooms); knock-on refusals name the real culprit.
- [ ] Locked items skip hit-testing but stay snappable; hidden items are signposted.
- [ ] Non-drag path for every drag.
