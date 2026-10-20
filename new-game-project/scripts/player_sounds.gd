class_name PlayerSounds
extends Node

# array of sounds
@export var walk_db := 0.0
@export var walk_sounds: Array[AudioStream] = []
@export var jump_db := 0.0
@export var jump_sounds: Array[AudioStream] = []


func play_walk_sound() -> void:
	if walk_sounds.is_empty():
		return

	var random_sound: AudioStream = walk_sounds.pick_random()
	SoundEffectPlayer.play_audio(random_sound, walk_db)
	
func play_jump_sound() -> void:
	if jump_sounds.is_empty():
		return

	var random_sound: AudioStream = jump_sounds.pick_random()
	SoundEffectPlayer.play_audio(random_sound, jump_db)
