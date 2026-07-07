@tool
@icon("uid://dy178uirc4rfd")
class_name Enemy
extends CharacterBody2D

signal direction_changed(new_dir)
signal was_hit( a: AttackArea )
signal was_killed()

@export var health: float = 1
@export var affected_by_gravity: bool = true

@export var face_left_on_start: bool = false:
	set(value):
		face_left_on_start = value
		_apply_editor_facing()

@export_category("Audio")
@export var death_sound: AudioStream



var damage_player: AnimationPlayer
var damage_area: DamageArea
var hazard_area: HazardArea
var sprite: Sprite2D
var state_machine: EnemyStateMachine
var decision_engine: DecisionEngine
var blackboard: Blackboard
var attack_area : AttackArea
var visuals : EnemyVisuals
var vfx: EnemyVFX
var animation_player : AnimationPlayer
var hit_particles : EnemyHitParticles
var player_sensor : PlayerSensor
var spawn_id : String = ""
var is_corpse : bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		_gather_children()
		if not blackboard:
			blackboard = Blackboard.new()
		_update_enemy_visuals()
		_apply_editor_facing()
		return

	_gather_children()
	blackboard = Blackboard.new()
	spawn_id = SpawnManager.get_enemy_id(self)
	if SpawnManager.is_dead(spawn_id):
		var death_data = SpawnManager.get_death_data(spawn_id)
		_spawn_as_corpse(death_data.element, death_data.dir, death_data.get("visuals", {}))
		return

	setup()
	_update_enemy_visuals()


func setup() -> void:
	blackboard.health = health
	if damage_area:
		damage_area.damage_taken.connect(on_damage_taken)
	if state_machine and decision_engine:
		state_machine.setup(self, blackboard)
		decision_engine.enemy = self
		decision_engine.blackboard = blackboard
	else:
		set_physics_process(false)

func _gather_children() -> void:
	for c in get_children():
		if c is AnimationPlayer and not animation_player:
			animation_player = c
		elif c is Sprite2D and not sprite:
			sprite = c
		elif c is DamageArea and not damage_area:
			damage_area = c
		elif c is HazardArea and not hazard_area:
			hazard_area = c
		elif c is EnemyStateMachine and not state_machine:
			state_machine = c
		elif c is DecisionEngine and not decision_engine:
			decision_engine = c
		elif c is AttackArea and not attack_area:
			attack_area = c
		elif c is EnemyVisuals and not visuals:
			visuals = c
		elif c is EnemyVFX and not vfx:
			vfx = c
		elif c is EnemyHitParticles and not hit_particles:
			hit_particles = c
		elif c is PlayerSensor and not player_sensor:
			player_sensor = c

	if not state_machine or not decision_engine:
		set_physics_process(false)


func _apply_editor_facing() -> void:
	if not Engine.is_editor_hint():
		return
	if visuals:
		visuals.set_facing_direction(-1 if face_left_on_start else 1)
	if vfx:
		vfx.set_facing_direction(-1 if face_left_on_start else 1)   


func _physics_process(delta: float) -> void:

	blackboard.update_distance_to_target(global_position)

	if blackboard.can_decide:
		state_machine.change_state(decision_engine.decide())

	if affected_by_gravity:
		velocity += get_gravity() * delta

	state_machine.physics_update(delta)
	move_and_slide()


func change_dir(new_dir: float) -> void:
	blackboard.dir = new_dir
	direction_changed.emit(new_dir)
	if visuals:
		visuals.set_facing_direction(new_dir)
	if vfx:                                      
		vfx.set_facing_direction(new_dir) 


func on_damage_taken(a: AttackArea) -> void:
	
	blackboard.can_decide = true
	attack_area.set_active( false )
	blackboard.damage_source = a
	blackboard.force = a.force
	blackboard.damage_element = a.dmg_element
	blackboard.damage_type = a.dmg_type
	blackboard.health -= a.damage

	if blackboard.health <= 0:
		damage_area.queue_free()
		hazard_area.queue_free()
		was_killed.emit()

	was_hit.emit(a)


func _spawn_as_corpse(element: DamageType.DamageElement, dir: float, visual_data: Dictionary = {}) -> void:
	is_corpse = true
	set_physics_process(false)
	if damage_area: damage_area.queue_free()
	if hazard_area: hazard_area.queue_free()
	if attack_area: attack_area.queue_free()
	if state_machine: state_machine.queue_free()
	if decision_engine: decision_engine.queue_free()
	if player_sensor: player_sensor.queue_free()

	apply_death_visual_data(visual_data)
	_update_enemy_visuals()
	if visuals and dir != 0.0:
		visuals.set_facing_direction(dir)
	if vfx and dir != 0.0:
		vfx.set_facing_direction(dir)

	var death_anims := {
		DamageType.DamageElement.FIRE: "death_fire",
		DamageType.DamageElement.AIR: "death_air",
		DamageType.DamageElement.WATER: "death_water",
		DamageType.DamageElement.EARTH: "death_earth",
		DamageType.DamageElement.PHYSICAL: "death",
		DamageType.DamageElement.SHADOW: "death_shadow",
		DamageType.DamageElement.BLOOD: "death_blood",
	}
	var anim_name : String = death_anims.get(element, "death")
	if visuals:
		visuals.play_animation(anim_name)
		var len := visuals.get_animation_length(anim_name)
		if visuals.animation_player and len > 0.0:
			visuals.animation_player.seek(len, true)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not find_children("*", "AnimationPlayer", true):
		warnings.append("Requires an AnimationPlayer!")

	if not find_children("*", "Sprite2D", true):
		warnings.append("Needs Sprite2D")

	if not find_children("*", "DamageArea", true):
		warnings.append("Requires a DamageArea!")

	if not find_children("*", "HazardArea", true):
		warnings.append("Requires a HazardArea!")

	if not find_children("*", "EnemyStateMachine", true):
		warnings.append("Requires an EnemyStateMachine!")

	if not find_children("*", "DecisionEngine", true):
		warnings.append("Requires a DecisionEngine!")

	return warnings


func _update_enemy_visuals() -> void:
	# Override in child classes
	pass


## Override in subclasses that roll random/variable visual state (e.g. a
## randomly-chosen cosmetic) which should stay fixed once the enemy dies,
## instead of re-rolling every time the corpse is recreated on scene reload.
## Called from ESDeath.enter() at the moment of death.
func get_death_visual_data() -> Dictionary:
	return {}


## Override in subclasses to apply data returned by get_death_visual_data().
## Called from _spawn_as_corpse(), before _update_enemy_visuals(), so the
## restored state is what actually gets rendered.
func apply_death_visual_data( _data : Dictionary ) -> void:
	pass
