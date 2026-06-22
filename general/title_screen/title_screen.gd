extends CanvasLayer

#region /// on ready variables
@onready var main_menue: VBoxContainer = %MainMenue
@onready var new_game_menue: VBoxContainer = %NewGameMenue
@onready var load_game_menue: VBoxContainer = %LoadGameMenue
@onready var settings: VBoxContainer = %Settings

@onready var new_game_button: Button = %NewGameButton
@onready var load_game_button: Button = %LoadGameButton
@onready var quit_game_button: Button = %QuitGameButton
@onready var settings_button: Button = %SettingsButton


@onready var new_slot_01: Button = %NewSlot01
@onready var new_slot_02: Button = %NewSlot02
@onready var new_slot_03: Button = %NewSlot03
@onready var cancel_new_game: Button = %CancelNewGame

@onready var load_slot_01: Button = %LoadSlot01
@onready var load_slot_02: Button = %LoadSlot02
@onready var load_slot_03: Button = %LoadSlot03
@onready var cancel_load: Button = %CancelLoad

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var cancel_settings: Button = %CancelSettings

var player_position : Vector2


#animation player for animated logo

#endregion ///

func _ready() -> void:
	new_game_button.pressed.connect( show_new_game_menue )
	load_game_button.pressed.connect( show_load_game_menue )
	quit_game_button.pressed.connect( on_game_quit )
	cancel_new_game.pressed.connect( show_main_menue )
	cancel_load.pressed.connect( show_main_menue )
	settings_button.pressed.connect( show_settings )
	cancel_settings.pressed.connect( show_main_menue )
	
	new_slot_01.pressed.connect( _on_new_game_pressed.bind( 0 ) )
	new_slot_02.pressed.connect( _on_new_game_pressed.bind( 1 ) )
	new_slot_03.pressed.connect( _on_new_game_pressed.bind( 2 ) )
	
	load_slot_01.pressed.connect( _on_load_game_pressed.bind( 0 ) )
	load_slot_02.pressed.connect( _on_load_game_pressed.bind( 1 ) )
	load_slot_03.pressed.connect( _on_load_game_pressed.bind( 2 ) )
	
	
	setup_settings_menu()
	show_main_menue()
	
	Audio.setup_button_audio( self )
	

	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed( "ui_cancel" ):
		if main_menue.visible == false:
			show_main_menue()


func show_main_menue() -> void:
	main_menue.visible = true
	new_game_menue.visible = false
	load_game_menue.visible = false
	settings.visible = false
	load_game_button.grab_focus()
	

func show_new_game_menue() -> void:
	main_menue.visible = false
	new_game_menue.visible = true
	load_game_menue.visible = false
	settings.visible = false
	cancel_new_game.grab_focus()
	
func show_settings() -> void:
	main_menue.visible = false
	new_game_menue.visible = false
	load_game_menue.visible = false
	settings.visible = true
	cancel_new_game.grab_focus()
				
	
	if SaveManager.save_file_exists ( 0 ):
		new_slot_01.text = "Spiel 01 überschreiben"
		
	if SaveManager.save_file_exists ( 1 ):
		new_slot_02.text = "Spiel 02 überschreiben"
		
	if SaveManager.save_file_exists ( 2 ):
		new_slot_03.text = "Spiel 03 überschreiben"
	pass

func show_load_game_menue() -> void:
	main_menue.visible = false
	new_game_menue.visible = false
	load_game_menue.visible = true
	settings.visible = false
	cancel_load.grab_focus()
	
	load_slot_01.disabled = not SaveManager.save_file_exists ( 0 )
	load_slot_01.disabled = not SaveManager.save_file_exists ( 1 )
	load_slot_01.disabled = not SaveManager.save_file_exists ( 2 )
	pass
	
func setup_settings_menu() -> void:

	music_slider.value = AudioServer.get_bus_volume_linear( 2 )
	sfx_slider.value = AudioServer.get_bus_volume_linear( 3 )
	ui_slider.value = AudioServer.get_bus_volume_linear( 4 )
	
	music_slider.value_changed.connect( _on_music_slider_changed )
	sfx_slider.value_changed.connect( _on_sfx_slider_changed )
	ui_slider.value_changed.connect( _on_ui_slider_changed )
	
	pass

func _on_new_game_pressed( slot : int ) -> void:
	SaveManager.create_new_game_save( slot )
	
	pass

func _on_load_game_pressed( slot : int ) -> void:
	SaveManager.load_game( slot )
	
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


func on_game_quit() -> void:
	get_tree().quit()
