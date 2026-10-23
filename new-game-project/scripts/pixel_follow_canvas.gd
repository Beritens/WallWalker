class_name PixelFollowCanvas
extends Control


var pixelSize: int
var target: Node2D
var zoom: float

# Called when the node enters the scene tree for the first time.
func setup(target_: Node2D, pixelSize_: int, zoom_: float) -> void:
	pixelSize = pixelSize_
	target = target_
	zoom = zoom_
	size /= zoom
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target == null:
		return
	var targetPos = target.position
	var px = floorf(targetPos.x / (pixelSize/zoom)) * (pixelSize/zoom)
	var py = floorf(targetPos.y / (pixelSize/zoom)) * (pixelSize/zoom)
	position = Vector2(px-size.x/2,py-size.y/2)
	pass
