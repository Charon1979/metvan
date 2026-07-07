class_name ESBanditSwordAdvance
extends EnemyState

@export var retreat_distance : float = 48.0
@export var max_retreat_distance : float = 80.0
@export var move_speed : float = 60.0
@export var retreat_speed : float = 50.0
@export var acceleration : float = 250.0
@export var attack_state : ESBanditSwordAttack

func enter() -> void:
	enemy.visuals.play_animation(animation_name if animation_name else "advance")
	#enemy.animation_player.play( "shield_advance" )
func re_enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(delta : float) -> void:
	if blackboard.target == null:
		return

	var distance : float = blackboard.target.global_position.x - enemy.global_position.x
	var target_dir : float = sign(distance)
	var abs_distance : float = abs(distance)

	if target_dir != 0 and target_dir != blackboard.dir:
		enemy.change_dir(target_dir)

	var on_cooldown : bool = attack_state.on_cooldown

	if on_cooldown:
		if abs_distance < retreat_distance:
			enemy.velocity.x = move_toward(enemy.velocity.x, -target_dir * retreat_speed, acceleration * delta)
		else:
			enemy.velocity.x = 0.0
	else:
		if abs_distance > attack_state.attack_range:
			enemy.velocity.x = move_toward(enemy.velocity.x, target_dir * move_speed, acceleration * delta)
		else:
			enemy.velocity.x = 0.0
