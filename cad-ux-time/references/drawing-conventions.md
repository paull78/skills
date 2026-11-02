# Drawing conventions: how the canvas looks

Two layers of meaning share the canvas. Keep them apart:

- **The drawing** (walls, openings, objects, labels, dimensions) follows drafting conventions. It is monochrome, and its hierarchy comes from line weight, fill and lightness.
- **The interaction state** (hover, selection, snap, invalid, warning, collaborators) uses colour, and only colour roles reserved for it. Interaction overlays are *added* on top; they never recolour the drawing itself.

## Line-weight hierarchy (architectural plans)

Pen weights step by about √2: 0.13 · 0.18 · 0.25 · 0.35 · 0.50 · 0.70 · 1.00 mm. The rule is "the closer to the cut plane, the heavier the line".

| Element | Paper weight (mm) | Screen |
|---|---|---|
| Walls cut by the plan plane | 0.50–0.70 outline + solid or dense **poché** fill | Strongest element: filled, darkest (lightest in dark mode) |
| Secondary cut (low walls, columns) | 0.35–0.50 | |
| Seen elements below the cut: furniture, fixtures, door leaves | 0.25–0.35 | Medium-grey stroke, light fill |
| Door swings, floor finishes, window glazing | 0.13–0.18 | Thin, lighter |
| Dimensions, leaders, text frames | 0.18–0.25 | Thin, own grey |
| Hatching, grid | 0.13 or less | Lightest; grid below everything |
| Overhead elements (above the cut) | dashed, thin | Dashed |

Source: a single teaching reference (learnarchitecture.net). Office standards vary, so treat this as the order, not exact values. On screen, keep the *order* at every zoom. Draw interaction chrome at constant px, and clamp structural lines to a minimum of about 1–2 px.

## Elements

- **Walls.**
  - Filled polygons at their true thickness, with mitred or cleaned-up joints. No centreline in the default view.
  - Openings cut the fill.
  - At small scales (1:200) the poché alone carries the wall.
- **Doors.**
  - A gap in the wall.
  - The leaf drawn open, usually at 90°, as a medium line.
  - A thin quarter-circle arc for the swing.
  - Hinge side and swing direction must be unambiguous, because they drive clearance checks.
- **Windows.**
  - A gap in the wall with two or three thin parallel lines (glazing and sill) across the wall thickness.
  - Collapse to one line at small scales.
- **Furniture and fixtures.**
  - A simple outline with a light fill, never heavier than the walls.
  - Detail (pillows, burners) only when it is large enough on screen.
  - The front of the piece must be readable when orientation matters (a bed's head, a desk's seat side).
- **Room labels.**
  - Name plus area ("Living 18.4 m²") at the visual centre (polylabel), not the centroid.
  - A halo in the paper colour behind the text.
  - Hide or reduce to a dot when the room is smaller than the label.
- **Dimensions.**
  - Architectural style uses **tick or oblique marks, not arrowheads**.
  - Text above the line, upright, reading from the bottom or the right.
  - Extension lines start with a small gap from the object and overshoot the dimension line slightly.
  - Arrange them in **strings** outside the plan: overall, then rooms or bays, then openings. Smaller strings must add up to the larger ones.
  - **Rounding can break the sum:** 1.333 + 1.333 + 1.334 shows as 1.33 + 1.33 + 1.33 ≠ 4.00, and the same happens with imperial fractions. Show enough precision, or round the parts so they add up to the rounded total.
  - **State the reference** (face, centreline, finished surface), and never mix references in one string.
- **Grid.**
  - An adaptive 1-2-5 step, minor and major levels, fading in over a pixel range so no more than two or three levels show at once.
  - Lines *or* dots, never both.
  - Below the drawing.
- **Underlay (a traced picture).**
  - Shown dimmed, under the drawing.
  - Offer a toggle for a minimal-weight "wireframe" drawing style while tracing (Rayon).
  - Keep ink colours stable over a photo or PDF so the markup stays sharp (Apple HIG on drawing over content).

## Colour roles

| Role | Use | Notes |
|---|---|---|
| Ink | The drawing | Near-black on paper (not pure #000 on #FFF on screen) |
| Accent (self) | Hover, selection, your live measurements | One hue, for example blue |
| Snap / inference | Snap markers, guides, tracking lines | Distinct from selection and never red (SketchUp axis colours, Onshape orange; Figma's pink/red guides clash with "invalid") |
| Invalid | Refused previews | Red, always plus a dashed stroke and a reason text |
| Warning | Allowed but problematic (a blocked swing, a tight walkway) | Amber, persistent, with its own shape |
| Collaborators | Cursor, tag, selection per user | A palette that avoids the self accent, red and amber; stable per user |
| Underlay | A traced picture | Dimmed |

All roles need 3:1 contrast against the canvas in both themes (WCAG 1.4.11), and a non-colour cue where they carry meaning (1.4.1).

## Interaction overlays

- **Hover:** a thin accent outline (about 1–2 px), slightly outset.
- **Selected:** a stronger outline plus handles, and an optional light tint.
- **Handles:** about 8–10 px visual size, filled white with an accent stroke, a 24 px+ hit area, constant on screen.
- **Live measurement while drawing:** dimension style in the accent colour.
- **Remote selection:** an outline in the user's colour, dashed or otherwise distinct from your own, with no handles.
- **Z-order:** grid → underlay → floor fills → furniture → walls → openings → labels → dimensions → warnings → selection and hover → snap guides → cursors → ghost preview on top.

## Export and print

- **Paper weights in mm** at the sheet scale, black on white, whatever the screen theme.
- **No interaction overlays, cursors or warnings** unless the user asks for an "issues" print.
- **A title block with a scale bar and the stated scale** (1:50) and north if relevant. Text no smaller than about 2.5 mm on paper.
- **What you see on screen at "paper view" matches the PDF.** Users should be able to check the sheet before exporting.

## Review checklist

- [ ] Monochrome drawing; colour only for state roles; overlays added, never recolouring.
- [ ] Weight order: cut walls > seen items > swings and dimensions > grid; poché.
- [ ] Door, window and dimension conventions (ticks, strings, a stated reference).
- [ ] Constant-size chrome; minimum structural line width; LOD hiding with hysteresis.
- [ ] Colour roles at 3:1 in both themes; red always paired with a non-colour cue.
- [ ] Export is black on white at paper weights and matches the preview.
