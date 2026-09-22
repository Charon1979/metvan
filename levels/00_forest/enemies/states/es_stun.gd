class_name ESStun
extends EnemyState
# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard
@export var knockback_resist : float = 0.0
@export var knockback_vertical_bias : float = -1.0 # negative = upward "pop" on hit
var vel_x : float = 0
var vel_y : float = 0
var duration : float = 0
var timer : float = 0
var stun_anims := {
	DamageType.DamageElement.FIRE: "fire",
	DamageType.DamageElement.AIR: "air",
	DamageType.DamageElement.EARTH: "earth",
	DamageType.DamageElement.WATER: "water",
	DamageType.DamageElement.PHYSICAL: "physical",
	DamageType.DamageElement.SHADOW: "shadow",
	DamageType.DamageElement.BLOOD: "blood"
}
func start() -> void:
	var effect_name = stun_anims.get(blackboard.damage_element)
	enemy.attack_area.activate( false )
	enemy.visuals.play_animation( animation_name if animation_name else "stun" )
	enemy.visuals.get_current_animation()
	if enemy.visuals.animation_player.current_animation == animation_name:
		enemy.visuals.play_animation( animation_name if animation_name else "stun" )
		enemy.vfx.play_vfx( effect_name )
	else:
		enemy.visuals.play_animation( animation_name if animation_name else "stun" )
		duration = enemy.visuals.get_animation_length( animation_name )
		enemy.vfx.play_vfx( effect_name )
	duration = enemy.visuals.get_animation_length( animation_name )
	if duration <= 0.0:
		duration = 0.0001 # avoid division by zero in physics_update
	timer = 0
	_calc_velocity( blackboard.damage_source )
	blackboard.damage_source = null
	blackboard.can_decide = false
	
	pass
func enter() -> void:
	start()
	pass
func re_enter() -> void:
	start()
	pass
func exit() -> void:
	blackboard.can_decide = true
	# Was `owner.vfx` — `owner` is the node's scene owner, not the Enemy, so
	# this silently failed to stop the stun VFX. Every other line in this
	# file correctly uses `enemy.*`.
	enemy.vfx.stop_vfx()
	pass
func physics_update( delta : float ) -> void:
	
	timer += delta
	enemy.velocity.x = vel_x * ( 1 - timer / duration ) 
	enemy.velocity.y = vel_y * ( 1 - timer / duration ) 
	if timer >= duration:
		blackboard.can_decide = true
	
	pass
func _calc_velocity( a : AttackArea ) -> void:
	if a == null:
		vel_x = 0
		vel_y = 0
		return
	vel_x = 1
	if a.global_position.x > enemy.global_position.x:
		vel_x = -1
	vel_x *= (a.force * 5 - knockback_resist)
	#vel_y = knockback_vertical_bias * (a.force - knockback_resist)
	pass
