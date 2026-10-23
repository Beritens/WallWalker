extends Node2D


#find objects with script pixel_follow

@export var pixelSize: int
@export var zoom: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	for node:PixelFollow in get_tree().root.find_children("*", "PixelFollow", true, false):
		node.setup($Camera2D2, pixelSize, zoom)
	for node:PixelFollowCanvas in get_tree().root.find_children("*", "PixelFollowCanvas", true, false):
		node.setup($Camera2D2, pixelSize, zoom)
	
	var player := get_tree().get_first_node_in_group("player")
	
	$"PhantomCamera2D".follow_target = player
