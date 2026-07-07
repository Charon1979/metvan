class_name DecisionEngineBowBandit
extends DecisionEngine

@export var idle_state : ESIdle
@export var stun_state : ESStun
@export var death_state : ESDeath
@export var aim_state : ESBowBanditAim
@export var attack_state : ESBowBanditAttack
@export var flee_state : ESBowBanditFlee
@export var chase_state : ESChase # reused as the "approach" state


func decide() -> EnemyState:
	if blackboard.health <= 0:
		return death_state

	if blackboard.damage_source:
		return stun_state

	if blackboard.target == null:
		return idle_state

	# The wind-up just finished (can_decide flipped back to true while we were
	# still in Aim) — go ahead and loose the shot rather than re-evaluating
	# whether to aim again.
	if current_state == aim_state:
		return attack_state

	# Being able to shoot wins even if the player is also close enough to
	# trigger Flee below — no point running if the cooldown is already up.
	if attack_state.can_attack():
		return aim_state

	# Don't run or chase off a ledge — hold ground instead. Shooting is still
	# allowed since that check already happened above.
	if blackboard.edge_detected:
		return idle_state

	if blackboard.distance_to_target < flee_state.safe_distance:
		return flee_state

	if blackboard.distance_to_target > attack_state.attack_range:
		return chase_state

	# In range, on cooldown, not too close — just hold position and wait it out.
	return idle_state
