
@tool
extends Line2D



var polygon2d: Polygon2D



func _ready() -> void:
	
	polygon2d = get_parent() as Polygon2D
	if not polygon2d.is_node_ready():
		await polygon2d.ready
	points = polygon2d.polygon

func _validate_property(property: Dictionary) -> void:
	if property.name == "points":
		property.usage &= ~PROPERTY_USAGE_STORAGE


func _process(_delta: float) -> void:
	set_process(Engine.is_editor_hint())
	
	if not is_instance_valid(polygon2d):
		return

	var new_points := polygon2d.polygon
	if points != new_points:
		points = new_points
