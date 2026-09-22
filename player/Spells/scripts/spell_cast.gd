## Base for any equippable spell's effect — instantiated fresh per cast and
## left to run on its own (same lifecycle as Arrow: spawned, does its thing,
## queue_free()s itself), never a shared/persistent instance living on the
## player. PlayerStateSpell.equipped_spell (and, once built, the empowered-
## release state) hold a PackedScene pointing at a scene whose root uses
## this script.
##
## "Different spells will use different nodes" — every child reference
## below is optional (get_node_or_null, same pattern as Arrow/Enemy), so a
## given spell's scene only needs to include whichever of these it actually
## uses: GPUParticles2D (auto-restarted on both cast() and cast_empowered()
## — see _start_particles() — so its amount/texture/process_material/
## lifetime/etc. as set on that node in each character's spell scene is all
## that's needed to get different particle behavior per spell, no script
## required), Sprite2D, an AnimationPlayer for the effect's own visual
## timing (distinct from the player's), AttackArea (damages enemies/
## breakables), HazardArea (damages the player — same class arrows use),
## DamageArea (makes this instance itself damageable, e.g. a totem an enemy
## can destroy). Apart from gpu_particles, none of them are wired to
## anything by this base class on their own; a concrete spell wires up
## whichever it needs inside its own _apply_cast_effect()/
## _apply_empowered_effect() override — which still runs BEFORE particles
## start, so it's free to reconfigure gpu_particles (direction, color, a
## swapped process_material) first.
##
## cast_animation/empowered_animation name a clip on the PLAYER's own
## AnimationPlayer, not this scene's — PlayerStateSpell reads these right
## after instantiate(), before calling cast()/cast_empowered() below.
class_name SpellCast
extends Node2D

@export_category( "Player animation" )
@export var cast_animation : StringName = &"spell_0"
@export var empowered_animation : StringName = &"spell_1"
## Played on the player instead of cast_animation when a cast is attempted
## without enough resource to pay for it — see PlayerStateSpell.enter().
## Named to match the (not yet built) empowered-charge system's own fail
## case, since by default both are meant to share one fizzle animation;
## override per-spell if a given spell wants its own.
@export var fail_animation : StringName = &"power_spell_fail"

@export_category( "Resource cost" )
## Spent via Messages.player_casting.emit(-cost) — the same generic
## resource-spend signal Dash already uses (Player._on_player_casted adds
## the (negative) amount to resource_current), so this works no matter
## which resource a given character subclass actually has, and regardless
## of what it's called.
@export var resource_cost : float = 10.0
@export var empowered_resource_cost : float = 20.0

@export_category( "Presentation" )
@export var cast_sfx : AudioStream
@export var empowered_sfx : AudioStream
@export var hit_sfx : AudioStream
@export var empowered_hit_sfx : AudioStream
## Where the effect should originate relative to the caster, e.g. nudged up
## to hand/staff height. (0,0) = player.global_position. The x component is
## mirrored automatically for a left-facing cast; y is not.
@export var origin_offset : Vector2 = Vector2.ZERO

@export_category( "Casting character" )
## Optional clip played on the CASTER's own separate SpellAnim
## AnimationPlayer (a player-scene node distinct from player.animation_player
## and from this scene's own effect_animation_player) the instant a real
## cast begins — e.g. a hand-glow or rune-circle overlay on the character
## itself, layered alongside cast_animation on the body. Empty ("") = no
## overlay for this spell. Read directly off the equip slot by
## PlayerStateSpell.enter(), same as cast_animation — see there for exact
## timing. Only fires on a real cast, not on a fail_animation fizzle.
@export var caster_animation : StringName = &""
## Optional sound tied to the CASTER (an incantation/shout/chant as casting
## starts) — distinct from cast_sfx above, which plays on the spell EFFECT
## itself once the cast animation finishes, positioned at wherever the
## effect actually originates. Also read directly off the equip slot by
## PlayerStateSpell.enter(), at the same moment as caster_animation, and
## also only on a real cast.
@export var caster_sfx : AudioStream = null

