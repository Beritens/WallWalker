extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	var player := get_tree().get_first_node_in_group("player")
	
	$"PhantomCamera2D".follow_target = player
