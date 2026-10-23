class_name MoveAlongClosestPath
extends Node2D

@export var speed := 400.0

var path: Path2D = null
var progress := 0.0
var direction := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	set_process(false)
	_initialize_path.call_deferred()


func _initialize_path() -> void:
	path = findClosestPath(global_position)

	if path == null:
		push_error("No path found.")
		return

	progress = path.curve.get_closest_offset(
		path.to_local(global_position)
	)

	set_process(true)

func findClosestPath(point: Vector2) -> Path2D:
	var paths: Array[Path2D] = []
	paths.assign(get_tree().get_nodes_in_group("path"))
	var closest_path: Path2D
	var dist := 1000000000.0
	for p in paths:
		var closest_point = p.curve.get_closest_point(p.to_local(point))
		var closest_global_point = p.to_global(closest_point)
		var d = (closest_global_point - point).length()
		if d < dist:
			dist = d
			closest_path = p
		
	return closest_path

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress = fposmod(
		progress + speed * delta * direction,
		path.curve.get_baked_length()
	)
	var sampled := path.curve.sample_baked_with_rotation(progress)
	var sampled_global := path.global_transform * sampled
	
	global_position = sampled_global.origin
	global_rotation = sampled_global.get_rotation()
	pass
