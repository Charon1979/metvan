class_name DecisionEngineSwordBandit
extends DecisionEngine
# Included in DecisionEngine:
# var enemy : Enemy
# var current_state : EnemyState
# var blackboard : Blackboard

@export var attack_state : ESBanditSwordAttack
@export var advance_state : ESBanditSwordAdvance
@onready var es_idle: ESIdle = %ESIdle
@onready var es_stun: ESStun = %ESStun
@onready var es_death: ESDeath = %ESDeath
@onready var es_shield_breaker: ESShieldBreaker = %ESShieldBreaker

func _ready() -> void:
	await super()
	pass

# All the conditions for making decisions go in this function
func decide() -> EnemyState:
	if current_state is ESDeath or not blackboard.can_decide:
		return null

	if blackboard.damage_source:
		if blackboard.health <= 0:
			return es_death
		if blackboard.shield_active:
			match blackboard.damage_type:
				DamageType.DamageType.MAGIC:
					
					return es_stun
				DamageType.DamageType.LIGHT, DamageType.DamageType.HEAVY:
					return es_shield_breaker
				_:
					return es_stun
		else:
			return es_stun

	if blackboard.edge_detected:
		return es_idle

	if blackboard.target:
		var can_attack : bool = attack_state.can_attack()

		if can_attack and blackboard.distance_to_target <= attack_state.attack_range:
			return attack_state

		if not can_attack and blackboard.distance_to_target >= advance_state.max_retreat_distance:
			return es_idle

		return advance_state

	return es_idle
