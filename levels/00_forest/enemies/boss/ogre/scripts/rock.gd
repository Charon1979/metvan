class_name Rock
extends CharacterBody2D

## Persistent projectile dropped from the ceiling by the ogre's Charge and
## Frenzy attacks (spawned via OgreBoss.spawn_ceiling_rock()). Falls until
## it lands, then becomes a solid, standable platform — destructible by the
## player, and instantly destroyed if the ogre touches it.
##
## Expected scene tree (see README for full setup):
##   Rock (CharacterBody2D, this script)
##   |- Sprite2D
##   |- CollisionShape2D        (the rock's own solid body)
##   |- HazardArea (class HazardArea)   -- active only while falling
##   |- DamageArea (class DamageArea)   -- lets the player's AttackArea hit it
##   |- OgreCrushArea (Area2D)          -- detects the ogre; destroys the rock
##   |- FloorRayCast (RayCast2D)        -- points straight down; see solid_layer below

@export var health : int = 1
@export var fall_speed : float = 420.0
@export var gravity_scale : float = 1.0
## Which collision_layer bit makes the rock solid to the player/world (i.e.
## the bit the player's own collision_mask reacts to). Off for the whole
## fall so the rock can drop straight through the player instead of
## physically shoving them into the floor, and switched on the moment
## floor_ray detects the ground is close — right before landing, not for
## the whole descent. collision_mask is left alone throughout, so the rock
## keeps detecting the actual floor via move_and_slide()/is_on_floor() the
## entire time regardless of this toggle.
@export var solid_layer : int = 1
@onready var sprite: Sprite2D = $Sprite2D

@onready var hazard_area : HazardArea = $HazardArea
@onready var damage_area : DamageArea = $DamageArea
## The rock's own solid body — see the scene tree note above. Used to query
## whether it's still physically overlapping world geometry right after
## spawning; see _still_overlapping_world() below.
@onready var collision_shape: CollisionShape2D = $CollisionShape2D



## Rename this path if your RayCast2D node isn't called "FloorRayCast".
## Point it straight down (target_position = Vector2(0, N)) — its length
## IS the "how close is close enough" threshold, since is_colliding() only
## flips true once the floor is within that ray's reach.
@onready var floor_ray: RayCast2D = $FloorRay

@export var particle_scene: PackedScene
@onready var particles_anchor: GPUParticles2D = $Rock_debries_v1
@onready var rock_debries: GPUParticles2D = $Rock_debries_v2

const AUDIO_OGRE_HIT_ROCK = preload("uid://tbq6wwlime6y")

var _landed : bool = false
var _solid : bool = false
var _world_mask : int = 0
var _ignoring_ceiling : bool = false


func _ready() -> void:
	z_index = -10
	damage_area.damage_taken.connect( _on_damage_taken )
	sprite.frame = randi_range(0,3)
	sprite.flip_h = randi() % 2 == 0
	set_collision_layer_value( solid_layer, false )

	# Spawning the Marker2D up near/inside the ceiling — so the rock doesn't
	# visibly pop in from clear air — means it can easily spawn overlapping
	# the ceiling's own collision. Ignore world collision entirely until a
	# shape query confirms we're actually clear of it (see
	# _still_overlapping_world below), rather than guessing a fixed fall
	# distance — a fixed distance can't tell "still stuck in the ceiling"
	# apart from "already reached the floor," which is exactly what let
	# rocks fall straight through low-ceilinged rooms.
	_world_mask = collision_mask
	collision_mask = 0
	_ignoring_ceiling = true


func _physics_process( delta : float ) -> void:
	if _landed:
		return

	velocity.y = min( velocity.y + get_gravity().y * gravity_scale * delta, fall_speed )

	if _ignoring_ceiling and not _still_overlapping_world():
		_ignoring_ceiling = false
		collision_mask = _world_mask

	# RayCast2D has no signal — it's polled, not event-driven. Godot
	# refreshes its result once per physics frame on its own, so just
	# reading is_colliding() here is enough; no force_raycast_update() needed.
	if not _solid and floor_ray and floor_ray.is_colliding():
		_solid = true
		set_collision_layer_value( solid_layer, true )

	move_and_slide()

	if not _ignoring_ceiling and is_on_floor():
		_land()


## True while the rock's own collision shape still overlaps anything on
## _world_mask (the ceiling it may have spawned inside of, most likely).
## Queried with collision_mask temporarily zeroed out, so this only ever
## reports the world geometry itself — never a false positive from the
## rock's own disabled solid_layer or the player.
func _still_overlapping_world() -> bool:
	if not collision_shape or not collision_shape.shape:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.collision_mask = _world_mask
	query.exclude = [ get_rid() ]
	var space_state : PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	return not space_state.intersect_shape( query, 1 ).is_empty()


func _land() -> void:
	z_index = 0
	_landed = true
	velocity = Vector2.ZERO
	rock_debries.emitting = true
	Audio.play_spatial_sound( AUDIO_OGRE_HIT_ROCK, global_position)
	# Failsafe: guarantees the rock ends up solid/standable even if
	# floor_ray never fired (missing node, mis-set target_position, etc.)
	# — otherwise it would land but stay permanently walk-through.
	if not _solid:
		_solid = true
		set_collision_layer_value( solid_layer, true )
	if hazard_area:
		hazard_area.queue_free()  # "no longer have a hazard area after they hit the ground"


func _on_damage_taken( attack_area : AttackArea ) -> void:
	health -= attack_area.damage if attack_area else 1
	if health <= 0:
		_destroy()

func _destroy() -> void:
	damage_area.queue_free()
	collision_shape.queue_free()
	hazard_area.queue_free()
	VisualEffects.hit_dust( global_position )
	Audio.play_spatial_sound( AUDIO_OGRE_HIT_ROCK, global_position)
	sprite.visible = false
	
	var p = particle_scene.instantiate()
	add_child(p)
	p.position = particles_anchor.position
	p.lifetime = 4
	p.speed_scale = 2
	p.restart()
	await p.finished
	queue_free()
