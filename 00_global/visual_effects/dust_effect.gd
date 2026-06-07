class_name DustEffect
extends Sprite2D

enum TYPE { JUMP, LAND, HIT }
var ground_type := {
		0: "null",
		1: "grass",
		2: "leaves",
		3: "dirt",
		4: "dust"
	}
	
var ground_id : int = 0

@onready var animation_player: AnimationPlayer = $AnimationPlayer



func start( type : TYPE ) -> void:
	get_dust_type()
	
	var anim_name : String = ground_type[ground_id]
	match type:
		TYPE.JUMP:
			anim_name = "jump_" + ground_type[ground_id]
			position.y -= 14
			
			
		TYPE.LAND:
			anim_name = "land_" + ground_type[ground_id]
			position.y -= 16
		TYPE.HIT:
			anim_name = "hit_light"
			position.y -= 20
			rotation_degrees = randi_range( -4, 4 ) * 45
	animation_player.play( anim_name )
	await animation_player.animation_finished
	queue_free()
	pass



func get_dust_type() -> void:
	for t in get_tree().get_nodes_in_group( "Tilemap" ):
		if t is TileMapLayer:
			
			var cell : Vector2i = t.local_to_map( t.to_local( global_position) )
			var data : TileData = t.get_cell_tile_data (cell)
			if data:
				var type = data.get_custom_data( "ground_type" )
				ground_id = type
			else:
				pass
		else:
			pass
	
