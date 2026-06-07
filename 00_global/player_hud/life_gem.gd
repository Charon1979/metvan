class_name LifeGem extends Control

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: Sprite2D = $Glow



var value : int = 2 :
	set( _value ): 
		value = _value
		update_sprite()


func update_sprite() -> void:
	sprite.frame = value
	if value < 2:
		glow.visible = false
	else:
		glow.visible = true
