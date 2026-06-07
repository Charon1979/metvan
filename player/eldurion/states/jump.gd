@icon("uid://bdtuue7gbi0h8")

class_name PlayerStateJump extends PlayerState

@export var jump_velocity : float = 450.0
@onready var jump_audio: AudioStreamPlayer2D = %JumpAudio
@onready var jump_particles: GPUParticles2D = $"../../ParticleSystems/Jump_Particles"







# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:
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
	
	pass


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "special" ) and player.can_dash():
		if player.ground_slam and Input.is_action_pressed( "down" ):
			return ground_slam
		return dash
	if _event.is_action_released( "jump" ):
		return fall
	return next_state


# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	set_jump_frame()
	return next_state


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
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
	player.velocity.y = -jump_velocity
	jump_audio.play()
	pass


func set_jump_frame() -> void:
	var frame : float = remap( player.velocity.y, -jump_velocity, 0.0, 0.0, 0.5 )
	player.animation_player.seek( frame, true )
	pass
