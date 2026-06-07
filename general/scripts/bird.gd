extends Node2D

@onready var anim_player = $AnimationPlayer
@onready var area = $Area2D
@onready var sprite = $Sprite2D

var flying = false
var fly_speed = 200.0
var fly_direction = Vector2(1, -0.3).normalized()
var start_position = Vector2.ZERO
var elapsed_time = 0.0
var min_flight_time = 2.0  # seconds before bird can disappear

func _ready():
	# Randomly flip the bird to face left or right when sitting
	randomize()
	sprite.flip_h = randi() % 2 == 0

	anim_player.play("sit")
	start_position = position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if flying:
		return
	if body.is_in_group("Player"):
		flying = true
		anim_player.play("fly")
		start_position = position
		elapsed_time = 0.0


		var to_player = body.global_position - global_position
		var direction_x = -sign(to_player.x)  # fly away from player

		if direction_x == 0:
			direction_x = 1  # fallback: fly right if perfectly vertical

		var direction_y = -0.3  # slightly upward
		fly_direction = Vector2(direction_x, direction_y).normalized()

		# Flip sprite to face direction it's flying
		sprite.flip_h = direction_x < 0

func _process(delta):
	if flying:
		elapsed_time += delta

		var base_move = fly_direction * fly_speed * elapsed_time
		var oscillation_y = 5 * sin(elapsed_time * 4)

		position = start_position + base_move + Vector2(0, oscillation_y)

		var viewport_width = get_viewport_rect().size.x
		if elapsed_time > min_flight_time and (position.x > viewport_width + 50 or position.x < -50 or position.y < -200):
			queue_free()
