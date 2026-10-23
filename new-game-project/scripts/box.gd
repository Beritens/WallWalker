extends Area2D

@export var strength := 800.0

func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	var direction = global_transform.x
	if body.is_in_group("playerBody"):
		var movement = body.get_node("Movement") as MovementComponent
		movement.push(direction * strength)
