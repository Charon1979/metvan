@icon("uid://ce4oo0s1yto54")

class_name DamageArea
extends Area2D

signal damage_taken( attack_area )
signal damage_effect( type )
@export var audio : AudioStream

var type: String = "light"

func _ready() -> void:
	pass


func take_damage ( attack_area : AttackArea ) -> void:
	damage_taken.emit( attack_area )
	damage_effect.emit()
	
	if audio:
		Audio.play_spatial_sound( audio, global_position )
	pass

func make_invulnerable( duration : float = 1.0 ) -> void:
	
	process_mode = Node.PROCESS_MODE_DISABLED
	await get_tree().create_timer( duration ).timeout
	process_mode = Node.PROCESS_MODE_INHERIT
	pass

func start_invulnerable() -> void:
	
	process_mode = Node.PROCESS_MODE_DISABLED
	pass
	
func end_invulnerable() -> void:
	
	process_mode = Node.PROCESS_MODE_INHERIT
	pass
