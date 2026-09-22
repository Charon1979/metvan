## Straight-line projectile spell — flies at a fixed speed away from the
## caster until it hits something, then despawns. Built on SpellCast (see
## spell_cast.gd) as a concrete example of overriding _apply_cast_effect().
##
## Scene requirements beyond what SpellCast already provides: a HazardArea
## child (not a plain AttackArea — HazardArea is always-on rather than
## needing an explicit activate() window, which is exactly what a
## continuously-flying projectile needs so it can hit something the instant
## it touches it, at any point mid-flight). Its damage/dmg_element/dmg_type/
## force are whatever you set directly on that HazardArea node in the
## scene — this script only sets its collision_mask. A Sprite2D and/or
## SpellCast's own effect_animation_player (an AnimationPlayer child named
## "AnimationPlayer") cover the "animation while airborne" requirement; this
## script plays flight_animation on it while airborne, and hit_animation
## once it actually stops (see _on_hit()/_stop_and_play_hit()).
##
## Facing/positioning is already handled by SpellCast._position_at() (called
## right before this runs) — it sets scale.x to +1/-1 for facing and
## global_position to the caster + origin_offset. This script only adds
## straight-line movement and the despawn-on-hit behavior on top of that.
##
## A breakable's own solid collision shell is commonly left on terrain_layer
## (so it still physically blocks the player) alongside its actual
## DamageArea on breakable_layer — see falling_rock.gd. _on_hit() below
## checks for exactly that case before treating a terrain-layer hit as real
## terrain, so a breakable with a shell like that still gets damaged (and
## still plays the hit effect, since physically it WAS blocked) instead of
## stopping/bursting with no damage ever reaching it.
class_name SpellProjectile
extends SpellCast

@export var speed : float = 500.0
## Played on effect_animation_player (SpellCast's own AnimationPlayer, not
## the player's) for as long as this is airborne — stops automatically
## whichever way this despawns, since queue_free() takes the whole node
## (and its AnimationPlayer) with it.
@export var flight_animation : StringName = &"fly"

@export_category( "Impact" )
## Played on effect_animation_player once this actually stops (terrain, an
## enemy, or a breakable's solid shell — see _on_hit()). NOT played on a
## clean pass-through hit against a breakable's own DamageArea, since the
## bolt keeps flying there rather than stopping.
## hit_sfx itself is NOT declared here — it's inherited from SpellCast
## (alongside empowered_hit_sfx), which already covers "a sound for the
## effect's own impact" as an export; redeclaring it here would collide
## with that parent member instead of filling a gap.
@export var hit_animation : StringName = &"spell_hit"

@export_category( "Collision" )
## Solid terrain/walls — the projectile despawns here same as on an enemy,
## just without anything registering as damaged (terrain bodies aren't
## DamageAreas, so AttackArea's own hit_target handling has nothing to do).
@export_range( 1, 32, 1 ) var terrain_layer : int = 1
## Enemies' DamageArea layer — stops and despawns the projectile.
@export_range( 1, 32, 1 ) var enemy_layer : int = 6
## Breakables' DamageArea layer — still damaged (via AttackArea's own
## hit_target handling, unaffected by this script) but does NOT stop the
## projectile; it keeps flying through. Same "passes through, still
## damages" idea the lightning spell used.
@export_range( 1, 32, 1 ) var breakable_layer : int = 7

# Signed, independent of scale.x — scale only flips how this renders, it
# doesn't change what adding to position.x means, so movement needs its
# own copy of which way "forward" is.
var _direction : float = 1.0

# DamageAreas already hit this flight. A breakable's solid shell
# (StaticBody2D/CharacterBody2D, usually left on terrain_layer so it still
# blocks the player — see falling_rock.gd) and its DamageArea are two
# separate shapes covering roughly the same space, and can each trigger
# their own body_entered/area_entered independently, sometimes both for the
# same physical hit. Tracked so the shell fallback in _on_hit() below can't
# double-damage a target already hit directly.
var _hit_damage_areas : Array[ DamageArea ] = []

# Guards _stop_and_play_hit() against running twice — body_entered and
# area_entered can both fire in the same frame (e.g. clipping a breakable's
# shell and its DamageArea at once), and hazard_area.queue_free() doesn't
# remove it from the tree (and stop its monitoring) until the frame ends.
var _stopped : bool = false


