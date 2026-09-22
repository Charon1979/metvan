class_name RegionInfo
extends Node

## Drop this as a child node anywhere in a level's scene tree to tag which
## region/level that scene belongs to. SaveManager looks it up (via the
## "region_info" group) whenever it captures save data, so tagging a scene
## is purely an editor step — no code changes needed per level.
##
## This is also the one place every persisted per-instance object IN this
## scene (switches, save points, boss fights, the ogre-room rocks, secret
## areas, ...) now gets its SaveManager.persistent_data key from — see
## persistent_key() below. Before this, each of those computed its own key
## by walking ResourceUID.path_to_uid(owner.scene_file_path) + parent name +
## node name (or a get_path() fallback) at runtime — four slightly
## different, independently-duplicated schemes across the codebase
## (BossBattleOrchestrator, FallingRock, InteractionTrigger, SavePoint, ...),
## every one of them silently liable to drift if a node ever got renamed or
## reparented. Now they all call SaveManager.persistent_key( self,
## persistent_id ) instead, which just routes through this node's
## region_id — set once by hand, never recomputed from the scene tree.
@export var region_id : String = ""
@export var region_name : String = ""
## Small icon shown next to this level's slot in the Load Game menu.
@export var icon : Texture2D
## Shown as this level's marker/thumbnail on the world map. Separate from
## `icon` above so a level can use a different image for each.
@export var map_picture : Texture2D

func _ready() -> void:
	add_to_group( "region_info" )
	if region_id == "":
		push_warning( "RegionInfo on %s has no region_id set — every SaveManager.persistent_key() call in this scene will collide with any other unkeyed scene's." % get_path() )
	pass

## Builds a stable, globally-unique persistent_data key for an object that
## lives inside this scene. instance_id only needs to be unique WITHIN this
## one scene (e.g. "entrance_rock", "west_switch", "ogre") — region_id
## already makes the result unique across the whole game. Prefer
## SaveManager.persistent_key( node, instance_id ) over calling this
## directly — it finds the right RegionInfo for you.
func persistent_key( instance_id : String ) -> String:
	return region_id + "/" + instance_id
