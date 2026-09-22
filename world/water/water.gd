@tool

extends Node2D
class_name DynamicWater2D

## controls which node to use for pulling the top left corner of the water from.
@export var top_left_marker: Node2D
## controls which node to use for pulling the bottom right corner of the water from.
@export var bottom_right_marker: Node2D

@export_group("visuals")
## controls the thickness of the surface water.
@export var surface_thickness: float = 6.0
## controls the color of the water on the surface.
@export var surface_color: Color = Color("2c998e66")
## controls the color of the water below the surface.
@export var water_color: Color = Color("87e0d733")

@export_group("waves")
## enables or disables passive waves.
@export var waves_enabled: bool = true
## controls how high the passive waves are.
@export var wave_height: float = 4.0
## controls how quick the passive waves are.
@export var wave_speed: float = 4.0
## controls how wide the passive waves are.
@export var wave_width: float = 16.0
## controls how many times forces should be calculated between neighbouring points per frame.
## higher values means waves travel faster.
@export var wave_spread_amount: int = 4

@export_group("points")
## controls how many surface points are created per nth unit of distance.
## this is basically the "resolution" of the surface water.
@export_range(2, 32, 2) var point_per_distance: int = 8
## controls the damping that will be applied to all points each frame.
## lower value will cause motion to die out quicker.
@export_range(0.0, 1.0) var point_damping = 0.98
## controls the stiffness between a point and it's resting y pos.
@export var point_independent_stiffness: float = 1.0
## controls the stiffness between neighbouring points.
## higher values mean motion is transferred between points quicker.
@export var point_neighbouring_stiffness: float = 2.0

## direction options for the steady current system. NONE applies no horizontal push.
enum CurrentDirection { NONE, LEFT, RIGHT }

@export_group("current")
## controls which steady direction (if any) this body of water pushes bodies in.
@export var current_direction: CurrentDirection = CurrentDirection.NONE
## controls the strength of the steady current push, in px/sec.
@export var current_strength: float = 60.0
## clamps the horizontal speed a body can reach purely from the current. -1 = no clamp.
@export var current_max_speed: float = -1.0

@export_group("swim")
## if true, any body that enters this water gets its `swim_enabled` flag set to true
## while submerged (and back to false on exit). the swim *state* itself is implemented
## on the character side — this just toggles the flag.
@export var enable_swim: bool = false

@export_group("particles")
## one-shot particles fired when a body enters or exits the water (splash).
@export var splash_particles: GPUParticles2D
## continuous particles that follow a body while it's actively moving through the water.
@export var movement_particles: GPUParticles2D
## minimum speed (px/sec) before movement particles start emitting.
@export var movement_particle_speed_threshold: float = 20.0

@export_group("distortion")
## shader material (see distortion.gdshader) applied to this node's canvas item while active.
@export var distortion_material: ShaderMaterial
## toggles the distortion shader on/off at runtime.
@export var distortion_enabled: bool = true:
	set(value):
		distortion_enabled = value
		_update_distortion()

@onready var water_area: Area2D = $WaterArea if has_node("WaterArea") else null

var top_left_point: Vector2
var top_right_point: Vector2
var bottom_right_point: Vector2
var bottom_left_point: Vector2
var extents_valid: bool = false
var _missing_markers_warned: bool = false

var points_positions: PackedVector2Array = PackedVector2Array([])
var points_motions: PackedVector2Array = PackedVector2Array([])

## bodies currently inside the water area. maps body -> true (used as a set).
var bodies_in_water: Dictionary = {}

func point_add(pos: Vector2) -> void:
	points_positions.append(pos)
	points_motions.append(Vector2.ZERO)

func points_size() -> int:
	return points_positions.size()

func points_clear() -> void:
	points_positions.clear()
	points_motions.clear()

func point_global_pos(point_idx: int) -> Vector2:
	return position + points_positions[point_idx]

## add some motion (force) to a given point.
func point_add_motion(point_idx: int, d: Vector2) -> Vector2:
	var motion := points_motions[point_idx]; motion += d
	points_motions[point_idx] = motion
	return d

