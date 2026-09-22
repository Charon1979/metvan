@icon( "uid://dgirl16l8umh7" )

class_name PlayerSpawn extends Node2D


func _ready() -> void:
	visible = false
	await get_tree().process_frame

	if get_tree().get_first_node_in_group( "Player" ):
		return

	var scene_path : String = SaveManager.get_active_character_scene()
	var player : Player = load( scene_path ).instantiate()
	get_tree().root.add_child( player )
	player.global_position = self.global_position
	pass
