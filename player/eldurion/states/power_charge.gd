@icon("uid://bdtuue7gbi0h8")
class_name PlayerStatePowerCharge
extends PlayerState

@onready var camera_2d: PlayerCamera = $"../../Camera2D"

@export var charge_duration : float = 2.0

var charge_time : float = 0.0
var already_played : bool = false
var power_active : bool = false
var windup_finished : bool = false


func enter() -> void:
	player.direction_locked = true
	charge_time = 0.0
	windup_finished = false
	player.animation_player.play("power_attack_0")
	player.animation_player.animation_finished.connect( _on_windup_finished )


func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_windup_finished ):
		player.animation_player.animation_finished.disconnect( _on_windup_finished )
	already_played = false
	player.direction_locked = false


func process(delta: float) -> PlayerState:
	charge_time += delta
	var fully_charged := charge_time >= charge_duration

	if not windup_finished:
		return null

	if player.attack_held:
		if player.animation_player.current_animation != "power_attack_1":
			player.animation_player.play("power_attack_1")

		if fully_charged and not already_played:
			already_played = true
			power_active = true

		_update_fx(clamp(charge_time / charge_duration, 0.0, 1.0))
		return null

	if fully_charged:
		return power_attack
	return power_cancel


func _on_windup_finished( _anim_name : String ) -> void:
	windup_finished = true


func _update_fx(_t: float) -> void:
	# particles / shake ramp — power_rdy sound + vfx cues go here once implemented
	pass
