@icon("uid://clik7pjgto8k4")
class_name PlayerStateJump extends PlayerState
const JUMP_AUDIO = preload("uid://k14rde8r1sc0")
@export var jump_velocity : float = 450.0
@export var camera_pan_offset : float = 64.0
@onready var jump_particles: GPUParticles2D = $"../../ParticleSystems/Jump_Particles"
@onready var camera_2d: PlayerCamera = $"../../Camera2D"
# What happens when this state is initialized?
func init() -> void:
	pass
# What happens when we enter this state?
func enter() -> void:
	if player.previous_state == pogo:
		player.animation_player.play( "jump" )
		player.animation_player.pause()
		# velocity already set by the pogo bounce — don't call do_jump() here,
		# just treat this as jump_count's "first jump" so double jump still works.
		player.jump_count = 1
		return
	
	if player.is_on_floor():
		VisualEffects.jump_dust( player.global_position )
	else:
		pass
	if player.jump_count == 0:
		player.animation_player.play( "jump" )
	else:
		player.animation_player.play("double_jump")
		jump_particles.emitting = true
	player.animation_player.pause()
	
	do_jump()
	
	if player.previous_state == fall and not Input.is_action_pressed( "jump" ):
		await get_tree().physics_frame
		player.velocity.y *= 0.5
		player.change_state( fall )
		pass
	
	pass
# What happens when we exit this state?
func exit() -> void:
	jump_particles.emitting = false
	camera_2d.pan_reset()
	
	pass
# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "special" ) and player.can_dash():
		if player.ground_slam and Input.is_action_pressed( "down" ):
			return ground_slam
		return dash
	if _event.is_action_pressed( "attack" ):
		if Input.is_action_pressed( "down" ):
			if player.can_pogo():
				return pogo
			return next_state
		if player.can_attack():
			if Input.is_action_pressed( "up" ):
				return attack_up
			return attack_air
	if _event.is_action_released( "jump" ):
		return fall
	return next_state
# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	set_jump_frame()
	return next_state
# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	# Pan strength ramps with how fast we're actually rising — a tiny hop
	# barely nudges the camera, a full jump eases toward the full offset.
	var intensity : float = clamp( -player.velocity.y / jump_velocity, 0.0, 1.0 )
	camera_2d.pan_to( -camera_pan_offset * intensity )
	
	if player.is_on_floor():
		
		return idle
	elif player.velocity.y >= 0:
		return fall
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
func do_jump() -> void:
	if player.jump_count > 0:
		if player.double_jump == false:
			return
		elif player.jump_count > 1:
			return
	player.jump_count += 1
	# Any real jump — first or double — starts a fresh air-time as far as
	# pogo is concerned, so it can be used again even if it was already
	# spent earlier in this air-time.
	player.pogo_count = 0
	player.velocity.y = -jump_velocity
	Audio.play_spatial_sound( JUMP_AUDIO, player.global_position, false, true, 0.25 )
	pass
func set_jump_frame() -> void:
	var frame : float = remap( player.velocity.y, -jump_velocity, 0.0, 0.0, 0.5 )
	player.animation_player.seek( frame, true )
	pass
