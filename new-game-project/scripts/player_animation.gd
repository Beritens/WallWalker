extends Node2D

@export var follow_handler: FollowHandler

@export var main: Node2D
@export var ikLeft: Node2D
@export var ikRight: Node2D


@export var mainFollow: PathFollow2D
@export var rightFollow: PathFollow2D
@export var leftFollow: PathFollow2D
@export var body: Node2D




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not follow_handler.attached:
		main.global_position = body.global_position
	else:
		main.global_rotation = mainFollow.global_rotation
		if(mainFollow.get_parent() != rightFollow.get_parent()):
			var path = mainFollow.get_parent()
			if path is Path2D:
				rightFollow.reparent(path)
				leftFollow.reparent(path)
		rightFollow.progress = mainFollow.progress + 100.0
		leftFollow.progress = mainFollow.progress - 100.0
		
		
		main.global_position = mainFollow.global_position
		ikLeft.global_position = leftFollow.global_position
		ikRight.global_position = rightFollow.global_position


	
