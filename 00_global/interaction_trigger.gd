@icon( "uid://dvc1rhwgsy4mo" )
class_name InteractionTrigger
extends Node2D

## Generic interaction node: player steps into area_2d, a hint (KLETTERN /
## BENUTZEN / ANSEHEN / LESEN / UNTERHALTEN / ...) appears, and pressing
## "up" runs every InteractionAction in `actions`, in order — combine as
## many as you need (e.g. play an animation AND save the game AND show
## text) by just adding more entries.
##
## For anything an action resource can't express (a condition, custom
## visuals, a door that also needs its own audio/sprite logic, ...),
## connect to the `interacted` signal below from a parent/sibling script
## instead — see switch.gd, save_point.gd, ladder.gd for examples of both
## approaches side by side.

signal interacted( player : Player )

@onready var area_2d: Area2D = $Area2D

## Shown as the input prompt while the player is inside area_2d.
@export var trigger : String = "BENUTZEN"

## Run in order on interact. Combine as many action types as you need.
@export var actions : Array[ InteractionAction ] = []

## If true, this interaction can only ever fire once — persisted via
## SaveManager.persistent_data (same pattern as Switch/SavePoint/
## BossBattleOrchestrator), so it stays spent across reloads. Set this in
## the Inspector, not from a parent script's _ready() — children run their
## own _ready() before their parent does, so anything a parent tries to set
## here would arrive too late to affect this node's own _ready() check.
@export var one_use : bool = false

## Key persistent_data is stored under when one_use is true. Leave empty to
## auto-derive one from this node's path (fine as long as you don't
## reparent/rename this node) — set it explicitly if you need a stable id
## regardless of scene position.
@export var persistent_id : String = ""


func _ready() -> void:
	if one_use and is_used():
		queue_free()  # already spent — nothing left to connect or show
		return

	area_2d.body_entered.connect( _on_player_entered )
	area_2d.body_exited.connect( _on_player_exited )
	pass


## Public so a parent script (Switch, SavePoint, ...) can check this in its
## own _ready() to restore the right visual state without keeping a second,
## separate persisted key of its own for "has this already happened."
func is_used() -> bool:
	return SaveManager.persistent_data.get( _id(), false ) == true


func _on_player_entered( _n : Node2D ) -> void:
	Messages.player_interacted.connect( _on_player_interacted )
	Messages.input_hint_changed.emit( trigger, false )
	pass


func _on_player_exited( _n : Node2D ) -> void:
	if Messages.player_interacted.is_connected( _on_player_interacted ):
		Messages.player_interacted.disconnect( _on_player_interacted )
	Messages.display_text.emit( "", true )
	Messages.input_hint_changed.emit( "", true )
	pass


func _on_player_interacted( player : Player ) -> void:
	Messages.input_hint_changed.emit( "", false )

	for action in actions:
		if action:
			action.execute( player, self )

	interacted.emit( player )

	if one_use:
		SaveManager.persistent_data[ _id() ] = true
		if Messages.player_interacted.is_connected( _on_player_interacted ):
			Messages.player_interacted.disconnect( _on_player_interacted )
		queue_free()  # spent — remove the whole trigger, area included
	pass


func _id() -> String:
	if persistent_id.is_empty():
		persistent_id = str( get_path() )
	return SaveManager.persistent_key( self, persistent_id )
