@icon("uid://bdtuue7gbi0h8")

class_name PlayerStatePowerAttack
extends PlayerState

@onready var camera_2d: PlayerCamera = $"../../Camera2D"

var finished : bool = false


func enter() -> void:
	finished = false
	player.animation_player.play("power_attack_2")
	player.animation_player.animation_finished.connect( _on_animation_finished )
	camera_2d._apply_shake(10.0)


func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )


func process(_delta: float) -> PlayerState:
	if finished:
		return idle
	return null


func _on_animation_finished( _anim_name : String ) -> void:
	finished = true
