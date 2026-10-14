@tool
extends EditorPlugin

enum Tool { SELECT, PEN, ERASER }

const POINT_SPACING := 2.0
const ERASER_RADIUS := 8.0

var active_canvas: DrawCanvas
var active_tool: Tool = Tool.PEN
var undo_redo: EditorUndoRedoManager
var toolbar: HBoxContainer
var pressure_toggle: CheckButton

var is_drawing := false
var is_erasing := false
var current_line: Line2D
var current_poly: Polygon2D
var stroke_group: Node2D
var gesture_canvas: DrawCanvas
var scene_root: Node
var pressure_samples := PackedFloat32Array()
var stroke_uses_pressure := false
var stroke_has_pressure := false
var last_pressure := 0.0
var erased_strokes: Array[Dictionary] = []
var previous_erase_position := Vector2.ZERO
var previous_accumulated_input := true


func _enter_tree() -> void:
	undo_redo = get_undo_redo()
	_create_toolbar()
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	get_window().focus_exited.connect(_finish_gesture)
	_on_selection_changed()


func _exit_tree() -> void:
	_finish_gesture()
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)
	get_window().focus_exited.disconnect(_finish_gesture)
	_set_active_canvas(null)
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	toolbar.queue_free()


func _create_toolbar() -> void:
	toolbar = HBoxContainer.new()
	var label := Label.new()
	label.text = "Draw:"
	toolbar.add_child(label)
	var tools := ButtonGroup.new()
	_add_tool_button("Select", "Use the normal 2D editor controls.", Tool.SELECT, tools)
	_add_tool_button("Pen", "Drag to draw a stroke. No modifier key needed.", Tool.PEN, tools)
	_add_tool_button("Eraser", "Click or drag across lines to remove whole strokes.", Tool.ERASER, tools)
	toolbar.add_child(VSeparator.new())
	pressure_toggle = CheckButton.new()
	pressure_toggle.text = "Pen Pressure"
	pressure_toggle.tooltip_text = "Use tablet pressure for new strokes. Mouse strokes keep their full width."
	pressure_toggle.toggled.connect(_on_pressure_toggled)
	toolbar.add_child(pressure_toggle)
	toolbar.hide()
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)


func _add_tool_button(text: String, tooltip: String, tool: Tool, group: ButtonGroup) -> void:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.toggle_mode = true
	button.button_group = group
	button.button_pressed = active_tool == tool
	button.pressed.connect(_set_tool.bind(tool))
	toolbar.add_child(button)


func _set_tool(tool: Tool) -> void:
	_finish_gesture()
	active_tool = tool


func _on_selection_changed() -> void:
	var selected := EditorInterface.get_selection().get_selected_nodes()
	_set_active_canvas(selected[0] if selected.size() == 1 and selected[0] is DrawCanvas else null)


func _set_active_canvas(canvas: DrawCanvas) -> void:
	if active_canvas == canvas:
		return
	_finish_gesture()
	if is_instance_valid(active_canvas):
		active_canvas.pressure_enabled_changed.disconnect(_on_pressure_setting_changed)
	active_canvas = canvas
	last_pressure = 0.0
	toolbar.visible = is_instance_valid(active_canvas)
	if active_canvas:
		active_canvas.pressure_enabled_changed.connect(_on_pressure_setting_changed)
		pressure_toggle.set_pressed_no_signal(active_canvas.pressure_enabled)


func _on_pressure_toggled(enabled: bool) -> void:
	if not is_instance_valid(active_canvas):
		return
	_finish_gesture()
	undo_redo.create_action("Toggle Pen Pressure", UndoRedo.MERGE_DISABLE, active_canvas)
	undo_redo.add_do_property(active_canvas, "pressure_enabled", enabled)
	undo_redo.add_undo_property(active_canvas, "pressure_enabled", active_canvas.pressure_enabled)
	undo_redo.commit_action()


func _on_pressure_setting_changed(enabled: bool) -> void:
	_finish_gesture()
	pressure_toggle.set_pressed_no_signal(enabled)


func _handles(object: Object) -> bool:
	return object is DrawCanvas


func _make_visible(visible: bool) -> void:
	toolbar.visible = visible and is_instance_valid(active_canvas)
	if not visible:
		_finish_gesture()


