class_name DecisionEngineAxeBandit
extends DecisionEngine

# Included in DecisionEngine:
# var enemy : Enemy
# var current_state : EnemyState
# var blackboard : Blackboard

@export var attack_state : ESBanditAxeAttack
@export var chase_state : EnemyState

## How long the bandit is allowed to keep chasing (while it can't yet
## attack) before it's forced to stop and rest — see chase_cooldown below.
## Measures unbroken time actually spent in chase_state, not overall time
## since the target was first spotted — see _process() below.
@export var chase_duration : float = 3.0
## How long the bandit stands still (idle) once chase_duration runs out,
## before it's allowed to chase again. Only blocks movement, not
## attacking — see decide()'s attack_state.can_attack() check, which is
## still checked first regardless of cooldown.
@export var chase_cooldown : float = 3.0

@onready var es_stun: ESStun = %ESStun
@onready var es_death: ESDeath = %ESDeath
@onready var es_idle: ESIdle = %ESIdle

# How long the CURRENT unbroken chase has been running. Reset to 0 the
# instant current_state isn't chase_state anymore for any reason (attacking,
# stunned, lost the target, or the cooldown below kicking in) — so this only
# ever measures one continuous chase, never an accumulated total.
var _chase_time : float = 0.0

# > 0 while on the forced-rest cooldown after a chase timed out. Ticked down
# every frame regardless of state, same idiom as player.gd's own cooldown
# timers (attack_cooldown_timer etc).
var _cooldown_timer : float = 0.0


func _ready() -> void:
	await super()
	pass


func _process( delta : float ) -> void:
	if current_state == chase_state:
		_chase_time += delta
	else:
		_chase_time = 0.0
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta


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
		if _cooldown_timer > 0.0:
			return es_idle
		if _chase_time >= chase_duration:
			_cooldown_timer = chase_cooldown
			return es_idle
		return chase_state
	return es_idle
