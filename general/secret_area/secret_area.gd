@tool
class_name SecretArea
extends Sprite2D

@onready var secret_area: Area2D = $Area2D
const SECRET_AREA_AUDIO = preload("uid://v5etoef251rc")

## Leave empty to auto-derive one from this node's path (fine as long as you
## don't reparent/rename this secret area); set it explicitly for a stable
## id regardless of scene position.
##
## NOTE: this used to be keyed by SceneManager.current_scene_uid alone —
## i.e. by WHICH SCENE the secret area is in, not which secret area it is.
## With more than one secret area in the same scene, finding any one of
## them marked ALL of them found (and finding one didn't survive a reload
## if a different one in the same scene got checked first). persistent_id
## below makes each instance its own key, the same way every other
## persisted object in the game already works — see
## RegionInfo.persistent_key()'s doc comment.
@export var persistent_id : String = ""

var is_explored : bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if SaveManager.is_secret_area_found( _key() ):
		is_explored = true
		queue_free()

	pass


func _key() -> String:
	if persistent_id.is_empty():
		persistent_id = str( get_path() )
	return SaveManager.persistent_key( self, persistent_id )


func _get_configuration_warnings() -> PackedStringArray:
	if _check_for_area() == false:
		return ["Requires an Area2D!"]
	return []


func _check_for_area() -> bool:
	for c in get_children():
		if c is Area2D:
			return true
	return false


func _on_area_2d_body_entered( _body: Node2D ) -> void:
	is_explored = true
	Audio.play_spatial_sound( SECRET_AREA_AUDIO, global_position )

	SaveManager.register_secret_area( _key() )

	visible = false
	queue_free()
	pass
