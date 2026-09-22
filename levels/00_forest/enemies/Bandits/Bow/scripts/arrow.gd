class_name Arrow
extends Sprite2D

## Peak height of the arc above the straight line from start to landing point.
## Godot's Y grows downward, so this is subtracted, not added.
@export var arc_height : float = 40.0

## How long the flight from spawn to landing point takes.
@export var flight_duration : float = 0.5

## How long the arrow lingers, stuck, after hitting a wall/floor before despawning.
@export var despawn_delay : float = 5.0

## Optional — swapped onto the sprite automatically once the arrow sticks.
## Leave empty and handle the swap yourself in _on_stuck() if you'd rather.
@export var stuck_texture : Texture2D

@onready var hazard_area : HazardArea = get_node_or_null("HazardArea")
@onready var wall_detector : Area2D = get_node_or_null("WallDetector")
@onready var collision_shape: CollisionShape2D = $HazardArea/CollisionShape2D


var _start : Vector2
var _control : Vector2
var _end : Vector2
var _timer : float = 0.0
var _in_flight : bool = false
var _stuck : bool = false

const AUDIO_ARROW_IMPACT = preload("uid://ckb08n8sltl4k")



func _ready() -> void:
	visible = false
	hazard_area.monitoring = false
	wall_detector.monitoring = false
	if wall_detector:
		wall_detector.body_entered.connect( _on_wall_detector_body_entered )
	if hazard_area:
		# AttackArea (which HazardArea extends) checks "is DamageArea", and
		# DamageArea is an Area2D, so the hit shows up on area_entered, not
		# body_entered. Connecting both just in case that setup ever differs.
		
		hazard_area.body_entered.connect( _on_hazard_area_hit )
		hazard_area.area_entered.connect( _on_hazard_area_hit )
	
	

## Called by ESBowBanditAttack right after this arrow is spawned and placed.
## target_position is a plain Vector2, captured once here — the arrow never
## holds a reference to the player, so it can't drift if the target moves.
func launch( target_position : Vector2 ) -> void:
	
	_start = global_position
	visible = true
	
	
	_end = target_position
	_control = ( _start + _end ) / 2.0 + Vector2( 0, -arc_height )
	_timer = 0.0
	_in_flight = true
	hazard_area.monitoring = true
	wall_detector.monitoring = true
	_update_transform( 0.0 )


func _physics_process( delta : float ) -> void:
	if not _in_flight:
		return

	_timer += delta
	# No clamp — if nothing's hit by the time t reaches 1.0, the arrow just
	# keeps extrapolating along the same curve rather than stopping in mid-air.
	# Only a physical collision (WallDetector/HazardArea) ends the flight.
	var t : float = _timer / flight_duration
	_update_transform( t )


func _update_transform( t : float ) -> void:
	global_position = _bezier_point( t )
	rotation = _bezier_tangent( t ).angle()


func _bezier_point( t : float ) -> Vector2:
	var u : float = 1.0 - t
	return ( u * u * _start ) + ( 2.0 * u * t * _control ) + ( t * t * _end )


func _bezier_tangent( t : float ) -> Vector2:
	# Derivative of the quadratic bezier — direction of travel at this point
	# on the curve, used to angle the sprite along the trajectory.
	return ( 2.0 * ( 1.0 - t ) * ( _control - _start ) ) + ( 2.0 * t * ( _end - _control ) )


func _on_wall_detector_body_entered( body : Node2D ) -> void:
	if body is Player:
		return # the player is handled by hazard_area, not the wall detector
	_on_stuck()


func _on_hazard_area_hit( node : Node2D ) -> void:
	Audio.play_spatial_sound( AUDIO_ARROW_IMPACT, global_position, false, false, 0.5)
	if node is DamageArea:
		queue_free()


func _on_stuck() -> void:
	Audio.play_spatial_sound( AUDIO_ARROW_IMPACT, global_position, false, false, 0.5)
	if _stuck:
		return
	_stuck = true
	_in_flight = false

	if hazard_area:
		hazard_area.queue_free()

	if stuck_texture:
		texture = stuck_texture
		hazard_area.queue_free()

	get_tree().create_timer( despawn_delay ).timeout.connect( queue_free )


func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []
	if not hazard_area:
		warnings.append("Requires a HazardArea child named 'HazardArea' to deal damage on hitting the player.")
	if not wall_detector:
		warnings.append("Requires an Area2D child named 'WallDetector' (configure its collision layer/mask to your ground/wall layer) to detect hitting a wall or floor.")
	return warnings
