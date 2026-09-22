class_name PlayerCamera extends Camera2D

@onready var player : Player = get_parent()

var shake_strength : float = 0.0
@export var shake_decay_rate : float = 5.0
@export var max_shake_offset : float = 20.0

@export_category("Look Offset")
@export var look_offset_distance_down : float = 150.0  # approx half a screen — tune to your viewport height
@export var look_offset_distance_up : float = 75.0
@export var look_offset_speed : float = 2.0             # higher = snappier ease toward/away from the target
var _look_offset_y : float = 0.0
var _look_target_y : float = 0.0

@export_category("Movement Look Ahead")
## How far (px) the camera leans ahead of the player while moving at full
## move_speed, either direction — scales down smoothly as speed drops, so
## standing still or only moving a little eases back to centered on its
## own, no separate deadzone needed. Driven directly by player.velocity.x
## every frame, so it applies the same whether running, jumping, or falling.
@export var move_look_ahead_distance : float = 64.0
@export var move_look_ahead_speed : float = 2.0
var _move_look_offset_x : float = 0.0

@export_category("Focus")
## Ease speed used by focus_on() / return_to_player() below.
@export var focus_speed : float = 2.0
var _focus_target : Node2D = null
var _focus_offset : Vector2 = Vector2.ZERO

@export_category("Level Bounds")
## Whichever LevelBounds (from LevelBounds.GROUP) currently has the camera's
## limits — see _update_level_bounds(). Lets one scene hold several
## differently-shaped "rooms" without a level transition between them:
## nothing to place per room beyond the LevelBounds nodes that already exist
## for the camera clamp itself. A LevelBounds with auto_detect = false
## (e.g. BossBattleOrchestrator's own, script-driven ones) is never in the
## group and so is never picked up here — those keep working exactly as
## they do today, entirely separately from this.
var _active_bounds : LevelBounds = null


func _ready() -> void:
	VisualEffects.camera_shook.connect( _apply_shake )
	SceneManager.new_scene_ready.connect( _on_scene_transition )
	pass


func _process( delta: float ) -> void:
	_update_level_bounds()

	# Frame-rate independent ease — approaches the target smoothly without
	# overshoot regardless of delta, and never snaps.
	_look_offset_y = lerp( _look_offset_y, _look_target_y, 1.0 - exp( -look_offset_speed * delta ) )

	# Horizontal look-ahead — leans toward whichever direction the player is
	# actually moving, proportional to how fast (full lean at full
	# move_speed), so it eases back to centered on its own once they stand
	# still or only move a little. Not tied to any particular PlayerState,
	# so it applies the same on the ground, jumping, or falling.
	var move_intensity : float = clamp( absf( player.velocity.x ) / maxf( player.move_speed, 0.01 ), 0.0, 1.0 )
	var move_target_x : float = signf( player.velocity.x ) * move_look_ahead_distance * move_intensity
	_move_look_offset_x = lerp( _move_look_offset_x, move_target_x, 1.0 - exp( -move_look_ahead_speed * delta ) )

	# Focus override — while a focus target is set, eases toward staying
	# centered on it instead of the player. Recomputed fresh every frame (not
	# a one-time snapshot), so it keeps tracking the same world point even as
	# the player — and therefore this camera's own base position — moves.
	var focus_target_offset : Vector2 = Vector2.ZERO
	if _focus_target and is_instance_valid( _focus_target ):
		focus_target_offset = _focus_target.global_position - global_position
	_focus_offset = lerp( _focus_offset, focus_target_offset, 1.0 - exp( -focus_speed * delta ) )

	var shake_offset := Vector2(
			randf_range( -shake_strength, shake_strength ),
			randf_range( -shake_strength, shake_strength )
		)
	offset = shake_offset + Vector2( _move_look_offset_x, _look_offset_y ) + _focus_offset
	shake_strength = lerp( shake_strength, 0.0, shake_decay_rate * delta )
	pass


func _apply_shake( strength : float ) -> void:
	shake_strength = min( strength, max_shake_offset )
	pass


## Starts easing the camera to an arbitrary vertical offset. Shared entry
## point for anything that wants to nudge the view — look_up/down below,
## and Jump/Fall's own pan.
func pan_to( offset_y : float ) -> void:
	_look_target_y = offset_y
	pass
## Starts easing the camera down by look_offset_distance_down.
func pan_down() -> void:
	pan_to( look_offset_distance_down )
## Starts easing the camera up by look_offset_distance_up.
func pan_up() -> void:
	pan_to( -look_offset_distance_up )
## Starts easing the camera back to centered on the player.
func pan_reset() -> void:
	pan_to( 0.0 )


## Eases the camera to stay centered on `point` instead of the player, and
## keeps tracking it every frame until return_to_player() is called.
## Intended to be driven by an Area2D (see camera_focus_area.gd): call this
## on body_entered with whatever point of interest that area should
## highlight, and call return_to_player() on body_exited.
func focus_on( point : Node2D ) -> void:
	_focus_target = point


## Eases the camera back onto the player, cancelling any active focus_on().
func return_to_player() -> void:
	_focus_target = null


func _on_scene_transition( _t, _o ) -> void:
	reset_smoothing.call_deferred()
	# Don't carry a held look-offset, movement lean, or focus target into a
	# freshly loaded scene.
	pan_reset()
	_look_offset_y = 0.0
	_move_look_offset_x = 0.0
	_focus_target = null
	_focus_offset = Vector2.ZERO
	# Whatever bounds was active belonged to the scene that just got
	# replaced — the new scene's own set_on_ready LevelBounds is what's
	# responsible for camera limits at load, same as before this existed;
	# forget the old one so _update_level_bounds() below re-adopts fresh
	# instead of comparing against a freed node.
	_active_bounds = null
	pass


## Keeps _active_bounds pointed at whichever LevelBounds (from
## LevelBounds.GROUP) currently contains the player, switching — smoothly,
## once one's already been established — whenever they leave its rect for
## another's.
func _update_level_bounds() -> void:
	if _active_bounds and is_instance_valid( _active_bounds ) and _active_bounds.contains_point( player.global_position ):
		return

	for b in get_tree().get_nodes_in_group( LevelBounds.GROUP ):
		if b is LevelBounds and b.contains_point( player.global_position ):
			# Snap (no tween) the very first time a bounds is adopted after a
			# scene load (_active_bounds was null) — only smooth for a real
			# room-to-room crossing afterward.
			#
			# This USED to skip calling set_camera_bounds() entirely on that
			# first adoption, on the assumption that whichever LevelBounds
			# the player happens to land in already applied its own limits
			# via its set_on_ready _ready(). That's only true for the ONE
			# bounds in the scene that actually has set_on_ready checked
			# (normally the scene's "main"/default room). If the player's
			# real position after a respawn/load/save-reload — e.g. a
			# checkpoint that sits in a second room of a multi-room scene —
			# lands inside a DIFFERENT auto-detect LevelBounds instead, that
			# room's limits were never applied by anyone: _active_bounds got
			# silently pointed at it while the camera stayed clamped to
			# whatever the default room (or Camera2D's own defaults) left
			# it at — indistinguishable from the camera being stuck. Calling
			# set_camera_bounds() unconditionally here fixes that regardless
			# of which room the player actually starts in.
			b.set_camera_bounds( _active_bounds != null )
			_active_bounds = b
			return
	pass
