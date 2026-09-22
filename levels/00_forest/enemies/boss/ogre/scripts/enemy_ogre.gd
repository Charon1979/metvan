@tool
@icon("uid://d2sbidjsqe1lq")
class_name OgreBoss
extends Enemy

## Boss arena references — place Marker2D/Node2D nodes in the boss arena
## scene and assign them here. Shared by every ogre-specific state via
## `enemy.left_wall` etc. instead of re-exporting the same refs on each one.
@export var left_wall : Node2D
@export var right_wall : Node2D
@export var ceiling_marker : Node2D

@export_category("Intro")
@export var roar_audio : AudioStream

@export_category("Rock Attack")
@export var rock_scene : PackedScene
## Delay between the ceiling dust warning appearing and the rock actually landing.
@export var rock_warning_delay : float = 0.6

@onready var fall_state : EnemyState = %ESOgreFall


func _ready() -> void:
	# The ogre has no ESStun/ESShieldBreaker node in its scene and doesn't
	# need one — flag it as a boss so OgreDecisionEngine's failsafe skips
	# routing hits there instead of getting stuck (see Enemy.is_boss).
	is_boss = true
	super._ready()


## Called by BossBattleOrchestrator once the player triggers the fight.
## Everything before this point (spawn, _ready(), the initial ESOgreDormant
## state) has to stay inert with the ogre invisible — this is the
## deliberate, explicit "go" signal, rather than relying on process_mode
## timing to keep things quiet.
##
## Takes the player explicitly rather than doing
## get_tree().get_first_node_in_group("Player") itself — that group isn't
## guaranteed to contain only the one real controllable player (Eldurion,
## for instance, also extends Player), so BossBattleOrchestrator passes
## the exact body that walked into the trigger area instead. This gives an
## immediate, correct target before the PlayerSensor child (see scene setup)
## has even had a physics frame to detect an overlap; the sensor then keeps
## target/target_position fresh for the rest of the fight on its own, the
## same way every other enemy's PlayerSensor already does — no more manual
## _physics_process sync needed here.
func begin_intro( player : Player ) -> void:
	visible = true
	blackboard.target = player
	state_machine.change_state( fall_state )


## Spawns the ceiling dust warning at `x` immediately, then the rock itself
## after rock_warning_delay. Used by both Charge (single rock) and Frenzy
## (three, called once per chosen x).
func spawn_ceiling_rock( x : float ) -> void:
	if not ceiling_marker:
		return

	var warn_pos := Vector2( x, ceiling_marker.global_position.y )
	VisualEffects.ceiling_dust_warning( warn_pos, rock_warning_delay )

	await get_tree().create_timer( rock_warning_delay ).timeout

	if not rock_scene:
		return

	var rock : Node2D = rock_scene.instantiate()
	get_tree().current_scene.add_child( rock )
	rock.global_position = Vector2( x, ceiling_marker.global_position.y )

	# The ogre needs to physically ignore his own falling/landed rocks —
	# unrelated to how they get destroyed (that's a separate HazardArea/
	# DamageArea interaction now, not this). Without this, once a rock
	# lands and goes solid (see rock.gd's solid_layer), it registers on
	# whatever collision_mask bit OgreBoss uses for wall/ground detection,
	# so ESOgreCharge's enemy.is_on_wall() check (es_ogre_charge.gd:27)
	# fires early against the rock instead of the real arena wall — and
	# even fixing that check alone wouldn't be enough, since move_and_slide()
	# would still physically block/stall the ogre against the rock's solid
	# body regardless. A per-pair collision exception sidesteps both: the
	# ogre passes straight through every rock it spawns. Area2D-based
	# overlap detection (HazardArea/DamageArea hits, the falling-rock
	# hazard, etc.) is unaffected by this — it only suppresses solid-body
	# collision resolution, not Area2D monitoring.
	if rock is PhysicsBody2D:
		add_collision_exception_with( rock )
		rock.add_collision_exception_with( self )

	# The ogre should ignore his own falling/landed rocks entirely — not
	# just for picking a move, but physically: without this, once a rock
	# lands and goes solid (see rock.gd's solid_layer), it registers on
	# whatever collision_mask bit OgreBoss uses for wall/ground detection,
	# so ESOgreCharge's enemy.is_on_wall() check (es_ogre_charge.gd:27)
	# fires early against the rock instead of the real arena wall — and
	# even fixing that check alone wouldn't be enough, since move_and_slide()
	# would still physically block/stall the ogre against the rock's solid
	# body regardless. A per-pair collision exception sidesteps both:
	# the ogre passes straight through every rock it spawns, while the
	# rock/player relationship (and OgreCrushArea's overlap detection,
	# which is Area2D-based and unaffected by this) stays untouched.
	if rock is PhysicsBody2D:
		add_collision_exception_with( rock )
		rock.add_collision_exception_with( self )
