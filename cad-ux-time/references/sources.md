# Sources and credits

Researched 2026-10-17. Values marked "(unverified)" in the reference files were not confirmed from a primary source; treat them as starting points to tune.

## Skills this one distils (ideas, not copied text)

| Skill | Licence | What was taken |
|---|---|---|
| [szilu/ux-designer-skill](https://github.com/szilu/ux-designer-skill) | MIT | Canvas navigation and object references, collaboration presence, reference-values table, review findings format. Its screen-px grid and Tab-to-select-next were *not* taken (wrong for CAD). |
| [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) | MIT | Chrome rules: drag `inert`, gesture alternatives, tooltip grouping, platform-specific shortcut symbols, destructive-action rules, focus. |
| [emilkowalski/skills](https://github.com/emilkowalski/skills) (apple-design, emil-design-eng, break-ui) | MIT | Glued-to-pointer drags with grab offset and pointer capture, respond on pointer-down, never animate frequent or keyboard actions, multi-touch protection, worst-case data. |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 | "Operate" mode for tools: every component's seven states, 150–250 ms transitions, inline before modal; Nielsen-scored critique idea. |
| [Dammyjay93/interface-design](https://github.com/Dammyjay93/interface-design) | MIT | Density in px for tool panels, sidebars share the canvas background, native or headless before hand-rolled, the hand-rolled behaviour contract. |
| [dembrandt/dembrandt-skills](https://github.com/dembrandt/dembrandt-skills) (operational-expert-tool-ui) | MIT | Expert-tool priorities, persisted panel state, shortcuts in tooltips, no right-click-only actions. |
| [OneRedOak/claude-code-workflows design-review](https://github.com/OneRedOak/claude-code-workflows/tree/main/design-review) | MIT | "Live environment first" review, Blocker/High/Medium/Nit triage. |
| [anthropics/skills frontend-design](https://github.com/anthropics/skills/tree/main/skills/frontend-design) | Apache-2.0 | Copy rules: buttons say what happens, errors never vague or apologetic, empty screens invite action. |

## Products and primary docs

- tldraw: [tools](https://tldraw.dev/sdk-features/tools), [snapping](https://tldraw.dev/sdk-features/snapping), [camera](https://tldraw.dev/sdk-features/camera), [history](https://tldraw.dev/sdk-features/history), [collaboration](https://tldraw.dev/sdk-features/collaboration), [accessibility](https://tldraw.dev/sdk-features/accessibility), [options.ts defaults](https://raw.githubusercontent.com/tldraw/tldraw/main/packages/editor/src/lib/options.ts)
- Excalidraw: [hint strings, en.json](https://raw.githubusercontent.com/excalidraw/excalidraw/master/packages/excalidraw/locales/en.json)
- Figma:
  - [multiplayer tech](https://www.figma.com/blog/how-figmas-multiplayer-technology-works/) · [multiplayer editing](https://www.figma.com/blog/multiplayer-editing-in-figma/) · [Figma, faster](https://www.figma.com/blog/figma-faster/)
  - [UI3 approach](https://www.figma.com/blog/our-approach-to-designing-ui3/) · [UI3 redesign](https://www.figma.com/blog/behind-our-redesign-ui3/)
  - [canvas accessibility](https://www.figma.com/blog/building-accessibility-into-a-canvas-based-product/) · [keyboard accessibility](https://www.figma.com/blog/introducing-keyboard-accessibility-features/)
  - [Smart Selection](https://www.figma.com/blog/introducing-smart-selection/) · [select layers](https://help.figma.com/hc/en-us/articles/360040449873) · [zoom](https://help.figma.com/hc/en-us/articles/360041065034) · [measure distances](https://help.figma.com/hc/en-us/articles/360039956974) · [follow](https://help.figma.com/hc/en-us/articles/360040322673) · [quick actions](https://help.figma.com/hc/en-us/articles/23570416033943-Use-quick-actions)
- AutoCAD:
  - [Dynamic Input](https://help.autodesk.com/cloudhelp/2021/ENU/AutoCAD-LT/files/GUID-38EC86CF-D96A-455F-A5DE-2CDA23C28FC4.htm) · [Dynamic Input settings](https://help.autodesk.com/cloudhelp/2021/ENU/AutoCAD-LT/files/GUID-A265C30C-CFD8-405D-BEE2-257B379475E2.htm)
  - [AutoSnap / Drafting](https://help.autodesk.com/cloudhelp/2024/ENU/AutoCAD-LT/files/GUID-33A0F8E8-9981-4111-AD73-128B20D7975C.htm) · [object snap tracking](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-LT/files/GUID-665DC37F-8C3E-414A-9369-72A13C0BE07A.htm)
  - [temporary overrides](https://www.cad-notes.com/10-autocad-temporary-override-keys/)
- BricsCAD: [drawing accurately](https://help.bricsys.com/en-us/document/bricscad/getting-started-with-bricscad/working-in-bricscad/how-to-draw-accurately)
- SketchUp: [drawing basics and the Measurements box](https://help.sketchup.com/en/sketchup/introducing-drawing-basics-and-concepts) · [basic shapes](https://help.sketchup.com/en/sketchup/drawing-basic-shapes)
- Onshape: [automatic inferencing](https://cad.onshape.com/help/Content/Sketch/automatic_inferencing.htm) · [follow mode](https://cad.onshape.com/help/Content/Collaboration/follow_mode.htm)
- Rhino: [object snaps](https://docs.mcneel.com/rhino/9/help/en-us/user_interface/object_snaps.htm)
- Rayon: [shortcuts](https://docs.rayon.design/documentation/design/shortcuts)
- magicplan: [change dimensions](https://help.magicplan.app/change-dimensions-of-your-floor-plan) · ArcSite: [drawing walls](https://support.arcsite.com/en/articles/7258181-drawing-walls)
- Blender: [number fields](https://docs.blender.org/manual/en/4.1/interface/controls/buttons/fields.html)
- Procreate: [gestures](https://help.procreate.com/procreate/handbook/interface-gestures/gestures) · Apple HIG: [Pencil and Scribble](https://developer.apple.com/design/human-interface-guidelines/apple-pencil-and-scribble)
- Liveblocks: [multiplayer undo/redo](https://liveblocks.io/blog/how-to-build-undo-redo-in-a-multiplayer-environment)
- Ink & Switch: [Slow Software](https://www.inkandswitch.com/slow-software/) · [Local-first](https://www.inkandswitch.com/essay/local-first/)
- Browser input: [MDN getPredictedEvents](https://developer.mozilla.org/en-US/docs/Web/API/PointerEvent/getPredictedEvents) · [WebKit bug 230545 (pinch as ctrlKey wheel)](https://bugs.webkit.org/show_bug.cgi?id=230545) · [tldraw quick zoom release notes](https://tldraw.dev/blog/release-notes-20230428)
- Snap hysteresis: [Flutter StickySnap](https://pub.dev/documentation/resizable_splitter/latest/resizable_splitter/StickySnap-class.html) · OhSnap (CHI 2011)

## Guidelines and research

- NN/g:
  - [modes](https://www.nngroup.com/articles/modes/) · [direct manipulation](https://www.nngroup.com/articles/direct-manipulation/) · [drag and drop](https://www.nngroup.com/articles/drag-drop/)
  - [indicators, validations, notifications](https://www.nngroup.com/articles/indicators-validations-notifications/) · [accelerators](https://www.nngroup.com/articles/ui-accelerators/)
  - [icon usability](https://www.nngroup.com/articles/icon-usability/) · [empty states](https://www.nngroup.com/articles/empty-state-interface-design/)
- WCAG 2.2: [2.5.1 Pointer Gestures](https://www.w3.org/WAI/WCAG22/Understanding/pointer-gestures.html) · [2.5.2 Pointer Cancellation](https://www.w3.org/WAI/WCAG22/Understanding/pointer-cancellation.html) · [2.5.7 Dragging Movements](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html) · [2.5.8 Target Size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)
- Microsoft: [touch targeting](https://learn.microsoft.com/en-us/windows/apps/design/input/guidelines-for-targeting)
- Drafting: [architectural line weights](https://learnarchitecture.net/articles/39292-architectural-line-weights.html) · [dimensioning](https://www.nobledesktop.com/learn/blueprint-reading/understanding-dimensioning-in-architecture-and-engineering-a-detailed-explanation)
