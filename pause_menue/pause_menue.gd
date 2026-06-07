extends CanvasLayer
class_name PauseMenu

#region /// On ready variables
@onready var pause_screen: Control = %PauseScreen
@onready var system: Control = %System
@onready var map: Control = %Map
@onready var skills: Control = %Skills


@onready var skill_button: Button = %SkillButton
@onready var system_button: Button = %SystemButton
@onready var map_button: Button = %MapButton
@onready var inventory_button: Button = %InventoryButton
@onready var character_button: Button = %CharacterButton

@onready var quit: Button = %Quit

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
#endregion

var player_position : Vector2



func _ready() -> void:
	show_pause_screen()
	Messages.game_paused.emit()
	skill_button.pressed.connect( show_skill_menu )
	system_button.pressed.connect( show_system_menu )
	map_button.pressed.connect( show_pause_screen )
	inventory_button.pressed.connect( show_inventory_menu )
	character_button.pressed.connect( show_character_menu )
	quit.pressed.connect( on_back_to_title_pressed )
	Audio.setup_button_audio( self )
	setup_system_menu()
	var player : Node2D = get_tree().get_first_node_in_group( "Player ")
	if player:
		player_position = player.global_position
	pass

func _unhandled_input( event: InputEvent ) -> void:
	if event.is_action_pressed( "pause" ):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		Messages.game_unpaused.emit()
		queue_free()
	if pause_screen.visible == true:
		if map_button.has_focus():
			show_pause_screen()
		if character_button.has_focus():
			show_character_menu()
		if skill_button.has_focus():
			show_skill_menu()
		if inventory_button.has_focus():
			show_inventory_menu()
		if system_button.has_focus():
			show_system_menu()
		pass
	pass

func show_pause_screen() -> void:
	system.visible = false
	map.visible = true
	skills.visible = false
	map_button.grab_focus()
	pass

func show_system_menu() -> void:
	system.visible = true
	map.visible = false
	skills.visible = false
	
	pass

func show_inventory_menu() -> void:
	system.visible = false
	map.visible = false
	skills.visible = false
	pass

func show_character_menu() -> void:
	system.visible = false
	map.visible = false
	skills.visible = false
	pass

func show_skill_menu() -> void:
	system.visible = false
	map.visible = false
	skills.visible = true
	pass

func setup_system_menu() -> void:

	music_slider.value = AudioServer.get_bus_volume_linear( 2 )
	sfx_slider.value = AudioServer.get_bus_volume_linear( 3 )
	ui_slider.value = AudioServer.get_bus_volume_linear( 4 )
	
	music_slider.value_changed.connect( _on_music_slider_changed )
	sfx_slider.value_changed.connect( _on_sfx_slider_changed )
	ui_slider.value_changed.connect( _on_ui_slider_changed )
	
	pass

func on_back_to_title_pressed() -> void:
	SceneManager.transition_scene( "uid://csi1wy7idb0ww", "", Vector2.ZERO, "up" )
	get_tree().paused = false
	Messages.back_to_title_screen.emit()
	queue_free()
	pass

func _on_music_slider_changed( v : float ) -> void:
	AudioServer.set_bus_volume_linear( 2, v )
	SaveManager.save_configuration()
	pass


func _on_sfx_slider_changed( v : float ) -> void:
	AudioServer.set_bus_volume_linear( 3, v )
	Audio.play_spatial_sound( Audio.ui_focus_audio, player_position )
	SaveManager.save_configuration()
	pass


func _on_ui_slider_changed( v : float ) -> void:
	AudioServer.set_bus_volume_linear( 4, v )
	Audio.ui_focus_change()
	SaveManager.save_configuration()
	pass
