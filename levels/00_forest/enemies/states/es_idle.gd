class_name ESIdle
extends EnemyState

# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard


func enter() -> void:
	enemy.visuals.play_animation( animation_name if animation_name else "idle" )
	#if enemy.animation_player and enemy.animation_player.has_animation("shield_idle"):
		#enemy.animation_player.play("shield_idle")
	pass



func re_enter() -> void:
	# What happens if the state is called again?
	pass


func exit() -> void:
	# What do we need to clean up when exiting this state?
	pass


func physics_update( _delta : float ) -> void:
	enemy.velocity.x = 0
	if blackboard.target == null:
		pass
	else:
		var dir : float = sign( blackboard.target.global_position.x - enemy.global_position.x )
		enemy.change_dir(dir)
	pass
