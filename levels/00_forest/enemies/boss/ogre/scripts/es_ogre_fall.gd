@icon("uid://clik7pjgto8k4")
class_name ESOgreFall
extends EnemyState

## Looping fall animation while the ogre drops from the ceiling. Entered
## directly by OgreBoss.begin_intro() — never picked by decide().

@export var next_state : EnemyState  ## ESOgreIntro
@export var fall_speed : float = 260.0  ## capped fall speed, for a controlled/cinematic drop rather than full accelerating gravity

const AUDIO_OGRE_HIT_ROCK = preload("uid://tbq6wwlime6y")

func enter() -> void:
	blackboard.can_decide = false
	enemy.visuals.play_animation( animation_name if animation_name else "ogre_fall" )


func re_enter() -> void:
	pass


func exit() -> void:
	Audio.play_spatial_sound( AUDIO_OGRE_HIT_ROCK, enemy.global_position)
	Messages.boss_intro_started.emit()
	
	pass


func physics_update( _delta : float ) -> void:
	enemy.velocity.x = 0
	enemy.velocity.y = min( enemy.velocity.y, fall_speed )

	if enemy.is_on_floor():
		state_machine.change_state( next_state )
