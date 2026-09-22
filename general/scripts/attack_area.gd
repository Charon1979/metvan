@icon("uid://dp7or28cg82jx")

class_name AttackArea
extends Area2D

signal hit_target( damage_area : DamageArea )

@export var damage : int = 1
@export var dmg_element: DamageType.DamageElement = DamageType.DamageElement.PHYSICAL
@export var dmg_type: DamageType.DamageType = DamageType.DamageType.LIGHT
@export var force : float = 1.0
@export var duration : float = 0.1




func _ready() -> void:
	body_entered.connect( _on_body_entered )
	area_entered.connect( _on_body_entered )
	visible = false
	monitorable = false
	monitoring = false
	pass


func _on_body_entered( body : Node2D ) -> void:
	
	if body is DamageArea:
		body.take_damage( self )
		hit_target.emit( body )
		
		
		#var pos: Vector2 = global_position
		#
		#pos.x = body.global_position.x
		#VisualEffects.hit_dust( pos )
		pass
	pass

func activate( duration : float ) -> void:
	
	set_active( true )
	await get_tree().create_timer( duration ).timeout
	set_active( false )
	pass

func set_active ( value : bool = true ) -> void:
	monitoring = value
	visible = value
	pass



func flip( direction_x : float ) -> void:
	if direction_x > 0:
		scale.x = 1
		position.x = abs(position.x)
	elif direction_x < 0:
		scale.x = -1
		position.x = -abs(position.x)
	pass
	