func _point_calc_motion(point_idx: int, target_y: float, stiffness: float) -> void:
	var target_point := Vector2(point_global_pos(point_idx).x, target_y)
	var motion := (target_point - point_global_pos(point_idx)) * stiffness
	points_motions[point_idx] += motion

func _point_calc_physics(point_idx: int, delta: float) -> void:
	var motion := points_motions[point_idx]
	var pos := points_positions[point_idx]
	# surface points are only ever meant to bounce vertically — their x spacing is
	# fixed at creation time by calc_surface_points(). apply_force() (used by splashes
	# and the current) computes a direction-based force that can include an x
	# component; if that were allowed to move a point's x, points could drift past
	# their neighbours and produce a self-intersecting polygon that draw_polygon()
	# can't triangulate ("Invalid polygon data, triangulation failed"). so only the
	# y component of motion is ever integrated into position.
	pos.y += motion.y * delta
	motion *= point_damping
	points_motions[point_idx] = motion
	points_positions[point_idx] = pos

func _points_get_circle(origin: Vector2, radius: float) -> Array[int]:
	var results: Array[int] = []
	# convert global coords to local coords
	var local_pos := to_local(origin)
	# find the furthest positions that could be affected to the left and right
	var left_most := local_pos.x - radius
	var right_most := local_pos.x + radius
	# convert those local positions to indices in the "points" array
	var left_most_index := _get_index_from_local_pos(left_most)
	var right_most_index := _get_index_from_local_pos(right_most)
	# test which points are in the circle provided
	for idx in range(left_most_index, right_most_index + 1):
		var point_pos := points_positions[idx]
		var dx := absf(point_pos.x - origin.x)
		var dy := absf(point_pos.y - origin.y)
		if dx + dy <= radius:
			results.append(idx); continue
		if dx ** 2 + dy ** 2 <= radius ** 2:
			results.append(idx); continue
	return results


func _ready() -> void:
	calc_extents()
	calc_surface_points()
	_sync_water_area_shape()
	_update_distortion()
	if water_area:
		water_area.body_entered.connect(_on_body_entered)
		water_area.body_exited.connect(_on_body_exited)
	else:
		push_warning("DynamicWater2D: no 'WaterArea' Area2D child found — current/swim/splash detection is disabled.")
	if movement_particles:
		# movement_particles' global_position is updated every frame to follow whoever's
		# swimming. with local_coords enabled (the GPUParticles2D default), already-emitted
		# particles simulate relative to the emitter's transform, so they'd get dragged along
		# too — collapsing the whole trail onto the current position instead of trailing behind.
		# forcing world-space simulation keeps emitted particles where they were emitted.
		movement_particles.local_coords = false


## calculates the extents of the water.
func calc_extents() -> void:
	if not top_left_marker or not bottom_right_marker:
		extents_valid = false
		if not _missing_markers_warned:
			push_warning("DynamicWater2D: 'top_left_marker' and/or 'bottom_right_marker' aren't assigned yet — skipping until they are.")
			_missing_markers_warned = true
		return
	_missing_markers_warned = false

	top_left_point = top_left_marker.position
	bottom_right_point = bottom_right_marker.position
	extents_valid = _validate_extents()
	if not extents_valid:
		push_error("invalid extents: top left corner cannot be bigger or equal on the X or Y axis than the bottom right corner")
		return
	top_right_point = Vector2(bottom_right_point.x, top_left_point.y)
	bottom_left_point = Vector2(top_left_point.x, bottom_right_point.y)


func _validate_extents() -> bool:
	var is_x_axis_valid := top_left_point.x < bottom_right_point.x
	var is_y_axis_valid := top_left_point.y < bottom_right_point.y
	return is_x_axis_valid and is_y_axis_valid


## calculates surface points.
func calc_surface_points() -> void:
	points_clear()
	if not extents_valid: return
	# populate the points arrays
	var point_amount := int(floor((top_right_point.x - top_left_point.x) / point_per_distance))
	for i in range(point_amount):
		var pos := Vector2(top_left_point.x + (point_per_distance * (i + 0.5)), top_left_point.y)
		point_add(pos)


