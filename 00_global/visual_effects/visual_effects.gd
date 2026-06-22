extends Node

const DUST_EFFECT = preload("uid://b6jnyetugbf44")
const HIT_PARTICLES = preload("uid://qn6kk66g71u")
const EFFECT_PARTICLES = preload("uid://b27gt6qfdp5yk")


signal camera_shook( strength : float )

var hit_settings_db: Array[HitParticleSettings] = []

# Create dust effects
# Create new instance of a dust effect
func _create_dust_effect( pos : Vector2 ) -> DustEffect:
	var dust : DustEffect = DUST_EFFECT.instantiate()
	add_child( dust )
	dust.global_position = pos
	return dust


# Create Jump Dust
func jump_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.JUMP )
	pass

# Create Land Dust
func land_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.LAND )
	pass

#Hit Dust
func hit_dust( pos : Vector2 ) -> void:
	var dust: DustEffect = _create_dust_effect( pos )
	dust.start( DustEffect.TYPE.HIT )
	pass


func hit_particles( pos: Vector2, dir: Vector2, settings : HitParticleSettings ) -> void:
	var p : HitParticles = HIT_PARTICLES.instantiate()
	add_child( p )
	p.global_position = pos
	p.start( dir, settings )
	pass

func effect_particles( pos: Vector2, dir: Vector2, settings : EffectParticleSettings ) -> void:
	var e : EffectParticles = EFFECT_PARTICLES.instantiate()
	add_child( e )
	e.global_position = pos
	e.start( dir, settings )
	pass

func get_hit_settings(attack: DamageType.DamageElement, target: DamageType.DamageElement) -> HitParticleSettings:
	for s in hit_settings_db:
		if s.attack_element == attack and s.target_element == target:
			return s
	return null
	
func spawn_hit(
	attack: AttackArea,
	target_element: DamageType.DamageElement,
	pos: Vector2,
	dir: Vector2
) -> void:

	var settings := get_hit_settings(attack.dmg_element, target_element)

	if settings == null:
		hit_dust(pos)
		return

	hit_particles(pos, dir, settings)


func camera_shake( strength : float = 1.0 ) -> void:
	camera_shook.emit( strength )
	pass
