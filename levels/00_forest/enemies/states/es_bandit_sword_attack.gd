class_name ESBanditSwordAttack
extends EnemyState
@export var attack_range : float = 48
@export var cooldown : float = 3.0
@export var attack_delay : float = 0.25
@export var attack_area : AttackArea
@export var move_speed : float = 0
@export var move_speed_curve : Curve
var timer : float = 0
var duration : float = 0
var on_cooldown : bool = true

func _ready() -> void:
	run_cooldown()

func enter() -> void:
	
	attack_area.flip( blackboard.dir )
	blackboard.can_decide = false
	if blackboard.shield_active == true:
		enemy.visuals.play_animation( animation_name if animation_name else "attack_1" )
		#enemy.animation_player.play( "shield_attack" )
		duration = enemy.visuals.get_animation_length("attack_1")
	else:
		enemy.visuals.play_animation( animation_name if animation_name else "attack_2" )
		duration = enemy.visuals.get_animation_length("attack_2")
	timer = 0
	blackboard.can_decide = false
	on_cooldown = true
	enemy.velocity.x = move_speed * blackboard.dir

	#_trigger_hit()
	pass

#func _trigger_hit() -> void:
	#if attack_delay > 0.0:
		#await get_tree().create_timer( attack_delay ).timeout
#
	## Bail out if we've already left this state (e.g. hit stun, death) by the time the delay ends
	#if state_machine.current_state != self:
		#return
#
	#attack_area.activate( attack_area.duration )

func re_enter() -> void:
	# What happens if the state is called again?
	pass
func exit() -> void:
	
	blackboard.can_decide = true
	attack_area.set_active( false )
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
	var start_time = Time.get_ticks_msec() / 1000.0
	await get_tree().create_timer( cooldown ).timeout
	
	on_cooldown = false
	pass
