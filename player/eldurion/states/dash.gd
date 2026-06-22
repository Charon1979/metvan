@icon("uid://bdtuue7gbi0h8")

class_name PlayerStateDash extends PlayerState

const DASH_AUDIO = preload("uid://d4k4f4ysr10fc")

@export var duration : float = 0.25
@export var speed: float = 350.0
@export var effect_delay : float = 0.05
@export var cost : int = 15

var dir : float = 1.0
var time : float = 0.0
var effect_time : float = 0.0

@onready var damage_area: DamageArea = %DamageArea
@onready var dash_part: GPUParticles2D = $"../../ParticleSystems/Dash_part"



# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:
	player.animation_player.play( "dash" )
	dash_part.restart()
	Messages.player_casting.emit( -15 )
	time = duration
	effect_time = 0.0
	get_dash_direction()
	damage_area.make_invulnerable( duration )
	Audio.play_spatial_sound( DASH_AUDIO, player.global_position, false, true, 0.5 )
	
	player.gravity_mulitplier = 0.0
	player.velocity.y = 0.0
	
	player.dash_count += 1
	
	player.sprite_2d.tween_color()
	pass


# What happens when we exit this state?
func exit() -> void:
	player.gravity_mulitplier = 1.0
	dash_part.emitting = false
	pass


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:

	return null


# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	time -= _delta
	if time <= 0.0:
		if player.is_on_floor():
			return idle
		else:
			return fall
			
	effect_time -= -_delta
	if effect_time > 0:
		effect_time = effect_delay
		player.sprite_2d.ghost()
	return null


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = ( speed * (time / duration ) + speed ) * dir
	return null

func get_dash_direction() -> void:
	dir = 1.0
	if player.sprite_2d.flip_h == true:
		dir = -1.0
	pass
