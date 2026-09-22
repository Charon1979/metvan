class_name ESShieldBreaker
extends EnemyState


@export var knockback_resist : float = 0.0
@export var knockback_vertical_bias : float = -1.0
@export var stun_state : ESStun
@export var light_hit_duration : float = 0.2
@export var shield_break : AudioStream

var vel_x : float = 0
var vel_y : float = 0
var duration : float = 0
var timer : float = 0


# AUDIO_SHIELD_IMPACT (the old light-hit sound) was removed — EnemyBanditSword.
# deflect_sound now covers that moment for every blocked hit (light AND
# heavy), so playing this too was doubling up. AUDIO_SHIELD_BREAK stays —
# that's the shield actually shattering, on top of the deflect sound, not a
# duplicate of it.



func start() -> void:
	blackboard.can_decide = false
	if blackboard.shield_active == true:
		match blackboard.damage_type:
			DamageType.DamageType.LIGHT:
				timer = 0
				duration = light_hit_duration
				_calc_velocity( blackboard.damage_source )
				enemy.hit_particles.trigger_hit_particle( blackboard.damage_source, 1 )
				blackboard.damage_source = null
			DamageType.DamageType.HEAVY:
				enemy.attack_area.set_active( false )
				enemy.visuals.play_animation( "stun" )
				duration = enemy.visuals.get_animation_length( "stun" )
				if duration <= 0.0:
					duration = 0.0001
				timer = 0
				_calc_velocity( blackboard.damage_source )
				enemy.hit_particles.trigger_hit_particle( blackboard.damage_source, 0 )
				blackboard.damage_source = null
				Audio.play_spatial_sound( shield_break, enemy.global_position, false, true, 1 )
				enemy.shield.visible = false
				blackboard.shield_active = false
	else:
		blackboard.damage_source = null
		state_machine.change_state(stun_state)
	pass
	
func enter() -> void:
	start()
	pass
	
func re_enter() -> void:
	start()
	pass
	
func exit() -> void:
	blackboard.can_decide = true
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
