@icon("uid://clik7pjgto8k4")
class_name ESOgreRecover
extends EnemyState

## The mandatory beat between moves: turn to face the player, hold a short
## idle, then hand control back to OgreDecisionEngine. This is the ONLY
## place blackboard.can_decide flips back to true — every move (and the
## intro) ends by transitioning here rather than being re-picked mid-move.

@export var recover_duration : float = 0.5

var _timer : float = 0.0


func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity.x = 0
	_timer = 0.0
	enemy.visuals.play_animation( animation_name if animation_name else "idle" )


func re_enter() -> void:
	enter()


func exit() -> void:
	pass


func physics_update( delta : float ) -> void:
	enemy.velocity.x = 0

	if blackboard.target:
		var dir : float = sign( blackboard.target.global_position.x - enemy.global_position.x )
		if dir != 0:
			enemy.change_dir( dir )

	_timer += delta
	if _timer >= recover_duration:
		blackboard.can_decide = true
