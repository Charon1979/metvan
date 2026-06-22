@icon("uid://bdtuue7gbi0h8")

class_name PlayerStateTakeDamage extends PlayerState

const HURT_AUDIO = preload("uid://b01mccy06o2bi")


@export var move_speed : float = 100
@export var move_height : float = 16
@export var invulnerable_duration : float = 1.0
var time : float = 0.0
var dir : float = 1.0
var force : float = 1


@onready var damage_area: DamageArea = %DamageArea





# What happens when this state is initialized?
func init() -> void:
	damage_area.damage_taken.connect( _on_damage_taken )
	pass


# What happens when we enter this state?
func enter() -> void:
	
	if player.is_on_floor():
		player.animation_player.play( "hurt" )
		time = player.animation_player.current_animation_length
	else:
		player.animation_player.play( "hurt_air" )
		
		time = player.animation_player.current_animation_length
	damage_area.make_invulnerable( invulnerable_duration )
	Audio.play_spatial_sound( HURT_AUDIO, player.global_position, false, true, 0.5 )
	VisualEffects.camera_shake( force * 2.0 )
	pass


# What happens when we exit this state?
func exit() -> void:
	
	pass


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	return null


# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	time -= _delta
	
		
	if time <= 0:
		if player.hp <= 0:
			return death
		return idle
	return null


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:

	player.velocity.x = move_speed * force * dir
	player.velocity.y = move_height * force * dir

	return next_state

func _on_damage_taken( attack_area : AttackArea ) -> void:
	if player.current_state == death:
		return
	player.change_state( self )
	if player.is_on_floor(): 
		force = attack_area.force
	else:
		player.velocity.y = player.max_fall_velocity
		force = 0.1

	if attack_area.global_position.x < player.global_position.x:
		dir = 1.0
	else:
		dir = -1.0
	pass
