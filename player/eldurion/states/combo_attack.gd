@icon("uid://bdtuue7gbi0h8")
class_name PlayerStateComboAttack
extends PlayerState

const AUDIO_ATTACK_1 = preload( "uid://c0h35s8l6r224" )
const AUDIO_ATTACK_2 = preload( "uid://va2ksh81j1jg" )
const AUDIO_ATTACK_3 = preload( "uid://va2ksh81j1jg" )


@export var combo_time_window : float = 0.3
@export var speed : float = 0

var timer : float = 0
var combo : int = 0


func init() -> void:
	pass



func enter() -> void:
	attacking()
	player.animation_player.animation_finished.connect( _on_animation_finished )
	pass



func exit() -> void:
	timer = 0
	combo = 0
	player.animation_player.animation_finished.disconnect( _on_animation_finished )
	next_state = null
	pass



func handle_input( _event : InputEvent ) -> PlayerState:
	if _event.is_action_pressed( "attack" ):
		timer = combo_time_window
	# Handle input
	#if _event.is_action_pressed( "jump" ):
		#return jump

	return null



func process( delta: float ) -> PlayerState:
	timer -= delta
	
	return next_state



func physics_process( _delta: float ) -> PlayerState:
	player.velocity.x = player.direction.x * speed
	
	return null


func attacking() -> void:
	
	var anim_name : String = "attack_"
	
	
	anim_name = "attack_" + str(combo)
	timer = 0
	player.animation_player.play( anim_name )
	Audio.play_spatial_sound( attack_sound() , player.global_position,false, true, 0.5 )
	
	pass

func _end_attack() -> void:
	 
	if timer > 0:
		combo = wrapi( combo + 1, 0, 3  )
		attacking()
	else:
		next_state = idle


func _on_animation_finished( _anim_name : String ) -> void:
	_end_attack()
	
	pass

func attack_sound() -> AudioStream:
	var audio_name : AudioStream = AUDIO_ATTACK_1
	if combo == 1:
		audio_name = AUDIO_ATTACK_2
	elif combo == 2:
		audio_name = AUDIO_ATTACK_3
		return audio_name
	return audio_name
