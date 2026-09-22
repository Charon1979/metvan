@icon("uid://clik7pjgto8k4")
class_name PlayerStatePogo 
extends PlayerState
#const POGO_AUDIO = preload("uid://REPLACE_ME") # swap for your pogo attack sfx
@onready var attack_area: AttackArea = %AttackArea
@export var pogo_modifier : float = 0.75
## Lockout applied once this state ends, however it ends (bounced or just
## landed). While this is running, jump/fall refuse to let the player pogo
## again even though a fresh jump already reset pogo_count.
@export var pogo_cooldown_duration : float = 1.0
## Only something on this collision layer (enemies) actually bounces the
## player. attack_area still damages anything else it overlaps (grass,
## breakables, ...) same as always — it just won't pogo off of it.
@export_range( 1, 32, 1 ) var pogo_bounce_layer : int = 6
var hit_something : bool = false

const AUDIO_SPEAR_1 = preload("uid://c7pyad7wkrck3")


# What happens when this state is initialized?
func init() -> void:
	pass
# What happens when we enter this state?
func enter() -> void:
	player.animation_player.play( "pogo" ) # swap for your actual animation name
	Audio.play_spatial_sound( AUDIO_SPEAR_1, player.global_position, false, true, 0.5 )
	hit_something = false
	player.pogo_count = 1
	attack_area.set_active( true )
	if not attack_area.hit_target.is_connected( _on_hit_target ):
		attack_area.hit_target.connect( _on_hit_target )
	#Audio.play_spatial_sound( POGO_AUDIO, player.global_position, false, true, 0.5 )
	pass
# What happens when we exit this state?
func exit() -> void:
	attack_area.set_active( false )
	if attack_area.hit_target.is_connected( _on_hit_target ):
		attack_area.hit_target.disconnect( _on_hit_target )
	player.start_pogo_cooldown( pogo_cooldown_duration )
	pass
# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	return null
# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	return null
# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	if hit_something:
		return do_pogo_bounce()
	if player.is_on_floor():
		return idle
	return next_state
func _on_hit_target( damage_area : DamageArea ) -> void:
	if damage_area.get_collision_layer_value( pogo_bounce_layer ):
		hit_something = true
func do_pogo_bounce() -> PlayerState:
	player.jump_count = 0
	player.dash_count = 0
	player.pogo_count = 0
	player.velocity.y = -jump.jump_velocity * pogo_modifier
	return jump
