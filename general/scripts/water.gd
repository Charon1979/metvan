extends StaticBody2D

@export var speed: float = 100.0
@export var direction: Vector2 = Vector2.LEFT

func _ready():
	constant_linear_velocity = direction.normalized() * speed
