class_name ESStun
extends EnemyState


# EnemyState class will inherit the following variables:
# @export var animation_name : String = "idle"
# var state_machine : EnemyStateMachine
# var enemy : Enemy
# var blackboard : Blackboard
@export var knockback_resist : float = 0.0
@export var timer_adjustment : float = 1.0
var vel_x : float = 0
var vel_y : float = 0
var duration : float = 0
var timer : float = 0
var force : float = 1
var stun_anims := {
	DamageType.DamageElement.FIRE: "fire",
	DamageType.DamageElement.LIGHTNING: "lightning",
	DamageType.DamageElement.EARTH: "earth",
	DamageType.DamageElement.ICE: "ice",
	DamageType.DamageElement.PHYSICAL: "physical",
	DamageType.DamageElement.SHADOW: "shadow",
	DamageType.DamageElement.BLOOD: "blood",
}

@onready var vfx_sprite: Sprite2D = %VFXSprite
@onready var vfx_player: AnimationPlayer = %VFXPlayer



func start() -> void:
	var anim : String = animation_name if animation_name else "hurt"
	if enemy.animation.current_animation == anim:
		enemy.animation.seek( 0 )

	else:
		enemy.play_animation( anim )
		var effect_name = stun_anims.get(blackboard.damage_element)
		vfx_player.play( effect_name )
	duration = enemy.animation.current_animation_length * timer_adjustment
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
	vfx_player.stop()
	vfx_sprite.visible = false
	pass


func physics_update( delta : float ) -> void:
	
	timer += delta
	enemy.velocity.x = vel_x * ( 1 - timer / duration ) 
	enemy.velocity.y = vel_y * ( 1 - timer / duration ) 
	if timer >= duration:
		blackboard.can_decide = true
	
	pass



func _calc_velocity( a : AttackArea ) -> void:
	
	vel_x = 1
	vel_y = -0.025
	
	if a.global_position.x > enemy.global_position.x:
		vel_x = -1
	vel_x *= (force - knockback_resist)
	vel_y *= (force - knockback_resist)
	pass
