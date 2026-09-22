@icon("uid://ce4oo0s1yto54")
class_name DamageArea
extends Area2D
signal damage_taken( attack_area )
signal damage_effect(attack: AttackArea, target_element: DamageType.DamageElement)
signal invulnerability_ended
@export var audio : AudioStream
@export var element: DamageType.DamageElement = DamageType.DamageElement.PHYSICAL
var _invuln_id : int = 0
func _ready() -> void:
	pass
func take_damage ( attack_area : AttackArea ) -> void:
	damage_taken.emit( attack_area )
	damage_effect.emit(attack_area, element)
	
	if audio:
		Audio.play_spatial_sound( audio, global_position, false, false, 0.4 )
	pass
func make_invulnerable( duration : float = 1.0 ) -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
	_invuln_id += 1
	var this_id := _invuln_id
	
	await get_tree().create_timer( duration ).timeout
	
	if this_id != _invuln_id:
		return # a newer make_invulnerable call has superseded this one
	
	process_mode = Node.PROCESS_MODE_INHERIT
	invulnerability_ended.emit()
	pass
func start_invulnerable() -> void:
	_invuln_id += 1
	process_mode = Node.PROCESS_MODE_DISABLED
	pass
	
func end_invulnerable() -> void:
	_invuln_id += 1
	process_mode = Node.PROCESS_MODE_INHERIT
	invulnerability_ended.emit()
	pass
func flip_damage_area( direction_x : float ) -> void:
	if direction_x > 0:
		scale.x = 1
		position.x = abs(position.x)
	elif direction_x < 0:
		scale.x = -1
		position.x = -abs(position.x)
	pass
