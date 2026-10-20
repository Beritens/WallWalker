@tool
extends Path2D

var _update_pending := false

@export var offset_distance: float = 32.0:
	set(value):
		offset_distance = value
		_request_update()

var path: Path2D
var _curve: Curve2D

var polygon2d: Polygon2D

var points: PackedVector2Array



func _ready() -> void:
	polygon2d = $"../Polygon2D" as Polygon2D


func _process(_delta: float) -> void:
	set_process(Engine.is_editor_hint())
	
	if not is_instance_valid(polygon2d):
		return

	var new_points := polygon2d.polygon
	if points != new_points:
		points = new_points
		_request_update()
	

func _request_update() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
		
	if _update_pending:
		return
	
	_update_pending = true
	_rebuild.call_deferred()

func _rebuild() -> void:
	_update_pending = false
	
	if not is_inside_tree():
		return
		
	
	var generated_curve := Curve2D.new()
	
	
	if points.size() > 1 and points[0].is_equal_approx(points[-1]):
		points.remove_at(points.size() - 1)

	if points.size() < 3:
		curve = generated_curve
		return
	
	var polygons := Geometry2D.offset_polygon(
		points,
		offset_distance,
		Geometry2D.JOIN_ROUND
	)
	
	
	if polygons.size() != 1:
		curve = generated_curve
		if polygons.size() > 1:
			push_warning("The offset produced multiple outlines (TODO: handle this)")
		else:
			return
	
	var outline := polygons[0]
	var count = 0
	
	for point in outline:
		if count == 0 or (point-generated_curve.get_point_position(count - 1)).length() > 0.01:
			generated_curve.add_point(point)
			count += 1
	generated_curve.add_point(outline[0])
	
	curve = generated_curve
	
	
	# get offset polygon
	
	# change path
	pass
