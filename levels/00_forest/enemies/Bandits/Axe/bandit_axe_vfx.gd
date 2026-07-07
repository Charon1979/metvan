@tool

class_name BanditAxeVFX
extends EnemyVFX

@export var vfx_data: BanditAxeVFXData = null


func play_vfx(element: String) -> void:

	if vfx_data == null:

		push_warning("BanditAxeVFX: vfx_data is not set.")
		return

	var texture: Texture2D = vfx_data.get(element)
	var config: VFXParticleConfig = vfx_data.get(element + "_part")

	if texture == null or config == null:
		push_warning("BanditAxeVFX: no data found for element '%s'." % element)
		return

	sprite.texture = texture
	vfx_sprite.visible = true
	sprite.visible = true
	light.visible = true
	gpu_particles.visible = true
	

	# Core
	gpu_particles.process_material = config.process_material
	gpu_particles.amount = config.amount
	gpu_particles.lifetime = config.lifetime
	gpu_particles.one_shot = config.one_shot
	gpu_particles.explosiveness = config.explosiveness
	gpu_particles.randomness = config.randomness
	gpu_particles.speed_scale = config.speed_scale
	gpu_particles.trail_enabled = config.trail_enabled
	# Timing
	gpu_particles.preprocess = config.preprocess
	

	# Visibility
	gpu_particles.visibility_rect = config.visibility_aabb
	gpu_particles.local_coords = config.local_coords

	# Texture
	gpu_particles.texture = config.texture

	gpu_particles.emitting = true

	if animation_player.has_animation(element):
		animation_player.play(element)

func apply_visuals() -> void:
	# Override here if BanditAxe needs custom visual setup beyond facing
	pass
