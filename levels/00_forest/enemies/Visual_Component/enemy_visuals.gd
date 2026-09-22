@tool
class_name EnemyVisuals
extends Node2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var animation_library: AnimationLibrary:
	set(value):
		animation_library = value
		_apply_animation_library()

## Color/duration for the hit-flash triggered by the enemy's `was_hit`
## signal below. Uses `modulate` rather than a shader so it works no matter
## what sprite structure a given enemy's visuals subtree has (plain body
## sprite, or layered sprites like BanditVisuals' hair/armor) — modulate
## multiplies down through every child CanvasItem automatically.
@export var flash_color : Color = Color(1.0, 0.2, 0.2)
@export var flash_duration : float = 0.12

var facing_right := true
var _flash_tween : Tween

func _ready() -> void:
	_apply_animation_library()
	if not Engine.is_editor_hint() and owner is Enemy:
		owner.was_hit.connect( _on_hit )

func _apply_animation_library() -> void:
	if not animation_player or not animation_library:
		return
	for lib_name in animation_player.get_animation_library_list():
		animation_player.remove_animation_library(lib_name)
	animation_player.add_animation_library("", animation_library)
	
func apply_visuals() -> void:
	pass
	
func set_facing_direction(dir: float) -> void:
	if dir == 0:
		return
	facing_right = dir > 0
	_apply_facing()
	
func _apply_facing() -> void:
	scale.x = 1 if facing_right else -1
	
func _on_hit( a : AttackArea ) -> void:
	if _is_harmless_shield_block( a ):
		return
	flash_hit()

## A LIGHT attack against an active shield bounces off completely — no
## damage, no shield break (see EnemyBanditSword._on_shield_blocked()'s
## LIGHT branch / ESShieldBreaker's own LIGHT case) — so unlike a real hit,
## or a HEAVY hit that actually breaks the shield, nothing happened here
## that should flash the enemy red/white.
func _is_harmless_shield_block( a : AttackArea ) -> bool:
	if not ( owner is Enemy ):
		return false
	var enemy : Enemy = owner
	return enemy.blackboard.shield_active and a.dmg_type == DamageType.DamageType.LIGHT

## Briefly tints the whole visuals subtree flash_color, then eases back to
## white. Safe to call repeatedly on fast hit combos — kills any tween
## already in flight so flashes don't stack or fight each other. Reads
## flash_color/flash_duration fresh each call so tweaking them in the
## Inspector at runtime takes effect immediately.
func flash_hit() -> void:
	if _flash_tween:
		_flash_tween.kill()
	modulate = flash_color
	_flash_tween = create_tween()
	_flash_tween.tween_property( self, "modulate", Color.WHITE, flash_duration )

func play_animation(name: StringName) -> void:
	if animation_player:
		animation_player.play(name)
		
func is_animation_playing() -> bool:
	return animation_player and animation_player.is_playing()
	
func get_current_animation() -> StringName:
	return animation_player.current_animation
	
func has_animation(name: StringName) -> bool:
	return animation_player and animation_player.has_animation(name)

func get_animation_length(name: StringName) -> float:
	if !animation_player:
		return 0
	var anim := animation_player.get_animation(name)
	return anim.length if anim else 0
	
func get_current_animation_length() -> float:
	return get_animation_length(animation_player.current_animation)
	
func wait_for_current_animation() -> void:
	var len := get_current_animation_length()
	if len > 0:
		await get_tree().create_timer(len).timeout
		
func play_and_wait(name: StringName) -> void:
	play_animation(name)
	await wait_for_current_animation()
