class_name ESBowBanditAim
extends EnemyState

# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard

## How long the bandit stands still drawing/holding the bow before it's ready to fire.
@export var wind_up_duration : float = 0.6

var timer : float = 0

const AUDIO_BOW_DRAW = preload("uid://chgrcow4lx1vw")


func _ready() -> void:
	# Getting hit while drawing the bow shouldn't cancel the shot — see
	# EnemyState.interruptible_by_hit / Enemy.on_damage_taken(). Covers the
	# aim/wind-up half of "bow shooting"; ESBowBanditAttack covers the
	# release half.
	interruptible_by_hit = false


func enter() -> void:
	# Lock facing toward the target before committing to the draw — no turning
	# once the arrow's being nocked.
	if blackboard.target:
		var target_dir : float = sign( blackboard.target.global_position.x - enemy.global_position.x )
		if target_dir != 0:
			enemy.change_dir( target_dir )

	enemy.visuals.play_animation( animation_name if animation_name else "aim" )
	Audio.play_spatial_sound( AUDIO_BOW_DRAW, enemy.global_position, false, false, 0.5)

	timer = 0
	enemy.velocity.x = 0
	blackboard.can_decide = false
	blackboard.is_aiming = true
	pass


func re_enter() -> void:
	pass


func exit() -> void:
	blackboard.can_decide = true
	blackboard.is_aiming = false
	pass


func physics_update( _delta : float ) -> void:
	# Rooted in place — no repositioning while the shot is being lined up.
	enemy.velocity.x = 0

	timer += _delta
	if timer >= wind_up_duration:
		blackboard.can_decide = true
	pass
