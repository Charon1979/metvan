@tool
extends Node2D

@export var plant_data: PlantData : set = _on_plant_data_set

enum FlowerType {
	RANDOM,
	FLOWER_0,
	FLOWER_1,
	FLOWER_2,
	FLOWER_3,
	FLOWER_4
}

@export var flower_type: FlowerType = FlowerType.RANDOM : set = _on_flower_type_set

## The actual concrete texture index once FLOWER_TYPE.RANDOM has been
## resolved. Stays fixed for the lifetime of this node — see _flower_rolled.
var resolved_flower_index: int = 0
var _flower_rolled: bool = false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var damage_area: DamageArea = $DamageArea
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var area: Area2D = $Area2D


var _player: Node2D = null

const AUDIO_GRASS_CUT = preload("uid://b6y54t3jsawnq")
const AUDIO_GRASS = preload("uid://dmjp8u458gh5n")

func _ready() -> void:
	_ensure_unique_material()
	_apply_flower_selection()

	if Engine.is_editor_hint():
		return

	damage_area.damage_taken.connect(on_damage_taken)
	
	
	if sprite_2d.material is ShaderMaterial:
		sprite_2d.material.set_shader_parameter("plant_x", global_position.x)
		sprite_2d.material.set_shader_parameter("plant_y", global_position.y)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("Player")
		return

	if sprite_2d.material is ShaderMaterial:
		sprite_2d.material.set_shader_parameter("trigger_x", _player.global_position.x)
		sprite_2d.material.set_shader_parameter("trigger_y", _player.global_position.y)


func _ensure_unique_material() -> void:
	if sprite_2d == null:
		return
	if sprite_2d.material is ShaderMaterial:
		sprite_2d.material = sprite_2d.material.duplicate()


func _on_plant_data_set(value: PlantData) -> void:
	plant_data = value
	_apply_flower_selection()


func _on_flower_type_set(value: FlowerType) -> void:
	flower_type = value
	_apply_flower_selection()


## Forces a specific resolved flower index (e.g. restoring a persisted
## plant's look) instead of letting _apply_flower_selection() roll a new
## random one. Call before apply_visuals — the roll will pick this up as
## already-resolved.
func set_resolved_flower_index(value: int) -> void:
	resolved_flower_index = value
	_flower_rolled = true


func _apply_flower_selection() -> void:
	if sprite_2d == null or plant_data == null or plant_data.flower_textures.is_empty():
		return

	var final_index: int

	if flower_type == FlowerType.RANDOM:
		if not _flower_rolled:
			resolved_flower_index = randi_range(0, plant_data.flower_textures.size() - 1)
			_flower_rolled = true
		final_index = resolved_flower_index
	else:
		# FlowerType.FLOWER_0 == 1, FLOWER_1 == 2, etc. — shift down by 1
		# since RANDOM occupies enum slot 0.
		final_index = int(flower_type) - 1
		resolved_flower_index = final_index
		_flower_rolled = true

	final_index = clamp(final_index, 0, plant_data.flower_textures.size() - 1)
	sprite_2d.texture = plant_data.flower_textures[final_index]


func on_damage_taken(_attack_area: AttackArea) -> void:
	Audio.play_spatial_sound( AUDIO_GRASS_CUT, global_position, false, false, 0.5 )
	particles.emitting = true
	damage_area.queue_free()
	if plant_data:
		sprite_2d.texture = plant_data.destroyed_texture

	_disable_shader()
	damage_area.monitoring = false
	area.queue_free()


func _disable_shader() -> void:
	if sprite_2d.material is ShaderMaterial:
		sprite_2d.material = null
		


func _on_area_2d_body_entered(body: Node2D) -> void:
	Audio.play_spatial_sound( AUDIO_GRASS, global_position, false, false, 0.5)
	pass # Replace with function body.
