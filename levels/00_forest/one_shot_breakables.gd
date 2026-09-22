extends CharacterBody2D

## A wall/object that breaks open over a few hits (via `breakable`), handing
## off from a "not yet broken" interaction (interaction_pre — e.g. an
## "examine the cracked wall" hint) to a "now broken" one (interaction_post
## — e.g. stepping through the new opening) once fully destroyed. Whether
## it's already broken persists across scene reloads via SaveManager — see
## save_key below.
##
## How many hits it takes lives entirely on the Breakable child now — set
## its Hp to however many hits you want and check ON its Fixed Hit Count (so
## Hp counts hits, not raw damage). This script no longer has, or needs, a
## separate hit-count of its own: it just mirrors whatever Breakable reports
## onto the sprite's frame, and switches to the destroyed state the instant
## Breakable itself says it's done.

@onready var sprite: Sprite2D = $Sprite2D

@onready var debries: GPUParticles2D = $GPUParticles2D
@onready var breakable: Breakable = $Breakable
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D

## Shown while the object is still intact (e.g. an "examine" hint). Optional
## — leave unset in the Inspector if this object doesn't need one.
@export var interaction_pre : InteractionTrigger
## Enabled once the object is fully destroyed (e.g. "step through the
## opening"). Optional — leave unset if this object doesn't need one.
@export var interaction_post : InteractionTrigger

@export var object : Texture2D

## Persisted via SaveManager.persistent_key( self, save_key ) — same pattern
## as FallingRock/InteractionTrigger/SecretArea. Leave empty to auto-derive
## one from this node's path (fine as long as you don't reparent/rename this
## node); set it explicitly for a stable id regardless of scene position.
@export var save_key : String = ""

var destroyed : bool = false


func _ready() -> void:
	sprite.texture = object
	destroyed = SaveManager.persistent_data.get( _key(), false )
	if destroyed:
		_apply_destroyed_state()
	else:
		sprite.frame = 0
		if interaction_post:
			interaction_post.area_2d.monitoring = false
		breakable.damage_taken.connect( _on_damage_taken )
		breakable.destroyed.connect( _on_destroyed )


## Fires on every hit that Breakable itself doesn't consider lethal yet —
## advance the sprite by one damage frame as feedback. Breakable's own Hp
## (with Fixed Hit Count on) is what's actually being counted down here;
## this is purely "show the next frame".
func _on_damage_taken() -> void:
	sprite.frame += 1
	if animation_player and animation_player.has_animation( "damage" ):
		animation_player.play( "damage" )
	_spawn_debris_burst()


## `debries` is kept purely as a template now, never emitted directly — a
## single shared emitter can only play one burst at a time, so hits landing
## close together (or a very short "one hit per frame" attack) would cut the
## previous burst's particles off early. Spawning a fresh duplicate per hit
## lets overlapping bursts play out independently, and each one frees itself
## the moment it's done rather than sticking around. Requires the template's
## One Shot to be enabled — that's what makes `finished` actually fire.
func _spawn_debris_burst() -> void:
	var burst : GPUParticles2D = debries.duplicate()
	burst.position = debries.position
	burst.emitting = false
	add_child( burst )
	burst.restart()
	if not burst.finished.is_connected( burst.queue_free ):
		burst.finished.connect( burst.queue_free )


## Fires exactly once — on the hit that actually finishes Breakable off.
func _on_destroyed() -> void:
	_spawn_debris_burst()
	destroyed = true
	SaveManager.persistent_data[ _key() ] = true
	_apply_destroyed_state()


## Shared by _ready() (restoring a save where this was already broken) and
## _on_destroyed() (just now breaking it) — same end state either way, so
## there's exactly one place that defines what "destroyed" looks like.
func _apply_destroyed_state() -> void:
	if animation_player:
		if animation_player.has_animation( "destroyed" ):
			animation_player.play( "destroyed" )
		else:
			push_warning( "%s: AnimationPlayer has no \"destroyed\" animation — collision/interaction still swap over, but nothing will visually change." % get_path() )
	if breakable:
		breakable.queue_free()
	if interaction_pre:
		interaction_pre.queue_free()
	if interaction_post:
		interaction_post.area_2d.monitoring = true
	if collision:
		collision.queue_free()


func _key() -> String:
	if save_key.is_empty():
		save_key = str( get_path() )
	return SaveManager.persistent_key( self, save_key )
