# Snapping and inference

Snapping is the precision engine of a canvas editor. Done well it feels like the tool reads your mind. Done badly it feels like the tool fights you. Three things decide which: it has to **explain itself**, it has to **stay put**, and it has to **give way** when the user wants it gone.

## Units: two kinds of number

| Measured in screen px (fixed under zoom) | Measured in world units (scales with zoom) |
|---|---|
| Snap capture radius (8–10 px) | Grid step, snap step, nudge step |
| Snap release radius (about 1.5–2× capture) | Angle increments (degrees) |
| Hit-test margin, handle size | Typed lengths, dimension values |
| Marker and label size | Geometry |

Convert screen to world at the moment of the test: `radiusWorld = radiusPx / pxPerUnit`. A snap radius stored in metres disappears when zoomed out and grabs everything when zoomed in. A grid stored in pixels produces coordinates like 0.2163 m that change with zoom, which corrupts the data. Of the two, the pixel grid is the worse bug.

Reference values:
- tldraw `snapThreshold`: 8 px.
- AutoCAD aperture: 1–50 px (configurable).
- BricsCAD dynamic-dimension aperture: 20 px.
- Common practice: 8–12 px for a mouse, larger for coarse pointers.

## Adaptive grid

- **Step in a 1-2-5 series of world units** (1, 2, 5, 10, 20, 50 cm …). Use the smallest step whose on-screen spacing is at least about 8–10 px.
- **Draw the grid you snap to.** Show the current step in a corner chip, for example "Grid 10 cm".
- **Make the grid the weakest snap.** It applies only when nothing else is in range.
- **Let the user pick a fixed snap step** when they need one (for example 1, 5, 10, 25, 50 cm, or Auto). Persist that choice, because users hate re-setting it after every reload.

## Priority order

Check in this order. The first candidate in range wins, except that axis snaps can combine (below).

1. **Exact points:** endpoint/joint/corner, intersection, the chain's own start point (closes the loop), then midpoint and centre.
2. **Geometric relations:** perpendicular foot, tangent, a point on an edge (makes a T-junction).
3. **Tracking and alignment:** horizontal and vertical lines through *acquired* points, extensions of existing lines, where two such lines cross.
4. **Angle increments:** 15°, measured from the world axes *and* from the previous segment.
5. **Length or step rounding:** snap step or grid.

Notes:
- **Translation snaps per axis.** Snap x and y independently (tldraw), so an object can align its left edge with one neighbour and its top with another at the same time.
- **Leave out the moving geometry** (the joint being dragged, the object being moved) from the candidates.
- **Prefer what is visible.** Off-screen candidates don't count.

## Feedback: say what you snapped to

AutoSnap is the reference pattern (AutoCAD). It has three parts:

1. **Marker**, a glyph whose shape encodes the type: □ endpoint, △ midpoint, ✕ intersection, ⊥ perpendicular, ○ centre. For the chain's start point (loop close), highlight the start joint itself with the word "Close". AutoCAD users read ◇ as Quadrant, so avoid it.
2. **Magnet**, the cursor visibly jumps to the point.
3. **Label**, a short word next to the marker: "Endpoint", "Midpoint", "Perpendicular", "15°".

A glyph on its own can't be learned in a five-minute session, so always pair it with the label. Other products follow the same idea:
- **SketchUp** adds coloured dots plus ScreenTips, and colours a line by the axis it aligns with.
- **Onshape** highlights the *related* entity in orange with a dotted connector.
- **tldraw and Figma** draw alignment lines and gap measurements.

Rules:
- **Draw alignment guides** as thin dashed lines from the source point to the snapped point, not across the whole viewport, so the user can see *what* it aligned to.
- **Show snap indicators only during a gesture or hover**, and clear them on release.
- **Wake inferences by proximity** (Onshape): relations appear only near the entity that causes them. That keeps the canvas quiet.
- **Give snap feedback one colour role**, distinct from selection and from invalid.

## Acquired tracking points (AutoCAD object snap tracking)

