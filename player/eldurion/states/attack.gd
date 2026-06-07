@icon("uid://bdtuue7gbi0h8")
class_name PlayerStateAttack
extends PlayerState

@export var hold_threshold : float = 0.3

var hold_time := 0.0
var attack_released := false


func enter() -> void:
	player.velocity.x = 0.0
	hold_time = 0.0
	attack_released = false

func exit() -> void:
	pass


func handle_input(event: InputEvent) -> PlayerState:

	if event.is_action_released("attack"):
		attack_released = true

	return null

func process(delta: float) -> PlayerState:

	hold_time += delta

	if attack_released and hold_time < hold_threshold:
		return combo_attack
	if hold_time >= hold_threshold:
		return power_charge
	

	return null
