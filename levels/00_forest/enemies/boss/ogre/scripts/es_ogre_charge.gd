@icon("uid://clik7pjgto8k4")
class_name ESOgreCharge
extends EnemyState

@export var next_state : EnemyState  ## ESOgreChargeEnd
@export var charge_speed : float = 220.0
const AUDIO_OGRE_STEP_1 = preload("uid://bkc0x0xxwtnbj")
const AUDIO_OGRE_STEP_2 = preload("uid://ilr7g7bi31cr")
const AUDIO_OGRE_STEP_3 = preload("uid://joq7k518dx0m")

var _footstep_sounds : Array[AudioStream] = [ AUDIO_OGRE_STEP_1, AUDIO_OGRE_STEP_2, AUDIO_OGRE_STEP_3 ]

func enter() -> void:
	enemy.visuals.play_animation( animation_name if animation_name else "charge" )

	if enemy.visuals is OgreVisuals:
		var ogre_visuals : OgreVisuals = enemy.visuals
		if not ogre_visuals.sprite.frame_changed.is_connected( _play_random_step ):
			ogre_visuals.sprite.frame_changed.connect( _play_random_step )
func re_enter() -> void:
	pass
func exit() -> void:
	if enemy.visuals is OgreVisuals:
		var ogre_visuals : OgreVisuals = enemy.visuals
		if ogre_visuals.sprite.frame_changed.is_connected( _play_random_step ):
			ogre_visuals.sprite.frame_changed.disconnect( _play_random_step )
	pass
func physics_update( _delta : float ) -> void:
	enemy.velocity.x = charge_speed * blackboard.dir
	if _reached_wall():
		state_machine.change_state( next_state )

func _reached_wall() -> bool:
	var wall : Node2D = enemy.right_wall if blackboard.dir > 0 else enemy.left_wall
	if not wall:
		return enemy.is_on_wall()  # no wall marker configured — fall back rather than charging forever
	if blackboard.dir > 0:
		return enemy.global_position.x >= wall.global_position.x
	return enemy.global_position.x <= wall.global_position.x

func _play_random_step() -> void:
	Audio.play_spatial_sound( _footstep_sounds.pick_random(), enemy.global_position )
