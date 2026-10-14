# Draw in Godot

`DrawCanvas` extends `Node2D`. Move, rotate, or scale it, or parent it to a player so the drawings follow the player at runtime. Choose **Select** in the Draw toolbar to manipulate the canvas with the normal editor tools.

For scenes made with the older `Node`-based canvas, change the canvas node's type to `Node2D`, keeping its script and children.

Enable the plugin under **Project > Project Settings > Plugins**, add a `DrawCanvas`, and select it in the scene tree. In the 2D viewport's **Draw** toolbar:

- **Pen:** left-click and drag to draw, without holding Alt.
- **Eraser:** click a line to remove its whole stroke and optional fill, or drag across several lines. Each gesture can be undone and redone.
- **Select:** use normal editor controls.
- **Pen Pressure:** toggle variable thickness for future tablet strokes. The toggle is saved per canvas and is also in the Inspector. Existing strokes keep their widths.

With pressure enabled, **Line Width** is the maximum thickness and **Minimum Pressure Width** controls the lightest thickness as a fraction of it (10% by default). Godot's native tablet pressure input is used, including on Linux. Mouse input and devices without pressure keep the full width. Pressure curves are saved with the scene.

Middle mouse, Alt-click, and Space-drag work for editor navigation. Editor zoom/pan and stroke transforms are supported; the scene root can be moved away from the origin. Eraser supports strokes created by earlier plugin versions.
