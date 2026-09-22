@icon("uid://clik7pjgto8k4")
class_name PlayerStatePowerAttack
extends PlayerState
@onready var camera_2d: PlayerCamera = $"../../Camera2D"
var finished : bool = false


const AUDIO_POWER_IMPACT = preload("uid://diigvgr4uasjy")


func enter() -> void:
	finished = false
	if player.vfx_sprite_2:
		player.vfx_sprite_2.visible = false
	player.animation_player.play("power_attack_2")
	Audio.play_spatial_sound( AUDIO_POWER_IMPACT, player.global_position, false, true, 0.5 )
	player.animation_player.animation_finished.connect( _on_animation_finished )
	camera_2d._apply_shake(10.0)
func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )
func process(_delta: float) -> PlayerState:
	if finished:
		return idle
	return null
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
func _on_animation_finished( _anim_name : String ) -> void:
	finished = true
