@icon("uid://bdtuue7gbi0h8")

class_name PlayerStateDeath extends PlayerState

const DEATH_AUDIO = preload("uid://b8vlx271tc7ip")
@onready var death_rec: ColorRect = $Death_rec



# What happens when we enter this state?
func enter() -> void:
	death_rec.visible = true
	player.animation_player.play( "death" )
	Audio.play_spatial_sound( DEATH_AUDIO, player.global_position )
	Audio.play_music( null )
	PlayerHud.hide_hud()
	await player.animation_player.animation_finished
	SaveManager.game_over()
	
	
	
	pass


# What happens when we exit this state?


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	return null


# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	return null


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = 0
	if player.hp >= 1:
		return idle
	return null
