@icon("uid://clik7pjgto8k4")
class_name ESOgreDormant
extends EnemyState

# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard

## True initial state. This has to be the FIRST child under the ogre's
## EnemyStateMachine node — EnemyStateMachine.setup() always enters
## states.front() automatically, and that happens at _ready() time,
## regardless of process_mode. Keeping a no-op state here (instead of
## ESOgreFall itself) means that automatic enter() is harmless: the ogre
## stays invisible and inert until BossBattleOrchestrator calls
## OgreBoss.begin_intro(), which explicitly transitions to ESOgreFall.


func enter() -> void:
	enemy.visible = false
	blackboard.can_decide = false


func re_enter() -> void:
	pass


func exit() -> void:
	pass


func physics_update( _delta : float ) -> void:
	pass
