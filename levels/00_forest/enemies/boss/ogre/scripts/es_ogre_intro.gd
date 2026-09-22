@icon("uid://clik7pjgto8k4")
class_name ESOgreIntro
extends EnemyState

## Landing impact + roar. Shakes the screen and fires the arena's rockfall
## (entrance-blocking) cue the instant the ogre hits the floor, then plays
## the intro animation before handing off to the normal fight loop.

@export var next_state : EnemyState  ## ESOgreRecover
@export var landing_shake_strength : float = 12.0



func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity.x = 0

	# Impact: screen shake + the entrance-blocking rockfall cue. The arena's
	# "rocks fall" AnimationPlayer listens for this signal itself, so the
	# ogre doesn't need a direct reference to it (see README).
	VisualEffects.camera_shake( landing_shake_strength )
	Messages.lair_action_1.emit()
	Messages.boss_intro_started.emit()

	if enemy is OgreBoss and enemy.roar_audio:
		Audio.play_spatial_sound( enemy.roar_audio, enemy.global_position )

	enemy.visuals.play_animation( animation_name if animation_name else "ogre_intro" )
	await enemy.visuals.animation_player.animation_finished

	# Battle officially starts once BossBattleOrchestrator hears this.
	Messages.boss_intro_ended.emit()

	state_machine.change_state( next_state )


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( _delta : float ) -> void:
	enemy.velocity.x = 0
