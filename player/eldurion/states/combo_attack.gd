@icon("uid://bdtuue7gbi0h8")
class_name PlayerStateComboAttack
extends PlayerState

const AUDIO_ATTACK_1 = preload( "uid://c0h35s8l6r224" )
const AUDIO_ATTACK_2 = preload( "uid://va2ksh81j1jg" )
const AUDIO_ATTACK_3 = preload( "uid://va2ksh81j1jg" )  # TODO: same file as AUDIO_ATTACK_2 right now — swap in a distinct 3rd-hit sound


@export var combo_time_window : float = 0.3
@export var speed : float = 0

var combo : int = 0

# True the moment attack is pressed during the active swing — consumed
# as soon as the current swing's animation finishes.
var buffered_next : bool = false

# True once the swing has finished with nothing buffered — we're now in
# the post-swing grace window, waiting to see if a late press still counts.
var awaiting_buffer : bool = false
var grace_timer : float = 0.0


func enter() -> void:
	player.animation_player.animation_finished.connect( _on_animation_finished )
	attacking()


func exit() -> void:
	combo = 0
	buffered_next = false
	awaiting_buffer = false
	player.animation_player.animation_finished.disconnect( _on_animation_finished )
	next_state = null


func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "attack" ):
		if awaiting_buffer:
			# Late press landed inside the post-swing grace window — chain right now,
			# no need to wait for the next process() tick.
			awaiting_buffer = false
			_advance_combo()
		else:
			buffered_next = true
	return null


func process( delta: float ) -> PlayerState:
	if awaiting_buffer:
		grace_timer -= delta
		if grace_timer <= 0.0:
			awaiting_buffer = false
			next_state = idle
	return next_state


func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * speed
	return null


func attacking() -> void:
	buffered_next = false
	var anim_name : String = "attack_" + str(combo)
	player.animation_player.play( anim_name )
	Audio.play_spatial_sound( attack_sound(), player.global_position, false, true, 0.5 )


func _advance_combo() -> void:
	combo = wrapi( combo + 1, 0, 3 )
	attacking()


func _end_attack() -> void:
	if buffered_next:
		_advance_combo()
	else:
		awaiting_buffer = true
		grace_timer = combo_time_window


func _on_animation_finished( _anim_name : String ) -> void:
	_end_attack()


func attack_sound() -> AudioStream:
	match combo:
		1:
			return AUDIO_ATTACK_2
		2:
			return AUDIO_ATTACK_3
		_:
			return AUDIO_ATTACK_1
