@tool
@icon( "uid://b6ehphsersdx3" )
class_name LevelBounds extends Node2D

## Group every auto_detect LevelBounds joins at runtime — how PlayerCamera's
## auto-detect (player_camera.gd) finds every room-shape sharing this scene
## to check the player's position against, without a manually-placed trigger
## area that would need to be kept in sync with width/height by hand.
const GROUP : StringName = "level_bounds"

@export_range( 352, 2048, 32, "suffix:px" ) var width : int = 480 : set = _on_width_changed
@export_range( 256, 2048, 32, "suffix:px" ) var height : int = 256 : set = _on_height_changed

@export var set_on_ready : bool = true : set = _on_bool_changed

## Whether PlayerCamera's auto-detect is allowed to switch TO this bounds
## on its own, purely because the player's position ends up inside its rect.
## Leave this on for ordinary rooms sharing one scene — that's the whole
## point. Turn it OFF for a bounds whose activation is driven by a script
## instead of plain position — e.g. BossBattleOrchestrator's
## boss_level_bounds/original_level_bounds, which can legitimately overlap a
## normal room's rect and are switched to explicitly by that script at a
## specific story beat (arena entered / boss defeated), not by the player
## merely wandering into their rect.
@export var auto_detect : bool = true

## Used only when set_camera_bounds() is called with smooth = true (e.g. the
## boss arena frame activating mid-level, or PlayerCamera's auto-detect
## crossing from one room's bounds into another's) — how long the camera
## limits take to ease into their new values instead of snapping instantly.
## Left unused for the normal set_on_ready path at level load, where there's
## no existing camera position to jar.
@export_range( 0.0, 3.0, 0.05, "suffix:s" ) var camera_transition_duration : float = 0.6

## static, not per-instance: set_camera_bounds() writes straight to the
## viewport's ONE shared Camera2D, so with multiple LevelBounds now able to
## trigger a transition (PlayerCamera's auto-detect, or several rooms
## crossed in quick succession), an instance-level _bounds_tween would only
## ever cancel THIS node's own previous tween — not some OTHER LevelBounds'
## still-running one — leaving two tweens fighting over the same limit_*
## properties at once. One shared tween means starting a new transition
## always cancels whichever one is currently running, regardless of which
## LevelBounds started it. Requires Godot 4.2+ (static var support).
static var _bounds_tween : Tween

func _ready() -> void:
	z_index = 256

	if Engine.is_editor_hint():
		return

	if auto_detect:
		add_to_group( GROUP )

	if not set_on_ready:
		return

	set_camera_bounds()
	pass

func set_camera_bounds( smooth : bool = false ) -> void:
	var _camera : Camera2D = null

	while not _camera:
		await get_tree().process_frame
		# Failsafe: if this node was freed/detached while waiting (e.g. a
		# scene reload — such as SceneManager.transition_scene() on player
		# death — swapping out the scene this LevelBounds belongs to before
		# a camera ever showed up), get_viewport() returns null and calling
		# get_camera_2d() on it crashes. Bail out quietly instead — there's
		# nothing left here to set bounds on.
		if not is_inside_tree():
			return
		var viewport : Viewport = get_viewport()
		if not viewport:
			return
		_camera = viewport.get_camera_2d()

	var target_left : int = int( global_position.x )
	var target_top : int = int( global_position.y )
	var target_right : int = int( global_position.x ) + width
	var target_bottom : int = int( global_position.y ) + height

	if _bounds_tween:
		_bounds_tween.kill()

	if smooth and camera_transition_duration > 0.0:
		# Ease the limits into place instead of snapping — a hard, instant
		# change (e.g. the boss arena frame kicking in while the player is
		# already standing well inside the old bounds) makes Camera2D clamp
		# the view into the new limit on the very next frame, which reads as
		# a jump cut. Tweening the limit values themselves means that clamp
		# gets applied a little at a time, so the camera pans smoothly
		# instead.
		_bounds_tween = create_tween()
		_bounds_tween.set_parallel( true )
		_bounds_tween.tween_property( _camera, "limit_left", target_left, camera_transition_duration )
		_bounds_tween.tween_property( _camera, "limit_top", target_top, camera_transition_duration )
		_bounds_tween.tween_property( _camera, "limit_right", target_right, camera_transition_duration )
		_bounds_tween.tween_property( _camera, "limit_bottom", target_bottom, camera_transition_duration )
	else:
		_camera.limit_left = target_left
		_camera.limit_top = target_top
		_camera.limit_right = target_right
		_camera.limit_bottom = target_bottom

	pass


## World-space rect this bounds occupies — the exact same rect
## set_camera_bounds() above turns into limit_left/top/right/bottom. Used by
## PlayerCamera's auto-detect to figure out which LevelBounds the player is
## currently standing inside, so that rect is the single source of truth
## for both "what can the camera see" and "which room is this" — nothing
## else to keep in sync when you resize one.
func get_rect() -> Rect2:
	return Rect2( global_position, Vector2( width, height ) )


func contains_point( point : Vector2 ) -> bool:
	return get_rect().has_point( point )


func _draw() -> void:
	if Engine.is_editor_hint():
		var r : Rect2 = Rect2( Vector2.ZERO, Vector2( width, height ) )
		draw_rect( r, Color( 0.0, 0.45, 1.0, 0.6 ), false, 3 )
		draw_rect( r, Color( 0.0, 0.75, 1.0 ), false, 1 )
	
	if not set_on_ready and Engine.is_editor_hint():
		var r : Rect2 = Rect2( Vector2.ZERO, Vector2( width, height ) )
		draw_rect( r, Color(1.0, 0.3, 0.0, 0.6), false, 3 )
		draw_rect( r, Color( 1.0, 0.4, 0.0, 1.0 ), false, 1 )
	pass
func _on_width_changed( new_width : int ) -> void:
	width = new_width
	queue_redraw()
	pass
func _on_height_changed( new_height : int ) -> void:
	height = new_height
	queue_redraw()
	pass

func _on_bool_changed( new_value : bool ) -> void:
	set_on_ready = new_value
	queue_redraw()
	pass
