@tool
class_name EnemyVFX
extends Node2D

@onready var vfx_sprite: Node2D = $VFXSprite
@onready var sprite: Sprite2D = $VFXSprite/Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D
@onready var light: PointLight2D = $VFXSprite/PointLight2D

var facing_right := true

func _ready() -> void:
	vfx_sprite.visible = false
	sprite.visible = false
	gpu_particles.visible = false
	light.visible = false

func apply_visuals() -> void:
	pass


func set_facing_direction(dir: float) -> void:
	if dir == 0:
		return
	facing_right = dir > 0
	_apply_facing()


func _apply_facing() -> void:
	scale.x = 1 if facing_right else -1


func emit_vfx_part(element: String) -> void:
	gpu_particles.emitting = true
	pass

func stop_vfx_part() -> void:
	gpu_particles.emitting = false
	pass

func play_vfx(element: String) -> void:
	pass

func stop_vfx() -> void:
	animation_player.stop()
	light.visible = false
	vfx_sprite.visible = false
	sprite.visible = false
	light.visible = false
	gpu_particles.emitting = false
		
func restart_vfx(element : String ) -> void:
	if animation_player:
		animation_player.seek(0)
		play_vfx( element )
	pass
