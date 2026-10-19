extends Node2D

@export var follow_handler: FollowHandler

@export var main: Node2D
@export var ikLeft: Node2D
@export var ikRight: Node2D


@export var mainFollow: PathFollow2D
@export var rightFollow: PathFollow2D
@export var leftFollow: PathFollow2D
@export var rightFollowTarget: PathFollow2D
@export var leftFollowTarget: PathFollow2D
@export var body: Node2D

@export var suctionCupLeft: Node2D
@export var suctionCupRight: Node2D
@export var ikEndLeft: PathFollow2D
@export var ikEndRight: PathFollow2D

@export var forwardFoot := 70.0
@export var backwardFoot := 40.0
@export var fooDistance:= 50.0

var groundPath: Path2D = null
var right_foot_active = true
var right_foot_was_active = true

@onready var _previous_body_position: Vector2 = body.global_position
@onready var _current_body_position: Vector2 = body.global_position
var _was_attached := false


# This node runs after Movement in the player scene. Keep both physics poses
# so the render-frame rig (and the camera following main) can move between ticks.
func _physics_process(_delta: float) -> void:
	_previous_body_position = _current_body_position
	_current_body_position = body.global_position
	if _was_attached and not follow_handler.attached:
		# Start the jump at the same path position the walking rig was using.
		_previous_body_position = mainFollow.global_position
	_was_attached = follow_handler.attached


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not follow_handler.attached:
		groundPath = null
		main.global_position = _previous_body_position.lerp(
			_current_body_position, Engine.get_physics_interpolation_fraction())
		
		
	else:
		
		
			
		main.global_rotation = mainFollow.global_rotation
		var new = false
		if(mainFollow.get_parent() != rightFollow.get_parent() or groundPath == null):
			new = true
			var path = mainFollow.get_parent()
			if path is Path2D:
				rightFollow.reparent(path)
				leftFollow.reparent(path)
				rightFollowTarget.reparent(path)
				leftFollowTarget.reparent(path)
			groundPath = mainFollow.get_parent().get_parent()
			
		
		rightFollowTarget.progress = mainFollow.progress + (forwardFoot if follow_handler.direction > 0.0 else -backwardFoot)
		leftFollowTarget.progress = mainFollow.progress + (-forwardFoot if follow_handler.direction < 0.0 else backwardFoot)
		
		if (rightFollow.global_position - rightFollowTarget.global_position).length() > fooDistance and not right_foot_active:
			right_foot_active = true
		elif (leftFollow.global_position - leftFollowTarget.global_position).length() > fooDistance and right_foot_active:
			right_foot_active = false
		
		print(right_foot_active)
		
		
		var weight := 1.0 - exp(-0.99 * delta)
		if right_foot_active:
			if(not right_foot_was_active):
				leftFollow.progress = leftFollowTarget.progress
			rightFollow.progress = lerpf(rightFollow.progress, rightFollowTarget.progress, weight)
		else:
			if(right_foot_was_active):
				rightFollow.progress = rightFollowTarget.progress
			leftFollow.progress = lerpf(leftFollow.progress, leftFollowTarget.progress, weight)
			
		right_foot_was_active = right_foot_active
		
		if(new):
			leftFollow.progress = leftFollowTarget.progress
			rightFollow.progress = rightFollowTarget.progress
		
		
		var global_positionR = rightFollow.global_position
		var global_positionL = leftFollow.global_position
		var normalR = rightFollow.global_transform.y
		var normalL = leftFollow.global_transform.y
		
		if(groundPath != null):
			var curve: Curve2D = groundPath.curve
			var local_point = groundPath.to_local(rightFollow.global_position)
			var progressR = curve.get_closest_offset(local_point)
			
			local_point = groundPath.to_local(leftFollow.global_position)
			var progressL = curve.get_closest_offset(local_point)
			
			var sampleR = groundPath.global_transform * curve.sample_baked_with_rotation(progressR)
			var sampleL = groundPath.global_transform * curve.sample_baked_with_rotation(progressL)
			global_positionR = sampleR.origin
			global_positionL = sampleL.origin
			
			normalR = sampleR.x.rotated(-PI / 2.0).normalized()
			normalL = sampleL.x.rotated(-PI / 2.0).normalized()
		
		
		main.global_position = mainFollow.global_position
		ikLeft.global_position = global_positionL + normalL * 10.0
		ikRight.global_position = global_positionR + normalR * 10.0
		
	_update_suction_cups.call_deferred()
	
		
func _update_suction_cups() -> void:
	ikEndLeft.progress_ratio = 1.0
	ikEndRight.progress_ratio = 1.0

	suctionCupLeft.global_position = ikEndLeft.global_position
	suctionCupRight.global_position = ikEndRight.global_position

	if follow_handler.attached:
		suctionCupLeft.global_rotation = leftFollow.global_rotation
		suctionCupRight.global_rotation = rightFollow.global_rotation
	else:
		suctionCupLeft.global_rotation = ikEndLeft.global_rotation - PI / 2.0
		suctionCupRight.global_rotation = ikEndRight.global_rotation - PI / 2.0


	
