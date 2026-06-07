
#SaveManager Script
extends Node

const CONFIG_FILE_PATH = "user://settings.cfg"
const SLOTS : Array[ String ] = [
	"save_01", "save_02", "save_03"
]

var current_slot : int = 0
var save_data : Dictionary
var discovered_areas : Array = []
var persistent_data : Dictionary = {}




func _ready() -> void:
	load_configuration()
	SceneManager.scene_entered.connect( _on_scene_entered )
	pass



func create_new_game_save( slot : int ) -> void:
	current_slot = slot
	
	discovered_areas.clear()
	persistent_data.clear()
	
	var new_game_scene : String = "uid://qrtkvued7hjv"
	
	save_data = {
		
		"scene_path" : new_game_scene,
		"x" : 40,
		"y" : 3,
		"hp" : 6,
		"max_hp" : 6,
		"mp" : 50,
		"max_mp" : 100,
		"gold" : 0,
		"dash" : false,
		"double_jump" :false,
		"ground_slam" : false,
		"morph_roll" : false,
		"discovered_areas" : discovered_areas,
		"persistent_data" : persistent_data,
		"check_scene" : new_game_scene,
		"check_x" : 40,
		"check_y" :  3,
		"check_dir" : Vector2.ZERO
	}

	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )
	save_file.close()
	load_game( slot )

func save_game() -> void:
	
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	save_data = {
		
		"scene_path" : SceneManager.current_scene_uid,
		"x" : player.global_position.x,
		"y" :  player.global_position.y,
		"hp" : player.hp,
		"max_hp" : player.max_hp,
		"mp" : player.mp,
		"max_mp" : player.max_mp,
		"gold" : player.gold, 
		"dash" : player.dash,
		"double_jump" : player.double_jump,
		"ground_slam" : player.ground_slam,
		"morph_roll" : player.morph_roll,
		"discovered_areas" : discovered_areas,
		"persistent_data" : persistent_data,
		"check_scene" : SceneManager.current_scene_uid,
		"check_x" : player.global_position.x,
		"check_y" :  player.global_position.y,
		"check_dir" : Vector2.ZERO
	}
	
	write_to_disc()
	pass

func load_game( slot : int ) -> void:
	
	if not FileAccess.file_exists( get_file_name( current_slot ) ):
		return
	current_slot = slot
	
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.READ )
	save_data = JSON.parse_string( save_file.get_line() )
	
	persistent_data = save_data.get( "persistent_data", {} )
	discovered_areas = save_data.get( "discovered_areas", [] )
	var scene_path : String = save_data.get( "scene_path", "uid://qrtkvued7hjv" )
	SceneManager.transition_scene( scene_path, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready
	setup_player()
	await setup_player()
	save_game()
	pass


func setup_player() -> void:
	var player : Player = null 
	while not player:
		player = get_tree().get_first_node_in_group( "Player" )
		await get_tree().process_frame

	player.max_hp = save_data.get( "max_hp", 6 )
	player.hp = save_data.get( "hp", 6 )
	player.max_mp = save_data.get( "max_mp", 100 )
	player.mp = save_data.get( "mp", 50 )
	player.gold = save_data.get( "gold", 0 )
	
	player.dash = save_data.get( "dash", false )
	player.double_jump = save_data.get( "double_jump", false )
	player.ground_slam = save_data.get( "ground_slam", false )
	player.morph_roll = save_data.get( "morph_roll", false )
	
	player.global_position = Vector2(
		save_data.get( "x", 0 ),
		save_data.get( "y", 0 ),
	)
	
	pass

func restore_checkpoint() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	var fade_pos : Vector2 = SceneManager.get_fade_pos( "down" )
	get_tree().paused = true
	SceneManager.fade.visible = true
	await SceneManager.fade_screen( fade_pos, Vector2.ZERO )
	
	player.global_position = Vector2(
		save_data.get( "check_x", 0 ),
		save_data.get( "check_y", 0 ),
	)
	player.direction = Vector2.ZERO
	
	get_tree().paused = false
	await get_tree().process_frame
	await SceneManager.fade_screen( Vector2.ZERO, -fade_pos )
	
	SceneManager.fade.visible = false
	

	pass
	
func game_over() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	var fade_pos : Vector2 = SceneManager.get_fade_pos( "down" )
	get_tree().paused = true
	SceneManager.fade.visible = true
	await SceneManager.fade_screen( fade_pos, Vector2.ZERO )
	
	player.global_position = Vector2(
		save_data.get( "x", 0 ),
		save_data.get( "y", 0 ),
	)
	player.direction = Vector2.ZERO
	player.hp = player.max_hp
	player.mp = player.max_mp
	player.gold = 0
	get_tree().paused = false
	await get_tree().process_frame
	await SceneManager.fade_screen( Vector2.ZERO, -fade_pos )
	player.death_rec.visible = false
	PlayerHud.show_hud()
	save_game()
	player.sprite_2d.modulate = Color(1, 1, 1, 1)
	SceneManager.fade.visible = false
	

	pass

func write_to_disc() -> void:
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )
	pass

func get_file_name( slot : int ) -> String:
	return "user://" + SLOTS[ slot ] + ".sav"

func save_file_exists (slot : int ) -> bool:
	return FileAccess.file_exists( get_file_name( slot ))


func is_area_discovered( scene_uid : String ) -> bool:
	return discovered_areas.has( scene_uid )



func _on_scene_entered( scene_uid : String ) -> void:
	if discovered_areas.has( scene_uid ):
		return
	else:
		discovered_areas.append( scene_uid )
	pass

#region Configuration settings

func save_configuration() -> void:
	var config := ConfigFile.new()
	config.set_value( "audio", "music", AudioServer.get_bus_volume_linear( 2 ) )
	config.set_value( "audio", "sfx", AudioServer.get_bus_volume_linear( 3 ) )
	config.set_value( "audio", "ui", AudioServer.get_bus_volume_linear( 4 ) )
	config.save( CONFIG_FILE_PATH )
	pass


func load_configuration() -> void:
	var config := ConfigFile.new()
	var err = config.load( CONFIG_FILE_PATH )
	
	if err != OK:
		AudioServer.set_bus_volume_linear( 2, 0.8 )
		AudioServer.set_bus_volume_linear( 3, 1.0 )
		AudioServer.set_bus_volume_linear( 4, 1.0 )
		save_configuration()
		return
	
	AudioServer.set_bus_volume_linear( 2, config.get_value( "audio", "music", 0.8 ) )
	AudioServer.set_bus_volume_linear( 3, config.get_value( "audio", "sfx", 1.0 ) )
	AudioServer.set_bus_volume_linear( 4, config.get_value( "audio", "ui", 1.0 ) )
	pass


#endregion
