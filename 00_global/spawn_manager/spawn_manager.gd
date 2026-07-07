extends Node
# key: String id -> { "element": DamageType.DamageElement, "dir": float, "visuals": Dictionary }
var dead_enemies : Dictionary = {}
func get_enemy_id(enemy: Enemy) -> String:
	var scene_path := enemy.get_tree().current_scene.scene_file_path
	var scene_uid := ResourceUID.path_to_uid(scene_path)
	return scene_uid + "/" + enemy.name
func is_dead(id: String) -> bool:
	return dead_enemies.has(id)
func get_death_data(id: String) -> Dictionary:
	return dead_enemies.get(id, {"element": DamageType.DamageElement.PHYSICAL, "dir": 1.0, "visuals": {}})
func mark_dead(id: String, element: DamageType.DamageElement, dir: float, visuals: Dictionary = {}) -> void:
	dead_enemies[id] = {"element": element, "dir": dir, "visuals": visuals}
func reset_all() -> void:
	dead_enemies.clear()
