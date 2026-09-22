@icon("uid://clik7pjgto8k4")
class_name ESOgreJump
extends EnemyState

## The jump arc. Launch velocity is fixed (every jump reaches the same
## apex height, per design), and horizontal speed is solved so the ogre
## lands at the target x by the time it comes back down.

@export var next_state : EnemyState  ## ESOgreJumpEnd
@export var jump_velocity : float = 480.0
## Landing offset past the player's position, along the travel direction,
## so the ogre lands "in front of" the player rather than on top of them.
@export var landing_offset : float = 24.0

const AUDIO_OGRE_CONFUSED = preload("uid://dheaweywsekyf")

var _landing_x : float = 0.0
var _has_launched : bool = false


func enter() -> void:
	enemy.visuals.play_animation( animation_name if animation_name else "jump" )
	Audio.play_spatial_sound( AUDIO_OGRE_CONFUSED, enemy.global_position)
	_has_launched = false

	if blackboard.target:
		_landing_x = blackboard.target.global_position.x + landing_offset * blackboard.dir
	else:
		_landing_x = enemy.global_position.x


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( _delta : float ) -> void:
	if not _has_launched:
		_launch()
		_has_launched = true
		return  # skip the floor check this frame — is_on_floor() still reflects standing here

	if enemy.is_on_floor():
		state_machine.change_state( next_state )


func _launch() -> void:
	var gravity : float = enemy.get_gravity().y
	if gravity <= 0.0:
		gravity = 980.0  # fallback, shouldn't normally be hit

	var time_to_land : float = 2.0 * jump_velocity / gravity
	var horizontal_distance : float = _landing_x - enemy.global_position.x

	enemy.velocity.y = -jump_velocity
	enemy.velocity.x = horizontal_distance / time_to_land
