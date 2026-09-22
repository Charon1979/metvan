@icon("uid://clik7pjgto8k4")
class_name ESOgreFrenzy
extends EnemyState

## The ground-pound barrage itself. At entry, picks 3 non-overlapping
## ceiling x-positions (at least min_rock_spacing apart) and kicks off a
## dust-warning-then-rock sequence at each, concurrently with the pounding.
## Entered only from ESOgreFrenzyStart, never picked by decide() directly.

@export var next_state : EnemyState  ## ESOgreFrenzyEnd
@export var repeat_count : int = 3
@export var min_rock_spacing : float = 48.0
@export var shake_strength : float = 10.0

var _reps_done : int = 0
var _timer : float = 0.0
var _rep_duration : float = 0.0

const AUDIO_OGRE_ROCK_PUNCH = preload("uid://b5pnuls7t3eu")

func enter() -> void:
	VisualEffects.camera_shake( shake_strength )
	enemy.velocity.x = 0
	_reps_done = 0

	_spawn_rock_barrage()
	_start_rep()


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( delta : float ) -> void:
	enemy.velocity.x = 0
	_timer += delta
	if _timer >= _rep_duration:
		_reps_done += 1
		if _reps_done >= repeat_count:
			state_machine.change_state( next_state )
		else:
			_start_rep()


func _start_rep() -> void:
	_timer = 0.0
	VisualEffects.camera_shake( shake_strength )
	enemy.visuals.play_animation( animation_name if animation_name else "frenzy" )
	_rep_duration = enemy.visuals.get_animation_length( animation_name if animation_name else "frenzy" )
	if _rep_duration <= 0.0:
		_rep_duration = 0.4  # fallback so a missing/zero-length animation can't stall the loop


func _spawn_rock_barrage() -> void:
	if not ( enemy is OgreBoss ) or not enemy.left_wall or not enemy.right_wall:
		return

	var min_x : float = min( enemy.left_wall.global_position.x, enemy.right_wall.global_position.x )
	var max_x : float = max( enemy.left_wall.global_position.x, enemy.right_wall.global_position.x )

	var chosen_x : Array[ float ] = []
	var attempts : int = 0
	while chosen_x.size() < 3 and attempts < 64:
		attempts += 1
		var candidate : float = randf_range( min_x, max_x )
		var far_enough : bool = true
		for x in chosen_x:
			if abs( x - candidate ) < min_rock_spacing:
				far_enough = false
				break
		if far_enough:
			chosen_x.append( candidate )

	for x in chosen_x:
		enemy.spawn_ceiling_rock( x )

func play_hit_sound() -> void:
	Audio.play_spatial_sound( AUDIO_OGRE_ROCK_PUNCH, enemy.global_position)
	pass
