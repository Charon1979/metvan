class_name InputHints extends Control

@onready var label: Label = $CenterContainer/Label
@onready var center_container: CenterContainer = $CenterContainer
@onready var center_container_2: CenterContainer = $CenterContainer2
@onready var hint_icon_root: Node2D = $CenterContainer2/HintIconRoot
@onready var display: Label = %Display
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var target : Node2D
@export var offset : Vector2 = Vector2( 0, -32 )
@export var anim_duration : float = 0.5

var _hint_tween : Tween
var _hint_visible : bool = false

func _ready() -> void:
	visible = true

	label.visible = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	display.visible = false
	display.text = ""

	center_container.visible = false
	center_container_2.visible = false
	center_container.modulate = Color( 1, 1, 1, 0 )
	center_container.scale = Vector2.ZERO
	hint_icon_root.scale = Vector2.ZERO
	hint_icon_root.modulate = Color( 1, 1, 1, 0 )

	Messages.input_hint_changed.connect( _on_hint_changed )
	Messages.display_text.connect( _on_text_displayed )
	pass

func _process( _delta : float ) -> void:
	if target:
		global_position = target.global_position + offset - size / 2.0

	# CenterContainer2 can't size around a Node2D child, so keep the icon
	# pair manually synced to its center each frame.
	hint_icon_root.position = center_container_2.position + center_container_2.size / 2.0

func _on_hint_changed( hint : String, instant : bool ) -> void:
	if hint == "":
		if instant:
			_hide_hint_instant()
		else:
			await _hide_hint()
	else:
		label.text = hint
		label.visible = true
		await _show_hint()
	pass

func _on_text_displayed( text : String, instant : bool ) -> void:
	if text == "":
		display.visible = false
		display.text = ""
		return

	if not instant and _hint_tween and _hint_tween.is_running():
		await _hint_tween.finished

	display.text = text
	display.visible = true
	pass

func _update_pivot() -> void:
	center_container.pivot_offset = center_container.size / 2.0

func _show_hint() -> void:
	if _hint_tween and _hint_tween.is_running():
		_hint_tween.kill()

	animation_player.stop()

	center_container.visible = true
	center_container_2.visible = true

	await get_tree().process_frame
	await get_tree().process_frame
	_update_pivot()

	center_container.scale = Vector2.ZERO
	center_container.modulate = Color( 1, 1, 1, 0 )
	hint_icon_root.scale = Vector2.ZERO
	hint_icon_root.modulate = Color( 1, 1, 1, 0 )

	_hint_tween = create_tween()
	_hint_tween.set_parallel( true )
	_hint_tween.tween_property( center_container, "scale", Vector2.ONE, anim_duration )
	_hint_tween.tween_property( center_container, "modulate:a", 1.0, anim_duration )
	_hint_tween.tween_property( hint_icon_root, "scale", Vector2.ONE, anim_duration )
	_hint_tween.tween_property( hint_icon_root, "modulate:a", 1.0, anim_duration )

	_hint_visible = true
	await _hint_tween.finished

	animation_player.play( "arrow" )
	pass

func _hide_hint() -> void:
	if not _hint_visible:
		return
	if _hint_tween and _hint_tween.is_running():
		_hint_tween.kill()

	animation_player.stop()
	_update_pivot()

	_hint_tween = create_tween()
	_hint_tween.set_parallel( true )
	_hint_tween.tween_property( center_container, "scale", Vector2.ZERO, anim_duration )
	_hint_tween.tween_property( center_container, "modulate:a", 0.0, anim_duration )
	_hint_tween.tween_property( hint_icon_root, "scale", Vector2.ZERO, anim_duration )
	_hint_tween.tween_property( hint_icon_root, "modulate:a", 0.0, anim_duration )

	await _hint_tween.finished

	center_container.visible = false
	center_container_2.visible = false
	_hint_visible = false
	pass

func _hide_hint_instant() -> void:
	if _hint_tween and _hint_tween.is_running():
		_hint_tween.kill()

	animation_player.stop()

	center_container.visible = false
	center_container_2.visible = false
	center_container.scale = Vector2.ZERO
	center_container.modulate = Color( 1, 1, 1, 0 )
	hint_icon_root.scale = Vector2.ZERO
	hint_icon_root.modulate = Color( 1, 1, 1, 0 )
	_hint_visible = false
	pass
