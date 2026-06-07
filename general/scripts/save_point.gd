@icon( "uid://dvc1rhwgsy4mo" )
class_name SavePoint
extends Node2D

@onready var animation_player: AnimationPlayer = $Node2D/AnimationPlayer
@onready var area_2d: Area2D = $Area2D



func _ready() -> void:
	area_2d.body_entered.connect( _on_player_entered )
	area_2d.body_exited.connect( _on_player_exited )
	animation_player.play( "fire_out" )
	pass


func _on_player_entered( _n : Node2D ) -> void:
	Messages.player_interacted.connect( _on_player_interacted )
	Messages.input_hint_changed.emit( "RASTEN" )
	pass

func _on_player_exited( _n : Node2D ) -> void:
	Messages.player_interacted.disconnect( _on_player_interacted )
	Messages.input_hint_changed.emit( "" )
	pass

func _on_player_interacted( _player : Player ) -> void:
	Messages.player_healed.emit( 999 )
	Messages.player_casting.emit( 999 )
	SaveManager.save_game()
	animation_player.play( "fire_on" )
	animation_player.seek( 0 )
	pass
