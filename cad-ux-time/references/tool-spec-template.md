# Tool interaction spec template

Use this when specifying a canvas tool (draw, place, edit, measure). Fill every section, or write "n/a" with a reason. Empty sections are where bugs hide.

```markdown
## <Tool name> (<shortcut>)

**Purpose.** One sentence: what the user makes or changes.
**Sticky or one-shot.** <choice> because <reason>. Lock or repeat: <how>.

### States
| State | Entered by | Pointer | Keys | Drawn |
|---|---|---|---|---|
| Idle | tool armed | hover: <highlight/snap preview> | Esc → Select | cursor <x>, hint "<text>" |
| Pointing | pointerdown | > <4/6> px → Dragging; up → click action | Esc → cancel | ... |
| Dragging / Chaining | ... | ... | digits → value buffer; Tab lock; Enter commit; Esc cancel | ghost, live <length/angle>, snap marker + label |
| (Typing) | first digit | mouse steers free value | Backspace, Tab, Enter, Esc | value at cursor, lock icons |

### Input map
- Pointer: click = <...>; drag = <...>; double-click = <...>; right-click = <...>.
- Modifiers (held): start from the default map (SKILL law 10): Shift = constrain / add; Alt = from centre / duplicate; Cmd (Mac) / Ctrl (Win) = bypass snap; Space = pan. List every deviation. No Ctrl-click actions on macOS.
- Keys: <tool keys>; shortcuts suppressed while typing a value or in text fields.
- Typed values: syntax <3.2 | 320cm | 3.2,1.8 | +0.5>; default unit <m>; which length <centreline/face>.

### Snapping
Targets in priority order: <...>. Capture <10> px, release <15> px. Bypass: <modifier>. Toggle: <where>. Feedback: <marker + label + guide>.

### Validation and refusal
Rules checked live: <...>. Shown: red + dashed ghost, culprit highlighted, reason at cursor "<example>". On release: <snap back | stop at last valid position>, no history entry for the refused part. Announced once. Typed value refused: field stays open, tinted. Remote/server refusal: <...>.
Warnings (allowed): <...> shown as <indicator>.

### Commit and undo
Commit on <release/click/Enter>. Undo granularity: <per segment / per gesture>. Undo mid-gesture: <...>. Cancel ≠ undo.

### Collaboration
Remote change under the gesture: <cancel + reason / re-validate>. Presence: <ghost broadcast or not>. Undo is per user.

### Non-drag and keyboard path (WCAG 2.5.7 / 2.1.1)
<inspector fields / click-click / keyboard cursor>. Announced: "<live region text>".

### Touch and pen
<thresholds, two-step placement, loupe>.

### Numbers
Drag threshold <4/6 px>, hit margin <px>, handle <visual/hit px>, snap <capture/release px>, nudge <world units>, frame budget <ms> at <N> elements.

### Out of scope (stated constraint)
<what the tool deliberately doesn't do, and what the user sees if they try>.

### Acceptance scenarios (scripted gestures)
1. <click, type 3.5, Enter, double-click → two walls, one joint>
2. <drag across an existing wall → red ghost, reason "...", release → unchanged, undo stack unchanged>
3. <Esc mid-drag → original state, redo empty>
```

## Example: a filled section

```markdown
### Validation and refusal
Rules checked live: segment ≥ 5 cm; no crossing an existing wall except at a snapped joint;
no collinear overlap. Shown: preview red + dashed; the crossed wall outlined red; tag at the
cursor "Crosses the kitchen wall". Click on an invalid point: nothing placed, anchor unchanged,
tag stays until the pointer moves. Typed 2.4 refused: field stays open, red, text kept.
Server refusal after optimistic commit: segment fades out, note at its midpoint
"Removed: conflicts with Ana's wall", chain continues from the last accepted joint.
Warnings: wall closer than 60 cm to a parallel wall → amber hatch between them, not blocking.
```
