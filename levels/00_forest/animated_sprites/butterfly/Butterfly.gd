extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

@export var speed: float = 60.0

@export_category("Vertical Wander")
@export var vertical_limit_up: float = 96.0
@export var vertical_limit_down: float = 20.0

# Bright, saturated colors only — no muted/dark hues.
const BRIGHT_COLORS: Array[Color] = [
	Color(1.0, 0.95, 0.05),   # yellow
	Color(1.0, 0.4, 0.7),    # pink
	Color(0.1, 0.3, 0.9),    # deep blue
	Color(1.0, 0.55, 0.0),   # orange
	Color(1.0, 1.0, 1.0),    # white
]

var velocity: Vector2 = Vector2.ZERO
var start_y: float = 0.0

var _direction_timer: float = 0.0
var _direction_interval: float = 0.0

var _animation_timer: float = 0.0
var _animation_interval: float = 0.0

var _rotation_timer: float = 0.0
var _rotation_interval: float = 0.0


func _ready() -> void:
	randomize()
	start_y = global_position.y

	sprite.modulate = BRIGHT_COLORS.pick_random()

	_reset_direction_interval()
	_reset_animation_interval()
	_reset_rotation_interval()

	anim_player.play("side")


func _process(delta: float) -> void:
	_direction_timer += delta
	_animation_timer += delta
	_rotation_timer += delta

	if _direction_timer > _direction_interval:
		_direction_timer = 0.0
		_reset_direction_interval()
		velocity = Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized() * speed

	global_position += velocity * delta
	global_position.y = clamp(global_position.y, start_y - vertical_limit_up, start_y + vertical_limit_down)

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	if _animation_timer > _animation_interval:
		_animation_timer = 0.0
		_reset_animation_interval()
		var next_anim: String = "up" if randf() < 0.5 else "side"
		if anim_player.current_animation != next_anim:
			anim_player.play(next_anim)

	if _rotation_timer > _rotation_interval:
		_rotation_timer = 0.0
		_reset_rotation_interval()
		rotation = deg_to_rad(randf_range(-45, 45))


func _reset_direction_interval() -> void:
	_direction_interval = 0.5 + randf() * 0.5

func _reset_animation_interval() -> void:
	_animation_interval = 0.3 + randf() * 0.4

func _reset_rotation_interval() -> void:
	_rotation_interval = 0.5 + randf() * 0.5
