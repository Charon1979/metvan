@tool
extends Node2D

# ─────────────────────────────
# Inspector options
# ─────────────────────────────

@export_group("Visual")

@export var texture: Texture2D:
	set(value):
		texture = value
		if is_inside_tree():
			$Sprite2D.texture = value

@export var disable_sprite_after_trigger := false
@export var z_index_after_trigger := -3


@export_group("Trigger Area")

@export var area_offset := Vector2.ZERO:
	set(value):
		area_offset = value
		if is_inside_tree():
			$Area2D.position = value

@export var area_size := Vector2(64, 64):
	set(value):
		area_size = value
		if is_inside_tree():
			$Area2D/CollisionShape2D.shape.size = value


@export_group("Audio")

@export var sound: AudioStream


# ─────────────────────────────
# Internal state
# ─────────────────────────────

var triggered := false
@onready var secret_area: Node2D = $"."
@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D
@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	sprite.texture = texture
	audio.stream = sound

	area.position = area_offset
	collision.shape.size = area_size


func _on_area_2d_body_entered(body: Node2D) -> void:
	if triggered:
		return

	if not body.is_in_group("Player"):
		return

	triggered = true

	if audio.stream:
		audio.play()

	secret_area.z_index = z_index_after_trigger
	

	if disable_sprite_after_trigger:
		sprite.visible = false

	area.monitoring = false
	collision.disabled = true

	area.disconnect(
		"body_entered",
		Callable(self, "_on_area_2d_body_entered")
	)
