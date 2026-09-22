extends Node
const CONFIG_FILE_PATH = "user://settings.cfg"
const SLOTS : Array[ String ] = [
	"save_01", "save_02", "save_03"
]
const CHARACTER_SCENES : Dictionary = {
	"eldurion" : "uid://jt8n0ekwi2xy",
}
const DEFAULT_CHARACTER_ID : String = "eldurion"
## Where a brand new game drops the player. Single source of truth so
## create_new_game_save(), load_game()'s "no save file" fallback, and
## game_over()'s "no real checkpoint exists yet" fallback all agree on the
## same starting point instead of three separately-hardcoded copies.
const NEW_GAME_SCENE : String = "uid://kyo44gx1xjia"
const NEW_GAME_START : Vector2 = Vector2( 228, 3 )
var current_slot : int = 0
var save_data : Dictionary
var discovered_areas : Array = []       # live, this session — updates the instant you enter a room
var revealed_on_map : Array = []        # what's actually been saved — only this drives the map
var persistent_data : Dictionary = {}
# Playtime accumulates here while a game is active and gets folded into
# save_data["playtime"] (with the accumulator reset to 0) on every write,
# so it survives across multiple saves in one session and across sessions.
var _session_playtime : float = 0.0
var _tracking_playtime : bool = false
func _ready() -> void:
	load_configuration()
	SceneManager.scene_entered.connect( _on_scene_entered )
	Messages.back_to_title_screen.connect( _on_back_to_title )
	pass
func _process( delta : float ) -> void:
	if _tracking_playtime:
		_session_playtime += delta
func _on_back_to_title() -> void:
	_tracking_playtime = false
	_session_playtime = 0.0
## Folds the session's accumulated playtime into save_data and resets the
## accumulator. Call before any write_to_disc() so the file is never stale.
func _fold_playtime() -> void:
	save_data["playtime"] = save_data.get( "playtime", 0.0 ) + _session_playtime
	_session_playtime = 0.0
