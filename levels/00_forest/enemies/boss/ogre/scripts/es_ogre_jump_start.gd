@icon( "uid://clik7pjgto8k4" )
class_name ESOgreJumpStart
extends EnemyState

## Windup: locks facing toward the player, holds briefly, then commits to
## the jump.

@export var next_state : EnemyState  ## ESOgreJump
@export var windup_duration : float = 0.4
## Jump is only offered as a move when the player is at least this far away.
@export var min_jump_distance : float = 96.0

const AUDIO_OGRE_GRUNT_1 = preload("uid://cbov02s28sofw")

var _timer : float = 0.0


func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity.x = 0
	_timer = 0.0

	if blackboard.target:
		var dir : float = sign( blackboard.target.global_position.x - enemy.global_position.x )
		if dir != 0:
			enemy.change_dir( dir )

	enemy.visuals.play_animation( animation_name if animation_name else "jump_start" )
	Audio.play_spatial_sound( AUDIO_OGRE_GRUNT_1, enemy.global_position)


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( delta : float ) -> void:
	enemy.velocity.x = 0
	_timer += delta
	if _timer >= windup_duration:
		state_machine.change_state( next_state )


## Queried by OgreDecisionEngine before offering Jump as a candidate move.
func can_perform() -> bool:
	if not blackboard.target:
		return false
	var distance : float = abs( blackboard.target.global_position.x - enemy.global_position.x )
	return distance >= min_jump_distance
