@tool
class_name WaterArea
extends Area2D

#region /// current (physics + conveyor belt)

## Direction the current pushes/accelerates the player. Also pushed to the
## assigned material as shader param "flow_direction", if it's a ShaderMaterial.
@export var flow_direction : Vector2 = Vector2.RIGHT :
	set(value):
		flow_direction = value
		_update_shader_params()

## Acceleration (units/sec²) applied to the player while submerged, only when current_enabled is true.
@export var flow_strength : float = 150.0

## Caps how fast the current alone can push the player.
@export var max_flow_speed : float = 220.0

## Turn off for standing/still water — no push at all. Shader still receives
## flow_direction = Vector2.ZERO so a direction-aware shader can go idle too.
@export var current_enabled : bool = true :
	set(value):
		current_enabled = value
		_update_shader_params()

#endregion


#region /// size (tool-editable)

## Area2D's own position is treated as the TOP-LEFT corner of the water rect,
## growing right/down from there. Resizes the collision shape and visual live in the editor.
@export var area_size : Vector2 = Vector2(128.0, 64.0) :
	set(value):
		area_size = Vector2(max(value.x, 4.0), max(value.y, 4.0))
		_update_shape_and_visual()

#endregion


#region /// particles

## Enable/disable the one-shot splash burst on entering/exiting the water,
## independent of whether a SplashParticles node is assigned.
@export var enable_splash_particles : bool = true

## Enable/disable the continuous swimming emitter, independent of whether a
## MovementParticles node is assigned.
@export var enable_movement_particles : bool = true

## Local offset applied on top of the player's position when positioning
## MovementParticles each frame — e.g. Vector2(0, -16) to sit above the player.
@export var movement_particles_offset : Vector2 = Vector2.ZERO

#endregion


@onready var collision_shape : CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var visual : Sprite2D = get_node_or_null("Visual")

## One-shot burst on entering/exiting the water. Configure its own particle
## settings (texture, process_material, amount, etc.) directly on the node.
@onready var splash_particles : GPUParticles2D = get_node_or_null("SplashParticles")

## Continuous emitter that follows the player and only runs while they're
## actively swimming (their own input), not while merely drifting on the
## current. Configure its own particle settings directly on the node.
@onready var movement_particles : GPUParticles2D = get_node_or_null("MovementParticles")

var _current_player : Player = null


func _ready() -> void:
	set_collision_layer_value( 1, false )
	set_collision_mask_value( 1, false )
	set_collision_mask_value( 5, true )   # Player layer — matches PlayerSensor's convention

	_update_shape_and_visual()
	_update_shader_params()

	if Engine.is_editor_hint():
		return

	body_entered.connect( _on_body_entered )
	body_exited.connect( _on_body_exited )


func _physics_process( _delta : float ) -> void:
	if Engine.is_editor_hint():
		return
	if not movement_particles:
		return
	if not enable_movement_particles or not _current_player:
		movement_particles.emitting = false
		return
	movement_particles.global_position = _current_player.global_position + movement_particles_offset
	# direction.x != 0 means the player is actively pressing a movement key —
	# distinguishes "swimming" from "drifting with velocity the current gave them".
	movement_particles.emitting = _current_player.direction.x != 0


func _update_shape_and_visual() -> void:
	if collision_shape and collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = area_size
		collision_shape.position = area_size / 2.0
	if visual:
		visual.scale = area_size
		visual.position = Vector2.ZERO
	_update_shader_params()


func _update_shader_params() -> void:
	if not visual or not visual.material is ShaderMaterial:
		return
	var mat : ShaderMaterial = visual.material
	mat.set_shader_parameter( "area_size", area_size )
	mat.set_shader_parameter( "flow_direction", flow_direction if current_enabled else Vector2.ZERO )


func _on_body_entered( body : Node2D ) -> void:
	if body is Player:
		_current_player = body
		_spawn_splash( body.global_position.x )
		_apply_current( body )


func _on_body_exited( body : Node2D ) -> void:
	if body is Player:
		_spawn_splash( body.global_position.x)
		_clear_current( body )
		if _current_player == body:
			_current_player = null
			if movement_particles:
				movement_particles.emitting = false


func _apply_current( player : Player ) -> void:
	if current_enabled:
		player.water_current = flow_direction.normalized() * flow_strength
		player.water_max_speed = max_flow_speed
	else:
		player.water_current = Vector2.ZERO
		player.water_max_speed = -1.0


func _clear_current( player : Player ) -> void:
	player.water_current = Vector2.ZERO
	player.water_max_speed = -1.0


func _spawn_splash( x_position : float ) -> void:
	if not enable_splash_particles or not splash_particles:
		return
	splash_particles.global_position = Vector2( x_position, global_position.y)
	splash_particles.restart()
	splash_particles.emitting = true


func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []
	if not collision_shape or not collision_shape.shape is RectangleShape2D:
		warnings.append("Requires a CollisionShape2D child named 'CollisionShape2D' with a RectangleShape2D — size gets driven by area_size.")
	if not visual:
		warnings.append("Requires a Sprite2D child named 'Visual' — assign your water ShaderMaterial to it manually; position/scale get driven by area_size.")
	if not splash_particles:
		warnings.append("Requires a GPUParticles2D child named 'SplashParticles' (jump in/out burst) — configure its own particle settings directly on the node.")
	if not movement_particles:
		warnings.append("Requires a GPUParticles2D child named 'MovementParticles' (follows the player while swimming) — configure its own particle settings directly on the node.")
	return warnings
