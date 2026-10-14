@tool
extends Node2D
class_name DrawCanvas

signal pressure_enabled_changed(enabled: bool)

@export_category("Line Configuration")
@export var line_color: Color = Color.WHITE
@export var line_width: float = 5.0

@export_category("Pen Pressure")
## Apply tablet pressure to new strokes. Mouse strokes remain full width.
@export var pressure_enabled: bool = false:
	set(value):
		if pressure_enabled == value:
			return
		pressure_enabled = value
		pressure_enabled_changed.emit(value)

## Fraction of Line Width used for the lightest tablet pressure.
@export_range(0.01, 1.0, 0.01) var minimum_pressure_width: float = 0.1

@export_category("Fill Configuration")
@export var has_polygon: bool = false
@export var polygon_color: Color = Color(1, 1, 1, 0.3)

@export_category("Cap & Joints")
@export var joint_mode: Line2D.LineJointMode = Line2D.LINE_JOINT_ROUND
@export var begin_cap_mode: Line2D.LineCapMode = Line2D.LINE_CAP_ROUND
@export var end_cap_mode: Line2D.LineCapMode = Line2D.LINE_CAP_ROUND
