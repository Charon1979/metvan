@icon ( "uid://clik7pjgto8k4" )

class_name EnemyState
extends Node

@export var animation_name : String

## "Hyper armor" switch — true (default) means a hit while this state is
## active knocks the enemy straight into its stun/shield-breaker/death
## reaction like normal. Set to false on states that shouldn't be cancelled
## mid-action (e.g. an attack swing already committed to) — see
## Enemy.on_damage_taken(), which is what actually reads this. The hit
## still registers (health/knockback data is recorded there regardless);
## this only controls whether it's allowed to interrupt what the enemy is
## currently doing right now, or has to wait until this state finishes and
## the decision engine re-evaluates on its own.
@export var interruptible_by_hit : bool = true

var state_machine : EnemyStateMachine
var enemy : Enemy
var blackboard : Blackboard

func enter() -> void: pass
func re_enter() -> void: pass
func exit() -> void: pass
func physics_update( _delta : float ) -> void : pass