func _process(delta: float) -> void:
	# update extents and recalculate surface points if any of our size markers change position
	if not top_left_marker or not bottom_right_marker:
		return
	if (not top_left_point.is_equal_approx(top_left_marker.position)
		or not bottom_right_point.is_equal_approx(bottom_right_marker.position)):
		calc_extents()
		calc_surface_points()
		_sync_water_area_shape()
	# only process if extents are valid
	if not extents_valid: return
	
	var target_y := global_position.y + top_left_point.y
	var points_len := points_size()
	for idx in range(points_len):
		# calculate motion for point
		_point_calc_motion(idx, target_y, point_independent_stiffness)
		# add the passive wave if enabled
		if waves_enabled:
			var time := fmod(float(Time.get_ticks_msec()) / 1000.0, PI * 2.0)
			point_add_motion(idx, Vector2.UP * sin(((idx / float(points_len)) * wave_width) + (time * wave_speed)) * wave_height)
		# calculate and apply spring forces between neighbouring points
		for j in range(wave_spread_amount):
			var apply_nforce: Callable = func(nidx: int) -> void:
				_point_calc_motion(idx, point_global_pos(nidx).y, point_neighbouring_stiffness)
			# to the left
			if idx - 1 >= 0: apply_nforce.call(idx - 1)
			# to the right
			if idx + 1 < points_len: apply_nforce.call(idx + 1)
	
	# run surface point physics
	for idx in range(points_len):
		_point_calc_physics(idx, delta)

	_update_movement_particles()

	queue_redraw()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# keep re-applying the current every physics frame so live edits to
	# current_direction / current_strength take effect immediately, and so the
	# player's `water_current` (which is expected to be refreshed while overlapping)
	# stays correct.
	for body in bodies_in_water.keys():
		if is_instance_valid(body):
			_apply_current(body)


## apply some force to provided position.
## will be applied as a circle, all points in the radius will be affected.
func apply_force(pos: Vector2, force: Vector2, radius: float = 16.0) -> void:
	# ignore if position outside of area
	if (point_global_pos(0).x - radius * 2) > pos.x or (point_global_pos(points_size() - 1).x + radius * 2) < pos.x:
		return
	var local_pos := to_local(pos)
	# get points around the pos
	var idxs := _points_get_circle(pos, radius)
	for idx in idxs:
		# direct force to the point
		force *= local_pos.direction_to(points_positions[idx])
		point_add_motion(idx, force)


func _get_index_from_local_pos(x: float) -> int:
	# returns an index of the "points" array on water's surface to the local pos
	var index = floor((abs(top_left_point.x - x) / (top_right_point.x - top_left_point.x)) * points_size())
	# ensure the index is a possible index of the array
	return int(clamp(index, 0, points_size() - 1))


#region /// body tracking: current, swim flag, splash

## keeps WaterArea's CollisionShape2D matched to the marker-defined extents.
## finds the first CollisionShape2D child of WaterArea (creating one if missing)
## and assigns/resizes a RectangleShape2D on it, so the shape never needs to be
## sized by hand in the editor — it always tracks top_left_marker / bottom_right_marker.
func _sync_water_area_shape() -> void:
	if not water_area or not extents_valid:
		return

	var shape_node: CollisionShape2D = null
	for child in water_area.get_children():
		if child is CollisionShape2D:
			shape_node = child
			break
	if not shape_node:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		water_area.add_child(shape_node)

	var rect_shape: RectangleShape2D
	if shape_node.shape is RectangleShape2D:
		rect_shape = shape_node.shape
	else:
		rect_shape = RectangleShape2D.new()
		shape_node.shape = rect_shape

	var size := bottom_right_point - top_left_point
	rect_shape.size = size
	shape_node.position = top_left_point + size * 0.5


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	bodies_in_water[body] = true

	var entry_velocity := Vector2.ZERO
	if body is CharacterBody2D:
		entry_velocity = body.velocity

	_apply_current(body)

	if "swim_enabled" in body:
		body.swim_enabled = enable_swim
	if "in_water" in body:
		body.in_water = true

	_spawn_splash(body, entry_velocity.y)


