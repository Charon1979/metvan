@tool
@icon( "uid://55elxn174d5" )

class_name Breakable extends Node2D

signal destroyed
signal damage_taken

@export var hp : float = 3
@export var fixed_hit_count : bool = false

@export_category( "Particles" )
@export var emission_offset : Vector2 = Vector2.ZERO
@export var hit_particles : Array[ HitParticleSettings ]
@export var destroy_particles : Array [ HitParticleSettings ]

@export_category( "Audio" )
@export var hit_audio : AudioStream = preload( "uid://vdkyaacynaa" )
@export var destroy_audio : AudioStream = preload( "uid://0c0prwmpduhj" )


@onready var damage_area: DamageArea = $DamageArea

## Set the instant `destroyed` fires, so a hit landing after that point (the
## collision body is freed by then, but the DamageArea itself isn't — see
## clear_collision()'s own comment) can't push hp further negative and fire
## `destroyed` all over again. Without this, anything still hittable after
## "destruction" kept re-emitting destroyed on every subsequent hit forever
## — harmless to Breakable itself, but very confusing for a listener like
## OneShotBreakable that counts hits off this signal.
var _is_destroyed : bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for c in get_children():
		if c is DamageArea:
			c.damage_taken.connect( _on_damage_taken )
	pass

func _on_damage_taken( attack_area : AttackArea ) -> void:
	if _is_destroyed:
		return
	if fixed_hit_count:
		hp -= 1
	else:
		hp -= attack_area.damage
	
	var pos: Vector2 = global_position + emission_offset
	var dir : Vector2 = Vector2( 1, -1 )
	if attack_area.global_position.x > global_position.x:
		dir.x *= -1
		
	if hp > 0:
		damage_taken.emit()
		Audio.play_spatial_sound( hit_audio, pos, false, true, 0.75 )
		for p in hit_particles:
			VisualEffects.hit_particles( pos, dir, p )
	else:
		_is_destroyed = true
		destroyed.emit()
		Audio.play_spatial_sound( destroy_audio, pos, false, true, 1 )
		clear_collision()
		for p in destroy_particles:
			VisualEffects.hit_particles( pos, dir, p )

		
	pass

func _get_configuration_warnings() -> PackedStringArray:
	if _check_for_damage_area() == false:
		return ["Requires a DamageArea Node!"]
	else:
		return[]
		
func _check_for_damage_area() -> bool:
	for c in get_children():
		if c is DamageArea:
			return true
	return false

func clear_collision() -> void:
	# Was calling queue_free() on `self` (the Breakable) instead of `c` (the
	# StaticBody2D child) — the collision body itself was never actually
	# freed, and this Breakable node got queued for deletion instead (once
	# per matching child), which could cut off anything still relying on it
	# after destruction (e.g. destroy particles/animations on this node).
	for c in get_children():
		if c is StaticBody2D:
			c.queue_free()
	pass