func _input(event: InputEvent) -> void:
	# A release outside the 2D viewport still has to finish the gesture.
	if (is_drawing or is_erasing) and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finish_gesture.call_deferred()


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if not is_instance_valid(active_canvas) or active_tool == Tool.SELECT:
		return false

	if event is InputEventMouseMotion:
		last_pressure = event.pressure
		if not is_drawing and not is_erasing:
			return false
		if not event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_finish_gesture()
			return false
		if is_drawing:
			_add_point(event.position, event.pressure)
		else:
			_erase_at(event.position, previous_erase_position)
			previous_erase_position = event.position
		return true

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Preserve the editor's pan gesture and shortcuts.
			if event.alt_pressed or event.ctrl_pressed or event.meta_pressed or Input.is_key_pressed(KEY_SPACE):
				return false
			_finish_gesture()
			if active_tool == Tool.PEN:
				_start_line(event.position)
			else:
				_begin_gesture()
				is_erasing = true
				previous_erase_position = event.position
				_erase_at(event.position, event.position)
			return true
		if is_drawing or is_erasing:
			if is_drawing:
				_add_point(event.position, last_pressure, true)
			_finish_gesture()
			return true

	return false


func _begin_gesture() -> void:
	gesture_canvas = active_canvas
	scene_root = EditorInterface.get_edited_scene_root()
	previous_accumulated_input = Input.use_accumulated_input
	Input.use_accumulated_input = false


func _start_line(position: Vector2) -> void:
	_begin_gesture()
	if not scene_root:
		Input.use_accumulated_input = previous_accumulated_input
		return
	is_drawing = true
	stroke_uses_pressure = gesture_canvas.pressure_enabled
	stroke_has_pressure = false
	pressure_samples.clear()
	stroke_group = Node2D.new()
	stroke_group.name = "DrawnShape"
	gesture_canvas.add_child(stroke_group, true)
	stroke_group.owner = scene_root

	if gesture_canvas.has_polygon:
		current_poly = Polygon2D.new()
		current_poly.name = "Polygon"
		current_poly.color = gesture_canvas.polygon_color
		stroke_group.add_child(current_poly)
		current_poly.owner = scene_root

	current_line = Line2D.new()
	current_line.name = "Line"
	current_line.default_color = gesture_canvas.line_color
	current_line.width = gesture_canvas.line_width
	current_line.joint_mode = gesture_canvas.joint_mode
	current_line.begin_cap_mode = gesture_canvas.begin_cap_mode
	current_line.end_cap_mode = gesture_canvas.end_cap_mode
	stroke_group.add_child(current_line)
	current_line.owner = scene_root
	current_line.add_point(_editor_transform(current_line).affine_inverse() * position)
	pressure_samples.append(_pressure_width(last_pressure))
	_update_width_curve()


func _add_point(position: Vector2, pressure: float, force := false) -> void:
	if not is_instance_valid(current_line):
		_finish_gesture()
		return
	var transform := _editor_transform(current_line)
	var last_point := current_line.points[-1]
	var distance := (transform * last_point).distance_to(position)
	var width := _pressure_width(pressure)
	if distance >= POINT_SPACING or (force and distance > 0.001):
		current_line.add_point(transform.affine_inverse() * position)
		pressure_samples.append(width)
	elif stroke_has_pressure:
		pressure_samples[-1] = width
	_update_width_curve()
	if current_poly and current_line.get_point_count() >= 3:
		current_poly.polygon = current_line.points


func _pressure_width(pressure: float) -> float:
	if not stroke_uses_pressure:
		return 1.0
	if pressure > 0.0 and not stroke_has_pressure:
		stroke_has_pressure = true
		# Button events have no pressure; use the first tablet sample at the start too.
		pressure_samples.fill(clampf(pressure, gesture_canvas.minimum_pressure_width, 1.0))
	if not stroke_has_pressure:
		return 1.0
	return clampf(pressure, gesture_canvas.minimum_pressure_width, 1.0)


