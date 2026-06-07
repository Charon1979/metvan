class_name InputHints extends Control

@onready var label: Label = $CenterContainer/Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var center_container_2: CenterContainer = $CenterContainer2


func _ready() -> void:

	visible = false
	Messages.input_hint_changed.connect( _on_hint_changed )
	
	pass


func _on_hint_changed( _hint : String ) -> void:
	if _hint == "":
		animation_player.play( "non_interact" )
		await animation_player.animation_finished
		visible = false
		reset()

	else:
		modulate = Color(1,1,1,0)
		label.text = _hint
		visible = true
		animation_player.play( "interact" )
		await animation_player.animation_finished
		animation_player.play( "arrow" )
		
		
		
	pass

func reset() -> void:
	modulate = Color(1,1,1,1)
