@icon( "uid://c2dxt4qqluf4e" )
@tool

class_name MapNode extends Control

const SCALE_FACTOR : float = 40


@export_file( "*.tscn" ) var linked_scene : String : set = _on_scene_set
@export_tool_button( "Update" ) var update_node_action = update_node

## A simplified silhouette image of this room, shown behind the entrance
## markers. Doesn't need to be pixel-accurate — just readable at map scale,
## the way Hollow Knight's hand-inked room shapes are. Auto-populated by
## update_node() if a "<scene_name>_map.png" file exists next to the level.
@export var room_texture : Texture2D :
	set( value ):
		room_texture = value
		_apply_texture()

@export var entrances_top : Array[ float ] = []
@export var entrances_right : Array[ float ] = []
@export var entrances_bottom : Array[ float ] = []
@export var entrances_left : Array[ float ] = []

var indicator_offset : Vector2 = Vector2.ZERO

@onready var label: Label = $Label
@onready var transition_blocks: Control = %TransitionBlocks
@onready var texture_rect: TextureRect = %TextureRect



func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_texture()
	else:
		label.queue_free()
		create_transition_blocks()
		_apply_texture()
		
		if not SaveManager.is_area_revealed_on_map( linked_scene ):
			visible = false
		elif SceneManager.current_scene_uid == linked_scene:
			display_player_location()
		
	pass



func _on_scene_set( value : String ) -> void:
	if linked_scene != value:
		linked_scene = value
		if Engine.is_editor_hint():
			update_node()
	pass



func update_node() -> void:
	var new_size : Vector2 = Vector2( 480, 270 )
	var transitions : Array[ LevelTransition ] = []
	
	if ResourceLoader.exists( linked_scene ):
		var packed_scene : PackedScene = ResourceLoader.load( linked_scene ) as PackedScene
		if packed_scene:
			var instance = packed_scene.instantiate()
			if instance:
				update_node_label( instance )
				# NOTE: a scene can now hold more than one LevelBounds
				# (PlayerCamera auto-switches between them at runtime — see
				# player_camera.gd/level_bounds.gd), so a room can have
				# several "shapes" in one file. The minimap still assumes
				# one thumbnail per scene file, deliberately left as-is for
				# now: whichever LevelBounds is LAST among this scene's
				# children wins here, arbitrarily. Revisit if a scene's
				# minimap thumbnail ever looks wrong because of this.
				for c in instance.get_children():
					if c is LevelBounds:
						new_size = Vector2( c.width, c.height )
						indicator_offset = c.position
					elif c is LevelTransition:
						transitions.append( c )
				instance.queue_free()
	
	size = new_size / SCALE_FACTOR
	size = size.round()
	create_entrance_data( transitions )
	create_transition_blocks()
	_try_autoload_room_texture()
	_apply_texture()
	pass



func update_node_label( scene : Node ) -> void:
	if not label:
		label = $Label
	var t : String = scene.scene_file_path
	t = t.replace( "res://levels/", "" )
	t = t.replace( ".tscn", "" )
	label.text = t
	pass


func create_entrance_data( transitions : Array[ LevelTransition ] ) -> void:
	entrances_bottom.clear()
	entrances_left.clear()
	entrances_right.clear()
	entrances_top.clear()
	
	for t in transitions:
		var pos : Vector2 = ( t.global_position - indicator_offset ) / SCALE_FACTOR
		if t.location == LevelTransition.SIDE.LEFT:
			var offset : float = clampf(
					pos.y - 3,
					2.0, self.size.y - 5
				)
			entrances_left.append( offset )
		elif t.location == LevelTransition.SIDE.RIGHT:
			var offset : float = clampf(
					pos.y - 3,
					2.0, self.size.y - 5
				)
			entrances_right.append( offset )
		elif t.location == LevelTransition.SIDE.TOP:
			var offset : float = clampf(
					pos.x,
					2.0, self.size.x - 5
				)
			entrances_top.append( offset )
		elif t.location == LevelTransition.SIDE.BOTTOM:
			var offset : float = clampf(
					pos.x,
					2.0, self.size.x - 5
				)
			entrances_bottom.append( offset )
	pass


func create_transition_blocks() -> void:
	if not transition_blocks:
		transition_blocks = %TransitionBlocks
	
	for c in transition_blocks.get_children():
		c.queue_free()
	
	for t in entrances_left:
		var block : ColorRect = add_block()
		block.size.y = 3
		block.position.x = 0
		block.position.y = t
	
	for t in entrances_right:
		var block : ColorRect = add_block()
		block.size.y = 3
		block.position.x = self.size.x - 1
		block.position.y = t
	
	for t in entrances_top:
		var block : ColorRect = add_block()
		block.size.x = 3
		block.position.y = 0
		block.position.x = t
	
	for t in entrances_bottom:
		var block : ColorRect = add_block()
		block.size.x = 3
		block.position.y = self.size.y - 1
		block.position.x = t
	pass



func add_block() -> ColorRect:
	var block : ColorRect = ColorRect.new()
	transition_blocks.add_child( block )
	block.custom_minimum_size.x = 1
	block.custom_minimum_size.y = 1
	return block



func display_player_location() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	var i : Control = %PlayerIndicator
	var pos : Vector2 = position
	pos += (( player.global_position - indicator_offset ) / SCALE_FACTOR )
	var bracket : Vector2 = Vector2( 2, 2 )
	pos = pos.clamp( position + bracket, position + size - bracket )
	i.position = pos
	pass


func _apply_texture() -> void:
	if not texture_rect:
		return
	texture_rect.texture = room_texture
	texture_rect.visible = room_texture != null
	texture_rect.size = size
	pass


## Looks for a hand-authored map thumbnail next to the level scene, named
## "<scene_name>_map.png" (e.g. levels/forest_01.tscn -> levels/forest_01_map.png).
## Draw this yourself as a simplified silhouette of the room's terrain —
## doesn't need to be pixel-accurate, just readable at map scale.
func _try_autoload_room_texture() -> void:
	var resolved_path : String = linked_scene
	if linked_scene.begins_with( "uid://" ):
		resolved_path = ResourceUID.get_id_path( ResourceUID.text_to_id( linked_scene ) )
	var texture_path : String = resolved_path.get_basename() + "_map.png"
	if ResourceLoader.exists( texture_path ):
		room_texture = load( texture_path )
	pass
