@icon("uid://bdtuue7gbi0h8")

class_name PlayerStatePowerCancel extends PlayerState

var finished : bool = false


func enter() -> void:
	finished = false
	player.animation_player.play( "power_attack_0" )
	player.animation_player.animation_finished.connect( _on_animation_finished )


func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )


func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "special" ) and player.can_dash():
		return dash
	return null


func process(_delta: float) -> PlayerState:
	if finished:
		return idle
	return null


func _on_animation_finished( _anim_name : String ) -> void:
	finished = true
