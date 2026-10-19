@tool

extends CollisionPolygon2D



var polygon2d: Polygon2D



func _ready() -> void:
	polygon2d = $"../../Polygon2D" as Polygon2D
	polygon = polygon2d.polygon
