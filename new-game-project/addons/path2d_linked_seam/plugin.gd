@tool
extends EditorPlugin

const SeamLink = preload("seam_link.gd")

var _button: Button
var _selection: EditorSelection
var _path: Path2D
var _links: Dictionary = {}


func _enter_tree() -> void:
	_button = Button.new()
	_button.name = "Path2DLinkEnds"
	_button.text = "Link Ends"
	_button.toggle_mode = true
	_button.focus_mode = Control.FOCUS_NONE
	_button.hide()
	_button.toggled.connect(_on_toggled)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, _button)

	_selection = get_editor_interface().get_selection()
	_selection.selection_changed.connect(_on_selection_changed)
	scene_changed.connect(_on_scene_changed)
	_on_scene_changed(get_editor_interface().get_edited_scene_root())
	_on_selection_changed()


func _exit_tree() -> void:
	set_process(false)
	_selection.selection_changed.disconnect(_on_selection_changed)
	scene_changed.disconnect(_on_scene_changed)
	for link in _links.values():
		link.stop()
	_links.clear()
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, _button)
	_button.queue_free()
	_path = null


func _process(_delta: float) -> void:
	# Also catches replacing the Curve resource in the Inspector.
	_refresh_button()


func _on_selection_changed() -> void:
	_path = null
	var nodes := _selection.get_selected_nodes()
	if nodes.size() == 1 and nodes[0] is Path2D:
		_path = nodes[0] as Path2D
	_refresh_button()


func _on_scene_changed(root: Node) -> void:
	for id in _links.keys():
		if _links[id].get_curve() == null:
			_links.erase(id)
	if root != null:
		_watch_scene(root)


func _watch_scene(node: Node) -> void:
	if node is Path2D:
		_watch_curve((node as Path2D).curve)
	for child in node.get_children():
		_watch_scene(child)


func _watch_curve(curve: Curve2D) -> void:
	if curve == null:
		return
	var id := curve.get_instance_id()
	if not _links.has(id):
		var link := SeamLink.new()
		_links[id] = link
		link.watch(curve)


func _refresh_button() -> void:
	if not is_instance_valid(_path) or not _path.is_inside_tree():
		_button.hide()
		return
	_button.show()
	var curve := _path.curve
	_watch_curve(curve)
	var enabled := SeamLink.is_enabled(curve)
	var closed := SeamLink.is_closed(curve)
	_button.set_pressed_no_signal(enabled)
	_button.disabled = curve == null or (not closed and not enabled)
	if enabled and not closed:
		_button.tooltip_text = "Linking paused: close the curve again, or turn Link Ends off."
	elif not closed:
		_button.tooltip_text = "Use Godot's Close Curve button first."
	else:
		_button.tooltip_text = "Keep the endpoints together and mirror both seam handles."


func _on_toggled(enabled: bool) -> void:
	if not is_instance_valid(_path) or _path.curve == null:
		return
	var curve := _path.curve
	if enabled and not SeamLink.is_closed(curve):
		_refresh_button()
		return
	_watch_curve(curve)

	var undo := get_undo_redo()
	var label := "Link Path2D Ends" if enabled else "Unlink Path2D Ends"
	undo.create_action(label, UndoRedo.MERGE_DISABLE, _path)
	undo.add_do_method(curve, "set_meta", SeamLink.META_KEY, enabled)
	# Undo metadata first so restoring the original independent handles is
	# not interpreted as another linked-handle edit.
	if curve.has_meta(SeamLink.META_KEY):
		undo.add_undo_method(
			curve, "set_meta", SeamLink.META_KEY, curve.get_meta(SeamLink.META_KEY)
		)
	else:
		undo.add_undo_method(curve, "remove_meta", SeamLink.META_KEY)

	if enabled:
		var last := curve.point_count - 1
		var handle := curve.get_point_out(0)
		if handle == Vector2.ZERO:
			handle = -curve.get_point_in(last)
		undo.add_do_method(curve, "set_point_out", 0, handle)
		undo.add_do_method(curve, "set_point_in", last, -handle)
		undo.add_undo_method(curve, "set_point_out", 0, curve.get_point_out(0))
		undo.add_undo_method(curve, "set_point_in", last, curve.get_point_in(last))

	# Metadata alone does not emit Resource.changed. This also refreshes
	# watchers on undo/redo when no handle setter needs to run.
	undo.add_do_method(curve, "emit_changed")
	undo.add_undo_method(curve, "emit_changed")
	undo.commit_action()
	_refresh_button()
