extends CanvasLayer

#region /// on ready variables
@onready var main_menue: VBoxContainer = %MainMenue
@onready var new_game_menue: VBoxContainer = %NewGameMenue
@onready var load_game_menue: VBoxContainer = %LoadGameMenue

@onready var new_game_button: Button = %NewGameButton
@onready var load_game_button: Button = %LoadGameButton
@onready var quit_game_button: Button = %QuitGameButton

@onready var new_slot_01: Button = %NewSlot01
@onready var new_slot_02: Button = %NewSlot02
@onready var new_slot_03: Button = %NewSlot03
@onready var cancel_new_game: Button = %CancelNewGame

@onready var load_slot_01: Button = %LoadSlot01
@onready var load_slot_02: Button = %LoadSlot02
@onready var load_slot_03: Button = %LoadSlot03
@onready var cancel_load: Button = %CancelLoad



#animation player for animated logo

#endregion ///

func _ready() -> void:
	new_game_button.pressed.connect( show_new_game_menue )
	load_game_button.pressed.connect( show_load_game_menue )
	quit_game_button.pressed.connect( on_game_quit )
	cancel_new_game.pressed.connect( show_main_menue )
	cancel_load.pressed.connect( show_main_menue )
	
	new_slot_01.pressed.connect( _on_new_game_pressed.bind( 0 ) )
	new_slot_02.pressed.connect( _on_new_game_pressed.bind( 1 ) )
	new_slot_03.pressed.connect( _on_new_game_pressed.bind( 2 ) )
	
	load_slot_01.pressed.connect( _on_load_game_pressed.bind( 0 ) )
	load_slot_02.pressed.connect( _on_load_game_pressed.bind( 1 ) )
	load_slot_03.pressed.connect( _on_load_game_pressed.bind( 2 ) )
	
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
	load_game_button.grab_focus()
	

func show_new_game_menue() -> void:
	main_menue.visible = false
	new_game_menue.visible = true
	load_game_menue.visible = false
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
	
	cancel_load.grab_focus()
	
	load_slot_01.disabled = not SaveManager.save_file_exists ( 0 )
	load_slot_01.disabled = not SaveManager.save_file_exists ( 1 )
	load_slot_01.disabled = not SaveManager.save_file_exists ( 2 )
	pass
	
func _on_new_game_pressed( slot : int ) -> void:
	SaveManager.create_new_game_save( slot )
	
	pass

func _on_load_game_pressed( slot : int ) -> void:
	SaveManager.load_game( slot )
	
	pass

func on_game_quit() -> void:
	get_tree().quit()
