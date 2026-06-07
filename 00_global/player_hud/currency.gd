extends Control

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $Label
@onready var timer: Timer = $Timer

var current_gold : int = 0
var is_playing : bool = false
var pause = false



func _ready() -> void:
	Messages.game_paused.connect( _on_game_paused )
	Messages.game_unpaused.connect( _on_game_unpaused )
	current_gold = SaveManager.save_data.get("gold", 0)
	Messages.player_gold_changed.connect( update_gold )
	sprite.visible = false
	label.visible = false
	_on_gold_chaged()
	label.text = str(current_gold)
	pass

func update_gold(value: int) -> void:
	current_gold = value
	label.text = str(current_gold)
	_on_gold_chaged()
	SaveManager.save_data["gold"] = current_gold
	SaveManager.write_to_disc()

func _on_gold_chaged() -> void:
	sprite.visible = true
	label.visible = true
	if is_playing == false:
		animation_player.play("shine")
		is_playing = true
	label.text = str( current_gold )
	timer.start(2)
	pass


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "shine":
		is_playing = false
	pass


func _on_timer_timeout() -> void:
	sprite.visible = false
	label.visible = false
	is_playing = false
	animation_player.stop()
	pass

func _on_game_paused() -> void:

	sprite.visible = true
	label.visible = true
	animation_player.play("shine_2")
	label.text = str( current_gold )

func _on_game_unpaused() -> void:

	sprite.visible = false
	label.visible = false
	animation_player.stop()
