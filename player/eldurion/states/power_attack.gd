@icon("uid://bdtuue7gbi0h8")

class_name PlayerStatePowerAttack
extends PlayerState

@onready var camera_2d: PlayerCamera = $"../../Camera2D"






func enter() -> void:
	player.animation_player.play("power_attack_2")
	camera_2d._apply_shake(10.0)

	
func process(_delta: float) -> PlayerState:
	if player.animation_player.current_animation == "power_attack_2":
		return
	else:
		return idle
	
