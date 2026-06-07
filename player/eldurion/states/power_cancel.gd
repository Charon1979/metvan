@icon("uid://bdtuue7gbi0h8")

class_name PlayerStatePowerCancel extends PlayerState


func enter() -> void:
	player.animation_player.play( "power_attack_0" )
	
	pass

func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "special" ) and player.can_dash():
		return dash
	return null

func process(_delta: float) -> PlayerState:
	if player.animation_player.current_animation == "power_attack_0":
		
		return
	else:
		
		return idle
