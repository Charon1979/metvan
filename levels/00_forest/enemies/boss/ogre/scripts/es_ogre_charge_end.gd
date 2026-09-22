@icon("uid://clik7pjgto8k4")
class_name ESOgreChargeEnd
extends EnemyState

## The wall impact: attack animation + hitbox, screen shake, and a ceiling
## dust warning + falling rock at the player's CURRENT position (captured
## here, not back at ChargeStart, since the player has had time to move).

@export var next_state : EnemyState  ## ESOgreRecover
@export var shake_strength : float = 10.0
@export var attack_area : AttackArea

const AUDIO_OGRE_ROCK_PUNCH = preload("uid://b5pnuls7t3eu")

func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity.x = 0

	if attack_area:
		attack_area.flip( blackboard.dir )
		attack_area.activate( attack_area.duration )

	VisualEffects.camera_shake( shake_strength )
	Audio.play_spatial_sound( AUDIO_OGRE_ROCK_PUNCH, enemy.global_position)
	if blackboard.target and enemy is OgreBoss:
		enemy.spawn_ceiling_rock( blackboard.target.global_position.x )

	enemy.visuals.play_animation( animation_name if animation_name else "attack" )
	await enemy.visuals.animation_player.animation_finished

	state_machine.change_state( next_state )


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( _delta : float ) -> void:
	enemy.velocity.x = 0
