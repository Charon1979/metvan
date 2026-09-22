class_name ESBowBanditAttack
extends EnemyState

# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard

@export var attack_range : float = 160.0
@export var cooldown : float = 2.0
@export var move_speed : float = 0
@export var move_speed_curve : Curve

@export_category("Projectile")
@export var projectile_scene : PackedScene
## How far past the target's position the arrow lands, in the direction the bandit is facing.
@export var landing_overshoot : float = 32.0
## Where the arrow spawns from. Leave empty to just use the enemy's own position.
@export var spawn_point : Node2D

var timer : float = 0
var duration : float = 0
var on_cooldown : bool = false

const AUDIO_ARROW_SWOOSH = preload("uid://cki485sqbvt12")

func _ready() -> void:
	# Getting hit while loosing the shot shouldn't cancel it — see
	# EnemyState.interruptible_by_hit / Enemy.on_damage_taken().
	interruptible_by_hit = false


func enter() -> void:
	blackboard.can_decide = false
	on_cooldown = true

	enemy.visuals.play_animation( animation_name if animation_name else "shoot" )
	duration = enemy.visuals.get_animation_length( animation_name if animation_name else "shoot" )
	Audio.play_spatial_sound( AUDIO_ARROW_SWOOSH, enemy.global_position, false, false, 0.5)
	if duration <= 0.0:
		duration = 0.0001 # avoid getting stuck if there's no animation length to go off of

	timer = 0
	enemy.velocity.x = move_speed * blackboard.dir

	_fire()
	pass


func re_enter() -> void:
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


func _fire() -> void:
	if not projectile_scene or not blackboard.target:
		return

	var projectile : Node2D = projectile_scene.instantiate()
	get_tree().current_scene.add_child( projectile )
	projectile.global_position = spawn_point.global_position if spawn_point else enemy.global_position

	# Facing was already locked in during ES_Aim, so overshoot is applied along
	# blackboard.dir — land a bit past the target rather than exactly on them.
	var landing_point : Vector2 = Vector2(
		blackboard.target.global_position.x + ( landing_overshoot * blackboard.dir ),
		blackboard.target.global_position.y
	)

	# The projectile owns its own arc/speed/curve — it just needs to know
	# where it's going, nothing about the player, enemy, or blackboard.
	if projectile.has_method( "launch" ):
		projectile.launch( landing_point )
	pass
