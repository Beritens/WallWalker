extends Node
class_name FollowHandler

@export var source: Node
@export var attach_signal: StringName

@export var pathFollow: PathFollow2D

var attached = false

var jump_vel := Vector2.RIGHT
const JUMP_VELOCITY = -400.0

@export var pathFollowSpeed: float = 10.0
@export var body: CharacterBody2D


var direction = -1.0

#var jump_vector = Vector2.UP



# listen to collistion signal
# get path of collider
# get closest position value
# set path follower value
# move path follower to children of path

# update

# move path follower


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if source == null or not source.has_signal(attach_signal):
			return
	
	source.connect(attach_signal, _on_attach)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_left"):
		direction *= -1.0
	if attached:
		pathFollow.progress += direction * delta * pathFollowSpeed

func _on_attach(collider: Object, vel: Vector2) -> void:
	
	var path = collider.get_parent().get_node("Path2D") as Path2D
	var local_point = path.to_local(body.global_position)
	var progress = path.curve.get_closest_offset(local_point)
	

	
	pathFollow.reparent(path)
	pathFollow.progress = progress
	
	
	
	
	var right = pathFollow.global_transform.x.normalized()
	var dir = jump_vel.normalized()
	
	
	if dir.dot(vel.normalized()) < -0.0:
		dir = vel.normalized()
		
	
	var dot = right.dot(-dir)
	 
	
	if dot < 0.0:
		direction = 1.0
	else:
		direction = -1.0
	

	attached = true  
	
func is_attached() -> bool:
	return attached
	
func detach() -> void:
	var up = pathFollow.global_transform.y.normalized() * JUMP_VELOCITY
	var right = pathFollow.global_transform.x.normalized() * direction * pathFollowSpeed
	var dir = (up + right)
	jump_vel = dir
	attached = false
