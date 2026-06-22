@icon( "uid://cltev4ia8x75q" )

class_name PlayerGold
extends CharacterBody2D

const GOLD_AUDIO = preload("uid://lk8px256n5bm")

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var gold_value : int = 0
var can_pickup : bool = false

@onready var area_2d: Area2D = $Area2D



func _ready() -> void:
	SceneManager.load_scene_finished.connect( _on_scene_finished )
	area_2d.body_entered.connect( _on_player_entered )
	can_pickup = false
	pass 


func _physics_process( delta: float ) -> void:
	
	move_and_slide()
	velocity.y += gravity * delta
	
	pass

func _on_player_entered( n : Node2D ) -> void:
	
	if n is Player:
		if not can_pickup:
			return
		
		area_2d.body_entered.disconnect( _on_player_entered )
		Audio.play_spatial_sound( GOLD_AUDIO, global_position, false, true, 0.0 )
		SaveManager.persistent_data.erase("player_gold_drop")
		SaveManager.save_game()
		SceneManager.load_scene_finished.disconnect( _on_scene_finished )
		n.gold += gold_value
		
		queue_free()
	pass

func _on_scene_finished() -> void:
	
	can_pickup = true
	pass