- **Acquire a point by hovering it briefly.** A small `+` marks it, and several points can be held at once (AutoCAD allows seven).
- **The cursor then gets alignment paths** from each acquired point: horizontal, vertical, polar.
- **Snap to where two paths cross.** This gives "in line with that corner and level with that one" without drawing construction lines.
- **A cheap version is enough for most apps:** aligned-x and aligned-y snaps to nearby joints, each with its dotted guide back to the source.

## Stickiness: hysteresis

Snap targets flicker when the cursor hovers near the boundary between two candidates, or at the edge of the capture radius. To stop it:

- **Capture within r; release only beyond R ≈ 1.5–2r.** Flutter `StickySnap`: "escape radius exceeding the capture radius is the hysteresis that prevents flicker". No source gives a canonical ratio, so start at 1.5 and tune it by hand.
- **Keep the current target** unless a new candidate is clearly closer, by a margin of a few px, or ranks higher in priority.
- **Snap at the start of a drag too.** OhSnap (CHI 2011) shows that an object can stay snapped briefly and then catch up with the pointer, which keeps small adjustments possible without jumping.

```ts
// Sticky snap: keep the current target until the pointer leaves R, or a better candidate wins.
// rank(): 0 = highest priority (endpoint), larger = weaker (grid last).
const CAPTURE_PX = 10, RELEASE_PX = 15;
function pickSnap(p: Pt, cands: Snap[], current: Snap | null, pxPerUnit: number): Snap | null {
  const r = CAPTURE_PX / pxPerUnit, R = RELEASE_PX / pxPerUnit;
  const best = cands.filter(c => dist(c.pt, p) <= r).sort(byPriorityThenDistance(p))[0] ?? null;
  if (current && dist(current.pt, p) <= R) {
    if (!best || rank(best) >= rank(current)) return current; // same or lower priority: stay
  }
  return best;
}
```

## Giving way

- **Per-gesture bypass.** Hold a modifier to switch snapping off for the current gesture. The default is Cmd on Mac and Ctrl on Windows (tldraw); Onshape uses Shift and some CAD tools Alt, but those keys usually mean constrain and duplicate already (SKILL law 10). Show the binding in the hint line ("Hold ⌘ to place freely").
- **Persistent toggle.** A visible snap on/off control in the status bar or tool bar (AutoCAD status bar, Rayon's bottom-right panel). Let users switch individual snap types on and off once there are more than about four.
- **Never make a position unreachable.** If snapping always pulls to the grid, the user can't place anything freely. Users of Sweet Home 3D and Lucid end up turning magnetism off entirely; that is a sign the override was missing.
- **Cycle between overlapping candidates with Tab**, mid-gesture with no typed value (AutoCAD; Rayon "flick through overlapping entities"). While a value is being typed, Tab locks it instead (SKILL law 5).

## Snapping furniture and objects

- **What objects snap to:** edges and centre lines of nearby objects, flush to wall faces, and walls' angles when rotating.
- **Show live distances to neighbours while moving.** Draw up to four dimension lines from the object's sides to the nearest obstacles, in the working unit (cm), in the accent colour. Figma's Alt-hover draws them in red, but here red means refused.
- **Auto-rotate to a wall only within a small angle**, and show that the object has turned.
- **Equal-spacing detection:** show equal-gap markers when the object is evenly spaced between neighbours (Figma smart guides).

## Review checklist

- [ ] Capture radius in px and converted at test time; grid and step in world units.
- [ ] Priority order written down and tested.
- [ ] Marker *and* label for every snap type; guides drawn from the source.
- [ ] Hysteresis (release radius > capture radius).
- [ ] Moving geometry excluded from the candidates.
- [ ] Per-gesture bypass modifier plus a persistent toggle; the snap step persists across reloads.
- [ ] Snap indicators cleared on release; colour role distinct from selection and invalid.
- [ ] Candidate search uses a spatial index, and a snap query fits within the frame budget (see performance-and-touch.md).
