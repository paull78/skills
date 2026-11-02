# Panels, fields and app chrome

The chrome is the DOM around the canvas: tool bar, inspector, palettes, dialogs, menus. It follows the rules for web interfaces, tuned for an expert tool, where density and speed of action count for more than spaciousness.

## Layout

- **Choose docked or floating panels by density.**
  - Dense, property-heavy tools: docked, resizable panels. In Figma UI3, floating panels "slowed people down" and were reverted.
  - Light tools with a few controls (tldraw, Excalidraw): small floating bars that stay put and never cover the work area.
- **One home per concern:**
  - tools in one bar;
  - properties of the selection in one inspector;
  - document-level things (layers or states, pages) in one place;
  - status (scale, grid, snap toggle, sync) in one strip.
- **Give the drawing as much space as possible.** Offer a "minimise UI" toggle (Figma) and keep panels collapsible.
- **Panels share the canvas background** or sit one step off it. Separate them with low-contrast borders, not heavy shadows (interface-design).
- **Density is a decision expressed in px:** 12–16 px padding feels like a tool panel; 24 px+ feels like a marketing page. Keep it consistent.
- **Remember panel state** (open, collapsed, widths, the last tab) across reloads (dembrandt operational-expert-tool-ui).
- **Check narrow viewports.** The bar must not wrap over the canvas. Collapse secondary controls into an overflow menu first.

## Tool bar

- **Each button shows a tooltip with the name and the shortcut:** "Wall (W)". Tooltips use platform symbols (⌘ on Mac, Ctrl elsewhere). Delay the first tooltip in a group; once one is open, its neighbours appear without delay (Vercel).
- **The active tool is unmistakable:** a pressed state (`aria-pressed`) plus a cursor or hint change on the canvas.
- **Show the active tool's options next to the bar or in the inspector:** wall thickness, door kind, snap step. Show non-default values inline, not hidden behind a menu (Figma UI3).
- **No icon-only controls for anything that isn't universal.** NN/g found that only a handful of icons are recognised without labels. For rare tools, use a label, a tooltip at minimum, and an accessible name equal to the visible label (Figma UI3 found icon-only minimalism an accessibility "deal breaker").
- **Don't use native `<select>` inside a keyboard-driven tool bar** if it steals focus from canvas shortcuts. Use a popover or segmented control that returns focus to the canvas.

## Inspector and numeric fields

- **The inspector reflects the selection.** With nothing selected, show useful context: the document's properties, or the active tool's hint and shortcuts.
- **Group by meaning:** geometry (position, size, rotation), appearance, then domain properties. Units go inside the field ("85 cm"), not in a separate label.
- **Numeric fields (Blender is the reference):**
  - drag on the label or field to scrub (Shift fine, Ctrl stepped);
  - click to type; Esc cancels; Enter commits;
  - arrow keys step (Shift ×10);
  - Ctrl/Cmd+wheel steps only while hovered and focused, never by plain scroll;
  - math and units: `2.4m`, `240cm`, `3*1.2`, `+0.1` relative to the current value;
  - soft limits while dragging, hard limits while typing;
  - an invalid entry turns red, keeps the text, and is never committed silently;
  - **"Mixed"** for a multi-selection with different values.
- **Commit on Enter and on blur, as one undo step.** Live preview while scrubbing.
- **Use the right control:**
  - checkbox or switch over a dropdown when it saves a click;
  - segmented control for 2–5 options;
  - popover list beyond that.
- **Every field has a visible label.** Placeholder text is not a label.

## Shortcuts and discoverability

- **Every shortcut is discoverable without leaving the canvas:**
  - tooltips;
  - a searchable shortcut sheet on `?` (avoid Cmd/Ctrl+/, which opens Quick Actions in Figma) that can stay open while working (Figma docks it at the bottom);
  - a command palette on Cmd/Ctrl+K listing every action with its shortcut.
- **Keep the shortcut sheet complete.** A partial list misleads users and is worse than none. Include modifiers (Shift constrains, ⌘/Ctrl bypasses snapping, Space pans).
- **Give context hints for the active tool,** in one line, with a setting to turn them off (Excalidraw).
- **Always keep a non-accelerated path** to every action: a menu, a button, the palette. Never rely on right-click menus or shortcuts as the only path (NN/g, dembrandt).
- **Never override platform shortcuts.** Use platform-specific symbols. Respect keyboard layouts (see tools-and-input.md).

## Context menus

- **The right-click menu mirrors what is possible on the target:** edit actions, arrange, convert, delete. Each item shows its shortcut.
- **It is never the only path** to an action.
- **Provide a touch equivalent:** a long press of about 500 ms, or an overflow button on the selection.
- **On macOS, Ctrl-click opens it**, so Ctrl-click can't be a canvas action.
- **It is fine to disable the browser menu on the canvas** (`contextmenu` → `preventDefault`) only if you provide your own menu.

## Dialogs and overlays

- **Use inline or progressive UI before a modal.** "Modals are usually laziness" (Impeccable). A modal is fine for focused, rare tasks (export settings, project settings).
- **Modals:**
  - trap focus;
  - Esc closes;
  - focus returns to the trigger;
  - the primary action names the outcome;
  - don't stack modals.
- **Popovers close on outside click and on Esc,** without also clearing the canvas selection.
- **Hand-rolled widgets owe the full behaviour contract:** arrow keys, Enter, Esc, focus management, ARIA roles and states, outside click (interface-design). Prefer native elements or a headless primitive.

## Interactive states

Every control has default, hover, focus-visible, active, disabled, loading and error states (Impeccable "Operate" mode). The focus ring is visible on keyboard focus (`:focus-visible`), has 3:1 contrast, and is never removed without a replacement.

## Copy

- **Use the domain's words,** not the implementation's: "Layout", "Room", "Door", not "Entity", "Polygon", "Opening#3".
- **Buttons are verbs that say what happens.** The confirmation echoes them.
- **Error messages say what happened and how to fix it.** No apologies, no codes alone.
- **Use the same names everywhere:** the tool name, the tooltip, the shortcut sheet and the docs agree.

## Dark mode

- **Theme the chrome and the paper, keep the drawing's hierarchy.** Walls stay the strongest element, so in dark mode they become the lightest one. State colours stay recognisable.
- **Export and print stay black on white** whatever the theme.
- **Test colour roles at 3:1 or better in both themes:** selection, snap, warning, error, collaborator colours.
- **Follow `prefers-color-scheme` by default,** with an explicit override.

## Review checklist

- [ ] Docked or floating chosen by density, stable positions; panel state persists; no wrapping at narrow widths.
- [ ] Tooltips give the name and the shortcut; active tool shown twice; options shown inline.
- [ ] Numeric fields: scrub, type, step, math and units, Mixed, Esc cancels, one undo step.
- [ ] Complete shortcut sheet; command palette once there are about 20 actions; context hints.
- [ ] Modals only for rare focused tasks; full keyboard contract.
- [ ] All interactive states; visible focus; domain words.
- [ ] Dark mode keeps the drawing's hierarchy; export stays black on white.