func _apply_cast_effect( player : Player ) -> void:
	_direction = scale.x if scale.x != 0.0 else ( -1.0 if player.sprite_2d.flip_h else 1.0 )

	if hazard_area:
		# breakable_layer is included so it still gets damaged — see _on_hit,
		# which is what actually decides whether a given layer stops flight.
		hazard_area.collision_mask = (
			( 1 << ( terrain_layer - 1 ) )
			| ( 1 << ( enemy_layer - 1 ) )
			| ( 1 << ( breakable_layer - 1 ) )
		)
		hazard_area.body_entered.connect( _on_hit )
		hazard_area.area_entered.connect( _on_hit )
	else:
		push_warning( "SpellProjectile: no HazardArea child found — needs one to hit anything or ever despawn on contact." )

	if effect_animation_player and effect_animation_player.has_animation( flight_animation ):
		effect_animation_player.play( flight_animation )


func _physics_process( delta : float ) -> void:
	global_position.x += _direction * speed * delta


## Whatever tripped hazard_area's mask — terrain, an enemy's DamageArea, or
## a breakable's DamageArea. Damage delivery to a real target already
## happened via AttackArea's own body_entered/area_entered handling
## (connected in its _ready(), independently of this) — this listener only
## decides whether the flight itself should end here, and (once it does)
## plays the impact effect via _stop_and_play_hit().
func _on_hit( node : Node2D ) -> void:
	# Terrain set up as a TileMapLayer reports the layer itself as the
	# colliding body, and TileMapLayer isn't a CollisionObject2D — it has no
	# get_collision_layer_value at all. Anything like that can only be
	# terrain here (breakables/enemies are DamageAreas, which are
	# CollisionObject2D).
	if node is CollisionObject2D and node.get_collision_layer_value( breakable_layer ):
		# Damaged already via AttackArea's own handling. Unless it's ALSO on
		# enemy_layer (falls through to the stop+hit-effect path below, same
		# as any other enemy hit), a breakable doesn't stop the bolt — it
		# keeps flying through, silently, same as before.
		if not node.get_collision_layer_value( enemy_layer ):
			return

	# A hit reaching here isn't necessarily real terrain — a breakable's own
	# solid shell (StaticBody2D/CharacterBody2D, kept on terrain_layer so it
	# still physically blocks the player, e.g. falling_rock.gd) reports the
	# same layer as an actual wall, and depending on approach angle the
	# projectile can reach that shell instead of (or before) the breakable's
	# own DamageArea. AttackArea's own hit handling only ever damages a
	# DamageArea overlap directly — it has no idea this solid body has one
	# attached — so without this, a shell hit like that would stop and play
	# the impact effect below with no damage ever reaching the breakable.
	# Route it to the sibling DamageArea first, same as a direct hit would.
	if node is CollisionObject2D and not ( node is DamageArea ):
		var sibling : DamageArea = _find_breakable_sibling( node )
		if sibling and not _hit_damage_areas.has( sibling ):
			_hit_damage_areas.append( sibling )
			sibling.take_damage( hazard_area )
			hazard_area.hit_target.emit( sibling )

	await _stop_and_play_hit()


## Looks for a DamageArea sibling of `node` that's actually on
## breakable_layer — i.e. "is this solid body's parent also a breakable",
## not just any DamageArea (an enemy's own DamageArea sibling of its body
## should still stop the bolt as a normal enemy hit, not get treated as a
## breakable).
func _find_breakable_sibling( node : Node2D ) -> DamageArea:
	var parent : Node = node.get_parent()
	if not parent:
		return null
	for c in parent.get_children():
		if c is DamageArea and c.get_collision_layer_value( breakable_layer ):
			return c
	return null


## Stops the flight and plays the impact effect, then despawns. Pulled out
## of _on_hit() so both the plain "hit terrain/an enemy" case and the
## "actually a breakable's shell" case above share one landing sequence.
func _stop_and_play_hit() -> void:
	if _stopped:
		return
	_stopped = true

	if hazard_area:
		hazard_area.queue_free()
	speed = 0

	if hit_sfx:
		Audio.play_spatial_sound( hit_sfx, global_position, false, true, 0.5 )

	if effect_animation_player and effect_animation_player.has_animation( hit_animation ):
		effect_animation_player.play( hit_animation )
		await effect_animation_player.animation_finished

	queue_free()
