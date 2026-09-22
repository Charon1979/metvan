@icon( "uid://clik7pjgto8k4" )
class_name ESOgreChargeStart
extends EnemyState

## Windup: locks facing toward the player (direction is fixed for the whole
## move from here on), holds briefly, then commits to the dash.

@export var next_state : EnemyState  ## ESOgreCharge
@export var windup_duration : float = 0.4
## How far from the wall on the player's side the ogre must be to commit to
## a charge — not enough room means charge isn't offered as a move.
@export var min_run_distance : float = 64.0

const AUDIO_OGRE_LONG_GROWL = preload("uid://c6v8m2h8uuqif")

var _timer : float = 0.0


func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity.x = 0
	_timer = 0.0

	if blackboard.target:
		var dir : float = sign( blackboard.target.global_position.x - enemy.global_position.x )
		if dir != 0:
			enemy.change_dir( dir )

	enemy.visuals.play_animation( animation_name if animation_name else "charge_start" )
	Audio.play_spatial_sound( AUDIO_OGRE_LONG_GROWL, enemy.global_position)

func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( delta : float ) -> void:
	enemy.velocity.x = 0
	_timer += delta
	if _timer >= windup_duration:
		state_machine.change_state( next_state )


## Queried by OgreDecisionEngine before offering Charge as a candidate move.
func can_perform() -> bool:
	if not blackboard.target or not ( enemy is OgreBoss ):
		return false

	var dir : float = sign( blackboard.target.global_position.x - enemy.global_position.x )
	var wall : Node2D = enemy.right_wall if dir > 0 else enemy.left_wall
	if not wall:
		return true  # no wall marker configured — don't block the move over missing setup

	var distance_to_wall : float = abs( wall.global_position.x - enemy.global_position.x )
	return distance_to_wall >= min_run_distance
