class_name DecisionEngineAxeBandit
extends DecisionEngine

# Included in DecisionEngine:
# var enemy : Enemy
# var current_state : EnemyState
# var blackboard : Blackboard

@export var attack_state : ESBanditAxeAttack
@export var chase_state : EnemyState

@onready var es_stun: ESStun = %ESStun
@onready var es_death: ESDeath = %ESDeath
@onready var es_idle: ESIdle = %ESIdle



func _ready() -> void:
	await super()
	pass



# All the conditions for making decisions go in this function
func decide() -> EnemyState:
	# Example decisions
	if blackboard.damage_source:
		if blackboard.health <= 0:
			return es_death
		else:
			return es_stun
	
	if current_state is ESDeath or not blackboard.can_decide:
		return null
	
	if blackboard.target:
		if attack_state.can_attack():
			return attack_state
		return chase_state
	return es_idle
