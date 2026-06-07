class_name PlayerStateLookUp extends PlayerState

@onready var camera_2d: Camera2D = $"../../Camera2D"



@export var lookup_time : float = 2.0

var lookup_timer : float = 2
var target_offset_y : float = -128.0



func _init() -> void:
	pass

#What happens when we enter this state?
func enter() -> void:
	lookup_timer = lookup_time
	
	pass

#What happens when we exit this state?
func exit() -> void:
	lookup_timer = lookup_time
	
	pass

#What hapens when an input is pressed?
func handle_input( event : InputEvent ) -> PlayerState:
	if event.is_action_pressed( "jump" ):
		return jump
	return next_state



#What happens each process tick of a state?
func  process( _delta: float ) -> PlayerState:
	if player.direction.y <= -0.5:
		lookup_timer -= _delta
		if lookup_timer <= 0:
			camera_2d.offset.y = lerp(camera_2d.offset.y, target_offset_y, _delta * 2.0)
		

	if player.direction.y <= -0.5:
		if camera_2d.offset.y < 0:
			player.camera_2d.reset_smoothing()
			camera_2d.offset.y = 0
		
		return idle
	return next_state
