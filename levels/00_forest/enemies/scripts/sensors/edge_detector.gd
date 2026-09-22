@icon( "uid://bdyfbpjv7vfx0" )

class_name EdgeDetector 
extends RayCast2D

signal edge_detected
signal edge_cleared

var colliding : bool = true
var enemy : Enemy



func _ready() -> void:

	set_collision_mask_value( 1, true )
	set_collision_mask_value( 2, true )
	if owner is Enemy:
		enemy = owner
		enemy.direction_changed.connect( direction_changed )
	pass



func _physics_process( _delta: float ) -> void:
	var _is_colliding : bool = is_colliding()
	
	if colliding != _is_colliding:
		colliding = _is_colliding
		if not colliding:
			edge_detected.emit()
			if enemy:
				enemy.blackboard.edge_detected = true
		else:
			edge_cleared.emit()
			if enemy:
				enemy.blackboard.edge_detected = false
	pass


func direction_changed( new_dir : float ) -> void:
	if new_dir < 0 and position.x > 0 or new_dir > 0 and position.x < 0:
		position.x *= -1
		force_raycast_update()
	pass
