@icon( "uid://cltev4ia8x75q" )

extends RigidBody2D
class_name Gold

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@export var value : int = 1


func _ready() -> void:
	var frame_count = animated_sprite_2d.sprite_frames.get_frame_count(animated_sprite_2d.animation)
	animated_sprite_2d.frame = randi_range(0, frame_count)
	if value == 1:
		mass = 0.25
		animated_sprite_2d.play("coin")
	elif value == 10:
		mass = 0.35
		animated_sprite_2d.play("red_gem")
	elif value == 20:
		mass = 0.5
		animated_sprite_2d.play("blue_gem")
	elif value == 50:
		mass = 0.5
		animated_sprite_2d.play("green_gem")
	elif value == 100:
		mass = 0.5
		animated_sprite_2d.play("diamond")


func _on_area_2d_body_entered(_body: Player) -> void:
	_body.gold += value
	queue_free()
	pass
