@icon("uid://bdtuue7gbi0h8")

class_name PlayerStateIdle extends PlayerState


# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:
	player.sprite_2d.z_index = 1
	player.animation_player.play( "idle" )
	player.jump_count = 0
	player.dash_count = 0
	pass


# What happens when we exit this state?
func exit() -> void:

	pass


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	# Handle input
	if _event.is_action_pressed( "special" ) and player.can_dash():
		return dash
	if _event.is_action_pressed( "attack" ):
		return attack
	if _event.is_action_pressed( "jump" ):
		return jump

	return null


# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	if player.direction.x != 0:
		return run
	#elif player.direction.y > 0.5:
		#return crouch
	return null


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = 0
	if player.is_on_floor() == false:
		return fall
	return next_state
	
