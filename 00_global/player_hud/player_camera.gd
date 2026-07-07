class_name PlayerCamera extends Camera2D

var shake_strength : float = 0.0
@export var shake_decay_rate : float = 5.0
@export var max_shake_offset : float = 20.0

@export_category("Look Offset")
@export var look_offset_distance_down : float = 150.0  # approx half a screen — tune to your viewport height
@export var look_offset_distance_up : float = 75.0
@export var look_offset_speed : float = 2.0             # higher = snappier ease toward/away from the target

var _look_offset_y : float = 0.0
var _look_target_y : float = 0.0

func _ready() -> void:
	VisualEffects.camera_shook.connect( _apply_shake )
	SceneManager.new_scene_ready.connect( _on_scene_transition )
	pass

func _process( delta: float ) -> void:
	# Frame-rate independent ease — approaches the target smoothly without
	# overshoot regardless of delta, and never snaps.
	_look_offset_y = lerp( _look_offset_y, _look_target_y, 1.0 - exp( -look_offset_speed * delta ) )

	var shake_offset := Vector2(
			randf_range( -shake_strength, shake_strength ),
			randf_range( -shake_strength, shake_strength )
		)
	offset = shake_offset + Vector2( 0.0, _look_offset_y )
	shake_strength = lerp( shake_strength, 0.0, shake_decay_rate * delta )
	pass

func _apply_shake( strength : float ) -> void:
	shake_strength = min( strength, max_shake_offset )
	pass

## Starts easing the camera down by look_offset_distance_down.
func pan_down() -> void:
	_look_target_y = look_offset_distance_down

## Starts easing the camera up by look_offset_distance_up.
func pan_up() -> void:
	_look_target_y = -look_offset_distance_up

## Starts easing the camera back to centered on the player.
func pan_reset() -> void:
	_look_target_y = 0.0

func _on_scene_transition( _t, _o ) -> void:
	reset_smoothing.call_deferred()
	# Don't carry a held look-offset into a freshly loaded scene.
	pan_reset()
	_look_offset_y = 0.0
	pass