## Builds a fresh save, drops the player into the starting scene, and then
## captures + writes that state to disk via _capture_save_data() — the same
## call save_game() uses at a real savepoint. This guarantees check_x/check_y
## (and x/y) are always a valid, on-disk checkpoint the instant the player
## exists, so dying before ever touching a savepoint still respawns at the
## real start position instead of a stale/uninitialized one.
## NOTE: this used to pre-write a raw file and then call load_game(slot),
## which re-read that file back through JSON.parse_string(). That round trip
## worked but was fragile (JSON can't round-trip non-JSON-native Variant
## types like Vector2 cleanly) and made the "checkpoint on spawn" behavior
## an indirect side effect instead of an explicit step. Doing the capture
## directly here removes that dependency.
func create_new_game_save( slot : int ) -> void:
	current_slot = slot
	discovered_areas.clear()
	revealed_on_map.clear()
	persistent_data.clear()
	_session_playtime = 0.0
	save_data = {
		"character_id" : DEFAULT_CHARACTER_ID,
		"scene_path" : NEW_GAME_SCENE,
		"x" : NEW_GAME_START.x,
		"y" : NEW_GAME_START.y,
		"hp" : 6,
		"max_hp" : 6,
		"resource" : 50,
		"max_resource" : 100,
		"gold" : 0,
		"dash" : false,
		"double_jump" :false,
		"ground_slam" : false,
		"morph_roll" : false,
		"unique_abilities" : {},
		"discovered_areas" : discovered_areas.duplicate(),
		"persistent_data" : persistent_data,
		"check_scene" : NEW_GAME_SCENE,
		"check_x" : NEW_GAME_START.x,
		"check_y" : NEW_GAME_START.y,
		"check_dir" : Vector2.ZERO,
		"playtime" : 0.0,
		"last_saved_unix" : int( Time.get_unix_time_from_system() ),
		"region_id" : "",
		"region_name" : "",
		"region_icon" : "",
	}
	SpawnManager.reset_all()
	SceneManager.transition_scene( NEW_GAME_SCENE, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready
	await setup_player()
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	_capture_save_data( player )
	pass
## Captures the given player's current state into save_data and writes it to disk.
## Does NOT transition scenes — callers that need a scene reload/fade handle that themselves.
func _capture_save_data( player : Player ) -> void:
	var total_playtime : float = save_data.get( "playtime", 0.0 ) + _session_playtime
	_session_playtime = 0.0
	var region_info : Dictionary = _get_current_region_info()
	save_data = {
		"character_id" : player.character_id,
		"scene_path" : SceneManager.current_scene_uid,
		"x" : player.global_position.x,
		"y" : player.global_position.y,
		"hp" : player.hp,
		"max_hp" : player.max_hp,
		"resource" : player.resource_current,
		"max_resource" : player.resource_max,
		"gold" : player.gold,
		"dash" : player.dash,
		"double_jump" : player.double_jump,
		"ground_slam" : player.ground_slam,
		"morph_roll" : player.morph_roll,
		"unique_abilities" : player.unique_abilities,
		"discovered_areas" : discovered_areas.duplicate(),
		"persistent_data" : persistent_data,
		"check_scene" : SceneManager.current_scene_uid,
		"check_x" : player.global_position.x,
		"check_y" : player.global_position.y,
		"check_dir" : Vector2.ZERO,
		"playtime" : total_playtime,
		"last_saved_unix" : int( Time.get_unix_time_from_system() ),
		"region_id" : region_info.region_id,
		"region_name" : region_info.region_name,
		"region_icon" : region_info.region_icon,
	}
	write_to_disc()
## Manual save (e.g. from a pause menu / checkpoint). Plays out as a full
## fade-out/reload-current-scene/fade-in transition, which also resets all
## enemies to alive (SpawnManager.reset_all() clears the dead list before
## the reload, so each enemy's _ready() sees a clean slate).
func save_game() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	_capture_save_data( player )
	SpawnManager.reset_all()
	# TODO: once a character-select scene exists, this is where we'd
	# transition_scene() to it instead of reloading the current scene.
	SceneManager.transition_scene( SceneManager.current_scene_uid, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready
	await setup_player()
	pass
func load_game( slot : int ) -> void:
	# NOTE: current_slot must be updated BEFORE the existence check — the old
	# order checked the previously active slot's file instead of the one
	# actually being loaded.
	current_slot = slot
	if not FileAccess.file_exists( get_file_name( current_slot ) ):
		return
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.READ )
	save_data = JSON.parse_string( save_file.get_line() )
	persistent_data = save_data.get( "persistent_data", {} )
	discovered_areas = save_data.get( "discovered_areas", [] ).duplicate()
	revealed_on_map = discovered_areas.duplicate()
	_session_playtime = 0.0
	var scene_path : String = save_data.get( "scene_path", NEW_GAME_SCENE )
	SpawnManager.reset_all()
	SceneManager.transition_scene( scene_path, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready
	await setup_player()
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	_capture_save_data( player )
	pass
func setup_player() -> void:
	var player : Player = null
	while not player:
		player = get_tree().get_first_node_in_group( "Player" )
		await get_tree().process_frame
	player.max_hp = save_data.get( "max_hp", 6 )
	player.hp = save_data.get( "hp", 6 )
	player.resource_max = save_data.get( "max_resource", player.resource_max )
	player.resource_current = save_data.get( "resource", player.resource_current )
	player.gold = save_data.get( "gold", 0 )
	player.dash = save_data.get( "dash", false )
	player.double_jump = save_data.get( "double_jump", false )
	player.ground_slam = save_data.get( "ground_slam", false )
	player.morph_roll = save_data.get( "morph_roll", false )
	player.unique_abilities = save_data.get( "unique_abilities", {} )
	player.global_position = Vector2(
		save_data.get( "x", 0 ),
		save_data.get( "y", 0 ),
	)
	# The scene reload already triggered PlayerCamera's own reset_smoothing()
	# via SceneManager.new_scene_ready — but that fired BEFORE the teleport
	# above, so it locked in the pre-teleport position as the smoothing
	# baseline and the camera drifts to the checkpoint instead of snapping.
	# Reset again now that the position is final.
	var cam : Camera2D = player.get_viewport().get_camera_2d()
	if cam:
		cam.reset_smoothing()
	_tracking_playtime = true
	# setup_player() is the one thing every real "enter gameplay with an
	# actual player" path (create_new_game_save(), load_game(), save_game(),
	# game_over()) awaits, so this is also the one place that needs to undo
	# title_screen.gd hiding the HUD on the way out of the menu — otherwise
	# starting/loading a game from the title screen would leave the mana/hp/
	# money HUD hidden for the whole session instead of just on the menu.
	PlayerHud.show_hud()
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
	# No scene reload happens on this path, so nothing else resets camera
	# smoothing — without this the camera would drift to the checkpoint
	# after the screen fades back in.
	var cam : Camera2D = player.get_viewport().get_camera_2d()
	if cam:
		cam.reset_smoothing()
	get_tree().paused = false
	await get_tree().process_frame
	await SceneManager.fade_screen( Vector2.ZERO, -fade_pos )
	SceneManager.fade.visible = false
	pass
## Quiet persist — writes current gold/discovered_areas/persistent_data to
## disk without moving the player, transitioning scenes, resetting enemies,
## or touching the "respawn here" position. Use for incidental pickups.
func persist_data() -> void:
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	save_data["gold"] = player.gold
	save_data["discovered_areas"] = discovered_areas.duplicate()
	save_data["persistent_data"] = persistent_data
	_fold_playtime()
	write_to_disc()
	pass
## Reuses setup_player() to return the player to their last save (correcting
## a previous bug where dying in a different scene than the last save left
## the player in the wrong scene), then applies game-over-specific overrides:
## full hp/mp restore, and lost gold.
func game_over() -> void:
	# The boss HP bar only ever hides via Messages.battle_ended, which ESDeath
	# emits once the BOSS actually dies. If the player dies mid-fight instead,
	# nothing ever tells PlayerHud to hide it, so it's left showing a stale HP
	# value (PlayerHud is a persistent autoload — it isn't reset by the level
	# reload below). Uses the _immediate variant, not hide_boss_hp() — the
	# animated version's await gets frozen mid-animation by
	# transition_scene()'s pause a moment from now, leaving the bar stuck
	# looking fully visible instead of actually hiding (see
	# PlayerHud.hide_boss_hp_immediate()'s own comment).
	# Called unconditionally now (not gated on boss_hp.visible) — that read
	# could itself race a hide_boss_hp() animation that's mid-flight for an
	# unrelated reason, and hide_boss_hp_immediate() is a no-op-safe hard
	# cut either way, so there's no upside to checking first.
	PlayerHud.hide_boss_hp_immediate()
	SpawnManager.reset_all()
	# No real save/checkpoint exists yet — save_data was never populated by
	# create_new_game_save()/load_game(), which happens when a level is
	# played directly instead of going through the title screen's New
	# Game/Load. There's no checkpoint to respawn at, so just start over
	# from the same place a brand new game would (NEW_GAME_SCENE/START —
	# same constants create_new_game_save() uses), instead of falling back
	# to SceneManager.current_scene_uid, which is empty just as often as
	# save_data is (it's only ever set by a prior transition_scene() call)
	# and was handing transition_scene() an empty path, crashing on
	# "Resource file not found: res://".
	var scene_path : String = save_data.get( "scene_path", NEW_GAME_SCENE )
	if not save_data.has( "x" ):
		save_data["x"] = NEW_GAME_START.x
	if not save_data.has( "y" ):
		save_data["y"] = NEW_GAME_START.y
	SceneManager.transition_scene( scene_path, "", Vector2.ZERO, "up" )
	await SceneManager.new_scene_ready
	await setup_player()
	var player : Player = get_tree().get_first_node_in_group( "Player" )
	player.hp = player.max_hp
	player.resource_current = player.resource_max
	player.gold = 0
	player.direction = Vector2.ZERO
	player.sprite_2d.modulate = Color(1, 1, 1, 1)
	PlayerHud.show_hud()
	_capture_save_data( player )
	await DeathVignette.reveal()
	pass
func write_to_disc() -> void:
	revealed_on_map = discovered_areas.duplicate()
	save_data["discovered_areas"] = revealed_on_map.duplicate()
	var save_file = FileAccess.open( get_file_name( current_slot ), FileAccess.WRITE )
	save_file.store_line( JSON.stringify( save_data ) )
	pass
func get_file_name( slot : int ) -> String:
	return "user://" + SLOTS[ slot ] + ".sav"
func save_file_exists (slot : int ) -> bool:
	return FileAccess.file_exists( get_file_name( slot ))
## Reads a save slot's metadata straight off disk without touching
## current_slot/save_data, so it's safe to call from menus at any time,
## including while a different game is already loaded in memory.
## Returns an empty Dictionary if the slot has no save file.
func get_slot_info( slot : int ) -> Dictionary:
	if not save_file_exists( slot ):
		return {}
	var file := FileAccess.open( get_file_name( slot ), FileAccess.READ )
	var data = JSON.parse_string( file.get_line() )
	file.close()
	if typeof( data ) != TYPE_DICTIONARY:
		return {}
	return {
		"region_id" : data.get( "region_id", "" ),
		"region_name" : data.get( "region_name", "" ),
		"region_icon" : data.get( "region_icon", "" ),
		"playtime" : data.get( "playtime", 0.0 ),
		"last_saved_unix" : data.get( "last_saved_unix", 0 ),
	}
## Formats seconds as "00S 00M" (hours/minutes, German suffixes).
func format_playtime( seconds : float ) -> String:
	var total_seconds : int = int( seconds )
	@warning_ignore( "integer_division" )
	var hours : int = total_seconds / 3600
	@warning_ignore( "integer_division" )
	var minutes : int = ( total_seconds % 3600 ) / 60
	return "%02dS %02dM" % [ hours, minutes ]
## Formats a unix timestamp as "DD.MM.YYYY HH:MM" for display.
## Accepts float because JSON round-trips all numbers as floats.
func format_last_saved( unix_time : float ) -> String:
	if unix_time <= 0:
		return ""
	var dt : Dictionary = Time.get_datetime_dict_from_unix_time( int( unix_time ) )
	return "%02d.%02d.%04d %02d:%02d" % [ dt.day, dt.month, dt.year, dt.hour, dt.minute ]
## Has the player ever physically visited this area this session? Not what
## the map should read from — use is_area_revealed_on_map() for that.
func is_area_discovered( scene_uid : String ) -> bool:
	return discovered_areas.has( scene_uid )
## What the map should actually check — only true once a save has happened
## since this area was first visited.
func is_area_revealed_on_map( scene_uid : String ) -> bool:
	return revealed_on_map.has( scene_uid )
## Records that a SecretArea (identified by its unique secret_id) has been
## found. Stored inside persistent_data so it rides along with normal
## save/load without needing its own save_data key, and is immediately
## flushed to disk via persist_data() so a find isn't lost on crash/quit.
func register_secret_area( secret_id : String ) -> void:
	var found : Array = persistent_data.get( "secret_areas", [] )
	if not found.has( secret_id ):
		found.append( secret_id )
	persistent_data["secret_areas"] = found
	persist_data()
## Whether a given SecretArea has already been found (per the active save).
func is_secret_area_found( secret_id : String ) -> bool:
	return persistent_data.get( "secret_areas", [] ).has( secret_id )
func get_active_character_scene() -> String:
	var id : String = save_data.get( "character_id", DEFAULT_CHARACTER_ID )
	return CHARACTER_SCENES.get( id, CHARACTER_SCENES[ DEFAULT_CHARACTER_ID ] )
func _on_scene_entered( scene_uid : String ) -> void:
	if discovered_areas.has( scene_uid ):
		return
	else:
		discovered_areas.append( scene_uid )
	pass
## The one persistent_data key builder every persisted per-instance object
## (switches, save points, boss fights, breakable rocks, secret areas, ...)
## should use now — see RegionInfo.persistent_key()'s doc comment for the
## four duplicated, individually-fragile schemes this replaced. Finds the
## current scene's RegionInfo (same lookup _get_current_region_info() below
## already does) and namespaces instance_id under its region_id. Falls back
## to a scene-path-based key with a loud warning if this scene has no
## RegionInfo yet, rather than crashing — still (mostly) works is better
## than taking down the whole scene.
func persistent_key( node : Node, instance_id : String ) -> String:
	var info : RegionInfo = node.get_tree().get_first_node_in_group( "region_info" )
	if not info:
		push_warning( "persistent_key(%s) called with no RegionInfo in the current scene — add one and give it a region_id. Falling back to a scene-path key, which is NOT guaranteed stable across renames/moves." % instance_id )
		return node.get_tree().current_scene.scene_file_path + "/" + instance_id
	return info.persistent_key( instance_id )
## Looks for a RegionInfo node anywhere in the currently loaded scene tree
## (via the "region_info" group) and returns its data in save-ready form.
## Falls back to empty/unknown values if the current scene isn't tagged.
func _get_current_region_info() -> Dictionary:
	var info_node : RegionInfo = get_tree().get_first_node_in_group( "region_info" )
	if info_node:
		return {
			"region_id" : info_node.region_id,
			"region_name" : info_node.region_name,
			"region_icon" : info_node.icon.resource_path if info_node.icon else "",
		}
	return {
		"region_id" : "",
		"region_name" : "",
		"region_icon" : "",
	}
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
