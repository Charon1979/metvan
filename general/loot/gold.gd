@icon( "uid://cltev4ia8x75q" )

class_name GoldPickup
extends CharacterBody2D

const COIN_AUDIO = preload("uid://lk8px256n5bm")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D

enum Currency {
	COIN = 1,
	RED_GEM = 10,
	BLUE_GEM = 20,
	GREEN_GEM = 50,
	DIAMOND = 100
}

const ANIMATION := {
	Currency.COIN: "coin",
	Currency.RED_GEM: "red_gem",
	Currency.BLUE_GEM: "blue_gem",
	Currency.GREEN_GEM: "green_gem",
	Currency.DIAMOND: "diamond",
}

@export var value: Currency = Currency.COIN

var bounce_count: int = 6
var friction: float = 6.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready() -> void:
	
	# correct animation selection
	if ANIMATION.has(value):
		anim.play(ANIMATION[value])

	# slight variation = less robotic feel
	anim.frame = randi() % anim.sprite_frames.get_frame_count(anim.animation)
	anim.speed_scale = randf_range(0.95, 1.1)

	area_2d.body_entered.connect(_on_player_entered)


func _physics_process(delta: float) -> void:
	if bounce_count > 0:
		velocity.y += gravity * delta

		var collision: KinematicCollision2D = move_and_collide(velocity * delta)

		if collision:
			bounce_count -= 1

			# realistic bounce loss
			velocity = velocity.bounce(collision.get_normal()) * 0.7

			# soften horizontal jitter
			velocity.x *= 0.85
	else:
		# settle on ground naturally
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.y += gravity * delta
		move_and_slide()


func _on_player_entered(n: Node2D) -> void:
	if n is Player:
		n.gold += value
		
		area_2d.body_entered.disconnect( _on_player_entered )
		Audio.play_spatial_sound(COIN_AUDIO, global_position, false, true, 0.0)
		
		queue_free()