func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return
	if not bodies_in_water.has(body):
		return

	var exit_velocity := Vector2.ZERO
	if is_instance_valid(body) and body is CharacterBody2D:
		exit_velocity = body.velocity

	bodies_in_water.erase(body)

	if is_instance_valid(body):
		if "water_current" in body:
			body.water_current = Vector2.ZERO
		if "water_max_speed" in body:
			body.water_max_speed = -1.0
		if "swim_enabled" in body:
			body.swim_enabled = false
		if "in_water" in body:
			body.in_water = false

	# jumping out still deserves a splash, so treat exit as a splash-worthy event too
	_spawn_splash(body, exit_velocity.y)


func _apply_current(body: Node2D) -> void:
	if not ("water_current" in body):
		return
	match current_direction:
		CurrentDirection.LEFT:
			body.water_current = Vector2.LEFT * current_strength
		CurrentDirection.RIGHT:
			body.water_current = Vector2.RIGHT * current_strength
		_:
			body.water_current = Vector2.ZERO
	if "water_max_speed" in body:
		body.water_max_speed = current_max_speed


func _spawn_splash(body: Node2D, velocity_y: float) -> void:
	if not is_instance_valid(body):
		return

	# push the surface down (jumping in) or up (jumping/climbing out) at the body's x position
	var surface_y := global_position.y + top_left_point.y
	var push_dir := signf(velocity_y) if velocity_y != 0.0 else 1.0
	apply_force(Vector2(body.global_position.x, surface_y), Vector2.DOWN * push_dir * absf(velocity_y) * 0.5)

	if not splash_particles:
		return

	splash_particles.global_position = Vector2(body.global_position.x, surface_y)
	# scale the burst with how fast the body was moving vertically when it crossed the surface
	splash_particles.amount_ratio = clampf(absf(velocity_y) / 400.0, 0.25, 1.0)
	if splash_particles.process_material is ParticleProcessMaterial:
		# splashes always fan upward/outward regardless of enter vs exit
		splash_particles.process_material.direction = Vector3(0.0, -1.0, 0.0)
	splash_particles.restart()
	splash_particles.emitting = true


func _update_movement_particles() -> void:
	# this script is @tool, so _process runs in the editor too. never touch the
	# particle node's state outside of actual gameplay — otherwise any manual
	# "Emitting" toggle in the inspector gets reset the very next editor frame.
	if Engine.is_editor_hint():
		return
	if not movement_particles:
		return

	var active_body: Node2D = null
	var active_velocity := Vector2.ZERO

	for body in bodies_in_water.keys():
		if not is_instance_valid(body):
			continue
		if body is CharacterBody2D and body.velocity.length() > movement_particle_speed_threshold:
			active_body = body
			active_velocity = body.velocity
			break

	if active_body:
		var surface_y := global_position.y + top_left_point.y
		movement_particles.global_position = Vector2(active_body.global_position.x, surface_y)
		if movement_particles.process_material is ParticleProcessMaterial:
			# trail opposite the movement direction, like a wake — but keep the
			# vertical component dominant so this reads as "up" with a gentle lean,
			# rather than "sideways" (an equal-weighted x/-0.3y vector points mostly
			# sideways once normalized, which looked wrong regardless of inspector settings).
			var dir_x := -signf(active_velocity.x) if active_velocity.x != 0.0 else 0.0
			movement_particles.process_material.direction = Vector3(dir_x * 0.3, -1.0, 0.0)
		if not movement_particles.emitting:
			movement_particles.emitting = true
	else:
		if movement_particles.emitting:
			movement_particles.emitting = false

#endregion


func _update_distortion() -> void:
	material = distortion_material if (distortion_enabled and distortion_material) else null


func _draw() -> void:
	if not extents_valid: return
	
	var surface := PackedVector2Array([top_left_point])
	var polygon := PackedVector2Array([top_left_point])
	var colors := PackedColorArray([water_color])
	for idx in range(points_size()):
		surface.append(points_positions[idx])
		polygon.append(points_positions[idx])
		colors.append(water_color)
	
	surface.append(top_right_point)
	
	for p in [top_right_point, bottom_right_point, bottom_left_point]:
		polygon.append(p)
		colors.append(water_color)
	
	draw_polygon(polygon, colors)
	draw_polyline(surface, surface_color, surface_thickness, true)
