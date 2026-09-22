@icon("uid://clik7pjgto8k4")
class_name PlayerStateStandUp
extends PlayerState

## Not reachable through any handle_input path — this state only exists to
## be change_state()'d into directly from code reacting to an event (e.g.
## PlayerStateDeath's respawn-at-last-save flow). Plays the stand_up
## animation, blocks input/movement for its duration, and hands off to idle
## once it finishes.
var finished : bool = false


func enter() -> void:
	finished = false
	player.velocity.x = 0.0
	player.animation_player.play( "stand_up" )
	player.animation_player.animation_finished.connect( _on_animation_finished )


func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )


func handle_input( _event : InputEvent ) -> PlayerState:
	# No commands accepted while getting back up.
	return null


func process( _delta: float ) -> PlayerState:
	if finished:
		return idle
	return null


func physics_process( _delta: float ) -> PlayerState:
	# Fully rooted for the duration of the animation.
	player.velocity.x = 0.0
	return next_state


func _on_animation_finished( _anim_name : String ) -> void:
	finished = true
