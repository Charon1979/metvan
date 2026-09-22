class_name BossLadder
extends Node2D

## Reflects the boss's defeated/alive state on load by playing the matching
## ladder animation — "ladder_down" once the boss is dead (so the player can
## climb down into/out of the arena), "ladder_up" while it's still alive
## (blocking the way). Reads the exact same persistent flag
## BossBattleOrchestrator sets on defeat, via its persistent_key(), so there's
## nothing new to keep in sync — just point this at that orchestrator.
##
## The actual scene transition is configured as an InteractionActionTransition
## resource on $InteractionTrigger's `actions` array (Inspector), not code —
## since interaction_trigger.area_2d.monitoring is only ever turned on once
## the boss is confirmed dead (below, and in _on_battle_ended), the
## transition can never fire while the boss is still alive, so no extra
## conditional is needed here. Tune the target scene/area/offset there.

@export var boss_orchestrator : BossBattleOrchestrator

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var interaction_trigger : InteractionTrigger = $InteractionTrigger


func _ready() -> void:
	Messages.battle_ended.connect( _on_battle_ended )

	if is_boss_dead():
		interaction_trigger.area_2d.monitoring = true
		animation_player.play( "ladder_ground" )
	else:
		interaction_trigger.area_2d.monitoring = false
		animation_player.play( "ladder_up" )


func is_boss_dead() -> bool:
	if not boss_orchestrator:
		return false  # unassigned — fail safe to "alive" rather than guessing
	return SaveManager.persistent_data.get( boss_orchestrator.persistent_key(), "" ) == "defeated"


func _on_battle_ended() -> void:
	# Messages.battle_ended fires for EVERY enemy's death, not just the boss
	# (same cross-talk issue already guarded against in
	# boss_battle_orchestrator.gd's own end_boss_battle()). Without this
	# check, any regular enemy dying anywhere in the loaded scene would
	# wrongly play the ladder-down animation and open the trigger even while
	# the actual boss is still alive.
	if not boss_orchestrator or not is_instance_valid( boss_orchestrator.boss ) or not ( boss_orchestrator.boss is Enemy ) or not ( boss_orchestrator.boss.state_machine.current_state is ESDeath ):
		return
	VisualEffects.camera_shake( 10 )
	animation_player.play( "ladder_down" )
	interaction_trigger.area_2d.monitoring = true
	pass
