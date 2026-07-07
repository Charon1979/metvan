@icon( "uid://dvc1rhwgsy4mo" )
class_name SavePoint
extends Node2D

## Key SaveManager.persistent_data is checked against — only the save point
## whose save_point_id matches this value shows as lit. There's only ever
## one active value stored, so lighting a new save point automatically
## makes every other one check out as unlit, with nothing needing to reach
## out and turn the previous one off directly.
const ACTIVE_KEY : String = "active_save_point"

## Unique per save point instance. Set this explicitly per-instance in the
## editor; if left empty it falls back to the node's scene path, which is
## fine as long as you don't reparent/rename these around.
@export var save_point_id : String = ""

## Whether this save point should (eventually) route to the character-select
## scene. Not wired up to anything yet — see _go_to_character_select() below.
@export var enable_character_select : bool = false

@onready var animation_player: AnimationPlayer = $Node2D/AnimationPlayer
@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	if save_point_id == "":
		save_point_id = str( get_path() )

	area_2d.body_entered.connect( _on_player_entered )
	area_2d.body_exited.connect( _on_player_exited )

	if SaveManager.persistent_data.get( ACTIVE_KEY, "" ) == save_point_id:
		animation_player.play( "fire_on" )
	else:
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

	# Overwrite the single shared key — this is the only place "which save
	# point is active" gets set, so whichever one was lit before now reads
	# as unlit the next time its own _ready() runs.
	SaveManager.persistent_data[ ACTIVE_KEY ] = save_point_id

	animation_player.play( "fire_on" )
	animation_player.seek( 0 )

	SaveManager.save_game()
	_go_to_character_select( enable_character_select )
	pass


## Placeholder — fill this in once the character-select scene exists.
func _go_to_character_select( _go : bool ) -> void:
	pass
