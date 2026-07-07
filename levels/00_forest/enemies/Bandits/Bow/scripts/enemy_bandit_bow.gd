@tool

class_name EnemyBanditBow
extends Enemy


@export var hair_type := BanditVisuals.HairType.NONE:
	set(value):
		hair_type = value
		_update_enemy_visuals()
		
@export var armor_type := BanditVisuals.ArmorType.NONE:
	set(value):
		armor_type = value
		_update_health_from_armor()
		_update_enemy_visuals()
@onready var bandit_visuals: BanditVisuals = $Visuals

func _ready() -> void:
	_update_health_from_armor()
	super()

	if not Engine.is_editor_hint():
		direction_changed.connect(_on_direction_changed)

	
func _on_direction_changed(new_dir: float) -> void:

	if attack_area:
		attack_area.flip(new_dir)
		
func on_damage_taken(a: AttackArea) -> void:
	super.on_damage_taken(a)
	
	
func _update_health_from_armor() -> void:
	match armor_type:
		BanditVisuals.ArmorType.NONE:
			health = 2
		BanditVisuals.ArmorType.LIGHT:
			health = 3
		BanditVisuals.ArmorType.MEDIUM:
			health = 5
		BanditVisuals.ArmorType.HEAVY:
			health = 7
			
func _update_enemy_visuals() -> void:
	if bandit_visuals == null:
		return
	bandit_visuals.hair_type = hair_type
	bandit_visuals.armor_type = armor_type
	bandit_visuals.apply_visuals()


## The hair export stays HairType.RANDOM as authored — what actually needs
## persisting is which concrete hair BanditVisuals rolled at death time.
func get_death_visual_data() -> Dictionary:
	if bandit_visuals:
		return { "hair_type": bandit_visuals.resolved_hair_type }
	return {}


## Forces bandit_visuals to reuse the persisted hair instead of re-rolling.
## Runs before _update_enemy_visuals() in Enemy._spawn_as_corpse().
func apply_death_visual_data( data : Dictionary ) -> void:
	if bandit_visuals and data.has( "hair_type" ):
		bandit_visuals.set_resolved_hair_type( data["hair_type"] )
