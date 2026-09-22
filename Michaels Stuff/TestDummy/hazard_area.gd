@icon("uid://bjt8ebbpchlih")
class_name HazardArea
extends AttackArea

## If true, this hazard also sends the player back to their last checkpoint
## on hit (pits, spikes, instant-death traps). Leave false for a normal
## damage-only hazard (e.g. a hurtful enemy contact area).
@export var is_trap: bool = false

## Magic damage dealt to an enemy that falls into the trap (is_trap only).
## Assumed to always exceed enemy HP/resistance, so this kills outright.
@export var trap_enemy_damage: int = 1000

const LAYER_PLAYER := 5
const LAYER_ENEMY := 6


func _ready() -> void:
	super()
	visible = true
	monitoring = true
	monitorable = true
	hit_target.connect(_on_hit_target)
	body_exited.connect(_on_exited)
	area_exited.connect(_on_exited)

	if is_trap:
		# A trap only ever cares about players and enemies, regardless of
		# whatever mask was left set up on the node in the editor.
		collision_mask = 0
		set_collision_mask_value(LAYER_PLAYER, true)
		set_collision_mask_value(LAYER_ENEMY, true)


func _on_body_entered(body: Node2D) -> void:
	if is_trap and body is DamageArea:
		var target := body as DamageArea
		if _is_enemy(target):
			_hit_enemy(target)
			return

	super._on_body_entered(body)


func _is_enemy(target: DamageArea) -> bool:
	return target.get_collision_layer_value(LAYER_ENEMY)


func _hit_enemy(target: DamageArea) -> void:
	# Run the hit through the normal damage pipeline with trap-specific
	# numbers, without permanently touching this AttackArea's own
	# @export damage/element (those still belong to the player-hit case).
	var original_damage: int = damage
	var original_element: DamageType.DamageElement = dmg_element

	damage = trap_enemy_damage
	
	target.take_damage(self) # lethal — triggers the enemy's own death/animation logic
	damage = original_damage
	dmg_element = original_element

	hit_target.emit(target)


func _on_hit_target(damage_area: DamageArea) -> void:
	if not is_trap or _is_enemy(damage_area):
		return # enemies are handled/killed in _hit_enemy, not here

	# A lethal hit is entirely the player's own death flow's business now
	# (take_damage.gd -> death.gd -> SaveManager.game_over()), which already
	# plays the death animation in place and only moves the player to the
	# checkpoint afterward. Calling restore_checkpoint() here too used to
	# race that flow directly: it could fade out and teleport the player to
	# the checkpoint before the death animation ever played (so the player
	# looked like they'd been yanked out of the trap first, animation
	# second), and since loot_dropper.gd's drop_player_loot() reads
	# global_position off the `dead` signal, it could even make the dropped
	# gold appear at the checkpoint instead of the trap. Only a SURVIVABLE
	# trap hit should snap the player back to the checkpoint immediately —
	# a lethal one is left alone here entirely.
	var target : Player = damage_area.owner as Player
	if target and target.hp <= 0:
		return

	set_deferred("monitoring", false) # avoid re-triggering every frame while still overlapping

	get_tree().paused = true
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = false

	SaveManager.restore_checkpoint()


func _on_exited(_node: Node2D) -> void:
	set_deferred("monitoring", true)
