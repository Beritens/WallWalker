class_name Boxer
extends Node2D


@export var direction:= 1.0
@export var mainBody: MoveAlongClosestPath

func _ready() -> void:
	mainBody.direction = direction
	mainBody.scale.x = direction
