@icon("uid://clik7pjgto8k4")
class_name ESOgreJumpEnd
extends EnemyState

## Landing impact: attack animation + hitbox, screen shake. No ceiling
## rock here — per design, rocks only accompany Charge and Frenzy.

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
	Audio.play_spatial_sound( AUDIO_OGRE_ROCK_PUNCH, enemy.global_position)
	VisualEffects.camera_shake( shake_strength )

	enemy.visuals.play_animation( animation_name if animation_name else "attack" )
	await enemy.visuals.animation_player.animation_finished

	state_machine.change_state( next_state )


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( _delta : float ) -> void:
	enemy.velocity.x = 0
