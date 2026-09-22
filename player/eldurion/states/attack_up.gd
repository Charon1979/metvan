@icon("uid://clik7pjgto8k4")
class_name PlayerStateAttackUp
extends PlayerState

## Triggered from idle/run/jump/fall alike (attack + "up" held). See
## PlayerStateAttackAir for the horizontal counterpart used from jump/fall
## when "up" isn't held.
##
## Same cooldown mechanic as the combo attacks (see PlayerStateComboAttack's
## attack_cooldown_duration doc comment) — this is a single hit with no
## combo/grace window to run it alongside, so it simply arms the moment the
## swing's animation finishes.
@export var attack_cooldown_duration : float = 1.0

var finished : bool = false

const AUDIO_SPEAR_6 = preload("uid://c7o7uqsacbfvy")


func enter() -> void:
	finished = false
	# No movement and no turning around while this swing plays out — both
	# resume normally the moment it's done.
	player.direction_locked = true
	if player.is_on_floor():
		player.animation_player.play( "attack_up" )
	else:
		player.animation_player.play( "jump_attack_up" )
	Audio.play_spatial_sound( AUDIO_SPEAR_6, player.global_position, false, true, 0.5 )
	player.animation_player.animation_finished.connect( _on_animation_finished )


func exit() -> void:
	if player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )
	player.direction_locked = false
	player.start_attack_cooldown( attack_cooldown_duration )


func process( _delta: float ) -> PlayerState:
	if finished:
		# Triggerable mid-air now too — land on whichever ground state
		# actually applies instead of assuming we're grounded.
		if not player.is_on_floor():
			return fall
		return ( run if player.direction.x != 0 else idle ) as PlayerState
	return null


func physics_process( _delta: float ) -> PlayerState:
	if player.is_on_floor():
		# Grounded up-attack: no movement allowed for the duration of the swing.
		player.velocity.x = 0.0
	else:
		# Airborne (jump_attack_up): facing is locked via direction_locked, but
		# the jump/fall arc keeps playing out — just keep riding it instead of
		# freezing in place. Gravity is applied elsewhere every physics frame
		# regardless of state, so vertical motion was never affected by this.
		player.velocity.x = player.direction.x * player.move_speed
	return next_state


func _on_animation_finished( _anim_name : String ) -> void:
	finished = true
