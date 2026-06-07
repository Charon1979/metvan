class_name EffectParticles extends GPUParticles2D



func start( dir : Vector2, settings : EffectParticleSettings ) -> void:
	if settings:
		amount = settings.count
		modulate = settings.color
		texture = settings.texture
		process_material = settings.process_material
		lifetime = settings.lifetime
		one_shot = settings.one_shot
		preprocess = settings.preprocess
		speed_scale = settings.speed_scale
		explosiveness = settings.explosiveness
		randomness = settings.randomness
		trail_enabled = settings.trail_enabled
		
	var particle_material := process_material as ParticleProcessMaterial

	if particle_material:
		particle_material.direction = Vector3(dir.x, dir.y, 0)
	
	emitting = true
	
	pass
