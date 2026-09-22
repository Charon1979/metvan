@icon("uid://clik7pjgto8k4")
class_name ESOgreFrenzyEnd
extends EnemyState

## Wind-down after the ground-pound barrage finishes, before handing off
## to Recover — a beat for the ogre to settle rather than snapping
## straight from the last pound into idle.

@export var next_state : EnemyState  ## ESOgreRecover


func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity.x = 0

	# play_and_wait(), not a raw await on animation_finished — see
	# ESOgreIntro for why (hangs forever on a missing/zero-length animation).
	await enemy.visuals.play_and_wait( animation_name if animation_name else "frenzy_end" )

	state_machine.change_state( next_state )


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( _delta : float ) -> void:
	enemy.velocity.x = 0
