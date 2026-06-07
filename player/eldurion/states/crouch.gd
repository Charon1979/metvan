@icon("uid://bdtuue7gbi0h8")

class_name PlayerStateCrouch extends PlayerState


@export var deceleration_rate : float = 10


func _init() -> void:
	pass

#What happens when we enter this state?
func enter() -> void:
	pass

func exit() -> void:
	
	pass


func handle_input( event : InputEvent ) -> PlayerState:
	if event.is_action_pressed( "jump" ):
		player.one_way_platform_shape_cast.force_shapecast_update()
		if player.one_way_platform_shape_cast.is_colliding():
			player.position.y += 4
			return fall
		else:
			return jump
	return next_state

#What happens each process tick of a state?
func  process( _delta: float ) -> PlayerState:
	return next_state

#What happens each physics_process tick of a state?
func  physics_process( _delta: float ) -> PlayerState:

	return next_state
