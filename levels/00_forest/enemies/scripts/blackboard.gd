class_name Blackboard
extends Resource

var health : float = 1
var target : Player = null
var distance_to_target : float = 0
var can_decide : bool = true
var edge_detected : bool = false
var damage_source : AttackArea = null
var dir : float = 0
var force : float = 1.0
var damage_element: DamageType.DamageElement = DamageType.DamageElement.PHYSICAL
var damage_type: DamageType.DamageType = DamageType.DamageType.LIGHT
var shield_active : bool = false
var is_aiming : bool = false
var target_position : Vector2 = Vector2.ZERO

func update_distance_to_target( pos : Vector2 ) -> void:
	if target:
		distance_to_target = pos.distance_to( target_position )
	else:
		distance_to_target = -1
	pass