@export_category( "Lifetime" )
## How long this instance exists before auto-despawning. 0 = never
## auto-despawn — a concrete spell that needs different timing (e.g.
## despawn only once its AttackArea's active window ends, or a projectile
## that despawns on impact) should call queue_free() itself instead and
## leave this at 0.
@export var lifetime : float = 0.0

@onready var gpu_particles : GPUParticles2D = get_node_or_null( "GPUParticles2D" )
@onready var sprite : Sprite2D = get_node_or_null( "Sprite2D" )
@onready var effect_animation_player : AnimationPlayer = get_node_or_null( "AnimationPlayer" )
@onready var attack_area : AttackArea = get_node_or_null( "AttackArea" )
@onready var hazard_area : HazardArea = get_node_or_null( "HazardArea" )
@onready var damage_area : DamageArea = get_node_or_null( "DamageArea" )


func _ready() -> void:
	if lifetime > 0.0:
		get_tree().create_timer( lifetime ).timeout.connect( queue_free )


## Called once by PlayerStateSpell right as the cast animation starts.
func cast( player : Player ) -> void:
	_position_at( player )
	# Messages.player_casting is declared as (mp: int) — cast explicitly
	# rather than relying on an implicit float->int conversion on emit.
	Messages.player_casting.emit( -int( round( resource_cost ) ) )
	if cast_sfx:
		Audio.play_spatial_sound( cast_sfx, global_position, false, true, 0.6 )
	_apply_cast_effect( player )
	_start_particles()


## Called once by the empowered-release state (not built yet).
func cast_empowered( player : Player ) -> void:
	_position_at( player )
	Messages.player_casting.emit( -int( round( empowered_resource_cost ) ) )
	if empowered_sfx:
		Audio.play_spatial_sound( empowered_sfx, global_position, false, true, 0.6 )
	_apply_empowered_effect( player )
	_start_particles()


## Override in a subclass: whatever the regular cast actually does —
## activate attack_area/hazard_area, reconfigure gpu_particles (it starts on
## its own right after this returns — see _start_particles()), play
## effect_animation_player, launch a projectile, all of it. Does nothing by
## default, so a spell with no override still gets positioned, spends its
## resource, plays its sound, and fires its particles (if it has any), and
## nothing else.
func _apply_cast_effect( _player : Player ) -> void:
	pass


## Override in a subclass. Defaults to the same effect as a regular cast —
## override this separately only when the empowered version needs to
## actually differ in *kind* (extra particles, a different shape/behavior).
## If it's just "the same effect with bigger numbers", set those on exported
## fields elsewhere and you likely don't need to override this at all.
func _apply_empowered_effect( player : Player ) -> void:
	_apply_cast_effect( player )


func _position_at( player : Player ) -> void:
	var dir : float = -1.0 if player.sprite_2d.flip_h else 1.0
	global_position = player.global_position + Vector2( origin_offset.x * dir, origin_offset.y )
	scale.x = dir


## Fires whatever's on gpu_particles, if the scene has one — called after
## _apply_cast_effect()/_apply_empowered_effect() so an override that needs
## to reconfigure gpu_particles first (direction, color, a swapped
## process_material — same idiom as EffectParticles.start() elsewhere in
## the project) still gets a chance to do that before emission starts.
## restart() rather than setting emitting = true directly, so a re-cast of
## an already-emitting one-shot effect still restarts cleanly. Entirely
## config-driven: a spell scene with no GPUParticles2D child just does
## nothing here, and one that has it gets exactly the amount/texture/
## material/lifetime/etc. already set on that node in the editor — no
## per-spell script needed to opt in.
func _start_particles() -> void:
	if gpu_particles:
		gpu_particles.restart()
