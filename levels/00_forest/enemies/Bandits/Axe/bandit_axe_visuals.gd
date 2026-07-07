@tool
class_name BanditVisuals
extends EnemyVisuals

enum HairType {
	NONE,
	BLONDE,
	MOHAWK,
	RED,
	HELMET,
	RANDOM
}
enum ArmorType {
	NONE,
	LIGHT,
	MEDIUM,
	HEAVY
}

@export var visuals_data: BanditVisualsData

var hair_type: HairType = HairType.NONE
var armor_type: ArmorType = ArmorType.NONE

## The actual concrete hair type once HairType.RANDOM has been resolved.
## Stays fixed for the lifetime of this node — see _hair_rolled below.
var resolved_hair_type := HairType.NONE
var _hair_rolled : bool = false

@onready var hair_sprite: Sprite2D = $Sprites/Hair
@onready var armor_sprite: Sprite2D = $Sprites/Armor

func _ready() -> void:
	super._ready()
	hair_sprite.region_enabled = false
	armor_sprite.region_enabled = false
	apply_visuals()
	
func apply_visuals() -> void:
	if visuals_data == null:
		return
	_apply_hair()
	_apply_armor()


## Forces a specific resolved hair type (e.g. restoring a persisted corpse's
## hair) instead of letting _apply_hair() roll a new random one. Call before
## apply_visuals()/apply_visuals() will pick this value up as already-rolled.
func set_resolved_hair_type( value : HairType ) -> void:
	resolved_hair_type = value
	_hair_rolled = true


func _apply_hair() -> void:
	var final_hair_type := hair_type
	if hair_type == HairType.RANDOM:
		if not _hair_rolled:
			var options := [
				HairType.BLONDE,
				HairType.MOHAWK,
				HairType.RED,
				HairType.HELMET
			]
			resolved_hair_type = options[randi_range(0, options.size() - 1)]
			_hair_rolled = true
		final_hair_type = resolved_hair_type
	else:
		resolved_hair_type = final_hair_type
		_hair_rolled = true
	match final_hair_type:
		HairType.NONE:
			hair_sprite.visible = false
		HairType.BLONDE:
			hair_sprite.visible = true
			hair_sprite.texture = visuals_data.hair_blonde
		HairType.MOHAWK:
			hair_sprite.visible = true
			hair_sprite.texture = visuals_data.hair_mohawk
		HairType.RED:
			hair_sprite.visible = true
			hair_sprite.texture = visuals_data.hair_red
		HairType.HELMET:
			hair_sprite.visible = true
			hair_sprite.texture = visuals_data.hair_helmet
			
func _apply_armor() -> void:
	match armor_type:
		ArmorType.NONE:
			armor_sprite.texture = visuals_data.armor_none
		ArmorType.LIGHT:
			armor_sprite.texture = visuals_data.armor_light
		ArmorType.MEDIUM:
			armor_sprite.texture = visuals_data.armor_medium
		ArmorType.HEAVY:
			armor_sprite.texture = visuals_data.armor_heavy
