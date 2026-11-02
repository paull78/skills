# Navigation: zoom, pan, view

## Input mapping

| Input | Action | Notes |
|---|---|---|
| Trackpad two-finger scroll | Pan | `wheel` with small deltas, often in both x and y |
| Trackpad pinch | Zoom at the cursor | Chrome and Firefox send `wheel` with `ctrlKey: true`. Safari has `gesture*` events; whether current Safari also sends `ctrlKey` wheels is contested (WebKit bug 230545), so handle both and `preventDefault` `gesturestart`. |
| Mouse wheel | Zoom at the cursor *or* pan | A user preference (tldraw `wheelBehavior`: pan / zoom / none). CAD users expect the wheel to zoom; design-tool users expect it to pan. A mouse wheel and two-finger trackpad scroll **can't be told apart reliably**, which is why this has to be a preference, and "wheel zooms" also turns trackpad scroll into zoom. |
| Cmd/Ctrl + wheel | Zoom at the cursor | Figma |
| Space + drag | Pan, from any tool, mid-gesture included | The universal design-tool quasimode |
| Middle-drag | Pan | CAD and design tools |
| Shift + wheel | Horizontal pan | For mice without horizontal scroll |
| Arrow keys with nothing selected | Pan (Shift = faster) | Figma; selected items nudge instead |
| Touch: one finger on empty canvas | Pan, or box-select in select mode | Decide per tool and document it |
| Touch: two-finger pinch / twist | Zoom / rotate the view (only if rotation is supported) | Procreate |

Rules:
- **Zoom around the cursor.** Keep the world point under the pointer fixed.
- **Make zoom proportional to the delta.** Trackpads send many small deltas, mice send a few large ones. Normalise `deltaMode` (lines and pages → px). Pinch deltas are tiny, so give `ctrlKey` wheels their own, larger gain.
- **Take the pointer position from `clientX - rect.left`**, not `offsetX`, which is relative to whatever child element is under the pointer (an overlay, a label).
- **Register wheel listeners `{ passive: false }`** and call `preventDefault`, so a pinch never zooms the browser page.
- **A real Ctrl+wheel can't be told apart from a pinch.** Both mean zoom, so this is fine.
- **Don't hijack scrolling inside panels.** Only the canvas element captures the wheel.
- **Any user input interrupts a running camera animation.**

```ts
// Zoom about the cursor, proportional to the wheel delta.
const LINE_PX = 16, PINCH_GAIN = 0.01, WHEEL_GAIN = 0.0015;   // tune by hand
function onWheel(e: WheelEvent) {
  e.preventDefault();                                   // listener registered { passive: false }
  const unit = e.deltaMode === 1 ? LINE_PX : e.deltaMode === 2 ? canvas.clientHeight : 1;
  const dx = e.deltaX * unit, dy = e.deltaY * unit;
  const rect = canvas.getBoundingClientRect();
  const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
  const pinch = e.ctrlKey;                              // trackpad pinch, or a real Ctrl+wheel
  if (pinch || e.metaKey || prefs.wheelZooms) {
    const before = cam.toWorld(sx, sy);
    cam.zoom = clamp(cam.zoom * Math.exp(-dy * (pinch ? PINCH_GAIN : WHEEL_GAIN)), MIN_ZOOM, MAX_ZOOM);
    const after = cam.toWorld(sx, sy);
    cam.center = { x: cam.center.x + before.x - after.x, y: cam.center.y + before.y - after.y };
  } else {
    cam.panByScreen(dx, dy);
  }
  requestRender();                                      // coalesced to one frame
}
```

## Standard view commands

| Shortcut | Command | Source |
|---|---|---|
| Shift+1 | Zoom to fit all content | Figma |
| Shift+2 | Zoom to the selection | Figma |
| Shift+0 or Cmd+0 | Zoom to 100% (don't fight the browser's Cmd+0 outside the canvas) | Figma |
| + / − (or Cmd+= / Cmd+−) | Zoom in or out in steps | Figma, tldraw steps `[0.1, 0.25, 0.5, 1, 2, 4, 8]` |
| Z (hold) | Quick zoom: zoom out to an overview, release to land where the pointer is | tldraw |
| Touch quick-pinch | Fit the canvas to the screen | Procreate |
| Zoom buttons (+, −, fit) | The single-pointer path for pinch (WCAG 2.5.1) | |

- **Open documents zoomed to fit**, with a margin of about 10%. Use a fixed view only for an empty document, centred on the origin at a sensible scale (for example a 10 m room filling about half the screen).
- **Clamp the zoom** to a useful range in world terms. For a floor plan: from a whole building on screen down to 1 cm being several px.
- **Remember the view per document and user** across reloads.

## Scale and orientation aids

- **Scale bar in world units** that resizes to round lengths (50 cm, 1 m, 2 m, 5 m). It is more useful than a zoom percentage, because "100%" means nothing for a building.
- **Zoom percentage or drawing scale** (1:50) in the status area, clickable to type a value.
- **Grid step chip** ("Grid 10 cm") next to the scale bar.
- **Rulers** along the edges, in world units, only for tracing or layout-heavy work. They cost screen space.
- **Minimap** only when documents are much bigger than the viewport. A floor plan rarely needs one; zoom-to-fit covers it.
- **Edge scroll while dragging** near the viewport edge. tldraw: 8 px edge zone, 200 ms delay before it starts, speed proportional to depth.

## Level of detail

- **Line widths, handle sizes and label text stay a constant size on screen.** Geometry scales.
- **Fade or hide detail by on-screen size, with hysteresis at the thresholds:**
  - labels when the room is smaller than the label;
  - door arcs and furniture symbols below a few px;
  - dimension text that no longer fits its span.
- **Apply a minimum on-screen width to structural lines** (about 1–2 px) so walls never vanish when zoomed out.

## Review checklist

- [ ] Zoom about the cursor, proportional to the delta, clamped.
- [ ] Pinch handled (`ctrlKey` wheel); the page never zooms.
- [ ] Trackpad pans; mouse wheel behaviour is a preference or follows a stated convention.
- [ ] Space-drag and middle-drag pan from any tool, mid-gesture included.
- [ ] Fit (Shift+1) and zoom to selection (Shift+2); the document opens fitted.
- [ ] Scale bar in world units; view remembered.
- [ ] Constant-size chrome; LOD with hysteresis; minimum line width.
