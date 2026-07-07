@icon( "uid://byacoub15iwlt" )

class_name PlayerSensor
extends Area2D


signal player_entered
signal player_exited
signal started_searching

@export_category("Visual Sensor")
@export var use_visual_sensor : bool = true
@export var search_duration : float = 3.0

@export_category("Audio Sensor")
@export var use_audio_sensor : bool = false
@export var audio_detect_dist : float = 192.0
@export var listening_duration : float = 2.0
@export_range(0.1, 1.0) var min_audio_sense : float = 0.5

var can_see_player : bool = false
var enemy : Enemy
var timer : float


func _ready() -> void:
	set_collision_layer_value( 1, false )
	set_collision_mask_value( 1, false )
	if owner is Enemy:
		enemy = owner
		set_collision_mask_value( 5, true )
		if use_audio_sensor:
			Audio.player_made_sound.connect( _on_player_sound )
		if use_visual_sensor:
			body_entered.connect( _on_body_entered )
			body_exited.connect( _on_body_exited )
		enemy.direction_changed.connect( _on_direction_changed )
	pass

func _physics_process( delta: float ) -> void:
	if timer > 0 and not can_see_player:
		timer -= delta
		if timer <= 0:
			player_exited.emit()
			enemy.blackboard.target = null
	pass

func _on_body_entered( n : Node2D ) -> void:
	if n is Player:
		player_entered.emit()
		can_see_player = true
		enemy.blackboard.target = n
	else:
		pass

func _on_body_exited( n : Node2D ) -> void:
	if n is Player:
		started_searching.emit()
		can_see_player = false
		timer = search_duration
	else:
		pass
	

func _on_direction_changed( dir: float ) -> void:
	if dir < 0:
		scale.x = -1
	elif dir > 0:
		scale.x = 1
	pass

func  _on_player_sound( pos: Vector2, volume : float ) -> void:

	var sound_dist: float = global_position.distance_to(pos)

	var t: float = clampf(1.0 - sound_dist / audio_detect_dist, 0.0, 1.0)

	var perceived_vol: float = volume * pow(t, 0.5)

	perceived_vol *= lerp(1.0, 2.0, t)

	if perceived_vol >= min_audio_sense:
		timer = listening_duration
		enemy.blackboard.target = get_tree().get_first_node_in_group("Player")
		
	pass
