@tool
@icon( "uid://cvuhbo452mnha" )
extends Node2D
class_name Door


@onready var animation_player: AnimationPlayer = $AnimationPlayer



func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	for c in get_children():
		if c is Switch:
			c.activated.connect( _on_switch_activated )
			if c.is_open == true:
				_on_switch_is_open()
	pass


func _on_switch_activated() -> void:
	animation_player.play( "opening" )
	pass

func _on_switch_is_open() -> void:
	animation_player.play( "opened" )
	pass

func _get_configuration_warnings() -> PackedStringArray:
	if _check_for_switch() == false:
		return ["Requires a Switch node!"]
	return[]

func _check_for_switch() -> bool:
	for c in get_children():
		if c is Switch:
			return true
	return false
