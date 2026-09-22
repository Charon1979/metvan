extends PointLight2D


func _ready() -> void:
	flicker()
	pass
	

func flicker() -> void:
	# Was recursive (flicker() called itself after the await instead of
	# looping). Each call suspends on the await before its own recursive
	# call returns, so the coroutine call stack grew without bound for as
	# long as this campfire existed. A while loop does the same thing
	# without ever growing the stack.
	while true:
		energy = randf() * 0.1 + 0.9
		scale = Vector2 ( 1, 1 ) * energy
		await get_tree().create_timer( 0.1 ).timeout
	pass
