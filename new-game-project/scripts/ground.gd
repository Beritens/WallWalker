@tool
extends Path2D


@export_tool_button("Make Resource Unique")
var make_unique_button: Callable = _make_resource_unique

func _make_resource_unique() -> void:
	if curve == null:
		return

	curve = curve.duplicate()
	$"Polygon2D".polygon = $"Polygon2D".polygon.duplicate()
	
	notify_property_list_changed()
