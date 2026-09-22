@tool
class_name OgreVisuals
extends EnemyVisuals

@export var particle_scene: PackedScene
@onready var particles_anchor: GPUParticles2D = $Rock_debries_v1
@onready var sprite : Sprite2D = $Sprite2D


func spawn_particles() -> void:
	var p = particle_scene.instantiate()
	add_child(p)
	p.position = particles_anchor.position
	p.lifetime = 4
	p.speed_scale = 2
	p.restart()
	await p.finished
	p.queue_free()
