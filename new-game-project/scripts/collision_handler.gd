extends Node
class_name CollisionHandler

@onready var body: CharacterBody2D = get_parent()

@export var source: Node
@export var detach_signal: StringName



signal hit_walkable(collider: Object, velocity: Vector2, position: Vector2)
signal hit_death(collider: Object)

var current: StaticBody2D

var last_vel: Vector2 = Vector2.ZERO
var pending_collisions: Array[KinematicCollision2D] = []



# if in freefall
# check collision
# if collision with walkable
# set attached object
# emit signal

func _ready() -> void:
	if source == null:
		return

	if source.has_signal(detach_signal):
		source.connect(detach_signal, _on_detach)
	if source.has_signal(&"collision_detected"):
		source.connect(&"collision_detected", _on_collision_detected)

func _on_collision_detected(collision: KinematicCollision2D) -> void:
	pending_collisions.append(collision)

func _physics_process(delta: float) -> void:
	# Movement forwards collisions from both movement methods for this tick.
	for i in range(pending_collisions.size()):
		var collision = pending_collisions[i]
		var collider = collision.get_collider()
		if collider.is_in_group("walkable"):
			if collider != current:
				current = collider
				hit_walkable.emit(collider, last_vel, collision.get_position())
				current.set_collision_layer_value(1, false) 
		if collider.is_in_group("death"):
			print("death")
			hit_death.emit(collider)
	pending_collisions.clear()
	last_vel = body.velocity
			
func _on_detach() -> void:
	current.set_collision_layer_value(1, true) 
	current = null
