@icon("uid://clik7pjgto8k4")
class_name PlayerStateRun extends PlayerState
# What happens when this state is initialized?
func init() -> void:
	pass
# What happens when we enter this state?
func enter() -> void:
	player.animation_player.play( "run" )
	pass
# What happens when we exit this state?
func exit() -> void:
	pass
# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "jump" ):
		if Input.is_action_pressed( "down" ):
			player.one_way_platform_shape_cast.force_shapecast_update()
			if player.one_way_platform_shape_cast.is_colliding():
				player.position.y += 4
				return fall
		return jump
	if _event.is_action_pressed( "special" ) and player.can_dash():
		return dash
	if _event.is_action_pressed( "attack" ) and player.can_attack():
		if Input.is_action_pressed( "up" ):
			return attack_up
		return attack
	if _event.is_action_pressed( "action" ) and player.can_cast() and player.equipped_spell:
		return spell
	return next_state
# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	if player.direction.x == 0:
		return idle
	return next_state
# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	if player.is_on_floor() == false:
		return fall
	return next_state
