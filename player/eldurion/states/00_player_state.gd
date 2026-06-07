extends Node
class_name PlayerState

var player : Player
var next_state : PlayerState

#region /// state references
@onready var idle: PlayerStateIdle = %Idle
@onready var run: PlayerStateRun = %Run
@onready var jump: PlayerStateJump = %Jump
@onready var fall: PlayerStateFall = %Fall
@onready var crouch: PlayerStateCrouch = %Crouch
@onready var attack: PlayerStateAttack = %Attack
@onready var take_damage: PlayerStateTakeDamage = %TakeDamage
@onready var death: PlayerStateDeath = %Death
@onready var dash: PlayerStateDash = %Dash
@onready var combo_attack: PlayerStateComboAttack = %ComboAttack
@onready var power_charge: PlayerStatePowerCharge = %PowerCharge
@onready var power_attack: PlayerStatePowerAttack = %PowerAttack
@onready var power_cancel: PlayerStatePowerCancel = %PowerCancel
@onready var ground_slam: PlayerStateGroundSlam = %GroundSlam





#endregion


# What happens when this state is initialized?
func init() -> void:
	pass


# What happens when we enter this state?
func enter() -> void:
	pass


# What happens when we exit this state?
func exit() -> void:
	pass


# What happens when an input is pressed?
func handle_input( _event : InputEvent ) -> PlayerState:
	return next_state


# What happens each process tick in this state?
func process( _delta: float ) -> PlayerState:
	return next_state


# What happens each physics_process tick in this state?
func physics_process( _delta: float ) -> PlayerState:
	return next_state
