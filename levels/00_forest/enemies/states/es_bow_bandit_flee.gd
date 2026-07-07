class_name ESBowBanditFlee
extends EnemyState

# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard

@export var run_speed : float = 70.0
@export var acceleration : float = 300.0 # ease-in only, stopping is instant

## Flee while the target is closer than this.
@export var safe_distance : float = 96.0

## Needed to know when the bandit is off cooldown and allowed to shoot again.
@export var attack_state : ESBowBanditAttack


func enter() -> void:
	enemy.visuals.play_animation( animation_name if animation_name else "chase" )
	pass


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( delta : float ) -> void:
	if blackboard.target == null:
		enemy.velocity.x = 0
		return

	var distance : float = blackboard.target.global_position.x - enemy.global_position.x
	var too_close : bool = abs( distance ) < safe_distance
	var can_shoot_again : bool = not attack_state.on_cooldown

	# Any of these hard-stops the retreat — no easing out, just cut the velocity.
	if not too_close or can_shoot_again or blackboard.edge_detected or enemy.is_on_wall() or blackboard.is_aiming:
		enemy.velocity.x = 0
		return

	var flee_dir : float = -sign( distance )
	enemy.velocity.x = move_toward( enemy.velocity.x, flee_dir * run_speed, acceleration * delta )
	pass
