@icon( "uid://dt7dhfwvgbk6t" )
extends Node
class_name MusicAutoTrigger

@export var track : AudioStream
@export var reverb : Audio.REVERB_TYPE = Audio.REVERB_TYPE.NONE



func _ready() -> void:
	Audio.play_music( track )
	Audio.set_reverb( reverb )
	pass
