class_name DeathVignetteController
extends Node2D

const MUSIC_BUS_INDEX := 2

@export var fade_black_duration : float = 1.0
@export var hold_duration : float = 5.0
@export var fade_reveal_duration : float = 1.0
@export var cover_size : float = 4000.0  # world units — large enough to cover any camera zoom

@export_category("Death Jingle")
@export var death_jingle : AudioStream
@export var jingle_bus : String = "SFX"  # kept off the Music bus so it isn't muted by the level-music fade

var overlay : Sprite2D
var camera : Camera2D
var follow_target : Node2D
var music_volume_before_fade : float = 1.0
var jingle_player : AudioStreamPlayer

func _ready() -> void:
	visible = false
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(0, 0, 0, 1))
	var tex := ImageTexture.create_from_image(img)
	overlay = Sprite2D.new()
	overlay.texture = tex
	overlay.centered = true
	overlay.z_index = 100
	overlay.z_as_relative = false
	overlay.scale = Vector2(cover_size, cover_size)
	add_child(overlay)

	jingle_player = AudioStreamPlayer.new()
	jingle_player.bus = jingle_bus
	add_child(jingle_player)

## Phase 1+2: fades to black and fades music out simultaneously, then holds
## fully black for hold_duration. Awaiting this guarantees the screen is
## fully black and stays that way until you call reveal().
func fade_to_black_and_hold( target : Node2D ) -> void:
	follow_target = target
	camera = get_viewport().get_camera_2d()
	visible = true
	overlay.modulate.a = 0.0
	if follow_target:
		follow_target.z_index = 200
		follow_target.z_as_relative = false
	music_volume_before_fade = AudioServer.get_bus_volume_linear(MUSIC_BUS_INDEX)

	if death_jingle:
		jingle_player.stream = death_jingle
		jingle_player.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property( overlay, "modulate:a", 1.0, fade_black_duration )
	tween.tween_method( _set_music_volume, music_volume_before_fade, 0.0, fade_black_duration )
	await tween.finished
	await get_tree().create_timer( hold_duration ).timeout

## Phase 3: fades music back in and fades the black overlay out simultaneously,
## then resets target z-index. Stops the death jingle if it's still playing.
func reveal() -> void:
	if jingle_player.playing:
		jingle_player.stop()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property( overlay, "modulate:a", 0.0, fade_reveal_duration )
	tween.tween_method( _set_music_volume, 0.0, music_volume_before_fade, fade_reveal_duration )
	await tween.finished
	visible = false
	if follow_target:
		follow_target.z_index = 0
		follow_target.z_as_relative = true
	follow_target = null

func _set_music_volume( vol : float ) -> void:
	AudioServer.set_bus_volume_linear( MUSIC_BUS_INDEX, vol )

func _process( _delta : float ) -> void:
	if visible:
		camera = get_viewport().get_camera_2d()
		if camera:
			global_position = camera.get_screen_center_position()
