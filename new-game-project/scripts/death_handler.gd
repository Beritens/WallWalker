extends Node

@export var source: Node
@export var death_signal: StringName



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if source == null or not source.has_signal(death_signal):
		return
	source.connect(death_signal, _on_death)


func _on_death(collider: Object) -> void:
	get_tree().call_deferred("reload_current_scene")
