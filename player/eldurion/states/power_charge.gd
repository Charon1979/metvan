@icon("uid://bdtuue7gbi0h8")
class_name PlayerStatePowerCharge
extends PlayerState

@onready var camera_2d: PlayerCamera = $"../../Camera2D"



@export var charge_duration : float = 2.0

var charge_time : float = 0.0
var already_played : bool = false
var power_active : bool = false

func enter() -> void:
	player.direction_locked = true
	player.animation_player.play("power_attack_0")
	charge_time = 0.0

	

func process(delta: float) -> PlayerState:

	charge_time += delta

	var fully_charged := charge_time >= charge_duration
	
	if player.animation_player.current_animation == "power_attack_0":
		
		return
	else:
		if player.attack_held:
			player.animation_player.play("power_attack_1")
			
			#if !charge_audio.playing:
			#	charge_audio.play()
				
			if charge_time > charge_duration and already_played == false:
				already_played = true
			#	power_rdy.play()
			#	vfx_player_02.play( "power_rdy" )
				power_active = true
				
			#if charge_time > charge_duration and already_played == true and power_active == true:
			#	vfx_player_01.play( "power_active" )
			#	power_part.emitting = false
			
			
			
			_update_fx(clamp(charge_time / charge_duration, 0.0, 1.0))
			return null

	if player.animation_player.current_animation != "power_attack_0":
		
		if !player.attack_held:
			if fully_charged:
				return power_attack
				
			else:
			#	power_part.emitting = false
				return power_cancel
				
	return null

func exit() -> void:
	#charge_audio.stop()
	#vfx_player_01.stop()
	#vfx_sprite.visible = false
	already_played = false
	player.direction_locked = false
	pass

func _update_fx(_t: float) -> void:
	#particles / shake ramp
	pass
