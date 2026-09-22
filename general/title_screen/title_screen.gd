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

@onready var load_slot_buttons : Array[Button] = [ load_slot_01, load_slot_02, load_slot_03 ]
@onready var load_slot_icons : Array[TextureRect] = [ %LoadSlot01Icon, %LoadSlot02Icon, %LoadSlot03Icon ]
@onready var load_slot_titles : Array[Label] = [ %LoadSlot01Title, %LoadSlot02Title, %LoadSlot03Title ]
@onready var load_slot_info_labels : Array[Label] = [ %LoadSlot01Info, %LoadSlot02Info, %LoadSlot03Info ]
@onready var load_slot_empty_labels : Array[Label] = [ %LoadSlot01Empty, %LoadSlot02Empty, %LoadSlot03Empty ]

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var ui_slider: HSlider = %UISlider
@onready var cancel_settings: Button = %CancelSettings

var player_position : Vector2


#animation player for animated logo

#endregion ///

func _ready() -> void:
	# PlayerHud is a persistent autoload, so whatever state it was left in
	# by the last level (mana/hp/money HUD shown, possibly a boss HP bar
	# too) otherwise carries straight over into the title screen. This
	# scene's _ready() runs both on a fresh game launch and on "back to
	# title" from in-game, so hiding here covers both instead of needing a
	# separate hook on Messages.back_to_title_screen. setup_player() (in
	# save_manager.gd) is what shows the HUD again once a real game
	# actually starts/loads.
	PlayerHud.hide_hud()
	PlayerHud.hide_boss_hp_immediate()

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

	if SaveManager.save_file_exists( 0 ):
		new_slot_01.text = "Spiel 01 überschreiben"
	if SaveManager.save_file_exists( 1 ):
		new_slot_02.text = "Spiel 02 überschreiben"
	if SaveManager.save_file_exists( 2 ):
		new_slot_03.text = "Spiel 03 überschreiben"
	pass


func show_settings() -> void:
	main_menue.visible = false
	new_game_menue.visible = false
	load_game_menue.visible = false
	settings.visible = true
	cancel_settings.grab_focus()
	pass


func show_load_game_menue() -> void:
	main_menue.visible = false
	new_game_menue.visible = false
	load_game_menue.visible = true
	settings.visible = false
	cancel_load.grab_focus()

	_refresh_load_slots()
	pass


## Updates each "load game" slot button's enabled state and contents.
## Title reads "01. Regionname"; info line reads "00S 00M    DD.MM.YYYY HH:MM".
func _refresh_load_slots() -> void:
	for i in load_slot_buttons.size():
		var info : Dictionary = SaveManager.get_slot_info( i )
		load_slot_buttons[i].disabled = info.is_empty()
		load_slot_empty_labels[i].visible = info.is_empty()
		if info.is_empty():
			load_slot_titles[i].visible = false
			load_slot_icons[i].visible = false
			load_slot_info_labels[i].visible = false
			continue
		load_slot_titles[i].visible = true
		load_slot_info_labels[i].visible = true
		var region_name : String = info.region_name if info.region_name != "" else "Unbekannt"
		load_slot_titles[i].text = "%02d. %s" % [ i + 1, region_name ]
		load_slot_titles[i].modulate = Color( 1, 1, 1, 1 )
		_apply_slot_display( load_slot_icons[i], load_slot_info_labels[i], info )
	pass


## Fills one load slot's icon and info label from a get_slot_info() Dictionary.
func _apply_slot_display( icon : TextureRect, info_label : Label, info : Dictionary ) -> void:
	icon.visible = info.region_icon != ""
	if icon.visible:
		icon.texture = load( info.region_icon )

	info_label.text = "%s    %s" % [
		SaveManager.format_playtime( info.playtime ),
		SaveManager.format_last_saved( info.last_saved_unix ),
	]
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
