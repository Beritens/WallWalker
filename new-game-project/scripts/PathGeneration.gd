@tool
extends Path2D

var _update_pending := false

@export var offset_distance: float = 32.0:
	set(value):
		offset_distance = value
		_request_update()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	
	var shape : SS2D_Shape = get_parent()
	
	if shape == null:
		push_error("no shape")
		return
	
	if not shape.points_modified.is_connected(_request_update):
		shape.points_modified.connect(_request_update)
		
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
		
	# sample shape
	var shape : SS2D_Shape = get_parent()
	
	var generated_curve := Curve2D.new()
	var geometry := shape.get_point_array()
	
	var points := geometry.get_curve().tessellate()
	
	
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
	
	for point in outline:
		generated_curve.add_point(point)
	generated_curve.add_point(outline[0])
	
	curve = generated_curve
	
	
	# get offset polygon
	
	# change path
	pass
