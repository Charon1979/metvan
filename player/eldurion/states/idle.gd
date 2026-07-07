@icon("uid://bdtuue7gbi0h8")
class_name PlayerStateIdle extends PlayerState

@export var look_hold_delay : float = 2.0

@onready var camera_2d: PlayerCamera = $"../../Camera2D"

var look_hold_time : float = 0.0
var look_direction : int = 0   # 1 = down, -1 = up, 0 = neither held
var looking : bool = false     # true once look_hold_delay has been crossed and the pan is active


# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:
	player.sprite_2d.z_index = 1
	player.animation_player.play( "idle" )
	player.jump_count = 0
	player.dash_count = 0
	_reset_look()


# What happens when we exit this state?
func exit() -> void:
	# Holding the look direction only pans the camera while actually idle —
	# leaving idle for any reason (moving, jumping, attacking...) cancels it.
	_reset_look()


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "special" ) and player.can_dash():
		return dash
	if _event.is_action_pressed( "attack" ):
		return attack
	if _event.is_action_pressed( "jump" ):
		return jump
	return null


# What happens each process tick in this state?
func process( delta: float ) -> PlayerState:
	if player.direction.x != 0:
		return run

	_update_look( delta )

	return null


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = 0
	if player.is_on_floor() == false:
		return fall
	return next_state


func _update_look( delta : float ) -> void:
	var held_dir : int = 0
	if player.direction.y > 0.5:
		held_dir = 1
	elif player.direction.y < -0.5:
		held_dir = -1

	if held_dir != look_direction:
		# Released, or switched from up to down (or vice versa) — start the hold over.
		look_direction = held_dir
		look_hold_time = 0.0
		if looking:
			looking = false
			camera_2d.pan_reset()

	if look_direction == 0:
		return

	look_hold_time += delta
	if not looking and look_hold_time >= look_hold_delay:
		looking = true
		if look_direction > 0:
			camera_2d.pan_down()
		else:
			camera_2d.pan_up()


func _reset_look() -> void:
	look_hold_time = 0.0
	look_direction = 0
	if looking:
		looking = false
		camera_2d.pan_reset()
