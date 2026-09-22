class_name ESBanditAxeAttack
extends EnemyState

@export var attack_range : float = 48
@export var cooldown : float = 3.0
@export var attack_area : AttackArea
@export var move_speed : float = 0
@export var move_speed_curve : Curve



var timer : float = 0
var duration : float = 0
var on_cooldown : bool = false

const AUDIO_WHIRLWIND_AXE = preload("uid://c8ciccywsllt8")


func _ready() -> void:
	# Getting hit mid-swing shouldn't cancel the attack — see
	# EnemyState.interruptible_by_hit / Enemy.on_damage_taken().
	interruptible_by_hit = false


func enter() -> void:

	attack_area.flip( blackboard.dir )
	
	enemy.visuals.play_animation( animation_name if animation_name else "attack" )
	Audio.play_spatial_sound( AUDIO_WHIRLWIND_AXE, enemy.global_position, false, false, 0.5 )
	duration = enemy.visuals.get_animation_length("attack")
	timer = 0
	blackboard.can_decide = false
	on_cooldown = true
	enemy.velocity.x = move_speed * blackboard.dir
	
	pass


func re_enter() -> void:
	# What happens if the state is called again?
	pass


func exit() -> void:
	blackboard.can_decide = true
	
	run_cooldown()
	pass


func physics_update( _delta : float ) -> void:

	timer += _delta
	if timer >= duration:
		blackboard.can_decide = true
	if move_speed_curve:
		var sample : float = move_speed_curve.sample( timer / duration )
		enemy.velocity.x = move_speed * sample * blackboard.dir
	pass


func can_attack() -> bool:
	
	if blackboard.distance_to_target <= attack_range and not on_cooldown:
		return true
	return false


func run_cooldown() -> void:
	await get_tree().create_timer( cooldown ).timeout
	on_cooldown = false
	pass
