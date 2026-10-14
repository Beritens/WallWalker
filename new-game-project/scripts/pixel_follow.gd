class_name PixelFollow

extends Camera2D


var pixelSize: int
var target: Node2D

# Called when the node enters the scene tree for the first time.
func setup(target_: Node2D, pixelSize_: int, zoom_: float) -> void:
	pixelSize = pixelSize_
	target = target_
	zoom = Vector2(zoom_, zoom_)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target == null:
		return
	var targetPos = target.position
	var px = floorf(targetPos.x / (pixelSize/zoom.x)) * (pixelSize/zoom.x)
	var py = floorf(targetPos.y / (pixelSize/zoom.y)) * (pixelSize/zoom.y)
	position = Vector2(px,py)
	pass
