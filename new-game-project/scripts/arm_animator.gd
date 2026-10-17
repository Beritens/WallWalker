@tool
extends Path2D


#main body
@export var body: Node2D

#arm base
@export var base: Node2D

#arm middle
@export var arm_middle: Node2D

#arm end
@export var arm_end: Node2D

#arm middle
@export var arm_middle_alt: Node2D



@export var curviness: float = 0.2

var side:float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (body == null or base == null or arm_middle == null or arm_end == null or arm_middle_alt == null):
		return
		
	var p0 := to_local(base.global_position)
	var middle_normal := to_local(arm_middle.global_position)
	var middle_alt := to_local(arm_middle_alt.global_position)
	var p3 := to_local(arm_end.global_position)
	
	var vec := (base.global_position - body.global_position).normalized()
	var vec2 := (arm_end.global_position - body.global_position).normalized()
	
	var curr_side = sign(vec.cross(vec2))
	
	side = lerpf(side,curr_side,1.0 - 0.02**delta)
	var s = (side + 1.0)/2.0
	var middle:Vector2 = middle_normal * s + middle_alt * (1.0 - s)
	var p1 := p0 * curviness + middle * (1.0 - curviness)
	var p2 := p3 * curviness + middle * (1.0 - curviness)
	
	
	
	curve.set_point_position(0, p0)
	curve.set_point_out(0, p1 - p0)
	curve.set_point_in(1, p2 - p3)
	curve.set_point_position(1, p3)
