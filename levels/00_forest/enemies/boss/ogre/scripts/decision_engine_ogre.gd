@icon( "uid://b5vgsaeajpqmg" )

extends DecisionEngine
class_name OgreDecisionEngine

# Included in DecisionEngine:
# var enemy : Enemy
# var current_state : EnemyState
# var blackboard : Blackboard

@export var charge_start : ESOgreChargeStart
@export var jump_start : ESOgreJumpStart
@export var frenzy_start : ESOgreFrenzyStart

# get_node_or_null() rather than the plain %Name shorthand — %Name calls
# get_node() under the hood, which logs a "Node not found" engine error the
# instant this scene is loaded if that unique-named state isn't present. The
# ogre boss doesn't have (or need) every one of these — see the is_boss
# branch in decide() below — so a missing one should just resolve to null
# quietly and get skipped, not spam the log every time this scene loads.
@onready var es_idle: ESIdle = get_node_or_null( "%ESIdle" )
@onready var es_stun: ESStun = get_node_or_null( "%ESStun" )
@onready var es_death: ESDeath = get_node_or_null( "%ESDeath" )
@onready var es_shield_breaker: ESShieldBreaker = get_node_or_null( "%ESShieldBreaker" )

## Whichever top-level move was picked last, so decide() can weight it down
## next time instead of repeating it back-to-back. Not touched by the
## windup/action/end chain within a move — only decide() itself sets it.
var last_move : EnemyState = null


func _ready() -> void:
	await super()
	pass


# All the conditions for making decisions go in this function
func decide() -> EnemyState:
	if blackboard.damage_source:
		if blackboard.health <= 0:
			return es_death
		if enemy.is_boss:
			# Failsafe: the ogre has no ESStun/ESShieldBreaker node in its
			# scene (%ESStun/%ESShieldBreaker above resolve to null) and
			# doesn't need one. Routing to them anyway would return null
			# every time — state_machine.change_state() silently no-ops on
			# null, but blackboard.damage_source is only ever cleared
			# inside ESStun/ESShieldBreaker.start(). So it would sit here
			# forever, this branch would keep firing every single future
			# frame, and the moment the ogre next landed in a state that
			# lets decide() run (e.g. idle) it would get stuck there
			# permanently, unable to ever pick a new move again — which is
			# exactly the "takes a hit, goes to idle and does nothing" bug.
			# Clear the hit here instead and fall through to normal
			# move-picking below so the ogre just shrugs the hit off.
			blackboard.damage_source = null
		else:
			# shield_active stays false by default (see Blackboard) — this just
			# keeps the same routing the sword bandit uses, in case the ogre
			# ever gets a guard/hide-toughness mechanic layered on later.
			# Written as if/return rather than a ternary — es_shield_breaker
			# (ESShieldBreaker) and es_stun (ESStun) are different EnemyState
			# subclasses, and GDScript's ternary type-checker won't infer
			# their common base on its own, which is what was throwing the
			# INCOMPATIBLE_TERNARY warning here.
			if blackboard.shield_active:
				return es_shield_breaker
			return es_stun

	if current_state is ESDeath or not blackboard.can_decide:
		return null

	if not blackboard.target:
		return es_idle

	var candidates : Dictionary = {}
	if charge_start and charge_start.can_perform():
		candidates[ charge_start ] = 0.35 if last_move == charge_start else 1.0
	if jump_start and jump_start.can_perform():
		candidates[ jump_start ] = 0.35 if last_move == jump_start else 1.0
	if frenzy_start and frenzy_start.can_perform():
		candidates[ frenzy_start ] = 0.35 if last_move == frenzy_start else 1.0

	if candidates.is_empty():
		return null  # shouldn't happen — frenzy_start.can_perform() is always true

	var chosen : EnemyState = _weighted_pick( candidates )
	last_move = chosen
	return chosen


## Weighted-random pick among currently-valid moves. A move gets a lower
## weight (not a hard block) if it was the last one used, so the ogre
## favors variety without making any move impossible to repeat.
func _weighted_pick( candidates : Dictionary ) -> EnemyState:
	var total : float = 0.0
	for w in candidates.values():
		total += w

	var roll : float = randf() * total
	for state in candidates.keys():
		roll -= candidates[ state ]
		if roll <= 0.0:
			return state

	return candidates.keys().back()  # floating-point safety net
