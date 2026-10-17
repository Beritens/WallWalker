class_name MovementComponent
extends Node

@onready var body: CharacterBody2D = get_parent()
@export var followHandler: FollowHandler
@export var target: PathFollow2D

@onready var sprite: Node2D = $"../Art"


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var source: Node
@export var attach_signal: StringName

signal detach()

# if no path follower:
# freefall: add gravity, move with velocity

# if path follower:
# move to follower position

#jump:
# get follower rotation
# set velocity based on folower speed and normal (just add the vectors)

func _ready() -> void:
	if source == null or not source.has_signal(attach_signal):
			return
	
	source.connect(attach_signal, _on_attach)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	#if not is_on_floor():
	
	if !followHandler.is_attached():
		body.velocity += body.get_gravity() * delta
		body.move_and_slide()
		return
		
		
	var target_position = target.global_position
	body.move_and_collide(target_position - body.global_position)
	
	sprite.rotation = target.rotation
	
	
	#body.global_position = target_position

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		followHandler.detach()
		
		var right = target.global_transform.x.normalized()
		var up = target.global_transform.y.normalized()
		
		body.velocity = Vector2.ZERO
		body.velocity += right * followHandler.currentSpeed * followHandler.direction
		body.velocity += up * JUMP_VELOCITY
		detach.emit()
	
	body.move_and_slide()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("move_left", "move_right")
	#if direction:
		#body.velocity.x = direction * SPEED
	#else:
		#body.velocity.x = move_toward(body.velocity.x, 0, SPEED)
		#
#func _physics_process(delta: float) -> void:
	## Add the gravity.
	##if not is_on_floor():
	#body.velocity += body.get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("jump"):
		#body.velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("move_left", "move_right")
	#if direction:
		#body.velocity.x = direction * SPEED
	#else:
		#body.velocity.x = move_toward(body.velocity.x, 0, SPEED)

	
	#body.move_and_slide()
	
func _on_attach(collider: Object, vel: Vector2) -> void:
	body.velocity = Vector2.ZERO
