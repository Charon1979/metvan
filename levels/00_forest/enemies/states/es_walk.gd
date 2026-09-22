class_name ESWalk
extends EnemyState

@export var walk_speed : float = 50


func enter() -> void:
	# enemy.play_animation() doesn't exist on Enemy — every other state routes
	# through enemy.visuals.play_animation(). Calling it directly here threw
	# a "function not found" runtime error the instant a basic-decision-engine
	# enemy entered Walk.
	enemy.visuals.play_animation( animation_name if animation_name else "walk" )
	pass


func re_enter() -> void:
	# What happens if the state is called again?
	pass


func exit() -> void:
	# What do we need to clean up when exiting this state?
	pass


func physics_update( _delta : float ) -> void:
	if enemy.is_on_wall():
		enemy.change_dir( -blackboard.dir )
	enemy.velocity.x = walk_speed * blackboard.dir
	pass
