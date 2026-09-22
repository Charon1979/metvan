class_name InteractionActionTransition
extends InteractionAction

## Sends the player to another scene. Fields mirror SceneManager.
## transition_scene()'s signature exactly — this just forwards to it.
## Covers KLETTERN-style ladder/door transitions.
##
## IMPORTANT — this is NOT an absolute-coordinate teleport. Positioning is
## handled entirely by LevelTransition nodes: target_area_name must exactly
## match the node name of an actual LevelTransition instance that already
## exists in the destination scene (see level_transistion.gd's
## _on_new_scene_ready — every LevelTransition in the loaded scene checks
## `target_name == name` and only the one that matches moves the player, to
## its own global_position + offset). If nothing in the target scene has
## that exact name, no one repositions the player at all, and they're left
## wherever they physically were in the previous scene — which looks like
## "always the same place, out of bounds" no matter what you set here.

@export var scene_uid : String = ""
## Must exactly match the node name of a LevelTransition already present in
## the target scene — not a free-form marker id.
@export var target_area_name : String = ""
## Relative to that LevelTransition node's own position, NOT an absolute
## world coordinate (e.g. Vector2(-48, 0) to stand just outside it).
@export var offset : Vector2 = Vector2.ZERO
## Which way the player enters facing — whatever strings SceneManager.
## transition_scene()'s last argument expects (e.g. "left", "right", "up", "down").
@export var facing : String = "left"


func execute( _player : Player, _trigger : InteractionTrigger ) -> void:
	SceneManager.transition_scene( scene_uid, target_area_name, offset, facing )
