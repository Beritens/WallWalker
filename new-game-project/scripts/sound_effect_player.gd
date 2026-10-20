extends Node
class_name ASPOverlapping


var StreamPlayers: Array[AudioStreamPlayer] = []
var index: int = 0

func _ready() -> void:
	StreamPlayers.assign(get_children())
func play_audio(resource, volume: float):
	var node = StreamPlayers[index]
	
	node.volume_db = volume
	node.stream = resource
	node.play()
	
	index += 1
	if index > StreamPlayers.size() -1:
		index = 0
