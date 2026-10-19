@tool
extends RefCounted
## Watches one Curve2D without keeping the resource alive.

const META_KEY: StringName = &"_path2d_linked_seam"

var _curve_ref: WeakRef
var _previous := PackedVector2Array()
var _previous_count := 0
var _armed := false
var _updating := false


static func is_enabled(curve: Curve2D) -> bool:
	return curve != null and bool(curve.get_meta(META_KEY, false))


static func is_closed(curve: Curve2D) -> bool:
	return (
		curve != null
		and curve.point_count >= 3
		and curve.get_point_position(0).is_equal_approx(
			curve.get_point_position(curve.point_count - 1)
		)
	)


func watch(curve: Curve2D) -> void:
	_curve_ref = weakref(curve)
	_remember(curve)
	_armed = is_enabled(curve) and is_closed(curve)
	curve.changed.connect(_on_changed)


func stop() -> void:
	var curve := get_curve()
	if curve != null and curve.changed.is_connected(_on_changed):
		curve.changed.disconnect(_on_changed)
	_curve_ref = null


func get_curve() -> Curve2D:
	if _curve_ref == null:
		return null
	return _curve_ref.get_ref() as Curve2D


func _on_changed() -> void:
	if _updating:
		return
	var curve := get_curve()
	if curve == null:
		return
	if not is_enabled(curve) or curve.point_count < 3:
		_armed = false
		_remember(curve)
		return

	_updating = true
	var last := curve.point_count - 1
	if not _armed or curve.point_count != _previous_count:
		# An endpoint may have been deleted or a new point appended. Never
		# move an unrelated new endpoint to the start. Resume when closed again.
		_armed = is_closed(curve)
		if _armed:
			var handle := curve.get_point_out(0)
			if handle == Vector2.ZERO:
				handle = -curve.get_point_in(last)
			curve.set_point_position(last, curve.get_point_position(0))
			curve.set_point_out(0, handle)
			curve.set_point_in(last, -handle)
	else:
		# Only watch the visible seam handles. Godot also changes the unused
		# opposite handles on these endpoints when its mirror options are on.
		if curve.get_point_position(0) != _previous[0]:
			curve.set_point_position(last, curve.get_point_position(0))
		elif curve.get_point_position(last) != _previous[1]:
			curve.set_point_position(0, curve.get_point_position(last))

		if curve.get_point_out(0) != _previous[2]:
			curve.set_point_in(last, -curve.get_point_out(0))
		elif curve.get_point_in(last) != _previous[3]:
			curve.set_point_out(0, -curve.get_point_in(last))

	_remember(curve)
	_updating = false


func _remember(curve: Curve2D) -> void:
	_previous_count = curve.point_count
	_previous.clear()
	if _previous_count < 3:
		return
	var last := _previous_count - 1
	_previous = PackedVector2Array([
		curve.get_point_position(0),
		curve.get_point_position(last),
		curve.get_point_out(0),
		curve.get_point_in(last),
	])
