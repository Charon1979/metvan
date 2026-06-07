extends Node2D
class_name Checkpoint

@onready var area_2d: Area2D = $Area2D



func _ready() -> void:
	area_2d.body_entered.connect( _on_player_entered )
	
	
	pass

func _on_player_entered( n : Node2D ) -> void:
	
	SaveManager.save_data = {
		
		"check_scene" : SceneManager.current_scene_uid,
		"check_x" : n.global_position.x,
		"check_y" :  n.global_position.y,
		"check_dir" : n.direction
	}
	
	pass
	
