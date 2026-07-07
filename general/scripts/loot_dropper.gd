@icon( "uid://dclq2l1yrpdnq" )

class_name LootDropper
extends Marker2D

@export var  items : Array[ LootData ]

var value : int = 0


func _ready() -> void:
	if owner is Enemy:
		owner.was_killed.connect( drop_loot )
	elif owner is Breakable:
		owner.destroyed.connect( drop_loot )
	elif owner is Player:
		owner.dead.connect( drop_player_loot )
		pass
	pass


func drop_loot() -> void:
	
	for i in items:
		if i.drop_chance <= randf():
			continue
		var drop_scene = load(i.item)
		var count: int = randi_range(i.minimum, i.maximum)

		for j in count:
			var drop = drop_scene.instantiate()
			owner.add_sibling.call_deferred(drop)

			# small spawn jitter so items don't overlap
			drop.global_position = global_position + Vector2(
				randf_range(-6, 6),
				randf_range(-6, 6)
			)

			# upward cone spray (main feel)
			var angle := randf_range(-PI * 0.85, -PI * 0.15)

			# add slight horizontal randomness for natural spread
			angle += randf_range(-0.35, 0.35)

			var speed := randf_range(180.0, 320.0)

			# stronger upward bias (feels like a pop)
			var velocity := Vector2(
				cos(angle),
				sin(angle)
			) * speed

			# extra polish: slight horizontal nudge randomness
			velocity.x += randf_range(-40.0, 40.0)

			drop.velocity = velocity

func drop_player_loot() -> void:
	
	if owner.gold <= 0:
		pass
	else:
		
		for i in items:
	
			var drop_scene = load(i.item)
			var drop = drop_scene.instantiate()
			drop.gold_value = owner.gold
			owner.add_sibling.call_deferred(drop)
			
				

			drop.global_position.x = owner.global_position.x
			drop.global_position.y = owner.global_position.y - 64
			
				
