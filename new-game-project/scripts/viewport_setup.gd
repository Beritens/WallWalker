extends Control

@onready var container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var display: TextureRect = $TextureRect

func _ready() -> void:
	container.stretch = true
	container.stretch_shrink = 3

	# Let the TextureRect display the result.
	container.hide()

	# Hiding the container disables its viewport's updates,
	# so enable them again AFTER hiding it.
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	display.texture = sub_viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
