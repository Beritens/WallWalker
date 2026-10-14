extends Node


@onready var body: CharacterBody2D = get_parent()

@export var source: Node
@export var detach_signal: StringName



signal hit_walkable(collider: Object)
signal hit_death(collider: Object)

var current: StaticBody2D

var last_vel: Vector2 = Vector2.ZERO



# if in freefall
# check collision
# if collision with walkable
# set attached object
# emit signal

func _ready() -> void:
	if source == null or not source.has_signal(detach_signal):
			return
	
	source.connect(detach_signal, _on_detach)

func _physics_process(delta: float) -> void:
		# Check all collisions from the last move_and_slide() call
	for i in range(body.get_slide_collision_count()):
		var collision = body.get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("walkable"):
			if collider != current:
				current = collider
				hit_walkable.emit(collider, last_vel)
				current.set_collision_layer_value(1, false) 
		if collider.is_in_group("death"):
			print("test")
			hit_death.emit(collider)
	last_vel = body.velocity
			
func _on_detach() -> void:
	current.set_collision_layer_value(1, true) 
	current = null
