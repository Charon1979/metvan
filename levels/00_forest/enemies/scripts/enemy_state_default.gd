#class_name ESName
extends EnemyState
# meta-name: EnemyState
# meta-description: Boilerplate template for enemy state script
# meta-default: true

# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard


func enter() -> void:
	# What happens when we enter this state?
	pass


func re_enter() -> void:
	# What happens if the state is called again?
	pass


func exit() -> void:
	# What do we need to clean up when exiting this state?
	pass


func physics_update( _delta : float ) -> void:
	# What physics do we need to influence while in this state?
	pass
