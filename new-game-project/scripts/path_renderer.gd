@tool
extends Line2D

var path: Path2D
var _curve: Curve2D

@export_range(0.1, 1000.0, 0.1, "or_greater")
var resolution: float = 10.0:
	set(value):
		resolution = maxf(value, 0.1)
		if is_node_ready():
			_on_parent_points_change()


func _ready() -> void:
	path = get_parent() as Path2D
	_sync_curve()
	_on_parent_points_change()


func _process(_delta: float) -> void:
	# Also handle replacing or clearing the entire Curve2D resource.
	_sync_curve()
	
func _sync_curve() -> void:
	var current_curve: Curve2D = path.curve if path != null else null

	if current_curve == _curve:
		return

	if _curve != null:
		_curve.changed.disconnect(_on_parent_points_change)

	_curve = current_curve

	if _curve != null:
		_curve.changed.connect(_on_parent_points_change)

	_on_parent_points_change()


func _on_parent_points_change() -> void:
	var sampled_points := PackedVector2Array()

	if _curve != null and _curve.point_count > 0:
		var length := _curve.get_baked_length()
		var distance := 0.0

		while distance < length:
			sampled_points.append(_curve.sample_baked(distance, true))
			distance += resolution

		# Always include the endpoint.
		if(not closed):
			sampled_points.append(_curve.sample_baked(length, true))

	points = sampled_points
