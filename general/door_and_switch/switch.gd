@icon( "uid://h778bp0rcsaa" )

extends Node2D
class_name Switch

const DOOR_SWITCH_AUDIO = preload( "uid://b3erby6k8kytv" )

signal activated

var is_open : bool = false

@onready var sprite_2d: Sprite2D = $Sprite2D
## Requires "One Use" checked on this child in the Inspector — a switch
## only ever opens once, and that has to be set there rather than forced
## here in code (this node's _ready() runs after the child's, too late to
## affect its one_use check).
@onready var interaction_trigger : InteractionTrigger = $InteractionTrigger

func _ready() -> void:
	if interaction_trigger.is_used():
		set_open()
	else:
		interaction_trigger.interacted.connect( _on_interacted )
	pass

func _on_interacted( _player : Player ) -> void:
	Audio.play_spatial_sound( DOOR_SWITCH_AUDIO, global_position, false, false, 0.75 )
	activated.emit()
	set_open()
	pass

func set_open() -> void:
	is_open = true
	sprite_2d.flip_h = true
	sprite_2d.modulate = Color.GRAY
	pass
