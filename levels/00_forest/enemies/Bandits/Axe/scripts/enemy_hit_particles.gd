@icon( "uid://de3l2kqneg3hl" )

class_name EnemyHitParticles
extends Marker2D


@export var hit_particles : Array[ HitParticleSettings ]
@export var death_particles : Array[ HitParticleSettings ]
@export var auto_trigger_on_hit : bool = true

var enemy_was_killed : bool = false


func _ready() -> void:
	if owner is Enemy:
		if auto_trigger_on_hit:
			owner.was_hit.connect( _on_hit )
		owner.was_killed.connect( _on_killed )
	else:
		if auto_trigger_on_hit:
			for c in get_parent().get_children():
				if c is DamageArea:
					c.damage_taken.connect( _on_hit )
		pass
	pass
	
func _on_hit(a: AttackArea) -> void:
	var dir := global_position.direction_to(a.global_position)
	dir.x *= -1
	var damage_area := get_parent().get_node_or_null( "DamageArea" )
	VisualEffects.spawn_hit(
		a,
		damage_area.element if damage_area else DamageType.DamageElement.PHYSICAL,
		global_position,
		dir
	)
func trigger_hit(a: AttackArea) -> void:
	_on_hit(a)
	
func trigger_hit_particle(a: AttackArea, index: int) -> void:
	if index < 0 or index >= hit_particles.size():
		push_warning("EnemyHitParticles: index %d out of range (size %d)" % [index, hit_particles.size()])
		return
	var dir := global_position.direction_to(a.global_position)
	dir.x *= -1
	VisualEffects.hit_particles(global_position, dir, hit_particles[index])
	
func _on_killed() -> void:
	enemy_was_killed = true
pass
