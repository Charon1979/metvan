@icon("uid://clik7pjgto8k4")
class_name PlayerStateComboAttack
extends PlayerState

## Attack sounds — assign attack_0..attack_5 in the Inspector (replaces the
## old hardcoded AudioStream consts so these can be redone/reassigned freely).
## 0-2 are the moving swings, 3-5 are the standing-still swings — see
## attacking() below.
@export var attack_0_audio : AudioStream
@export var attack_1_audio : AudioStream
@export var attack_2_audio : AudioStream
@export var attack_3_audio : AudioStream
@export var attack_4_audio : AudioStream
@export var attack_5_audio : AudioStream

## How long after a swing's animation ends a late attack-press still chains
## into the next hit before the combo is considered over.
@export var combo_time_window : float = 0.3

## Lockout applied once the combo ends — whether it ran to its last hit,
## its grace window expired with nothing buffered, or it got cut short
## (e.g. the player is hurt). While this is running, idle/run refuse to let
## the player start attacking again.
##
## This runs *in parallel* with the grace window above, not after it — it's
## armed the instant a swing ends with nothing buffered, so if you never
## chain again, total lockout is max(combo_time_window, attack_cooldown_duration),
## not their sum. That also means this can never make you wait less than
## combo_time_window — that's the floor for how long the game waits to see
## whether you're chaining at all.
@export var attack_cooldown_duration : float = 1.0

# Which hit of the 3-hit combo we're on: 0, 1, 2 — and no further. Reaching
# 2 and finishing always ends the combo, so it can't be chained forever.
var combo_step : int = 0

# True from the moment we've proactively armed the cooldown (grace start, or
# the hard cap ending the combo) until either the combo truly ends (in which
# case exit() leaves it alone — it's already running) or a chained hit
# cancels it because the combo wasn't actually over after all.
var cooldown_armed : bool = false

# Movement variant of the swing currently playing. Re-sampled at the start
# of every swing (not continuously) so switching between moving/standing
# mid-combo finishes the current animation and only changes variant on the
# *next* hit, in either direction.
var is_moving : bool = false

# True the moment attack is pressed during the active swing — consumed
# as soon as the current swing's animation finishes.
var buffered_next : bool = false

# True once the swing has finished with nothing buffered — we're now in
# the post-swing grace window, waiting to see if a late press still counts.
var awaiting_buffer : bool = false
var grace_timer : float = 0.0


func enter() -> void:
	combo_step = 0
	cooldown_armed = false
	player.animation_player.animation_finished.connect( _on_animation_finished )
	attacking()


func exit() -> void:
	combo_step = 0
	buffered_next = false
	awaiting_buffer = false
	player.animation_player.animation_finished.disconnect( _on_animation_finished )
	# Safety net — if something (e.g. take_damage) yanked us out mid-swing,
	# don't leave the player stuck facing a locked direction.
	player.direction_locked = false
	next_state = null
	# Every other way of ending the combo already armed the cooldown itself
	# (see _arm_cooldown()) the instant it happened, so it's had a head start
	# running in parallel with whatever came after. This is only the
	# fallback for a forced exit that never went through that path at all
	# (e.g. hurt mid-swing, before the swing even finished) — still apply the
	# full lockout in that case.
	if not cooldown_armed:
		player.start_attack_cooldown( attack_cooldown_duration )
	cooldown_armed = false


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
		# Keep the recovery pose in sync in case the player starts/stops
		# moving while we're waiting to see if they chain into the next hit.
		_play_recovery_pose()
		grace_timer -= delta
		if grace_timer <= 0.0:
			awaiting_buffer = false
			next_state = _recovery_state()
	return next_state


func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * player.move_speed
	return null


func attacking() -> void:
	buffered_next = false
	# Re-sample movement and facing fresh right as a new swing starts, then
	# lock them for the swing's duration — turning around mid-swing must not
	# spin the animation or hitbox, only the *next* swing should pick up a
	# direction change (which is also what lets moving/standing switch).
	player.direction_locked = false
	player.update_direction()
	is_moving = player.direction.x != 0
	player.direction_locked = true
	var anim_index : int = combo_step + ( 0 if is_moving else 3 )
	player.animation_player.play( "attack_" + str( anim_index ) )
	Audio.play_spatial_sound( _audio_for_index( anim_index ), player.global_position, false, true, 0.5 )


func _advance_combo() -> void:
	if cooldown_armed:
		# We'd pre-armed the cooldown in case the combo was over, but a hit
		# actually landed inside the grace window — the combo continues, so
		# that premature cooldown doesn't apply after all.
		player.attack_cooldown_timer = 0.0
		cooldown_armed = false
	combo_step += 1
	attacking()


func _arm_cooldown() -> void:
	player.start_attack_cooldown( attack_cooldown_duration )
	cooldown_armed = true


func _end_attack() -> void:
	# The swing that just finished is unlocking direction — the player can
	# turn around now, before the next swing (if any) starts and re-locks it.
	player.direction_locked = false
	if combo_step >= 2:
		# Last hit of the combo — always ends here. No more chaining, and
		# any late buffered press is discarded rather than looping forever.
		buffered_next = false
		_arm_cooldown()
		next_state = _recovery_state()
		_play_recovery_pose()
		return
	if buffered_next:
		_advance_combo()
	else:
		awaiting_buffer = true
		grace_timer = combo_time_window
		# Arm the cooldown now, in parallel with the grace window, rather
		# than waiting for the grace window to expire first — see the export
		# var's doc comment for why.
		_arm_cooldown()
		_play_recovery_pose()


func _on_animation_finished( _anim_name : String ) -> void:
	_end_attack()


func _recovery_state() -> PlayerState:
	return ( run if player.direction.x != 0 else idle ) as PlayerState


func _play_recovery_pose() -> void:
	# The swing's animation has nothing queued after it, so without this the
	# character just freezes on the last frame of the attack pose until the
	# state machine actually leaves this state.
	if player.direction.x != 0:
		player.animation_player.play( "run" )
	else:
		player.animation_player.play( "idle" )


func _audio_for_index( index : int ) -> AudioStream:
	match index:
		0: return attack_0_audio
		1: return attack_1_audio
		2: return attack_2_audio
		3: return attack_3_audio
		4: return attack_4_audio
		_: return attack_5_audio
