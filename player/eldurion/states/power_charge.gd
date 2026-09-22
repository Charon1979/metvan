@icon("uid://clik7pjgto8k4")
class_name PlayerStatePowerCharge
extends PlayerState
@onready var camera_2d: PlayerCamera = $"../../Camera2D"
@export var charge_duration : float = 2.0
var charge_time : float = 0.0
var already_played : bool = false
var power_active : bool = false
var windup_finished : bool = false
const AUDIO_POWER_RDY = preload("uid://dj5lml65fk77m")
const AUDIO_WEAPON_CHARGE = preload("uid://cdcocmta0g1ap")

# Handle to the sustained charge-up sound so it can be cut short on exit()
# instead of playing out to the end regardless of what the player does.
# Only reliable because it's started with ignore_pool = true (see
# Audio.play_spatial_sound's doc comment) — a pooled instance can get
# reassigned to a totally different sound before we get a chance to stop it.
var charge_audio_player : AudioStreamPlayer2D

# True for exactly as long as this state instance is the one actually
# active. Guards the awaited windup below: if the state gets exited while
# still waiting on the windup animation (e.g. the player is hurt mid-charge),
# exit() has already run by the time that await resumes, so this stops the
# charge sound from starting at all rather than starting one nothing will
# ever stop.
var _active : bool = false


func enter() -> void:
	_active = true
	player.direction_locked = true
	charge_time = 0.0
	windup_finished = false
	already_played = false
	power_active = false
	player.animation_player.animation_finished.connect( _on_windup_finished )
	player.animation_player.play( "power_attack_0" )
	# Starts the instant the player commits to charging (holding past
	# attack.gd's hold_threshold long enough to land here) — not gated
	# behind the windup animation finishing, so the buildup is visible from
	# frame one of the hold, not just once the windup pose settles.
	# Not every character has this vfx set up (Eldurion doesn't) — see
	# Player.vfxp_art's own comment — so this (and every other vfx_*/vfxp_art
	# reference below) is skipped entirely when null instead of crashing.
	if player.vfxp_art:
		player.vfxp_art.emitting = true
	await player.animation_player.animation_finished
	if not _active:
		return
	charge_audio_player = Audio.play_spatial_sound( AUDIO_WEAPON_CHARGE, player.global_position, true, true, 0.5 )


func exit() -> void:
	_active = false
	if player.animation_player.animation_finished.is_connected( _on_windup_finished ):
		player.animation_player.animation_finished.disconnect( _on_windup_finished )
	if player.vfx_player and player.vfx_player.animation_finished.is_connected( _on_power_ready_finished ):
		player.vfx_player.animation_finished.disconnect( _on_power_ready_finished )
	if is_instance_valid( charge_audio_player ):
		charge_audio_player.stop()
		charge_audio_player.queue_free()
	charge_audio_player = null
	already_played = false
	player.direction_locked = false
	power_active = false
	# Cleanup for a charge cut short before it ever reached full (e.g. the
	# player got hurt mid-charge) — without this the particles/weapon glow
	# would keep running into whatever state comes next.
	if player.vfxp_art:
		player.vfxp_art.emitting = false
	if player.vfx_sprite_2:
		player.vfx_sprite_2.visible = false


func process(delta: float) -> PlayerState:
	charge_time += delta
	var fully_charged := charge_time >= charge_duration
	if not windup_finished:
		return null
	if player.attack_held:
		if player.animation_player.current_animation != "power_attack_1":
			player.animation_player.play("power_attack_1")
		if fully_charged and not already_played:
			# Threshold just crossed — swap the charging particles for the
			# weapon's own "power_ready" flash, timed to the same sound.
			# power_active (the held-and-ready loop) takes over once that
			# flash finishes playing — see _on_power_ready_finished().
			Audio.play_spatial_sound( AUDIO_POWER_RDY, player.global_position, false, true, 0.5 )
			already_played = true
			power_active = true
			if player.vfxp_art:
				player.vfxp_art.emitting = false
			if player.vfx_sprite_2:
				player.vfx_sprite_2.visible = true
			if player.vfx_player:
				player.vfx_player.animation_finished.connect( _on_power_ready_finished, CONNECT_ONE_SHOT )
				player.vfx_player.play( "power_ready" )
		_update_fx(clamp(charge_time / charge_duration, 0.0, 1.0))
		return null
	if fully_charged:

		return power_attack
	return power_cancel


func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = 0.0
	return next_state


func _on_windup_finished( _anim_name : String ) -> void:
	windup_finished = true


## power_ready is a one-shot "just crossed the threshold" flash — once it's
## done playing, hand off to power_active, which loops for as long as the
## player keeps holding attack (release/timeout is handled in process()
## above, not by this animation ending).
func _on_power_ready_finished( _anim_name : String ) -> void:
	if not _active or not power_active or not player.vfx_player:
		return
	player.vfx_player.play( "power_active" )


func _update_fx(_t: float) -> void:
	pass
