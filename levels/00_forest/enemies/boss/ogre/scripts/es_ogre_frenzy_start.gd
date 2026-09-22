@icon("uid://clik7pjgto8k4")
class_name ESOgreFrenzyStart
extends EnemyState

## Windup before the ground-pound barrage: faces the player (direction is
## fixed for the whole move from here on, same as Charge/Jump), holds
## briefly, then commits. Always a valid move — the guaranteed fallback
## when Charge/Jump can't fire.

@export var next_state : EnemyState  ## ESOgreFrenzy
@export var windup_duration : float = 0.4

const AUDIO_OGRE_ANGRY_GROWL = preload("uid://37fythn1spku")

var _timer : float = 0.0


func enter() -> void:
	blackboard.can_decide = false
	enemy.velocity.x = 0
	_timer = 0.0

	if blackboard.target:
		var dir : float = sign( blackboard.target.global_position.x - enemy.global_position.x )
		if dir != 0:
			enemy.change_dir( dir )

	enemy.visuals.play_animation( animation_name if animation_name else "frenzy_start" )
	Audio.play_spatial_sound( AUDIO_OGRE_ANGRY_GROWL, enemy.global_position)

func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( delta : float ) -> void:
	enemy.velocity.x = 0
	_timer += delta
	if _timer >= windup_duration:
		state_machine.change_state( next_state )


## Queried by OgreDecisionEngine before offering Frenzy as a candidate move.
func can_perform() -> bool:
	return true  # always a valid fallback, per design
