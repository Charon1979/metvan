@icon("uid://clik7pjgto8k4")

class_name PlayerStateGroundSlam extends PlayerState

const DASH_AUDIO = preload("uid://d4k4f4ysr10fc")
const BOOM_AUDIO = preload("uid://diigvgr4uasjy")
const BREAK_WOOD_AUDIO = preload("uid://0c0prwmpduhj")











@onready var attack_area: AttackArea = %AttackArea
@onready var damage_area: DamageArea = %DamageArea
@onready var ground_slam_shape_cast: ShapeCast2D = $"../../GroundSlamShapeCast"
@onready var dash_part: GPUParticles2D = %Dash_part


@export var velocity : float = 400
@export var effect_delay : float = 0.075


var effect_timer : float = 0



func _ready() -> void:
	pass

func enter() -> void:
	player.animation_player.play( "ground_slam_impact" )
	dash_part.restart()
	#vfx_sprite.visible = true
	#vfx_player_01.play( "air_down" )
	player.sprite_2d.tween_color()
	Audio.play_spatial_sound( DASH_AUDIO, player.global_position, false, true, 0.5 )
	damage_area.start_invulnerable()
	pass

func process( _delta: float ) -> PlayerState:
	check_collisions( _delta )
	effect_timer -= _delta
	if effect_timer < 0:
		effect_timer = effect_delay
		player.sprite_2d.ghost()
	#	dash_part.restart()
	return null


		

func physics_process( _delta: float ) -> PlayerState:
	
	player.velocity = Vector2( 0, velocity )
	if player.is_on_floor():
		if not check_collisions( _delta ):
		#	vfx_sprite.visible = false
		#	vfx_player_01.stop()
			return idle
	return next_state

func check_collisions( _delta : float ) -> bool:
	ground_slam_shape_cast.target_position.y = velocity * _delta
	ground_slam_shape_cast.force_shapecast_update()
	if ground_slam_shape_cast.is_colliding():
		for i in ground_slam_shape_cast.get_collision_count():
			var c = ground_slam_shape_cast.get_collider( i )
			var pos : Vector2 = ground_slam_shape_cast.get_collision_point( i )
			
			VisualEffects.camera_shake( 10.0 )
			
			if c.get_parent() is Breakable:
				var b : Breakable = c.get_parent()
				b.queue_free()
				Audio.play_spatial_sound( b.destroy_audio, pos, false, true, 0.75 )
				for p in b.destroy_particles:
					VisualEffects.hit_particles( pos, Vector2.DOWN, p )
			else:
			
				c.queue_free()
				#VisualEffects.hit_particles( pos, Vector2.DOWN, HitParticles )
				Audio.play_spatial_sound( BREAK_WOOD_AUDIO, pos, false, true, 1 )
				
		return true
	return false


func exit() -> void:
	VisualEffects.camera_shake( 10.0 )
	VisualEffects.land_dust( player.global_position )
	Audio.play_spatial_sound( BOOM_AUDIO, player.global_position, false, true, 1 )
	dash_part.emitting = false
#	vfx_player_02.play( "down_attack_aoe" )
	damage_area.make_invulnerable()
	pass
