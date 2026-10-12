extends Camera2D

@export var target: Node2D
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = position.lerp(target.global_position, 1.0 - 0.02**delta)
