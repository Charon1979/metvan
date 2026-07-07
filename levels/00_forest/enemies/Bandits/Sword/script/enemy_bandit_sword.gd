@tool

class_name EnemyBanditSword
extends Enemy


@onready var shield: Sprite2D = %Shield

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
	if is_corpse:
		shield.visible = false
		return
	if not Engine.is_editor_hint():
		blackboard.shield_active = true
		direction_changed.connect(_on_direction_changed)
	shield.visible = true
	
func _on_direction_changed(new_dir: float) -> void:
	shield.scale.x = 1 if new_dir > 0 else -1
	shield.position.x = abs(shield.position.x) if new_dir > 0 else -abs(shield.position.x)
	if attack_area:
		attack_area.flip(new_dir)
		
func on_damage_taken(a: AttackArea) -> void:
	if blackboard.shield_active and a.dmg_type != DamageType.DamageType.MAGIC:
		_on_shield_blocked(a)
		return
	super.on_damage_taken(a)
	
func _on_shield_blocked(a: AttackArea) -> void:
	blackboard.can_decide = true
	attack_area.set_active(false)
	blackboard.damage_source = a
	blackboard.damage_element = a.dmg_element
	blackboard.damage_type = a.dmg_type        # FIX: was never assigned
	blackboard.force = a.force
	# no health subtraction, no death check — shield fully absorbs light/heavy hits
	was_hit.emit(a)
	
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
