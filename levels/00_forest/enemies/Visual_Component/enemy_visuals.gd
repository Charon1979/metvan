@tool
class_name EnemyVisuals
extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var animation_library: AnimationLibrary:
	set(value):
		animation_library = value
		_apply_animation_library()
		
var facing_right := true

func _ready() -> void:
	_apply_animation_library()
	
func _apply_animation_library() -> void:
	if not animation_player or not animation_library:
		return
	for lib_name in animation_player.get_animation_library_list():
		animation_player.remove_animation_library(lib_name)
	animation_player.add_animation_library("", animation_library)
	
func apply_visuals() -> void:
	pass
	
func set_facing_direction(dir: float) -> void:
	if dir == 0:
		return
	facing_right = dir > 0
	_apply_facing()
	
func _apply_facing() -> void:
	scale.x = 1 if facing_right else -1
	
func play_animation(name: StringName) -> void:
	if animation_player:
		animation_player.play(name)
		
func is_animation_playing() -> bool:
	return animation_player and animation_player.is_playing()
	
func get_current_animation() -> StringName:
	return animation_player.current_animation
	
func get_animation_length(name: StringName) -> float:
	if !animation_player:
		return 0
	var anim := animation_player.get_animation(name)
	return anim.length if anim else 0
	
func get_current_animation_length() -> float:
	return get_animation_length(animation_player.current_animation)
	
func wait_for_current_animation() -> void:
	var len := get_current_animation_length()
	if len > 0:
		await get_tree().create_timer(len).timeout
		
func play_and_wait(name: StringName) -> void:
	play_animation(name)
	await wait_for_current_animation()
