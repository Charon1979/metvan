class_name ESChase
extends EnemyState

# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard

@export var chase_speed : float = 50.0
@export var acceleration : float = 250.0
@export var brake_speed : float = 350.0
@export var turn_speed_threshold : float = 5.0
@export var stop_distance : float = 24.0


func enter() -> void:
	enemy.visuals.play_animation(animation_name if animation_name else "chase")


func re_enter() -> void:
	pass


func exit() -> void:
	pass



func physics_update(delta : float) -> void:
	var distance := blackboard.target.global_position.x - enemy.global_position.x
	var target_dir : float = sign(distance)

	# Stay this many pixels away from the player
	if abs(distance) <= stop_distance:
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, brake_speed * delta)
		return

	if target_dir != blackboard.dir:
		# Slow down before turning around
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, brake_speed * delta)

		# Turn once we've almost stopped
		if abs(enemy.velocity.x) < turn_speed_threshold:
			enemy.change_dir(target_dir)
	else:
		# Accelerate towards chase speed
		var target_velocity : float = target_dir * chase_speed
		enemy.velocity.x = move_toward(
			enemy.velocity.x,
			target_velocity,
			acceleration * delta
			)