func _update_width_curve() -> void:
	if not stroke_has_pressure:
		return
	var curve := Curve.new()
	var lengths := PackedFloat32Array([0.0])
	for index in range(1, current_line.get_point_count()):
		lengths.append(lengths[-1] + current_line.points[index - 1].distance_to(current_line.points[index]))
	var total_length := lengths[-1]
	if is_zero_approx(total_length):
		curve.add_point(Vector2(0.0, pressure_samples[0]))
		curve.add_point(Vector2(1.0, pressure_samples[0]))
	else:
		for index in range(pressure_samples.size()):
			curve.add_point(Vector2(lengths[index] / total_length, pressure_samples[index]),
				0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	current_line.width_curve = curve


func _finish_gesture() -> void:
	if not is_drawing and not is_erasing:
		return
	Input.use_accumulated_input = previous_accumulated_input
	if is_drawing and is_instance_valid(stroke_group) and is_instance_valid(gesture_canvas):
		# Two nearly coincident points let Line2D render a click as a round dot.
		if current_line.get_point_count() == 1:
			current_line.add_point(current_line.points[0] + Vector2(0.001, 0.0))
			pressure_samples.append(pressure_samples[0])
			_update_width_curve()
		undo_redo.create_action("Draw Stroke", UndoRedo.MERGE_DISABLE, gesture_canvas)
		undo_redo.add_do_method(gesture_canvas, "add_child", stroke_group)
		_record_draw_owners(stroke_group)
		undo_redo.add_do_reference(stroke_group)
		undo_redo.add_undo_method(gesture_canvas, "remove_child", stroke_group)
		# The preview already contains the final geometry.
		undo_redo.commit_action(false)
	elif is_erasing and not erased_strokes.is_empty() and is_instance_valid(gesture_canvas):
		undo_redo.create_action("Erase Strokes", UndoRedo.MERGE_DISABLE, gesture_canvas)
		# Restore ascending sibling indices, including strokes erased out of order.
		erased_strokes.sort_custom(func(a: Dictionary, b: Dictionary): return a.index < b.index)
		for erased in erased_strokes:
			undo_redo.add_do_method(gesture_canvas, "remove_child", erased.node)
			undo_redo.add_undo_method(gesture_canvas, "add_child", erased.node)
			undo_redo.add_undo_method(gesture_canvas, "move_child", erased.node, erased.index)
			for owned in erased.owners:
				undo_redo.add_undo_property(owned.node, "owner", owned.owner)
			undo_redo.add_undo_reference(erased.node)
		undo_redo.commit_action(false)
	is_drawing = false
	is_erasing = false
	current_line = null
	current_poly = null
	stroke_group = null
	gesture_canvas = null
	scene_root = null
	pressure_samples.clear()
	erased_strokes.clear()


func _record_draw_owners(node: Node) -> void:
	undo_redo.add_do_property(node, "owner", scene_root)
	for child in node.get_children():
		_record_draw_owners(child)


func _collect_owners(node: Node, owners: Array[Dictionary]) -> void:
	owners.append({"node": node, "owner": node.owner})
	for child in node.get_children():
		_collect_owners(child, owners)


func _erase_at(position: Vector2, previous: Vector2) -> void:
	var strokes := gesture_canvas.get_children()
	strokes.reverse()
	for stroke in strokes:
		# Support strokes created by the original plugin as well.
		var line := stroke.get_node_or_null("Line") as Line2D
		if not line or not stroke is Node2D or not str(stroke.name).begins_with("DrawnShape"):
			continue
		if not line.is_visible_in_tree() or not _line_hit(line, previous, position):
			continue
		var owners: Array[Dictionary] = []
		_collect_owners(stroke, owners)
		var original_index := stroke.get_index()
		var removed_indices: Array[int] = []
		for erased in erased_strokes:
			removed_indices.append(erased.index)
		removed_indices.sort()
		for removed_index in removed_indices:
			if removed_index <= original_index:
				original_index += 1
		erased_strokes.append({"node": stroke, "index": original_index, "owners": owners})
		gesture_canvas.remove_child(stroke)
		# One click erases the uppermost hit; dragging can erase more strokes.
		return


func _editor_transform(item: CanvasItem) -> Transform2D:
	return item.get_viewport().global_canvas_transform * item.get_global_transform_with_canvas()


func _line_hit(line: Line2D, from: Vector2, to: Vector2) -> bool:
	var points := line.points
	if points.is_empty():
		return false
	var transform := _editor_transform(line)
	var scale_factor := maxf(transform.x.length(), transform.y.length())
	var lengths := PackedFloat32Array([0.0])
	for index in range(1, points.size()):
		lengths.append(lengths[-1] + points[index - 1].distance_to(points[index]))
	var total_length := lengths[-1]
	for index in range(maxi(1, points.size() - 1)):
		var next := mini(index + 1, points.size() - 1)
		var a := transform * points[index]
		var b := transform * points[next]
		var closest := Geometry2D.get_closest_points_between_segments(from, to, a, b)
		var width_factor := 1.0
		if line.width_curve:
			var segment_fraction := 0.0 if a.is_equal_approx(b) else a.distance_to(closest[1]) / a.distance_to(b)
			var offset := lerpf(lengths[index], lengths[next], segment_fraction)
			width_factor = line.width_curve.sample(0.0 if is_zero_approx(total_length) else offset / total_length)
		var radius := ERASER_RADIUS + line.width * width_factor * scale_factor * 0.5
		if closest[0].distance_to(closest[1]) <= radius:
			return true
	return false
