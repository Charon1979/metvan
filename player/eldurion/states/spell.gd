@icon("uid://clik7pjgto8k4")
class_name PlayerStateSpell
extends PlayerState

## Deliberately thin — this state's only job is to play whichever animations
## and sounds the equipped spell names for the CASTER (player.animation_player's
## cast_animation/fail_animation, plus the optional caster_animation/
## caster_sfx overlay on spell_anim — see enter()), root the player and lock
## facing for its duration, and hand off to run/idle once the animation
## ends. Everything the spell EFFECT itself does (its own animation, vfx,
## sfx, resource cost) is entirely SpellCast's own responsibility, triggered
## once the cast animation actually finishes — not when it starts.
##
## The equipped spell itself lives on the player as a persistent "equip
## slot" instance (player.equipped_spell) that's never added to the scene
## tree — see Player.equipped_spell_scene — so its cast_animation/
## resource_cost/fail_animation are cheaply readable straight off it with
## no instantiate-to-peek step. Actually casting duplicate()s that instance
## into a fresh, independent one, added to the tree and told to cast() only
## once animation_finished fires, in _on_animation_finished() below — the
## equip slot itself is never touched or freed.
##
## Casting is only possible with a spell equipped — idle/run gate entry into
## this state on `player.equipped_spell` being non-null (see their
## handle_input), so until that's set (via Player.equip_spell() or its
## equipped_spell_scene export), "action" simply does nothing.

## Own independent cooldown timer (player.spell_cooldown_timer /
## can_cast() / start_spell_cooldown()) — being on spell cooldown doesn't
## block melee and vice versa, same as every other attack-style cooldown.
## Only actually armed if a cast really happened — see exit().
@export var cast_cooldown_duration : float = 0.5

## The CASTER's own overlay AnimationPlayer — separate from
## player.animation_player (body pose: idle/run/cast_animation/
## fail_animation) and from the spell effect's own effect_animation_player
## (the packed scene playing e.g. flight_animation once airborne). Plays
## equipped.caster_animation, if the equipped spell names one — see enter().
@onready var spell_anim: AnimationPlayer = $"../../SpellAnim"

var finished : bool = false

# True once we've committed to this cast attempt (equipped + affordable) —
# not on a fizzle (nothing equipped, or not enough resource). Gates both
# the animation_finished disconnect and the cooldown in exit(), so a
# fizzled attempt costs nothing and doesn't lock the player out of trying
# again immediately. Set true up front, independently of whether the
# animation ever actually reaches its end — an interrupted cast (e.g. the
# player is hurt mid-animation) still committed to the attempt and still
# gets the cooldown, same as an interrupted melee combo. It just never
# actually fires — see exit()'s cleanup of _pending_instance.
var _cast_happened : bool = false

# Separate from _cast_happened — this just tracks whether enter() connected
# animation_finished this time (true for both a real cast AND a fail-
# animation fizzle, since both need the connection to know when to leave
# this state), so exit() always disconnects cleanly regardless of which
# path was taken.
var _animation_connected : bool = false

# duplicate() of player.equipped_spell, made once the cast animation starts
# so it reflects whatever was equipped at that moment — but not added to
# the tree or told to cast() until _on_animation_finished(). The spell only
# actually fires once the cast animation reaches its end.
var _pending_instance : SpellCast = null


func enter() -> void:
	finished = false
	_cast_happened = false
	_animation_connected = false
	_pending_instance = null

	if not player.equipped_spell:
		# idle/run already gate on this, but stay safe if entered any other way.
		finished = true
		return

	var equipped : SpellCast = player.equipped_spell

	if player.resource_current < equipped.resource_cost:
		# Can't afford it — no resource spent, no cast happens, but play the
		# fail animation instead of silently doing nothing. equipped is the
		# persistent equip slot itself, so there's nothing to free here.
		var fail_anim : StringName = equipped.fail_animation
		player.direction_locked = false
		player.update_direction()
		player.direction_locked = true
		player.animation_player.play( fail_anim )
		player.animation_player.animation_finished.connect( _on_animation_finished )
		_animation_connected = true
		return

	# Facing can't change mid-cast — unlock, resample fresh, relock, right as
	# the cast actually starts. Same idiom as every melee attack.
	player.direction_locked = false
	player.update_direction()
	player.direction_locked = true

	# Caster-side presentation — the character's own overlay animation and
	# incantation sound, both named on the equipped spell but distinct from
	# cast_animation/cast_sfx (which belong to the effect, not the caster).
	# Only reached on a real cast, never on the fail_animation branch above.
	if equipped.caster_animation != &"" and spell_anim.has_animation( equipped.caster_animation ):
		spell_anim.play( equipped.caster_animation )
	if equipped.caster_sfx:
		# was_player = true: enemies can hear this via player_sensor.gd,
		# same as any other player-made sound.
		Audio.play_spatial_sound( equipped.caster_sfx, player.global_position, false, true, 0.5 )

	player.animation_player.play( equipped.cast_animation )
	player.animation_player.animation_finished.connect( _on_animation_finished )
	_animation_connected = true

	# duplicate() rather than instantiating equipped_spell_scene again, so
	# the live instance starts from whatever's actually set on the equip
	# slot right now. Not added to the tree yet — see
	# _on_animation_finished() — so its @onready children/HazardArea etc.
	# haven't activated and won't until it actually gets added.
	_pending_instance = equipped.duplicate()
	_cast_happened = true


func exit() -> void:
	if _animation_connected and player.animation_player.animation_finished.is_connected( _on_animation_finished ):
		player.animation_player.animation_finished.disconnect( _on_animation_finished )
	player.direction_locked = false
	if _cast_happened:
		player.start_spell_cooldown( cast_cooldown_duration )
	# Interrupted before the animation ever finished (e.g. took damage
	# mid-cast) — the spell never actually fired, so don't leave an
	# instantiated-but-never-used instance dangling.
	if _pending_instance:
		_pending_instance.queue_free()
		_pending_instance = null


func handle_input( _event : InputEvent ) -> PlayerState:
	# No commands accepted mid-cast.
	return null


func process( _delta : float ) -> PlayerState:
	if finished:
		return ( run if player.direction.x != 0 else idle ) as PlayerState
	return null


func physics_process( _delta : float ) -> PlayerState:
	# Fully rooted for the cast's duration.
	player.velocity.x = 0.0
	return next_state


func _on_animation_finished( _anim_name : String ) -> void:
	if _pending_instance:
		player.get_tree().root.add_child( _pending_instance )
		_pending_instance.cast( player )
		_pending_instance = null
	finished = true
