@icon("uid://clik7pjgto8k4")
class_name PlayerStateAttack
extends PlayerState
@export var hold_threshold : float = 0.3
var hold_time := 0.0
var attack_released := false
func enter() -> void:
	hold_time = 0.0
	attack_released = false
func exit() -> void:
	pass
func handle_input(event: InputEvent) -> PlayerState:
	if event.is_action_released("attack"):
		attack_released = true
	return null
func process(delta: float) -> PlayerState:
	# Covers "up" being pressed a beat *after* "attack" — idle/run only catch
	# "up" already held at the moment "attack" is pressed, so without this,
	# up-attack would only ever fire if both were pressed on the exact same
	# frame in the exact right order. Checked every tick for as long as we're
	# still deciding what this attack is, so holding up any time before that
	# decision resolves (tap vs hold vs up) is enough.
	if Input.is_action_pressed( "up" ):
		return attack_up
	hold_time += delta
	if attack_released and hold_time < hold_threshold:
		return combo_attack
	if hold_time >= hold_threshold:
		return power_charge

	return null
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
