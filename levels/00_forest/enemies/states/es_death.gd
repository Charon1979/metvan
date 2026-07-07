class_name ESDeath
extends EnemyState
# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard

@export var knockback_strength : float = 100
@export var knockback_duration : float = 0.25

@export_group("Death Audio")
@export var death_audio_default : AudioStream
@export var death_audio_physical : AudioStream
@export var death_audio_fire : AudioStream
@export var death_audio_air : AudioStream
@export var death_audio_water : AudioStream
@export var death_audio_earth : AudioStream
@export var death_audio_shadow : AudioStream
@export var death_audio_blood : AudioStream

var vel_x : float = 0
var duration : float = 0
var timer : float = 0

var death_anims := {
	DamageType.DamageElement.FIRE: "death_fire",
	DamageType.DamageElement.AIR: "death_air",
	DamageType.DamageElement.WATER: "death_water",
	DamageType.DamageElement.EARTH: "death_earth",
	DamageType.DamageElement.PHYSICAL: "death",
	DamageType.DamageElement.SHADOW: "death_shadow",
	DamageType.DamageElement.BLOOD: "death_blood",
}

var death_audio_by_element : Dictionary

func _ready() -> void:
	death_audio_by_element = {
		DamageType.DamageElement.FIRE: death_audio_fire,
		DamageType.DamageElement.AIR: death_audio_air,
		DamageType.DamageElement.WATER: death_audio_water,
		DamageType.DamageElement.EARTH: death_audio_earth,
		DamageType.DamageElement.PHYSICAL: death_audio_physical,
		DamageType.DamageElement.SHADOW: death_audio_shadow,
		DamageType.DamageElement.BLOOD: death_audio_blood,
	}

func enter() -> void:
	enemy.attack_area.activate( false )
	enemy.hazard_area.queue_free()
	enemy.attack_area.queue_free()
	enemy.damage_area.queue_free()
	
	SpawnManager.mark_dead( enemy.spawn_id, blackboard.damage_element, blackboard.dir, enemy.get_death_visual_data() )
	var anim_name = death_anims.get(blackboard.damage_element, "death")

	enemy.visuals.play_animation(anim_name)
	enemy.vfx.emit_vfx_part(anim_name)

	var audio : AudioStream = death_audio_by_element.get( blackboard.damage_element, death_audio_default )
	if not audio:
		audio = death_audio_default
	if audio:
		Audio.play_spatial_sound(audio, enemy.global_position)

	duration = enemy.visuals.get_animation_length( anim_name ) if enemy.visuals.animation_player else 2.0
	timer = 0.0
	_calc_velocity(blackboard.damage_source)
	blackboard.damage_source = null
	blackboard.can_decide = false
func re_enter() -> void:
	pass
func exit() -> void:
	pass
func physics_update(delta: float) -> void:
	timer += delta
	if timer >= knockback_duration:
		enemy.velocity.x = 0.0
	else:
		var t : float = 1.0 - (timer / knockback_duration)
		enemy.velocity.x = vel_x * t
	if timer >= duration:
		blackboard.can_decide = true
	if timer >= 0.6:
		enemy.vfx.stop_vfx_part()
func _calc_velocity(a: AttackArea) -> void:
	vel_x = 1
	if a and a.global_position.x > enemy.global_position.x:
		vel_x = -1
	vel_x *= knockback_strength
