@icon("uid://clik7pjgto8k4")
class_name PlayerStateAttackAir
extends PlayerState

## Horizontal attack while airborne — attack pressed alone (no "up" held),
## from either jump or fall. See PlayerStateAttackUp for the up-attack
## counterpart triggered the same way but with "up" also held; down+attack
## is still pogo, unaffected by this.
##
## Same cooldown mechanic as the other single-hit attacks (see
## PlayerStateComboAttack's attack_cooldown_duration doc comment) — shares
## the same player.attack_cooldown_timer as every other melee attack.
@export var attack_cooldown_duration : float = 1.0

var finished : bool = false

const AUDIO_SPEAR_6 = preload("uid://c7o7uqsacbfvy")


func enter() -> void:
	finished = false
	# Facing locked for the swing's duration and resumes normally the moment
	# it's done — but the jump/fall arc itself (both horizontal drift and
	# vertical motion) keeps playing out underneath it, so this reads as a
	# swing thrown mid-arc rather than a full stop in midair.
	player.direction_locked = true
	player.animation_player.play( "jump_attack" )
	Audio.play_spatial_sound( AUDIO_SPEAR_6, player.global_position, false, true, 0.5 )
	player.animation_player.animation_finished.connect( _on_animation_finished )


func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )
	player.direction_locked = false
	player.start_attack_cooldown( attack_cooldown_duration )


func process( _delta: float ) -> PlayerState:
	if finished:
		if not player.is_on_floor():
			return fall
		return ( run if player.direction.x != 0 else idle ) as PlayerState
	return null


func physics_process( _delta: float ) -> PlayerState:
	# This state is only ever entered airborne, so keep riding the jump/fall
	# arc instead of halting it — facing is what's locked (direction_locked),
	# not motion. Vertical motion is untouched here; gravity is applied
	# elsewhere every physics frame regardless of state.
	player.velocity.x = player.direction.x * player.move_speed
	return next_state


func _on_animation_finished( _anim_name : String ) -> void:
	finished = true
